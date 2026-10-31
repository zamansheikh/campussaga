package growth

import (
	"context"
	"encoding/json"
	"slices"
	"strconv"
	"strings"
	"time"

	"github.com/google/uuid"

	"github.com/zamansheikh/varsitykotha/backend/internal/platform/apperr"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/auth"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/db"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/httpx"
)

func (s *Service) audit(ctx context.Context, action, targetType, targetID string, meta any) error {
	b, err := json.Marshal(meta)
	if err != nil || meta == nil {
		b = []byte("{}")
	}
	_, err = s.d.Q(ctx).Exec(ctx, `INSERT INTO audit_log (actor_id, action, target_type, target_id, meta) VALUES ($1, $2, $3, $4, $5)`,
		auth.MustUser(ctx).UserID, action, targetType, targetID, b)
	return err
}

func atoi(s string) int { n, _ := strconv.Atoi(s); return n }

// ---- campaigns: create, list, edit ---------------------------------------------------

// AdminCampaign is a campaign with both languages, for the admin panel.
type AdminCampaign struct {
	ID            uuid.UUID   `json:"id"`
	TitleEn       string      `json:"titleEn"`
	TitleBn       string      `json:"titleBn"`
	BodyEn        string      `json:"bodyEn"`
	BodyBn        string      `json:"bodyBn"`
	RulesEn       string      `json:"rulesEn"`
	RulesBn       string      `json:"rulesBn"`
	StartsAt      time.Time   `json:"startsAt"`
	EndsAt        time.Time   `json:"endsAt"`
	SettlesAt     time.Time   `json:"settlesAt"`
	UniversityIDs []uuid.UUID `json:"universityIds"`
	Prizes        []Prize     `json:"prizes"`
	Status        string      `json:"status"`
	CreatedAt     time.Time   `json:"createdAt"`
	UpdatedAt     time.Time   `json:"updatedAt"`
	BannerURL     *string     `json:"bannerUrl"`
	Scoring       Scoring     `json:"scoring"`
}

func (s *Service) adminView(c campaign) AdminCampaign {
	return AdminCampaign{
		ID: c.ID, TitleEn: c.TitleEn, TitleBn: c.TitleBn, BodyEn: c.BodyEn, BodyBn: c.BodyBn, RulesEn: c.RulesEn, RulesBn: c.RulesBn,
		StartsAt: c.StartsAt.UTC(), EndsAt: c.EndsAt.UTC(), SettlesAt: c.SettlesAt.UTC(), UniversityIDs: c.UniversityIDs,
		Prizes: c.Prizes, Status: c.state(s.now()), CreatedAt: c.CreatedAt.UTC(), UpdatedAt: c.UpdatedAt.UTC(),
		BannerURL: c.bannerURL(), Scoring: c.Scoring,
	}
}

type campaignInput struct {
	// Scoring: point values merged over the defaults (§8.1).
	Scoring       *ScoringInput `json:"scoring"`
	TitleEn       string        `json:"titleEn" validate:"required,max=120"`
	TitleBn       string        `json:"titleBn" validate:"max=120"`
	BodyEn        string        `json:"bodyEn" validate:"max=2000"`
	BodyBn        string        `json:"bodyBn" validate:"max=2000"`
	RulesEn       string        `json:"rulesEn" validate:"max=8000"`
	RulesBn       string        `json:"rulesBn" validate:"max=8000"`
	StartsAt      time.Time     `json:"startsAt" validate:"required"`
	EndsAt        time.Time     `json:"endsAt" validate:"required"`
	SettlesAt     *time.Time    `json:"settlesAt"`
	UniversityIDs []uuid.UUID   `json:"universityIds" validate:"max=200"`
	Prizes        []Prize       `json:"prizes" validate:"max=20,dive"`
}

func checkDates(starts, ends, settles time.Time) error {
	if !ends.After(starts) || settles.Before(ends) {
		return ErrCampaignDates
	}
	return nil
}

// checkPrizes: ranks from <= to, no two rows share a rank.
func checkPrizes(ps []Prize) error {
	sorted := slices.Clone(ps)
	slices.SortFunc(sorted, func(a, b Prize) int { return a.RankFrom - b.RankFrom })
	for i, p := range sorted {
		if p.RankTo < p.RankFrom || (i > 0 && p.RankFrom <= sorted[i-1].RankTo) {
			return ErrCampaignPrizes
		}
	}
	return nil
}

func (s *Service) checkUniversities(ctx context.Context, ids []uuid.UUID) error {
	if len(ids) == 0 {
		return nil
	}
	var n int
	if err := s.d.Q(ctx).QueryRow(ctx, `SELECT count(*)::int FROM universities WHERE id = ANY($1)`, ids).Scan(&n); err != nil {
		return err
	}
	if n != len(slices.Compact(slices.SortedFunc(slices.Values(ids), func(a, b uuid.UUID) int { return strings.Compare(a.String(), b.String()) }))) {
		return apperr.Validation(map[string]string{"universityIds": "unknown university"})
	}
	return nil
}

// universitiesOrNil: no list means all universities (NULL).
func universitiesOrNil(ids []uuid.UUID) []uuid.UUID {
	if len(ids) == 0 {
		return nil
	}
	return ids
}

