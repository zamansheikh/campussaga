package campusadmin

import (
	"context"
	"strings"
	"time"
	"unicode/utf8"

	"github.com/google/uuid"

	"github.com/zamansheikh/varsitykotha/backend/internal/platform/apperr"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/auth"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/db"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/httpx"
)

// What a campus admin sees of a student: never an email.

type GroupRef struct {
	ID   uuid.UUID `json:"id"`
	Name string    `json:"name"`
	Role string    `json:"role"`
}

type Student struct {
	ID             uuid.UUID  `json:"id"`
	Name           string     `json:"name"`
	Department     *string    `json:"department"`
	Batch          *string    `json:"batch"`
	PhotoVersion   *string    `json:"photoVersion"`
	GooglePhotoURL *string    `json:"googlePhotoUrl"`
	Verified       bool       `json:"verified"`
	Via            *string    `json:"via"`
	Vouches        int        `json:"vouches"`
	Groups         []GroupRef `json:"groups"`
	VouchBlocked   bool       `json:"vouchBlocked"`
	JoinedAt       time.Time  `json:"joinedAt"`
}

type HistoryEntry struct {
	Method    string     `json:"method"`
	Actor     *Ref       `json:"actor"`
	At        time.Time  `json:"at"`
	RevokedAt *time.Time `json:"revokedAt"`
	Reason    string     `json:"reason"`
}

type VouchedBy struct {
	ID   uuid.UUID `json:"id"`
	Name string    `json:"name"`
	At   time.Time `json:"at"`
}

type StudentDetail struct {
	Student
	History               []HistoryEntry `json:"history"`
	VouchedBy             []VouchedBy    `json:"vouchedBy"`
	ConfirmedOrVouchedFor int            `json:"confirmedOrVouchedFor"`
}

const studentCols = `u.id, coalesce(u.display_name, ''), u.department, u.batch, u.photo_key, u.google_photo_url,
	(u.verified_at IS NOT NULL), u.verified_via,
	(SELECT count(*) FROM vouches v JOIN users vu ON vu.id = v.voucher_id
	 WHERE v.user_id = u.id AND v.void_at IS NULL AND vu.verified_at IS NOT NULL)::int,
	EXISTS (SELECT 1 FROM vouch_blocks b WHERE b.user_id = u.id), u.created_at`

type scanner interface{ Scan(dest ...any) error }

func scanStudent(r scanner) (Student, error) {
	var st Student
	err := r.Scan(&st.ID, &st.Name, &st.Department, &st.Batch, &st.PhotoVersion, &st.GooglePhotoURL,
		&st.Verified, &st.Via, &st.Vouches, &st.VouchBlocked, &st.JoinedAt)
	st.Groups = []GroupRef{}
	return st, err
}

// fillGroups adds each student's sections at the university.
func (s *Service) fillGroups(ctx context.Context, uni uuid.UUID, list []Student) error {
	if len(list) == 0 {
		return nil
	}
	ids := make([]string, len(list))
	at := map[uuid.UUID]int{}
	for i, st := range list {
		ids[i], at[st.ID] = st.ID.String(), i
	}
	rows, err := s.d.Q(ctx).Query(ctx, `
		SELECT m.user_id, g.id, `+sqlGroupName+`, m.role FROM class_group_members m JOIN class_groups g ON g.id = m.group_id
		WHERE m.user_id = ANY($1::uuid[]) AND g.university_id = $2 ORDER BY g.department, g.batch, g.section`, ids, uni)
	if err != nil {
		return err
	}
	defer rows.Close()
	for rows.Next() {
		var u uuid.UUID
		var g GroupRef
		if err := rows.Scan(&u, &g.ID, &g.Name, &g.Role); err != nil {
			return err
		}
		list[at[u]].Groups = append(list[at[u]].Groups, g)
	}
	return rows.Err()
}

// student loads one student of the university (404 for anyone else).
func (s *Service) student(ctx context.Context, uni, id uuid.UUID) (*Student, error) {
	st, err := scanStudent(s.d.Q(ctx).QueryRow(ctx, `SELECT `+studentCols+` FROM users u WHERE u.id = $1 AND u.university_id = $2`, id, uni))
	if db.IsNoRows(err) {
		return nil, ErrUserNotFound
	}
	if err != nil {
		return nil, err
	}
	list := []Student{st}
	if err := s.fillGroups(ctx, uni, list); err != nil {
		return nil, err
	}
	return &list[0], nil
}

