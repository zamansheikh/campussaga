package app

import (
	"context"
	"net/http"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

type rwSectionRow struct {
	Rank       int    `json:"rank"`
	GroupID    string `json:"groupId"`
	Name       string `json:"name"`
	University string `json:"university"`
	Members    int    `json:"members"`
	Slots      int    `json:"slots"`
	Champion   bool   `json:"champion"`
	CR         *struct {
		ID    string `json:"id"`
		Name  string `json:"name"`
		Email string `json:"email"`
	} `json:"cr"`
}

type rwBoard struct {
	Rows []rwSectionRow `json:"rows"`
	Mine *rwSectionRow  `json:"mine"`
}

type rwDetail struct {
	ID               string  `json:"id"`
	SectionPrize     *string `json:"sectionPrize"`
	SectionChallenge struct {
		Members int `json:"members"`
		Slots   int `json:"slots"`
	} `json:"sectionChallenge"`
	FinisherReward *struct {
		Title string `json:"title"`
		Count int    `json:"count"`
		Left  int    `json:"left"`
	} `json:"finisherReward"`
	Finisher *struct {
		Position int  `json:"position"`
		InReward bool `json:"inReward"`
		Claimed  bool `json:"claimed"`
		Sent     bool `json:"sent"`
	} `json:"finisher"`
}

type rwFinisher struct {
	Position int `json:"position"`
	User     struct {
		ID         string `json:"id"`
		Name       string `json:"name"`
		Email      string `json:"email"`
		University string `json:"university"`
	} `json:"user"`
	FinishedAt string  `json:"finishedAt"`
	InReward   bool    `json:"inReward"`
	Phone      *string `json:"phone"`
	ClaimedAt  *string `json:"claimedAt"`
	SentAt     *string `json:"sentAt"`
}

// rwCode is the n-th class join code (6 letters without I or O).
func rwCode(n int) string {
	const letters = "ABCDEFGHJKLMNPQRSTUVWXYZ"
	b := []byte("AAAAAA")
	for i := 5; i >= 0 && n > 0; i-- {
		b[i] = letters[n%len(letters)]
		n /= len(letters)
	}
	return string(b)
}

// rwPeople inserts n verified students at a university.
func (h *harness) rwPeople(prefix, uni string, n int) []string {
	h.t.Helper()
	at := h.Now().Add(-10 * 24 * time.Hour)
	out := make([]string, n)
	for i := range n {
		out[i] = h.ptUser(prefix+" "+rwCode(i+1), uni, &at, "")
	}
	return out
}

func (h *harness) rwDetail(tok, id, query string) rwDetail {
	h.t.Helper()
	r := h.do("GET", "/campaigns/"+id+query, tok, nil)
	require.Equal(h.t, http.StatusOK, r.Status, r.Raw)
	var d rwDetail
	r.into(h.t, &d)
	return d
}

func (h *harness) rwHasBadge(user, badge string) bool {
	h.t.Helper()
	var n int
	require.NoError(h.t, h.app.DB.Pool.QueryRow(context.Background(), `SELECT count(*) FROM user_badges WHERE user_id = $1 AND badge = $2`, user, badge).Scan(&n))
	return n == 1
}

func TestGrowthSectionChallenge(t *testing.T) {
	h := newHarness(t)
	ctx := context.Background()
	now := h.Now()
	admin := h.gwStudent("admin@test.ac.bd", "Admin One")
	h.sql(`UPDATE users SET role = 'admin' WHERE id = $1`, admin.ID)
	sara := h.gwStudent("sara@test.ac.bd", "Sara Section")
	tara := h.gwStudent("tara@test.ac.bd", "Tara Tiny")
	uma := h.gwStudent("uma@test.ac.bd", "Uma None")
	uni := h.universityID("test-uni")
	h.sql(`INSERT INTO universities (slug, name) VALUES ('far-uni', 'Far University')`)
	far := h.universityID("far-uni")
	start, end := now.Add(-time.Hour), now.Add(10*24*time.Hour)

	// ---- the section prize: on list, detail (my language) and public; none without one ----
	a := h.gwAdminCampaign(admin.Tok, "POST", "/admin/campaigns", campaignBody(start, end, map[string]any{
		"sectionPrizeEn": "Pizza party for the section", "sectionPrizeBn": "সেকশনের জন্য পিজ্জা পার্টি"}), http.StatusCreated)
	h.gwAdminCampaign(admin.Tok, "PATCH", "/admin/campaigns/"+a.ID, map[string]any{"status": "live"}, http.StatusOK)
	plain := h.gwAdminCampaign(admin.Tok, "POST", "/admin/campaigns", campaignBody(start, end, map[string]any{"titleEn": "No section prize"}), http.StatusCreated)
	h.gwAdminCampaign(admin.Tok, "PATCH", "/admin/campaigns/"+plain.ID, map[string]any{"status": "live"}, http.StatusOK)
	farOnly := h.gwAdminCampaign(admin.Tok, "POST", "/admin/campaigns", campaignBody(start, end, map[string]any{
		"titleEn": "Far only", "universityIds": []string{far}}), http.StatusCreated)
	// Editable while live; set back to keep the checks below.
	h.gwAdminCampaign(admin.Tok, "PATCH", "/admin/campaigns/"+a.ID, map[string]any{"sectionPrizeEn": "Other"}, http.StatusOK)
	h.gwAdminCampaign(admin.Tok, "PATCH", "/admin/campaigns/"+a.ID, map[string]any{"sectionPrizeEn": "Pizza party for the section"}, http.StatusOK)
	assert.Equal(t, "VALIDATION_FAILED", h.do("POST", "/admin/campaigns", admin.Tok, campaignBody(start, end, map[string]any{
		"sectionPrizeEn": strings.Repeat("x", 121)})).code())

	d := h.rwDetail(sara.Tok, a.ID, "")
	require.NotNil(t, d.SectionPrize)
	assert.Equal(t, "Pizza party for the section", *d.SectionPrize)
	assert.Equal(t, 25, d.SectionChallenge.Members)
	assert.Equal(t, 5, d.SectionChallenge.Slots)
	assert.Equal(t, "সেকশনের জন্য পিজ্জা পার্টি", *h.rwDetail(sara.Tok, a.ID, "?lang=bn").SectionPrize)
	assert.Nil(t, h.rwDetail(sara.Tok, plain.ID, "").SectionPrize)
	var list []rwDetail
	h.do("GET", "/campaigns", sara.Tok, nil).into(t, &list)
	for _, c := range list {
		if c.ID == a.ID {
			require.NotNil(t, c.SectionPrize)
			assert.Equal(t, "Pizza party for the section", *c.SectionPrize)
		}
	}
	var pub struct {
		SectionPrizeEn string `json:"sectionPrizeEn"`
		SectionPrizeBn string `json:"sectionPrizeBn"`
	}
	h.do("GET", "/campaigns/"+a.ID+"/public", "", nil).into(t, &pub)
	assert.Equal(t, "Pizza party for the section", pub.SectionPrizeEn)
	assert.Equal(t, "সেকশনের জন্য পিজ্জা পার্টি", pub.SectionPrizeBn)

	// ---- sections ----
	code := 0
	group := func(section string, cr string, slots int, members ...string) string {
		code++
		return h.ptGroup(uni, rwCode(1000+code), section, cr, now.Add(-time.Duration(100-code)*time.Hour), slots, members...)
	}
	crs := h.rwPeople("Captain", uni, 30)
	fewSlots := group("Few", crs[0], 4, h.rwPeople("Few member", uni, 29)...)                               // 30 verified, 4 classes
	champ := group("Champ", crs[1], 5, append(h.rwPeople("Champ member", uni, 24), sara.ID)...)             // 26 verified, 5 classes
	near := group("Near", crs[2], 5, append(h.rwPeople("Near member", uni, 23), h.rwPeople2(uni, 2)...)...) // 24 verified (+2 not)
	tieEarly := group("TieEarly", crs[3], 1, h.rwPeople("Early member", uni, 2)...)
	tieLate := group("TieLate", crs[4], 1, h.rwPeople("Late member", uni, 2)...)
	// The last verified member of TieLate joined after everyone in TieEarly.
	h.sql(`UPDATE class_group_members SET joined_at = $2 WHERE group_id = $1`, tieEarly, now.Add(-5*time.Hour))
	h.sql(`UPDATE class_group_members SET joined_at = $2 WHERE group_id = $1`, tieLate, now.Add(-4*time.Hour))
	for i := range 20 { // twenty groups of two
		group("Pair", crs[5+i], 0, h.rwPeople("Pair member "+rwCode(i), uni, 1)...)
	}
	tiny := group("Tiny", tara.ID, 0) // just Tara
	// A section without a CR, and one at Far University.
	var noCR string
	require.NoError(t, h.app.DB.Pool.QueryRow(ctx, `INSERT INTO class_groups (university_id, department, batch, section, semester, join_code)
		VALUES ($1, 'EEE', '12', '', 'Fall 2026', 'ZZZZZZ') RETURNING id`, uni).Scan(&noCR))
	for _, m := range h.rwPeople("Loose member", uni, 2) {
		h.sql(`INSERT INTO class_group_members (group_id, user_id, role) VALUES ($1, $2, 'member')`, noCR, m)
	}
	farCR := h.ptUser("Far Captain", far, &start, "")
	h.sql(`INSERT INTO class_groups (university_id, department, batch, section, semester, join_code, created_by) VALUES ($1, 'BBA', '9', 'A', 'Fall 2026', 'YYYYYY', $2)`, far, farCR)
	h.sql(`INSERT INTO class_group_members (group_id, user_id, role) SELECT id, $1, 'cr' FROM class_groups WHERE join_code = 'YYYYYY'`, farCR)

	r := h.do("GET", "/campaigns/"+a.ID+"/sections", sara.Tok, nil)
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	var board rwBoard
	r.into(t, &board)
	require.Len(t, board.Rows, 20, "the top 20")
	top := func(i int) rwSectionRow { return board.Rows[i] }
	assert.Equal(t, []string{fewSlots, champ, near, tieEarly, tieLate}, []string{top(0).GroupID, top(1).GroupID, top(2).GroupID, top(3).GroupID, top(4).GroupID},
		"by verified members; a tie goes to the group that reached it first")
	assert.Equal(t, []int{30, 26, 24, 3, 3}, []int{top(0).Members, top(1).Members, top(2).Members, top(3).Members, top(4).Members})
	assert.Equal(t, []bool{false, true, false, false, false}, []bool{top(0).Champion, top(1).Champion, top(2).Champion, top(3).Champion, top(4).Champion},
		"25+ verified members and 5+ classes")
	assert.Equal(t, 4, top(0).Slots)
	assert.Equal(t, "CSE 40 · Champ", top(1).Name)
	assert.Equal(t, "Test University", top(1).University)
	for i, row := range board.Rows {
		assert.Equal(t, i+1, row.Rank)
		assert.Nil(t, row.CR, "students don't see the CR's details")
	}
	require.NotNil(t, board.Mine)
	assert.Equal(t, champ, board.Mine.GroupID, "my best section")
	assert.Equal(t, 2, board.Mine.Rank)
	var tb rwBoard
	h.do("GET", "/campaigns/"+a.ID+"/sections", tara.Tok, nil).into(t, &tb)
	require.NotNil(t, tb.Mine)
	assert.Equal(t, tiny, tb.Mine.GroupID)
	assert.Greater(t, tb.Mine.Rank, 20, "mine also outside the top 20")
	assert.Equal(t, 1, tb.Mine.Members)
	var ub rwBoard
	h.do("GET", "/campaigns/"+a.ID+"/sections", uma.Tok, nil).into(t, &ub)
	assert.Nil(t, ub.Mine)
	assert.Equal(t, "CAMPAIGN_NOT_FOUND", h.do("GET", "/campaigns/"+farOnly.ID+"/sections", sara.Tok, nil).code())

	// ---- the team's board: top 50 with the CR; only the campaign's universities ----
	var ab rwBoard
	ar := h.do("GET", "/admin/campaigns/"+a.ID+"/sections", admin.Tok, nil)
	require.Equal(t, http.StatusOK, ar.Status, ar.Raw)
	ar.into(t, &ab)
	assert.Len(t, ab.Rows, 28, "every section with a verified member, both universities")
	assert.Nil(t, ab.Mine)
	require.NotNil(t, ab.Rows[0].CR)
	assert.Equal(t, crs[0], ab.Rows[0].CR.ID)
	assert.Equal(t, "Captain "+rwCode(1), ab.Rows[0].CR.Name)
	assert.Contains(t, ab.Rows[0].CR.Email, "@points.test")
	for _, row := range ab.Rows {
		if row.GroupID == noCR {
			assert.Nil(t, row.CR)
			assert.Equal(t, "EEE 12", row.Name)
		}
	}
	h.do("GET", "/admin/campaigns/"+farOnly.ID+"/sections", admin.Tok, nil).into(t, &ab)
	require.Len(t, ab.Rows, 1)
	assert.Equal(t, "Far University", ab.Rows[0].University)
	assert.Equal(t, http.StatusForbidden, h.do("GET", "/admin/campaigns/"+a.ID+"/sections", sara.Tok, nil).Status)

	// ---- the champion_section badge: every member, CR included; it stays ----
	assert.True(t, h.gwBadges(sara.Tok).has("champion_section"))
	require.NoError(t, h.app.Growth.Recompute(ctx, uuid.MustParse(crs[1])))
	assert.True(t, h.rwHasBadge(crs[1], "champion_section"), "the CR too")
	require.NoError(t, h.app.Growth.Recompute(ctx, uuid.MustParse(crs[0])))
	assert.False(t, h.rwHasBadge(crs[0], "champion_section"), "4 classes")
	require.NoError(t, h.app.Growth.Recompute(ctx, uuid.MustParse(crs[2])))
	assert.False(t, h.rwHasBadge(crs[2], "champion_section"), "24 verified members")
	assert.False(t, h.gwBadges(tara.Tok).has("champion_section"))
	h.sql(`DELETE FROM class_group_members WHERE group_id = $1 AND role = 'member' AND user_id <> $2`, champ, sara.ID)
	assert.True(t, h.gwBadges(sara.Tok).has("champion_section"), "earned once, it stays")
}

// rwPeople2 inserts n unverified students.
func (h *harness) rwPeople2(uni string, n int) []string {
	h.t.Helper()
	out := make([]string, n)
	for i := range n {
		out[i] = h.ptUser("Unverified "+rwCode(i+1), uni, nil, "")
	}
	return out
}

func TestGrowthFinishers(t *testing.T) {
	h := newHarness(t)
	ctx := context.Background()
	now := h.Now()
	at := func(d time.Duration) *time.Time { x := now.Add(d); return &x }
	admin := h.gwStudent("admin@test.ac.bd", "Admin One")
	h.sql(`UPDATE users SET role = 'admin' WHERE id = $1`, admin.ID)
	uni := h.universityID("test-uni")
	start, end := now.Add(-time.Hour), now.Add(10*24*time.Hour)
	// One friend at my own university enters the race; no pioneer extra.
	race := map[string]any{"invite": 10, "pioneerFirst": 1, "minOwnCampus": 1, "minOtherCampus": 0}

	// ---- the reward: validation, draft only, the count may only go up while live ----
	assert.Equal(t, "VALIDATION_FAILED", h.do("POST", "/admin/campaigns", admin.Tok, campaignBody(start, end, map[string]any{
		"scoring": race, "finisherRewardEn": "20 TK", "finisherRewardCount": 10001})).code())
	assert.Equal(t, "VALIDATION_FAILED", h.do("POST", "/admin/campaigns", admin.Tok, campaignBody(start, end, map[string]any{
		"scoring": race, "finisherRewardCount": 2})).code(), "a count needs a title")
	f := h.gwAdminCampaign(admin.Tok, "POST", "/admin/campaigns", campaignBody(start, end, map[string]any{
		"scoring": race, "finisherRewardEn": "20 TK", "finisherRewardCount": 5}), http.StatusCreated)
	r := h.do("PATCH", "/admin/campaigns/"+f.ID, admin.Tok, map[string]any{
		"finisherRewardEn": "20 TK mobile recharge", "finisherRewardBn": "২০ টাকা মোবাইল রিচার্জ", "finisherRewardCount": 2})
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	var adm struct {
		FinisherRewardEn    string `json:"finisherRewardEn"`
		FinisherRewardBn    string `json:"finisherRewardBn"`
		FinisherRewardCount int    `json:"finisherRewardCount"`
	}
	r.into(t, &adm)
	assert.Equal(t, 2, adm.FinisherRewardCount, "a draft can lower it")
	h.gwAdminCampaign(admin.Tok, "PATCH", "/admin/campaigns/"+f.ID, map[string]any{"status": "live"}, http.StatusOK)
	// Editable while live too (set back below).
	for _, p := range []map[string]any{{"finisherRewardCount": 1}, {"finisherRewardEn": "30 TK"}, {"finisherRewardBn": "x"}} {
		h.gwAdminCampaign(admin.Tok, "PATCH", "/admin/campaigns/"+f.ID, p, http.StatusOK)
	}
	h.gwAdminCampaign(admin.Tok, "PATCH", "/admin/campaigns/"+f.ID, map[string]any{
		"finisherRewardEn": "20 TK mobile recharge", "finisherRewardBn": "২০ টাকা মোবাইল রিচার্জ"}, http.StatusOK)
	h.gwAdminCampaign(admin.Tok, "PATCH", "/admin/campaigns/"+f.ID, map[string]any{"finisherRewardCount": 2}, http.StatusOK)
	var pub struct {
		FinisherRewardEn    string `json:"finisherRewardEn"`
		FinisherRewardCount int    `json:"finisherRewardCount"`
	}
	h.do("GET", "/campaigns/"+f.ID+"/public", "", nil).into(t, &pub)
	assert.Equal(t, "20 TK mobile recharge", pub.FinisherRewardEn)
	assert.Equal(t, 2, pub.FinisherRewardCount)
	// A draft with the same rules never gets finishers.
	draft := h.gwAdminCampaign(admin.Tok, "POST", "/admin/campaigns", campaignBody(start, end, map[string]any{"scoring": race}), http.StatusCreated)

	// ---- students; badges seeded first so new ones would push ----
	s1 := h.gwStudent("s1@test.ac.bd", "Shafin One")
	s2 := h.gwStudent("s2@test.ac.bd", "Sumi Two")
	s3 := h.gwStudent("s3@test.ac.bd", "Sakib Three")
	s4 := h.gwStudent("s4@test.ac.bd", "Sohel Four")
	h.register(s1.Tok, "fin-1", "android", "en")
	h.register(s2.Tok, "fin-2", "android", "bn")
	h.register(s3.Tok, "fin-3", "android", "en")
	for _, u := range []*gwUser{s1, s2, s3, s4} {
		h.gwBadges(u.Tok)
	}
	h.pushes()
	friend := func(name string) string { return h.ptUser(name, uni, at(-time.Minute), "") }
	h.ptInvite(s1.ID, friend("Shafin Friend A"), now, at(time.Hour), false)
	h.ptInvite(s1.ID, friend("Shafin Friend B"), now, at(time.Hour), false) // 20 points
	h.ptInvite(s2.ID, friend("Sumi Friend"), now, at(time.Hour), false)     // 10 points

	// ---- the sweep hands out places in points order and pushes once ----
	h.gwSweep()
	byToken := map[string][2]string{}
	for _, n := range h.pushes() {
		assert.NotEqual(t, "race_finisher", n.Data["badge"], "no badge push for it: race_finished says it")
		if n.Data["type"] == "race_finished" {
			assert.Equal(t, f.ID, n.Data["campaignId"])
			byToken[n.Token] = [2]string{n.Title, n.Body}
		}
	}
	assert.Equal(t, map[string][2]string{
		"fin-1": {"You're in the prize race!", "You're finisher #1: 20 TK mobile recharge. Add your number to get it."},
		"fin-2": {"তুমি পুরস্কারের দৌড়ে!", "তুমি #2 নম্বর: ২০ টাকা মোবাইল রিচার্জ। পেতে তোমার নম্বর দাও।"},
	}, byToken)
	h.gwSweep()
	for _, n := range h.pushes() {
		assert.NotEqual(t, "race_finished", n.Data["type"], "only once")
	}

	// ---- an invite that qualifies now gives the next place right away ----
	var f3 string
	require.NoError(t, h.app.DB.Pool.QueryRow(ctx, `INSERT INTO users (email, university_id, university_email, verified_at, display_name, created_at)
		VALUES ('sakib.friend@test.ac.bd', $1, 'sakib.friend@test.ac.bd', $2, 'Sakib Friend', $2) RETURNING id`, uni, now.Add(-2*24*time.Hour)).Scan(&f3))
	h.sql(`INSERT INTO referrals (referred_id, referrer_id, source, created_at) VALUES ($1, $2, 'link', $3)`, f3, s3.ID, now)
	for i := range 3 {
		h.sql(`INSERT INTO user_active_days (user_id, day) VALUES ($1, $2)`, f3, now.In(time.FixedZone("Dhaka", 6*3600)).AddDate(0, 0, i-2).Format(time.DateOnly))
	}
	require.NoError(t, h.app.Growth.Qualify(ctx, uuid.MustParse(f3)))
	var s3push []string
	for _, n := range h.pushes() {
		if n.Data["type"] == "race_finished" {
			s3push = append(s3push, n.Token, n.Title, n.Body)
		}
	}
	assert.Equal(t, []string{"fin-3", "You're in the prize race!", "Invite and win"}, s3push, "outside the reward: no reward text")

	// ---- the student's view ----
	d1 := h.rwDetail(s1.Tok, f.ID, "")
	require.NotNil(t, d1.FinisherReward)
	assert.Equal(t, "20 TK mobile recharge", d1.FinisherReward.Title)
	assert.Equal(t, 2, d1.FinisherReward.Count)
	assert.Zero(t, d1.FinisherReward.Left)
	require.NotNil(t, d1.Finisher)
	assert.Equal(t, 1, d1.Finisher.Position)
	assert.True(t, d1.Finisher.InReward)
	assert.False(t, d1.Finisher.Claimed)
	assert.Equal(t, "২০ টাকা মোবাইল রিচার্জ", h.rwDetail(s1.Tok, f.ID, "?lang=bn").FinisherReward.Title)
	d3 := h.rwDetail(s3.Tok, f.ID, "")
	require.NotNil(t, d3.Finisher)
	assert.Equal(t, 3, d3.Finisher.Position)
	assert.False(t, d3.Finisher.InReward)
	assert.Nil(t, h.rwDetail(s4.Tok, f.ID, "").Finisher)
	assert.True(t, h.gwBadges(s1.Tok).has("race_finisher"))
	assert.False(t, h.gwBadges(s4.Tok).has("race_finisher"))
	var n int
	require.NoError(t, h.app.DB.Pool.QueryRow(ctx, `SELECT count(*) FROM campaign_finishers WHERE campaign_id = $1`, draft.ID).Scan(&n))
	assert.Zero(t, n, "a draft has no finishers")

	// ---- claiming the reward ----
	claim := func(u *gwUser, phone string) *response {
		return h.do("POST", "/campaigns/"+f.ID+"/finisher-claim", u.Tok, map[string]string{"phone": phone})
	}
	for _, c := range []struct {
		u      *gwUser
		phone  string
		code   string
		status int
	}{
		{s4, "01712345678", "NOT_A_FINISHER", http.StatusForbidden},
		{s3, "01712345678", "NO_REWARD", http.StatusUnprocessableEntity},
		{s1, "12345", "INVALID_PHONE", http.StatusBadRequest},
		{s1, "01212345678", "INVALID_PHONE", http.StatusBadRequest},
		{s1, "", "INVALID_PHONE", http.StatusBadRequest},
	} {
		res := claim(c.u, c.phone)
		assert.Equal(t, c.code, res.code(), c.phone)
		assert.Equal(t, c.status, res.Status, c.phone)
	}
	assert.Equal(t, http.StatusNoContent, claim(s1, "+880 1712-345678").Status)
	again := claim(s1, "01712345678")
	assert.Equal(t, "ALREADY_CLAIMED", again.code())
	assert.Equal(t, http.StatusConflict, again.Status)
	assert.Equal(t, http.StatusNoContent, claim(s2, "০১৮১২৩৪৫৬৭৮").Status, "Bangla digits")
	assert.True(t, h.rwDetail(s1.Tok, f.ID, "").Finisher.Claimed)

	// ---- the team: the list, mark sent ----
	finishers := func() []rwFinisher {
		res := h.do("GET", "/admin/campaigns/"+f.ID+"/finishers", admin.Tok, nil)
		require.Equal(t, http.StatusOK, res.Status, res.Raw)
		var out []rwFinisher
		res.into(t, &out)
		return out
	}
	fl := finishers()
	require.Len(t, fl, 3)
	assert.Equal(t, []int{1, 2, 3}, []int{fl[0].Position, fl[1].Position, fl[2].Position})
	assert.Equal(t, []string{s1.ID, s2.ID, s3.ID}, []string{fl[0].User.ID, fl[1].User.ID, fl[2].User.ID})
	assert.Equal(t, []bool{true, true, false}, []bool{fl[0].InReward, fl[1].InReward, fl[2].InReward})
	require.NotNil(t, fl[0].Phone)
	assert.Equal(t, "01712345678", *fl[0].Phone, "+880 is stored as 01…")
	assert.Equal(t, "01812345678", *fl[1].Phone)
	assert.Nil(t, fl[2].Phone)
	assert.NotNil(t, fl[0].ClaimedAt)
	assert.Nil(t, fl[0].SentAt)
	assert.Equal(t, "s1@test.ac.bd", fl[0].User.Email)
	assert.Equal(t, "Test University", fl[0].User.University)
	assert.NotEmpty(t, fl[0].FinishedAt)
	assert.Equal(t, http.StatusNoContent, h.do("POST", "/admin/campaigns/"+f.ID+"/finishers/"+s1.ID+"/sent", admin.Tok, nil).Status)
	assert.Equal(t, "FINISHER_NOT_FOUND", h.do("POST", "/admin/campaigns/"+f.ID+"/finishers/"+s4.ID+"/sent", admin.Tok, nil).code())
	assert.Equal(t, http.StatusForbidden, h.do("GET", "/admin/campaigns/"+f.ID+"/finishers", s1.Tok, nil).Status)
	assert.True(t, h.rwDetail(s1.Tok, f.ID, "").Finisher.Sent)
	assert.NotNil(t, finishers()[0].SentAt)
	require.NoError(t, h.app.DB.Pool.QueryRow(ctx, `SELECT count(*) FROM audit_log WHERE action = 'campaign.finisher_sent'`).Scan(&n))
	assert.Equal(t, 1, n)

	// ---- the count goes up while live: the third place is now rewarded ----
	h.gwAdminCampaign(admin.Tok, "PATCH", "/admin/campaigns/"+f.ID, map[string]any{"finisherRewardCount": 3}, http.StatusOK)
	d3 = h.rwDetail(s3.Tok, f.ID, "")
	assert.True(t, d3.Finisher.InReward)
	assert.Zero(t, d3.FinisherReward.Left)
	assert.Equal(t, http.StatusNoContent, claim(s3, "8801912345678").Status)

	// ---- disqualifying removes the place; others keep theirs; places aren't reused ----
	require.Equal(t, http.StatusNoContent, h.do("POST", "/admin/campaigns/"+f.ID+"/participants/"+s2.ID+"/disqualify", admin.Tok, map[string]string{"reason": "fake"}).Status)
	assert.Nil(t, h.rwDetail(s2.Tok, f.ID, "").Finisher)
	s5 := h.gwStudent("s5@test.ac.bd", "Samira Five")
	h.ptInvite(s5.ID, friend("Samira Friend"), now, at(time.Hour), false)
	h.gwSweep()
	fl = finishers()
	require.Len(t, fl, 3, "Sumi isn't added back")
	assert.Equal(t, []int{1, 3, 4}, []int{fl[0].Position, fl[1].Position, fl[2].Position})
	assert.Equal(t, s5.ID, fl[2].User.ID)

	// ---- phones go 90 days after sending ----
	h.sql(`UPDATE campaign_finishers SET sent_at = $2 WHERE user_id = $1`, s1.ID, now.Add(-91*24*time.Hour))
	h.gwSweep()
	fl = finishers()
	assert.Nil(t, fl[0].Phone)
	require.NotNil(t, fl[1].Phone, "not sent yet: kept")

	// ---- after the end, nobody new finishes ----
	h.advance(11 * 24 * time.Hour)
	s6 := h.gwStudent("s6@test.ac.bd", "Shuvo Six")
	h.ptInvite(s6.ID, friend("Shuvo Friend"), now, at(time.Hour), false)
	h.gwSweep()
	require.NoError(t, h.app.DB.Pool.QueryRow(ctx, `SELECT count(*) FROM campaign_finishers WHERE user_id = $1`, s6.ID).Scan(&n))
	assert.Zero(t, n)
}

func TestGrowthAmbassador(t *testing.T) {
	h := newHarness(t)
	ctx := context.Background()
	now := h.Now()
	admin := h.gwStudent("admin@test.ac.bd", "Admin One")
	h.sql(`UPDATE users SET role = 'admin' WHERE id = $1`, admin.ID)
	uni := h.universityID("test-uni")
	h.sql(`INSERT INTO universities (slug, name) VALUES ('far-uni', 'Far University')`)
	far := h.universityID("far-uni")
	x := h.gwStudent("xenia@test.ac.bd", "Xenia First")
	y := h.gwStudent("yasin@test.ac.bd", "Yasin Second")
	z := h.gwStudent("zara@test.ac.bd", "Zara Third")
	w := h.gwStudent("wahid@test.ac.bd", "Wahid Team")
	h.sql(`UPDATE users SET role = 'moderator' WHERE id = $1`, w.ID)
	h.register(y.Tok, "amb-y", "android", "en")
	for _, u := range []*gwUser{x, y, z} {
		h.gwBadges(u.Tok)
	}
	h.pushes()
	friends := func(referrer *gwUser, prefix, at string, n int, from time.Duration) {
		for i := range n {
			q := now.Add(from + time.Duration(i)*time.Minute)
			h.ptInvite(referrer.ID, h.ptUser(prefix+" "+rwCode(i+1), at, &q, ""), now, &q, false)
		}
	}
	growth := func(id string) *struct {
		ID      string `json:"id"`
		Name    string `json:"name"`
		Email   string `json:"email"`
		Invites int    `json:"invites"`
	} {
		res := h.do("GET", "/admin/universities/"+id+"/growth", admin.Tok, nil)
		require.Equal(t, http.StatusOK, res.Status, res.Raw)
		var out struct {
			Ambassador *struct {
				ID      string `json:"id"`
				Name    string `json:"name"`
				Email   string `json:"email"`
				Invites int    `json:"invites"`
			} `json:"ambassador"`
		}
		res.into(t, &out)
		return out.Ambassador
	}

	// ---- at least 5 friends from the same university ----
	friends(x, "Xenia friend", uni, 4, time.Hour)
	friends(x, "Xenia far friend", far, 3, time.Hour) // other universities don't count
	friends(w, "Team friend", uni, 8, 0)              // the team doesn't take part
	assert.False(t, h.gwBadges(x.Tok).has("ambassador"), "4 from the same university")
	assert.Nil(t, growth(uni))
	friends(x, "Xenia fifth", uni, 1, 2*time.Hour)
	assert.True(t, h.gwBadges(x.Tok).has("ambassador"), "5")
	a := growth(uni)
	require.NotNil(t, a)
	assert.Equal(t, x.ID, a.ID)
	assert.Equal(t, "Xenia First", a.Name)
	assert.Equal(t, "xenia@test.ac.bd", a.Email)
	assert.Equal(t, 5, a.Invites)
	assert.Nil(t, growth(far))
	assert.Equal(t, "UNIVERSITY_NOT_FOUND", h.do("GET", "/admin/universities/00000000-0000-0000-0000-0000000000aa/growth", admin.Tok, nil).code())
	assert.Equal(t, http.StatusForbidden, h.do("GET", "/admin/universities/"+uni+"/growth", x.Tok, nil).Status)

	// ---- a new leader takes it; the sweep moves it, with one push ----
	friends(y, "Yasin friend", uni, 6, 3*time.Hour)
	friends(z, "Zara friend", uni, 6, 4*time.Hour) // also 6, but reached later
	// Neither opened the app lately: the sweep still moves the badge (it
	// recomputes whoever holds it and each university's leader).
	h.sql(`DELETE FROM user_active_days WHERE user_id = ANY($1::uuid[])`, []string{x.ID, y.ID})
	h.gwSweep()
	assert.True(t, h.rwHasBadge(y.ID, "ambassador"))
	assert.False(t, h.rwHasBadge(x.ID, "ambassador"), "moved like a role")
	assert.False(t, h.rwHasBadge(z.ID, "ambassador"), "a tie goes to who reached it first")
	assert.False(t, h.rwHasBadge(w.ID, "ambassador"))
	assert.Equal(t, y.ID, growth(uni).ID)
	pushed := 0
	for _, n := range h.pushes() {
		if n.Data["type"] == "badge_earned" && n.Data["badge"] == "ambassador" {
			assert.Equal(t, "amb-y", n.Token)
			assert.Equal(t, "New badge: Campus ambassador", n.Title)
			pushed++
		}
	}
	assert.Equal(t, 1, pushed)
	h.gwSweep()
	for _, n := range h.pushes() {
		assert.NotEqual(t, "ambassador", n.Data["badge"], "only once")
	}
	// A disqualified invite no longer counts: Zara leads.
	var one string
	require.NoError(t, h.app.DB.Pool.QueryRow(ctx, `SELECT referred_id::text FROM referrals WHERE referrer_id = $1 LIMIT 1`, y.ID).Scan(&one))
	require.Equal(t, http.StatusNoContent, h.do("POST", "/admin/referrals/"+one+"/disqualify", admin.Tok, map[string]string{"reason": "fake"}).Status)
	h.gwSweep()
	assert.True(t, h.rwHasBadge(z.ID, "ambassador"))
	assert.False(t, h.rwHasBadge(y.ID, "ambassador"))
}

// Invites that qualify at the same moment still get distinct places, 1..n.
func TestGrowthFinishersConcurrent(t *testing.T) {
	h := newHarness(t)
	ctx := context.Background()
	now := h.Now()
	admin := h.gwStudent("admin@test.ac.bd", "Admin One")
	h.sql(`UPDATE users SET role = 'admin' WHERE id = $1`, admin.ID)
	uni := h.universityID("test-uni")
	c := h.gwAdminCampaign(admin.Tok, "POST", "/admin/campaigns", campaignBody(now.Add(-time.Hour), now.Add(10*24*time.Hour), map[string]any{
		"scoring": map[string]any{"minOwnCampus": 1, "minOtherCampus": 0}, "finisherRewardEn": "20 TK", "finisherRewardCount": 3}), http.StatusCreated)
	h.gwAdminCampaign(admin.Tok, "PATCH", "/admin/campaigns/"+c.ID, map[string]any{"status": "live"}, http.StatusOK)
	const n = 8
	friends := make([]uuid.UUID, n)
	for i := range n {
		referrer := h.ptUser("Racer "+rwCode(i+1), uni, &now, "")
		email := strings.ToLower("racer.friend." + rwCode(i+1) + "@test.ac.bd")
		var f string
		require.NoError(t, h.app.DB.Pool.QueryRow(ctx, `INSERT INTO users (email, university_id, university_email, verified_at, display_name, created_at)
			VALUES ($1, $2, $1, $3, 'Racer friend', $3) RETURNING id`, email, uni, now.Add(-2*24*time.Hour)).Scan(&f))
		h.sql(`INSERT INTO referrals (referred_id, referrer_id, source, created_at) VALUES ($1, $2, 'link', $3)`, f, referrer, now)
		for d := range 3 {
			h.sql(`INSERT INTO user_active_days (user_id, day) VALUES ($1, $2)`, f, now.In(time.FixedZone("Dhaka", 6*3600)).AddDate(0, 0, d-2).Format(time.DateOnly))
		}
		friends[i] = uuid.MustParse(f)
	}
	errs := make(chan error, n)
	for _, f := range friends {
		go func() { errs <- h.app.Growth.Qualify(ctx, f) }()
	}
	for range n {
		require.NoError(t, <-errs)
	}
	var positions []int
	rows, err := h.app.DB.Pool.Query(ctx, `SELECT position FROM campaign_finishers WHERE campaign_id = $1 ORDER BY position`, c.ID)
	require.NoError(t, err)
	for rows.Next() {
		var p int
		require.NoError(t, rows.Scan(&p))
		positions = append(positions, p)
	}
	rows.Close()
	assert.Equal(t, []int{1, 2, 3, 4, 5, 6, 7, 8}, positions)
}