func (s *Service) handleAdminCreate(ctx context.Context, in *campaignInput) (*AdminCampaign, error) {
	settles := in.EndsAt.Add(7 * 24 * time.Hour)
	if in.SettlesAt != nil {
		settles = *in.SettlesAt
	}
	if err := checkDates(in.StartsAt, in.EndsAt, settles); err != nil {
		return nil, err
	}
	if err := checkPrizes(in.Prizes); err != nil {
		return nil, err
	}
	if err := s.checkUniversities(ctx, in.UniversityIDs); err != nil {
		return nil, err
	}
	sc, err := in.Scoring.mergeOver(DefaultScoring)
	if err != nil {
		return nil, err
	}
	prizes, _ := json.Marshal(append([]Prize{}, in.Prizes...))
	scoring, _ := json.Marshal(sc)
	var out *AdminCampaign
	err = s.d.InTx(ctx, func(ctx context.Context) error {
		c, err := scanCampaign(s.d.Q(ctx).QueryRow(ctx, `INSERT INTO campaigns AS c (title_en, title_bn, body_en, body_bn, rules_en, rules_bn,
				starts_at, ends_at, settles_at, university_ids, prizes, created_by, scoring)
			VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13) RETURNING `+campaignCols,
			in.TitleEn, in.TitleBn, in.BodyEn, in.BodyBn, in.RulesEn, in.RulesBn, in.StartsAt, in.EndsAt, settles,
			universitiesOrNil(in.UniversityIDs), prizes, auth.MustUser(ctx).UserID, scoring))
		if err != nil {
			return err
		}
		v := s.adminView(c)
		out = &v
		return s.audit(ctx, "campaign.create", "campaign", c.ID.String(), map[string]any{"title": c.TitleEn})
	})
	return out, err
}

type adminListReq struct {
	Page     string `json:"-" query:"page" validate:"omitempty,number,min=1,max=1000"`
	PageSize string `json:"-" query:"pageSize" validate:"omitempty,number"`
	Status   string `json:"-" query:"status" validate:"omitempty,oneof=draft live ended announced all"`
}

type campaignPage struct {
	Items    []AdminCampaign `json:"items"`
	Total    int             `json:"total"`
	Page     int             `json:"page"`
	PageSize int             `json:"pageSize"`
}

func pageOf(page, size string) (int, int) {
	p, n := max(atoi(page), 1), atoi(size)
	if n < 1 {
		n = 25
	}
	return p, min(n, 100)
}

func (s *Service) handleAdminCampaigns(ctx context.Context, in *adminListReq) (*campaignPage, error) {
	page, size := pageOf(in.Page, in.PageSize)
	now := s.now()
	// "ended" is a live campaign past its end, as in the views.
	where := `($1 = '' OR $1 = 'all' OR ($1 = 'live' AND c.status IN ('live', 'ended') AND c.ends_at >= $2)
		OR ($1 = 'ended' AND c.status IN ('live', 'ended') AND c.ends_at < $2) OR ($1 IN ('draft', 'announced') AND c.status = $1))`
	out := &campaignPage{Items: []AdminCampaign{}, Page: page, PageSize: size}
	q := s.d.Q(ctx)
	if err := q.QueryRow(ctx, `SELECT count(*)::int FROM campaigns c WHERE `+where, in.Status, now).Scan(&out.Total); err != nil {
		return nil, err
	}
	rows, err := q.Query(ctx, `SELECT `+campaignCols+` FROM campaigns c WHERE `+where+` ORDER BY c.created_at DESC, c.id LIMIT $3 OFFSET $4`,
		in.Status, now, size, (page-1)*size)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	for rows.Next() {
		c, err := scanCampaign(rows)
		if err != nil {
			return nil, err
		}
		out.Items = append(out.Items, s.adminView(c))
	}
	return out, rows.Err()
}

func (s *Service) handleAdminCampaign(ctx context.Context, in *campaignReq) (*AdminCampaign, error) {
	c, err := s.loadCampaign(ctx, uuid.MustParse(in.ID), false)
	if err != nil {
		return nil, err
	}
	v := s.adminView(c)
	return &v, nil
}

type patchReq struct {
	ID            string       `json:"-" path:"id" validate:"required,uuid"`
	TitleEn       *string      `json:"titleEn" validate:"omitnil,min=1,max=120"`
	TitleBn       *string      `json:"titleBn" validate:"omitnil,max=120"`
	BodyEn        *string      `json:"bodyEn" validate:"omitnil,max=2000"`
	BodyBn        *string      `json:"bodyBn" validate:"omitnil,max=2000"`
	RulesEn       *string      `json:"rulesEn" validate:"omitnil,max=8000"`
	RulesBn       *string      `json:"rulesBn" validate:"omitnil,max=8000"`
	StartsAt      *time.Time   `json:"startsAt"`
	EndsAt        *time.Time   `json:"endsAt"`
	SettlesAt     *time.Time   `json:"settlesAt"`
	UniversityIDs *[]uuid.UUID `json:"universityIds" validate:"omitnil,max=200"`
	Prizes        *[]Prize     `json:"prizes" validate:"omitnil,max=20,dive"`
	Status        *string      `json:"status" validate:"omitnil,oneof=live"`
	// Scoring: point values merged over the current ones; draft only.
	Scoring *ScoringInput `json:"scoring"`
}