// ---- inbox ---------------------------------------------------------------------------

type VerificationEvent struct {
	Student Ref        `json:"student"`
	Method  string     `json:"method"`
	Actor   *Ref       `json:"actor"`
	At      time.Time  `json:"at"`
	Revoked *time.Time `json:"revokedAt"`
}

type CampusInbox struct {
	University       Ref                 `json:"university"`
	Waiting          []Student           `json:"waiting"`
	WaitingCount     int                 `json:"waitingCount"`
	Reports          int                 `json:"reports"`
	SectionsWithoutC int                 `json:"sectionsWithoutCr"`
	OpenBlood        int                 `json:"openBlood"`
	Recent           []VerificationEvent `json:"recent"`
}

// waitingWhere: not verified, and either someone vouched or they're in a section.
const waitingWhere = `u.university_id = $1 AND u.verified_at IS NULL AND (
	EXISTS (SELECT 1 FROM vouches v WHERE v.user_id = u.id AND v.void_at IS NULL)
	OR EXISTS (SELECT 1 FROM class_group_members m WHERE m.user_id = u.id))`

func (s *Service) handleCampusInbox(ctx context.Context, _ *httpx.Empty) (*CampusInbox, error) {
	uni, err := s.campusAdmin(ctx)
	if err != nil {
		return nil, err
	}
	q := s.d.Q(ctx)
	out := &CampusInbox{University: Ref{ID: uni}, Waiting: []Student{}, Recent: []VerificationEvent{}}
	if out.University.Name, err = s.uniName(ctx, uni); err != nil {
		return nil, err
	}
	rows, err := q.Query(ctx, `SELECT `+studentCols+` FROM users u WHERE `+waitingWhere+` ORDER BY u.created_at DESC LIMIT 20`, uni)
	if err != nil {
		return nil, err
	}
	for rows.Next() {
		st, err := scanStudent(rows)
		if err != nil {
			rows.Close()
			return nil, err
		}
		out.Waiting = append(out.Waiting, st)
	}
	rows.Close()
	if err := rows.Err(); err != nil {
		return nil, err
	}
	if err := s.fillGroups(ctx, uni, out.Waiting); err != nil {
		return nil, err
	}
	if err := q.QueryRow(ctx, `SELECT count(*)::int FROM users u WHERE `+waitingWhere, uni).Scan(&out.WaitingCount); err != nil {
		return nil, err
	}
	if out.Reports, err = s.ports.ReportsWaiting(ctx, uni); err != nil {
		return nil, err
	}
	if err := q.QueryRow(ctx, `SELECT count(*)::int FROM class_groups g WHERE g.university_id = $1
		AND NOT EXISTS (SELECT 1 FROM class_group_members m WHERE m.group_id = g.id AND m.role = 'cr')`, uni).Scan(&out.SectionsWithoutC); err != nil {
		return nil, err
	}
	if err := q.QueryRow(ctx, `SELECT count(*)::int FROM blood_requests WHERE university_id = $1 AND status = 'open'`, uni).Scan(&out.OpenBlood); err != nil {
		return nil, err
	}
	ev, err := q.Query(ctx, `
		SELECT u.id, coalesce(u.display_name, ''), e.method, a.id, coalesce(a.display_name, ''), e.created_at, e.revoked_at
		FROM verification_events e JOIN users u ON u.id = e.user_id LEFT JOIN users a ON a.id = e.actor_id
		WHERE e.university_id = $1 ORDER BY e.created_at DESC LIMIT 10`, uni)
	if err != nil {
		return nil, err
	}
	defer ev.Close()
	for ev.Next() {
		var e VerificationEvent
		var aid *uuid.UUID
		var aname string
		if err := ev.Scan(&e.Student.ID, &e.Student.Name, &e.Method, &aid, &aname, &e.At, &e.Revoked); err != nil {
			return nil, err
		}
		if aid != nil {
			e.Actor = &Ref{ID: *aid, Name: aname}
		}
		out.Recent = append(out.Recent, e)
	}
	return out, ev.Err()
}

// ---- students ------------------------------------------------------------------------

type studentsReq struct {
	Page
	Status string `json:"-" query:"status" validate:"omitempty,oneof=unverified verified all"`
	Q      string `json:"-" query:"q" validate:"max=100"`
	// GroupID: only members of this section (its page lists them).
	GroupID string `json:"-" query:"groupId" validate:"omitempty,uuid"`
}

