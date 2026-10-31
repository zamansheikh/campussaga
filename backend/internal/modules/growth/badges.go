package growth

import (
	"context"
	"time"

	"github.com/google/uuid"

	"github.com/zamansheikh/varsitykotha/backend/internal/platform/auth"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/db"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/httpx"
)

// foundingBefore: accounts created before this get the founding badge.
var foundingBefore = time.Date(2027, 4, 1, 0, 0, 0, 0, dhaka)

type badgeDef struct {
	Key     string
	Tiers   []int // bronze / silver / gold thresholds; empty: no tiers
	Private bool  // only the owner sees it; it can't be featured
	// Role badges follow the role: they disappear when it ends. The others
	// keep their best tier.
	Role   bool
	NameEn string
	NameBn string
}

var catalog = []badgeDef{
	{Key: "verified", Role: true, NameEn: "Verified student", NameBn: "ভেরিফায়েড শিক্ষার্থী"},
	{Key: "founding", Role: true, NameEn: "Founding student", NameBn: "প্রতিষ্ঠাতা সদস্য"},
	{Key: "cr", Role: true, NameEn: "CR", NameBn: "সিআর"},
	{Key: "campus_admin", Role: true, NameEn: "Campus admin", NameBn: "ক্যাম্পাস অ্যাডমিন"},
	{Key: "bus_rep", Role: true, NameEn: "Bus rep", NameBn: "বাস প্রতিনিধি"},
	{Key: "official", Role: true, NameEn: "Official", NameBn: "কর্তৃপক্ষ"},
	{Key: "blood_donor", Role: true, NameEn: "Blood donor", NameBn: "রক্তদাতা"},
	{Key: "life_saver", Tiers: []int{1, 3, 5}, NameEn: "Life saver", NameBn: "জীবনরক্ষাকারী"},
	{Key: "bus_buddy", Tiers: []int{1, 10, 30}, NameEn: "Bus buddy", NameBn: "বাস বন্ধু"},
	{Key: "section_builder", Tiers: []int{20, 40, 60}, NameEn: "Section builder", NameBn: "সেকশন নির্মাতা"},
	{Key: "connector", Tiers: []int{5, 25, 100}, NameEn: "Connector", NameBn: "সংযোগকারী"},
	{Key: "bug_hunter", Tiers: []int{1, 3, 10}, NameEn: "Bug hunter", NameBn: "বাগ শিকারি"},
	{Key: "helper", Tiers: []int{10, 50, 200}, Private: true, NameEn: "Helper", NameBn: "সহায়ক"},
	{Key: "campus_voice", Tiers: []int{1, 3, 10}, Private: true, NameEn: "Campus voice", NameBn: "ক্যাম্পাস ভয়েস"},
}

func badgeByKey(key string) (badgeDef, bool) {
	for _, b := range catalog {
		if b.Key == key {
			return b, true
		}
	}
	return badgeDef{}, false
}

// tierOf is the tier a count reaches (0: none yet).
func (b badgeDef) tierOf(n int) int {
	t := 0
	for i, need := range b.Tiers {
		if n >= need {
			t = i + 1
		}
	}
	return t
}

var tierNames = [][2]string{{"", ""}, {"Bronze", "ব্রোঞ্জ"}, {"Silver", "সিলভার"}, {"Gold", "গোল্ড"}}

// held is a badge the student has now.
type held struct {
	Tier      int
	Private   bool
	EarnedAt  time.Time
	Persisted bool
}

