package app

import (
	"net/http"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// Admin tools for Campus social, blood donation and live buses
// (docs/ADMIN.md, "Build 6 features in the admin panel"). The harness clock
// is Tuesday 27 October 2026, 15:00 in Dhaka.

type adminBloodJSON struct {
	ID         string `json:"id"`
	University struct {
		ID   string `json:"id"`
		Name string `json:"name"`
	} `json:"university"`
	BloodGroup   string    `json:"bloodGroup"`
	Units        int       `json:"units"`
	Hospital     string    `json:"hospital"`
	NeededBy     time.Time `json:"neededBy"`
	ContactPhone string    `json:"contactPhone"`
	Status       string    `json:"status"`
	Notified     int       `json:"notified"`
	Responses    int       `json:"responses"`
	Requester    *struct {
		ID    string `json:"id"`
		Name  string `json:"name"`
		Email string `json:"email"`
	} `json:"requester"`
	CreatedAt time.Time  `json:"createdAt"`
	ClosedAt  *time.Time `json:"closedAt"`
}

type adminBloodPage struct {
	Items    []adminBloodJSON `json:"items"`
	Total    int              `json:"total"`
	Page     int              `json:"page"`
	PageSize int              `json:"pageSize"`
}

func TestAdminStatsBuild6(t *testing.T) {
	h := newHarness(t)
	c := newVoiceCast(h)
	h.addUni("other", "Other University")

	// Campus: one item of each kind, a comment and a reaction.
	post := h.postIssue(c.author, postBody("post", "Fresh samosas at the canteen"))
	h.postIssue(c.author, postBody("question", "Where is the physics lab?"))
	h.postIssue(c.author, pollBody("Best canteen day?", "Friday", "Saturday"))
	h.postIssue(c.author, issueBody("Broken water pump in Hall 3"))
	h.comment(c.mate, post.ID, map[string]any{"body": "Yum."})
	r, _ := h.react(c.mate, post.ID, map[string]string{"reaction": "like"})
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	old := h.postIssue(c.author, postBody("post", "An old post"))
	h.sql(`UPDATE issues SET created_at = now() - interval '30 days' WHERE id = $1`, old.ID)

	// Blood: 4 donors, 2 can donate now (one is switched off, one gave 10 days ago).
	d1 := h.bloodUser("d1@test.ac.bd", "Donor One")
	d2 := h.bloodUser("d2@test.ac.bd", "Donor Two")
	d3 := h.bloodUser("d3@test.ac.bd", "Donor Three")
	d4 := h.bloodUser("d4@test.ac.bd", "Donor Four")
	recent, edge := "2026-10-17", "2026-06-29"
	h.bloodDonor(d1, "A+", "01711111111", true, nil)
	h.bloodDonor(d2, "O+", "01722222222", false, nil)
	h.bloodDonor(d3, "A+", "01733333333", true, &recent)
	h.bloodDonor(d4, "B+", "01744444444", true, &edge)
	req, body := h.postBlood(d2, bloodBody("A+", h.Now().Add(6*time.Hour), true))
	require.Equal(t, http.StatusCreated, req.Status, req.Raw)
	r = h.do("POST", "/blood/requests/"+body.ID+"/respond", d1, map[string]any{"phone": "01711111111"})
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	// A second request, long past: not open any more, and older than a week.
	h.sql(`INSERT INTO blood_requests (university_id, requester_id, blood_group, hospital, needed_by, contact_name, contact_phone, created_at)
		SELECT university_id, requester_id, 'B+', 'Old Hospital', now() - interval '30 days', 'Rafi', '01712345678', now() - interval '40 days'
		FROM blood_requests LIMIT 1`)

	// Buses: one live share, one finished trip counted, one rating.
	admin := c.admin
	route, a, b := h.busRoute(admin)
	r = h.busShare(a, route, shareBody("14:30", 90.4005))
	require.Equal(t, http.StatusCreated, r.Status, r.Raw)
	h.sql(`INSERT INTO bus_share_stats (user_id, trips) SELECT id, 4 FROM users WHERE email = 'a@test.ac.bd'`)
	r = h.do("POST", "/transport/routes/"+route+"/feedback", b, map[string]any{
		"direction": "to_campus", "departs": "14:30", "date": "2026-10-27", "status": "late"})
	require.Equal(t, http.StatusOK, r.Status, r.Raw)

	var st struct {
		Campus struct {
			PostsLast7Days     map[string]int `json:"postsLast7Days"`
			CommentsLast7Days  int            `json:"commentsLast7Days"`
			ReactionsLast7Days int            `json:"reactionsLast7Days"`
		} `json:"campus"`
		Blood struct {
			Donors             int `json:"donors"`
			Available          int `json:"available"`
			OpenRequests       int `json:"openRequests"`
			RequestsLast7Days  int `json:"requestsLast7Days"`
			ResponsesLast7Days int `json:"responsesLast7Days"`
		} `json:"blood"`
		Bus struct {
			LiveNow           int `json:"liveNow"`
			SharesLast7Days   int `json:"sharesLast7Days"`
			TripsShared       int `json:"tripsShared"`
			RatingsLast30Days int `json:"ratingsLast30Days"`
		} `json:"bus"`
		Users struct {
			Total int `json:"total"`
		} `json:"users"`
	}
	r = h.do("GET", "/admin/stats", admin, nil)
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	r.into(t, &st)
	assert.Equal(t, map[string]int{"issue": 1, "post": 1, "question": 1, "poll": 1}, st.Campus.PostsLast7Days)
	assert.Equal(t, 1, st.Campus.CommentsLast7Days)
	assert.Equal(t, 1, st.Campus.ReactionsLast7Days)
	assert.Equal(t, 4, st.Blood.Donors)
	assert.Equal(t, 2, st.Blood.Available, "d1 and d4 (exactly 120 days); d3 gave 10 days ago, d2 is off")
	assert.Equal(t, 1, st.Blood.OpenRequests)
	assert.Equal(t, 1, st.Blood.RequestsLast7Days)
	assert.Equal(t, 1, st.Blood.ResponsesLast7Days)
	assert.Equal(t, 1, st.Bus.LiveNow)
	assert.Equal(t, 1, st.Bus.SharesLast7Days)
	assert.Equal(t, 4, st.Bus.TripsShared)
	assert.Equal(t, 1, st.Bus.RatingsLast30Days)
	assert.Greater(t, st.Users.Total, 0, "existing keys stay")

	// Two minutes of silence: not live any more, still a share.
	h.advance(3 * time.Minute)
	admin = h.signIn("admin@test.ac.bd").Tokens.AccessToken // the old token has expired
	r = h.do("GET", "/admin/stats", admin, nil)
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	st.Bus.LiveNow = -1
	r.into(t, &st)
	assert.Equal(t, 0, st.Bus.LiveNow)
	assert.Equal(t, 1, st.Bus.SharesLast7Days)
}

func TestAdminBloodRequests(t *testing.T) {
	h := newHarness(t)
	admin := h.makeAdmin("admin@test.ac.bd")
	adminID := h.me(admin).ID
	other := h.addUni("other", "Other University")
	home := h.universityID("test-uni")
	rafi := h.bloodUser("rafi@test.ac.bd", "Rafi")
	mina := h.bloodUser("mina@other.ac.bd", "Mina")
	donor := h.bloodUser("donor@test.ac.bd", "Donor")
	h.bloodDonor(donor, "A+", "01755555555", true, nil)

	soon := h.Now().Add(6 * time.Hour)
	r, first := h.postBlood(rafi, bloodBody("A+", soon, true))
	require.Equal(t, http.StatusCreated, r.Status, r.Raw)
	h.advance(time.Minute)
	b2 := bloodBody("O-", soon, false)
	b2["hospital"], b2["area"], b2["contactName"], b2["contactPhone"] = "Square Hospital", "Panthapath", "Mina Akter", "01999999999"
	r, second := h.postBlood(mina, b2)
	require.Equal(t, http.StatusCreated, r.Status, r.Raw)
	h.advance(time.Minute)
	r, third := h.postBlood(rafi, bloodBody("B+", soon, false))
	require.Equal(t, http.StatusCreated, r.Status, r.Raw)
	require.Equal(t, http.StatusOK, h.do("POST", "/blood/requests/"+first.ID+"/respond", donor, map[string]any{"phone": "01755555555"}).Status)
	// third is fulfilled by its requester.
	require.Equal(t, http.StatusOK, h.do("POST", "/blood/requests/"+third.ID+"/close", rafi, map[string]any{"fulfilled": true}).Status)

	list := func(query string) adminBloodPage {
		t.Helper()
		r := h.do("GET", "/admin/blood/requests"+query, admin, nil)
		require.Equal(t, http.StatusOK, r.Status, r.Raw)
		var p adminBloodPage
		r.into(t, &p)
		return p
	}
	idsOf := func(p adminBloodPage) []string {
		out := []string{}
		for _, it := range p.Items {
			out = append(out, it.ID)
		}
		return out
	}

	// Default: open, newest first.
	p := list("")
	assert.Equal(t, []string{second.ID, first.ID}, idsOf(p))
	assert.Equal(t, 2, p.Total)
	assert.Equal(t, 1, p.Page)
	assert.Equal(t, 25, p.PageSize)
	it := p.Items[1]
	assert.Equal(t, "open", it.Status)
	assert.Equal(t, "A+", it.BloodGroup)
	assert.Equal(t, 1, it.Responses)
	assert.Equal(t, "test-uni", h.universitySlugOf(it.University.ID))
	assert.Equal(t, home, it.University.ID)
	assert.NotEmpty(t, it.University.Name)
	require.NotNil(t, it.Requester)
	assert.Equal(t, "rafi@test.ac.bd", it.Requester.Email)
	assert.Equal(t, "Rafi", it.Requester.Name)
	assert.Equal(t, h.me(rafi).ID, it.Requester.ID)
	assert.Equal(t, "01712345678", it.ContactPhone)
	assert.Nil(t, it.ClosedAt)

	assert.Equal(t, []string{third.ID}, idsOf(list("?status=fulfilled")))
	assert.Empty(t, list("?status=closed").Items)
	assert.Equal(t, []string{third.ID, second.ID, first.ID}, idsOf(list("?status=all")))
	assert.Equal(t, []string{third.ID, first.ID}, idsOf(list("?status=all&universityId="+home+"&q=enam")), "hospital")
	assert.Equal(t, []string{second.ID}, idsOf(list("?status=all&q=square")), "hospital")
	assert.Equal(t, []string{third.ID, first.ID}, idsOf(list("?status=all&universityId="+home)))
	assert.Equal(t, []string{second.ID}, idsOf(list("?universityId="+other)))
	assert.Equal(t, []string{second.ID}, idsOf(list("?q=panthapath")), "area")
	assert.Equal(t, []string{second.ID}, idsOf(list("?q=Mina+Akter")), "contact name")
	assert.Equal(t, []string{second.ID}, idsOf(list("?q=01999999999")), "contact phone")
	assert.Equal(t, []string{second.ID}, idsOf(list("?q=mina@other")), "requester email")
	assert.Empty(t, list("?q=%25").Items, "wildcards are literal")

	p = list("?status=all&pageSize=2&page=2")
	assert.Equal(t, 3, p.Total)
	assert.Equal(t, []string{first.ID}, idsOf(p))
	assert.Equal(t, "VALIDATION_FAILED", h.do("GET", "/admin/blood/requests?status=bogus", admin, nil).code())

	// Closing.
	assert.Equal(t, "VALIDATION_FAILED", h.do("POST", "/admin/blood/requests/"+first.ID+"/close", admin,
		map[string]string{"reason": string(make([]byte, 301))}).code())
	assert.Equal(t, "NOT_ADMIN", h.do("POST", "/admin/blood/requests/"+first.ID+"/close", rafi, map[string]string{}).code())
	assert.Equal(t, http.StatusForbidden, h.do("POST", "/admin/blood/requests/"+first.ID+"/close", rafi, map[string]string{}).Status)
	assert.Equal(t, http.StatusForbidden, h.do("GET", "/admin/blood/requests", rafi, nil).Status)
	assert.Equal(t, "BLOOD_REQUEST_NOT_FOUND", h.do("POST", "/admin/blood/requests/"+adminID+"/close", admin, map[string]string{}).code())

	r = h.do("POST", "/admin/blood/requests/"+first.ID+"/close", admin, map[string]string{"reason": "Duplicate"})
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	var closed adminBloodJSON
	r.into(t, &closed)
	assert.Equal(t, first.ID, closed.ID)
	assert.Equal(t, "closed", closed.Status)
	require.NotNil(t, closed.ClosedAt)
	assert.True(t, closed.ClosedAt.Equal(h.Now()))
	assert.Equal(t, 1, closed.Responses)
	assert.Equal(t, 1, h.count(`SELECT count(*) FROM audit_log WHERE action = 'blood.close' AND actor_id = $1 AND target_id = $2
		AND meta->>'reason' = 'Duplicate'`, adminID, first.ID))

	r = h.do("POST", "/admin/blood/requests/"+first.ID+"/close", admin, map[string]string{})
	assert.Equal(t, http.StatusConflict, r.Status)
	assert.Equal(t, "BLOOD_REQUEST_NOT_OPEN", r.code())
	assert.Equal(t, 1, h.count(`SELECT count(*) FROM audit_log WHERE action = 'blood.close'`), "no second row")
	assert.Equal(t, "BLOOD_REQUEST_NOT_OPEN", h.do("POST", "/admin/blood/requests/"+third.ID+"/close", admin, nil).code(), "fulfilled")
	assert.Equal(t, []string{second.ID}, idsOf(list("")))
	assert.Equal(t, []string{first.ID}, idsOf(list("?status=closed")))
}

func (h *harness) universitySlugOf(id string) string {
	h.t.Helper()
	var slug string
	require.NoError(h.t, h.app.DB.Pool.QueryRow(h.t.Context(), `SELECT slug FROM universities WHERE id = $1`, id).Scan(&slug))
	return slug
}

// busRoute makes a route like TestBusLive's (four stops, a 14:30 trip to
// campus) and two students, a and b, of the test university.
func (h *harness) busRoute(admin string) (route, a, b string) {
	h.t.Helper()
	a = h.signIn("a@test.ac.bd").Tokens.AccessToken
	b = h.signIn("b@test.ac.bd").Tokens.AccessToken
	r := h.do("POST", "/admin/transport/routes", admin, map[string]any{"universityId": h.universityID("test-uni"), "name": "Route 7"})
	require.Equal(h.t, http.StatusCreated, r.Status, r.Raw)
	var rt busRouteJSONWithIDs
	r.into(h.t, &rt)
	base := "/transport/routes/" + rt.ID
	at := func(lng float64) map[string]float64 { return map[string]float64{"lat": 23.80, "lng": lng} }
	r = h.do("PUT", base+"/stops", admin, map[string]any{"stops": []map[string]any{
		{"name": "Far end", "toCampusMin": 0, "fromCampusMin": 30, "location": at(90.40)},
		{"name": "Mirpur 10", "toCampusMin": 10, "fromCampusMin": 20, "location": at(90.41)},
		{"name": "Agargaon", "toCampusMin": 20, "fromCampusMin": 10, "location": at(90.42)},
		{"name": "Campus", "toCampusMin": 30, "fromCampusMin": 0, "location": at(90.43)},
	}})
	require.Equal(h.t, http.StatusOK, r.Status, r.Raw)
	r = h.do("PUT", base+"/trips", admin, map[string]any{"trips": []map[string]any{
		{"direction": "to_campus", "departs": "14:30", "weekdays": []int{1, 2, 3, 4, 5, 6, 7}},
	}})
	require.Equal(h.t, http.StatusOK, r.Status, r.Raw)
	return rt.ID, a, b
}

func TestAdminRouteActivityAndEnd(t *testing.T) {
	h := newHarness(t)
	admin := h.makeAdmin("admin@test.ac.bd")
	adminID := h.me(admin).ID
	h.addUni("other", "Other University")
	route, a, b := h.busRoute(admin)
	aID := h.me(a).ID
	base := "/admin/transport/routes/" + route

	// Nothing live yet.
	r := h.do("GET", base+"/activity", admin, nil)
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	assert.Contains(t, r.Raw, `"runs":[]`)
	assert.Contains(t, r.Raw, `"trips":[]`)

	// A shares and keeps pinging, so the trip counts when it ends.
	r = h.busShare(a, route, shareBody("14:30", 90.4005))
	require.Equal(t, http.StatusCreated, r.Status, r.Raw)
	var shared shareJSON
	r.into(t, &shared)
	for _, lng := range []float64{90.401, 90.402, 90.403} {
		h.advance(61 * time.Second)
		pr, out := h.busPing(a, shared.SessionID, lng)
		require.Equal(t, http.StatusOK, pr.Status, pr.Raw)
		require.False(t, out.Ended)
	}
	vote := map[string]any{"direction": "to_campus", "departs": "14:30", "date": "2026-10-27", "status": "late", "crowded": true}
	require.Equal(t, http.StatusOK, h.do("POST", "/transport/routes/"+route+"/feedback", b, vote).Status)

	// Students can't use the admin routes.
	assert.Equal(t, http.StatusForbidden, h.do("GET", base+"/activity", a, nil).Status)
	assert.Equal(t, http.StatusForbidden, h.do("POST", base+"/live/end", a, nil).Status)
	assert.Equal(t, "ROUTE_NOT_FOUND", h.do("GET", "/admin/transport/routes/"+adminID+"/activity", admin, nil).code())
	assert.Equal(t, "ROUTE_NOT_FOUND", h.do("POST", "/admin/transport/routes/"+adminID+"/live/end", admin, nil).code())

	r = h.do("GET", base+"/activity", admin, nil)
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	assert.NotContains(t, r.Raw, aID)
	assert.NotContains(t, r.Raw, `"mine"`)
	assert.NotContains(t, r.Raw, "userId")
	var act struct {
		Live struct {
			Runs []liveRunJSON `json:"runs"`
		} `json:"live"`
		Insights struct {
			Trips []insightJSON `json:"trips"`
		} `json:"insights"`
		SharesLast7Days   int `json:"sharesLast7Days"`
		RatingsLast30Days int `json:"ratingsLast30Days"`
	}
	r.into(t, &act)
	require.Len(t, act.Live.Runs, 1)
	run := act.Live.Runs[0]
	assert.Equal(t, "to_campus", run.Direction)
	require.NotNil(t, run.Departs)
	assert.Equal(t, "14:30", *run.Departs)
	assert.Equal(t, 1, run.Riders)
	assert.True(t, run.OnRoute)
	assert.NotNil(t, run.NextStopID)
	require.Len(t, act.Insights.Trips, 1)
	assert.Equal(t, 1, act.Insights.Trips[0].Votes)
	assert.Equal(t, 1, act.Insights.Trips[0].Late)
	assert.Equal(t, 1, act.Insights.Trips[0].Crowded)
	assert.Equal(t, 1, act.SharesLast7Days)
	assert.Equal(t, 1, act.RatingsLast30Days)

	// End: the share closes, the trip is counted, the sharer is told.
	r = h.do("POST", base+"/live/end", admin, nil)
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	var ended struct {
		Ended int `json:"ended"`
	}
	r.into(t, &ended)
	assert.Equal(t, 1, ended.Ended)
	assert.Contains(t, r.Raw, `"data":{"ended":1}`)
	assert.Equal(t, 1, h.count(`SELECT count(*) FROM bus_live_sessions WHERE id = $1 AND ended_at IS NOT NULL AND end_reason = 'admin'`, shared.SessionID))
	assert.Equal(t, 1, h.count(`SELECT trips FROM bus_share_stats WHERE user_id = $1`, aID))
	assert.Equal(t, 1, h.count(`SELECT count(*) FROM audit_log WHERE action = 'transport.live.end' AND actor_id = $1 AND target_id = $2
		AND (meta->>'ended')::int = 1`, adminID, route))
	pr, out := h.busPing(a, shared.SessionID, 90.404)
	require.Equal(t, http.StatusOK, pr.Status, pr.Raw)
	assert.True(t, out.Ended)
	require.NotNil(t, out.Reason)
	assert.Equal(t, "admin", *out.Reason)
	assert.Empty(t, h.busLive(b, route).Runs)
	r = h.do("GET", base+"/activity", admin, nil)
	r.into(t, &act)
	assert.Empty(t, act.Live.Runs)
	assert.Contains(t, r.Raw, `"runs":[]`)

	// Nothing left to end: ok, zero, still audited.
	r = h.do("POST", base+"/live/end", admin, nil)
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	assert.Contains(t, r.Raw, `"data":{"ended":0}`)
	assert.Equal(t, 1, h.count(`SELECT trips FROM bus_share_stats WHERE user_id = $1`, aID), "not counted twice")
}

func TestModerationIssueCampusOnly(t *testing.T) {
	h := newHarness(t)
	c := newVoiceCast(h)
	inside := h.postIssue(c.author, postBody("post", "Only for us here", map[string]any{"campusOnly": true}))
	open := h.postIssue(c.author, postBody("post", "Everyone can read this"))
	var mod struct {
		Kind       string `json:"kind"`
		CampusOnly bool   `json:"campusOnly"`
	}
	r := h.do("GET", "/moderation/issues/"+inside.ID, c.mod, nil)
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	assert.Contains(t, r.Raw, `"campusOnly":true`)
	r.into(t, &mod)
	assert.True(t, mod.CampusOnly)
	assert.Equal(t, "post", mod.Kind)
	r = h.do("GET", "/moderation/issues/"+open.ID, c.mod, nil)
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	assert.Contains(t, r.Raw, `"campusOnly":false`)
}