func (s *Service) handleCampusStudents(ctx context.Context, in *studentsReq) (*Paged[Student], error) {
	uni, err := s.campusAdmin(ctx)
	if err != nil {
		return nil, err
	}
	page, size := in.limits()
	search := strings.TrimSpace(in.Q)
	where := `u.university_id = $1 AND ($2 = 'all' OR ($2 = 'verified') = (u.verified_at IS NOT NULL))
		AND ($3 = '' OR u.display_name ILIKE $4 OR u.department ILIKE $4 OR u.batch ILIKE $4)
		AND ($5 = '' OR EXISTS (SELECT 1 FROM class_group_members m WHERE m.group_id::text = $5 AND m.user_id = u.id))`
	status := in.Status
	if status == "" {
		status = "all"
	}
	q := s.d.Q(ctx)
	out := &Paged[Student]{Items: []Student{}, Page: page, PageSize: size}
	if err := q.QueryRow(ctx, `SELECT count(*)::int FROM users u WHERE `+where, uni, status, search, like(search), in.GroupID).Scan(&out.Total); err != nil {
		return nil, err
	}
	rows, err := q.Query(ctx, `SELECT `+studentCols+` FROM users u WHERE `+where+` ORDER BY u.created_at DESC, u.id LIMIT $6 OFFSET $7`,
		uni, status, search, like(search), in.GroupID, size, (page-1)*size)
	if err != nil {
		return nil, err
	}
	for rows.Next() {
		st, err := scanStudent(rows)
		if err != nil {
			rows.Close()
			return nil, err
		}
		out.Items = append(out.Items, st)
	}
	rows.Close()
	if err := rows.Err(); err != nil {
		return nil, err
	}
	return out, s.fillGroups(ctx, uni, out.Items)
}

type idReq struct {
	ID string `json:"-" path:"id" validate:"required,uuid"`
}

func (s *Service) handleCampusStudent(ctx context.Context, in *idReq) (*StudentDetail, error) {
	uni, err := s.campusAdmin(ctx)
	if err != nil {
		return nil, err
	}
	id := uuid.MustParse(in.ID)
	st, err := s.student(ctx, uni, id)
	if err != nil {
		return nil, err
	}
	out := &StudentDetail{Student: *st, History: []HistoryEntry{}, VouchedBy: []VouchedBy{}}
	q := s.d.Q(ctx)
	rows, err := q.Query(ctx, `
		SELECT e.method, a.id, coalesce(a.display_name, ''), e.created_at, e.revoked_at, e.reason
		FROM verification_events e LEFT JOIN users a ON a.id = e.actor_id
		WHERE e.user_id = $1 ORDER BY e.created_at DESC, (e.revoked_at IS NULL) DESC, e.id`, id)
	if err != nil {
		return nil, err
	}
	for rows.Next() {
		var h HistoryEntry
		var aid *uuid.UUID
		var aname string
		if err := rows.Scan(&h.Method, &aid, &aname, &h.At, &h.RevokedAt, &h.Reason); err != nil {
			rows.Close()
			return nil, err
		}
		if aid != nil {
			h.Actor = &Ref{ID: *aid, Name: aname}
		}
		out.History = append(out.History, h)
	}
	rows.Close()
	if err := rows.Err(); err != nil {
		return nil, err
	}
	vr, err := q.Query(ctx, `SELECT v.voucher_id, coalesce(u.display_name, ''), v.created_at FROM vouches v
		JOIN users u ON u.id = v.voucher_id WHERE v.user_id = $1 AND v.void_at IS NULL ORDER BY v.created_at`, id)
	if err != nil {
		return nil, err
	}
	for vr.Next() {
		var v VouchedBy
		if err := vr.Scan(&v.ID, &v.Name, &v.At); err != nil {
			vr.Close()
			return nil, err
		}
		out.VouchedBy = append(out.VouchedBy, v)
	}
	vr.Close()
	if err := vr.Err(); err != nil {
		return nil, err
	}
	err = q.QueryRow(ctx, `SELECT count(*)::int FROM (
		SELECT user_id FROM verification_events WHERE actor_id = $1 AND method = 'cr'
		UNION SELECT user_id FROM vouches WHERE voucher_id = $1) x`, id).Scan(&out.ConfirmedOrVouchedFor)
	return out, err
}

