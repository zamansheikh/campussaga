// Package migrations embeds every SQL migration and applies them in one
// idempotent step (`campusapi migrate`, or at start-up in development).
//
// Files are goose-format (-- +goose Up / -- +goose Down). Never edit a
// migration that has shipped; add a new one. Version ranges:
// 00001-00099 platform, 00100 universities, 00200 accounts, 00300 app config,
// 01000+ My Class (R1), 02000+ Campus Voice (R2).
package migrations

import (
	"context"
	"embed"
	"fmt"
	"log/slog"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/jackc/pgx/v5/stdlib"
	"github.com/pressly/goose/v3"
)

//go:embed *.sql
var FS embed.FS

// Up applies all pending migrations.
func Up(ctx context.Context, pool *pgxpool.Pool, log *slog.Logger) error {
	sqlDB := stdlib.OpenDBFromPool(pool)
	defer sqlDB.Close()
	// Out-of-order is allowed because each area owns a version range
	// (a new 00110 file may arrive after 00300 was applied).
	provider, err := goose.NewProvider(goose.DialectPostgres, sqlDB, FS,
		goose.WithAllowOutofOrder(true),
	)
	if err != nil {
		return fmt.Errorf("migrations: provider: %w", err)
	}
	results, err := provider.Up(ctx)
	if err != nil {
		return fmt.Errorf("migrations: up: %w", err)
	}
	for _, r := range results {
		if log != nil {
			log.Info("migration applied", "version", r.Source.Version, "file", r.Source.Path, "took", r.Duration)
		}
	}
	return nil
}
