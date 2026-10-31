package growth

import (
	"context"
	"fmt"
	"net/http"
	"regexp"
	"strings"
	"time"

	"github.com/google/uuid"

	"github.com/zamansheikh/varsitykotha/backend/internal/platform/apperr"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/auth"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/db"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/httpx"
)

// Low-cost rewards (docs/GROWTH.md §9): the section challenge, the race
// finisher reward and the campus ambassador.
const (
	ChampionMembers       = 25 // verified members a champion section needs
	ChampionSlots         = 5  // routine slots it needs
	SectionBoardSize      = 20
	AdminSectionBoardSize = 50
	AmbassadorMin         = 5  // same-university friends an ambassador needs
	KeepFinisherPhoneDays = 90 // phones go this long after the reward was sent
)

var (
	ErrNotAFinisher        = apperr.New(http.StatusForbidden, "NOT_A_FINISHER", "You haven't entered the prize race of this campaign")
	ErrNoReward            = apperr.New(http.StatusUnprocessableEntity, "NO_REWARD", "Your place isn't among the rewarded finishers")
	ErrInvalidPhone        = apperr.New(http.StatusBadRequest, "INVALID_PHONE", "Enter a Bangladesh mobile number: 01XXXXXXXXX")
	ErrFinisherNotFound    = apperr.New(http.StatusNotFound, "FINISHER_NOT_FOUND", "This student isn't a finisher of this campaign")
	ErrUniversityNotFound  = apperr.New(http.StatusNotFound, "UNIVERSITY_NOT_FOUND", "This university was not found")
	ErrFinisherRewardTitle = apperr.Validation(map[string]string{"finisherRewardEn": "required when finisherRewardCount is above 0"})
)

// verifiedMember: the class_group_members row m is a verified, not blocked
// student (joined as u).
const verifiedMember = `u.verified_at IS NOT NULL AND u.blocked_at IS NULL`

// ---- 9.1 section challenge ---------------------------------------------------------------

// SectionChallenge is the champion section goal, for the app.
type SectionChallenge struct {
	Members int `json:"members"`
	Slots   int `json:"slots"`
}

// SectionRow is one class group on the top sections board.
type SectionRow struct {
	Rank       int       `json:"rank"`
	GroupID    uuid.UUID `json:"groupId"`
	Name       string    `json:"name"`
	University string    `json:"university"`
	Members    int       `json:"members"` // verified
	Slots      int       `json:"slots"`
	Champion   bool      `json:"champion"`
}

type SectionBoard struct {
	Rows []SectionRow `json:"rows"`
	Mine *SectionRow  `json:"mine"`
}

// SectionCR is a section's CR, for the team.
type SectionCR struct {
	ID    uuid.UUID `json:"id"`
	Name  string    `json:"name"`
	Email string    `json:"email"`
}

type AdminSectionRow struct {
	SectionRow
	CR *SectionCR `json:"cr"`
}

type AdminSectionBoard struct {
	Rows []AdminSectionRow `json:"rows"`
}