func (s *Service) handleCampusVerify(ctx context.Context, in *idReq) (*Student, error) {
	uni, err := s.campusAdmin(ctx)
	if err != nil {
		return nil, err
	}
	id := uuid.MustParse(in.ID)
	err = s.d.InTx(ctx, func(ctx context.Context) error {
		if _, err := s.student(ctx, uni, id); err != nil {
			return err
		}
		st, err := s.lockStudent(ctx, id)
		if err != nil {
			return err
		}
		if st.Verified {
			return ErrAlreadyVerif
		}
		if err := s.verifyNow(ctx, id, uni, "campus_admin", auth.MustUser(ctx).UserID); err != nil {
			return err
		}
		return s.audit(ctx, "campus.verify", "user", id.String(), map[string]any{"method": "campus_admin"})
	})
	if err != nil {
		return nil, err
	}
	return s.student(ctx, uni, id)
}

type reasonReq struct {
	ID     string `json:"-" path:"id" validate:"required,uuid"`
	Reason string `json:"reason" validate:"required,max=300"`
}

func cleanReason(r string) (string, error) {
	r = strings.Join(strings.Fields(r), " ")
	if r == "" || utf8.RuneCountInString(r) > 300 {
		return "", apperr.Validation(map[string]string{"reason": "must be 1 to 300 characters"})
	}
	return r, nil
}

func (s *Service) handleCampusUnverify(ctx context.Context, in *reasonReq) (*Student, error) {
	uni, err := s.campusAdmin(ctx)
	if err != nil {
		return nil, err
	}
	reason, err := cleanReason(in.Reason)
	if err != nil {
		return nil, err
	}
	id, actor := uuid.MustParse(in.ID), auth.MustUser(ctx).UserID
	err = s.d.InTx(ctx, func(ctx context.Context) error {
		if _, err := s.student(ctx, uni, id); err != nil {
			return err
		}
		st, err := s.lockStudent(ctx, id)
		if err != nil {
			return err
		}
		switch {
		case !st.Verified:
			return ErrNotVerified
		case st.Via == "email":
			return ErrEmailVerified
		case st.Via == "admin":
			return ErrAdminVerified
		}
		now := s.now()
		q := s.d.Q(ctx)
		// Who gave the verification: they may get a vouch block.
		var givers []uuid.UUID
		if st.Via == "vouch" {
			rows, err := q.Query(ctx, `UPDATE vouches SET void_at = $2 WHERE user_id = $1 AND void_at IS NULL RETURNING voucher_id`, id, now)
			if err != nil {
				return err
			}
			for rows.Next() {
				var v uuid.UUID
				if err := rows.Scan(&v); err != nil {
					rows.Close()
					return err
				}
				givers = append(givers, v)
			}
			rows.Close()
			if err := rows.Err(); err != nil {
				return err
			}
		}
		rows, err := q.Query(ctx, `UPDATE verification_events SET revoked_at = $2, revoked_by = $3, reason = $4
			WHERE user_id = $1 AND revoked_at IS NULL RETURNING method, actor_id`, id, now, actor, reason)
		if err != nil {
			return err
		}
		for rows.Next() {
			var method string
			var a *uuid.UUID
			if err := rows.Scan(&method, &a); err != nil {
				rows.Close()
				return err
			}
			if method == "cr" && a != nil {
				givers = append(givers, *a)
			}
		}
		rows.Close()
		if err := rows.Err(); err != nil {
			return err
		}
		if _, err := q.Exec(ctx, `UPDATE users SET verified_at = NULL WHERE id = $1`, id); err != nil {
			return err
		}
		if err := s.audit(ctx, "campus.unverify", "user", id.String(), map[string]any{"reason": reason, "was": st.Via}); err != nil {
			return err
		}
		for _, g := range givers {
			if err := s.maybeAutoBlock(ctx, g, now); err != nil {
				return err
			}
		}
		return nil
	})
	if err != nil {
		return nil, err
	}
	return s.student(ctx, uni, id)
}

// maybeAutoBlock blocks vouching for someone two of whose verified students
// lost their verification within 90 days.
func (s *Service) maybeAutoBlock(ctx context.Context, giver uuid.UUID, now time.Time) error {
	q := s.d.Q(ctx)
	var n int
	if err := q.QueryRow(ctx, `SELECT count(*)::int FROM (
		SELECT user_id FROM verification_events WHERE actor_id = $1 AND method = 'cr' AND revoked_at > $2
		UNION SELECT user_id FROM vouches WHERE voucher_id = $1 AND void_at > $2) x`,
		giver, now.AddDate(0, 0, -AutoBlockDays)).Scan(&n); err != nil {
		return err
	}
	if n < AutoBlockStudents {
		return nil
	}
	tag, err := q.Exec(ctx, `INSERT INTO vouch_blocks (user_id, blocked_by, reason, auto, created_at)
		VALUES ($1, NULL, 'Two students they verified were unverified', true, $2) ON CONFLICT (user_id) DO NOTHING`, giver, now)
	if err != nil || tag.RowsAffected() == 0 {
		return err
	}
	return s.audit(ctx, "campus.vouch_block", "user", giver.String(), map[string]any{"auto": true})
}

