package growth

import (
	"context"
	"encoding/json"
	"strings"
	"time"

	"github.com/google/uuid"

	"github.com/zamansheikh/varsitykotha/backend/internal/platform/auth"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/db"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/httpx"
)

// Prize is one prize row: ranks rankFrom..rankTo each win it.
type Prize struct {
	RankFrom int    `json:"rankFrom" validate:"min=1,max=1000"`
	RankTo   int    `json:"rankTo" validate:"min=1,max=1000"`
	TitleEn  string `json:"titleEn" validate:"required,max=120"`
	TitleBn  string `json:"titleBn" validate:"max=120"`
}

// campaign is a stored campaign.
type campaign struct {
	ID            uuid.UUID
	TitleEn       string
	TitleBn       string
	BodyEn        string
	BodyBn        string
	RulesEn       string
	RulesBn       string
	StartsAt      time.Time
	EndsAt        time.Time
	SettlesAt     time.Time
	UniversityIDs []uuid.UUID
	Prizes        []Prize
	Status        string
	CreatedAt     time.Time
	UpdatedAt     time.Time
	// BannerKey / BannerVersion: the banner photo, if one was uploaded.
	BannerKey     *string
	BannerVersion *string
	Scoring       Scoring
	// §9: an optional section prize and the reward for the first finishers.
	SectionPrizeEn      string
	SectionPrizeBn      string
	FinisherRewardEn    string
	FinisherRewardBn    string
	FinisherRewardCount int
}

const campaignCols = `c.id, c.title_en, c.title_bn, c.body_en, c.body_bn, c.rules_en, c.rules_bn, c.starts_at, c.ends_at, c.settles_at,
	c.university_ids, c.prizes, c.status, c.created_at, c.updated_at, c.banner_key, c.banner_version, c.scoring,
	c.section_prize_en, c.section_prize_bn, c.finisher_reward_en, c.finisher_reward_bn, c.finisher_reward_count`

type scanner interface{ Scan(dest ...any) error }

// bannerURL: the public banner address, relative to the API prefix
// ("/campaigns/{id}/banner?v={version}"), or nil without a banner.
func (c campaign) bannerURL() *string {
	if c.BannerKey == nil || c.BannerVersion == nil {
		return nil
	}
	u := "/campaigns/" + c.ID.String() + "/banner?v=" + *c.BannerVersion
	return &u
}

func scanCampaign(r scanner) (campaign, error) {
	var c campaign
	var prizes, scoring []byte
	err := r.Scan(&c.ID, &c.TitleEn, &c.TitleBn, &c.BodyEn, &c.BodyBn, &c.RulesEn, &c.RulesBn, &c.StartsAt, &c.EndsAt, &c.SettlesAt,
		&c.UniversityIDs, &prizes, &c.Status, &c.CreatedAt, &c.UpdatedAt, &c.BannerKey, &c.BannerVersion, &scoring,
		&c.SectionPrizeEn, &c.SectionPrizeBn, &c.FinisherRewardEn, &c.FinisherRewardBn, &c.FinisherRewardCount)
	if err != nil {
		return c, err
	}
	c.Scoring = parseScoring(scoring)
	if err := json.Unmarshal(prizes, &c.Prizes); err != nil || c.Prizes == nil {
		c.Prizes = []Prize{}
	}
	return c, nil
}

func (s *Service) loadCampaign(ctx context.Context, id uuid.UUID, forUpdate bool) (campaign, error) {
	sql := `SELECT ` + campaignCols + ` FROM campaigns c WHERE c.id = $1`
	if forUpdate {
		sql += ` FOR UPDATE`
	}
	c, err := scanCampaign(s.d.Q(ctx).QueryRow(ctx, sql, id))
	if db.IsNoRows(err) {
		return c, ErrCampaignNotFound
	}
	return c, err
}

// state is the status as time sees it: a live campaign past its end is ended.
func (c campaign) state(now time.Time) string {
	if c.Status == "live" || c.Status == "ended" {
		if now.After(c.EndsAt) {
			return "ended"
		}
		return "live"
	}
	return c.Status
}