// sectionBoardSQL ranks the class groups of $1's universities (all when
// null) by verified members; ties: the group whose last current verified
// member joined earlier (it reached the count first), then id. It returns the
// top $2 and every group $3 belongs to; $4: also the earliest CR.
const sectionBoardSQL = `
WITH g AS (
	SELECT g.id, g.department || ' ' || g.batch || CASE WHEN g.section <> '' THEN ' · ' || g.section ELSE '' END AS name,
	       un.name AS uni,
	       (SELECT count(*) FROM class_group_members m JOIN users u ON u.id = m.user_id WHERE m.group_id = g.id AND ` + verifiedMember + `)::int AS members,
	       (SELECT max(m.joined_at) FROM class_group_members m JOIN users u ON u.id = m.user_id WHERE m.group_id = g.id AND ` + verifiedMember + `) AS reached,
	       (SELECT count(*) FROM routine_slots rs WHERE rs.group_id = g.id)::int AS slots
	FROM class_groups g JOIN universities un ON un.id = g.university_id
	WHERE $1::uuid[] IS NULL OR g.university_id = ANY($1)),
ranked AS (
	SELECT g.*, row_number() OVER (ORDER BY g.members DESC, g.reached, g.id)::int AS rank FROM g WHERE g.members > 0)
SELECT r.rank, r.id, r.name, r.uni, r.members, r.slots,
       EXISTS (SELECT 1 FROM class_group_members m WHERE m.group_id = r.id AND m.user_id = $3),
       cr.id, coalesce(cr.display_name, ''), coalesce(cr.email, '')
FROM ranked r
LEFT JOIN LATERAL (SELECT u.id, u.display_name, u.email FROM class_group_members m JOIN users u ON u.id = m.user_id
                   WHERE m.group_id = r.id AND m.role = 'cr' ORDER BY m.joined_at, u.id LIMIT 1) cr ON $4::bool
WHERE r.rank <= $2 OR EXISTS (SELECT 1 FROM class_group_members m WHERE m.group_id = r.id AND m.user_id = $3)
ORDER BY r.rank`

type boardRow struct {
	SectionRow
	Mine bool
	CR   *SectionCR
}

func (s *Service) sectionBoard(ctx context.Context, c campaign, top int, me uuid.UUID, withCR bool) ([]boardRow, error) {
	rows, err := s.d.Q(ctx).Query(ctx, sectionBoardSQL, c.UniversityIDs, top, me, withCR)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var out []boardRow
	for rows.Next() {
		var r boardRow
		var crID *uuid.UUID
		var crName, crEmail string
		if err := rows.Scan(&r.Rank, &r.GroupID, &r.Name, &r.University, &r.Members, &r.Slots, &r.Mine, &crID, &crName, &crEmail); err != nil {
			return nil, err
		}
		r.Champion = r.Members >= ChampionMembers && r.Slots >= ChampionSlots
		if crID != nil {
			r.CR = &SectionCR{ID: *crID, Name: crName, Email: crEmail}
		}
		out = append(out, r)
	}
	return out, rows.Err()
}

func (s *Service) handleSections(ctx context.Context, in *campaignReq) (*SectionBoard, error) {
	me := auth.MustUser(ctx).UserID
	c, err := s.studentCampaign(ctx, in.ID)
	if err != nil {
		return nil, err
	}
	all, err := s.sectionBoard(ctx, c, SectionBoardSize, me, false)
	if err != nil {
		return nil, err
	}
	out := &SectionBoard{Rows: []SectionRow{}}
	for _, r := range all {
		if r.Rank <= SectionBoardSize {
			out.Rows = append(out.Rows, r.SectionRow)
		}
		if r.Mine && out.Mine == nil { // ordered by rank: my best group
			row := r.SectionRow
			out.Mine = &row
		}
	}
	return out, nil
}

func (s *Service) handleAdminSections(ctx context.Context, in *campaignReq) (*AdminSectionBoard, error) {
	c, err := s.loadCampaign(ctx, uuid.MustParse(in.ID), false)
	if err != nil {
		return nil, err
	}
	all, err := s.sectionBoard(ctx, c, AdminSectionBoardSize, uuid.Nil, true)
	if err != nil {
		return nil, err
	}
	out := &AdminSectionBoard{Rows: []AdminSectionRow{}}
	for _, r := range all {
		out.Rows = append(out.Rows, AdminSectionRow{SectionRow: r.SectionRow, CR: r.CR})
	}
	return out, nil
}

// ---- 9.2 race finishers ------------------------------------------------------------------

// FinisherReward is the reward for the first finishers, in my language.
type FinisherReward struct {
	Title string `json:"title"`
	Count int    `json:"count"`
	Left  int    `json:"left"` // rewarded places not taken yet
}

// MyFinisher is my place in the prize race.
type MyFinisher struct {
	Position int  `json:"position"`
	InReward bool `json:"inReward"`
	Claimed  bool `json:"claimed"`
	Sent     bool `json:"sent"`
}

