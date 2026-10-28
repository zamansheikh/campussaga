package httpx

import (
	"context"
	"crypto/rand"
	"fmt"
	"log/slog"
	"net"
	"net/http"
	"net/netip"
	"runtime/debug"
	"strings"
	"time"

	"github.com/go-chi/chi/v5"

	"github.com/zamansheikh/campussaga/backend/internal/platform/apperr"
)

const traceAlphabet = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz_-"

func newTraceID() string {
	var b [16]byte
	_, _ = rand.Read(b[:])
	for i := range b {
		b[i] = traceAlphabet[int(b[i])%len(traceAlphabet)]
	}
	return string(b[:])
}

// Base installs trace id, real client IP, request logger and client info.
// Must be the outermost middleware.
func Base(log *slog.Logger) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			trace := r.Header.Get("X-Trace-Id")
			if trace == "" || len(trace) > 64 {
				trace = newTraceID()
			}
			w.Header().Set("X-Trace-Id", trace)
			ip := RealIP(r)
			ctx := context.WithValue(r.Context(), traceKey{}, trace)
			base := log.With("traceId", trace)
			ctx = context.WithValue(ctx, loggerKey{}, base)
			ctx = context.WithValue(ctx, baseLoggerKey{}, base)
			ctx = context.WithValue(ctx, clientKey{}, clientFrom(r, ip))
			next.ServeHTTP(w, r.WithContext(ctx))
		})
	}
}

// RealIP is the caller's address. Production: phone → nginx on the host →
// this process over loopback or the Docker bridge. Only those hops are
// trusted: X-Forwarded-For is walked from the right and the first address
// that is not loopback/private is the client. Headers a client can set
// itself (X-Real-IP, the left end of XFF) are never believed, or one caller
// could spoof another's rate-limit bucket.
func RealIP(r *http.Request) string {
	peer := r.RemoteAddr
	if host, _, err := net.SplitHostPort(peer); err == nil {
		peer = host
	}
	if !trustedHop(peer) {
		return peer
	}
	var hops []string
	for _, v := range r.Header.Values("X-Forwarded-For") {
		for _, h := range strings.Split(v, ",") {
			if h = strings.TrimSpace(h); h != "" {
				hops = append(hops, h)
			}
		}
	}
	for i := len(hops) - 1; i >= 0; i-- {
		if !trustedHop(hops[i]) {
			return hops[i]
		}
	}
	if len(hops) > 0 {
		return hops[0]
	}
	return peer
}

func trustedHop(s string) bool {
	a, err := netip.ParseAddr(s)
	if err != nil {
		return false
	}
	a = a.Unmap()
	return a.IsLoopback() || a.IsPrivate()
}

// Recover turns panics into a logged 500 envelope.
func Recover(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		defer func() {
			if p := recover(); p != nil {
				if p == http.ErrAbortHandler {
					panic(p)
				}
				Logger(r.Context()).Error("panic", "panic", fmt.Sprint(p), "stack", string(debug.Stack()))
				WriteError(w, r, apperr.Internal)
			}
		}()
		next.ServeHTTP(w, r)
	})
}

type statusRecorder struct {
	http.ResponseWriter
	status int
	bytes  int
}

func (s *statusRecorder) WriteHeader(code int) {
	if s.status == 0 {
		s.status = code
	}
	s.ResponseWriter.WriteHeader(code)
}

func (s *statusRecorder) Write(b []byte) (int, error) {
	if s.status == 0 {
		s.status = http.StatusOK
	}
	n, err := s.ResponseWriter.Write(b)
	s.bytes += n
	return n, err
}

func (s *statusRecorder) Unwrap() http.ResponseWriter { return s.ResponseWriter }

// AccessLog logs every request with its route pattern ("/auth/verify"),
// never the raw path or body: request bodies can hold emails and codes.
func AccessLog(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		rec := &statusRecorder{ResponseWriter: w}
		rctx := chi.NewRouteContext()
		next.ServeHTTP(rec, r.WithContext(context.WithValue(r.Context(), chi.RouteCtxKey, rctx)))
		d := time.Since(start)
		route := "unmatched"
		if p := rctx.RoutePattern(); p != "" {
			route = p
		}
		if rec.status == 0 {
			rec.status = http.StatusOK
		}
		lvl := slog.LevelInfo
		switch {
		case rec.status >= 500:
			lvl = slog.LevelError
		case r.Method == http.MethodGet && rec.status < 400 && d < 250*time.Millisecond:
			lvl = slog.LevelDebug
		}
		Logger(r.Context()).Log(r.Context(), lvl, "http",
			"method", r.Method, "route", route, "status", rec.status,
			"ms", d.Milliseconds(), "bytes", rec.bytes)
	})
}

// SecurityHeaders for a JSON API used by mobile apps.
func SecurityHeaders(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		h := w.Header()
		h.Set("X-Content-Type-Options", "nosniff")
		h.Set("Referrer-Policy", "no-referrer")
		h.Set("X-Frame-Options", "DENY")
		h.Set("Cache-Control", "no-store")
		h.Set("Strict-Transport-Security", "max-age=31536000; includeSubDomains")
		next.ServeHTTP(w, r)
	})
}

// MaxBody caps request bodies. larger raises the cap for exact paths
// (photo uploads), e.g. {"/api/v1/uploads": 9 << 20}.
func MaxBody(limit int64, larger ...map[string]int64) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			if r.Body != nil {
				l := limit
				for _, m := range larger {
					if v, ok := m[r.URL.Path]; ok {
						l = v
					}
				}
				r.Body = http.MaxBytesReader(w, r.Body, l)
			}
			next.ServeHTTP(w, r)
		})
	}
}
