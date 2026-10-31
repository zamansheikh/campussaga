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
}

const campaignCols = `c.id, c.title_en, c.title_bn, c.body_en, c.body_bn, c.rules_en, c.rules_bn, c.starts_at, c.ends_at, c.settles_at,
	c.university_ids, c.prizes, c.status, c.created_at, c.updated_at, c.banner_key, c.banner_version`

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
	var prizes []byte
	err := r.Scan(&c.ID, &c.TitleEn, &c.TitleBn, &c.BodyEn, &c.BodyBn, &c.RulesEn, &c.RulesBn, &c.StartsAt, &c.EndsAt, &c.SettlesAt,
		&c.UniversityIDs, &prizes, &c.Status, &c.CreatedAt, &c.UpdatedAt, &c.BannerKey, &c.BannerVersion)
	if err != nil {
		return c, err
	}
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

// Score is the participant's qualified invites with created_at inside the
// campaign and qualified_at by settles_at; disqualified invites, invites on
// the same phone and disqualified participants don't count. Only verified,
// non-team students take part. Ranks go by score, then by who reached it
// first (the last counted invite's qualified_at), then by id.
type standing struct {
	Rank      int
	UserID    uuid.UUID
	Name      string
	Hidden    bool
	UniID     uuid.UUID
	UniName   string
	Score     int
	ReachedAt time.Time
	Badge     *BadgeRef
}

func (s *Service) standings(ctx context.Context, c campaign, scopeUni *uuid.UUID, limit int) ([]standing, error) {
	rows, err := s.d.Q(ctx).Query(ctx, `
		WITH scored AS (
			SELECT r.referrer_id AS user_id, count(*)::int AS score, max(r.qualified_at) AS reached_at
			FROM referrals r
			WHERE r.qualified_at IS NOT NULL AND r.disqualified_at IS NULL AND NOT r.same_device
			  AND r.created_at >= $2 AND r.created_at <= $3 AND r.qualified_at <= $4
			GROUP BY r.referrer_id),
		ranked AS (
			SELECT s.user_id, s.score, s.reached_at, coalesce(u.display_name, ''), u.leaderboard_hidden, u.university_id, un.name,
			       fb.badge, fb.tier,
			       row_number() OVER (ORDER BY s.score DESC, s.reached_at, s.user_id)::int AS rank
			FROM scored s JOIN users u ON u.id = s.user_id JOIN universities un ON un.id = u.university_id
			LEFT JOIN user_badges fb ON fb.user_id = u.id AND fb.badge = u.featured_badge AND NOT fb.private
			WHERE u.verified_at IS NOT NULL AND u.role NOT IN ('admin', 'moderator') AND u.blocked_at IS NULL
			  AND ($5::uuid[] IS NULL OR u.university_id = ANY($5))
			  AND ($6::uuid IS NULL OR u.university_id = $6)
			  AND NOT EXISTS (SELECT 1 FROM campaign_disqualified d WHERE d.campaign_id = $1 AND d.user_id = u.id))
		SELECT * FROM ranked ORDER BY rank LIMIT $7`,
		c.ID, c.StartsAt, c.EndsAt, c.SettlesAt, c.UniversityIDs, scopeUni, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var out []standing
	for rows.Next() {
		var x standing
		var badge *string
		var tier *int16
		if err := rows.Scan(&x.UserID, &x.Score, &x.ReachedAt, &x.Name, &x.Hidden, &x.UniID, &x.UniName, &badge, &tier, &x.Rank); err != nil {
			return nil, err
		}
		if badge != nil && tier != nil {
			x.Badge = &BadgeRef{Key: *badge, Tier: int(*tier)}
		}
		out = append(out, x)
	}
	return out, rows.Err()
}

// myStanding: the student's score and rank (rank 0: no score).
func (s *Service) myStanding(ctx context.Context, c campaign, uid uuid.UUID) (score, rank int, err error) {
	all, err := s.standings(ctx, c, nil, 1_000_000)
	if err != nil {
		return 0, 0, err
	}
	for _, x := range all {
		if x.UserID == uid {
			return x.Score, x.Rank, nil
		}
	}
	return 0, 0, nil
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
	MyRank    *int        `json:"myRank"`
	RulesURL  string      `json:"rulesUrl"`
	BannerURL *string     `json:"bannerUrl"`
}

// CampaignDetail adds whether the student won.
type CampaignDetail struct {
	CampaignView
	IWon *IWon `json:"iWon"`
}

func (s *Service) view(ctx context.Context, c campaign, uid uuid.UUID) (CampaignView, error) {
	l := lang(ctx)
	v := CampaignView{
		ID: c.ID, Title: pick(l, c.TitleEn, c.TitleBn), Body: pick(l, c.BodyEn, c.BodyBn),
		StartsAt: c.StartsAt.UTC(), EndsAt: c.EndsAt.UTC(), SettlesAt: c.SettlesAt.UTC(), Status: c.state(s.now()),
		Prizes: []PrizeView{}, RulesURL: RulesBase + c.ID.String(), BannerURL: c.bannerURL(),
	}
	for _, p := range c.Prizes {
		v.Prizes = append(v.Prizes, PrizeView{RankFrom: p.RankFrom, RankTo: p.RankTo, Title: pick(l, p.TitleEn, p.TitleBn)})
	}
	score, rank, err := s.myStanding(ctx, c, uid)
	if err != nil {
		return v, err
	}
	v.MyScore = score
	if rank > 0 {
		v.MyRank = &rank
	}
	return v, nil
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
		v, err := s.view(ctx, c, me.UserID)
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
	v, err := s.view(ctx, c, me.UserID)
	if err != nil {
		return nil, err
	}
	out := &CampaignDetail{CampaignView: v}
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
	for i, x := range all {
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
	return &PublicCampaign{
		ID: c.ID, TitleEn: c.TitleEn, TitleBn: c.TitleBn, BodyEn: c.BodyEn, BodyBn: c.BodyBn, RulesEn: c.RulesEn, RulesBn: c.RulesBn,
		StartsAt: c.StartsAt.UTC(), EndsAt: c.EndsAt.UTC(), SettlesAt: c.SettlesAt.UTC(), Status: c.state(s.now()), Prizes: c.Prizes,
		BannerURL: c.bannerURL(),
	}, nil
}