// coversUniversity: the campaign is for all universities, or this one.
func (c campaign) coversUniversity(id uuid.UUID) bool {
	if c.UniversityIDs == nil {
		return true
	}
	for _, u := range c.UniversityIDs {
		if u == id {
			return true
		}
	}
	return false
}

// prizeFor is the prize row that covers rank.
func (c campaign) prizeFor(rank int) (Prize, bool) {
	for _, p := range c.Prizes {
		if rank >= p.RankFrom && rank <= p.RankTo {
			return p, true
		}
	}
	return Prize{}, false
}

// ---- standings ----------------------------------------------------------------------

// The score is points (docs/GROWTH.md §8): counted invites (created inside
// the campaign, qualified by settles_at, not disqualified, not on the same
// phone) with their bonuses, plus the missions. Only verified, non-team
// students take part; anyone with a point has a row. Only the eligible
// (counted friends: at least minOwnCampus at my university and minOtherCampus
// at others, §8.5) are ranked, first; the rest follow with rank 0. Ranks go
// by points, then by who reached them first (the latest counted event), then
// by id.
type standing struct {
	Rank      int // 0: not eligible
	Eligible  bool
	UserID    uuid.UUID
	Name      string
	Hidden    bool
	UniID     uuid.UUID
	UniName   string
	Score     int
	ReachedAt *time.Time
	Badge     *BadgeRef
	Tally     tally
}

