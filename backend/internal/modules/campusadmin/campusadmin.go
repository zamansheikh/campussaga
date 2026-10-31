// Package campusadmin is campus admins and verification by people
// (docs/CAMPUS_ADMINS.md): trusted students appointed per university who
// verify classmates, settle section problems and moderate their own
// campus, the vouch and CR-confirm ways to get verified without a
// university email, and the central admin's inbox and university health.
//
// Campus admins stay students (a table, not a role). They never see
// students' emails. Queries are plain SQL here because most of them join
// tables of several modules; moderation, blood and domain rules are
// reused through the Ports the app wires.
package campusadmin

import (
	"context"
	"net"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/google/uuid"

	"github.com/zamansheikh/varsitykotha/backend/internal/platform/apperr"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/auth"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/db"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/httpx"
)

// Rules of docs/CAMPUS_ADMINS.md §2.
const (
	VouchesNeeded      = 2
	VouchesPer30Days   = 5
	ConfirmsPer30Days  = 80
	MaxCampusAdmins    = 5
	AutoBlockStudents  = 2  // students unverified ...
	AutoBlockDays      = 90 // ... within this many days
	MinStudentsForNeed = 5  // a university this big needs a campus admin
	LinkBase           = "https://varsitykotha.com/v/"
)

// NoticeText is a push in one language.
type NoticeText struct{ Title, Body string }

// Notice is a push; Texts are keyed by language ("en", "bn").
type Notice struct {
	Texts map[string]NoticeText
	Data  map[string]string
}

// Notifier sends a Notice to students' phones (wired to the push module).
type Notifier func(userIDs []uuid.UUID, n Notice)

// Ports are the other modules' rules a campus admin reuses (wired in app.go).
type Ports struct {
	// Campus Voice moderation scoped to one university.
	Reports        func(ctx context.Context, uni uuid.UUID) (any, error)
	ReportsWaiting func(ctx context.Context, uni uuid.UUID) (int, error)
	Moderate       func(ctx context.Context, uni uuid.UUID, kind string, id uuid.UUID, action string) error
	// Blood requests of one university.
	BloodOpen  func(ctx context.Context, uni uuid.UUID) (any, error)
	BloodClose func(ctx context.Context, uni, id uuid.UUID, reason string) (any, error)
	// AddDomain adds an email domain to a university (admin rules).
	AddDomain func(ctx context.Context, uni uuid.UUID, domain string) error
}

// MXLookup says whether a domain has mail servers.
type MXLookup func(ctx context.Context, domain string) bool

// DNSLookup is the real MX check, with a short timeout.
func DNSLookup(ctx context.Context, domain string) bool {
	ctx, cancel := context.WithTimeout(ctx, 3*time.Second)
	defer cancel()
	mx, err := net.DefaultResolver.LookupMX(ctx, domain)
	return err == nil && len(mx) > 0
}

type Service struct {
	d      *db.DB
	now    func() time.Time
	ports  Ports
	notify Notifier
	mx     MXLookup
	// onVerified runs after a student is verified (invites, docs/GROWTH.md).
	onVerified func(ctx context.Context, id uuid.UUID)
}

// OnVerified sets what runs after a student is verified by CR, vouches or a campus admin.
func (s *Service) OnVerified(f func(ctx context.Context, id uuid.UUID)) { s.onVerified = f }

func NewService(d *db.DB, now func() time.Time, ports Ports) *Service {
	return &Service{d: d, now: now, ports: ports, mx: DNSLookup}
}

// SetNotifier turns pushes on.
func (s *Service) SetNotifier(n Notifier) { s.notify = n }

// SetMXLookup replaces the DNS check (tests).
func (s *Service) SetMXLookup(f MXLookup) {
	if f != nil {
		s.mx = f
	}
}