type blockReq struct {
	ID     string `json:"-" path:"id" validate:"required,uuid"`
	Reason string `json:"reason" validate:"max=300"`
}

func (s *Service) handleVouchBlock(ctx context.Context, in *blockReq) (*Student, error) {
	uni, err := s.campusAdmin(ctx)
	if err != nil {
		return nil, err
	}
	reason := strings.Join(strings.Fields(in.Reason), " ")
	id := uuid.MustParse(in.ID)
	err = s.d.InTx(ctx, func(ctx context.Context) error {
		if _, err := s.student(ctx, uni, id); err != nil {
			return err
		}
		if _, err := s.d.Q(ctx).Exec(ctx, `INSERT INTO vouch_blocks (user_id, blocked_by, reason, auto, created_at)
			VALUES ($1, $2, $3, false, $4)
			ON CONFLICT (user_id) DO UPDATE SET blocked_by = EXCLUDED.blocked_by, reason = EXCLUDED.reason, auto = false`,
			id, auth.MustUser(ctx).UserID, reason, s.now()); err != nil {
			return err
		}
		return s.audit(ctx, "campus.vouch_block", "user", id.String(), map[string]any{"reason": reason})
	})
	if err != nil {
		return nil, err
	}
	return s.student(ctx, uni, id)
}

func (s *Service) handleVouchUnblock(ctx context.Context, in *idReq) (*Student, error) {
	uni, err := s.campusAdmin(ctx)
	if err != nil {
		return nil, err
	}
	id := uuid.MustParse(in.ID)
	err = s.d.InTx(ctx, func(ctx context.Context) error {
		if _, err := s.student(ctx, uni, id); err != nil {
			return err
		}
		if _, err := s.d.Q(ctx).Exec(ctx, `DELETE FROM vouch_blocks WHERE user_id = $1`, id); err != nil {
			return err
		}
		return s.audit(ctx, "campus.vouch_unblock", "user", id.String(), nil)
	})
	if err != nil {
		return nil, err
	}
	return s.student(ctx, uni, id)
}

// ---- sections --------------------------------------------------------------------------

type Section struct {
	ID             uuid.UUID `json:"id"`
	Name           string    `json:"name"`
	Term           string    `json:"term"`
	Members        int       `json:"members"`
	CR             []Ref     `json:"cr"`
	LastActivityAt time.Time `json:"lastActivityAt"`
}

func (s *Service) handleSections(ctx context.Context, _ *httpx.Empty) ([]Section, error) {
	uni, err := s.campusAdmin(ctx)
	if err != nil {
		return nil, err
	}
	rows, err := s.d.Q(ctx).Query(ctx, `
		SELECT g.id, `+sqlGroupName+`, g.semester,
		       (SELECT count(*) FROM class_group_members m WHERE m.group_id = g.id)::int,
		       GREATEST(g.updated_at, coalesce((SELECT max(a.created_at) FROM announcements a WHERE a.group_id = g.id), g.updated_at))
		FROM class_groups g WHERE g.university_id = $1
		ORDER BY NOT EXISTS (SELECT 1 FROM class_group_members m WHERE m.group_id = g.id AND m.role = 'cr') DESC,
		         g.department, g.batch, g.section, g.id
		LIMIT 500`, uni)
	if err != nil {
		return nil, err
	}
	out := []Section{}
	at := map[uuid.UUID]int{}
	for rows.Next() {
		var sec Section
		if err := rows.Scan(&sec.ID, &sec.Name, &sec.Term, &sec.Members, &sec.LastActivityAt); err != nil {
			rows.Close()
			return nil, err
		}
		sec.CR = []Ref{}
		at[sec.ID] = len(out)
		out = append(out, sec)
	}
	rows.Close()
	if err := rows.Err(); err != nil {
		return nil, err
	}
	crs, err := s.d.Q(ctx).Query(ctx, `
		SELECT m.group_id, u.id, coalesce(u.display_name, '') FROM class_group_members m
		JOIN class_groups g ON g.id = m.group_id JOIN users u ON u.id = m.user_id
		WHERE g.university_id = $1 AND m.role = 'cr' ORDER BY m.joined_at`, uni)
	if err != nil {
		return nil, err
	}
	defer crs.Close()
	for crs.Next() {
		var g uuid.UUID
		var r Ref
		if err := crs.Scan(&g, &r.ID, &r.Name); err != nil {
			return nil, err
		}
		out[at[g]].CR = append(out[at[g]].CR, r)
	}
	return out, crs.Err()
}