// standingsSQL: $1 campaign, $2 starts, $3 ends, $4 settles, $5 its
// universities, $6 one university (leaderboard scope), $7 limit, $8 count
// invites at all (worth points, or needed for eligibility), $9 pioneerFirst,
// $10 count sections joined, $11 count donors, $12 bus days that count (0:
// off), $13 CR sections that count (0: off), $14 routine slots and $15
// verified members a section needs, $16 a bus share's minimum minutes,
// $17..$24 the points per key, $25 invites worth points (their time breaks
// ties), $26 minOtherCampus, $27 minOwnCampus.
//
// Bus: a Dhaka day counts when I shared a live bus that day that ran at least
// $16 minutes (by its last ping), didn't end off the route, and another
// student watched (a bus_live_views row for the same run).
const standingsSQL = `
WITH counted AS (
	SELECT r.referrer_id AS user_id, r.qualified_at,
	       (f.university_id IS NOT NULL AND f.university_id IS DISTINCT FROM rr.university_id) AS other_campus,
	       (f.university_id IS NOT NULL AND f.university_id = rr.university_id) AS own_campus,
	       (f.verified_at IS NOT NULL AND f.university_id IS NOT NULL
	        AND (SELECT count(*) FROM users x WHERE x.university_id = f.university_id AND x.verified_at < f.verified_at) < $9::int) AS pioneer,
	       EXISTS (SELECT 1 FROM class_group_members m WHERE m.user_id = f.id) AS in_section
	FROM referrals r JOIN users f ON f.id = r.referred_id JOIN users rr ON rr.id = r.referrer_id
	WHERE $8::bool AND r.qualified_at IS NOT NULL AND r.disqualified_at IS NULL AND NOT r.same_device
	  AND r.created_at >= $2 AND r.created_at <= $3 AND r.qualified_at <= $4),
bus_days AS (
	SELECT s.user_id, (s.started_at AT TIME ZONE 'Asia/Dhaka')::date AS day, min(s.started_at) AS started
	FROM bus_live_sessions s
	WHERE $12::int > 0 AND s.started_at >= $2 AND s.started_at <= $3
	  AND s.last_at - s.started_at >= make_interval(mins => $16::int)
	  AND s.end_reason IS DISTINCT FROM 'off_route'
	  AND EXISTS (SELECT 1 FROM bus_live_views v WHERE v.route_id = s.route_id AND v.direction = s.direction
	                AND v.service_date = s.service_date AND v.departs = s.departs AND v.user_id <> s.user_id)
	GROUP BY 1, 2),
cr_sections AS (
	SELECT m.user_id, row_number() OVER (PARTITION BY m.user_id ORDER BY g.created_at, g.id) AS k
	FROM class_group_members m JOIN class_groups g ON g.id = m.group_id
	WHERE $13::int > 0 AND m.role = 'cr'
	  AND (SELECT count(*) FROM routine_slots rs WHERE rs.group_id = g.id) >= $14::int
	  AND (SELECT count(*) FROM class_group_members o JOIN users ou ON ou.id = o.user_id
	       WHERE o.group_id = g.id AND o.user_id <> m.user_id AND ou.verified_at IS NOT NULL) >= $15::int),
parts AS (
	SELECT user_id, count(*)::int AS invites, (count(*) FILTER (WHERE other_campus))::int AS other_campus,
	       (count(*) FILTER (WHERE pioneer))::int AS pioneer, (count(*) FILTER (WHERE in_section))::int AS friend_section,
	       0 AS join_section, 0 AS blood_donor, 0 AS bus_days, 0 AS sections,
	       CASE WHEN $25::bool THEN max(qualified_at) END AS reached_at, (count(*) FILTER (WHERE own_campus))::int AS own_campus
	FROM counted GROUP BY user_id
	UNION ALL
	SELECT user_id, 0, 0, 0, 0, 1, 0, 0, 0, min(joined_at), 0 FROM class_group_members WHERE $10::bool GROUP BY user_id
	UNION ALL
	SELECT user_id, 0, 0, 0, 0, 0, 1, 0, 0, created_at, 0 FROM blood_donors WHERE $11::bool
	UNION ALL
	SELECT user_id, 0, 0, 0, 0, 0, 0, count(*)::int, 0, max(started), 0
	FROM (SELECT b.user_id, b.started, row_number() OVER (PARTITION BY b.user_id ORDER BY b.day) AS k FROM bus_days b) x
	WHERE k <= $12::int GROUP BY user_id
	UNION ALL
	SELECT user_id, 0, 0, 0, 0, 0, 0, 0, count(*)::int, NULL::timestamptz, 0 FROM cr_sections WHERE k <= $13::int GROUP BY user_id),
tallied AS (
	SELECT user_id, sum(invites)::int AS invites, sum(other_campus)::int AS other_campus, sum(pioneer)::int AS pioneer,
	       sum(friend_section)::int AS friend_section, sum(join_section)::int AS join_section, sum(blood_donor)::int AS blood_donor,
	       sum(bus_days)::int AS bus_days, sum(sections)::int AS sections, max(reached_at) AS reached_at,
	       sum(own_campus)::int AS own_campus
	FROM parts GROUP BY user_id),
scored AS (
	SELECT t.*, (t.invites * $17::int + t.other_campus * $18::int + t.pioneer * $19::int + t.friend_section * $20::int
	             + t.join_section * $21::int + t.blood_donor * $22::int + t.bus_days * $23::int + t.sections * $24::int) AS score
	FROM tallied t),
ranked AS (
	SELECT s.user_id, s.score, s.reached_at, coalesce(u.display_name, '') AS name, u.leaderboard_hidden, u.university_id, un.name AS uni_name,
	       fb.badge, fb.tier, s.invites, s.other_campus, s.pioneer, s.friend_section, s.join_section, s.blood_donor, s.bus_days, s.sections,
	       s.own_campus, s.own_campus >= $27::int AND s.other_campus >= $26::int AS eligible,
	       row_number() OVER (PARTITION BY s.own_campus >= $27::int AND s.other_campus >= $26::int
	                          ORDER BY s.score DESC, s.reached_at NULLS LAST, s.user_id)::int AS k
	FROM scored s JOIN users u ON u.id = s.user_id JOIN universities un ON un.id = u.university_id
	LEFT JOIN user_badges fb ON fb.user_id = u.id AND fb.badge = u.featured_badge AND NOT fb.private
	WHERE s.score > 0 AND u.verified_at IS NOT NULL AND u.role NOT IN ('admin', 'moderator') AND u.blocked_at IS NULL
	  AND ($5::uuid[] IS NULL OR u.university_id = ANY($5))
	  AND ($6::uuid IS NULL OR u.university_id = $6)
	  AND NOT EXISTS (SELECT 1 FROM campaign_disqualified d WHERE d.campaign_id = $1 AND d.user_id = u.id))
SELECT user_id, score, reached_at, name, leaderboard_hidden, university_id, uni_name, badge, tier,
       invites, other_campus, pioneer, friend_section, join_section, blood_donor, bus_days, sections, own_campus,
       eligible, CASE WHEN eligible THEN k ELSE 0 END
FROM ranked ORDER BY eligible DESC, k LIMIT $7`