// computed is what the student's data says right now: key -> tier (0 for a
// role or a badge without tiers). Counts for the private badges are
// aggregates only; no anonymous item is ever read back out.
func (s *Service) computed(ctx context.Context, id uuid.UUID) (map[string]int, error) {
	q := s.d.Q(ctx)
	var (
		verified, founding, cr, admin, rep, official, donor bool
		donations, trips, sectionMembers, qualified, bugs   int
		helper, solved                                      int
	)
	err := q.QueryRow(ctx, `SELECT
		u.verified_at IS NOT NULL,
		u.created_at < $2,
		EXISTS (SELECT 1 FROM class_group_members m WHERE m.user_id = u.id AND m.role = 'cr'),
		EXISTS (SELECT 1 FROM campus_admins c WHERE c.user_id = u.id),
		EXISTS (SELECT 1 FROM transport_reps t WHERE t.user_id = u.id),
		EXISTS (SELECT 1 FROM staff f WHERE f.user_id = u.id),
		EXISTS (SELECT 1 FROM blood_donors b WHERE b.user_id = u.id),
		coalesce((SELECT b.donations FROM blood_donors b WHERE b.user_id = u.id), 0),
		coalesce((SELECT t.trips FROM bus_share_stats t WHERE t.user_id = u.id), 0),
		coalesce((SELECT max(n) FROM (SELECT count(*)::int AS n FROM class_group_members x
			WHERE x.group_id IN (SELECT m.group_id FROM class_group_members m WHERE m.user_id = u.id AND m.role = 'cr')
			GROUP BY x.group_id) g), 0),
		(SELECT count(*)::int FROM referrals r WHERE r.referrer_id = u.id AND r.qualified_at IS NOT NULL AND r.disqualified_at IS NULL),
		(SELECT count(*)::int FROM feedback f WHERE f.user_id = u.id AND f.kind = 'bug' AND f.status = 'done'),
		-- Private badges: aggregate counts over the author tables, read for
		-- this student only and only ever shown to them.
		(SELECT count(*)::int FROM comment_authors ca JOIN comments c ON c.id = ca.comment_id AND c.visibility = 'visible'
			JOIN comment_likes l ON l.comment_id = c.id AND l.user_id <> ca.user_id WHERE ca.user_id = u.id),
		(SELECT count(*)::int FROM issue_authors ia JOIN issues i ON i.id = ia.issue_id
			WHERE ia.user_id = u.id AND i.kind = 'issue' AND i.status = 'solved' AND i.visibility = 'visible')
		FROM users u WHERE u.id = $1`, id, foundingBefore).
		Scan(&verified, &founding, &cr, &admin, &rep, &official, &donor, &donations, &trips, &sectionMembers, &qualified, &bugs, &helper, &solved)
	if err != nil {
		return nil, err
	}
	out := map[string]int{}
	for key, on := range map[string]bool{"verified": verified, "founding": founding, "cr": cr, "campus_admin": admin,
		"bus_rep": rep, "official": official, "blood_donor": donor} {
		if on {
			out[key] = 0
		}
	}
	for key, n := range map[string]int{"life_saver": donations, "bus_buddy": trips, "section_builder": sectionMembers,
		"connector": qualified, "bug_hunter": bugs, "helper": helper, "campus_voice": solved} {
		b, _ := badgeByKey(key)
		if t := b.tierOf(n); t > 0 {
			out[key] = t
		}
	}
	return out, nil
}

// Recompute brings user_badges in line with the student's data: role
// badges follow the role, activity badges keep their best tier, a featured
// badge that is gone is cleared, and a new badge or higher tier sends a
// badge_earned push. The very first computation for a student seeds
// silently (a new feature must not push everything they already had).
func (s *Service) Recompute(ctx context.Context, id uuid.UUID) error {
	type change struct {
		key  string
		tier int
	}
	var earned []change
	err := s.d.InTx(ctx, func(ctx context.Context) error {
		earned = nil
		q := s.d.Q(ctx)
		if _, err := q.Exec(ctx, `SELECT 1 FROM users WHERE id = $1 FOR UPDATE`, id); err != nil {
			return err
		}
		want, err := s.computed(ctx, id)
		if err != nil {
			return err
		}
		have := map[string]held{}
		rows, err := q.Query(ctx, `SELECT badge, tier, private, earned_at FROM user_badges WHERE user_id = $1`, id)
		if err != nil {
			return err
		}
		for rows.Next() {
			var key string
			var h held
			if err := rows.Scan(&key, &h.Tier, &h.Private, &h.EarnedAt); err != nil {
				rows.Close()
				return err
			}
			have[key] = h
		}
		rows.Close()
		if err := rows.Err(); err != nil {
			return err
		}
		first := len(have) == 0
		now := s.now()
		for _, def := range catalog {
			tier, on := want[def.Key]
			cur, had := have[def.Key]
			switch {
			case !on && had && def.Role:
				if _, err := q.Exec(ctx, `DELETE FROM user_badges WHERE user_id = $1 AND badge = $2`, id, def.Key); err != nil {
					return err
				}
			case on && (!had || tier > cur.Tier):
				if _, err := q.Exec(ctx, `INSERT INTO user_badges (user_id, badge, tier, private, earned_at) VALUES ($1, $2, $3, $4, $5)
					ON CONFLICT (user_id, badge) DO UPDATE SET tier = EXCLUDED.tier, earned_at = EXCLUDED.earned_at`,
					id, def.Key, tier, def.Private, now); err != nil {
					return err
				}
				if !first {
					earned = append(earned, change{def.Key, tier})
				}
			}
		}
		// The featured badge must still be a public one they hold.
		_, err = q.Exec(ctx, `UPDATE users u SET featured_badge = NULL WHERE u.id = $1 AND u.featured_badge IS NOT NULL
			AND NOT EXISTS (SELECT 1 FROM user_badges b WHERE b.user_id = u.id AND b.badge = u.featured_badge AND NOT b.private)`, id)
		return err
	})
	if err != nil {
		return err
	}
	for _, c := range earned {
		s.notifyBadge(id, c.key, c.tier)
	}
	return nil
}