func (s *Service) handleAdminPatch(ctx context.Context, in *patchReq) (*AdminCampaign, error) {
	var out *AdminCampaign
	err := s.d.InTx(ctx, func(ctx context.Context) error {
		c, err := s.loadCampaign(ctx, uuid.MustParse(in.ID), true)
		if err != nil {
			return err
		}
		if c.Status == "announced" {
			return ErrCampaignLocked
		}
		// A draft can change freely; once live only the end, the settle
		// date, the rules and the prizes can (never the point values).
		if c.Status != "draft" {
			if in.TitleEn != nil || in.TitleBn != nil || in.BodyEn != nil || in.BodyBn != nil || in.StartsAt != nil ||
				in.UniversityIDs != nil || in.Status != nil || in.Scoring != nil {
				return ErrCampaignLocked
			}
		}
		if c.Scoring, err = in.Scoring.mergeOver(c.Scoring); err != nil {
			return err
		}
		set := func(dst *string, v *string) {
			if v != nil {
				*dst = strings.TrimSpace(*v)
			}
		}
		set(&c.TitleEn, in.TitleEn)
		set(&c.TitleBn, in.TitleBn)
		set(&c.BodyEn, in.BodyEn)
		set(&c.BodyBn, in.BodyBn)
		set(&c.RulesEn, in.RulesEn)
		set(&c.RulesBn, in.RulesBn)
		if in.StartsAt != nil {
			c.StartsAt = *in.StartsAt
		}
		if in.EndsAt != nil {
			c.EndsAt = *in.EndsAt
			if in.SettlesAt == nil && c.SettlesAt.Before(c.EndsAt) {
				c.SettlesAt = c.EndsAt.Add(7 * 24 * time.Hour)
			}
		}
		if in.SettlesAt != nil {
			c.SettlesAt = *in.SettlesAt
		}
		if in.UniversityIDs != nil {
			if err := s.checkUniversities(ctx, *in.UniversityIDs); err != nil {
				return err
			}
			c.UniversityIDs = universitiesOrNil(*in.UniversityIDs)
		}
		if in.Prizes != nil {
			if err := checkPrizes(*in.Prizes); err != nil {
				return err
			}
			c.Prizes = append([]Prize{}, *in.Prizes...)
		}
		if err := checkDates(c.StartsAt, c.EndsAt, c.SettlesAt); err != nil {
			return err
		}
		publish := in.Status != nil && c.Status == "draft"
		if publish {
			if strings.TrimSpace(c.TitleEn) == "" || strings.TrimSpace(c.RulesEn) == "" || len(c.Prizes) == 0 || !c.EndsAt.After(s.now()) {
				return ErrCampaignIncomplete
			}
			c.Status = "live"
		}
		if c.Status == "live" || c.Status == "ended" {
			c.Status = c.state(s.now())
		}
		prizes, _ := json.Marshal(c.Prizes)
		scoring, _ := json.Marshal(c.Scoring)
		if _, err := s.d.Q(ctx).Exec(ctx, `UPDATE campaigns SET title_en = $2, title_bn = $3, body_en = $4, body_bn = $5, rules_en = $6, rules_bn = $7,
				starts_at = $8, ends_at = $9, settles_at = $10, university_ids = $11, prizes = $12, status = $13, scoring = $14 WHERE id = $1`,
			c.ID, c.TitleEn, c.TitleBn, c.BodyEn, c.BodyBn, c.RulesEn, c.RulesBn, c.StartsAt, c.EndsAt, c.SettlesAt,
			c.UniversityIDs, prizes, c.Status, scoring); err != nil {
			return err
		}
		action := "campaign.update"
		if publish {
			action = "campaign.publish"
		}
		if err := s.audit(ctx, action, "campaign", c.ID.String(), map[string]any{"title": c.TitleEn}); err != nil {
			return err
		}
		fresh, err := s.loadCampaign(ctx, c.ID, false)
		if err != nil {
			return err
		}
		v := s.adminView(fresh)
		out = &v
		return nil
	})
	return out, err
}

// ---- invites with their flags --------------------------------------------------------

// invite is one referral as an admin sees it.
type invite struct {
	ReferredID     uuid.UUID
	ReferredName   string
	ReferredUni    string
	ReferrerID     uuid.UUID
	ReferrerName   string
	ReferrerUni    string
	Source         string
	CreatedAt      time.Time
	VerifiedVia    *string
	ActiveDays     int
	QualifiedAt    *time.Time
	SameDevice     bool
	Disqualified   bool
	Reason         string
	Burst          bool
	ReferrerIsNew  bool
	ReferrerEmail  string
	ReferrerCreate time.Time
	OtherCampus    bool
	// VerifiedBefore: students of the friend's university verified before
	// them (nil: the friend isn't verified); pioneer when under pioneerFirst.
	VerifiedBefore *int
	InSection      bool
	SelfVouched    bool
}

// selfVouchedSQL: the friend (u) is verified by people (CR, vouches, campus
// admin) and the inviter (r.referrer_id) was one of them: a live verification
// event they made, or a vouch of theirs that still counts.
const selfVouchedSQL = `(u.verified_at IS NOT NULL AND u.verified_via IN ('cr', 'vouch', 'campus_admin') AND (
	EXISTS (SELECT 1 FROM verification_events e WHERE e.user_id = u.id AND e.actor_id = r.referrer_id AND e.revoked_at IS NULL)
	OR EXISTS (SELECT 1 FROM vouches v WHERE v.user_id = u.id AND v.voucher_id = r.referrer_id AND v.void_at IS NULL)))`