func (s *Service) standings(ctx context.Context, c campaign, scopeUni *uuid.UUID, limit int) ([]standing, error) {
	sc := c.Scoring
	busDays, sections := sc.BusShareDays, sc.SectionSetupMax
	if sc.BusShare == 0 {
		busDays = 0
	}
	if sc.SectionSetup == 0 {
		sections = 0
	}
	invitesWorth := sc.Invite+sc.OtherCampus+sc.Pioneer+sc.FriendSection > 0
	rows, err := s.d.Q(ctx).Query(ctx, standingsSQL,
		c.ID, c.StartsAt, c.EndsAt, c.SettlesAt, c.UniversityIDs, scopeUni, limit,
		invitesWorth || sc.MinOtherCampus > 0 || sc.MinOwnCampus > 0, sc.PioneerFirst, sc.JoinSection > 0, sc.BloodDonor > 0,
		busDays, sections, SectionSlotsNeed, SectionMembersNeed, BusShareMinMinutes,
		sc.Invite, sc.OtherCampus, sc.Pioneer, sc.FriendSection, sc.JoinSection, sc.BloodDonor, sc.BusShare, sc.SectionSetup,
		invitesWorth, sc.MinOtherCampus, sc.MinOwnCampus)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var out []standing
	for rows.Next() {
		var x standing
		var badge *string
		var tier *int16
		t := &x.Tally
		if err := rows.Scan(&x.UserID, &x.Score, &x.ReachedAt, &x.Name, &x.Hidden, &x.UniID, &x.UniName, &badge, &tier,
			&t.Invites, &t.OtherCampus, &t.Pioneer, &t.FriendSection, &t.JoinSection, &t.BloodDonor, &t.BusDays, &t.Sections,
			&t.OwnCampus, &x.Eligible, &x.Rank); err != nil {
			return nil, err
		}
		if badge != nil && tier != nil {
			x.Badge = &BadgeRef{Key: *badge, Tier: int(*tier)}
		}
		out = append(out, x)
	}
	return out, rows.Err()
}

// myStanding: the student's row; rank 0 and an empty tally without points.
func (s *Service) myStanding(ctx context.Context, c campaign, uid uuid.UUID) (standing, error) {
	all, err := s.standings(ctx, c, nil, 1_000_000)
	if err != nil {
		return standing{}, err
	}
	for _, x := range all {
		if x.UserID == uid {
			return x, nil
		}
	}
	return standing{UserID: uid}, nil
}

// SectionProgress is my best section as CR that doesn't count yet.
type SectionProgress struct {
	GroupID uuid.UUID `json:"groupId"`
	Name    string    `json:"name"`
	Slots   int       `json:"slots"`
	Members int       `json:"members"`
}