// Routes mounts the module's endpoints.
func (s *Service) Routes(r *httpx.Router) {
	st := r.Student()
	st.Get("/me/verification", httpx.Handle(s.handleMyVerification))
	st.Get("/vouch/{code}", httpx.Handle(s.handleVouchInfo))
	st.With(r.LimitUser("vouch", 60, time.Hour)).Post("/vouch/{code}", httpx.Handle(s.handleVouch))
	st.Post("/groups/{id}/members/{user}/confirm", httpx.Handle(s.handleConfirm))
	r.Public().With(r.Limit("domain-request", 10, time.Hour)).
		Post("/universities/domain-requests", httpx.Handle(s.handleDomainRequest, httpx.Status(http.StatusAccepted)))

	st.Get("/campus-admin/inbox", httpx.Handle(s.handleCampusInbox))
	st.Get("/campus-admin/students", httpx.Handle(s.handleCampusStudents))
	st.Get("/campus-admin/students/{id}", httpx.Handle(s.handleCampusStudent))
	st.Post("/campus-admin/students/{id}/verify", httpx.Handle(s.handleCampusVerify))
	st.Post("/campus-admin/students/{id}/unverify", httpx.Handle(s.handleCampusUnverify))
	st.Put("/campus-admin/students/{id}/vouch-block", httpx.Handle(s.handleVouchBlock))
	st.Delete("/campus-admin/students/{id}/vouch-block", httpx.Handle(s.handleVouchUnblock))
	st.Get("/campus-admin/sections", httpx.Handle(s.handleSections))
	st.Put("/campus-admin/sections/{id}/cr", httpx.Handle(s.handleSetCR))
	st.Delete("/campus-admin/sections/{id}/cr/{user}", httpx.Handle(s.handleRemoveCR))
	st.Get("/campus-admin/bus-reps", httpx.Handle(s.handleBusReps))
	st.Put("/campus-admin/bus-reps", httpx.Handle(s.handleSetBusRep))
	st.Delete("/campus-admin/bus-reps/{user}", httpx.Handle(s.handleRemoveBusRep, httpx.NoContent()))
	st.Get("/campus-admin/reports", httpx.Handle(s.handleReports))
	st.Post("/campus-admin/reports/{kind}/{id}", httpx.Handle(s.handleReportAction, httpx.NoContent()))
	st.Get("/campus-admin/blood", httpx.Handle(s.handleBlood))
	st.Post("/campus-admin/blood/{id}/close", httpx.Handle(s.handleBloodClose))
	st.Post("/campus-admin/escalations", httpx.Handle(s.handleEscalate, httpx.Status(http.StatusCreated)))

	a := r.Admin()
	a.Get("/admin/campus-admins", httpx.Handle(s.handleListCampusAdmins))
	a.Post("/admin/campus-admins", httpx.Handle(s.handleAddCampusAdmin, httpx.Status(http.StatusCreated)))
	a.Delete("/admin/campus-admins/{user}", httpx.Handle(s.handleRemoveCampusAdmin, httpx.NoContent()))
	a.Get("/admin/inbox", httpx.Handle(s.handleInbox))
	a.Post("/admin/escalations/{id}/resolve", httpx.Handle(s.handleResolveEscalation))
	a.Get("/admin/domain-requests", httpx.Handle(s.handleListDomainRequests))
	a.Post("/admin/domain-requests/{id}/approve", httpx.Handle(s.handleApproveDomain))
	a.Post("/admin/domain-requests/{id}/reject", httpx.Handle(s.handleRejectDomain))
	a.Get("/admin/universities/health", httpx.Handle(s.handleHealth))
}

// Error codes are the wire contract with the app and the panel.
var (
	ErrNotCampusAdmin = apperr.New(http.StatusForbidden, "NOT_CAMPUS_ADMIN", "You are not a campus admin")
	ErrVouchNotFound  = apperr.New(http.StatusNotFound, "VOUCH_NOT_FOUND", "This link is not valid")
	ErrVouchSelf      = apperr.New(http.StatusConflict, "VOUCH_SELF", "You can't vouch for yourself")
	ErrVerifyFirst    = apperr.New(http.StatusForbidden, "VERIFY_YOURSELF_FIRST", "Get verified yourself first")
	ErrOtherUni       = apperr.New(http.StatusForbidden, "OTHER_UNIVERSITY", "This student is at another university")
	ErrVouchBlocked   = apperr.New(http.StatusForbidden, "VOUCH_BLOCKED", "You can't verify other students")
	ErrVouchLimit     = apperr.New(http.StatusTooManyRequests, "VOUCH_LIMIT", "You have vouched the most times allowed for now")
	ErrConfirmLimit   = apperr.New(http.StatusTooManyRequests, "CONFIRM_LIMIT", "You have confirmed the most students allowed for now")
	ErrAlreadyVerif   = apperr.New(http.StatusConflict, "ALREADY_VERIFIED", "This student is already verified")
	ErrNotVerified    = apperr.New(http.StatusConflict, "NOT_VERIFIED", "This student is not verified")
	ErrEmailVerified  = apperr.New(http.StatusConflict, "EMAIL_VERIFIED", "This student proved a university email. Only the VarsityKotha team can change it")
	ErrAdminVerified  = apperr.New(http.StatusConflict, "ADMIN_VERIFIED", "The VarsityKotha team verified this student. Only the team can change it")
	ErrNotCR          = apperr.New(http.StatusForbidden, "NOT_CR", "Only a CR of this section can confirm students")
	ErrUserNotFound   = apperr.New(http.StatusNotFound, "USER_NOT_FOUND", "No such student")
	ErrGroupNotFound  = apperr.New(http.StatusNotFound, "GROUP_NOT_FOUND", "No such section")
	ErrMemberNotFound = apperr.New(http.StatusNotFound, "MEMBER_NOT_FOUND", "This student is not in the section")
	ErrLastCR         = apperr.New(http.StatusConflict, "LAST_CR", "A section always keeps one CR. Make someone else CR first")
	ErrCRLimit        = apperr.New(http.StatusConflict, "CR_LIMIT_REACHED", "A section can have at most 3 CRs")
	ErrNotACR         = apperr.New(http.StatusNotFound, "CR_NOT_FOUND", "This student is not a CR of the section")
	ErrRepNotFound    = apperr.New(http.StatusNotFound, "REP_NOT_FOUND", "This student is not a bus rep of your university")
	ErrAdminLimit     = apperr.New(http.StatusConflict, "CAMPUS_ADMIN_LIMIT", "A university can have at most 5 campus admins")
	ErrAdminNotFound  = apperr.New(http.StatusNotFound, "CAMPUS_ADMIN_NOT_FOUND", "This student is not a campus admin")
	ErrEscalationGone = apperr.New(http.StatusNotFound, "ESCALATION_NOT_FOUND", "No such escalation")
	ErrEscalationDone = apperr.New(http.StatusConflict, "ESCALATION_RESOLVED", "This escalation is already resolved")
	ErrDomainReqGone  = apperr.New(http.StatusNotFound, "DOMAIN_REQUEST_NOT_FOUND", "No such domain request")
	ErrDomainReqDone  = apperr.New(http.StatusConflict, "DOMAIN_REQUEST_DECIDED", "This request is already decided")
	ErrUniNotFound    = apperr.New(http.StatusNotFound, "UNIVERSITY_NOT_FOUND", "No such university")
	ErrBadAction      = apperr.New(http.StatusUnprocessableEntity, "BAD_ACTION", "This action is not allowed here")
)

