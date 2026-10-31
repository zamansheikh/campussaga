package campusadmin

import (
	"context"
	"net/mail"
	"strings"
	"time"

	"github.com/google/uuid"

	"github.com/zamansheikh/varsitykotha/backend/internal/platform/apperr"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/auth"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/db"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/httpx"
)

// ---- campus admins (central admin) ---------------------------------------------------------

type adminUser struct {
	ID    uuid.UUID `json:"id"`
	Name  string    `json:"name"`
	Email string    `json:"email"`
}

type CampusAdminItem struct {
	User        adminUser `json:"user"`
	University  Ref       `json:"university"`
	AppointedAt time.Time `json:"appointedAt"`
}

type listAdminsReq struct {
	UniversityID string `json:"-" query:"universityId" validate:"omitempty,uuid"`
}

func (s *Service) campusAdminItems(ctx context.Context, uni *uuid.UUID, user *uuid.UUID) ([]CampusAdminItem, error) {
	rows, err := s.d.Q(ctx).Query(ctx, `
		SELECT u.id, coalesce(u.display_name, ''), u.email, un.id, un.name, c.created_at
		FROM campus_admins c JOIN users u ON u.id = c.user_id JOIN universities un ON un.id = c.university_id
		WHERE ($1::uuid IS NULL OR c.university_id = $1) AND ($2::uuid IS NULL OR c.user_id = $2)
		ORDER BY un.name, c.created_at`, uni, user)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []CampusAdminItem{}
	for rows.Next() {
		var it CampusAdminItem
		if err := rows.Scan(&it.User.ID, &it.User.Name, &it.User.Email, &it.University.ID, &it.University.Name, &it.AppointedAt); err != nil {
			return nil, err
		}
		out = append(out, it)
	}
	return out, rows.Err()
}

func (s *Service) handleListCampusAdmins(ctx context.Context, in *listAdminsReq) ([]CampusAdminItem, error) {
	var uni *uuid.UUID
	if in.UniversityID != "" {
		u := uuid.MustParse(in.UniversityID)
		uni = &u
	}
	return s.campusAdminItems(ctx, uni, nil)
}

type addAdminReq struct {
	UserID string `json:"userId" validate:"required,uuid"`
}

func (s *Service) handleAddCampusAdmin(ctx context.Context, in *addAdminReq) (*CampusAdminItem, error) {
	user := uuid.MustParse(in.UserID)
	err := s.d.InTx(ctx, func(ctx context.Context) error {
		st, err := s.lockStudent(ctx, user)
		if err != nil {
			return err
		}
		if !st.Verified || st.Uni == nil {
			return ErrNotVerified
		}
		q := s.d.Q(ctx)
		var exists bool
		if err := q.QueryRow(ctx, `SELECT EXISTS (SELECT 1 FROM campus_admins WHERE user_id = $1 AND university_id = $2)`, user, *st.Uni).Scan(&exists); err != nil {
			return err
		}
		if exists {
			return nil
		}
		// One campus per person: a leftover appointment at another university goes.
		if _, err := q.Exec(ctx, `DELETE FROM campus_admins WHERE user_id = $1`, user); err != nil {
			return err
		}
		if _, err := q.Exec(ctx, `SELECT 1 FROM universities WHERE id = $1 FOR UPDATE`, *st.Uni); err != nil {
			return err
		}
		var n int
		if err := q.QueryRow(ctx, `SELECT count(*)::int FROM campus_admins WHERE university_id = $1`, *st.Uni).Scan(&n); err != nil {
			return err
		}
		if n >= MaxCampusAdmins {
			return ErrAdminLimit
		}
		if _, err := q.Exec(ctx, `INSERT INTO campus_admins (user_id, university_id, appointed_by, created_at) VALUES ($1, $2, $3, $4)`,
			user, *st.Uni, auth.MustUser(ctx).UserID, s.now()); err != nil {
			return err
		}
		return s.audit(ctx, "admin.campus_admin.add", "user", user.String(), map[string]any{"universityId": *st.Uni})
	})
	if err != nil {
		return nil, err
	}
	items, err := s.campusAdminItems(ctx, nil, &user)
	if err != nil || len(items) == 0 {
		return nil, err
	}
	return &items[0], nil
}

func (s *Service) handleRemoveCampusAdmin(ctx context.Context, in *userPath) (*httpx.Empty, error) {
	user := uuid.MustParse(in.User)
	return nil, s.d.InTx(ctx, func(ctx context.Context) error {
		tag, err := s.d.Q(ctx).Exec(ctx, `DELETE FROM campus_admins WHERE user_id = $1`, user)
		if err != nil {
			return err
		}
		if tag.RowsAffected() == 0 {
			return ErrAdminNotFound
		}
		return s.audit(ctx, "admin.campus_admin.remove", "user", user.String(), nil)
	})
}