// inviteSelect: the shared SELECT. burst: some 1-hour window that holds this
// invite has 10 or more invites of the same inviter. new_account: the inviter's
// first invite came within 7 days of their own sign-up. self_vouched: see
// selfVouchedSQL.
const inviteSelect = `
SELECT r.referred_id, coalesce(u.display_name, ''), coalesce(uu.name, ''), r.referrer_id, coalesce(rr.display_name, ''), coalesce(ru.name, ''),
       r.source, r.created_at, u.verified_via,
       (SELECT count(*)::int FROM user_active_days a WHERE a.user_id = u.id
          AND a.day >= (u.created_at AT TIME ZONE 'Asia/Dhaka')::date AND a.day < (u.created_at AT TIME ZONE 'Asia/Dhaka')::date + 14),
       r.qualified_at, r.same_device, r.disqualified_at IS NOT NULL, r.reason,
       EXISTS (SELECT 1 FROM referrals x WHERE x.referrer_id = r.referrer_id
                 AND x.created_at <= r.created_at AND x.created_at > r.created_at - interval '1 hour'
                 AND (SELECT count(*) FROM referrals y WHERE y.referrer_id = x.referrer_id
                        AND y.created_at >= x.created_at AND y.created_at < x.created_at + interval '1 hour') >= 10),
       (SELECT min(x.created_at) FROM referrals x WHERE x.referrer_id = r.referrer_id) - rr.created_at < interval '7 days',
       rr.email, rr.created_at,
       (u.university_id IS NOT NULL AND u.university_id IS DISTINCT FROM rr.university_id),
       CASE WHEN u.verified_at IS NOT NULL AND u.university_id IS NOT NULL THEN
         (SELECT count(*)::int FROM users x WHERE x.university_id = u.university_id AND x.verified_at < u.verified_at) END,
       EXISTS (SELECT 1 FROM class_group_members m WHERE m.user_id = u.id),
       ` + selfVouchedSQL + `
FROM referrals r
JOIN users u ON u.id = r.referred_id LEFT JOIN universities uu ON uu.id = u.university_id
JOIN users rr ON rr.id = r.referrer_id LEFT JOIN universities ru ON ru.id = rr.university_id`

func scanInvite(r scanner) (invite, error) {
	var x invite
	err := r.Scan(&x.ReferredID, &x.ReferredName, &x.ReferredUni, &x.ReferrerID, &x.ReferrerName, &x.ReferrerUni,
		&x.Source, &x.CreatedAt, &x.VerifiedVia, &x.ActiveDays, &x.QualifiedAt, &x.SameDevice, &x.Disqualified, &x.Reason,
		&x.Burst, &x.ReferrerIsNew, &x.ReferrerEmail, &x.ReferrerCreate,
		&x.OtherCampus, &x.VerifiedBefore, &x.InSection, &x.SelfVouched)
	return x, err
}

func (x invite) flags() []string {
	out := []string{}
	if x.SameDevice {
		out = append(out, "same_device")
	}
	if x.Burst {
		out = append(out, "burst")
	}
	if x.ReferrerIsNew {
		out = append(out, "new_account")
	}
	if x.SelfVouched {
		out = append(out, "self_vouched")
	}
	return out
}

type Ref struct {
	ID         uuid.UUID `json:"id"`
	Name       string    `json:"name"`
	University string    `json:"university"`
}

type InviteView struct {
	Referred     Ref        `json:"referred"`
	Source       string     `json:"source"`
	CreatedAt    time.Time  `json:"createdAt"`
	VerifiedVia  *string    `json:"verifiedVia"`
	ActiveDays   int        `json:"activeDays"`
	QualifiedAt  *time.Time `json:"qualifiedAt"`
	SameDevice   bool       `json:"sameDevice"`
	Disqualified bool       `json:"disqualified"`
	Reason       string     `json:"reason"`
	// The bonuses (§8.1): the friend is at another university, among the
	// first verified students of theirs, in a class group.
	OtherCampus bool `json:"otherCampus"`
	Pioneer     bool `json:"pioneer"`
	InSection   bool `json:"inSection"`
}

// view: pioneerFirst is the campaign's (the default outside a campaign).
func (x invite) view(pioneerFirst int) InviteView {
	v := InviteView{
		Referred: Ref{ID: x.ReferredID, Name: x.ReferredName, University: x.ReferredUni}, Source: x.Source, CreatedAt: x.CreatedAt.UTC(),
		VerifiedVia: x.VerifiedVia, ActiveDays: x.ActiveDays, SameDevice: x.SameDevice, Disqualified: x.Disqualified, Reason: x.Reason,
		OtherCampus: x.OtherCampus, Pioneer: x.VerifiedBefore != nil && *x.VerifiedBefore < pioneerFirst, InSection: x.InSection,
	}
	if x.QualifiedAt != nil {
		t := x.QualifiedAt.UTC()
		v.QualifiedAt = &t
	}
	return v
}

// ---- standings -----------------------------------------------------------------------

