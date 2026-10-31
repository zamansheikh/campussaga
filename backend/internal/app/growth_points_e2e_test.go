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
	ID       string         `json:"id"`
	MyScore  int            `json:"myScore"`
	MyRank   *int           `json:"myRank"`
	Scoring  map[string]int `json:"scoring"`
	Missions []ptMission    `json:"missions"`
	Section  *struct {
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
	"busShare": 2, "busShareDays": 10, "sectionSetup": 15, "sectionSetupMax": 2, "pioneerFirst": 20,
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
	} {
		r := h.do("POST", "/admin/campaigns", admin.Tok, campaignBody(start, end, map[string]any{"scoring": bad}))
		assert.Equal(t, "INVALID_SCORING", r.code(), "%v", bad)
		assert.Equal(t, http.StatusBadRequest, r.Status)
	}
	assert.Equal(t, "INVALID_SCORING", h.do("PATCH", "/admin/campaigns/"+id, admin.Tok, map[string]any{"scoring": map[string]any{"invite": 500}}).code())
	r := h.do("PATCH", "/admin/campaigns/"+id, admin.Tok, map[string]any{"scoring": map[string]any{"busShareDays": 2, "pioneerFirst": 3}})
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	r.into(t, &created)
	want := map[string]int{}
	for k, v := range defaultScoring {
		want[k] = v
	}
	want["busShareDays"], want["pioneerFirst"] = 2, 3
	assert.Equal(t, want, created.Scoring, "merged over the stored values")
	require.Equal(t, http.StatusOK, h.do("PATCH", "/admin/campaigns/"+id, admin.Tok, map[string]any{"status": "live"}).Status)
	assert.Equal(t, "CAMPAIGN_LOCKED", h.do("PATCH", "/admin/campaigns/"+id, admin.Tok, map[string]any{"scoring": map[string]any{"invite": 20}}).code(),
		"point values can't change once live")

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
	assert.Equal(t, 2, *dc.MyRank)
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
}

func ptInt(n int) *int { return &n }
