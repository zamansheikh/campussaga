// Package db owns the Postgres pool and the transaction model.
//
//   - A transaction travels in the context. db.InTx(ctx, fn) starts one (or
//     joins the one already in ctx) and hands fn a ctx that carries it.
//   - Stores never take a tx parameter. They call d.Q(ctx), which returns
//     the ctx's tx if present, else the pool, so the same store code runs
//     standalone or inside a bigger unit of work.
//   - Side effects that must only happen if the tx commits (push, cache
//     invalidation) are registered with db.AfterCommit(ctx, fn).
//   - The outermost InTx retries fn on serialization failures and deadlocks,
//     so fn must not have side effects other than DB writes and AfterCommit
//     hooks (discarded on each failed attempt).
package db

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
)

// Querier is satisfied by *pgxpool.Pool and pgx.Tx; it is the DBTX
// interface sqlc generates, so d.Q(ctx) can be passed to store.New().
type Querier interface {
	Exec(ctx context.Context, sql string, args ...any) (pgconn.CommandTag, error)
	Query(ctx context.Context, sql string, args ...any) (pgx.Rows, error)
	QueryRow(ctx context.Context, sql string, args ...any) pgx.Row
}

// DB wraps the pool.
type DB struct {
	Pool *pgxpool.Pool
}

// Open connects and pings.
func Open(ctx context.Context, url string, maxConns int32) (*DB, error) {
	pc, err := pgxpool.ParseConfig(url)
	if err != nil {
		return nil, fmt.Errorf("db: parse url: %w", err)
	}
	pc.MaxConns = maxConns
	pc.MaxConnLifetime = 30 * time.Minute
	pc.ConnConfig.RuntimeParams["timezone"] = "UTC"
	pool, err := pgxpool.NewWithConfig(ctx, pc)
	if err != nil {
		return nil, fmt.Errorf("db: connect: %w", err)
	}
	pingCtx, cancel := context.WithTimeout(ctx, 10*time.Second)
	defer cancel()
	if err := pool.Ping(pingCtx); err != nil {
		pool.Close()
		return nil, fmt.Errorf("db: ping: %w", err)
	}
	return &DB{Pool: pool}, nil
}

// New wraps an existing pool (tests).
func New(pool *pgxpool.Pool) *DB { return &DB{Pool: pool} }

func (d *DB) Close() { d.Pool.Close() }

type txKey struct{}

type txState struct {
	tx          pgx.Tx
	afterCommit []func(context.Context)
}

// Q returns the transaction in ctx, or the pool.
func (d *DB) Q(ctx context.Context) Querier {
	if st, ok := ctx.Value(txKey{}).(*txState); ok {
		return st.tx
	}
	return d.Pool
}

// InTransaction reports whether ctx carries a transaction.
func InTransaction(ctx context.Context) bool {
	_, ok := ctx.Value(txKey{}).(*txState)
	return ok
}

// AfterCommit schedules fn to run after the ctx's transaction commits.
// Without a transaction it runs fn immediately.
func AfterCommit(ctx context.Context, fn func(context.Context)) {
	if st, ok := ctx.Value(txKey{}).(*txState); ok {
		st.afterCommit = append(st.afterCommit, fn)
		return
	}
	fn(context.WithoutCancel(ctx))
}

const maxTxAttempts = 4

// InTx runs fn inside a transaction. Nested calls join the outer one.
func (d *DB) InTx(ctx context.Context, fn func(ctx context.Context) error) error {
	if InTransaction(ctx) {
		return fn(ctx)
	}
	var err error
	for attempt := 1; attempt <= maxTxAttempts; attempt++ {
		var hooks []func(context.Context)
		hooks, err = d.runOnce(ctx, fn)
		if err == nil {
			detached := context.WithoutCancel(ctx)
			for _, h := range hooks {
				h(detached)
			}
			return nil
		}
		if !IsRetryable(err) || ctx.Err() != nil {
			return err
		}
		time.Sleep(time.Duration(attempt*attempt) * 5 * time.Millisecond)
	}
	return err
}

func (d *DB) runOnce(ctx context.Context, fn func(ctx context.Context) error) (hooks []func(context.Context), err error) {
	tx, err := d.Pool.Begin(ctx)
	if err != nil {
		return nil, fmt.Errorf("db: begin: %w", err)
	}
	st := &txState{tx: tx}
	defer func() {
		if p := recover(); p != nil {
			_ = tx.Rollback(context.WithoutCancel(ctx))
			panic(p)
		}
	}()
	if err := fn(context.WithValue(ctx, txKey{}, st)); err != nil {
		_ = tx.Rollback(context.WithoutCancel(ctx))
		return nil, err
	}
	if err := tx.Commit(ctx); err != nil {
		return nil, fmt.Errorf("db: commit: %w", err)
	}
	return st.afterCommit, nil
}

// Postgres error codes the codebase branches on.
const (
	CodeUniqueViolation      = "23505"
	CodeSerializationFailure = "40001"
	CodeDeadlockDetected     = "40P01"
)

// PgCode returns the SQLSTATE of err, or "".
func PgCode(err error) string {
	var pe *pgconn.PgError
	if errors.As(err, &pe) {
		return pe.Code
	}
	return ""
}

// IsUniqueViolation optionally checks the constraint name too.
func IsUniqueViolation(err error, constraint ...string) bool {
	var pe *pgconn.PgError
	if !errors.As(err, &pe) || pe.Code != CodeUniqueViolation {
		return false
	}
	return len(constraint) == 0 || pe.ConstraintName == constraint[0]
}

// IsRetryable reports serialization failures and deadlocks.
func IsRetryable(err error) bool {
	c := PgCode(err)
	return c == CodeSerializationFailure || c == CodeDeadlockDetected
}

// IsNoRows reports pgx.ErrNoRows.
func IsNoRows(err error) bool { return errors.Is(err, pgx.ErrNoRows) }
