package growth

import (
	"context"
	"crypto/rand"
	"strings"
	"time"

	"github.com/google/uuid"

	"github.com/zamansheikh/varsitykotha/backend/internal/platform/apperr"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/auth"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/db"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/httpx"
)

const codeAlphabet = "abcdefghijklmnopqrstuvwxyz0123456789"

// newCode: 8 characters [a-z0-9].
func newCode() string {
	b := make([]byte, 8)
	_, _ = rand.Read(b)
	for i := range b {
		b[i] = codeAlphabet[int(b[i])%len(codeAlphabet)]
	}
	return string(b)
}

// Code returns the student's invite code, making one on first use.
func (s *Service) Code(ctx context.Context, id uuid.UUID) (string, error) {
	q := s.d.Q(ctx)
	for range 5 {
		var code *string
		if err := q.QueryRow(ctx, `SELECT referral_code FROM users WHERE id = $1`, id).Scan(&code); err != nil {
			return "", err
		}
		if code != nil {
			return *code, nil
		}
		_, err := q.Exec(ctx, `UPDATE users SET referral_code = $2 WHERE id = $1 AND referral_code IS NULL`, id, newCode())
		if err != nil && !db.IsUniqueViolation(err) {
			return "", err
		}
	}
	return "", apperr.New(500, "INTERNAL", "Could not make an invite link")
}

// ---- claim --------------------------------------------------------------------------

type claimReq struct {
	Code   string `json:"code" validate:"required,max=40"`
	Source string `json:"source" validate:"omitempty,oneof=link join"`
}

func (s *Service) handleClaim(ctx context.Context, in *claimReq) (*httpx.Empty, error) {
	me := auth.MustUser(ctx).UserID
	code := strings.ToLower(strings.TrimSpace(in.Code))
	source := in.Source
	if source == "" {
		source = "link"
	}
	now := s.now()
	return nil, s.d.InTx(ctx, func(ctx context.Context) error {
		q := s.d.Q(ctx)
		var created time.Time
		var already bool
		if err := q.QueryRow(ctx, `SELECT u.created_at, EXISTS (SELECT 1 FROM referrals WHERE referred_id = u.id)
			FROM users u WHERE u.id = $1 FOR UPDATE`, me).Scan(&created, &already); err != nil {
			return err
		}
		if already {
			return ErrAlreadyReferred
		}
		if now.Sub(created) > ClaimWithinDays*24*time.Hour {
			return ErrReferralTooLate
		}
		var referrer uuid.UUID
		err := q.QueryRow(ctx, `SELECT id FROM users WHERE referral_code = $1 AND role = 'student' AND blocked_at IS NULL`, code).Scan(&referrer)
		if db.IsNoRows(err) {
			return ErrReferralNotFound
		}
		if err != nil {
			return err
		}
		if referrer == me {
			return ErrReferralSelf
		}
		same, err := s.sharesDevice(ctx, referrer, me)
		if err != nil {
			return err
		}
		_, err = q.Exec(ctx, `INSERT INTO referrals (referred_id, referrer_id, source, created_at, same_device) VALUES ($1, $2, $3, $4, $5)`,
			me, referrer, source, now, same)
		if db.IsUniqueViolation(err) {
			return ErrAlreadyReferred
		}
		return err
	})
}

// sharesDevice: the two accounts used one phone's push token (tokens only:
// no Firebase installation id is stored).
func (s *Service) sharesDevice(ctx context.Context, a, b uuid.UUID) (bool, error) {
	var same bool
	err := s.d.Q(ctx).QueryRow(ctx, `SELECT EXISTS (
		SELECT 1 FROM device_token_users x JOIN device_token_users y ON y.token_hash = x.token_hash
		WHERE x.user_id = $1 AND y.user_id = $2)`, a, b).Scan(&same)
	return same, err
}

// ---- qualification ------------------------------------------------------------------