func (c campaign) inReward(position int) bool {
	return c.FinisherRewardCount > 0 && position <= c.FinisherRewardCount
}

func (s *Service) myFinisher(ctx context.Context, c campaign, uid uuid.UUID) (*FinisherReward, *MyFinisher, error) {
	q := s.d.Q(ctx)
	var reward *FinisherReward
	if c.FinisherRewardCount > 0 {
		var taken int
		if err := q.QueryRow(ctx, `SELECT count(*)::int FROM campaign_finishers WHERE campaign_id = $1 AND position <= $2`,
			c.ID, c.FinisherRewardCount).Scan(&taken); err != nil {
			return nil, nil, err
		}
		reward = &FinisherReward{Title: pick(lang(ctx), c.FinisherRewardEn, c.FinisherRewardBn), Count: c.FinisherRewardCount,
			Left: max(c.FinisherRewardCount-taken, 0)}
	}
	var f MyFinisher
	err := q.QueryRow(ctx, `SELECT position, claimed_at IS NOT NULL, sent_at IS NOT NULL FROM campaign_finishers WHERE campaign_id = $1 AND user_id = $2`,
		c.ID, uid).Scan(&f.Position, &f.Claimed, &f.Sent)
	if db.IsNoRows(err) {
		return reward, nil, nil
	}
	if err != nil {
		return nil, nil, err
	}
	f.InReward = c.inReward(f.Position)
	return reward, &f, nil
}

// recordFinishers gives the next positions to the students who are in the
// prize race of a live campaign (inside its dates) and have none yet; only:
// just that student. Positions are handed out under a lock on the campaign
// row, so they never repeat or change; several new ones at once go in the
// standings order (points). Each new finisher gets race_finished and their
// badges refreshed after the commit.
func (s *Service) recordFinishers(ctx context.Context, cid uuid.UUID, only *uuid.UUID) error {
	return s.d.InTx(ctx, func(ctx context.Context) error {
		c, err := s.loadCampaign(ctx, cid, true)
		if err != nil {
			return err
		}
		now := s.now()
		if c.Status != "live" || now.Before(c.StartsAt) || now.After(c.EndsAt) {
			return nil
		}
		all, err := s.standings(ctx, c, nil, 1_000_000)
		if err != nil {
			return err
		}
		q := s.d.Q(ctx)
		have := map[uuid.UUID]bool{}
		rows, err := q.Query(ctx, `SELECT user_id FROM campaign_finishers WHERE campaign_id = $1`, c.ID)
		if err != nil {
			return err
		}
		for rows.Next() {
			var id uuid.UUID
			if err := rows.Scan(&id); err != nil {
				rows.Close()
				return err
			}
			have[id] = true
		}
		rows.Close()
		if err := rows.Err(); err != nil {
			return err
		}
		var next int
		if err := q.QueryRow(ctx, `SELECT coalesce(max(position), 0) FROM campaign_finishers WHERE campaign_id = $1`, c.ID).Scan(&next); err != nil {
			return err
		}
		type finisher struct {
			id  uuid.UUID
			pos int
		}
		var added []finisher
		for _, x := range all {
			if !x.Eligible {
				break // the eligible come first
			}
			if have[x.UserID] || (only != nil && x.UserID != *only) {
				continue
			}
			next++
			if _, err := q.Exec(ctx, `INSERT INTO campaign_finishers (campaign_id, user_id, position, finished_at) VALUES ($1, $2, $3, $4)`,
				c.ID, x.UserID, next, now); err != nil {
				return err
			}
			added = append(added, finisher{x.UserID, next})
		}
		if len(added) > 0 {
			db.AfterCommit(ctx, func(ctx context.Context) {
				for _, f := range added {
					s.notifyFinisher(c, f.id, f.pos)
					if err := s.Recompute(ctx, f.id); err != nil {
						s.log.Warn("growth: badges after finishing", "err", err)
					}
				}
			})
		}
		return nil
	})
}