// sectionProgress: of my CR sections that don't meet the thresholds, the one
// closest to them (then the oldest). Nil when the mission is off, I already
// have the most sections that count, or there's none.
func (s *Service) sectionProgress(ctx context.Context, sc Scoring, counted int, uid uuid.UUID) (*SectionProgress, error) {
	if sc.SectionSetup == 0 || sc.SectionSetupMax == 0 || counted >= sc.SectionSetupMax {
		return nil, nil
	}
	rows, err := s.d.Q(ctx).Query(ctx, `
		SELECT g.id, (g.department || ' ' || g.batch || CASE WHEN g.section <> '' THEN ' · ' || g.section ELSE '' END),
		       (SELECT count(*) FROM routine_slots rs WHERE rs.group_id = g.id)::int,
		       (SELECT count(*) FROM class_group_members o JOIN users ou ON ou.id = o.user_id
		         WHERE o.group_id = g.id AND o.user_id <> $1 AND ou.verified_at IS NOT NULL)::int
		FROM class_group_members m JOIN class_groups g ON g.id = m.group_id
		WHERE m.user_id = $1 AND m.role = 'cr'
		ORDER BY g.created_at, g.id`, uid)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var best *SectionProgress
	bestNear := -1
	for rows.Next() {
		var p SectionProgress
		if err := rows.Scan(&p.GroupID, &p.Name, &p.Slots, &p.Members); err != nil {
			return nil, err
		}
		if p.Slots >= SectionSlotsNeed && p.Members >= SectionMembersNeed {
			continue
		}
		if near := min(p.Slots, SectionSlotsNeed) + min(p.Members, SectionMembersNeed); near > bestNear {
			best, bestNear = &p, near
		}
	}
	return best, rows.Err()
}

// ---- student API --------------------------------------------------------------------

type PrizeView struct {
	RankFrom int    `json:"rankFrom"`
	RankTo   int    `json:"rankTo"`
	Title    string `json:"title"`
}

type IWon struct {
	Rank    int    `json:"rank"`
	Prize   string `json:"prize"`
	Claimed bool   `json:"claimed"`
}

// CampaignView is a campaign in the student's language.
type CampaignView struct {
	ID        uuid.UUID   `json:"id"`
	Title     string      `json:"title"`
	Body      string      `json:"body"`
	StartsAt  time.Time   `json:"startsAt"`
	EndsAt    time.Time   `json:"endsAt"`
	SettlesAt time.Time   `json:"settlesAt"`
	Status    string      `json:"status"`
	Prizes    []PrizeView `json:"prizes"`
	MyScore   int         `json:"myScore"`
	MyRank    *int        `json:"myRank"` // null: no points, or not eligible
	// MyOwnCampus / MyOtherCampus: my counted friends at my / other
	// universities; Eligible: at least scoring.minOwnCampus and
	// scoring.minOtherCampus of them, so I'm ranked (§8.5).
	MyOwnCampus   int     `json:"myOwnCampus"`
	MyOtherCampus int     `json:"myOtherCampus"`
	Eligible      bool    `json:"eligible"`
	RulesURL      string  `json:"rulesUrl"`
	BannerURL     *string `json:"bannerUrl"`
	Scoring       Scoring `json:"scoring"`
	// SectionPrize: the prize for the section the team picks from the board
	// (§9.1), in my language; null without one.
	SectionPrize *string `json:"sectionPrize"`
	// Sponsor: "Powered by" (docs/SPONSORS.md §5): {name, logoUrl, link}, or null.
	Sponsor any `json:"sponsor"`
}

// CampaignDetail adds whether the student won, the ways to earn points with
// my progress, my CR section that doesn't count yet, the section challenge
// goal and the finisher reward with my place (§9).
type CampaignDetail struct {
	CampaignView
	IWon             *IWon            `json:"iWon"`
	Missions         []Mission        `json:"missions"`
	Section          *SectionProgress `json:"section"`
	SectionChallenge SectionChallenge `json:"sectionChallenge"`
	FinisherReward   *FinisherReward  `json:"finisherReward"`
	Finisher         *MyFinisher      `json:"finisher"`
}

