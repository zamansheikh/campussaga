package campusadmin

import (
	"context"
	"crypto/rand"
	"encoding/json"
	"time"

	"github.com/google/uuid"

	"github.com/zamansheikh/varsitykotha/backend/internal/platform/apperr"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/auth"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/db"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/httpx"
)

// sqlGroupName is a section's display name: "CSE 61 · A".
const sqlGroupName = `(g.department || ' ' || g.batch || CASE WHEN g.section <> '' THEN ' · ' || g.section ELSE '' END)`

func writeAudit(ctx context.Context, q db.Querier, actor uuid.UUID, action, targetType, targetID string, meta any) error {
	b, err := json.Marshal(meta)
	if err != nil || meta == nil {
		b = []byte("{}")
	}
	_, err = q.Exec(ctx, `INSERT INTO audit_log (actor_id, action, target_type, target_id, meta) VALUES ($1, $2, $3, $4, $5)`,
		actor, action, targetType, targetID, b)
	return err
}

// ---- making someone verified -----------------------------------------------------

// verifyNow marks the (already locked) student verified by method and writes
// the history row; the push goes out after the transaction commits.
func (s *Service) verifyNow(ctx context.Context, student, uni uuid.UUID, method string, actor uuid.UUID) error {
	now := s.now()
	q := s.d.Q(ctx)
	if _, err := q.Exec(ctx, `UPDATE users SET verified_at = $2, verified_via = $3 WHERE id = $1`, student, now, method); err != nil {
		return err
	}
	if _, err := q.Exec(ctx, `INSERT INTO verification_events (user_id, university_id, method, actor_id, created_at)
		VALUES ($1, $2, $3, $4, $5)`, student, uni, method, actor, now); err != nil {
		return err
	}
	name, err := s.uniName(ctx, uni)
	if err != nil {
		return err
	}
	db.AfterCommit(ctx, func(ctx context.Context) {
		if s.onVerified != nil {
			s.onVerified(ctx, student)
		}
		if s.notify == nil {
			return
		}
		s.notify([]uuid.UUID{student}, Notice{
			Texts: map[string]NoticeText{
				"en": {Title: "You're verified at " + name, Body: "You can now use everything in VarsityKotha"},
				"bn": {Title: name + "-এ তুমি এখন ভেরিফায়েড", Body: "এখন ভার্সিটি কথার সবকিছু ব্যবহার করতে পারবে"},
			},
			Data: map[string]string{"type": "campus_verified"},
		})
	})
	return nil
}

type lockedStudent struct {
	Uni      *uuid.UUID
	Verified bool
	Via      string
}

// lockStudent locks the student's row for a change.
func (s *Service) lockStudent(ctx context.Context, id uuid.UUID) (lockedStudent, error) {
	var l lockedStudent
	var via *string
	err := s.d.Q(ctx).QueryRow(ctx,
		`SELECT university_id, verified_at IS NOT NULL, verified_via FROM users WHERE id = $1 FOR UPDATE`, id).
		Scan(&l.Uni, &l.Verified, &via)
	if db.IsNoRows(err) {
		return l, ErrUserNotFound
	}
	if via != nil {
		l.Via = *via
	}
	return l, err
}

func (s *Service) vouchBlocked(ctx context.Context, id uuid.UUID) (bool, error) {
	var b bool
	err := s.d.Q(ctx).QueryRow(ctx, `SELECT EXISTS (SELECT 1 FROM vouch_blocks WHERE user_id = $1)`, id).Scan(&b)
	return b, err
}

// ---- my verification ----------------------------------------------------------------

type CRRef struct {
	GroupID   uuid.UUID `json:"groupId"`
	GroupName string    `json:"groupName"`
	CRID      uuid.UUID `json:"crId"`
	CRName    string    `json:"crName"`
}

type MyVerification struct {
	Verified      bool    `json:"verified"`
	Via           *string `json:"via"`
	EmailPossible bool    `json:"emailPossible"`
	Vouches       int     `json:"vouches"`
	Needed        int     `json:"needed"`
	VouchedBy     []Ref   `json:"vouchedBy"`
	Code          *string `json:"code"`
	Link          *string `json:"link"`
	CRs           []CRRef `json:"crs"`
}

const codeAlphabet = "abcdefghijklmnopqrstuvwxyz0123456789"

func newCode() string {
	b := make([]byte, 8)
	_, _ = rand.Read(b)
	for i := range b {
		b[i] = codeAlphabet[int(b[i])%len(codeAlphabet)]
	}
	return string(b)
}