// liveCampaigns: the live campaigns inside their dates; for: only those that
// cover this student's university (uuid.Nil: all).
func (s *Service) liveCampaigns(ctx context.Context, forUser uuid.UUID) ([]uuid.UUID, error) {
	rows, err := s.d.Q(ctx).Query(ctx, `SELECT c.id FROM campaigns c
		WHERE c.status = 'live' AND c.starts_at <= $1 AND c.ends_at >= $1
		  AND ($2::uuid IS NULL OR c.university_ids IS NULL
		       OR (SELECT u.university_id FROM users u WHERE u.id = $2) = ANY(c.university_ids))
		ORDER BY c.starts_at, c.id`, s.now(), nilIfZero(forUser))
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var out []uuid.UUID
	for rows.Next() {
		var id uuid.UUID
		if err := rows.Scan(&id); err != nil {
			return nil, err
		}
		out = append(out, id)
	}
	return out, rows.Err()
}

func nilIfZero(id uuid.UUID) *uuid.UUID {
	if id == uuid.Nil {
		return nil
	}
	return &id
}

// finishersFor checks a student who just got an invite counted.
func (s *Service) finishersFor(ctx context.Context, uid uuid.UUID) {
	ids, err := s.liveCampaigns(ctx, uid)
	if err != nil {
		s.log.Warn("growth: finishers", "err", err)
		return
	}
	for _, id := range ids {
		if err := s.recordFinishers(ctx, id, &uid); err != nil {
			s.log.Warn("growth: finishers", "err", err)
		}
	}
}

func (s *Service) notifyFinisher(c campaign, uid uuid.UUID, pos int) {
	if s.notify == nil {
		return
	}
	texts := map[string]NoticeText{
		"en": {Title: "You're in the prize race!", Body: c.TitleEn},
		"bn": {Title: "তুমি পুরস্কারের দৌড়ে আছ!", Body: cmpOr(c.TitleBn, c.TitleEn)},
	}
	if c.inReward(pos) {
		texts = map[string]NoticeText{
			"en": {Title: "You're in the prize race!",
				Body: fmt.Sprintf("You're finisher #%d: %s. Add your number to get it.", pos, c.FinisherRewardEn)},
			"bn": {Title: "তুমি পুরস্কারের দৌড়ে!",
				Body: fmt.Sprintf("তুমি #%d নম্বর: %s। পেতে তোমার নম্বর দাও।", pos, cmpOr(c.FinisherRewardBn, c.FinisherRewardEn))},
		}
	}
	s.notify([]uuid.UUID{uid}, Notice{Texts: texts, Data: map[string]string{"type": "race_finished", "campaignId": c.ID.String()}})
}

// ---- finisher claim ----

var bdMobile = regexp.MustCompile(`^01[3-9][0-9]{8}$`)

// normalizePhone reads a Bangladesh mobile number: spaces, dashes, dots and
// brackets are dropped, Bangla digits read as digits, +880 / 880 become 0.
// The result is 01XXXXXXXXX (operators 013-019).
func normalizePhone(raw string) (string, bool) {
	p := strings.Map(func(r rune) rune {
		switch {
		case r == ' ' || r == '-' || r == '.' || r == '(' || r == ')':
			return -1
		case r >= '০' && r <= '৯':
			return '0' + (r - '০')
		}
		return r
	}, strings.TrimSpace(raw))
	switch {
	case strings.HasPrefix(p, "+880"):
		p = "0" + strings.TrimPrefix(p, "+880")
	case strings.HasPrefix(p, "880") && len(p) == 13:
		p = "0" + p[3:]
	}
	return p, bdMobile.MatchString(p)
}

type finisherClaimReq struct {
	ID    string `json:"-" path:"id" validate:"required,uuid"`
	Phone string `json:"phone"`
}