type StandingUser struct {
	ID         uuid.UUID `json:"id"`
	Name       string    `json:"name"`
	Email      string    `json:"email"`
	University string    `json:"university"`
}

type StandingRow struct {
	Rank   *int         `json:"rank"`
	User   StandingUser `json:"user"`
	Score  int          `json:"score"`
	Hidden bool         `json:"hidden"`
	// Disqualified participants are listed after the ranked ones (rank null)
	// so they can be restored.
	Disqualified bool `json:"disqualified"`
	// Eligible: at least minOwnCampus counted friends at their university
	// (OwnCampus) and minOtherCampus at others (OtherCampus), so ranked; the
	// others have rank null (§8.5).
	Eligible    bool `json:"eligible"`
	OwnCampus   int  `json:"ownCampus"`
	OtherCampus int  `json:"otherCampus"`
	// Points per key (zero for a disqualified participant).
	Points  Points       `json:"points"`
	Invites []InviteView `json:"invites"`
	Flags   []string     `json:"flags"`
}

const standingsSize = 100

func (s *Service) handleAdminStandings(ctx context.Context, in *campaignReq) (*[]StandingRow, error) {
	c, err := s.loadCampaign(ctx, uuid.MustParse(in.ID), false)
	if err != nil {
		return nil, err
	}
	all, err := s.standings(ctx, c, nil, 1_000_000)
	if err != nil {
		return nil, err
	}
	// The top eligible (ranked), then the top who aren't eligible yet.
	out := []StandingRow{}
	users := map[uuid.UUID]int{}
	ranked, others := 0, 0
	for _, x := range all {
		if x.Eligible {
			if ranked++; ranked > standingsSize {
				continue
			}
		} else if others++; others > standingsSize {
			break
		}
		var rank *int
		if x.Eligible {
			r := x.Rank
			rank = &r
		}
		users[x.UserID] = len(out)
		out = append(out, StandingRow{Rank: rank, Score: x.Score, Hidden: x.Hidden, Eligible: x.Eligible, OwnCampus: x.Tally.OwnCampus, OtherCampus: x.Tally.OtherCampus,
			Points: x.Tally.points(c.Scoring), Invites: []InviteView{}, Flags: []string{},
			User: StandingUser{ID: x.UserID, Name: x.Name, University: x.UniName}})
	}
	// Disqualified participants, after the ranked ones.
	rows, err := s.d.Q(ctx).Query(ctx, `SELECT d.user_id, coalesce(u.display_name, ''), un.name, u.leaderboard_hidden
		FROM campaign_disqualified d JOIN users u ON u.id = d.user_id LEFT JOIN universities un ON un.id = u.university_id
		WHERE d.campaign_id = $1 ORDER BY d.created_at`, c.ID)
	if err != nil {
		return nil, err
	}
	for rows.Next() {
		var id uuid.UUID
		var name string
		var uni *string
		var hidden bool
		if err := rows.Scan(&id, &name, &uni, &hidden); err != nil {
			rows.Close()
			return nil, err
		}
		u := ""
		if uni != nil {
			u = *uni
		}
		users[id] = len(out)
		out = append(out, StandingRow{Hidden: hidden, Disqualified: true, Invites: []InviteView{}, Flags: []string{}, User: StandingUser{ID: id, Name: name, University: u}})
	}
	rows.Close()
	if err := rows.Err(); err != nil {
		return nil, err
	}
	if len(out) == 0 {
		return &out, nil
	}
	ids := make([]uuid.UUID, 0, len(users))
	for id := range users {
		ids = append(ids, id)
	}
	irows, err := s.d.Q(ctx).Query(ctx, inviteSelect+` WHERE r.referrer_id = ANY($1) AND r.created_at >= $2 AND r.created_at <= $3 ORDER BY r.created_at`,
		ids, c.StartsAt, c.EndsAt)
	if err != nil {
		return nil, err
	}
	defer irows.Close()
	for irows.Next() {
		x, err := scanInvite(irows)
		if err != nil {
			return nil, err
		}
		row := &out[users[x.ReferrerID]]
		row.User.Email = x.ReferrerEmail
		row.Invites = append(row.Invites, x.view(c.Scoring.PioneerFirst))
		for _, f := range x.flags() {
			if !slices.Contains(row.Flags, f) {
				row.Flags = append(row.Flags, f)
			}
		}
	}
	if err := irows.Err(); err != nil {
		return nil, err
	}
	// Emails for rows without invites in the window.
	for i := range out {
		if out[i].User.Email == "" {
			if err := s.d.Q(ctx).QueryRow(ctx, `SELECT email FROM users WHERE id = $1`, out[i].User.ID).Scan(&out[i].User.Email); err != nil {
				return nil, err
			}
		}
	}
	return &out, nil
}

// ---- disqualify ----------------------------------------------------------------------

type reasonReq struct {
	ReferredID string `json:"-" path:"referredId" validate:"omitempty,uuid"`
	ID         string `json:"-" path:"id" validate:"omitempty,uuid"`
	UserID     string `json:"-" path:"userId" validate:"omitempty,uuid"`
	Reason     string `json:"reason" validate:"max=300"`
}