// ---- shared helpers ------------------------------------------------------------

// Page is the paging query of every list.
type Page struct {
	Page     string `json:"-" query:"page" validate:"omitempty,number,min=1,max=6"`
	PageSize string `json:"-" query:"pageSize" validate:"omitempty,number"`
}

func (p Page) limits() (page, size int) {
	page, _ = strconv.Atoi(p.Page)
	size, _ = strconv.Atoi(p.PageSize)
	page = max(page, 1)
	if size < 1 {
		size = 25
	}
	return page, min(size, 100)
}

// Paged is a page of a list.
type Paged[T any] struct {
	Items    []T `json:"items"`
	Total    int `json:"total"`
	Page     int `json:"page"`
	PageSize int `json:"pageSize"`
}

// Ref is a short id and name.
type Ref struct {
	ID   uuid.UUID `json:"id"`
	Name string    `json:"name"`
}

func like(q string) string {
	return "%" + strings.NewReplacer(`\`, `\\`, `%`, `\%`, `_`, `\_`).Replace(q) + "%"
}

// audit writes one audit_log row for the signed-in user.
func (s *Service) audit(ctx context.Context, action, targetType, targetID string, meta any) error {
	return writeAudit(ctx, s.d.Q(ctx), auth.MustUser(ctx).UserID, action, targetType, targetID, meta)
}

// who is the signed-in student's row.
type who struct {
	ID       uuid.UUID
	Uni      *uuid.UUID
	Verified bool
	Name     string
}

func (s *Service) caller(ctx context.Context) (who, error) {
	w := who{ID: auth.MustUser(ctx).UserID}
	err := s.d.Q(ctx).QueryRow(ctx,
		`SELECT university_id, verified_at IS NOT NULL, coalesce(display_name, '') FROM users WHERE id = $1`, w.ID).
		Scan(&w.Uni, &w.Verified, &w.Name)
	if db.IsNoRows(err) {
		return w, ErrUserNotFound
	}
	return w, err
}

// campusAdmin returns the caller's university, or NOT_CAMPUS_ADMIN. The
// appointment only counts while they are verified at that university.
func (s *Service) campusAdmin(ctx context.Context) (uuid.UUID, error) {
	var uni uuid.UUID
	err := s.d.Q(ctx).QueryRow(ctx, `
		SELECT c.university_id FROM campus_admins c JOIN users u ON u.id = c.user_id
		WHERE c.user_id = $1 AND u.university_id = c.university_id AND u.verified_at IS NOT NULL`,
		auth.MustUser(ctx).UserID).Scan(&uni)
	if db.IsNoRows(err) {
		return uuid.Nil, ErrNotCampusAdmin
	}
	return uni, err
}

func (s *Service) uniName(ctx context.Context, id uuid.UUID) (string, error) {
	var name string
	err := s.d.Q(ctx).QueryRow(ctx, `SELECT name FROM universities WHERE id = $1`, id).Scan(&name)
	return name, err
}

func parseID(s string) (uuid.UUID, error) {
	id, err := uuid.Parse(s)
	if err != nil {
		return uuid.Nil, apperr.Validation(map[string]string{"id": "must be a valid UUID"})
	}
	return id, nil
}
