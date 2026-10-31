package app

import (
	"context"
	"encoding/json"
	"io"
	"net/http"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

type gwPrize struct {
	RankFrom int    `json:"rankFrom"`
	RankTo   int    `json:"rankTo"`
	Title    string `json:"title"`
}

type gwCampaign struct {
	ID        string    `json:"id"`
	Title     string    `json:"title"`
	Body      string    `json:"body"`
	StartsAt  string    `json:"startsAt"`
	EndsAt    string    `json:"endsAt"`
	SettlesAt string    `json:"settlesAt"`
	Status    string    `json:"status"`
	Prizes    []gwPrize `json:"prizes"`
	MyScore   int       `json:"myScore"`
	MyRank    *int      `json:"myRank"`
	RulesURL  string    `json:"rulesUrl"`
	IWon      *struct {
		Rank    int    `json:"rank"`
		Prize   string `json:"prize"`
		Claimed bool   `json:"claimed"`
	} `json:"iWon"`
}

type gwRow struct {
	Rank          int     `json:"rank"`
	UserID        *string `json:"userId"`
	Name          string  `json:"name"`
	University    string  `json:"university"`
	FeaturedBadge *struct {
		Key string `json:"key"`
	} `json:"featuredBadge"`
	Score int  `json:"score"`
	Me    bool `json:"me"`
}

type gwBoard struct {
	Rows      []gwRow `json:"rows"`
	Me        *gwRow  `json:"me"`
	UpdatedAt string  `json:"updatedAt"`
}

type gwAdminCampaign struct {
	ID            string   `json:"id"`
	TitleEn       string   `json:"titleEn"`
	TitleBn       string   `json:"titleBn"`
	RulesEn       string   `json:"rulesEn"`
	StartsAt      string   `json:"startsAt"`
	EndsAt        string   `json:"endsAt"`
	SettlesAt     string   `json:"settlesAt"`
	UniversityIDs []string `json:"universityIds"`
	Prizes        []struct {
		RankFrom int    `json:"rankFrom"`
		RankTo   int    `json:"rankTo"`
		TitleEn  string `json:"titleEn"`
		TitleBn  string `json:"titleBn"`
	} `json:"prizes"`
	Status string `json:"status"`
}

type gwStanding struct {
	Rank *int `json:"rank"`
	User struct {
		ID         string `json:"id"`
		Name       string `json:"name"`
		Email      string `json:"email"`
		University string `json:"university"`
	} `json:"user"`
	Score        int  `json:"score"`
	Hidden       bool `json:"hidden"`
	Disqualified bool `json:"disqualified"`
	Invites      []struct {
		Referred struct {
			ID         string `json:"id"`
			Name       string `json:"name"`
			University string `json:"university"`
		} `json:"referred"`
		Source       string  `json:"source"`
		CreatedAt    string  `json:"createdAt"`
		VerifiedVia  *string `json:"verifiedVia"`
		ActiveDays   int     `json:"activeDays"`
		QualifiedAt  *string `json:"qualifiedAt"`
		SameDevice   bool    `json:"sameDevice"`
		Disqualified bool    `json:"disqualified"`
	} `json:"invites"`
	Flags []string `json:"flags"`
}

// invitesOnly: one point per counted invite and nothing else, and no
// minimum of friends from other universities, so the score is the invite
// count and everyone is ranked (TestGrowthPoints covers the rest).
var invitesOnly = map[string]any{
	"invite": 1, "otherCampus": 0, "pioneer": 0, "friendSection": 0, "joinSection": 0, "bloodDonor": 0, "busShare": 0, "sectionSetup": 0,
	"minOwnCampus": 0, "minOtherCampus": 0,
}

func campaignBody(start, end time.Time, extra map[string]any) map[string]any {
	b := map[string]any{
		"scoring": invitesOnly,
		"titleEn": "Invite and win", "titleBn": "আমন্ত্রণ করো, জেতো",
		"bodyEn": "Bring friends who really use VarsityKotha", "bodyBn": "যারা সত্যিই ব্যবহার করে তাদের আনো",
		"rulesEn": "Free to enter. Winners are chosen by rank. Google is not a sponsor.", "rulesBn": "",
		"startsAt": start.UTC().Format(time.RFC3339), "endsAt": end.UTC().Format(time.RFC3339),
		"universityIds": []string{},
		"prizes": []map[string]any{
			{"rankFrom": 1, "rankTo": 1, "titleEn": "Laptop", "titleBn": "ল্যাপটপ"},
			{"rankFrom": 2, "rankTo": 3, "titleEn": "Headphones", "titleBn": "হেডফোন"},
		},
	}
	for k, v := range extra {
		b[k] = v
	}
	return b
}

func (h *harness) gwGetWith(tok, path string, headers map[string]string) *response {
	h.t.Helper()
	req, err := http.NewRequest("GET", h.srv.URL+"/api/v1"+path, nil)
	require.NoError(h.t, err)
	req.Header.Set("Authorization", "Bearer "+tok)
	for k, v := range headers {
		req.Header.Set(k, v)
	}
	res, err := http.DefaultClient.Do(req)
	require.NoError(h.t, err)
	defer res.Body.Close()
	raw, err := io.ReadAll(res.Body)
	require.NoError(h.t, err)
	out := &response{Status: res.StatusCode, Raw: string(raw)}
	if len(raw) > 0 {
		require.NoError(h.t, json.Unmarshal(raw, out), out.Raw)
	}
	return out
}

func (h *harness) gwCampaigns(tok, query string) []gwCampaign {
	h.t.Helper()
	r := h.do("GET", "/campaigns"+query, tok, nil)
	require.Equal(h.t, http.StatusOK, r.Status, r.Raw)
	var out []gwCampaign
	r.into(h.t, &out)
	return out
}

func gwFind(cs []gwCampaign, id string) gwCampaign {
	for _, c := range cs {
		if c.ID == id {
			return c
		}
	}
	return gwCampaign{}
}

func (h *harness) gwBoard(tok, id, query string) gwBoard {
	h.t.Helper()
	r := h.do("GET", "/campaigns/"+id+"/leaderboard"+query, tok, nil)
	require.Equal(h.t, http.StatusOK, r.Status, r.Raw)
	var out gwBoard
	r.into(h.t, &out)
	return out
}

func (h *harness) gwStandings(tok, id string) []gwStanding {
	h.t.Helper()
	r := h.do("GET", "/admin/campaigns/"+id+"/standings", tok, nil)
	require.Equal(h.t, http.StatusOK, r.Status, r.Raw)
	var out []gwStanding
	r.into(h.t, &out)
	return out
}

func (h *harness) gwAdminCampaign(tok, method, path string, body any, want int) gwAdminCampaign {
	h.t.Helper()
	r := h.do(method, path, tok, body)
	require.Equal(h.t, want, r.Status, r.Raw)
	var c gwAdminCampaign
	r.into(h.t, &c)
	return c
}

func TestGrowthCampaigns(t *testing.T) {
	h := newHarness(t)
	ctx := context.Background()
	now := h.Now()
	admin := h.gwStudent("admin@test.ac.bd", "Admin One")
	h.sql(`UPDATE users SET role = 'admin' WHERE id = $1`, admin.ID)
	p1 := h.gwStudent("p1@test.ac.bd", "Parvez One")
	h.sql(`UPDATE users SET created_at = $2 WHERE id = $1`, p1.ID, now.Add(-30*24*time.Hour))
	p2 := h.gwStudent("p2@test.ac.bd", "Pori Two")
	p3 := h.gwStudent("p3@test.ac.bd", "Piyas Three")
	p5 := h.gwStudent("p5@test.ac.bd", "Pavel Five")
	_, qs := h.caOtherUniversity()
	q := &gwUser{Tok: qs.Tok, Refresh: qs.Refresh, ID: qs.ID}
	h.register(p1.Tok, "p1-bn", "android", "bn")
	h.register(p3.Tok, "p3-en", "android", "en")
	require.Equal(t, http.StatusOK, h.do("PATCH", "/me", p2.Tok, map[string]any{"leaderboardHidden": true}).Status)

	// ---- create: validation, drafts are private ----
	start, end := now.Add(-time.Hour), now.Add(2*24*time.Hour)
	assert.Equal(t, http.StatusForbidden, h.do("POST", "/admin/campaigns", p1.Tok, campaignBody(start, end, nil)).Status)
	assert.Equal(t, http.StatusUnauthorized, h.do("POST", "/admin/campaigns", "", campaignBody(start, end, nil)).Status)
	assert.Equal(t, "CAMPAIGN_DATES", h.do("POST", "/admin/campaigns", admin.Tok, campaignBody(end, start, nil)).code())
	assert.Equal(t, "CAMPAIGN_DATES", h.do("POST", "/admin/campaigns", admin.Tok, campaignBody(start, end, map[string]any{"settlesAt": start.Format(time.RFC3339)})).code())
	assert.Equal(t, "CAMPAIGN_PRIZES", h.do("POST", "/admin/campaigns", admin.Tok, campaignBody(start, end, map[string]any{
		"prizes": []map[string]any{{"rankFrom": 1, "rankTo": 2, "titleEn": "A"}, {"rankFrom": 2, "rankTo": 3, "titleEn": "B"}}})).code())
	assert.Equal(t, "VALIDATION_FAILED", h.do("POST", "/admin/campaigns", admin.Tok, campaignBody(start, end, map[string]any{"titleEn": ""})).code())
	assert.Equal(t, "VALIDATION_FAILED", h.do("POST", "/admin/campaigns", admin.Tok, campaignBody(start, end, map[string]any{
		"universityIds": []string{"00000000-0000-0000-0000-0000000000aa"}})).code())

	a := h.gwAdminCampaign(admin.Tok, "POST", "/admin/campaigns", campaignBody(start, end, map[string]any{"rulesEn": ""}), http.StatusCreated)
	assert.Equal(t, "draft", a.Status)
	assert.Equal(t, end.Add(7*24*time.Hour).UTC().Format(time.RFC3339), a.SettlesAt, "settles_at = ends_at + 7 days")
	require.Len(t, a.Prizes, 2)

	assert.Empty(t, h.gwCampaigns(p1.Tok, ""))
	assert.Equal(t, "CAMPAIGN_NOT_FOUND", h.do("GET", "/campaigns/"+a.ID, p1.Tok, nil).code())
	assert.Equal(t, "CAMPAIGN_NOT_FOUND", h.do("GET", "/campaigns/"+a.ID+"/leaderboard", p1.Tok, nil).code())
	assert.Equal(t, http.StatusNotFound, h.do("GET", "/campaigns/"+a.ID+"/public", "", nil).Status)

	// A draft changes freely; it can't go live without rules; then it can.
	assert.Equal(t, "CAMPAIGN_INCOMPLETE", h.do("PATCH", "/admin/campaigns/"+a.ID, admin.Tok, map[string]any{"status": "live"}).code())
	assert.Equal(t, "VALIDATION_FAILED", h.do("PATCH", "/admin/campaigns/"+a.ID, admin.Tok, map[string]any{"status": "ended"}).code())
	a = h.gwAdminCampaign(admin.Tok, "PATCH", "/admin/campaigns/"+a.ID, map[string]any{"titleEn": "Invite and win!", "rulesEn": "Free to enter. Winners are chosen by rank. Google is not a sponsor."}, http.StatusOK)
	assert.Equal(t, "Invite and win!", a.TitleEn)
	a = h.gwAdminCampaign(admin.Tok, "PATCH", "/admin/campaigns/"+a.ID, map[string]any{"titleEn": "Invite and win"}, http.StatusOK)
	a = h.gwAdminCampaign(admin.Tok, "PATCH", "/admin/campaigns/"+a.ID, map[string]any{"status": "live"}, http.StatusOK)
	assert.Equal(t, "live", a.Status)

	// Live: still editable (a spelling fix, new criteria), and it stays live.
	a = h.gwAdminCampaign(admin.Tok, "PATCH", "/admin/campaigns/"+a.ID, map[string]any{"titleEn": "Invite and wim"}, http.StatusOK)
	a = h.gwAdminCampaign(admin.Tok, "PATCH", "/admin/campaigns/"+a.ID, map[string]any{"titleEn": "Invite and win"}, http.StatusOK)
	assert.Equal(t, "Invite and win", a.TitleEn)
	assert.Equal(t, "live", a.Status)
	a = h.gwAdminCampaign(admin.Tok, "PATCH", "/admin/campaigns/"+a.ID, map[string]any{"rulesBn": "বিনামূল্যে অংশগ্রহণ"}, http.StatusOK)
	a = h.gwAdminCampaign(admin.Tok, "PATCH", "/admin/campaigns/"+a.ID, map[string]any{"endsAt": end.Add(24 * time.Hour).Format(time.RFC3339)}, http.StatusOK)
	settles := end.Add(7 * 24 * time.Hour) // unchanged: still after the new end
	end = end.Add(24 * time.Hour)          // 3 days from now
	assert.Equal(t, settles.UTC().Format(time.RFC3339), a.SettlesAt)

	// A second campaign for the test university only.
	uni := h.universityID("test-uni")
	b := h.gwAdminCampaign(admin.Tok, "POST", "/admin/campaigns", campaignBody(start, end, map[string]any{"titleEn": "Test University cup", "universityIds": []string{uni}}), http.StatusCreated)
	b = h.gwAdminCampaign(admin.Tok, "PATCH", "/admin/campaigns/"+b.ID, map[string]any{"status": "live"}, http.StatusOK)
	assert.Equal(t, []string{uni}, b.UniversityIDs)

	var list struct {
		Items    []gwAdminCampaign `json:"items"`
		Total    int               `json:"total"`
		Page     int               `json:"page"`
		PageSize int               `json:"pageSize"`
	}
	h.do("GET", "/admin/campaigns", admin.Tok, nil).into(t, &list)
	assert.Equal(t, 2, list.Total)
	assert.Equal(t, 1, list.Page)
	assert.Equal(t, 25, list.PageSize)
	h.do("GET", "/admin/campaigns?status=draft", admin.Tok, nil).into(t, &list)
	assert.Equal(t, 0, list.Total)
	assert.NotNil(t, list.Items)

	// ---- visibility by university ----
	assert.Len(t, h.gwCampaigns(p1.Tok, ""), 2)
	vis := h.gwCampaigns(q.Tok, "")
	require.Len(t, vis, 1, "the other university sees only the all-universities campaign")
	assert.Equal(t, a.ID, vis[0].ID)
	assert.Equal(t, "CAMPAIGN_NOT_FOUND", h.do("GET", "/campaigns/"+b.ID, q.Tok, nil).code())
	assert.Equal(t, "CAMPAIGN_NOT_FOUND", h.do("GET", "/campaigns/"+b.ID+"/leaderboard", q.Tok, nil).code())

	// ---- scores ----
	win := func(d time.Duration) *time.Time { t := now.Add(d); return &t }
	for i, name := range []string{"F1", "F2", "F3"} { // Parvez: 3, reached first
		h.gwInvite(p1.ID, "P1 friend "+name, now, win(time.Duration(i+1)*time.Minute), false)
	}
	for i, name := range []string{"F1", "F2", "F3"} { // Pori: 3, reached later
		h.gwInvite(p2.ID, "P2 friend "+name, now, win(time.Duration(10+i)*time.Minute), false)
	}
	for i, name := range []string{"F1", "F2", "F3", "F4"} { // Piyas: 4 that count ...
		h.gwInvite(p3.ID, "P3 friend "+name, now, win(time.Duration(20+i)*time.Minute), false)
	}
	h.gwInvite(p3.ID, "P3 same phone", now, win(time.Minute), true)                       // ... same phone
	dq := h.gwInvite(p3.ID, "P3 disqualified", now, win(time.Minute), false)              // ... disqualified
	h.gwInvite(p3.ID, "P3 too early", now.Add(-2*time.Hour), win(-90*time.Minute), false) // ... before the start
	h.gwInvite(p3.ID, "P3 too late", now, win(settles.Sub(now)+time.Hour), false)         // ... qualified after settling
	h.gwInvite(p3.ID, "P3 pending", now, nil, false)                                      // ... not qualified
	h.sql(`UPDATE referrals SET disqualified_at = now(), reason = 'fake' WHERE referred_id = $1`, dq)
	for i := range 10 { // Pavel: 10 within an hour
		h.gwInvite(p5.ID, "P5 friend "+string(rune('A'+i)), now.Add(time.Duration(i)*time.Minute), win(time.Duration(30+i)*time.Minute), false)
	}
	for i := range 2 { // the other university
		h.gwInvite(q.ID, "Q friend "+string(rune('A'+i)), now, win(time.Duration(40+i)*time.Minute), false)
	}
	for i := range 2 { // a team member does not take part
		h.gwInvite(admin.ID, "Admin friend "+string(rune('A'+i)), now, win(time.Duration(i)*time.Minute), false)
	}

	// Pavel (10) leads until the team removes him from the campaign.
	board := h.gwBoard(p1.Tok, a.ID, "")
	require.Len(t, board.Rows, 5)
	assert.Equal(t, "Pavel Five", board.Rows[0].Name)
	assert.Equal(t, 10, board.Rows[0].Score)

	// ---- admin standings, flags ----
	st := h.gwStandings(admin.Tok, a.ID)
	require.Len(t, st, 5)
	byName := map[string]gwStanding{}
	for _, s := range st {
		byName[s.User.Name] = s
		assert.NotNil(t, s.Flags)
	}
	pv := byName["Pavel Five"]
	assert.ElementsMatch(t, []string{"burst", "new_account"}, pv.Flags)
	assert.Len(t, pv.Invites, 10)
	p3s := byName["Piyas Three"]
	assert.Equal(t, 4, p3s.Score)
	assert.ElementsMatch(t, []string{"same_device", "new_account"}, p3s.Flags)
	assert.Equal(t, "p3@test.ac.bd", p3s.User.Email)
	assert.Equal(t, "Test University", p3s.User.University)
	sawSame, sawDq := false, false
	for _, inv := range p3s.Invites {
		sawSame = sawSame || inv.SameDevice
		sawDq = sawDq || inv.Disqualified
		assert.Equal(t, "link", inv.Source)
		assert.NotEmpty(t, inv.CreatedAt)
		require.NotNil(t, inv.VerifiedVia)
		assert.Equal(t, "email", *inv.VerifiedVia)
	}
	assert.True(t, sawSame)
	assert.True(t, sawDq)
	assert.Len(t, p3s.Invites, 8, "all invites inside the dates, counted or not")
	p1s := byName["Parvez One"]
	assert.Empty(t, p1s.Flags, "an old account with few invites has no flags")
	assert.True(t, byName["Pori Two"].Hidden)
	assert.Equal(t, http.StatusForbidden, h.do("GET", "/admin/campaigns/"+a.ID+"/standings", p1.Tok, nil).Status)

	// ---- disqualify a participant, restore, disqualify ----
	assert.Equal(t, http.StatusNoContent, h.do("POST", "/admin/campaigns/"+a.ID+"/participants/"+p5.ID+"/disqualify", admin.Tok, map[string]string{"reason": "burst of invites"}).Status)
	board = h.gwBoard(p1.Tok, a.ID, "")
	require.Len(t, board.Rows, 4)
	assert.Equal(t, "Piyas Three", board.Rows[0].Name)
	st = h.gwStandings(admin.Tok, a.ID)
	require.Len(t, st, 5)
	last := st[len(st)-1]
	assert.True(t, last.Disqualified)
	assert.Nil(t, last.Rank)
	assert.Equal(t, p5.ID, last.User.ID)
	assert.Equal(t, http.StatusNoContent, h.do("DELETE", "/admin/campaigns/"+a.ID+"/participants/"+p5.ID+"/disqualify", admin.Tok, nil).Status)
	assert.Len(t, h.gwBoard(p1.Tok, a.ID, "").Rows, 5)
	h.do("POST", "/admin/campaigns/"+a.ID+"/participants/"+p5.ID+"/disqualify", admin.Tok, map[string]string{"reason": "burst of invites"})
	assert.Equal(t, "USER_NOT_FOUND", h.do("POST", "/admin/campaigns/"+a.ID+"/participants/00000000-0000-0000-0000-0000000000aa/disqualify", admin.Tok, map[string]string{"reason": "x"}).code())

	// ---- a single invite: disqualify and restore ----
	var p1Invite string
	require.NoError(t, h.app.DB.Pool.QueryRow(ctx, `SELECT referred_id::text FROM referrals WHERE referrer_id = $1 LIMIT 1`, p1.ID).Scan(&p1Invite))
	assert.Equal(t, http.StatusNoContent, h.do("POST", "/admin/referrals/"+p1Invite+"/disqualify", admin.Tok, map[string]string{"reason": "same person"}).Status)
	assert.Equal(t, 2, gwFind(h.gwCampaigns(p1.Tok, ""), a.ID).MyScore)
	assert.Equal(t, "REFERRAL_NOT_FOUND", h.do("POST", "/admin/referrals/00000000-0000-0000-0000-0000000000aa/disqualify", admin.Tok, map[string]string{"reason": "x"}).code())
	var refs struct {
		Items []struct {
			Referred struct{ ID string } `json:"referred"`
			Referrer struct{ Name string }
			Flags    []string `json:"flags"`
		} `json:"items"`
		Total int `json:"total"`
	}
	h.do("GET", "/admin/referrals?flag=disqualified", admin.Tok, nil).into(t, &refs)
	assert.Equal(t, 2, refs.Total, "Piyas's and Parvez's")
	h.do("GET", "/admin/referrals?flag=burst", admin.Tok, nil).into(t, &refs)
	assert.Equal(t, 10, refs.Total)
	h.do("GET", "/admin/referrals?q=Pavel&flag=new_account", admin.Tok, nil).into(t, &refs)
	assert.Equal(t, 10, refs.Total)
	assert.Equal(t, http.StatusNoContent, h.do("POST", "/admin/referrals/"+p1Invite+"/restore", admin.Tok, nil).Status)
	h.do("GET", "/admin/referrals?flag=disqualified", admin.Tok, nil).into(t, &refs)
	assert.Equal(t, 1, refs.Total)

	// ---- the student's views ----
	ca := gwFind(h.gwCampaigns(p1.Tok, ""), a.ID)
	assert.Equal(t, "Invite and win", ca.Title)
	assert.Equal(t, "Bring friends who really use VarsityKotha", ca.Body)
	assert.Equal(t, "live", ca.Status)
	assert.Equal(t, 3, ca.MyScore)
	require.NotNil(t, ca.MyRank)
	assert.Equal(t, 2, *ca.MyRank, "behind Piyas (4); ahead of Pori, who reached 3 later")
	assert.Equal(t, "https://varsitykotha.com/campaigns/"+a.ID, ca.RulesURL)
	assert.Equal(t, []gwPrize{{1, 1, "Laptop"}, {2, 3, "Headphones"}}, ca.Prizes)
	assert.Equal(t, settles.UTC().Format(time.RFC3339), ca.SettlesAt)
	// Language: ?lang, Accept-Language, English by default; Bangla falls back to English.
	assert.Equal(t, "আমন্ত্রণ করো, জেতো", gwFind(h.gwCampaigns(p1.Tok, "?lang=bn"), a.ID).Title)
	r := h.gwGetWith(p1.Tok, "/campaigns", map[string]string{"Accept-Language": "bn-BD,bn;q=0.9,en;q=0.8"})
	var viaHeader []gwCampaign
	r.into(t, &viaHeader)
	assert.Equal(t, "আমন্ত্রণ করো, জেতো", gwFind(viaHeader, a.ID).Title)
	assert.Equal(t, "ল্যাপটপ", gwFind(viaHeader, a.ID).Prizes[0].Title)
	r = h.gwGetWith(p1.Tok, "/campaigns?lang=en", map[string]string{"Accept-Language": "bn"})
	r.into(t, &viaHeader)
	assert.Equal(t, "Invite and win", gwFind(viaHeader, a.ID).Title, "the lang parameter wins")
	r = h.gwGetWith(p1.Tok, "/campaigns", map[string]string{"Accept-Language": "fr-FR"})
	r.into(t, &viaHeader)
	assert.Equal(t, "Invite and win", gwFind(viaHeader, a.ID).Title)
	// A student without invites has a zero score and no rank.
	r = h.do("GET", "/campaigns/"+a.ID, h.gwStudent("zero@test.ac.bd", "Zero Score").Tok, nil)
	var det gwCampaign
	r.into(t, &det)
	assert.Equal(t, 0, det.MyScore)
	assert.Nil(t, det.MyRank)
	assert.Nil(t, det.IWon)
	assert.Equal(t, "VALIDATION_FAILED", h.do("GET", "/campaigns/not-a-uuid", p1.Tok, nil).code())

	// ---- leaderboard: order, tie-break, hidden names, my row, scopes ----
	board = h.gwBoard(p1.Tok, a.ID, "")
	require.Len(t, board.Rows, 4)
	assert.NotEmpty(t, board.UpdatedAt)
	var names []string
	for _, row := range board.Rows {
		names = append(names, row.Name)
	}
	assert.Equal(t, []string{"Piyas Three", "Parvez One", "A student at Test University"}, names[:3])
	assert.Equal(t, []int{4, 3, 3, 2}, []int{board.Rows[0].Score, board.Rows[1].Score, board.Rows[2].Score, board.Rows[3].Score})
	assert.Equal(t, []int{1, 2, 3, 4}, []int{board.Rows[0].Rank, board.Rows[1].Rank, board.Rows[2].Rank, board.Rows[3].Rank})
	hidden := board.Rows[2]
	assert.Nil(t, hidden.UserID, "a hidden student can't be opened")
	assert.Nil(t, hidden.FeaturedBadge)
	assert.NotContains(t, h.do("GET", "/campaigns/"+a.ID+"/leaderboard", p1.Tok, nil).Raw, "Pori")
	require.NotNil(t, board.Rows[1].UserID)
	assert.Equal(t, p1.ID, *board.Rows[1].UserID)
	assert.Equal(t, "Test University", board.Rows[0].University)
	assert.Equal(t, "Other University", board.Rows[3].University)
	require.NotNil(t, board.Me)
	assert.Equal(t, 2, board.Me.Rank)
	assert.True(t, board.Me.Me)
	assert.True(t, board.Rows[1].Me)
	assert.False(t, board.Rows[0].Me)
	// The hidden student sees their own name on their own row.
	own := h.gwBoard(p2.Tok, a.ID, "")
	require.NotNil(t, own.Me)
	assert.Equal(t, "Pori Two", own.Me.Name)
	assert.Equal(t, "Pori Two", own.Rows[2].Name)
	assert.Equal(t, 3, own.Me.Rank)
	// My university only.
	uniBoard := h.gwBoard(p1.Tok, a.ID, "?scope=university")
	require.Len(t, uniBoard.Rows, 3)
	assert.Equal(t, 2, uniBoard.Me.Rank)
	qBoard := h.gwBoard(q.Tok, a.ID, "?scope=university")
	require.Len(t, qBoard.Rows, 1)
	assert.Equal(t, 1, qBoard.Me.Rank)
	assert.Equal(t, 4, h.gwBoard(q.Tok, a.ID, "?scope=all").Me.Rank)
	assert.Equal(t, "VALIDATION_FAILED", h.do("GET", "/campaigns/"+a.ID+"/leaderboard?scope=world", p1.Tok, nil).code())
	// Someone with no invites has no row.
	assert.Nil(t, h.gwBoard(admin.Tok, a.ID, "").Me)
	// The top 50 only.
	for i := range 52 {
		f := h.gwFake("Bulk "+string(rune('a'+i%26))+string(rune('a'+i/26)), now)
		h.sql(`INSERT INTO referrals (referred_id, referrer_id, source, created_at, qualified_at) VALUES ($1, $2, 'link', $3, $3)`, h.gwFake("Bulk friend "+string(rune('a'+i%26))+string(rune('a'+i/26)), now), f, now)
	}
	big := h.gwBoard(p1.Tok, a.ID, "")
	assert.Len(t, big.Rows, 50)
	require.NotNil(t, big.Me, "my row is returned even outside the top 50")
	assert.Equal(t, 2, big.Me.Rank)

	// ---- public rules page ----
	r = h.do("GET", "/campaigns/"+a.ID+"/public", "", nil)
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	var pub struct {
		TitleEn string `json:"titleEn"`
		TitleBn string `json:"titleBn"`
		RulesEn string `json:"rulesEn"`
		RulesBn string `json:"rulesBn"`
		BodyEn  string `json:"bodyEn"`
		Prizes  []struct {
			TitleEn string `json:"titleEn"`
			TitleBn string `json:"titleBn"`
		} `json:"prizes"`
		StartsAt string `json:"startsAt"`
		EndsAt   string `json:"endsAt"`
		Status   string `json:"status"`
	}
	r.into(t, &pub)
	assert.Equal(t, "Invite and win", pub.TitleEn)
	assert.Equal(t, "আমন্ত্রণ করো, জেতো", pub.TitleBn)
	assert.Contains(t, pub.RulesEn, "Google is not a sponsor")
	assert.Equal(t, "বিনামূল্যে অংশগ্রহণ", pub.RulesBn)
	require.Len(t, pub.Prizes, 2)
	assert.Equal(t, "ল্যাপটপ", pub.Prizes[0].TitleBn)

	// ---- stats ----
	var stats struct {
		Growth struct {
			InvitesLast7Days   int `json:"invitesLast7Days"`
			QualifiedLast7Days int `json:"qualifiedLast7Days"`
			LiveCampaigns      int `json:"liveCampaigns"`
		} `json:"growth"`
	}
	h.do("GET", "/admin/stats", admin.Tok, nil).into(t, &stats)
	var inv, qual int
	require.NoError(t, h.app.DB.Pool.QueryRow(ctx, `SELECT count(*) FILTER (WHERE created_at >= $1), count(*) FILTER (WHERE qualified_at >= $1) FROM referrals`, now.Add(-7*24*time.Hour)).Scan(&inv, &qual))
	assert.Equal(t, inv, stats.Growth.InvitesLast7Days)
	assert.Equal(t, qual, stats.Growth.QualifiedLast7Days)
	assert.Greater(t, inv, 20)
	assert.Equal(t, 2, stats.Growth.LiveCampaigns)

	// ---- announce only after settling ----
	picks := []map[string]any{{"userId": p3.ID, "rank": 1}, {"userId": p1.ID, "rank": 2}}
	nr := h.do("POST", "/admin/campaigns/"+a.ID+"/announce", admin.Tok, map[string]any{"winners": picks})
	assert.Equal(t, "CAMPAIGN_NOT_SETTLED", nr.code())
	assert.Equal(t, http.StatusConflict, nr.Status)
	h.advance(11 * 24 * time.Hour)
	for _, u := range []*gwUser{admin, p1, p2, p3, q} {
		h.gwRefresh(u)
	}
	h.pushes()
	assert.Equal(t, "ended", h.gwAdminCampaign(admin.Tok, "GET", "/admin/campaigns/"+a.ID, nil, http.StatusOK).Status)
	assert.Equal(t, "ended", gwFind(h.gwCampaigns(p1.Tok, ""), a.ID).Status)
	assert.Equal(t, "VALIDATION_FAILED", h.do("POST", "/admin/campaigns/"+a.ID+"/announce", admin.Tok, map[string]any{"winners": []any{}}).code())
	for name, bad := range map[string][]map[string]any{
		"not a participant": {{"userId": admin.ID, "rank": 1}},
		"disqualified":      {{"userId": p5.ID, "rank": 1}},
		"no prize at rank":  {{"userId": p3.ID, "rank": 4}},
		"same rank twice":   {{"userId": p3.ID, "rank": 2}, {"userId": p1.ID, "rank": 2}},
		"same user twice":   {{"userId": p3.ID, "rank": 1}, {"userId": p3.ID, "rank": 2}},
	} {
		assert.Equal(t, "CAMPAIGN_WINNERS", h.do("POST", "/admin/campaigns/"+a.ID+"/announce", admin.Tok, map[string]any{"winners": bad}).code(), name)
	}
	assert.Equal(t, http.StatusForbidden, h.do("POST", "/admin/campaigns/"+a.ID+"/announce", p1.Tok, map[string]any{"winners": picks}).Status)

	r = h.do("POST", "/admin/campaigns/"+a.ID+"/announce", admin.Tok, map[string]any{"winners": picks})
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	var won []struct {
		UserID  string `json:"userId"`
		Rank    int    `json:"rank"`
		PrizeEn string `json:"prizeEn"`
		PrizeBn string `json:"prizeBn"`
	}
	r.into(t, &won)
	require.Len(t, won, 2)
	assert.Equal(t, p3.ID, won[0].UserID)
	assert.Equal(t, "Laptop", won[0].PrizeEn)
	assert.Equal(t, "হেডফোন", won[1].PrizeBn)
	assert.Equal(t, "announced", h.gwAdminCampaign(admin.Tok, "GET", "/admin/campaigns/"+a.ID, nil, http.StatusOK).Status)
	pushed := map[string]string{}
	for _, n := range h.pushes() {
		assert.Equal(t, "campaign_won", n.Data["type"])
		assert.Equal(t, a.ID, n.Data["campaignId"])
		pushed[n.Token] = n.Title
	}
	assert.Equal(t, map[string]string{"p3-en": "You won: Laptop!", "p1-bn": "তুমি জিতেছ: হেডফোন!"}, pushed)
	assert.Equal(t, "CAMPAIGN_NOT_ANNOUNCEABLE", h.do("POST", "/admin/campaigns/"+a.ID+"/announce", admin.Tok, map[string]any{"winners": picks}).code())
	// Even after the announcement the text can be fixed; it stays announced.
	fixed := h.gwAdminCampaign(admin.Tok, "PATCH", "/admin/campaigns/"+a.ID, map[string]any{"rulesBn": "বিনামূল্যে অংশগ্রহণ।"}, http.StatusOK)
	assert.Equal(t, "announced", fixed.Status)
	assert.Equal(t, "CAMPAIGN_WINNERS", h.do("POST", "/admin/campaigns/"+b.ID+"/announce", admin.Tok, map[string]any{"winners": []map[string]any{{"userId": admin.ID, "rank": 1}}}).code(), "winners must be participants of that campaign")

	// ---- winners claim ----
	r = h.do("GET", "/campaigns/"+a.ID, p3.Tok, nil)
	var d3 gwCampaign
	r.into(t, &d3)
	require.NotNil(t, d3.IWon)
	assert.Equal(t, 1, d3.IWon.Rank)
	assert.Equal(t, "Laptop", d3.IWon.Prize)
	assert.False(t, d3.IWon.Claimed)
	var d1 gwCampaign
	h.do("GET", "/campaigns/"+a.ID+"?lang=bn", p1.Tok, nil).into(t, &d1)
	require.NotNil(t, d1.IWon)
	assert.Equal(t, "হেডফোন", d1.IWon.Prize)
	var d2 gwCampaign
	h.do("GET", "/campaigns/"+a.ID, p2.Tok, nil).into(t, &d2)
	assert.Nil(t, d2.IWon)

	claim := map[string]any{"fullName": "Piyas Three", "phone": "01712345678", "address": "House 1, Road 2, Dhaka", "note": "After 5 pm"}
	nw := h.do("POST", "/campaigns/"+a.ID+"/claim", p2.Tok, claim)
	assert.Equal(t, "NOT_A_WINNER", nw.code())
	assert.Equal(t, http.StatusForbidden, nw.Status)
	assert.Equal(t, "VALIDATION_FAILED", h.do("POST", "/campaigns/"+a.ID+"/claim", p3.Tok, map[string]any{"fullName": "Piyas", "phone": "017"}).code())
	assert.Equal(t, http.StatusNoContent, h.do("POST", "/campaigns/"+a.ID+"/claim", p3.Tok, claim).Status)
	again := h.do("POST", "/campaigns/"+a.ID+"/claim", p3.Tok, claim)
	assert.Equal(t, "ALREADY_CLAIMED", again.code())
	assert.Equal(t, http.StatusConflict, again.Status)
	h.do("GET", "/campaigns/"+a.ID, p3.Tok, nil).into(t, &d3)
	assert.True(t, d3.IWon.Claimed)

	r = h.do("GET", "/admin/campaigns/"+a.ID+"/winners", admin.Tok, nil)
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	var ws []struct {
		UserID      string  `json:"userId"`
		Rank        int     `json:"rank"`
		Email       string  `json:"email"`
		ClaimedAt   *string `json:"claimedAt"`
		DeliveredAt *string `json:"deliveredAt"`
		Claim       *struct {
			FullName string `json:"fullName"`
			Phone    string `json:"phone"`
			Address  string `json:"address"`
			Note     string `json:"note"`
		} `json:"claim"`
	}
	r.into(t, &ws)
	require.Len(t, ws, 2)
	require.NotNil(t, ws[0].Claim)
	assert.Equal(t, "01712345678", ws[0].Claim.Phone)
	assert.Equal(t, "House 1, Road 2, Dhaka", ws[0].Claim.Address)
	assert.NotNil(t, ws[0].ClaimedAt)
	assert.Nil(t, ws[0].DeliveredAt)
	assert.Nil(t, ws[1].Claim)
	assert.Equal(t, http.StatusForbidden, h.do("GET", "/admin/campaigns/"+a.ID+"/winners", p3.Tok, nil).Status)

	assert.Equal(t, http.StatusNoContent, h.do("POST", "/admin/campaigns/"+a.ID+"/winners/"+p3.ID+"/delivered", admin.Tok, nil).Status)
	assert.Equal(t, "NOT_A_WINNER", h.do("POST", "/admin/campaigns/"+a.ID+"/winners/"+p2.ID+"/delivered", admin.Tok, nil).code())
	h.do("GET", "/admin/campaigns/"+a.ID+"/winners", admin.Tok, nil).into(t, &ws)
	assert.NotNil(t, ws[0].DeliveredAt)

	// Claims go 90 days after delivery; the win and the claimed mark stay.
	var n int
	h.gwSweep()
	require.NoError(t, h.app.DB.Pool.QueryRow(ctx, `SELECT count(*) FROM campaign_claims`).Scan(&n))
	assert.Equal(t, 1, n)
	h.sql(`UPDATE campaign_winners SET delivered_at = $1 WHERE user_id = $2`, h.Now().Add(-91*24*time.Hour), p3.ID)
	h.gwSweep()
	require.NoError(t, h.app.DB.Pool.QueryRow(ctx, `SELECT count(*) FROM campaign_claims`).Scan(&n))
	assert.Zero(t, n)
	require.NoError(t, h.app.DB.Pool.QueryRow(ctx, `SELECT count(*) FROM campaign_winners WHERE claimed_at IS NOT NULL`).Scan(&n))
	assert.Equal(t, 1, n)

	// Announced campaigns stay visible for 30 days.
	assert.Len(t, h.gwCampaigns(p1.Tok, ""), 2, "A announced; the cup still live or ended")
	h.sql(`UPDATE campaign_winners SET announced_at = $1`, h.Now().Add(-31*24*time.Hour))
	for _, c := range h.gwCampaigns(p1.Tok, "") {
		assert.NotEqual(t, a.ID, c.ID)
	}
	assert.Equal(t, "CAMPAIGN_NOT_FOUND", h.do("GET", "/campaigns/"+a.ID, p1.Tok, nil).code())
	assert.Equal(t, http.StatusOK, h.do("GET", "/campaigns/"+a.ID+"/public", "", nil).Status, "the rules page stays")

	// ---- audit rows ----
	counts := map[string]int{}
	rows, err := h.app.DB.Pool.Query(ctx, `SELECT action, count(*)::int FROM audit_log WHERE action LIKE 'campaign.%' OR action LIKE 'referral.%' GROUP BY action`)
	require.NoError(t, err)
	for rows.Next() {
		var a string
		var c int
		require.NoError(t, rows.Scan(&a, &c))
		counts[a] = c
	}
	rows.Close()
	assert.Equal(t, 2, counts["campaign.create"])
	assert.Equal(t, 2, counts["campaign.publish"])
	assert.GreaterOrEqual(t, counts["campaign.update"], 3)
	assert.Equal(t, 2, counts["campaign.disqualify"])
	assert.Equal(t, 1, counts["campaign.restore"])
	assert.Equal(t, 1, counts["campaign.announce"])
	assert.Equal(t, 1, counts["campaign.delivered"])
	assert.Equal(t, 1, counts["referral.disqualify"])
	assert.Equal(t, 1, counts["referral.restore"])
}