func (s *Service) handleAdminDisqualifyReferral(ctx context.Context, in *reasonReq) (*httpx.Empty, error) {
	id := uuid.MustParse(in.ReferredID)
	return nil, s.d.InTx(ctx, func(ctx context.Context) error {
		tag, err := s.d.Q(ctx).Exec(ctx, `UPDATE referrals SET disqualified_at = $2, disqualified_by = $3, reason = $4 WHERE referred_id = $1`,
			id, s.now(), auth.MustUser(ctx).UserID, strings.TrimSpace(in.Reason))
		if err != nil {
			return err
		}
		if tag.RowsAffected() == 0 {
			return ErrReferralNotFound
		}
		return s.audit(ctx, "referral.disqualify", "referral", id.String(), map[string]any{"reason": in.Reason})
	})
}

func (s *Service) handleAdminRestoreReferral(ctx context.Context, in *reasonReq) (*httpx.Empty, error) {
	id := uuid.MustParse(in.ReferredID)
	return nil, s.d.InTx(ctx, func(ctx context.Context) error {
		tag, err := s.d.Q(ctx).Exec(ctx, `UPDATE referrals SET disqualified_at = NULL, disqualified_by = NULL, reason = '' WHERE referred_id = $1`, id)
		if err != nil {
			return err
		}
		if tag.RowsAffected() == 0 {
			return ErrReferralNotFound
		}
		return s.audit(ctx, "referral.restore", "referral", id.String(), nil)
	})
}

func (s *Service) handleAdminDisqualifyUser(ctx context.Context, in *reasonReq) (*httpx.Empty, error) {
	cid, uid := uuid.MustParse(in.ID), uuid.MustParse(in.UserID)
	return nil, s.d.InTx(ctx, func(ctx context.Context) error {
		if _, err := s.loadCampaign(ctx, cid, false); err != nil {
			return err
		}
		var exists bool
		if err := s.d.Q(ctx).QueryRow(ctx, `SELECT EXISTS (SELECT 1 FROM users WHERE id = $1)`, uid).Scan(&exists); err != nil {
			return err
		}
		if !exists {
			return ErrUserNotFound
		}
		if _, err := s.d.Q(ctx).Exec(ctx, `INSERT INTO campaign_disqualified (campaign_id, user_id, reason, disqualified_by) VALUES ($1, $2, $3, $4)
			ON CONFLICT (campaign_id, user_id) DO UPDATE SET reason = EXCLUDED.reason, disqualified_by = EXCLUDED.disqualified_by`,
			cid, uid, strings.TrimSpace(in.Reason), auth.MustUser(ctx).UserID); err != nil {
			return err
		}
		return s.audit(ctx, "campaign.disqualify", "campaign", cid.String(), map[string]any{"userId": uid, "reason": in.Reason})
	})
}

func (s *Service) handleAdminRestoreUser(ctx context.Context, in *reasonReq) (*httpx.Empty, error) {
	cid, uid := uuid.MustParse(in.ID), uuid.MustParse(in.UserID)
	return nil, s.d.InTx(ctx, func(ctx context.Context) error {
		if _, err := s.d.Q(ctx).Exec(ctx, `DELETE FROM campaign_disqualified WHERE campaign_id = $1 AND user_id = $2`, cid, uid); err != nil {
			return err
		}
		return s.audit(ctx, "campaign.restore", "campaign", cid.String(), map[string]any{"userId": uid})
	})
}

// ---- announce, winners, delivery --------------------------------------------------------

type winnerPick struct {
	UserID uuid.UUID `json:"userId" validate:"required"`
	Rank   int       `json:"rank" validate:"min=1,max=1000"`
}

type announceReq struct {
	ID      string       `json:"-" path:"id" validate:"required,uuid"`
	Winners []winnerPick `json:"winners" validate:"required,min=1,max=100,dive"`
}

type Winner struct {
	UserID      uuid.UUID  `json:"userId"`
	Name        string     `json:"name"`
	Email       string     `json:"email"`
	University  string     `json:"university"`
	Rank        int        `json:"rank"`
	PrizeEn     string     `json:"prizeEn"`
	PrizeBn     string     `json:"prizeBn"`
	AnnouncedAt time.Time  `json:"announcedAt"`
	ClaimedAt   *time.Time `json:"claimedAt"`
	DeliveredAt *time.Time `json:"deliveredAt"`
	Claim       *WinClaim  `json:"claim"`
}

type WinClaim struct {
	FullName  string    `json:"fullName"`
	Phone     string    `json:"phone"`
	Address   string    `json:"address"`
	Note      string    `json:"note"`
	CreatedAt time.Time `json:"createdAt"`
}