func (s *Service) view(ctx context.Context, c campaign, uid uuid.UUID) (CampaignView, standing, error) {
	l := lang(ctx)
	v := CampaignView{
		ID: c.ID, Title: pick(l, c.TitleEn, c.TitleBn), Body: pick(l, c.BodyEn, c.BodyBn),
		StartsAt: c.StartsAt.UTC(), EndsAt: c.EndsAt.UTC(), SettlesAt: c.SettlesAt.UTC(), Status: c.state(s.now()),
		Prizes: []PrizeView{}, RulesURL: RulesBase + c.ID.String(), BannerURL: c.bannerURL(), Scoring: c.Scoring,
	}
	if sp := pick(l, c.SectionPrizeEn, c.SectionPrizeBn); sp != "" {
		v.SectionPrize = &sp
	}
	sponsor, err := s.campaignSponsor(ctx, c.ID)
	if err != nil {
		return v, standing{}, err
	}
	v.Sponsor = sponsor
	for _, p := range c.Prizes {
		v.Prizes = append(v.Prizes, PrizeView{RankFrom: p.RankFrom, RankTo: p.RankTo, Title: pick(l, p.TitleEn, p.TitleBn)})
	}
	me, err := s.myStanding(ctx, c, uid)
	if err != nil {
		return v, me, err
	}
	v.MyScore = me.Score
	v.MyOwnCampus, v.MyOtherCampus = me.Tally.OwnCampus, me.Tally.OtherCampus
	v.Eligible = c.Scoring.eligible(me.Tally)
	if me.Rank > 0 {
		rank := me.Rank
		v.MyRank = &rank
	}
	return v, me, nil
}

// visibleTo: a campaign the student may see (not a draft; their university is
// covered; live, ended and not yet announced, or announced in the last 30 days).
func (s *Service) visibleTo(ctx context.Context, c campaign, uni uuid.UUID) bool {
	if c.Status == "draft" || !c.coversUniversity(uni) {
		return false
	}
	if c.Status != "announced" {
		return true
	}
	var at *time.Time
	if err := s.d.Q(ctx).QueryRow(ctx, `SELECT max(announced_at) FROM campaign_winners WHERE campaign_id = $1`, c.ID).Scan(&at); err != nil {
		return false
	}
	ref := c.UpdatedAt
	if at != nil {
		ref = *at
	}
	return s.now().Sub(ref) <= 30*24*time.Hour
}

func (s *Service) studentCampaign(ctx context.Context, rawID string) (campaign, error) {
	id, err := uuid.Parse(rawID)
	if err != nil {
		return campaign{}, ErrCampaignNotFound
	}
	c, err := s.loadCampaign(ctx, id, false)
	if err != nil {
		return c, err
	}
	if !s.visibleTo(ctx, c, auth.MustUser(ctx).UniversityID) {
		return c, ErrCampaignNotFound
	}
	return c, nil
}

func (s *Service) handleCampaigns(ctx context.Context, _ *httpx.Empty) (*[]CampaignView, error) {
	me := auth.MustUser(ctx)
	rows, err := s.d.Q(ctx).Query(ctx, `SELECT `+campaignCols+` FROM campaigns c WHERE c.status <> 'draft' ORDER BY c.starts_at DESC, c.id`)
	if err != nil {
		return nil, err
	}
	var all []campaign
	for rows.Next() {
		c, err := scanCampaign(rows)
		if err != nil {
			rows.Close()
			return nil, err
		}
		all = append(all, c)
	}
	rows.Close()
	if err := rows.Err(); err != nil {
		return nil, err
	}
	out := []CampaignView{}
	for _, c := range all {
		if !s.visibleTo(ctx, c, me.UniversityID) {
			continue
		}
		v, _, err := s.view(ctx, c, me.UserID)
		if err != nil {
			return nil, err
		}
		out = append(out, v)
	}
	return &out, nil
}

type campaignReq struct {
	ID string `json:"-" path:"id" validate:"required,uuid"`
}

