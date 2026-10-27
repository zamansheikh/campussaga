// Package admin is the superadmin panel's API (campus.silifton.com/admin):
// dashboard numbers, users, universities, class groups, app settings,
// pushes and the audit log. Every route needs a signed-in admin, except
// the two sign-in ones; every change writes an audit_log row.
package admin

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgconn"

	"github.com/zamansheikh/campussaga/backend/internal/modules/admin/store"
	"github.com/zamansheikh/campussaga/backend/internal/platform/auth"
	"github.com/zamansheikh/campussaga/backend/internal/platform/db"
	"github.com/zamansheikh/campussaga/backend/internal/platform/httpx"
)

// SignIn is the port to the accounts module (admin sign-in by email code).
type SignIn struct {
	// RequestCode answers the same whether or not the email is an admin's.
	RequestCode func(ctx context.Context, email string) (any, error)
	// VerifyCode returns the signed-in answer (tokens + user) and the user's id.
	VerifyCode func(ctx context.Context, email, code string) (any, uuid.UUID, error)
}

// PushText is one push in English, optionally Bangla too.
type PushText struct {
	Title, Body, TitleBn, BodyBn string
}

// Pusher sends a push to every phone of the users, in the background.
type Pusher func(userIDs []uuid.UUID, t PushText)

type Service struct {
	d      *db.DB
	signIn SignIn
	push   Pusher
	now    func() time.Time
}

func NewService(d *db.DB, signIn SignIn, push Pusher, now func() time.Time) *Service {
	return &Service{d: d, signIn: signIn, push: push, now: now}
}

// Routes mounts the module's endpoints.
func (s *Service) Routes(r *httpx.Router) {
	r.Public().With(r.Limit("admin-code", 10, time.Hour)).
		Post("/admin/auth/code", httpx.Handle(s.handleRequestCode, httpx.Status(http.StatusAccepted)))
	r.Public().With(r.Limit("admin-verify", 30, time.Hour)).
		Post("/admin/auth/verify", httpx.Handle(s.handleVerify))

	a := r.Admin()
	a.Get("/admin/stats", httpx.Handle(s.handleStats))

	a.Get("/admin/users", httpx.Handle(s.handleListUsers))
	a.Get("/admin/users/{id}", httpx.Handle(s.handleGetUser))
	a.Patch("/admin/users/{id}", httpx.Handle(s.handlePatchUser))
	a.Delete("/admin/users/{id}", httpx.Handle(s.handleDeleteUser, httpx.NoContent()))

	a.Get("/admin/universities", httpx.Handle(s.handleListUniversities))
	a.Post("/admin/universities", httpx.Handle(s.handleCreateUniversity, httpx.Status(http.StatusCreated)))
	a.Patch("/admin/universities/{id}", httpx.Handle(s.handlePatchUniversity))
	a.Put("/admin/universities/{id}/domains", httpx.Handle(s.handleSetDomains))

	a.Get("/admin/groups", httpx.Handle(s.handleListGroups))
	a.Get("/admin/groups/{id}", httpx.Handle(s.handleGetGroup))
	a.Put("/admin/groups/{id}/members/{user}", httpx.Handle(s.handleSetMemberRole, httpx.NoContent()))
	a.Delete("/admin/groups/{id}/members/{user}", httpx.Handle(s.handleRemoveMember, httpx.NoContent()))
	a.Delete("/admin/groups/{id}", httpx.Handle(s.handleDeleteGroup, httpx.NoContent()))

	a.Get("/admin/config", httpx.Handle(s.handleListConfig))
	a.Put("/admin/config/{key}", httpx.Handle(s.handleUpdateConfig))

	a.With(r.LimitUser("admin-push", 30, time.Hour)).
		Post("/admin/push", httpx.Handle(s.handlePush))

	a.Get("/admin/audit", httpx.Handle(s.handleAudit))
}

// ---- shared helpers -----------------------------------------------------------

// Page is the paging query of every list.
type Page struct {
	Page     string `json:"-" query:"page" validate:"omitempty,number,min=1,max=6"`
	PageSize string `json:"-" query:"pageSize" validate:"omitempty,number"`
}

func (p Page) limits() (page, size int, lim, off int32) {
	page, _ = strconv.Atoi(p.Page)
	size, _ = strconv.Atoi(p.PageSize)
	page = max(page, 1)
	if size < 1 {
		size = 25
	}
	size = min(size, 100)
	return page, size, int32(size), int32((page - 1) * size)
}

// Paged is a page of a list.
type Paged[T any] struct {
	Items    []T `json:"items"`
	Total    int `json:"total"`
	Page     int `json:"page"`
	PageSize int `json:"pageSize"`
}

// like turns a search into an ILIKE pattern, matching % and _ literally.
func like(q string) string {
	return "%" + strings.NewReplacer(`\`, `\\`, `%`, `\%`, `_`, `\_`).Replace(q) + "%"
}

// audit writes one audit_log row for the signed-in admin.
func (s *Service) audit(ctx context.Context, q *store.Queries, action, targetType, targetID string, meta any) error {
	c := auth.MustUser(ctx)
	return writeAudit(ctx, q, c.UserID, action, targetType, targetID, meta)
}

func writeAudit(ctx context.Context, q *store.Queries, actor uuid.UUID, action, targetType, targetID string, meta any) error {
	b, err := json.Marshal(meta)
	if err != nil || meta == nil {
		b = []byte("{}")
	}
	return q.InsertAudit(ctx, store.InsertAuditParams{
		ActorID: &actor, Action: action, TargetType: strPtr(targetType), TargetID: strPtr(targetID), Meta: b,
	})
}

func strPtr(s string) *string {
	if s == "" {
		return nil
	}
	return &s
}

// pgError returns the Postgres error under err, if any.
func pgError(err error) (*pgconn.PgError, bool) {
	var pe *pgconn.PgError
	if errors.As(err, &pe) {
		return pe, true
	}
	return nil, false
}

// bdToday is today's date in Bangladesh (UTC+6, no daylight saving).
func bdToday(now time.Time) time.Time {
	t := now.In(time.FixedZone("BDT", 6*3600))
	return time.Date(t.Year(), t.Month(), t.Day(), 0, 0, 0, 0, time.UTC)
}

// ---- sign-in --------------------------------------------------------------------

type codeReq struct {
	Email string `json:"email" validate:"required,email,max=254"`
}

func (s *Service) handleRequestCode(ctx context.Context, in *codeReq) (any, error) {
	return s.signIn.RequestCode(ctx, in.Email)
}

type verifyReq struct {
	Email string `json:"email" validate:"required,email,max=254"`
	Code  string `json:"code" validate:"required,len=6,numeric"`
}

func (s *Service) handleVerify(ctx context.Context, in *verifyReq) (any, error) {
	out, userID, err := s.signIn.VerifyCode(ctx, in.Email, in.Code)
	if err != nil {
		return nil, err
	}
	if err := writeAudit(ctx, store.New(s.d.Q(ctx)), userID, "admin.sign_in", "user", userID.String(),
		map[string]string{"ip": httpx.ClientInfo(ctx).IP}); err != nil {
		httpx.Logger(ctx).Error("admin: audit sign-in", "err", err)
	}
	return out, nil
}