// ---- domain requests ----------------------------------------------------------------------

type DomainRequest struct {
	ID             uuid.UUID  `json:"id"`
	Domain         string     `json:"domain"`
	Email          string     `json:"email"`
	University     *Ref       `json:"university"`
	UniversityName string     `json:"universityName"`
	Requester      *Ref       `json:"requester"`
	MXOk           bool       `json:"mxOk"`
	CreatedAt      time.Time  `json:"createdAt"`
	Status         string     `json:"status"`
	DecidedAt      *time.Time `json:"decidedAt"`
}

type domainReq struct {
	Email          string `json:"email" validate:"required,email,max=254"`
	UniversityID   string `json:"universityId" validate:"omitempty,uuid"`
	UniversityName string `json:"universityName" validate:"max=120"`
}

type accepted struct {
	Received bool `json:"received"`
}

func (s *Service) handleDomainRequest(ctx context.Context, in *domainReq) (*accepted, error) {
	addr, err := mail.ParseAddress(strings.TrimSpace(in.Email))
	if err != nil || !strings.Contains(addr.Address, "@") {
		return nil, apperr.Validation(map[string]string{"email": "must be a valid email"})
	}
	email := strings.ToLower(addr.Address)
	domain := email[strings.LastIndex(email, "@")+1:]
	if !strings.Contains(domain, ".") {
		return nil, apperr.Validation(map[string]string{"email": "must be a valid email"})
	}
	var uni *uuid.UUID
	if in.UniversityID != "" {
		u := uuid.MustParse(in.UniversityID)
		var ok bool
		if err := s.d.Q(ctx).QueryRow(ctx, `SELECT EXISTS (SELECT 1 FROM universities WHERE id = $1)`, u).Scan(&ok); err != nil {
			return nil, err
		}
		if !ok {
			return nil, ErrUniNotFound
		}
		uni = &u
	}
	mxOK := s.mx(ctx, domain)
	// A signed-in requester is noted when the app sends its token.
	var requester *uuid.UUID
	if c, ok := auth.User(ctx); ok {
		requester = &c.UserID
	}
	name := strings.Join(strings.Fields(in.UniversityName), " ")
	_, err = s.d.Q(ctx).Exec(ctx, `
		INSERT INTO domain_requests (domain, email, university_id, university_name, requester_id, mx_ok, created_at)
		SELECT $1, $2, $3, $4, $5, $6, $7
		WHERE NOT EXISTS (SELECT 1 FROM domain_requests WHERE status = 'open' AND email = $2)`,
		domain, email, uni, name, requester, mxOK, s.now())
	return &accepted{Received: true}, err
}

const domainCols = `r.id, r.domain, r.email, un.id, un.name, r.university_name, ru.id, coalesce(ru.display_name, ''), r.mx_ok,
	r.created_at, r.status, r.decided_at`

func scanDomainRequest(r scanner) (DomainRequest, error) {
	var d DomainRequest
	var uid, rid *uuid.UUID
	var uname *string
	var rname string
	err := r.Scan(&d.ID, &d.Domain, &d.Email, &uid, &uname, &d.UniversityName, &rid, &rname, &d.MXOk, &d.CreatedAt, &d.Status, &d.DecidedAt)
	if uid != nil && uname != nil {
		d.University = &Ref{ID: *uid, Name: *uname}
	}
	if rid != nil {
		d.Requester = &Ref{ID: *rid, Name: rname}
	}
	return d, err
}

const domainFrom = ` FROM domain_requests r LEFT JOIN universities un ON un.id = r.university_id LEFT JOIN users ru ON ru.id = r.requester_id`