func (s *Service) handleFinisherClaim(ctx context.Context, in *finisherClaimReq) (*httpx.Empty, error) {
	me := auth.MustUser(ctx).UserID
	c, err := s.studentCampaign(ctx, in.ID)
	if err != nil {
		return nil, err
	}
	return nil, s.d.InTx(ctx, func(ctx context.Context) error {
		q := s.d.Q(ctx)
		var pos int
		var claimed *time.Time
		err := q.QueryRow(ctx, `SELECT position, claimed_at FROM campaign_finishers WHERE campaign_id = $1 AND user_id = $2 FOR UPDATE`,
			c.ID, me).Scan(&pos, &claimed)
		if db.IsNoRows(err) {
			return ErrNotAFinisher
		}
		if err != nil {
			return err
		}
		if !c.inReward(pos) {
			return ErrNoReward
		}
		if claimed != nil {
			return ErrAlreadyClaimed
		}
		phone, ok := normalizePhone(in.Phone)
		if !ok {
			return ErrInvalidPhone
		}
		_, err = q.Exec(ctx, `UPDATE campaign_finishers SET phone = $3, claimed_at = $4 WHERE campaign_id = $1 AND user_id = $2`,
			c.ID, me, phone, s.now())
		return err
	})
}

// ---- admin: finishers ----

// FinisherRow is a finisher as the team sees them.
type FinisherRow struct {
	Position   int          `json:"position"`
	User       StandingUser `json:"user"`
	FinishedAt time.Time    `json:"finishedAt"`
	InReward   bool         `json:"inReward"`
	Phone      *string      `json:"phone"`
	ClaimedAt  *time.Time   `json:"claimedAt"`
	SentAt     *time.Time   `json:"sentAt"`
}

