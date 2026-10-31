// Package app wires the process: database, mailer, router and the modules
// mounted on it. Modules never import each other; this file connects them.
package app

import (
	"cmp"
	"context"
	"errors"
	"log/slog"
	"net/http"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"

	"github.com/zamansheikh/varsitykotha/backend/internal/modules/accounts"
	"github.com/zamansheikh/varsitykotha/backend/internal/modules/admin"
	"github.com/zamansheikh/varsitykotha/backend/internal/modules/appconfig"
	"github.com/zamansheikh/varsitykotha/backend/internal/modules/blood"
	"github.com/zamansheikh/varsitykotha/backend/internal/modules/classgroups"
	"github.com/zamansheikh/varsitykotha/backend/internal/modules/photos"
	"github.com/zamansheikh/varsitykotha/backend/internal/modules/push"
	"github.com/zamansheikh/varsitykotha/backend/internal/modules/transport"
	"github.com/zamansheikh/varsitykotha/backend/internal/modules/universities"
	"github.com/zamansheikh/varsitykotha/backend/internal/modules/voice"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/auth"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/config"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/db"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/firebase"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/httpx"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/mail"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/media"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/ratelimit"
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
	Push         *push.Service
	Voice        *voice.Service
	Blood        *blood.Service

	handler http.Handler
}

