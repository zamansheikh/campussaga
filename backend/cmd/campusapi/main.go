// Command campusapi runs the VarsityKotha API.
//
//	campusapi            serve (development: applies migrations first)
//	campusapi serve      same
//	campusapi migrate    apply pending migrations and exit (production deploys)
package main

import (
	"context"
	"fmt"
	"log/slog"
	"os"
	"os/signal"
	"syscall"

	"github.com/zamansheikh/varsitykotha/backend/internal/app"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/config"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/db"
	"github.com/zamansheikh/varsitykotha/backend/migrations"
)

func main() {
	if err := run(); err != nil {
		fmt.Fprintln(os.Stderr, "campusapi:", err)
		os.Exit(1)
	}
}

func run() error {
	cmd := "serve"
	if len(os.Args) > 1 {
		cmd = os.Args[1]
	}
	cfg, err := config.Load()
	if err != nil {
		return err
	}
	log := newLogger(cfg)
	slog.SetDefault(log)

	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	d, err := db.Open(ctx, cfg.DatabaseURL, cfg.DBMaxConns)
	if err != nil {
		return err
	}
	defer d.Close()

	switch cmd {
	case "migrate":
		return migrations.Up(ctx, d.Pool, log)
	case "serve":
		if !cfg.IsProduction() {
			if err := migrations.Up(ctx, d.Pool, log); err != nil {
				return err
			}
		}
		return app.New(cfg, log, d).Serve(ctx)
	default:
		return fmt.Errorf("unknown command %q (serve | migrate)", cmd)
	}
}

func newLogger(cfg *config.Config) *slog.Logger {
	if cfg.IsProduction() {
		return slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{Level: slog.LevelInfo}))
	}
	return slog.New(slog.NewTextHandler(os.Stdout, &slog.HandlerOptions{Level: slog.LevelDebug}))
}