func (s *Service) handleAdminAnnounce(ctx context.Context, in *announceReq) (*[]Winner, error) {
	cid := uuid.MustParse(in.ID)
	type pushTo struct {
		id         uuid.UUID
		en, bn, ti string
	}
	var pushes []pushTo
	err := s.d.InTx(ctx, func(ctx context.Context) error {
		pushes = nil
		c, err := s.loadCampaign(ctx, cid, true)
		if err != nil {
			return err
		}
		if c.Status != "live" && c.Status != "ended" {
			return ErrNotAnnounceable
		}
		if s.now().Before(c.SettlesAt) {
			return ErrNotSettled
		}
		all, err := s.standings(ctx, c, nil, 1_000_000)
		if err != nil {
			return err
		}
		// Participants, and whether each may win (§8.5).
		participant := map[uuid.UUID]bool{}
		for _, x := range all {
			participant[x.UserID] = x.Eligible
		}
		users, ranks := map[uuid.UUID]bool{}, map[int]bool{}
		for _, w := range in.Winners {
			canWin, ok := participant[w.UserID]
			if !ok || users[w.UserID] || ranks[w.Rank] {
				return ErrWinners
			}
			if !canWin {
				return ErrNotEligible
			}
			users[w.UserID], ranks[w.Rank] = true, true
			if _, ok := c.prizeFor(w.Rank); !ok {
				return ErrWinners
			}
		}
		now := s.now()
		for _, w := range in.Winners {
			p, _ := c.prizeFor(w.Rank)
			if _, err := s.d.Q(ctx).Exec(ctx, `INSERT INTO campaign_winners (campaign_id, user_id, rank, prize_en, prize_bn, announced_at) VALUES ($1, $2, $3, $4, $5, $6)`,
				cid, w.UserID, w.Rank, p.TitleEn, cmpOr(p.TitleBn, p.TitleEn), now); err != nil {
				return err
			}
			pushes = append(pushes, pushTo{id: w.UserID, en: p.TitleEn, bn: cmpOr(p.TitleBn, p.TitleEn), ti: c.TitleEn})
		}
		if _, err := s.d.Q(ctx).Exec(ctx, `UPDATE campaigns SET status = 'announced' WHERE id = $1`, cid); err != nil {
			return err
		}
		return s.audit(ctx, "campaign.announce", "campaign", cid.String(), map[string]any{"winners": len(in.Winners)})
	})
	if err != nil {
		return nil, err
	}
	if s.notify != nil {
		for _, p := range pushes {
			s.notify([]uuid.UUID{p.id}, Notice{
				Texts: map[string]NoticeText{
					"en": {Title: "You won: " + p.en + "!", Body: p.ti},
					"bn": {Title: "তুমি জিতেছ: " + p.bn + "!", Body: p.ti},
				},
				Data: map[string]string{"type": "campaign_won", "campaignId": cid.String()},
			})
		}
	}
	return s.winners(ctx, cid)
}

func cmpOr(a, b string) string {
	if a != "" {
		return a
	}
	return b
}

func (s *Service) winners(ctx context.Context, cid uuid.UUID) (*[]Winner, error) {
	rows, err := s.d.Q(ctx).Query(ctx, `SELECT w.user_id, coalesce(u.display_name, ''), u.email, coalesce(un.name, ''), w.rank, w.prize_en, w.prize_bn,
			w.announced_at, w.claimed_at, w.delivered_at, c.full_name, c.phone, c.address, c.note, c.created_at
		FROM campaign_winners w JOIN users u ON u.id = w.user_id LEFT JOIN universities un ON un.id = u.university_id
		LEFT JOIN campaign_claims c ON c.campaign_id = w.campaign_id AND c.user_id = w.user_id
		WHERE w.campaign_id = $1 ORDER BY w.rank, w.user_id`, cid)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []Winner{}
	for rows.Next() {
		var w Winner
		var full, phone, addr, note *string
		var at *time.Time
		if err := rows.Scan(&w.UserID, &w.Name, &w.Email, &w.University, &w.Rank, &w.PrizeEn, &w.PrizeBn,
			&w.AnnouncedAt, &w.ClaimedAt, &w.DeliveredAt, &full, &phone, &addr, &note, &at); err != nil {
			return nil, err
		}
		if full != nil {
			w.Claim = &WinClaim{FullName: *full, Phone: *phone, Address: *addr, Note: *note, CreatedAt: at.UTC()}
		}
		w.AnnouncedAt = w.AnnouncedAt.UTC()
		out = append(out, w)
	}
	return &out, rows.Err()
}

func (s *Service) handleAdminWinners(ctx context.Context, in *campaignReq) (*[]Winner, error) {
	cid := uuid.MustParse(in.ID)
	if _, err := s.loadCampaign(ctx, cid, false); err != nil {
		return nil, err
	}
	return s.winners(ctx, cid)
}

func (s *Service) handleAdminDelivered(ctx context.Context, in *reasonReq) (*httpx.Empty, error) {
	cid, uid := uuid.MustParse(in.ID), uuid.MustParse(in.UserID)
	return nil, s.d.InTx(ctx, func(ctx context.Context) error {
		tag, err := s.d.Q(ctx).Exec(ctx, `UPDATE campaign_winners SET delivered_at = coalesce(delivered_at, $3) WHERE campaign_id = $1 AND user_id = $2`,
			cid, uid, s.now())
		if err != nil {
			return err
		}
		if tag.RowsAffected() == 0 {
			return ErrNotAWinner
		}
		return s.audit(ctx, "campaign.delivered", "campaign", cid.String(), map[string]any{"userId": uid})
	})
}

// ---- referrals list --------------------------------------------------------------------

type referralsReq struct {
	Page     string `json:"-" query:"page" validate:"omitempty,number,min=1,max=10000"`
	PageSize string `json:"-" query:"pageSize" validate:"omitempty,number"`
	Q        string `json:"-" query:"q" validate:"max=100"`
	Flag     string `json:"-" query:"flag" validate:"omitempty,oneof=same_device burst new_account self_vouched disqualified qualified pending"`
}