// Options tune the assembly (tests).
type Options struct {
	Now    func() time.Time        // clock; nil = time.Now
	Mailer mail.Sender             // nil = SMTP from config
	Google accounts.GoogleVerifier // nil = Firebase verifier from config (if configured)
	Push   push.Sender             // nil = FCM from config, or log only
	Media  media.Store             // nil = a directory at cfg.MediaDir
	// PhotoChecker replaces the backend/nsfw service (tests).
	PhotoChecker voice.PhotoChecker
	// RoadRouter replaces OSRM for bus route paths (tests).
	RoadRouter transport.RoadRouter
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
		return &accounts.University{ID: u.ID, Slug: u.Slug, Name: u.Name, NameBn: u.NameBn, City: u.City, Domains: u.Domains, IsDemo: u.IsDemo}
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
		LogCodes:    !cfg.IsProduction(),
		ReviewEmail: cfg.ReviewEmail, ReviewCode: cfg.ReviewCode,
	}, now, log)
	cfgSvc := appconfig.NewService(d)
	groupSvc := classgroups.NewService(d, now)
	sender := o.Push
	if sender == nil {
		sender = push.LogSender{Log: log}
		if cfg.FCMCredentialsFile != "" {
			fcm, err := push.NewFCMFromFile(cfg.FCMCredentialsFile, now)
			if err != nil {
				log.Error("push: notifications only logged", "err", err)
			} else {
				sender = fcm
			}
		}
	}
	pushSvc := push.NewService(d, sender, log)
	groupSvc.SetNotifier(func(userIDs []uuid.UUID, n classgroups.Notice) {
		texts := make(map[string]push.Text, len(n.Texts))
		for lang, t := range n.Texts {
			texts[lang] = push.Text{Title: t.Title, Body: t.Body}
		}
		pushSvc.Notify(userIDs, push.Message{Texts: texts, Data: n.Data})
	})

	adminSvc := admin.NewService(d, admin.SignIn{
		RequestCode: func(ctx context.Context, email string) (any, error) {
			return accSvc.RequestAdminCode(ctx, email)
		},
		VerifyCode: func(ctx context.Context, email, code string) (any, uuid.UUID, error) {
			out, err := accSvc.VerifyAdminCode(ctx, email, code)
			if err != nil {
				return nil, uuid.Nil, err
			}
			return out, out.User.ID, nil
		},
	}, func(userIDs []uuid.UUID, t admin.PushText) {
		texts := map[string]push.Text{"en": {Title: t.Title, Body: t.Body}}
		if t.TitleBn != "" || t.BodyBn != "" {
			texts["bn"] = push.Text{Title: cmp.Or(t.TitleBn, t.Title), Body: cmp.Or(t.BodyBn, t.Body)}
		}
		pushSvc.Notify(userIDs, push.Message{Texts: texts, Data: map[string]string{"type": "admin"}})
	}, now)

	store := o.Media
	if store == nil && cfg.NimbusAPIKey != "" {
		store = media.NewNimbus(cfg.NimbusURL, cfg.NimbusAPIKey, cfg.NimbusPrefix)
		log.Info("media: photos on Nimbus", "prefix", cfg.NimbusPrefix)
	}
	if store == nil {
		disk, err := media.NewDisk(cmp.Or(cfg.MediaDir, "tmp/media"))
		if err != nil {
			log.Error("media: can't open the photo directory", "err", err)
		} else {
			store = disk
		}
	}
	voiceSvc := voice.NewService(d, store, cfg.VoiceHMACSecret, now, log)
	roads := o.RoadRouter
	if roads == nil && cfg.RoadRouterURL != "" && cfg.RoadRouterURL != "off" {
		roads = transport.NewOSRM(cfg.RoadRouterURL)
	}
	checker := o.PhotoChecker
	if checker == nil && cfg.NSFWURL != "" {
		checker = voice.NewHTTPChecker(cfg.NSFWURL)
	}
	if checker == nil && cfg.IsProduction() {
		log.Warn("voice: NSFW_URL not set; photos are held for moderators until the photo check runs")
	}
	photoSvc := photos.NewService(d, store, photos.Check{
		Scorer: checker, Max: cmp.Or(cfg.NSFWHold, 0.70), Required: cfg.IsProduction(),
	}, func(ctx context.Context) (any, error) { return accSvc.GetMe(ctx) }, log)
	accSvc.OnPhotoGone(photoSvc.Remove)
	adminSvc.OnPhotoGone(photoSvc.Remove)
	voiceSvc.SetPhotoCheck(voice.PhotoCheck{
		Checker: checker, Reject: cmp.Or(cfg.NSFWReject, 0.98), Hold: cmp.Or(cfg.NSFWHold, 0.70),
		Required: cfg.IsProduction(),
	})
	voiceSvc.SetNotifier(func(userIDs []uuid.UUID, n voice.Notice) {
		texts := make(map[string]push.Text, len(n.Texts))
		for lang, t := range n.Texts {
			texts[lang] = push.Text{Title: t.Title, Body: t.Body}
		}
		pushSvc.Notify(userIDs, push.Message{Texts: texts, Data: n.Data})
	})

	bloodSvc := blood.NewService(d, now)
	bloodSvc.SetNotifier(func(userIDs []uuid.UUID, n blood.Notice) {
		texts := make(map[string]push.Text, len(n.Texts))
		for lang, t := range n.Texts {
			texts[lang] = push.Text{Title: t.Title, Body: t.Body}
		}
		pushSvc.Notify(userIDs, push.Message{Texts: texts, Data: n.Data})
	})

	a := &App{Cfg: cfg, Log: log, DB: d, Tokens: tokens, Universities: uniSvc, Accounts: accSvc, Config: cfgSvc, ClassGroups: groupSvc, Push: pushSvc, Voice: voiceSvc, Blood: bloodSvc}

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
		pushSvc.Routes(r)
		adminSvc.Routes(r)
		voiceSvc.Routes(r)
		transport.NewService(d, now, roads, log).Routes(r)
		bloodSvc.Routes(r)
		photoSvc.Routes(r)
	})

	var h http.Handler = root
	h = httpx.MaxBody(64<<10, map[string]int64{
		cfg.APIPrefix + "/uploads":  voice.UploadLimit,
		cfg.APIPrefix + "/me/photo": photos.UploadLimit,
	})(h)
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
	go a.Voice.CleanupLoop(bg, time.Hour)

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
	a.Push.Wait() // let notifications already queued go out
	return nil
}