func (s *Service) handleAdminFinishers(ctx context.Context, in *campaignReq) (*[]FinisherRow, error) {
	c, err := s.loadCampaign(ctx, uuid.MustParse(in.ID), false)
	if err != nil {
		return nil, err
	}
	rows, err := s.d.Q(ctx).Query(ctx, `SELECT f.position, u.id, coalesce(u.display_name, ''), u.email, coalesce(un.name, ''),
			f.finished_at, f.phone, f.claimed_at, f.sent_at
		FROM campaign_finishers f JOIN users u ON u.id = f.user_id LEFT JOIN universities un ON un.id = u.university_id
		WHERE f.campaign_id = $1 ORDER BY f.position`, c.ID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []FinisherRow{}
	for rows.Next() {
		var f FinisherRow
		if err := rows.Scan(&f.Position, &f.User.ID, &f.User.Name, &f.User.Email, &f.User.University,
			&f.FinishedAt, &f.Phone, &f.ClaimedAt, &f.SentAt); err != nil {
			return nil, err
		}
		f.FinishedAt = f.FinishedAt.UTC()
		f.ClaimedAt, f.SentAt = utcPtr(f.ClaimedAt), utcPtr(f.SentAt)
		f.InReward = c.inReward(f.Position)
		out = append(out, f)
	}
	return &out, rows.Err()
}

func utcPtr(t *time.Time) *time.Time {
	if t == nil {
		return nil
	}
	u := t.UTC()
	return &u
}

func (s *Service) handleAdminFinisherSent(ctx context.Context, in *reasonReq) (*httpx.Empty, error) {
	cid, uid := uuid.MustParse(in.ID), uuid.MustParse(in.UserID)
	return nil, s.d.InTx(ctx, func(ctx context.Context) error {
		if _, err := s.loadCampaign(ctx, cid, false); err != nil {
			return err
		}
		var pos int
		err := s.d.Q(ctx).QueryRow(ctx, `UPDATE campaign_finishers SET sent_at = coalesce(sent_at, $3), sent_by = coalesce(sent_by, $4)
			WHERE campaign_id = $1 AND user_id = $2 RETURNING position`, cid, uid, s.now(), auth.MustUser(ctx).UserID).Scan(&pos)
		if db.IsNoRows(err) {
			return ErrFinisherNotFound
		}
		if err != nil {
			return err
		}
		return s.audit(ctx, "campaign.finisher_sent", "campaign", cid.String(), map[string]any{"userId": uid, "position": pos})
	})
}

// ---- 9.3 campus ambassador -----------------------------------------------------------------

// ambassadorsSQL: per university ($1: one, or all when null), the verified,
// not blocked, non-team student with the most counted invites (qualified,
// not disqualified, not on the same phone) of friends at the same
// university, at least $2; ties: who reached the count first (their latest
// counted qualified_at), then id.
const ambassadorsSQL = `
SELECT DISTINCT ON (uni) uni, user_id, n FROM (
	SELECT rr.university_id AS uni, r.referrer_id AS user_id, count(*)::int AS n, max(r.qualified_at) AS reached
	FROM referrals r JOIN users f ON f.id = r.referred_id JOIN users rr ON rr.id = r.referrer_id
	WHERE r.qualified_at IS NOT NULL AND r.disqualified_at IS NULL AND NOT r.same_device
	  AND rr.university_id IS NOT NULL AND f.university_id = rr.university_id
	  AND rr.verified_at IS NOT NULL AND rr.blocked_at IS NULL AND rr.role NOT IN ('admin', 'moderator')
	  AND ($1::uuid IS NULL OR rr.university_id = $1)
	GROUP BY rr.university_id, r.referrer_id
	HAVING count(*) >= $2) x
ORDER BY uni, n DESC, reached, user_id`

type ambassadorPick struct {
	UserID  uuid.UUID
	Invites int
}

// ambassadors: university -> its ambassador (uni nil: every university).
func (s *Service) ambassadors(ctx context.Context, uni *uuid.UUID) (map[uuid.UUID]ambassadorPick, error) {
	rows, err := s.d.Q(ctx).Query(ctx, ambassadorsSQL, uni, AmbassadorMin)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := map[uuid.UUID]ambassadorPick{}
	for rows.Next() {
		var u uuid.UUID
		var p ambassadorPick
		if err := rows.Scan(&u, &p.UserID, &p.Invites); err != nil {
			return nil, err
		}
		out[u] = p
	}
	return out, rows.Err()
}

// isAmbassador: the student is their university's ambassador now.
func (s *Service) isAmbassador(ctx context.Context, uni *uuid.UUID, uid uuid.UUID) (bool, error) {
	if uni == nil {
		return false, nil
	}
	m, err := s.ambassadors(ctx, uni)
	if err != nil {
		return false, err
	}
	p, ok := m[*uni]
	return ok && p.UserID == uid, nil
}

// Ambassador is a university's ambassador, for the team.
type Ambassador struct {
	ID      uuid.UUID `json:"id"`
	Name    string    `json:"name"`
	Email   string    `json:"email"`
	Invites int       `json:"invites"`
}

// UniversityGrowth is the growth part of a university's admin page.
type UniversityGrowth struct {
	Ambassador *Ambassador `json:"ambassador"`
}

func (s *Service) handleAdminUniversityGrowth(ctx context.Context, in *userIDReq) (*UniversityGrowth, error) {
	uni := uuid.MustParse(in.ID)
	var exists bool
	if err := s.d.Q(ctx).QueryRow(ctx, `SELECT EXISTS (SELECT 1 FROM universities WHERE id = $1)`, uni).Scan(&exists); err != nil {
		return nil, err
	}
	if !exists {
		return nil, ErrUniversityNotFound
	}
	m, err := s.ambassadors(ctx, &uni)
	if err != nil {
		return nil, err
	}
	out := &UniversityGrowth{}
	if p, ok := m[uni]; ok {
		a := Ambassador{ID: p.UserID, Invites: p.Invites}
		if err := s.d.Q(ctx).QueryRow(ctx, `SELECT coalesce(display_name, ''), email FROM users WHERE id = $1`, p.UserID).Scan(&a.Name, &a.Email); err != nil {
			return nil, err
		}
		out.Ambassador = &a
	}
	return out, nil
}
