package httpx

import (
	"context"
	"net/http"
	"strings"
	"time"

	"github.com/go-chi/chi/v5"

	"github.com/zamansheikh/campussaga/backend/internal/platform/apperr"
	"github.com/zamansheikh/campussaga/backend/internal/platform/auth"
	"github.com/zamansheikh/campussaga/backend/internal/platform/ratelimit"
)

// Router is what a module receives to mount its endpoints. Every route is
// mounted through an access group, so the access rule of an endpoint is
// visible where it is declared:
//
//	func (m *Module) Routes(r *httpx.Router) {
//	    r.Public().Get("/universities", httpx.Handle(m.h.list))
//	    r.Student().Get("/me", httpx.Handle(m.h.me))
//	}
//
// Paths are relative to the API prefix (/api/v1).
type Router struct {
	root    chi.Router
	tokens  *auth.Tokens
	limiter *ratelimit.Limiter
	check   SessionCheck
}

// SessionCheck runs after the token is verified, on every Student request
// (is the session still active?). nil skips it.
type SessionCheck func(ctx context.Context, c *auth.Claims) error

func NewRouter(root chi.Router, tokens *auth.Tokens, limiter *ratelimit.Limiter, check SessionCheck) *Router {
	if limiter == nil {
		limiter = ratelimit.New(nil)
	}
	return &Router{root: root, tokens: tokens, limiter: limiter, check: check}
}

// Public: no authentication.
func (r *Router) Public() chi.Router { return r.root.With() }

// Student: requires a valid, unexpired access token. Every signed-in user
// is a verified student (accounts are created only after the email code).
func (r *Router) Student() chi.Router { return r.root.With(r.requireUser) }

// Limit returns a middleware allowing limit requests per window per client IP.
func (r *Router) Limit(name string, limit int, window time.Duration) func(http.Handler) http.Handler {
	return RateLimit(r.limiter, name, limit, window, PerIP)
}

// Bearer extracts the token of an "Authorization: Bearer …" header.
func Bearer(r *http.Request) string {
	h := r.Header.Get("Authorization")
	if len(h) > 7 && strings.EqualFold(h[:7], "bearer ") {
		return strings.TrimSpace(h[7:])
	}
	return ""
}

func (r *Router) requireUser(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, req *http.Request) {
		tok := Bearer(req)
		if tok == "" {
			WriteError(w, req, auth.ErrUnauthorized)
			return
		}
		claims, err := r.tokens.Verify(tok)
		if err != nil {
			WriteError(w, req, err)
			return
		}
		if r.check != nil {
			if err := r.check(req.Context(), claims); err != nil {
				WriteError(w, req, err)
				return
			}
		}
		ctx := auth.WithUser(req.Context(), claims)
		ctx = withLogger(ctx, Logger(ctx).With("userId", claims.UserID))
		next.ServeHTTP(w, req.WithContext(ctx))
	})
}

// ErrTooManyRequests is returned by the per-IP limiter.
var ErrTooManyRequests = apperr.TooManyRequests("Too many requests, please wait a moment")

// RateLimit allows limit requests per window per key. keyFn returns "" to skip.
func RateLimit(l *ratelimit.Limiter, name string, limit int, window time.Duration, keyFn func(*http.Request) string) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			k := keyFn(r)
			if k == "" {
				next.ServeHTTP(w, r)
				return
			}
			if ok, retry := l.Allow(name+":"+k, limit, window); !ok {
				WriteError(w, r, ErrTooManyRequests.WithDetails(RetryAfter{RetryAfterSeconds: int(retry.Seconds()) + 1}))
				return
			}
			next.ServeHTTP(w, r)
		})
	}
}

// PerIP keys by client IP.
func PerIP(r *http.Request) string { return ClientInfo(r.Context()).IP }

// NotFoundHandler renders unmatched routes in the envelope.
func NotFoundHandler(w http.ResponseWriter, r *http.Request) {
	WriteError(w, r, apperr.NotFound("Cannot "+r.Method+" "+r.URL.Path))
}