func (s *Service) notifyBadge(id uuid.UUID, key string, tier int) {
	def, ok := badgeByKey(key)
	if s.notify == nil || !ok {
		return
	}
	en, bn := def.NameEn, def.NameBn
	if len(def.Tiers) > 0 && tier > 0 {
		en += " (" + tierNames[tier][0] + ")"
		bn += " (" + tierNames[tier][1] + ")"
	}
	s.notify([]uuid.UUID{id}, Notice{
		Texts: map[string]NoticeText{
			"en": {Title: "New badge: " + en, Body: "Tap to see your badges"},
			"bn": {Title: "নতুন ব্যাজ: " + bn, Body: "তোমার ব্যাজ দেখতে চাপো"},
		},
		Data: map[string]string{"type": "badge_earned", "badge": key, "tier": itoa(tier)},
	})
}

// ---- API ----------------------------------------------------------------------------

type BadgeRef struct {
	Key  string `json:"key"`
	Tier int    `json:"tier"`
}

type MyBadge struct {
	Key      string    `json:"key"`
	Tier     int       `json:"tier"`
	Private  bool      `json:"private"`
	EarnedAt time.Time `json:"earnedAt"`
}

type BadgeInfo struct {
	Key     string `json:"key"`
	Tiers   []int  `json:"tiers"`
	Private bool   `json:"private"`
}

type MyBadges struct {
	Badges   []MyBadge   `json:"badges"`
	Featured *BadgeRef   `json:"featured"`
	All      []BadgeInfo `json:"all"`
}

func (s *Service) myBadges(ctx context.Context, id uuid.UUID) (*MyBadges, error) {
	out := &MyBadges{Badges: []MyBadge{}, All: []BadgeInfo{}}
	for _, def := range catalog {
		tiers := def.Tiers
		if tiers == nil {
			tiers = []int{}
		}
		out.All = append(out.All, BadgeInfo{Key: def.Key, Tiers: tiers, Private: def.Private})
	}
	rows, err := s.d.Q(ctx).Query(ctx, `SELECT b.badge, b.tier, b.private, b.earned_at, coalesce(b.badge = u.featured_badge, false)
		FROM user_badges b JOIN users u ON u.id = b.user_id WHERE b.user_id = $1 ORDER BY b.earned_at, b.badge`, id)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	for rows.Next() {
		var b MyBadge
		var featured bool
		if err := rows.Scan(&b.Key, &b.Tier, &b.Private, &b.EarnedAt, &featured); err != nil {
			return nil, err
		}
		b.EarnedAt = b.EarnedAt.UTC()
		out.Badges = append(out.Badges, b)
		if featured && !b.Private {
			out.Featured = &BadgeRef{Key: b.Key, Tier: b.Tier}
		}
	}
	return out, rows.Err()
}

func (s *Service) handleMyBadges(ctx context.Context, _ *httpx.Empty) (*MyBadges, error) {
	me := auth.MustUser(ctx).UserID
	if err := s.Recompute(ctx, me); err != nil {
		return nil, err
	}
	return s.myBadges(ctx, me)
}

type featureReq struct {
	Key *string `json:"key" validate:"omitnil,max=40"`
}

type featureRes struct {
	Featured *BadgeRef `json:"featured"`
}

func (s *Service) handleFeature(ctx context.Context, in *featureReq) (*featureRes, error) {
	me := auth.MustUser(ctx).UserID
	if in.Key == nil || *in.Key == "" {
		if _, err := s.d.Q(ctx).Exec(ctx, `UPDATE users SET featured_badge = NULL WHERE id = $1`, me); err != nil {
			return nil, err
		}
		return &featureRes{}, nil
	}
	if err := s.Recompute(ctx, me); err != nil {
		return nil, err
	}
	var tier int
	var private bool
	err := s.d.Q(ctx).QueryRow(ctx, `SELECT tier, private FROM user_badges WHERE user_id = $1 AND badge = $2`, me, *in.Key).Scan(&tier, &private)
	if db.IsNoRows(err) {
		return nil, ErrBadgeNotHeld
	}
	if err != nil {
		return nil, err
	}
	if private {
		return nil, ErrBadgePrivate
	}
	if _, err := s.d.Q(ctx).Exec(ctx, `UPDATE users SET featured_badge = $2 WHERE id = $1`, me, *in.Key); err != nil {
		return nil, err
	}
	return &featureRes{Featured: &BadgeRef{Key: *in.Key, Tier: tier}}, nil
}
