// Package testkit gives every test real infrastructure, isolated: a fresh
// Postgres DATABASE per test, cloned in milliseconds from a template that has
// all migrations applied (the template name is a hash of the migration files,
// so editing a migration rebuilds it automatically).
//
// Requirements: `make deps-up` (docker compose Postgres :55632) or
// TEST_DATABASE_URL pointing elsewhere. Tests FAIL (not skip) when the
// database is missing: a silently skipped security test is worse than a red
// build.
package testkit

import (
	"context"
	"crypto/rand"
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"io/fs"
	"net/url"
	"os"
	"sort"
	"strings"
	"sync"
	"testing"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/zamansheikh/campussaga/backend/internal/platform/db"
	"github.com/zamansheikh/campussaga/backend/migrations"
)

const defaultPG = "postgres://campus:campus@localhost:55632/campus?sslmode=disable"

func pgURL() string {
	if v := os.Getenv("TEST_DATABASE_URL"); v != "" {
		return v
	}
	return defaultPG
}

func withDatabase(raw, name string) string {
	u, err := url.Parse(raw)
	if err != nil {
		panic(err)
	}
	u.Path = "/" + name
	return u.String()
}

var (
	templateOnce sync.Once
	templateName string
	templateErr  error
)

// migrationsHash fingerprints every migration file.
func migrationsHash() (string, error) {
	h := sha256.New()
	var names []string
	err := fs.WalkDir(migrations.FS, ".", func(p string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if !d.IsDir() && strings.HasSuffix(p, ".sql") {
			names = append(names, p)
		}
		return nil
	})
	if err != nil {
		return "", err
	}
	sort.Strings(names)
	for _, n := range names {
		b, err := fs.ReadFile(migrations.FS, n)
		if err != nil {
			return "", err
		}
		h.Write([]byte(n))
		h.Write(b)
	}
	return hex.EncodeToString(h.Sum(nil))[:16], nil
}

func ensureTemplate(ctx context.Context) (string, error) {
	templateOnce.Do(func() {
		hash, err := migrationsHash()
		if err != nil {
			templateErr = err
			return
		}
		name := "tmpl_" + hash
		admin, err := pgx.Connect(ctx, pgURL())
		if err != nil {
			templateErr = fmt.Errorf("testkit: cannot reach Postgres at %s (run `make deps-up` in backend/): %w", pgURL(), err)
			return
		}
		defer admin.Close(ctx)
		// Serialise template creation across parallel `go test` processes.
		if _, err := admin.Exec(ctx, `SELECT pg_advisory_lock(424242)`); err != nil {
			templateErr = err
			return
		}
		defer admin.Exec(context.Background(), `SELECT pg_advisory_unlock(424242)`) //nolint:errcheck

		var exists bool
		if err := admin.QueryRow(ctx,
			`SELECT EXISTS (SELECT 1 FROM pg_database WHERE datname = $1 AND datistemplate)`, name).Scan(&exists); err != nil {
			templateErr = err
			return
		}
		if !exists {
			build := name + "_build"
			_, _ = admin.Exec(ctx, `DROP DATABASE IF EXISTS `+build+` WITH (FORCE)`)
			if _, err := admin.Exec(ctx, `CREATE DATABASE `+build); err != nil {
				templateErr = err
				return
			}
			pool, err := pgxpool.New(ctx, withDatabase(pgURL(), build))
			if err != nil {
				templateErr = err
				return
			}
			err = migrations.Up(ctx, pool, nil)
			pool.Close()
			if err != nil {
				templateErr = fmt.Errorf("testkit: migrations failed: %w", err)
				return
			}
			// Atomic publish: rename + mark as template only after success.
			if _, err := admin.Exec(ctx, `ALTER DATABASE `+build+` RENAME TO `+name); err != nil {
				templateErr = err
				return
			}
			if _, err := admin.Exec(ctx, `ALTER DATABASE `+name+` WITH IS_TEMPLATE true`); err != nil {
				templateErr = err
				return
			}
		}
		templateName = name
	})
	return templateName, templateErr
}

func randomSuffix() string {
	var b [6]byte
	_, _ = rand.Read(b[:])
	return hex.EncodeToString(b[:])
}

// NewDB returns a pool on a brand-new, fully migrated database that is
// dropped when the test ends.
func NewDB(t testing.TB) *db.DB {
	t.Helper()
	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Minute)
	defer cancel()
	tmpl, err := ensureTemplate(ctx)
	if err != nil {
		t.Fatalf("%v", err)
	}
	name := "t_" + randomSuffix()
	admin, err := pgx.Connect(ctx, pgURL())
	if err != nil {
		t.Fatalf("testkit: connect: %v", err)
	}
	defer admin.Close(ctx)
	for attempt := 0; ; attempt++ {
		_, err = admin.Exec(ctx, `CREATE DATABASE `+name+` TEMPLATE `+tmpl)
		if err == nil || attempt == 20 || !strings.Contains(err.Error(), "being accessed by other users") {
			break
		}
		time.Sleep(50 * time.Millisecond)
	}
	if err != nil {
		t.Fatalf("testkit: create database: %v", err)
	}
	cfg, err := pgxpool.ParseConfig(withDatabase(pgURL(), name))
	if err != nil {
		t.Fatalf("testkit: %v", err)
	}
	cfg.MaxConns = 8 // several test packages share one Postgres (max_connections=300)
	cfg.ConnConfig.RuntimeParams["timezone"] = "UTC"
	pool, err := pgxpool.NewWithConfig(ctx, cfg)
	if err != nil {
		t.Fatalf("testkit: pool: %v", err)
	}
	t.Cleanup(func() {
		pool.Close()
		c, err := pgx.Connect(context.Background(), pgURL())
		if err != nil {
			return
		}
		defer c.Close(context.Background())
		_, _ = c.Exec(context.Background(), `DROP DATABASE IF EXISTS `+name+` WITH (FORCE)`)
	})
	return db.New(pool)
}
