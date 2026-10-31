package growth

import (
	"context"
	"time"

	"github.com/google/uuid"

	"github.com/zamansheikh/varsitykotha/backend/internal/platform/auth"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/db"
)

type ProfileUniversity struct {
	ID   uuid.UUID `json:"id"`
	Name string    `json:"name"`
	Slug string    `json:"slug"`
}

type ProfileBadge struct {
	Key      string    `json:"key"`
	Tier     int       `json:"tier"`
	EarnedAt time.Time `json:"earnedAt"`
	// Private: only the owner ever gets these.
	Private bool `json:"private"`
}

// Profile is what other students see of a student: never an email.
type Profile struct {
	ID         uuid.UUID          `json:"id"`
	Name       string             `json:"name"`
	Verified   bool               `json:"verified"`
	University *ProfileUniversity `json:"university"`
	Department *string            `json:"department"`
	Batch      *string            `json:"batch"`
	// JoinedAt: the first of the month they joined (month precision).
	JoinedAt       time.Time      `json:"joinedAt"`
	PhotoVersion   *string        `json:"photoVersion"`
	GooglePhotoURL *string        `json:"googlePhotoUrl"`
	FeaturedBadge  *BadgeRef      `json:"featuredBadge"`
	Badges         []ProfileBadge `json:"badges"`
	Roles          []string       `json:"roles"`
	InvitesJoined  int            `json:"invitesJoined"`
	Posts          any            `json:"posts"`
}

type profileReq struct {
	ID string `json:"-" path:"id" validate:"required,uuid"`
}

func (s *Service) handleProfile(ctx context.Context, in *profileReq) (*Profile, error) {
	c := auth.MustUser(ctx)
	id := uuid.MustParse(in.ID)
	q := s.d.Q(ctx)
	p := &Profile{ID: id, Badges: []ProfileBadge{}, Roles: []string{}}
	var (
		name                *string
		uniID               *uuid.UUID
		uniName, uniSlug    *string
		photo, google       *string
		featured            *string
		featuredTier        *int16
		created             time.Time
		cr, admin, rep, off bool
		shares              bool
	)
	err := q.QueryRow(ctx, `SELECT u.display_name, u.verified_at IS NOT NULL, u.university_id, un.name, un.slug, u.department, u.batch,
			u.created_at, u.photo_key, u.google_photo_url, fb.badge, fb.tier,
			EXISTS (SELECT 1 FROM class_group_members m WHERE m.user_id = u.id AND m.role = 'cr'),
			EXISTS (SELECT 1 FROM campus_admins x WHERE x.user_id = u.id),
			EXISTS (SELECT 1 FROM transport_reps x WHERE x.user_id = u.id),
			EXISTS (SELECT 1 FROM staff x WHERE x.user_id = u.id),
			-- the photo rule of GET /users/{id}/photo: a shared class group
			EXISTS (SELECT 1 FROM class_group_members a JOIN class_group_members b ON b.group_id = a.group_id
				WHERE a.user_id = $2 AND b.user_id = u.id),
			(SELECT count(*)::int FROM referrals r WHERE r.referrer_id = u.id AND r.qualified_at IS NOT NULL AND r.disqualified_at IS NULL)
		FROM users u
		LEFT JOIN universities un ON un.id = u.university_id
		LEFT JOIN user_badges fb ON fb.user_id = u.id AND fb.badge = u.featured_badge AND NOT fb.private
		WHERE u.id = $1 AND u.blocked_at IS NULL`, id, c.UserID).
		Scan(&name, &p.Verified, &uniID, &uniName, &uniSlug, &p.Department, &p.Batch,
			&created, &photo, &google, &featured, &featuredTier, &cr, &admin, &rep, &off, &shares, &p.InvitesJoined)
	if db.IsNoRows(err) {
		return nil, ErrUserNotFound
	}
	if err != nil {
		return nil, err
	}
	if name != nil {
		p.Name = *name
	}
	if uniID != nil && uniName != nil && uniSlug != nil {
		p.University = &ProfileUniversity{ID: *uniID, Name: *uniName, Slug: *uniSlug}
	}
	cd := created.UTC()
	p.JoinedAt = time.Date(cd.Year(), cd.Month(), 1, 0, 0, 0, 0, time.UTC)
	if id == c.UserID || c.Role == "admin" || shares {
		p.PhotoVersion, p.GooglePhotoURL = photo, google
	}
	if featured != nil && featuredTier != nil {
		p.FeaturedBadge = &BadgeRef{Key: *featured, Tier: int(*featuredTier)}
	}
	for _, r := range []struct {
		key string
		on  bool
	}{{"cr", cr}, {"campus_admin", admin}, {"bus_rep", rep}, {"official", off}} {
		if r.on {
			p.Roles = append(p.Roles, r.key)
		}
	}
	// A student looking at their own profile gets fresh badges, private
	// ones included; everyone else gets the public ones, refreshed now and
	// then so a profile isn't empty until the hourly sweep.
	if id == c.UserID || s.dueProfileRecompute(id) {
		if err := s.Recompute(ctx, id); err != nil {
			return nil, err
		}
	}
	rows, err := q.Query(ctx, `SELECT badge, tier, earned_at, private FROM user_badges
		WHERE user_id = $1 AND ($1 = $2 OR NOT private) ORDER BY earned_at, badge`, id, c.UserID)
	if err != nil {
		return nil, err
	}
	for rows.Next() {
		var b ProfileBadge
		if err := rows.Scan(&b.Key, &b.Tier, &b.EarnedAt, &b.Private); err != nil {
			rows.Close()
			return nil, err
		}
		b.EarnedAt = b.EarnedAt.UTC()
		p.Badges = append(p.Badges, b)
	}
	rows.Close()
	if err := rows.Err(); err != nil {
		return nil, err
	}
	p.Posts = []any{}
	if s.ports.Posts != nil {
		if p.Posts, err = s.ports.Posts(ctx, id); err != nil {
			return nil, err
		}
	}
	return p, nil
}

// dueProfileRecompute reports whether another student's badges should be
// recomputed for their profile, and marks them done.
func (s *Service) dueProfileRecompute(id uuid.UUID) bool {
	now := s.now()
	s.mu.Lock()
	defer s.mu.Unlock()
	if last, ok := s.recomputed[id]; ok && now.Sub(last) < profileRecomputeEvery {
		return false
	}
	if len(s.recomputed) > 50000 { // keep it small
		s.recomputed = map[uuid.UUID]time.Time{}
	}
	s.recomputed[id] = now
	return true
}