type setCRReq struct {
	ID     string `json:"-" path:"id" validate:"required,uuid"`
	UserID string `json:"userId" validate:"required,uuid"`
}

// sectionOf checks the section is at the university.
func (s *Service) sectionOf(ctx context.Context, uni, group uuid.UUID) error {
	var ok bool
	if err := s.d.Q(ctx).QueryRow(ctx, `SELECT EXISTS (SELECT 1 FROM class_groups WHERE id = $1 AND university_id = $2)`, group, uni).Scan(&ok); err != nil {
		return err
	}
	if !ok {
		return ErrGroupNotFound
	}
	return nil
}

func (s *Service) handleSetCR(ctx context.Context, in *setCRReq) ([]Section, error) {
	uni, err := s.campusAdmin(ctx)
	if err != nil {
		return nil, err
	}
	group, user := uuid.MustParse(in.ID), uuid.MustParse(in.UserID)
	err = s.d.InTx(ctx, func(ctx context.Context) error {
		if err := s.sectionOf(ctx, uni, group); err != nil {
			return err
		}
		q := s.d.Q(ctx)
		if _, err := q.Exec(ctx, `SELECT 1 FROM class_groups WHERE id = $1 FOR UPDATE`, group); err != nil {
			return err
		}
		var role string
		var verified bool
		err := q.QueryRow(ctx, `SELECT m.role, u.verified_at IS NOT NULL FROM class_group_members m JOIN users u ON u.id = m.user_id
			WHERE m.group_id = $1 AND m.user_id = $2`, group, user).Scan(&role, &verified)
		if db.IsNoRows(err) {
			return ErrMemberNotFound
		}
		if err != nil {
			return err
		}
		if !verified {
			return ErrNotVerified
		}
		if role == "cr" {
			return nil
		}
		var n int
		if err := q.QueryRow(ctx, `SELECT count(*)::int FROM class_group_members WHERE group_id = $1 AND role = 'cr'`, group).Scan(&n); err != nil {
			return err
		}
		if n >= 3 {
			return ErrCRLimit
		}
		if _, err := q.Exec(ctx, `UPDATE class_group_members SET role = 'cr' WHERE group_id = $1 AND user_id = $2`, group, user); err != nil {
			return err
		}
		return s.audit(ctx, "campus.section_cr_set", "group", group.String(), map[string]any{"userId": user})
	})
	if err != nil {
		return nil, err
	}
	return s.handleSections(ctx, nil)
}

type removeCRReq struct {
	ID   string `json:"-" path:"id" validate:"required,uuid"`
	User string `json:"-" path:"user" validate:"required,uuid"`
}

func (s *Service) handleRemoveCR(ctx context.Context, in *removeCRReq) ([]Section, error) {
	uni, err := s.campusAdmin(ctx)
	if err != nil {
		return nil, err
	}
	group, user := uuid.MustParse(in.ID), uuid.MustParse(in.User)
	err = s.d.InTx(ctx, func(ctx context.Context) error {
		if err := s.sectionOf(ctx, uni, group); err != nil {
			return err
		}
		q := s.d.Q(ctx)
		if _, err := q.Exec(ctx, `SELECT 1 FROM class_groups WHERE id = $1 FOR UPDATE`, group); err != nil {
			return err
		}
		var role string
		err := q.QueryRow(ctx, `SELECT role FROM class_group_members WHERE group_id = $1 AND user_id = $2`, group, user).Scan(&role)
		if db.IsNoRows(err) {
			return ErrMemberNotFound
		}
		if err != nil {
			return err
		}
		if role != "cr" {
			return ErrNotACR
		}
		var n int
		if err := q.QueryRow(ctx, `SELECT count(*)::int FROM class_group_members WHERE group_id = $1 AND role = 'cr'`, group).Scan(&n); err != nil {
			return err
		}
		if n <= 1 {
			return ErrLastCR
		}
		if _, err := q.Exec(ctx, `UPDATE class_group_members SET role = 'member' WHERE group_id = $1 AND user_id = $2`, group, user); err != nil {
			return err
		}
		return s.audit(ctx, "campus.section_cr_remove", "group", group.String(), map[string]any{"userId": user})
	})
	if err != nil {
		return nil, err
	}
	return s.handleSections(ctx, nil)
}