// Qualify checks the invite of a friend (referred) and, when it counts,
// marks it qualified, tells the inviter and refreshes their badges. It is
// safe to call any time: nothing happens when the invite is already
// qualified, disqualified or the friend is not there yet.
func (s *Service) Qualify(ctx context.Context, referred uuid.UUID) error {
	q := s.d.Q(ctx)
	var (
		referrer        uuid.UUID
		same            bool
		created         time.Time
		verified        *time.Time
		name            *string
		blocked         bool
		referrerBlocked bool
	)
	err := q.QueryRow(ctx, `SELECT r.referrer_id, r.same_device, u.created_at, u.verified_at, u.display_name, u.blocked_at IS NOT NULL,
			rr.blocked_at IS NOT NULL
		FROM referrals r JOIN users u ON u.id = r.referred_id JOIN users rr ON rr.id = r.referrer_id
		WHERE r.referred_id = $1 AND r.qualified_at IS NULL AND r.disqualified_at IS NULL`, referred).
		Scan(&referrer, &same, &created, &verified, &name, &blocked, &referrerBlocked)
	if db.IsNoRows(err) {
		return nil
	}
	if err != nil {
		return err
	}
	if !same {
		if same, err = s.sharesDevice(ctx, referrer, referred); err != nil {
			return err
		}
		if same {
			if _, err := q.Exec(ctx, `UPDATE referrals SET same_device = true WHERE referred_id = $1`, referred); err != nil {
				return err
			}
		}
	}
	end := created.Add(WindowDays * 24 * time.Hour)
	if same || blocked || referrerBlocked || verified == nil || verified.After(end) {
		return nil
	}
	first, err := time.Parse(time.DateOnly, dhakaDay(created))
	if err != nil {
		return err
	}
	var days int
	if err := q.QueryRow(ctx, `SELECT count(*)::int FROM user_active_days WHERE user_id = $1 AND day >= $2 AND day < $3`,
		referred, first, first.AddDate(0, 0, WindowDays)).Scan(&days); err != nil {
		return err
	}
	if days < ActiveDaysNeed {
		return nil
	}
	tag, err := q.Exec(ctx, `UPDATE referrals SET qualified_at = $2 WHERE referred_id = $1 AND qualified_at IS NULL AND disqualified_at IS NULL`,
		referred, s.now())
	if err != nil || tag.RowsAffected() == 0 {
		return err
	}
	friend := ""
	if name != nil {
		friend = *name
	}
	s.notifyJoined(referrer, friend)
	if err := s.Recompute(ctx, referrer); err != nil {
		s.log.Warn("growth: badges after an invite", "err", err)
	}
	// This invite may put them in a live campaign's prize race (§9.2).
	s.finishersFor(ctx, referrer)
	return nil
}

func (s *Service) notifyJoined(referrer uuid.UUID, friend string) {
	if s.notify == nil {
		return
	}
	en, bn := friend, friend
	if friend == "" {
		en, bn = "A friend", "একজন বন্ধু"
	}
	s.notify([]uuid.UUID{referrer}, Notice{
		Texts: map[string]NoticeText{
			"en": {Title: en + " joined VarsityKotha with your link", Body: "Tap to see your invites"},
			"bn": {Title: bn + " তোমার লিংক দিয়ে ভার্সিটি কথায় যোগ দিয়েছে", Body: "তোমার আমন্ত্রণ দেখতে চাপো"},
		},
		Data: map[string]string{"type": "referral_joined"},
	})
}

// QualifyPending re-checks every invite that can still qualify.
func (s *Service) QualifyPending(ctx context.Context) error {
	rows, err := s.d.Q(ctx).Query(ctx, `SELECT r.referred_id FROM referrals r JOIN users u ON u.id = r.referred_id
		WHERE r.qualified_at IS NULL AND r.disqualified_at IS NULL AND u.created_at > $1`,
		s.now().Add(-(WindowDays+2)*24*time.Hour))
	if err != nil {
		return err
	}
	var ids []uuid.UUID
	for rows.Next() {
		var id uuid.UUID
		if err := rows.Scan(&id); err != nil {
			rows.Close()
			return err
		}
		ids = append(ids, id)
	}
	rows.Close()
	if err := rows.Err(); err != nil {
		return err
	}
	for _, id := range ids {
		if err := s.Qualify(ctx, id); err != nil {
			s.log.Warn("growth: qualify", "err", err)
		}
	}
	return nil
}

// OnVerified runs when a student has just become verified.
func (s *Service) OnVerified(ctx context.Context, id uuid.UUID) {
	if err := s.Qualify(ctx, id); err != nil {
		s.log.Warn("growth: qualify", "err", err)
	}
	if err := s.Recompute(ctx, id); err != nil {
		s.log.Warn("growth: badges", "err", err)
	}
}

// ---- views --------------------------------------------------------------------------

type Pending struct {
	Name       string    `json:"name"`
	Verified   bool      `json:"verified"`
	ActiveDays int       `json:"activeDays"`
	CreatedAt  time.Time `json:"createdAt"`
}

