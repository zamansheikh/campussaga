// Package app wires the process: database, mailer, router and the modules
// mounted on it. Modules never import each other; this file connects them.
package app

import (
	"context"
	"errors"
	"log/slog"
	"net/http"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"

	"github.com/zamansheikh/campussaga/backend/internal/modules/accounts"
	"github.com/zamansheikh/campussaga/backend/internal/modules/appconfig"
	"github.com/zamansheikh/campussaga/backend/internal/modules/classgroups"
	"github.com/zamansheikh/campussaga/backend/internal/modules/universities"
	"github.com/zamansheikh/campussaga/backend/internal/platform/auth"
	"github.com/zamansheikh/campussaga/backend/internal/platform/config"
	"github.com/zamansheikh/campussaga/backend/internal/platform/db"
	"github.com/zamansheikh/campussaga/backend/internal/platform/firebase"
	"github.com/zamansheikh/campussaga/backend/internal/platform/httpx"
	"github.com/zamansheikh/campussaga/backend/internal/platform/mail"
	"github.com/zamansheikh/campussaga/backend/internal/platform/ratelimit"
)

// App is the assembled process.
type App struct {
	Cfg          *config.Config
	Log          *slog.Logger
	DB           *db.DB
	Tokens       *auth.Tokens
	Universities *universities.Service
	Accounts     *accounts.Service
	Config       *appconfig.Service
	ClassGroups  *classgroups.Service

	handler http.Handler
}

// Options tune the assembly (tests).
type Options struct {
	Now    func() time.Time        // clock; nil = time.Now
	Mailer mail.Sender             // nil = SMTP from config
	Google accounts.GoogleVerifier // nil = Firebase verifier from config (if configured)
}

// New assembles the app on an open, migrated database.
func New(cfg *config.Config, log *slog.Logger, d *db.DB, opts ...Options) *App {
	var o Options
	if len(opts) > 0 {
		o = opts[0]
	}
	now := o.Now
	if now == nil {
		now = time.Now
	}
	mailer := o.Mailer
	if mailer == nil {
		mailer = &mail.SMTP{Host: cfg.SMTPHost, Port: cfg.SMTPPort, Username: cfg.SMTPUsername, Password: cfg.SMTPPassword, From: cfg.MailFrom}
	}

	google := o.Google
	if google == nil && cfg.FirebaseProjectID != "" {
		google = firebase.NewVerifier(cfg.FirebaseProjectID, firebase.NewGoogleKeys(nil), now)
	}

	tokens := auth.NewTokens(cfg.JWTSecret, cfg.AccessTTL, now)
	uniSvc := universities.NewService(d)
	toAccounts := func(u *universities.Summary) *accounts.University {
		if u == nil {
			return nil
		}
		return &accounts.University{ID: u.ID, Slug: u.Slug, Name: u.Name, NameBn: u.NameBn}
	}
	accSvc := accounts.NewService(d, tokens, mailer, accounts.Universities{
		ForEmail: func(ctx context.Context, email string) (*accounts.University, error) {
			u, err := uniSvc.ForEmail(ctx, email)
			return toAccounts(u), err
		},
		Get: func(ctx context.Context, id uuid.UUID) (*accounts.University, error) {
			u, err := uniSvc.Get(ctx, id)
			return toAccounts(u), err
		},
	}, google, accounts.Config{
		CodeSecret: cfg.CodeSecret, CodeTTL: cfg.CodeTTL, ResendAfter: cfg.CodeResendAfter,
		MaxPerHour: cfg.CodeMaxPerHour, MaxAttempts: cfg.CodeMaxAttempts, RefreshTTL: cfg.RefreshTTL,
		LogCodes: !cfg.IsProduction(),
	}, now, log)
	cfgSvc := appconfig.NewService(d)
	groupSvc := classgroups.NewService(d)

	a := &App{Cfg: cfg, Log: log, DB: d, Tokens: tokens, Universities: uniSvc, Accounts: accSvc, Config: cfgSvc, ClassGroups: groupSvc}

	root := chi.NewRouter()
	root.NotFound(httpx.NotFoundHandler)
	root.MethodNotAllowed(httpx.NotFoundHandler)
	root.Route(cfg.APIPrefix, func(api chi.Router) {
		api.NotFound(httpx.NotFoundHandler)
		api.MethodNotAllowed(httpx.NotFoundHandler)
		api.Get("/health", a.health)
		r := httpx.NewRouter(api, tokens, ratelimit.New(now), accSvc.CheckSession)
		uniSvc.Routes(r)
		accSvc.Routes(r)
		cfgSvc.Routes(r)
		groupSvc.Routes(r)
	})

	var h http.Handler = root
	h = httpx.MaxBody(64 << 10)(h)
	h = httpx.SecurityHeaders(h)
	h = httpx.AccessLog(h)
	h = httpx.Recover(h)
	h = httpx.Base(log)(h)
	a.handler = h
	return a
}

// Handler is the root http.Handler.
func (a *App) Handler() http.Handler { return a.handler }

type healthRes struct {
	Status string    `json:"status"`
	DB     string    `json:"db"`
	Time   time.Time `json:"time"`
}

func (a *App) health(w http.ResponseWriter, r *http.Request) {
	ctx, cancel := context.WithTimeout(r.Context(), 2*time.Second)
	defer cancel()
	res := healthRes{Status: "ok", DB: "ok", Time: time.Now().UTC()}
	status := http.StatusOK
	if err := a.DB.Pool.Ping(ctx); err != nil {
		res.Status, res.DB, status = "degraded", "unreachable", http.StatusServiceUnavailable
	}
	httpx.WriteOK(w, r, status, res)
}

// Serve runs the HTTP server and background jobs until ctx is cancelled,
// then lets in-flight requests finish within the shutdown timeout.
func (a *App) Serve(ctx context.Context) error {
	srv := &http.Server{
		Addr:              a.Cfg.Addr,
		Handler:           a.handler,
		ReadHeaderTimeout: 10 * time.Second,
		ReadTimeout:       30 * time.Second,
		WriteTimeout:      30 * time.Second,
		IdleTimeout:       120 * time.Second,
		ErrorLog:          slog.NewLogLogger(a.Log.Handler(), slog.LevelWarn),
	}
	bg, stopBG := context.WithCancel(ctx)
	defer stopBG()
	go a.Accounts.PurgeLoop(bg, time.Hour)

	errc := make(chan error, 1)
	go func() {
		a.Log.Info("campusapi listening", "addr", a.Cfg.Addr, "prefix", a.Cfg.APIPrefix, "env", a.Cfg.Env)
		errc <- srv.ListenAndServe()
	}()
	select {
	case err := <-errc:
		return err
	case <-ctx.Done():
	}
	a.Log.Info("shutting down")
	sctx, cancel := context.WithTimeout(context.Background(), a.Cfg.ShutdownTimeout)
	defer cancel()
	if err := srv.Shutdown(sctx); err != nil && !errors.Is(err, http.ErrServerClosed) {
		return err
	}
	return nil
}