func (s *Service) handleCampaign(ctx context.Context, in *campaignReq) (*CampaignDetail, error) {
	me := auth.MustUser(ctx)
	c, err := s.studentCampaign(ctx, in.ID)
	if err != nil {
		return nil, err
	}
	v, mine, err := s.view(ctx, c, me.UserID)
	if err != nil {
		return nil, err
	}
	out := &CampaignDetail{CampaignView: v, Missions: missions(c.Scoring, mine.Tally),
		SectionChallenge: SectionChallenge{Members: ChampionMembers, Slots: ChampionSlots}}
	if out.Section, err = s.sectionProgress(ctx, c.Scoring, mine.Tally.Sections, me.UserID); err != nil {
		return nil, err
	}
	if out.FinisherReward, out.Finisher, err = s.myFinisher(ctx, c, me.UserID); err != nil {
		return nil, err
	}
	var rank int
	var en, bn string
	var claimed *time.Time
	err = s.d.Q(ctx).QueryRow(ctx, `SELECT rank, prize_en, prize_bn, claimed_at FROM campaign_winners WHERE campaign_id = $1 AND user_id = $2`,
		c.ID, me.UserID).Scan(&rank, &en, &bn, &claimed)
	if err == nil {
		out.IWon = &IWon{Rank: rank, Prize: pick(lang(ctx), en, bn), Claimed: claimed != nil}
	} else if !db.IsNoRows(err) {
		return nil, err
	}
	return out, nil
}

// ---- leaderboard --------------------------------------------------------------------

type leaderboardReq struct {
	ID    string `json:"-" path:"id" validate:"required,uuid"`
	Scope string `json:"-" query:"scope" validate:"omitempty,oneof=all university"`
}

// LBRow is one leaderboard line. A student who hides themselves shows as
// "A student at {university}" with no id and no badge.
type LBRow struct {
	Rank          int        `json:"rank"`
	UserID        *uuid.UUID `json:"userId"`
	Name          string     `json:"name"`
	University    string     `json:"university"`
	FeaturedBadge *BadgeRef  `json:"featuredBadge"`
	Score         int        `json:"score"`
	Me            bool       `json:"me"`
}

type Leaderboard struct {
	Rows      []LBRow   `json:"rows"`
	Me        *LBRow    `json:"me"`
	UpdatedAt time.Time `json:"updatedAt"`
}

const leaderboardSize = 50

func (s *Service) lbRow(l string, x standing, me uuid.UUID) LBRow {
	row := LBRow{Rank: x.Rank, Name: x.Name, University: x.UniName, FeaturedBadge: x.Badge, Score: x.Score, Me: x.UserID == me}
	if !row.Me {
		if x.Hidden {
			row.Name, row.FeaturedBadge = pick(l, "A student at "+x.UniName, x.UniName+"-এর একজন শিক্ষার্থী"), nil
		} else {
			id := x.UserID
			row.UserID = &id
		}
	} else {
		id := x.UserID
		row.UserID = &id
	}
	return row
}

func (s *Service) handleLeaderboard(ctx context.Context, in *leaderboardReq) (*Leaderboard, error) {
	me := auth.MustUser(ctx)
	c, err := s.studentCampaign(ctx, in.ID)
	if err != nil {
		return nil, err
	}
	var scope *uuid.UUID
	if in.Scope == "university" && me.UniversityID != uuid.Nil {
		u := me.UniversityID
		scope = &u
	}
	all, err := s.standings(ctx, c, scope, 1_000_000)
	if err != nil {
		return nil, err
	}
	l := lang(ctx)
	out := &Leaderboard{Rows: []LBRow{}, UpdatedAt: s.now().UTC()}
	// Only the eligible are ranked (they come first); my row too.
	for i, x := range all {
		if !x.Eligible {
			break
		}
		if i < leaderboardSize {
			out.Rows = append(out.Rows, s.lbRow(l, x, me.UserID))
		}
		if x.UserID == me.UserID {
			r := s.lbRow(l, x, me.UserID)
			out.Me = &r
		}
	}
	return out, nil
}

// ---- claim a prize ------------------------------------------------------------------

type prizeClaimReq struct {
	ID       string `json:"-" path:"id" validate:"required,uuid"`
	FullName string `json:"fullName" validate:"required,max=80"`
	Phone    string `json:"phone" validate:"required,max=20"`
	Address  string `json:"address" validate:"required,max=300"`
	Note     string `json:"note" validate:"max=300"`
}