// ---- bus reps --------------------------------------------------------------------------

// BusRep has the shape of /admin/transport/reps items; the email is always
// empty here (campus admins never see emails).
type BusRep struct {
	UserID       uuid.UUID `json:"userId"`
	Email        string    `json:"email"`
	Name         *string   `json:"name"`
	UniversityID uuid.UUID `json:"universityId"`
	University   string    `json:"university"`
	Slug         string    `json:"universitySlug"`
	CreatedAt    time.Time `json:"createdAt"`
}

type busRepsRes struct {
	Items []BusRep `json:"items"`
}

func (s *Service) busReps(ctx context.Context, uni uuid.UUID) (*busRepsRes, error) {
	rows, err := s.d.Q(ctx).Query(ctx, `
		SELECT r.user_id, u.display_name, r.university_id, un.name, un.slug, r.created_at
		FROM transport_reps r JOIN users u ON u.id = r.user_id JOIN universities un ON un.id = r.university_id
		WHERE r.university_id = $1 ORDER BY u.display_name, r.user_id`, uni)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := &busRepsRes{Items: []BusRep{}}
	for rows.Next() {
		var r BusRep
		if err := rows.Scan(&r.UserID, &r.Name, &r.UniversityID, &r.University, &r.Slug, &r.CreatedAt); err != nil {
			return nil, err
		}
		out.Items = append(out.Items, r)
	}
	return out, rows.Err()
}

func (s *Service) handleBusReps(ctx context.Context, _ *httpx.Empty) (*busRepsRes, error) {
	uni, err := s.campusAdmin(ctx)
	if err != nil {
		return nil, err
	}
	return s.busReps(ctx, uni)
}

type setBusRepReq struct {
	UserID string `json:"userId" validate:"required,uuid"`
}

func (s *Service) handleSetBusRep(ctx context.Context, in *setBusRepReq) (*busRepsRes, error) {
	uni, err := s.campusAdmin(ctx)
	if err != nil {
		return nil, err
	}
	user := uuid.MustParse(in.UserID)
	err = s.d.InTx(ctx, func(ctx context.Context) error {
		if _, err := s.student(ctx, uni, user); err != nil {
			return err
		}
		if _, err := s.d.Q(ctx).Exec(ctx, `INSERT INTO transport_reps (user_id, university_id) VALUES ($1, $2)
			ON CONFLICT (user_id) DO UPDATE SET university_id = EXCLUDED.university_id`, user, uni); err != nil {
			return err
		}
		return s.audit(ctx, "campus.bus_rep_set", "user", user.String(), map[string]any{"universityId": uni})
	})
	if err != nil {
		return nil, err
	}
	return s.busReps(ctx, uni)
}

type userPath struct {
	User string `json:"-" path:"user" validate:"required,uuid"`
}

func (s *Service) handleRemoveBusRep(ctx context.Context, in *userPath) (*httpx.Empty, error) {
	uni, err := s.campusAdmin(ctx)
	if err != nil {
		return nil, err
	}
	user := uuid.MustParse(in.User)
	return nil, s.d.InTx(ctx, func(ctx context.Context) error {
		tag, err := s.d.Q(ctx).Exec(ctx, `DELETE FROM transport_reps WHERE user_id = $1 AND university_id = $2`, user, uni)
		if err != nil {
			return err
		}
		if tag.RowsAffected() == 0 {
			return ErrRepNotFound
		}
		return s.audit(ctx, "campus.bus_rep_remove", "user", user.String(), nil)
	})
}

// ---- reports and blood -----------------------------------------------------------------

func (s *Service) handleReports(ctx context.Context, _ *httpx.Empty) (any, error) {
	uni, err := s.campusAdmin(ctx)
	if err != nil {
		return nil, err
	}
	return s.ports.Reports(ctx, uni)
}

type reportActionReq struct {
	Kind   string `json:"-" path:"kind" validate:"required,oneof=issue comment"`
	ID     string `json:"-" path:"id" validate:"required,uuid"`
	Action string `json:"action" validate:"required,oneof=hide restore dismiss"`
}