func (s *Service) domainRequests(ctx context.Context, where string, args ...any) ([]DomainRequest, error) {
	rows, err := s.d.Q(ctx).Query(ctx, `SELECT `+domainCols+domainFrom+` WHERE `+where, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []DomainRequest{}
	for rows.Next() {
		d, err := scanDomainRequest(rows)
		if err != nil {
			return nil, err
		}
		out = append(out, d)
	}
	return out, rows.Err()
}

type domainListReq struct {
	Page
	Status string `json:"-" query:"status" validate:"omitempty,oneof=open approved rejected all"`
}

func (s *Service) handleListDomainRequests(ctx context.Context, in *domainListReq) (*Paged[DomainRequest], error) {
	page, size := in.limits()
	status := in.Status
	if status == "" {
		status = "open"
	}
	out := &Paged[DomainRequest]{Page: page, PageSize: size}
	if err := s.d.Q(ctx).QueryRow(ctx, `SELECT count(*)::int FROM domain_requests WHERE $1 = 'all' OR status = $1`, status).Scan(&out.Total); err != nil {
		return nil, err
	}
	var err error
	out.Items, err = s.domainRequests(ctx, `($1 = 'all' OR r.status = $1) ORDER BY r.created_at DESC, r.id LIMIT $2 OFFSET $3`,
		status, size, (page-1)*size)
	return out, err
}

type approveReq struct {
	ID           string `json:"-" path:"id" validate:"required,uuid"`
	UniversityID string `json:"universityId" validate:"required,uuid"`
}

func (s *Service) decideDomain(ctx context.Context, id uuid.UUID, status string, uni *uuid.UUID) (*DomainRequest, error) {
	err := s.d.InTx(ctx, func(ctx context.Context) error {
		q := s.d.Q(ctx)
		var domain, cur string
		err := q.QueryRow(ctx, `SELECT domain, status FROM domain_requests WHERE id = $1 FOR UPDATE`, id).Scan(&domain, &cur)
		if db.IsNoRows(err) {
			return ErrDomainReqGone
		}
		if err != nil {
			return err
		}
		if cur != "open" {
			return ErrDomainReqDone
		}
		if status == "approved" {
			if err := s.ports.AddDomain(ctx, *uni, domain); err != nil {
				return err
			}
		}
		if _, err := q.Exec(ctx, `UPDATE domain_requests SET status = $2, decided_by = $3, decided_at = $4,
			university_id = coalesce($5, university_id) WHERE id = $1`, id, status, auth.MustUser(ctx).UserID, s.now(), uni); err != nil {
			return err
		}
		action := map[string]string{"approved": "approve", "rejected": "reject"}[status]
		return s.audit(ctx, "admin.domain_request."+action, "domain_request", id.String(),
			map[string]any{"domain": domain, "universityId": uni})
	})
	if err != nil {
		return nil, err
	}
	list, err := s.domainRequests(ctx, `r.id = $1`, id)
	if err != nil || len(list) == 0 {
		return nil, err
	}
	return &list[0], nil
}

func (s *Service) handleApproveDomain(ctx context.Context, in *approveReq) (*DomainRequest, error) {
	u := uuid.MustParse(in.UniversityID)
	return s.decideDomain(ctx, uuid.MustParse(in.ID), "approved", &u)
}

func (s *Service) handleRejectDomain(ctx context.Context, in *idReq) (*DomainRequest, error) {
	return s.decideDomain(ctx, uuid.MustParse(in.ID), "rejected", nil)
}

// ---- inbox ---------------------------------------------------------------------------------

type UniNeedingAdmin struct {
	ID       uuid.UUID `json:"id"`
	Name     string    `json:"name"`
	Students int       `json:"students"`
}

type AutoBlock struct {
	User       Ref       `json:"user"`
	University *Ref      `json:"university"`
	Reason     string    `json:"reason"`
	CreatedAt  time.Time `json:"createdAt"`
}

type Inbox struct {
	Escalations                    []Escalation      `json:"escalations"`
	DomainRequests                 []DomainRequest   `json:"domainRequests"`
	UniversitiesWithoutCampusAdmin []UniNeedingAdmin `json:"universitiesWithoutCampusAdmin"`
	AutoVouchBlocks                []AutoBlock       `json:"autoVouchBlocks"`
	ReportsWaiting                 int               `json:"reportsWaiting"`
	FeedbackNew                    int               `json:"feedbackNew"`
}

func (s *Service) handleInbox(ctx context.Context, _ *httpx.Empty) (*Inbox, error) {
	q := s.d.Q(ctx)
	out := &Inbox{Escalations: []Escalation{}, UniversitiesWithoutCampusAdmin: []UniNeedingAdmin{}, AutoVouchBlocks: []AutoBlock{}}
	rows, err := q.Query(ctx, `SELECT `+escalationCols+` FROM escalations e JOIN universities un ON un.id = e.university_id
		LEFT JOIN users cu ON cu.id = e.created_by WHERE e.resolved_at IS NULL ORDER BY e.created_at LIMIT 100`)
	if err != nil {
		return nil, err
	}
	for rows.Next() {
		e, err := scanEscalation(rows)
		if err != nil {
			rows.Close()
			return nil, err
		}
		out.Escalations = append(out.Escalations, e)
	}
	rows.Close()
	if err := rows.Err(); err != nil {
		return nil, err
	}
	if out.DomainRequests, err = s.domainRequests(ctx, `r.status = 'open' ORDER BY r.created_at LIMIT 100`); err != nil {
		return nil, err
	}
	ur, err := q.Query(ctx, `
		SELECT un.id, un.name, count(u.id)::int AS n FROM universities un JOIN users u ON u.university_id = un.id
		WHERE NOT un.is_demo AND NOT EXISTS (SELECT 1 FROM campus_admins c WHERE c.university_id = un.id)
		GROUP BY un.id HAVING count(u.id) >= $1 ORDER BY n DESC, un.name LIMIT 100`, MinStudentsForNeed)
	if err != nil {
		return nil, err
	}
	for ur.Next() {
		var u UniNeedingAdmin
		if err := ur.Scan(&u.ID, &u.Name, &u.Students); err != nil {
			ur.Close()
			return nil, err
		}
		out.UniversitiesWithoutCampusAdmin = append(out.UniversitiesWithoutCampusAdmin, u)
	}
	ur.Close()
	if err := ur.Err(); err != nil {
		return nil, err
	}
	br, err := q.Query(ctx, `
		SELECT u.id, coalesce(u.display_name, ''), un.id, un.name, b.reason, b.created_at
		FROM vouch_blocks b JOIN users u ON u.id = b.user_id LEFT JOIN universities un ON un.id = u.university_id
		WHERE b.auto AND b.created_at >= $1 ORDER BY b.created_at DESC LIMIT 100`, s.now().AddDate(0, 0, -14))
	if err != nil {
		return nil, err
	}
	defer br.Close()
	for br.Next() {
		var b AutoBlock
		var uid *uuid.UUID
		var uname *string
		if err := br.Scan(&b.User.ID, &b.User.Name, &uid, &uname, &b.Reason, &b.CreatedAt); err != nil {
			return nil, err
		}
		if uid != nil && uname != nil {
			b.University = &Ref{ID: *uid, Name: *uname}
		}
		out.AutoVouchBlocks = append(out.AutoVouchBlocks, b)
	}
	if err := br.Err(); err != nil {
		return nil, err
	}
	if out.DomainRequests == nil {
		out.DomainRequests = []DomainRequest{}
	}
	if err := q.QueryRow(ctx, `
		SELECT (SELECT count(*) FROM issues WHERE report_count > 0 AND visibility <> 'removed')
		     + (SELECT count(*) FROM comments WHERE report_count > 0 AND visibility <> 'removed')`).Scan(&out.ReportsWaiting); err != nil {
		return nil, err
	}
	err = q.QueryRow(ctx, `SELECT count(*)::int FROM feedback WHERE status = 'new' OR team_unread > 0`).Scan(&out.FeedbackNew)
	return out, err
}

type resolveReq struct {
	ID         string `json:"-" path:"id" validate:"required,uuid"`
	Resolution string `json:"resolution" validate:"max=300"`
}

func (s *Service) handleResolveEscalation(ctx context.Context, in *resolveReq) (*Escalation, error) {
	id := uuid.MustParse(in.ID)
	resolution := strings.Join(strings.Fields(in.Resolution), " ")
	err := s.d.InTx(ctx, func(ctx context.Context) error {
		var resolved *time.Time
		err := s.d.Q(ctx).QueryRow(ctx, `SELECT resolved_at FROM escalations WHERE id = $1 FOR UPDATE`, id).Scan(&resolved)
		if db.IsNoRows(err) {
			return ErrEscalationGone
		}
		if err != nil {
			return err
		}
		if resolved != nil {
			return ErrEscalationDone
		}
		if _, err := s.d.Q(ctx).Exec(ctx, `UPDATE escalations SET resolved_at = $2, resolved_by = $3, resolution = $4 WHERE id = $1`,
			id, s.now(), auth.MustUser(ctx).UserID, resolution); err != nil {
			return err
		}
		return s.audit(ctx, "admin.escalation.resolve", "escalation", id.String(), map[string]any{"resolution": resolution})
	})
	if err != nil {
		return nil, err
	}
	return s.escalation(ctx, id)
}

// ---- university health ----------------------------------------------------------------------

type HealthRow struct {
	ID              uuid.UUID `json:"id"`
	Name            string    `json:"name"`
	Students        int       `json:"students"`
	Verified        int       `json:"verified"`
	VerifiedPct     int       `json:"verifiedPct"`
	CampusAdmins    int       `json:"campusAdmins"`
	Sections        int       `json:"sections"`
	SectionsWithCR  int       `json:"sectionsWithCr"`
	BusRoutes       int       `json:"busRoutes"`
	OpenReports     int       `json:"openReports"`
	OpenEscalations int       `json:"openEscalations"`
	Attention       []string  `json:"attention"`
}

type healthReq struct {
	Page
	Sort string `json:"-" query:"sort" validate:"omitempty,oneof=students verifiedPct attention"`
	Q    string `json:"-" query:"q" validate:"max=100"`
}

// Attention reasons (docs/CAMPUS_ADMINS.md §3).
const (
	lowVerifiedStudents = 10 // at least this many students ...
	lowVerifiedPct      = 40 // ... and under this share verified
)

const healthCTE = `
WITH h AS (
  SELECT un.id, un.name,
    (SELECT count(*) FROM users u WHERE u.university_id = un.id)::int AS students,
    (SELECT count(*) FROM users u WHERE u.university_id = un.id AND u.verified_at IS NOT NULL)::int AS verified,
    (SELECT count(*) FROM campus_admins c WHERE c.university_id = un.id)::int AS campus_admins,
    (SELECT count(*) FROM class_groups g WHERE g.university_id = un.id)::int AS sections,
    (SELECT count(*) FROM class_groups g WHERE g.university_id = un.id
       AND EXISTS (SELECT 1 FROM class_group_members m WHERE m.group_id = g.id AND m.role = 'cr'))::int AS sections_with_cr,
    (SELECT count(*) FROM bus_routes b WHERE b.university_id = un.id)::int AS bus_routes,
    ((SELECT count(*) FROM issues i WHERE i.university_id = un.id AND i.report_count > 0 AND i.visibility <> 'removed')
     + (SELECT count(*) FROM comments c JOIN issues i ON i.id = c.issue_id
        WHERE i.university_id = un.id AND c.report_count > 0 AND c.visibility <> 'removed'))::int AS open_reports,
    (SELECT count(*) FROM escalations e WHERE e.university_id = un.id AND e.resolved_at IS NULL)::int AS open_escalations
  FROM universities un
  WHERE NOT un.is_demo AND ($1 = '' OR un.name ILIKE $2)
), p AS (
  SELECT h.*, CASE WHEN students = 0 THEN 0 ELSE (verified * 100 / students) END AS pct,
    (campus_admins = 0 AND students >= ` + "5" + `) AS a_admin,
    (sections > sections_with_cr) AS a_cr,
    (open_reports > 0) AS a_reports,
    (students >= ` + "10" + ` AND verified * 100 / students < ` + "40" + `) AS a_low
  FROM h
)`

func (s *Service) handleHealth(ctx context.Context, in *healthReq) (*Paged[HealthRow], error) {
	page, size := in.Page.limits()
	search := strings.TrimSpace(in.Q)
	order := `students DESC, name`
	switch in.Sort {
	case "verifiedPct":
		order = `(students = 0), pct ASC, students DESC, name`
	case "attention":
		order = `(a_admin::int + a_cr::int + a_reports::int + a_low::int) DESC, students DESC, name`
	}
	out := &Paged[HealthRow]{Items: []HealthRow{}, Page: page, PageSize: size}
	if err := s.d.Q(ctx).QueryRow(ctx, healthCTE+` SELECT count(*)::int FROM p`, search, like(search)).Scan(&out.Total); err != nil {
		return nil, err
	}
	rows, err := s.d.Q(ctx).Query(ctx, healthCTE+` SELECT id, name, students, verified, pct, campus_admins, sections, sections_with_cr,
		bus_routes, open_reports, open_escalations, a_admin, a_cr, a_reports, a_low FROM p ORDER BY `+order+` LIMIT $3 OFFSET $4`,
		search, like(search), size, (page-1)*size)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	for rows.Next() {
		var r HealthRow
		var aAdmin, aCR, aReports, aLow bool
		if err := rows.Scan(&r.ID, &r.Name, &r.Students, &r.Verified, &r.VerifiedPct, &r.CampusAdmins, &r.Sections, &r.SectionsWithCR,
			&r.BusRoutes, &r.OpenReports, &r.OpenEscalations, &aAdmin, &aCR, &aReports, &aLow); err != nil {
			return nil, err
		}
		r.Attention = []string{}
		for _, a := range []struct {
			on   bool
			code string
		}{{aAdmin, "no_campus_admin"}, {aCR, "sections_without_cr"}, {aReports, "reports_waiting"}, {aLow, "low_verified"}} {
			if a.on {
				r.Attention = append(r.Attention, a.code)
			}
		}
		out.Items = append(out.Items, r)
	}
	return out, rows.Err()
}
