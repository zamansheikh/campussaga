package app

import (
	"context"
	"net/http"
	"strings"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

type ptMission struct {
	Key    string `json:"key"`
	Points int    `json:"points"`
	Per    string `json:"per"`
	Count  int    `json:"count"`
	Max    *int   `json:"max"`
	Earned int    `json:"earned"`
}

type ptDetail struct {
	ID            string         `json:"id"`
	MyScore       int            `json:"myScore"`
	MyRank        *int           `json:"myRank"`
	MyOwnCampus   int            `json:"myOwnCampus"`
	MyOtherCampus int            `json:"myOtherCampus"`
	Eligible      bool           `json:"eligible"`
	Scoring       map[string]int `json:"scoring"`
	Missions      []ptMission    `json:"missions"`
	Section       *struct {
		GroupID string `json:"groupId"`
		Name    string `json:"name"`
		Slots   int    `json:"slots"`
		Members int    `json:"members"`
	} `json:"section"`
}

type ptStanding struct {
	Rank *int `json:"rank"`
	User struct {
		ID string `json:"id"`
	} `json:"user"`
	Score   int            `json:"score"`
	Points  map[string]int `json:"points"`
	Invites []struct {
		Referred struct {
			ID string `json:"id"`
		} `json:"referred"`
		OtherCampus bool `json:"otherCampus"`
		Pioneer     bool `json:"pioneer"`
		InSection   bool `json:"inSection"`
	} `json:"invites"`
	Flags []string `json:"flags"`
}

var defaultScoring = map[string]int{
	"invite": 10, "otherCampus": 5, "pioneer": 5, "friendSection": 3, "joinSection": 2, "bloodDonor": 3,
	"busShare": 2, "busShareDays": 10, "sectionSetup": 15, "sectionSetupMax": 2, "pioneerFirst": 20, "minOwnCampus": 3, "minOtherCampus": 2,
}

// ptUser inserts a student at a university; verifiedAt nil: unverified.
func (h *harness) ptUser(name, uni string, verifiedAt *time.Time, via string) string {
	h.t.Helper()
	var viaArg *string
	if via != "" {
		viaArg = &via
	}
	var id string
	email := strings.ToLower(strings.ReplaceAll(name, " ", ".")) + "@points.test"
	require.NoError(h.t, h.app.DB.Pool.QueryRow(context.Background(), `INSERT INTO users (email, university_id, verified_at, verified_via, display_name, created_at)
		VALUES ($1, $2, $3, $4, $5, $6) RETURNING id`, email, uni, verifiedAt, viaArg, name, h.Now().Add(-40*24*time.Hour)).Scan(&id))
	return id
}

// ptInvite records an invite of friend by referrer.
func (h *harness) ptInvite(referrer, friend string, created time.Time, qualified *time.Time, sameDevice bool) {
	h.t.Helper()
	h.sql(`INSERT INTO referrals (referred_id, referrer_id, source, created_at, qualified_at, same_device) VALUES ($1, $2, 'link', $3, $4, $5)`,
		friend, referrer, created, qualified, sameDevice)
}

// ptGroup makes a class group with a CR, slots routine classes and members.
func (h *harness) ptGroup(uni, code, section, cr string, created time.Time, slots int, members ...string) string {
	h.t.Helper()
	var id string
	require.NoError(h.t, h.app.DB.Pool.QueryRow(context.Background(), `INSERT INTO class_groups (university_id, department, batch, section, semester, join_code, created_by, created_at)
		VALUES ($1, 'CSE', '40', $2, 'Fall 2026', $3, $4, $5) RETURNING id`, uni, section, code, cr, created).Scan(&id))
	h.sql(`INSERT INTO class_group_members (group_id, user_id, role) VALUES ($1, $2, 'cr')`, id, cr)
	for _, m := range members {
		h.sql(`INSERT INTO class_group_members (group_id, user_id, role) VALUES ($1, $2, 'member')`, id, m)
	}
	for i := range slots {
		h.sql(`INSERT INTO routine_slots (group_id, course_code, weekday, starts_min, ends_min) VALUES ($1, $2, $3, 540, 620)`, id, "CSE "+string(rune('1'+i)), i%5+1)
	}
	return id
}

func (h *harness) ptDetail(tok, id string) ptDetail {
	h.t.Helper()
	r := h.do("GET", "/campaigns/"+id, tok, nil)
	require.Equal(h.t, http.StatusOK, r.Status, r.Raw)
	var d ptDetail
	r.into(h.t, &d)
	return d
}

func TestGrowthPoints(t *testing.T) {
	h := newHarness(t)
	now := h.Now() // 2026-10-27 09:00 UTC, 15:00 in Dhaka
	at := func(d time.Duration) *time.Time { x := now.Add(d); return &x }
	admin := h.gwStudent("admin@test.ac.bd", "Admin One")
	h.sql(`UPDATE users SET role = 'admin' WHERE id = $1`, admin.ID)
	a := h.gwStudent("amina@test.ac.bd", "Amina Inviter")
	h.sql(`UPDATE users SET created_at = $2 WHERE id = $1`, a.ID, now.Add(-30*24*time.Hour)) // no new_account flag
	b := h.gwStudent("bashir@test.ac.bd", "Bashir Bus")
	c := h.gwStudent("chandni@test.ac.bd", "Chandni CR")
	e := h.gwStudent("emon@test.ac.bd", "Emon CR")
	uni := h.universityID("test-uni")
	h.sql(`INSERT INTO universities (slug, name) VALUES ('far-uni', 'Far University')`)
	far := h.universityID("far-uni")

	// ---- point values: defaults, ranges, merged edits, draft only ----
	start, end := now.Add(-time.Hour), now.Add(10*24*time.Hour)
	body := campaignBody(start, end, nil)
	delete(body, "scoring")
	cp := h.do("POST", "/admin/campaigns", admin.Tok, body)
	require.Equal(t, http.StatusCreated, cp.Status, cp.Raw)
	var created struct {
		ID      string         `json:"id"`
		Scoring map[string]int `json:"scoring"`
	}
	cp.into(t, &created)
	assert.Equal(t, defaultScoring, created.Scoring, "no scoring: the defaults")
	id := created.ID
	for _, bad := range []map[string]any{
		{"invite": 101}, {"joinSection": -1}, {"busShareDays": 61}, {"sectionSetupMax": 11}, {"pioneerFirst": 0}, {"pioneerFirst": 1001},
		{"minOtherCampus": -1}, {"minOtherCampus": 21}, {"minOwnCampus": -1}, {"minOwnCampus": 21},
	} {
		r := h.do("POST", "/admin/campaigns", admin.Tok, campaignBody(start, end, map[string]any{"scoring": bad}))
		assert.Equal(t, "INVALID_SCORING", r.code(), "%v", bad)
		assert.Equal(t, http.StatusBadRequest, r.Status)
	}
	assert.Equal(t, "INVALID_SCORING", h.do("PATCH", "/admin/campaigns/"+id, admin.Tok, map[string]any{"scoring": map[string]any{"invite": 500}}).code())
	// No minimums of friends here (0: everyone with points is ranked); the
	// Min, Own and Both campaigns below test them.
	r := h.do("PATCH", "/admin/campaigns/"+id, admin.Tok, map[string]any{"scoring": map[string]any{
		"busShareDays": 2, "pioneerFirst": 3, "minOwnCampus": 0, "minOtherCampus": 0}})
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	r.into(t, &created)
	want := map[string]int{}
	for k, v := range defaultScoring {
		want[k] = v
	}
	want["busShareDays"], want["pioneerFirst"], want["minOwnCampus"], want["minOtherCampus"] = 2, 3, 0, 0
	assert.Equal(t, want, created.Scoring, "merged over the stored values")
	require.Equal(t, http.StatusOK, h.do("PATCH", "/admin/campaigns/"+id, admin.Tok, map[string]any{"status": "live"}).Status)
	assert.Equal(t, "CAMPAIGN_LOCKED", h.do("PATCH", "/admin/campaigns/"+id, admin.Tok, map[string]any{"scoring": map[string]any{"invite": 20}}).code(),
		"point values can't change once live")

	// The Min campaign: the same values with only the other-universities
	// minimum (2, set while a draft; locked once live) and none for my own.
	minC := h.gwAdminCampaign(admin.Tok, "POST", "/admin/campaigns", campaignBody(start, end, map[string]any{
		"titleEn": "Min", "scoring": map[string]any{"busShareDays": 2, "pioneerFirst": 3, "minOwnCampus": 0, "minOtherCampus": 5}}), http.StatusCreated).ID
	r = h.do("PATCH", "/admin/campaigns/"+minC, admin.Tok, map[string]any{"scoring": map[string]any{"minOtherCampus": 2}})
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	r.into(t, &created)
	assert.Equal(t, 2, created.Scoring["minOtherCampus"])
	h.gwAdminCampaign(admin.Tok, "PATCH", "/admin/campaigns/"+minC, map[string]any{"status": "live"}, http.StatusOK)
	assert.Equal(t, "CAMPAIGN_LOCKED", h.do("PATCH", "/admin/campaigns/"+minC, admin.Tok, map[string]any{"scoring": map[string]any{"minOtherCampus": 1}}).code())

	// A second campaign with joining a section and bus shares turned off.
	off := h.gwAdminCampaign(admin.Tok, "POST", "/admin/campaigns", campaignBody(start, end, map[string]any{
		"titleEn": "Sections off", "scoring": map[string]any{"joinSection": 0, "busShare": 0}}), http.StatusCreated)
	h.gwAdminCampaign(admin.Tok, "PATCH", "/admin/campaigns/"+off.ID, map[string]any{"status": "live"}, http.StatusOK)

	// ---- invites with bonuses (Amina) ----
	// pioneerFirst is 3: three Test University students were verified long ago.
	for _, n := range []string{"Old One", "Old Two", "Old Three"} {
		h.ptUser(n, uni, at(-30*24*time.Hour), "")
	}
	f1 := h.ptUser("Friend One", uni, at(-time.Minute), "vouch") // same university, not a pioneer; Amina vouched
	h.sql(`INSERT INTO vouches (user_id, voucher_id, created_at) VALUES ($1, $2, $3)`, f1, a.ID, now)
	f2 := h.ptUser("Friend Two", far, at(-30*24*time.Hour), "cr") // first at Far University; verified by Chandni, not Amina
	h.sql(`INSERT INTO verification_events (user_id, university_id, method, actor_id, created_at) VALUES ($1, $2, 'cr', $3, $4)`, f2, far, c.ID, now)
	for _, n := range []string{"Far One", "Far Two", "Far Three"} {
		h.ptUser(n, far, at(-20*24*time.Hour), "")
	}
	f3 := h.ptUser("Friend Three", far, at(-time.Minute), "") // Far University, fifth there: not a pioneer
	f4 := h.ptUser("Friend Four", far, at(-time.Minute), "")  // same phone
	f5 := h.ptUser("Friend Five", far, at(-time.Minute), "")  // qualified after settling
	h.ptInvite(a.ID, f1, now, at(time.Hour), false)
	h.ptInvite(a.ID, f2, now, at(time.Hour), false)
	h.ptInvite(a.ID, f3, now, at(2*time.Hour), false)
	h.ptInvite(a.ID, f4, now, at(time.Hour), true)
	h.ptInvite(a.ID, f5, now, at(30*24*time.Hour), false)

	// ---- sections (Chandni: three complete, two count; Emon: none yet) ----
	var five []string
	for _, n := range []string{"Member A", "Member B", "Member C", "Member D", "Member E"} {
		five = append(five, h.ptUser(n, uni, at(-10*24*time.Hour), ""))
	}
	g1 := h.ptGroup(uni, "AAAAAA", "A", c.ID, now.Add(-3*time.Hour), 5, append([]string{a.ID}, five...)...) // Amina joins a section too
	h.ptGroup(uni, "BBBBBB", "B", c.ID, now.Add(-2*time.Hour), 6, five...)
	h.ptGroup(uni, "CCCCCC", "C", c.ID, now.Add(-time.Hour), 5, five...)
	unverified := h.ptUser("Not Verified", uni, nil, "")
	g4 := h.ptGroup(uni, "DDDDDD", "D", e.ID, now.Add(-2*time.Hour), 5, append([]string{unverified}, five[:4]...)...) // 4 verified members
	h.ptGroup(uni, "EEEEEE", "E", e.ID, now.Add(-time.Hour), 3, append([]string{f2}, five...)...)                     // 3 classes; Friend Two joins
	_ = g1

	// ---- a blood donor ----
	h.sql(`INSERT INTO blood_donors (user_id, blood_group) VALUES ($1, 'O+')`, a.ID)

	// ---- bus shares (Bashir): a day counts when another student watched a run of 10+ minutes not off the route ----
	var route string
	require.NoError(t, h.app.DB.Pool.QueryRow(context.Background(), `INSERT INTO bus_routes (university_id, name) VALUES ($1, 'Mirpur') RETURNING id`, uni).Scan(&route))
	departs := 0
	share := func(startAt time.Duration, minutes int, endReason string, viewer string) {
		departs++
		s := now.Add(startAt)
		day := s.In(time.FixedZone("Dhaka", 6*3600)).Format("2006-01-02")
		h.sql(`INSERT INTO bus_live_sessions (route_id, user_id, direction, service_date, departs, started_at, last_at, ended_at, end_reason)
			VALUES ($1, $2, 'to_campus', $3, $4, $5, $6, $6, $7)`, route, b.ID, day, departs, s, s.Add(time.Duration(minutes)*time.Minute), endReason)
		h.sql(`INSERT INTO bus_live_views (route_id, direction, service_date, departs, user_id, first_at) VALUES ($1, 'to_campus', $2, $3, $4, $5)`,
			route, day, departs, viewer, s)
	}
	share(-2*time.Hour, 30, "arrived", c.ID)   // before the start
	share(time.Hour, 30, "arrived", c.ID)      // Oct 27: counts
	share(3*time.Hour, 30, "arrived", e.ID)    // Oct 27 again: the same day
	share(24*time.Hour, 5, "arrived", c.ID)    // Oct 28: too short
	share(48*time.Hour, 30, "off_route", c.ID) // Oct 29: off the route
	share(72*time.Hour, 30, "arrived", b.ID)   // Oct 30: only Bashir watched
	share(96*time.Hour, 30, "stopped", c.ID)   // Oct 31: counts
	share(120*time.Hour, 30, "arrived", c.ID)  // Nov 1: over busShareDays (2)

	// ---- scores ----
	da := h.ptDetail(a.Tok, id)
	assert.Equal(t, 3*10+2*5+1*5+1*3+2+3, da.MyScore, "3 invites, 2 from another campus, 1 pioneer, 1 in a section; joined a section; donor")
	require.NotNil(t, da.MyRank)
	assert.Equal(t, 1, *da.MyRank)
	assert.Equal(t, want, da.Scoring)
	two := 2
	assert.Equal(t, []ptMission{
		{"invite", 10, "friend", 3, nil, 30},
		{"otherCampus", 5, "friend", 2, nil, 10},
		{"pioneer", 5, "friend", 1, nil, 5},
		{"friendSection", 3, "friend", 1, nil, 3},
		{"joinSection", 2, "once", 1, ptInt(1), 2},
		{"bloodDonor", 3, "once", 1, ptInt(1), 3},
		{"busShare", 2, "day", 0, &two, 0},
		{"sectionSetup", 15, "section", 0, &two, 0},
	}, da.Missions)
	assert.Nil(t, da.Section, "not a CR")

	dc := h.ptDetail(c.Tok, id)
	assert.Equal(t, 2*15+2, dc.MyScore, "two sections count (the most), and she's in one")
	require.NotNil(t, dc.MyRank)
	assert.Equal(t, 2, *dc.MyRank, "no minimum here: ranked without friends from other universities")
	assert.True(t, dc.Eligible)
	assert.Zero(t, dc.MyOtherCampus)
	assert.Nil(t, dc.Section, "already at the most sections that count")

	db := h.ptDetail(b.Tok, id)
	assert.Equal(t, 2*2, db.MyScore, "Oct 27 and Oct 31; Nov 1 is over the limit")
	assert.Equal(t, 3, *db.MyRank)
	busMission := func(d ptDetail) ptMission {
		for _, m := range d.Missions {
			if m.Key == "busShare" {
				return m
			}
		}
		return ptMission{}
	}
	assert.Equal(t, ptMission{"busShare", 2, "day", 2, &two, 4}, busMission(db))
	// Without the low limit: exactly the three good days (not the short
	// run, the one off the route, the one only Bashir watched, or the one
	// before the start).
	bus := h.gwAdminCampaign(admin.Tok, "POST", "/admin/campaigns", campaignBody(start, end, map[string]any{
		"titleEn": "Bus days", "scoring": map[string]any{"busShareDays": 10}}), http.StatusCreated)
	h.gwAdminCampaign(admin.Tok, "PATCH", "/admin/campaigns/"+bus.ID, map[string]any{"status": "live"}, http.StatusOK)
	ten := 10
	assert.Equal(t, ptMission{"busShare", 2, "day", 3, &ten, 6}, busMission(h.ptDetail(b.Tok, bus.ID)))

	de := h.ptDetail(e.Tok, id)
	assert.Equal(t, 2, de.MyScore, "only joining (as CR) counts; neither section is complete")
	require.NotNil(t, de.Section)
	assert.Equal(t, g4, de.Section.GroupID, "the one closest: 5 classes, 4 verified members")
	assert.Equal(t, "CSE 40 · D", de.Section.Name)
	assert.Equal(t, 5, de.Section.Slots)
	assert.Equal(t, 4, de.Section.Members, "the unverified member doesn't count")

	// One more verified member completes it: now it counts, and there's no section left to show.
	h.sql(`INSERT INTO class_group_members (group_id, user_id, role) VALUES ($1, $2, 'member')`, g4, five[4])
	de = h.ptDetail(e.Tok, id)
	assert.Equal(t, 15+2, de.MyScore)
	require.NotNil(t, de.Section)
	assert.Equal(t, 3, de.Section.Slots, "the 3-class section is left")
	assert.Equal(t, 6, de.Section.Members)

	// ---- leaderboard: points; the unverified student isn't ranked ----
	board := h.gwBoard(a.Tok, id, "")
	require.GreaterOrEqual(t, len(board.Rows), 4)
	assert.Equal(t, []string{"Amina Inviter", "Chandni CR", "Emon CR", "Bashir Bus"}, []string{board.Rows[0].Name, board.Rows[1].Name, board.Rows[2].Name, board.Rows[3].Name})
	assert.Equal(t, 53, board.Rows[0].Score)
	for _, row := range board.Rows {
		assert.NotEqual(t, "Not Verified", row.Name)
		assert.Positive(t, row.Score)
	}
	// Ties go to who reached the points first: the five members all have 2
	// points from joining; Friend Two joined last.
	var twos []string
	for _, row := range board.Rows {
		if row.Score == 2 {
			twos = append(twos, row.Name)
		}
	}
	require.NotEmpty(t, twos)
	assert.Equal(t, "Friend Two", twos[len(twos)-1])

	// ---- admin standings: the breakdown, the invite bonuses, the flag ----
	sr := h.do("GET", "/admin/campaigns/"+id+"/standings", admin.Tok, nil)
	require.Equal(t, http.StatusOK, sr.Status, sr.Raw)
	var st []ptStanding
	sr.into(t, &st)
	byID := map[string]ptStanding{}
	for _, s := range st {
		byID[s.User.ID] = s
	}
	sa := byID[a.ID]
	assert.Equal(t, map[string]int{"invite": 30, "otherCampus": 10, "pioneer": 5, "friendSection": 3, "joinSection": 2, "bloodDonor": 3, "busShare": 0, "sectionSetup": 0}, sa.Points)
	assert.ElementsMatch(t, []string{"self_vouched", "same_device"}, sa.Flags)
	inv := map[string][3]bool{}
	for _, i := range sa.Invites {
		inv[i.Referred.ID] = [3]bool{i.OtherCampus, i.Pioneer, i.InSection}
	}
	assert.Equal(t, [3]bool{false, false, false}, inv[f1])
	assert.Equal(t, [3]bool{true, true, true}, inv[f2])
	assert.Equal(t, [3]bool{true, false, false}, inv[f3])
	assert.Len(t, sa.Invites, 5, "all invites inside the dates, counted or not")
	assert.Equal(t, 30, byID[c.ID].Points["sectionSetup"])
	assert.Equal(t, 4, byID[b.ID].Points["busShare"])
	var refs struct {
		Total int `json:"total"`
		Items []struct {
			Referred struct{ ID string } `json:"referred"`
			Flags    []string            `json:"flags"`
		} `json:"items"`
	}
	h.do("GET", "/admin/referrals?flag=self_vouched", admin.Tok, nil).into(t, &refs)
	require.Equal(t, 1, refs.Total)
	assert.Equal(t, f1, refs.Items[0].Referred.ID)
	assert.Contains(t, refs.Items[0].Flags, "self_vouched")
	// A revoked verification by the inviter doesn't flag.
	h.sql(`UPDATE vouches SET void_at = $2 WHERE user_id = $1`, f1, now)
	h.do("GET", "/admin/referrals?flag=self_vouched", admin.Tok, nil).into(t, &refs)
	assert.Zero(t, refs.Total)
	h.sql(`INSERT INTO verification_events (user_id, university_id, method, actor_id, created_at, revoked_at) VALUES ($1, $2, 'cr', $3, $4, $4)`, f3, far, a.ID, now)
	h.sql(`UPDATE users SET verified_via = 'cr' WHERE id = $1`, f3)
	h.do("GET", "/admin/referrals?flag=self_vouched", admin.Tok, nil).into(t, &refs)
	assert.Zero(t, refs.Total)
	h.sql(`INSERT INTO verification_events (user_id, university_id, method, actor_id, created_at) VALUES ($1, $2, 'cr', $3, $4)`, f3, far, a.ID, now)
	h.do("GET", "/admin/referrals?flag=self_vouched", admin.Tok, nil).into(t, &refs)
	assert.Equal(t, 1, refs.Total, "the inviter as CR verified them")

	// ---- the campaign with joining and bus shares off ----
	do := h.ptDetail(e.Tok, off.ID)
	assert.Equal(t, 15, do.MyScore, "the complete section only")
	var keys []string
	for _, m := range do.Missions {
		keys = append(keys, m.Key)
	}
	assert.Equal(t, []string{"invite", "otherCampus", "pioneer", "friendSection", "bloodDonor", "sectionSetup"}, keys)
	dbo := h.ptDetail(b.Tok, off.ID)
	assert.Zero(t, dbo.MyScore)
	assert.Nil(t, dbo.MyRank)
	for _, row := range h.gwBoard(a.Tok, off.ID, "").Rows {
		assert.NotEqual(t, "Member A", row.Name, "joining alone earns nothing here")
	}

	// ---- scoring on the list and the public page ----
	assert.Equal(t, want, func() map[string]int {
		var list []ptDetail
		h.do("GET", "/campaigns", a.Tok, nil).into(t, &list)
		for _, x := range list {
			if x.ID == id {
				return x.Scoring
			}
		}
		return nil
	}())
	var pub struct {
		Scoring map[string]int `json:"scoring"`
	}
	h.do("GET", "/campaigns/"+id+"/public", "", nil).into(t, &pub)
	assert.Equal(t, want, pub.Scoring)

	// A disqualified participant loses their points.
	require.Equal(t, http.StatusNoContent, h.do("POST", "/admin/campaigns/"+id+"/participants/"+a.ID+"/disqualify", admin.Tok, map[string]string{"reason": "test"}).Status)
	da = h.ptDetail(a.Tok, id)
	assert.Zero(t, da.MyScore)
	assert.Nil(t, da.MyRank)

	// ---- the minimum of friends from other universities (Min: 2) ----
	g := h.gwStudent("gita@test.ac.bd", "Gita One Away")
	h.ptInvite(g.ID, h.ptUser("Friend Six", far, at(-time.Minute), ""), now, at(time.Hour), false) // one friend at another university
	dm := h.ptDetail(a.Tok, minC)
	assert.Equal(t, 53, dm.MyScore)
	assert.Equal(t, 2, dm.MyOtherCampus)
	assert.Equal(t, 1, dm.MyOwnCampus, "Friend One; no minimum for my own university here")
	assert.True(t, dm.Eligible, "exactly at the minimum")
	require.NotNil(t, dm.MyRank)
	assert.Equal(t, 1, *dm.MyRank)
	dg := h.ptDetail(g.Tok, minC)
	assert.Equal(t, 10+5, dg.MyScore, "points still count below the minimum")
	assert.Equal(t, 1, dg.MyOtherCampus)
	assert.False(t, dg.Eligible)
	assert.Nil(t, dg.MyRank, "not ranked below the minimum")
	assert.Len(t, dg.Missions, 8, "and sees their progress")
	dc = h.ptDetail(c.Tok, minC)
	assert.Equal(t, 32, dc.MyScore)
	assert.Nil(t, dc.MyRank)
	assert.False(t, dc.Eligible)
	var inList ptDetail
	var list []ptDetail
	h.do("GET", "/campaigns", g.Tok, nil).into(t, &list)
	for _, x := range list {
		if x.ID == minC {
			inList = x
		}
	}
	assert.Equal(t, 1, inList.MyOtherCampus)
	assert.False(t, inList.Eligible)
	assert.Nil(t, inList.MyRank)
	// Leaderboards (both scopes) list only the eligible; my row is null when I'm not.
	for _, scope := range []string{"", "?scope=university"} {
		bd := h.gwBoard(c.Tok, minC, scope)
		require.Len(t, bd.Rows, 1, scope)
		assert.Equal(t, "Amina Inviter", bd.Rows[0].Name)
		assert.Equal(t, 1, bd.Rows[0].Rank)
		assert.Nil(t, bd.Me, scope)
	}
	assert.Nil(t, h.gwBoard(g.Tok, minC, "").Me)
	assert.Equal(t, 1, h.gwBoard(a.Tok, minC, "").Me.Rank)
	// Admin standings: the eligible ranked first, then the rest with rank null.
	sr = h.do("GET", "/admin/campaigns/"+minC+"/standings", admin.Tok, nil)
	require.Equal(t, http.StatusOK, sr.Status, sr.Raw)
	type eligStanding struct {
		ptStanding
		Eligible    bool `json:"eligible"`
		OwnCampus   int  `json:"ownCampus"`
		OtherCampus int  `json:"otherCampus"`
	}
	var ms []eligStanding
	sr.into(t, &ms)
	require.Greater(t, len(ms), 3)
	assert.Equal(t, a.ID, ms[0].User.ID)
	require.NotNil(t, ms[0].Rank)
	assert.Equal(t, 1, *ms[0].Rank)
	assert.True(t, ms[0].Eligible)
	assert.Equal(t, 2, ms[0].OtherCampus)
	assert.Equal(t, c.ID, ms[1].User.ID, "then by points: Chandni (32)")
	for _, s := range ms[1:] {
		assert.Nil(t, s.Rank)
		assert.False(t, s.Eligible)
		if s.User.ID == g.ID {
			assert.Equal(t, 1, s.OtherCampus)
			assert.Equal(t, 0, s.OwnCampus)
			assert.Equal(t, 15, s.Score)
		}
	}

	// ---- friends from my own university too (Own: 3 of mine; Both: 3 of mine and 2 of others) ----
	// pioneerFirst 1 keeps the pioneer extra out of these sums.
	ownC := h.gwAdminCampaign(admin.Tok, "POST", "/admin/campaigns", campaignBody(start, end, map[string]any{
		"titleEn": "Own", "scoring": map[string]any{"pioneerFirst": 1, "minOtherCampus": 0}}), http.StatusCreated).ID
	h.gwAdminCampaign(admin.Tok, "PATCH", "/admin/campaigns/"+ownC, map[string]any{"status": "live"}, http.StatusOK)
	bothC := h.gwAdminCampaign(admin.Tok, "POST", "/admin/campaigns", campaignBody(start, end, map[string]any{
		"titleEn": "Both", "scoring": map[string]any{"pioneerFirst": 1, "minOwnCampus": 5}}), http.StatusCreated).ID
	r = h.do("PATCH", "/admin/campaigns/"+bothC, admin.Tok, map[string]any{"scoring": map[string]any{"minOwnCampus": 3}})
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	r.into(t, &created)
	assert.Equal(t, 3, created.Scoring["minOwnCampus"], "set while a draft")
	assert.Equal(t, 2, created.Scoring["minOtherCampus"], "the default")
	h.gwAdminCampaign(admin.Tok, "PATCH", "/admin/campaigns/"+bothC, map[string]any{"status": "live"}, http.StatusOK)
	assert.Equal(t, "CAMPAIGN_LOCKED", h.do("PATCH", "/admin/campaigns/"+bothC, admin.Tok, map[string]any{"scoring": map[string]any{"minOwnCampus": 1}}).code())

	friends := func(inviter, prefix string, own, other int) {
		for i := range own {
			h.ptInvite(inviter, h.ptUser(prefix+" Own "+string(rune('A'+i)), uni, at(-time.Minute), ""), now, at(time.Hour), false)
		}
		for i := range other {
			h.ptInvite(inviter, h.ptUser(prefix+" Far "+string(rune('A'+i)), far, at(-time.Minute), ""), now, at(time.Hour), false)
		}
	}
	joy := h.gwStudent("joy@test.ac.bd", "Joy Short Own")       // 2 mine, 2 others: one short of mine
	kiran := h.gwStudent("kiran@test.ac.bd", "Kiran Short Far") // 3 mine, 1 other: one short of others
	lina := h.gwStudent("lina@test.ac.bd", "Lina In")           // 3 mine, 2 others
	friends(joy.ID, "Joy", 2, 2)
	friends(kiran.ID, "Kiran", 3, 1)
	friends(lina.ID, "Lina", 3, 2)

	// Own only: Lina and Kiran are in; Joy (2 of mine) and Amina (1) aren't.
	dj := h.ptDetail(joy.Tok, ownC)
	assert.Equal(t, 40+2*5, dj.MyScore)
	assert.Equal(t, 2, dj.MyOwnCampus)
	assert.False(t, dj.Eligible)
	assert.Nil(t, dj.MyRank)
	dk := h.ptDetail(kiran.Tok, ownC)
	assert.True(t, dk.Eligible, "exactly 3 of mine; no minimum for others here")
	require.NotNil(t, dk.MyRank)
	assert.Equal(t, 2, *dk.MyRank, "45 points, behind Lina's 60")
	assert.False(t, h.ptDetail(a.Tok, ownC).Eligible)
	var names []string
	for _, row := range h.gwBoard(joy.Tok, ownC, "").Rows {
		names = append(names, row.Name)
	}
	assert.Equal(t, []string{"Lina In", "Kiran Short Far"}, names)

	// Both: only Lina; one short of either part is out.
	for _, x := range []struct {
		u          *gwUser
		own, other int
		in         bool
	}{{joy, 2, 2, false}, {kiran, 3, 1, false}, {lina, 3, 2, true}} {
		d := h.ptDetail(x.u.Tok, bothC)
		assert.Equal(t, x.own, d.MyOwnCampus, x.u.Email)
		assert.Equal(t, x.other, d.MyOtherCampus, x.u.Email)
		assert.Equal(t, x.in, d.Eligible, x.u.Email)
		assert.Equal(t, x.in, d.MyRank != nil, x.u.Email)
		assert.Positive(t, d.MyScore, x.u.Email)
	}
	list = nil
	h.do("GET", "/campaigns", lina.Tok, nil).into(t, &list)
	for _, x := range list {
		if x.ID == bothC {
			assert.Equal(t, 3, x.MyOwnCampus)
			assert.Equal(t, 2, x.MyOtherCampus)
			assert.True(t, x.Eligible)
		}
	}
	bothBoard := h.gwBoard(joy.Tok, bothC, "")
	require.Len(t, bothBoard.Rows, 1)
	assert.Equal(t, "Lina In", bothBoard.Rows[0].Name)
	assert.Nil(t, bothBoard.Me)
	sr = h.do("GET", "/admin/campaigns/"+bothC+"/standings", admin.Tok, nil)
	require.Equal(t, http.StatusOK, sr.Status, sr.Raw)
	var bs []eligStanding
	sr.into(t, &bs)
	require.NotEmpty(t, bs)
	assert.Equal(t, lina.ID, bs[0].User.ID)
	assert.True(t, bs[0].Eligible)
	assert.Equal(t, [2]int{3, 2}, [2]int{bs[0].OwnCampus, bs[0].OtherCampus})
	seen := 0
	for _, s := range bs[1:] {
		assert.Nil(t, s.Rank)
		switch s.User.ID {
		case joy.ID:
			assert.Equal(t, [2]int{2, 2}, [2]int{s.OwnCampus, s.OtherCampus})
			seen++
		case kiran.ID:
			assert.Equal(t, [2]int{3, 1}, [2]int{s.OwnCampus, s.OtherCampus})
			seen++
		}
	}
	assert.Equal(t, 2, seen)

	// ---- announce: a winner must be eligible ----
	h.advance(18 * 24 * time.Hour)
	h.gwRefresh(admin)
	for _, u := range []*gwUser{joy, kiran} {
		assert.Equal(t, "NOT_ELIGIBLE", h.do("POST", "/admin/campaigns/"+bothC+"/announce", admin.Tok,
			map[string]any{"winners": []map[string]any{{"userId": u.ID, "rank": 1}}}).code(), u.Email)
	}
	won := h.do("POST", "/admin/campaigns/"+bothC+"/announce", admin.Tok, map[string]any{"winners": []map[string]any{{"userId": lina.ID, "rank": 1}}})
	assert.Equal(t, http.StatusOK, won.Status, won.Raw)
	for _, picks := range [][]map[string]any{{{"userId": c.ID, "rank": 1}}, {{"userId": a.ID, "rank": 1}, {"userId": g.ID, "rank": 2}}} {
		nr := h.do("POST", "/admin/campaigns/"+minC+"/announce", admin.Tok, map[string]any{"winners": picks})
		assert.Equal(t, "NOT_ELIGIBLE", nr.code())
		assert.Equal(t, http.StatusUnprocessableEntity, nr.Status)
	}
	assert.Equal(t, "CAMPAIGN_WINNERS", h.do("POST", "/admin/campaigns/"+minC+"/announce", admin.Tok,
		map[string]any{"winners": []map[string]any{{"userId": admin.ID, "rank": 1}}}).code(), "not a participant at all")
	ok := h.do("POST", "/admin/campaigns/"+minC+"/announce", admin.Tok, map[string]any{"winners": []map[string]any{{"userId": a.ID, "rank": 1}}})
	assert.Equal(t, http.StatusOK, ok.Status, ok.Raw)
}

func ptInt(n int) *int { return &n }