func (s *Service) handleReportAction(ctx context.Context, in *reportActionReq) (*httpx.Empty, error) {
	uni, err := s.campusAdmin(ctx)
	if err != nil {
		return nil, err
	}
	id := uuid.MustParse(in.ID)
	return nil, s.d.InTx(ctx, func(ctx context.Context) error {
		if err := s.ports.Moderate(ctx, uni, in.Kind, id, in.Action); err != nil {
			return err
		}
		return s.audit(ctx, "campus.report_"+in.Action, in.Kind, id.String(), nil)
	})
}

func (s *Service) handleBlood(ctx context.Context, _ *httpx.Empty) (any, error) {
	uni, err := s.campusAdmin(ctx)
	if err != nil {
		return nil, err
	}
	return s.ports.BloodOpen(ctx, uni)
}

type bloodCloseReq struct {
	ID     string `json:"-" path:"id" validate:"required,uuid"`
	Reason string `json:"reason" validate:"max=300"`
}

func (s *Service) handleBloodClose(ctx context.Context, in *bloodCloseReq) (any, error) {
	uni, err := s.campusAdmin(ctx)
	if err != nil {
		return nil, err
	}
	return s.ports.BloodClose(ctx, uni, uuid.MustParse(in.ID), in.Reason)
}

// ---- escalations -----------------------------------------------------------------------

type escalateReq struct {
	Kind     string `json:"kind" validate:"required,oneof=student section report other"`
	TargetID string `json:"targetId" validate:"max=64"`
	Note     string `json:"note" validate:"required,max=500"`
}

type Escalation struct {
	ID         uuid.UUID  `json:"id"`
	University Ref        `json:"university"`
	Kind       string     `json:"kind"`
	TargetID   *string    `json:"targetId"`
	Note       string     `json:"note"`
	CreatedBy  *Ref       `json:"createdBy"`
	CreatedAt  time.Time  `json:"createdAt"`
	ResolvedAt *time.Time `json:"resolvedAt"`
	Resolution string     `json:"resolution"`
}

func (s *Service) handleEscalate(ctx context.Context, in *escalateReq) (*Escalation, error) {
	uni, err := s.campusAdmin(ctx)
	if err != nil {
		return nil, err
	}
	note := strings.Join(strings.Fields(in.Note), " ")
	if note == "" {
		return nil, apperr.Validation(map[string]string{"note": "is required"})
	}
	var target *string
	if in.TargetID != "" {
		target = &in.TargetID
	}
	var id uuid.UUID
	err = s.d.InTx(ctx, func(ctx context.Context) error {
		if err := s.d.Q(ctx).QueryRow(ctx, `INSERT INTO escalations (university_id, kind, target_id, note, created_by, created_at)
			VALUES ($1, $2, $3, $4, $5, $6) RETURNING id`, uni, in.Kind, target, note, auth.MustUser(ctx).UserID, s.now()).Scan(&id); err != nil {
			return err
		}
		return s.audit(ctx, "campus.escalate", "escalation", id.String(), map[string]any{"kind": in.Kind, "targetId": target})
	})
	if err != nil {
		return nil, err
	}
	return s.escalation(ctx, id)
}

const escalationCols = `e.id, e.university_id, un.name, e.kind, e.target_id, e.note, cu.id, coalesce(cu.display_name, ''),
	e.created_at, e.resolved_at, e.resolution`

func scanEscalation(r scanner) (Escalation, error) {
	var e Escalation
	var cid *uuid.UUID
	var cname string
	err := r.Scan(&e.ID, &e.University.ID, &e.University.Name, &e.Kind, &e.TargetID, &e.Note, &cid, &cname, &e.CreatedAt, &e.ResolvedAt, &e.Resolution)
	if cid != nil {
		e.CreatedBy = &Ref{ID: *cid, Name: cname}
	}
	return e, err
}

func (s *Service) escalation(ctx context.Context, id uuid.UUID) (*Escalation, error) {
	e, err := scanEscalation(s.d.Q(ctx).QueryRow(ctx, `SELECT `+escalationCols+` FROM escalations e
		JOIN universities un ON un.id = e.university_id LEFT JOIN users cu ON cu.id = e.created_by WHERE e.id = $1`, id))
	if db.IsNoRows(err) {
		return nil, ErrEscalationGone
	}
	return &e, err
}
