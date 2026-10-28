package httpx

import (
	"context"
	"log/slog"
	"net/http"
)

type traceKey struct{}
type loggerKey struct{}

// baseLoggerKey: the request logger before any user id was added.
type baseLoggerKey struct{}
type clientKey struct{}

// Client describes the calling device/network, filled by Base.
type Client struct {
	IP        string
	UserAgent string
}

// TraceID of the request ("" outside a request).
func TraceID(ctx context.Context) string {
	s, _ := ctx.Value(traceKey{}).(string)
	return s
}

// Logger returns the request-scoped logger (carries traceId), or the default.
func Logger(ctx context.Context) *slog.Logger {
	if l, ok := ctx.Value(loggerKey{}).(*slog.Logger); ok {
		return l
	}
	return slog.Default()
}

func withLogger(ctx context.Context, l *slog.Logger) context.Context {
	return context.WithValue(ctx, loggerKey{}, l)
}

// ClientInfo returns caller network/device info.
func ClientInfo(ctx context.Context) Client {
	c, _ := ctx.Value(clientKey{}).(Client)
	return c
}

// WithClientInfo is for tests and non-HTTP entry points.
func WithClientInfo(ctx context.Context, c Client) context.Context {
	return context.WithValue(ctx, clientKey{}, c)
}

func clientFrom(r *http.Request, ip string) Client {
	return Client{IP: ip, UserAgent: r.UserAgent()}
}

// Unlogged drops the signed-in user's id from this request's log lines
// (Campus Voice: who wrote what must not reach the logs). Use it after the
// token check.
func Unlogged(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if l, ok := r.Context().Value(baseLoggerKey{}).(*slog.Logger); ok {
			r = r.WithContext(withLogger(r.Context(), l))
		}
		next.ServeHTTP(w, r)
	})
}