// vouchCode returns the student's vouch code, making one on first use.
func (s *Service) vouchCode(ctx context.Context, id uuid.UUID) (string, error) {
	q := s.d.Q(ctx)
	for range 5 {
		var code *string
		if err := q.QueryRow(ctx, `SELECT vouch_code FROM users WHERE id = $1`, id).Scan(&code); err != nil {
			return "", err
		}
		if code != nil {
			return *code, nil
		}
		_, err := q.Exec(ctx, `UPDATE users SET vouch_code = $2 WHERE id = $1 AND vouch_code IS NULL`, id, newCode())
		if err != nil && !db.IsUniqueViolation(err) {
			return "", err
		}
	}
	return "", apperr.New(500, "INTERNAL", "Could not make a link")
}

// activeVouchers: who currently vouches for the student (still verified, not voided).
func (s *Service) activeVouchers(ctx context.Context, id uuid.UUID) ([]Ref, error) {
	rows, err := s.d.Q(ctx).Query(ctx, `
		SELECT v.voucher_id, coalesce(u.display_name, '') FROM vouches v JOIN users u ON u.id = v.voucher_id
		WHERE v.user_id = $1 AND v.void_at IS NULL AND u.verified_at IS NOT NULL ORDER BY v.created_at`, id)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []Ref{}
	for rows.Next() {
		var r Ref
		if err := rows.Scan(&r.ID, &r.Name); err != nil {
			return nil, err
		}
		out = append(out, r)
	}
	return out, rows.Err()
}