type RecentJoin struct {
	Name        string    `json:"name"`
	QualifiedAt time.Time `json:"qualifiedAt"`
}

type MyReferrals struct {
	Code    string       `json:"code"`
	Link    string       `json:"link"`
	Invited int          `json:"invited"`
	Joined  int          `json:"joined"`
	Pending []Pending    `json:"pending"`
	Recent  []RecentJoin `json:"recent"`
}

func (s *Service) handleMyReferrals(ctx context.Context, _ *httpx.Empty) (*MyReferrals, error) {
	me := auth.MustUser(ctx).UserID
	code, err := s.Code(ctx, me)
	if err != nil {
		return nil, err
	}
	q := s.d.Q(ctx)
	out := &MyReferrals{Code: code, Link: LinkBase + code, Pending: []Pending{}, Recent: []RecentJoin{}}
	if err := q.QueryRow(ctx, `SELECT count(*)::int, (count(*) FILTER (WHERE qualified_at IS NOT NULL))::int
		FROM referrals WHERE referrer_id = $1 AND disqualified_at IS NULL`, me).Scan(&out.Invited, &out.Joined); err != nil {
		return nil, err
	}
	// Friends who can still qualify: inside their 14 days, not on the same phone.
	rows, err := q.Query(ctx, `SELECT coalesce(u.display_name, ''), u.verified_at IS NOT NULL, r.created_at,
			(SELECT count(*) FROM user_active_days a WHERE a.user_id = u.id
			 AND a.day >= (u.created_at AT TIME ZONE 'Asia/Dhaka')::date AND a.day < (u.created_at AT TIME ZONE 'Asia/Dhaka')::date + $3::int)::int
		FROM referrals r JOIN users u ON u.id = r.referred_id
		WHERE r.referrer_id = $1 AND r.qualified_at IS NULL AND r.disqualified_at IS NULL AND NOT r.same_device
		  AND u.created_at + make_interval(days => $3::int) > $2
		ORDER BY r.created_at DESC LIMIT 50`, me, s.now(), WindowDays)
	if err != nil {
		return nil, err
	}
	for rows.Next() {
		var p Pending
		if err := rows.Scan(&p.Name, &p.Verified, &p.CreatedAt, &p.ActiveDays); err != nil {
			rows.Close()
			return nil, err
		}
		p.ActiveDays, p.CreatedAt = min(p.ActiveDays, ActiveDaysNeed), p.CreatedAt.UTC()
		out.Pending = append(out.Pending, p)
	}
	rows.Close()
	if err := rows.Err(); err != nil {
		return nil, err
	}
	rows, err = q.Query(ctx, `SELECT coalesce(u.display_name, ''), r.qualified_at FROM referrals r JOIN users u ON u.id = r.referred_id
		WHERE r.referrer_id = $1 AND r.qualified_at IS NOT NULL AND r.disqualified_at IS NULL
		ORDER BY r.qualified_at DESC LIMIT 10`, me)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	for rows.Next() {
		var x RecentJoin
		if err := rows.Scan(&x.Name, &x.QualifiedAt); err != nil {
			return nil, err
		}
		x.QualifiedAt = x.QualifiedAt.UTC()
		out.Recent = append(out.Recent, x)
	}
	return out, rows.Err()
}

type lookupReq struct {
	Code string `json:"-" path:"code" validate:"required,max=40"`
}

type LookupRes struct {
	Name       string `json:"name"`
	University *struct {
		Name string `json:"name"`
	} `json:"university"`
}

// handleLookup serves the web invite page: who invited, no sign-in needed.
// Only the first name-level facts are public: a display name and the
// university name.
func (s *Service) handleLookup(ctx context.Context, in *lookupReq) (*LookupRes, error) {
	var name, uni *string
	err := s.d.Q(ctx).QueryRow(ctx, `SELECT u.display_name, un.name FROM users u LEFT JOIN universities un ON un.id = u.university_id
		WHERE u.referral_code = $1 AND u.role = 'student' AND u.blocked_at IS NULL`, strings.ToLower(in.Code)).Scan(&name, &uni)
	if db.IsNoRows(err) || (err == nil && name == nil) {
		return nil, ErrReferralNotFound
	}
	if err != nil {
		return nil, err
	}
	out := &LookupRes{Name: *name}
	if uni != nil {
		out.University = &struct {
			Name string `json:"name"`
		}{Name: *uni}
	}
	return out, nil
}