type ReferralItem struct {
	InviteView
	Referrer Ref      `json:"referrer"`
	Flags    []string `json:"flags"`
}

type referralPage struct {
	Items    []ReferralItem `json:"items"`
	Total    int            `json:"total"`
	Page     int            `json:"page"`
	PageSize int            `json:"pageSize"`
}

func (s *Service) handleAdminReferrals(ctx context.Context, in *referralsReq) (*referralPage, error) {
	page, size := pageOf(in.Page, in.PageSize)
	search := strings.TrimSpace(in.Q)
	pat := "%" + strings.NewReplacer(`\`, `\\`, `%`, `\%`, `_`, `\_`).Replace(search) + "%"
	// Filter on the joined columns directly; the flag tests repeat the
	// definitions of inviteSelect.
	where := `($1 = '' OR u.display_name ILIKE $2 OR rr.display_name ILIKE $2 OR u.email ILIKE $2 OR rr.email ILIKE $2)`
	flagWhere := `($3 = '' OR ($3 = 'same_device' AND r.same_device)
		OR ($3 = 'burst' AND EXISTS (SELECT 1 FROM referrals x WHERE x.referrer_id = r.referrer_id
			AND x.created_at <= r.created_at AND x.created_at > r.created_at - interval '1 hour'
			AND (SELECT count(*) FROM referrals y WHERE y.referrer_id = x.referrer_id AND y.created_at >= x.created_at AND y.created_at < x.created_at + interval '1 hour') >= 10))
		OR ($3 = 'new_account' AND (SELECT min(x.created_at) FROM referrals x WHERE x.referrer_id = r.referrer_id) - rr.created_at < interval '7 days')
		OR ($3 = 'self_vouched' AND ` + selfVouchedSQL + `)
		OR ($3 = 'disqualified' AND r.disqualified_at IS NOT NULL)
		OR ($3 = 'qualified' AND r.qualified_at IS NOT NULL AND r.disqualified_at IS NULL)
		OR ($3 = 'pending' AND r.qualified_at IS NULL AND r.disqualified_at IS NULL))`
	out := &referralPage{Items: []ReferralItem{}, Page: page, PageSize: size}
	q := s.d.Q(ctx)
	from := ` FROM referrals r JOIN users u ON u.id = r.referred_id JOIN users rr ON rr.id = r.referrer_id WHERE ` + where + ` AND ` + flagWhere
	if err := q.QueryRow(ctx, `SELECT count(*)::int`+from, search, pat, in.Flag).Scan(&out.Total); err != nil {
		return nil, err
	}
	rows, err := q.Query(ctx, inviteSelect+` WHERE `+where+` AND `+flagWhere+` ORDER BY r.created_at DESC, r.referred_id LIMIT $4 OFFSET $5`,
		search, pat, in.Flag, size, (page-1)*size)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	for rows.Next() {
		x, err := scanInvite(rows)
		if err != nil {
			return nil, err
		}
		out.Items = append(out.Items, ReferralItem{InviteView: x.view(DefaultScoring.PioneerFirst), Referrer: Ref{ID: x.ReferrerID, Name: x.ReferrerName, University: x.ReferrerUni}, Flags: x.flags()})
	}
	return out, rows.Err()
}

// ---- one student's growth (admin user page) ----------------------------------------------

type UserGrowth struct {
	ReferralCode *string      `json:"referralCode"`
	InvitedBy    *Ref         `json:"invitedBy"`
	Invited      []InviteView `json:"invited"`
	Badges       []MyBadge    `json:"badges"`
}

type userIDReq struct {
	ID string `json:"-" path:"id" validate:"required,uuid"`
}

func (s *Service) handleAdminUserGrowth(ctx context.Context, in *userIDReq) (*UserGrowth, error) {
	id := uuid.MustParse(in.ID)
	out := &UserGrowth{Invited: []InviteView{}, Badges: []MyBadge{}}
	q := s.d.Q(ctx)
	if err := q.QueryRow(ctx, `SELECT referral_code FROM users WHERE id = $1`, id).Scan(&out.ReferralCode); err != nil {
		if db.IsNoRows(err) {
			return nil, ErrUserNotFound
		}
		return nil, err
	}
	var ref Ref
	err := q.QueryRow(ctx, `SELECT rr.id, coalesce(rr.display_name, ''), coalesce(un.name, '') FROM referrals r JOIN users rr ON rr.id = r.referrer_id
		LEFT JOIN universities un ON un.id = rr.university_id WHERE r.referred_id = $1`, id).Scan(&ref.ID, &ref.Name, &ref.University)
	if err == nil {
		out.InvitedBy = &ref
	} else if !db.IsNoRows(err) {
		return nil, err
	}
	rows, err := q.Query(ctx, inviteSelect+` WHERE r.referrer_id = $1 ORDER BY r.created_at DESC LIMIT 200`, id)
	if err != nil {
		return nil, err
	}
	for rows.Next() {
		x, err := scanInvite(rows)
		if err != nil {
			rows.Close()
			return nil, err
		}
		out.Invited = append(out.Invited, x.view(DefaultScoring.PioneerFirst))
	}
	rows.Close()
	if err := rows.Err(); err != nil {
		return nil, err
	}
	mb, err := s.myBadges(ctx, id)
	if err != nil {
		return nil, err
	}
	out.Badges = mb.Badges
	return out, nil
}