func (s *Service) handlePrizeClaim(ctx context.Context, in *prizeClaimReq) (*httpx.Empty, error) {
	me := auth.MustUser(ctx).UserID
	id := uuid.MustParse(in.ID)
	return nil, s.d.InTx(ctx, func(ctx context.Context) error {
		q := s.d.Q(ctx)
		var claimed *time.Time
		err := q.QueryRow(ctx, `SELECT claimed_at FROM campaign_winners WHERE campaign_id = $1 AND user_id = $2 FOR UPDATE`, id, me).Scan(&claimed)
		if db.IsNoRows(err) {
			return ErrNotAWinner
		}
		if err != nil {
			return err
		}
		if claimed != nil {
			return ErrAlreadyClaimed
		}
		if _, err := q.Exec(ctx, `INSERT INTO campaign_claims (campaign_id, user_id, full_name, phone, address, note, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7)`,
			id, me, strings.TrimSpace(in.FullName), strings.TrimSpace(in.Phone), strings.TrimSpace(in.Address), strings.TrimSpace(in.Note), s.now()); err != nil {
			return err
		}
		_, err = q.Exec(ctx, `UPDATE campaign_winners SET claimed_at = $3 WHERE campaign_id = $1 AND user_id = $2`, id, me, s.now())
		return err
	})
}

// ---- public rules page --------------------------------------------------------------

// PublicCampaign is what the web rules page shows: both languages.
type PublicCampaign struct {
	ID        uuid.UUID `json:"id"`
	TitleEn   string    `json:"titleEn"`
	TitleBn   string    `json:"titleBn"`
	BodyEn    string    `json:"bodyEn"`
	BodyBn    string    `json:"bodyBn"`
	RulesEn   string    `json:"rulesEn"`
	RulesBn   string    `json:"rulesBn"`
	StartsAt  time.Time `json:"startsAt"`
	EndsAt    time.Time `json:"endsAt"`
	SettlesAt time.Time `json:"settlesAt"`
	Status    string    `json:"status"`
	Prizes    []Prize   `json:"prizes"`
	BannerURL *string   `json:"bannerUrl"`
	Scoring   Scoring   `json:"scoring"`
	// §9: empty strings and 0 when not set.
	SectionPrizeEn      string `json:"sectionPrizeEn"`
	SectionPrizeBn      string `json:"sectionPrizeBn"`
	FinisherRewardEn    string `json:"finisherRewardEn"`
	FinisherRewardBn    string `json:"finisherRewardBn"`
	FinisherRewardCount int    `json:"finisherRewardCount"`
	// Sponsor: "Powered by" (docs/SPONSORS.md §5), or null.
	Sponsor any `json:"sponsor"`
}

// campaignSponsor: the campaign's live sponsor, or nil.
func (s *Service) campaignSponsor(ctx context.Context, id uuid.UUID) (any, error) {
	if s.ports.CampaignSponsor == nil {
		return nil, nil
	}
	return s.ports.CampaignSponsor(ctx, id)
}

func (s *Service) handlePublicCampaign(ctx context.Context, in *campaignReq) (*PublicCampaign, error) {
	id := uuid.MustParse(in.ID)
	c, err := s.loadCampaign(ctx, id, false)
	if err != nil {
		return nil, err
	}
	if c.Status == "draft" {
		return nil, ErrCampaignNotFound
	}
	sponsor, err := s.campaignSponsor(ctx, c.ID)
	if err != nil {
		return nil, err
	}
	return &PublicCampaign{Sponsor: sponsor,
		ID: c.ID, TitleEn: c.TitleEn, TitleBn: c.TitleBn, BodyEn: c.BodyEn, BodyBn: c.BodyBn, RulesEn: c.RulesEn, RulesBn: c.RulesBn,
		StartsAt: c.StartsAt.UTC(), EndsAt: c.EndsAt.UTC(), SettlesAt: c.SettlesAt.UTC(), Status: c.state(s.now()), Prizes: c.Prizes,
		BannerURL: c.bannerURL(), Scoring: c.Scoring,
		SectionPrizeEn: c.SectionPrizeEn, SectionPrizeBn: c.SectionPrizeBn,
		FinisherRewardEn: c.FinisherRewardEn, FinisherRewardBn: c.FinisherRewardBn, FinisherRewardCount: c.FinisherRewardCount,
	}, nil
}