func (s *Service) handleMyVerification(ctx context.Context, _ *httpx.Empty) (*MyVerification, error) {
	me, err := s.caller(ctx)
	if err != nil {
		return nil, err
	}
	q := s.d.Q(ctx)
	out := &MyVerification{Verified: me.Verified, Needed: VouchesNeeded, VouchedBy: []Ref{}, CRs: []CRRef{}}
	if err := q.QueryRow(ctx, `SELECT verified_via FROM users WHERE id = $1`, me.ID).Scan(&out.Via); err != nil {
		return nil, err
	}
	if me.Uni != nil {
		if err := q.QueryRow(ctx, `SELECT EXISTS (SELECT 1 FROM university_domains WHERE university_id = $1)`, *me.Uni).
			Scan(&out.EmailPossible); err != nil {
			return nil, err
		}
		code, err := s.vouchCode(ctx, me.ID)
		if err != nil {
			return nil, err
		}
		link := LinkBase + code
		out.Code, out.Link = &code, &link
	}
	if out.VouchedBy, err = s.activeVouchers(ctx, me.ID); err != nil {
		return nil, err
	}
	out.Vouches = len(out.VouchedBy)
	rows, err := q.Query(ctx, `
		SELECT g.id, `+sqlGroupName+`, c.user_id, coalesce(cu.display_name, '')
		FROM class_group_members mine
		JOIN class_groups g ON g.id = mine.group_id
		JOIN class_group_members c ON c.group_id = g.id AND c.role = 'cr' AND c.user_id <> mine.user_id
		JOIN users cu ON cu.id = c.user_id AND cu.verified_at IS NOT NULL
		WHERE mine.user_id = $1 ORDER BY g.department, g.batch, g.section, c.joined_at`, me.ID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	for rows.Next() {
		var c CRRef
		if err := rows.Scan(&c.GroupID, &c.GroupName, &c.CRID, &c.CRName); err != nil {
			return nil, err
		}
		out.CRs = append(out.CRs, c)
	}
	return out, rows.Err()
}

// ---- vouching ---------------------------------------------------------------------------

type VouchStudent struct {
	ID             uuid.UUID `json:"id"`
	Name           string    `json:"name"`
	Department     *string   `json:"department"`
	Batch          *string   `json:"batch"`
	PhotoVersion   *string   `json:"photoVersion"`
	GooglePhotoURL *string   `json:"googlePhotoUrl"`
}

type VouchInfo struct {
	Student        VouchStudent `json:"student"`
	University     *Ref         `json:"university"`
	Vouches        int          `json:"vouches"`
	Needed         int          `json:"needed"`
	Verified       bool         `json:"verified"`
	AlreadyVouched bool         `json:"alreadyVouched"`
	CanVouch       bool         `json:"canVouch"`
	Reason         *string      `json:"reason"`
}

type codeReq struct {
	Code string `json:"-" path:"code" validate:"required,max=40"`
}

// vouchInfo reads the vouch page for code as viewer. forUpdate locks the
// student's row (the vouch itself).
func (s *Service) vouchInfo(ctx context.Context, viewer who, code string, forUpdate bool) (*VouchInfo, uuid.UUID, error) {
	q := s.d.Q(ctx)
	sql := `SELECT id, coalesce(display_name, ''), department, batch, photo_key, google_photo_url, university_id, verified_at IS NOT NULL
		FROM users WHERE vouch_code = $1`
	if forUpdate {
		sql += ` FOR UPDATE`
	}
	var (
		info VouchInfo
		uni  *uuid.UUID
	)
	st := &info.Student
	err := q.QueryRow(ctx, sql, code).Scan(&st.ID, &st.Name, &st.Department, &st.Batch, &st.PhotoVersion, &st.GooglePhotoURL, &uni, &info.Verified)
	if db.IsNoRows(err) {
		return nil, uuid.Nil, ErrVouchNotFound
	}
	if err != nil {
		return nil, uuid.Nil, err
	}
	if uni == nil {
		return nil, uuid.Nil, ErrVouchNotFound
	}
	info.University = &Ref{ID: *uni}
	if err := q.QueryRow(ctx, `SELECT name FROM universities WHERE id = $1`, *uni).Scan(&info.University.Name); err != nil {
		return nil, uuid.Nil, err
	}
	vs, err := s.activeVouchers(ctx, st.ID)
	if err != nil {
		return nil, uuid.Nil, err
	}
	info.Vouches, info.Needed = len(vs), VouchesNeeded
	for _, v := range vs {
		info.AlreadyVouched = info.AlreadyVouched || v.ID == viewer.ID
	}
	reason, err := s.vouchReason(ctx, viewer, st.ID, uni, info.Verified)
	if err != nil {
		return nil, uuid.Nil, err
	}
	if reason != "" {
		info.Reason = &reason
	}
	info.CanVouch = reason == "" && !info.AlreadyVouched
	return &info, st.ID, nil
}

// vouchReason is why viewer can't vouch for the student ("" = they can).
func (s *Service) vouchReason(ctx context.Context, viewer who, student uuid.UUID, uni *uuid.UUID, studentVerified bool) (string, error) {
	switch {
	case viewer.ID == student:
		return "self", nil
	case !viewer.Verified:
		return "not_verified", nil
	case viewer.Uni == nil || uni == nil || *viewer.Uni != *uni:
		return "other_university", nil
	}
	if blocked, err := s.vouchBlocked(ctx, viewer.ID); err != nil {
		return "", err
	} else if blocked {
		return "blocked", nil
	}
	var n int
	if err := s.d.Q(ctx).QueryRow(ctx, `SELECT count(*) FROM vouches WHERE voucher_id = $1 AND created_at > $2`,
		viewer.ID, s.now().Add(-30*24*time.Hour)).Scan(&n); err != nil {
		return "", err
	}
	if n >= VouchesPer30Days {
		return "limit", nil
	}
	if studentVerified {
		return "already_verified", nil
	}
	return "", nil
}

var reasonErrors = map[string]*apperr.Error{
	"self": ErrVouchSelf, "not_verified": ErrVerifyFirst, "other_university": ErrOtherUni,
	"blocked": ErrVouchBlocked, "limit": ErrVouchLimit, "already_verified": ErrAlreadyVerif,
}

func (s *Service) handleVouchInfo(ctx context.Context, in *codeReq) (*VouchInfo, error) {
	me, err := s.caller(ctx)
	if err != nil {
		return nil, err
	}
	info, _, err := s.vouchInfo(ctx, me, in.Code, false)
	return info, err
}

func (s *Service) handleVouch(ctx context.Context, in *codeReq) (*VouchInfo, error) {
	me, err := s.caller(ctx)
	if err != nil {
		return nil, err
	}
	var out *VouchInfo
	err = s.d.InTx(ctx, func(ctx context.Context) error {
		info, student, err := s.vouchInfo(ctx, me, in.Code, true)
		if err != nil {
			return err
		}
		if info.Reason != nil {
			if info.AlreadyVouched && *info.Reason == "already_verified" {
				out = info // vouched, and that was enough
				return nil
			}
			return reasonErrors[*info.Reason]
		}
		if info.AlreadyVouched {
			out = info
			return nil
		}
		now := s.now()
		if _, err := s.d.Q(ctx).Exec(ctx, `
			INSERT INTO vouches (user_id, voucher_id, created_at) VALUES ($1, $2, $3)
			ON CONFLICT (user_id, voucher_id) DO UPDATE SET void_at = NULL, created_at = EXCLUDED.created_at
			WHERE vouches.void_at IS NOT NULL`, student, me.ID, now); err != nil {
			return err
		}
		if err := s.audit(ctx, "campus.vouch", "user", student.String(), nil); err != nil {
			return err
		}
		vs, err := s.activeVouchers(ctx, student)
		if err != nil {
			return err
		}
		if len(vs) >= VouchesNeeded {
			if err := s.verifyNow(ctx, student, *me.Uni, "vouch", me.ID); err != nil {
				return err
			}
			if err := s.audit(ctx, "campus.verify", "user", student.String(), map[string]any{"method": "vouch"}); err != nil {
				return err
			}
		}
		info, _, err = s.vouchInfo(ctx, me, in.Code, false)
		out = info
		return err
	})
	return out, err
}

// ---- CR confirms ---------------------------------------------------------------------------

type confirmReq struct {
	ID   string `json:"-" path:"id" validate:"required,uuid"`
	User string `json:"-" path:"user" validate:"required,uuid"`
}

// Member is a section member as the CR sees them (the same shape as the
// class group member list).
type Member struct {
	UserID         uuid.UUID `json:"userId"`
	Name           string    `json:"name"`
	Role           string    `json:"role"`
	JoinedAt       time.Time `json:"joinedAt"`
	IsMe           bool      `json:"isMe"`
	Verified       bool      `json:"verified"`
	PhotoVersion   *string   `json:"photoVersion"`
	GooglePhotoURL *string   `json:"googlePhotoUrl"`
}

func (s *Service) handleConfirm(ctx context.Context, in *confirmReq) (*Member, error) {
	group, student := uuid.MustParse(in.ID), uuid.MustParse(in.User)
	me, err := s.caller(ctx)
	if err != nil {
		return nil, err
	}
	var out *Member
	err = s.d.InTx(ctx, func(ctx context.Context) error {
		q := s.d.Q(ctx)
		var isCR bool
		if err := q.QueryRow(ctx, `SELECT EXISTS (SELECT 1 FROM class_group_members WHERE group_id = $1 AND user_id = $2 AND role = 'cr')`,
			group, me.ID).Scan(&isCR); err != nil {
			return err
		}
		if !isCR {
			return ErrNotCR
		}
		if !me.Verified || me.Uni == nil {
			return ErrVerifyFirst
		}
		var isMember bool
		if err := q.QueryRow(ctx, `SELECT EXISTS (SELECT 1 FROM class_group_members WHERE group_id = $1 AND user_id = $2)`,
			group, student).Scan(&isMember); err != nil {
			return err
		}
		if !isMember {
			return ErrMemberNotFound
		}
		st, err := s.lockStudent(ctx, student)
		if err != nil {
			return err
		}
		if st.Uni == nil || *st.Uni != *me.Uni {
			return ErrOtherUni
		}
		if st.Verified {
			return ErrAlreadyVerif
		}
		if blocked, err := s.vouchBlocked(ctx, me.ID); err != nil {
			return err
		} else if blocked {
			return ErrVouchBlocked
		}
		var n int
		if err := q.QueryRow(ctx, `SELECT count(*) FROM verification_events WHERE actor_id = $1 AND method = 'cr' AND created_at > $2`,
			me.ID, s.now().Add(-30*24*time.Hour)).Scan(&n); err != nil {
			return err
		}
		if n >= ConfirmsPer30Days {
			return ErrConfirmLimit
		}
		if err := s.verifyNow(ctx, student, *me.Uni, "cr", me.ID); err != nil {
			return err
		}
		if err := s.audit(ctx, "campus.verify", "user", student.String(), map[string]any{"method": "cr", "groupId": group}); err != nil {
			return err
		}
		m := &Member{UserID: student, IsMe: student == auth.MustUser(ctx).UserID}
		err = q.QueryRow(ctx, `
			SELECT coalesce(u.display_name, ''), m.role, m.joined_at, u.verified_at IS NOT NULL, u.photo_key, u.google_photo_url
			FROM class_group_members m JOIN users u ON u.id = m.user_id WHERE m.group_id = $1 AND m.user_id = $2`, group, student).
			Scan(&m.Name, &m.Role, &m.JoinedAt, &m.Verified, &m.PhotoVersion, &m.GooglePhotoURL)
		out = m
		return err
	})
	return out, err
}
