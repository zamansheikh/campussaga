package app

import (
	"context"
	"net/http"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// Live buses (docs/BUS_LIVE.md). The harness clock is Tuesday 27 October
// 2026, 15:00 in Dhaka. The route runs east along latitude 23.80 with four
// stops about 1.02 km apart (90.40, 90.41, 90.42, 90.43), timed 0, 10, 20 and
// 30 minutes to campus.

type liveRunJSON struct {
	Direction  string                     `json:"direction"`
	Departs    *string                    `json:"departs"`
	Riders     int                        `json:"riders"`
	Position   struct{ Lat, Lng float64 } `json:"position"`
	OnRoute    bool                       `json:"onRoute"`
	Progress   float64                    `json:"progress"`
	Length     float64                    `json:"length"`
	Speed      float64                    `json:"speed"`
	DelayMin   *int                       `json:"delayMin"`
	NextStopID *string                    `json:"nextStopId"`
	Passed     []string                   `json:"passed"`
	ETAs       []struct {
		StopID string    `json:"stopId"`
		At     time.Time `json:"at"`
	} `json:"etas"`
	UpdatedAt time.Time `json:"updatedAt"`
	Mine      bool      `json:"mine"`
}

type liveJSON struct {
	Runs      []liveRunJSON `json:"runs"`
	MySession *struct {
		ID        string  `json:"id"`
		Direction string  `json:"direction"`
		Departs   *string `json:"departs"`
	} `json:"mySession"`
}

type shareJSON struct {
	SessionID string   `json:"sessionId"`
	Live      liveJSON `json:"live"`
}

type pingsJSON struct {
	Ended  bool    `json:"ended"`
	Reason *string `json:"reason"`
	Riders int     `json:"riders"`
}

type insightJSON struct {
	Direction string `json:"direction"`
	Departs   string `json:"departs"`
	Votes     int    `json:"votes"`
	OnTime    int    `json:"onTime"`
	Late      int    `json:"late"`
	NoShow    int    `json:"noShow"`
	Crowded   int    `json:"crowded"`
	DelayMin  *int   `json:"delayMin"`
	Runs      int    `json:"runs"`
}

func (h *harness) busShare(tok, route string, body map[string]any) *response {
	h.t.Helper()
	return h.do("POST", "/transport/routes/"+route+"/live/share", tok, body)
}

func shareBody(departs any, lng float64) map[string]any {
	return map[string]any{"direction": "to_campus", "departs": departs, "lat": 23.80, "lng": lng, "accuracy": 10}
}

// busPing sends one point at the current harness time.
func (h *harness) busPing(tok, session string, lng float64) (*response, pingsJSON) {
	h.t.Helper()
	r := h.do("POST", "/transport/live/"+session+"/pings", tok, map[string]any{"points": []map[string]any{
		{"at": h.Now().UTC().Format(time.RFC3339), "lat": 23.80, "lng": lng, "accuracy": 10},
	}})
	var out pingsJSON
	if r.Status == http.StatusOK {
		r.into(h.t, &out)
	}
	return r, out
}

func (h *harness) busLive(tok, route string) liveJSON {
	h.t.Helper()
	r := h.do("GET", "/transport/routes/"+route+"/live", tok, nil)
	require.Equal(h.t, http.StatusOK, r.Status, r.Raw)
	var out liveJSON
	r.into(h.t, &out)
	return out
}

func (h *harness) count(q string, args ...any) int {
	h.t.Helper()
	var n int
	require.NoError(h.t, h.app.DB.Pool.QueryRow(context.Background(), q, args...).Scan(&n))
	return n
}

func TestBusLive(t *testing.T) {
	h := newHarness(t)
	admin := h.makeAdmin("admin@test.ac.bd")
	h.addUni("other", "Other University")
	aSign, bSign := h.signIn("a@test.ac.bd"), h.signIn("b@test.ac.bd")
	a, b := aSign.Tokens.AccessToken, bSign.Tokens.AccessToken
	c := h.signIn("c@other.ac.bd").Tokens.AccessToken

	// A route with four placed stops and two trips each way.
	r := h.do("POST", "/admin/transport/routes", admin, map[string]any{"universityId": h.universityID("test-uni"), "name": "Route 7"})
	require.Equal(t, http.StatusCreated, r.Status, r.Raw)
	var route busRouteJSONWithIDs
	r.into(t, &route)
	base := "/transport/routes/" + route.ID
	at := func(lng float64) map[string]float64 { return map[string]float64{"lat": 23.80, "lng": lng} }
	r = h.do("PUT", base+"/stops", admin, map[string]any{"stops": []map[string]any{
		{"name": "Far end", "toCampusMin": 0, "fromCampusMin": 30, "location": at(90.40)},
		{"name": "Mirpur 10", "toCampusMin": 10, "fromCampusMin": 20, "location": at(90.41)},
		{"name": "Agargaon", "toCampusMin": 20, "fromCampusMin": 10, "location": at(90.42)},
		{"name": "Campus", "toCampusMin": 30, "fromCampusMin": 0, "location": at(90.43)},
	}})
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	r.into(t, &route)
	require.Len(t, route.Stops, 4)
	all := []int{1, 2, 3, 4, 5, 6, 7}
	r = h.do("PUT", base+"/trips", admin, map[string]any{"trips": []map[string]any{
		{"direction": "to_campus", "departs": "14:30", "weekdays": all},
		{"direction": "to_campus", "departs": "20:00", "weekdays": all},
		{"direction": "from_campus", "departs": "14:30", "weekdays": all},
	}})
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	stop := func(i int) string { return route.Stops[i].ID }

	// Nobody is live yet.
	live := h.busLive(b, route.ID)
	assert.Empty(t, live.Runs)
	assert.Nil(t, live.MySession)
	assert.Contains(t, h.do("GET", "/transport/live", b, nil).Raw, `"routes":[]`)

	// Another university's student sees nothing of this route.
	assert.Equal(t, "ROUTE_NOT_FOUND", h.do("GET", base+"/live", c, nil).code())
	assert.Equal(t, "ROUTE_NOT_FOUND", h.busShare(c, route.ID, shareBody("14:30", 90.4005)).code())
	assert.Equal(t, "ROUTE_NOT_FOUND", h.do("GET", base+"/insights", c, nil).code())
	assert.Equal(t, "ROUTE_NOT_FOUND", h.do("PUT", base+"/alert", c, map[string]any{"stopId": stop(2), "direction": "to_campus", "leadMin": 10}).code())

	// Sharing errors.
	assert.Equal(t, "TRIP_NOT_RUNNING", h.busShare(b, route.ID, shareBody("09:15", 90.4005)).code(), "not a trip of the route")
	assert.Equal(t, "TRIP_NOT_RUNNING", h.busShare(b, route.ID, shareBody("20:00", 90.4005)).code(), "too long before it leaves")
	assert.Equal(t, "NOT_ON_ROUTE", h.busShare(b, route.ID, map[string]any{"direction": "to_campus", "departs": nil, "lat": 23.9, "lng": 90.5, "accuracy": 10}).code())
	assert.Equal(t, "VALIDATION_FAILED", h.busShare(b, route.ID, map[string]any{"direction": "sideways", "lat": 23.8, "lng": 90.4, "accuracy": 10}).code())
	assert.Equal(t, "SESSION_NOT_FOUND", h.do("POST", "/transport/live/"+route.ID+"/pings", b, map[string]any{"points": []map[string]any{{"at": h.Now().UTC().Format(time.RFC3339), "lat": 23.8, "lng": 90.4, "accuracy": 10}}}).code())

	// B wants to know when the bus is 10 minutes from Agargaon.
	h.register(b, "phone-b", "android", "en")
	r = h.do("PUT", base+"/alert", b, map[string]any{"stopId": stop(2), "direction": "to_campus", "leadMin": 10})
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	assert.Equal(t, "VALIDATION_FAILED", h.do("PUT", base+"/alert", b, map[string]any{"stopId": stop(2), "direction": "to_campus", "leadMin": 7}).code())
	assert.Equal(t, "STOP_NOT_FOUND", h.do("PUT", base+"/alert", b, map[string]any{"stopId": route.ID, "direction": "to_campus", "leadMin": 10}).code())
	var alerts struct {
		Alerts []struct {
			RouteID, StopID, Direction string
			LeadMin                    int
		} `json:"alerts"`
	}
	h.do("GET", "/transport/alerts", b, nil).into(t, &alerts)
	require.Len(t, alerts.Alerts, 1)
	assert.Equal(t, route.ID, alerts.Alerts[0].RouteID)
	assert.Equal(t, stop(2), alerts.Alerts[0].StopID)
	assert.Equal(t, 10, alerts.Alerts[0].LeadMin)

	// A starts sharing the 14:30 bus near the far end.
	r = h.busShare(a, route.ID, shareBody("14:30", 90.4005))
	require.Equal(t, http.StatusCreated, r.Status, r.Raw)
	var shared shareJSON
	r.into(t, &shared)
	session := shared.SessionID
	require.NotEmpty(t, session)
	require.Len(t, shared.Live.Runs, 1)
	assert.True(t, shared.Live.Runs[0].Mine)
	assert.Equal(t, 1, shared.Live.Runs[0].Riders)
	require.NotNil(t, shared.Live.MySession)
	assert.Equal(t, session, shared.Live.MySession.ID)
	assert.Empty(t, h.pushes(), "the bus is 20 minutes away: too early")

	// B sees the run, without any user id.
	r = h.do("GET", base+"/live", b, nil)
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	assert.NotContains(t, r.Raw, aSign.User.ID)
	assert.NotContains(t, r.Raw, "userId")
	r.into(t, &live)
	require.Len(t, live.Runs, 1)
	run := live.Runs[0]
	assert.False(t, run.Mine)
	assert.Nil(t, live.MySession)
	assert.Equal(t, 1, run.Riders)
	assert.True(t, run.OnRoute)
	require.NotNil(t, run.Departs)
	assert.Equal(t, "14:30", *run.Departs)
	assert.InDelta(t, 3053, run.Length, 15)
	assert.InDelta(t, 51, run.Progress, 10)
	assert.InDelta(t, 90.4005, run.Position.Lng, 0.0002)
	require.NotNil(t, run.DelayMin)
	assert.InDelta(t, 34, *run.DelayMin, 5, "15:0x against a 14:30 bus at minute 0")
	assert.Equal(t, []string{stop(0)}, run.Passed)
	require.NotNil(t, run.NextStopID)
	assert.Equal(t, stop(1), *run.NextStopID)
	require.Len(t, run.ETAs, 3)
	assert.Equal(t, stop(1), run.ETAs[0].StopID)
	assert.InDelta(t, 9.5, run.ETAs[0].At.Sub(h.Now()).Minutes(), 0.6)
	assert.Equal(t, stop(3), run.ETAs[2].StopID)
	assert.InDelta(t, 29.5, run.ETAs[2].At.Sub(h.Now()).Minutes(), 0.6)

	// The route list badge.
	var badges struct {
		Routes []struct {
			RouteID string `json:"routeId"`
			Runs    int    `json:"runs"`
			Riders  int    `json:"riders"`
		} `json:"routes"`
	}
	h.do("GET", "/transport/live", b, nil).into(t, &badges)
	require.Len(t, badges.Routes, 1)
	assert.Equal(t, route.ID, badges.Routes[0].RouteID)
	assert.Equal(t, 1, badges.Routes[0].Runs)
	assert.Equal(t, 1, badges.Routes[0].Riders)
	assert.Contains(t, h.do("GET", "/transport/live", c, nil).Raw, `"routes":[]`, "other universities see nothing")

	// The bus moves past Mirpur 10: it is now about 9 minutes from Agargaon.
	h.advance(90 * time.Second)
	rr, pg := h.busPing(a, session, 90.4105)
	require.Equal(t, http.StatusOK, rr.Status, rr.Raw)
	assert.False(t, pg.Ended)
	assert.Nil(t, pg.Reason)
	assert.Equal(t, 1, pg.Riders)
	assert.Contains(t, rr.Raw, `"reason":null`)

	sent := h.pushes()
	require.Len(t, sent, 1)
	assert.Equal(t, "phone-b", sent[0].Token)
	assert.Equal(t, "bus_near", sent[0].Data["type"])
	assert.Equal(t, route.ID, sent[0].Data["routeId"])
	assert.Equal(t, stop(2), sent[0].Data["stopId"])
	assert.Equal(t, "Bus coming: Route 7", sent[0].Title)
	assert.Contains(t, sent[0].Body, "from Agargaon")
	assert.Contains(t, sent[0].Body, "1 sharing live")

	live = h.busLive(b, route.ID)
	require.Len(t, live.Runs, 1)
	run = live.Runs[0]
	assert.InDelta(t, 1068, run.Progress, 15)
	assert.Equal(t, []string{stop(0), stop(1)}, run.Passed)
	assert.Equal(t, stop(2), *run.NextStopID)
	require.Len(t, run.ETAs, 2)
	assert.Greater(t, run.Speed, 0.0)

	// Later pings: the alert has fired for this run, it does not fire again.
	h.advance(90 * time.Second)
	_, pg = h.busPing(a, session, 90.4205)
	assert.False(t, pg.Ended)
	live = h.busLive(b, route.ID)
	assert.Equal(t, []string{stop(0), stop(1), stop(2)}, live.Runs[0].Passed)
	assert.Equal(t, stop(3), *live.Runs[0].NextStopID)
	assert.Empty(t, h.pushes())

	// A point too soon after the last, or from far away, is dropped; the
	// session lives on.
	_, pg = h.busPing(a, session, 90.4205)
	assert.False(t, pg.Ended)

	// The bus reaches the end of the line.
	h.advance(90 * time.Second)
	rr, pg = h.busPing(a, session, 90.4300)
	require.Equal(t, http.StatusOK, rr.Status, rr.Raw)
	assert.True(t, pg.Ended)
	require.NotNil(t, pg.Reason)
	assert.Equal(t, "arrived", *pg.Reason)
	assert.Empty(t, h.pushes())
	// Asking again says the same, so the phone stops cleanly.
	_, pg = h.busPing(a, session, 90.4300)
	assert.True(t, pg.Ended)
	assert.Equal(t, "arrived", *pg.Reason)
	// Someone else's session does not exist for you.
	assert.Equal(t, "SESSION_NOT_FOUND", h.do("POST", "/transport/live/"+session+"/stop", b, nil).code())
	r, _ = h.busPing(b, session, 90.4300)
	assert.Equal(t, "SESSION_NOT_FOUND", r.code())
	assert.Empty(t, h.busLive(b, route.ID).Runs, "an ended share is not live")

	// Stopping after the server ended it still answers, and counts the trip once.
	var stopped struct{ Helped, Trips int }
	r = h.do("POST", "/transport/live/"+session+"/stop", a, nil)
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	r.into(t, &stopped)
	assert.GreaterOrEqual(t, stopped.Helped, 1)
	assert.Equal(t, 1, stopped.Trips)
	h.do("POST", "/transport/live/"+session+"/stop", a, nil).into(t, &stopped)
	assert.Equal(t, 1, stopped.Trips)
	assert.Equal(t, 1, h.count(`SELECT trips FROM bus_share_stats WHERE user_id = $1`, aSign.User.ID))

	// What the live bus taught: the stops it passed, with their timetable times.
	assert.GreaterOrEqual(t, h.count(`SELECT count(*) FROM bus_run_stops WHERE route_id = $1 AND scheduled_at IS NOT NULL`, route.ID), 3)

	// Trip feedback: one vote per student, a second replaces it.
	fb := func(tok string, body map[string]any) *response { return h.do("POST", base+"/feedback", tok, body) }
	vote := map[string]any{"direction": "to_campus", "departs": "14:30", "date": "2026-10-27", "status": "late", "crowded": true}
	r = fb(b, vote)
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	var in insightJSON
	r.into(t, &in)
	assert.Equal(t, insightJSON{Direction: "to_campus", Departs: "14:30", Votes: 1, Late: 1, Crowded: 1, Runs: 1}, in)
	vote["status"], vote["crowded"] = "on_time", false
	fb(b, vote)
	r = fb(a, vote)
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	vote["status"], vote["crowded"] = "no_show", true
	fb(c, vote) // other university: ignored below
	var ins struct {
		Trips []insightJSON `json:"trips"`
	}
	h.do("GET", base+"/insights", b, nil).into(t, &ins)
	require.Len(t, ins.Trips, 1)
	assert.Equal(t, insightJSON{Direction: "to_campus", Departs: "14:30", Votes: 2, OnTime: 2, Runs: 1}, ins.Trips[0])
	assert.Contains(t, h.do("GET", base+"/insights", b, nil).Raw, `"delayMin":null`)

	vote["status"] = "late"
	assert.Equal(t, "FEEDBACK_TOO_EARLY", fb(b, map[string]any{"direction": "to_campus", "departs": "20:00", "date": "2026-10-27", "status": "late", "crowded": false}).code())
	assert.Equal(t, "TRIP_NOT_FOUND", fb(b, map[string]any{"direction": "to_campus", "departs": "09:15", "date": "2026-10-27", "status": "late", "crowded": false}).code())
	assert.Equal(t, "INVALID_FEEDBACK", fb(b, map[string]any{"direction": "to_campus", "departs": "14:30", "date": "2026-10-20", "status": "late", "crowded": false}).code())
	assert.Equal(t, "INVALID_FEEDBACK", fb(b, map[string]any{"direction": "to_campus", "departs": "14:30", "date": "2026-10-28", "status": "late", "crowded": false}).code())
	assert.Equal(t, "VALIDATION_FAILED", fb(b, map[string]any{"direction": "to_campus", "departs": "14:30", "date": "2026-10-27", "status": "meh", "crowded": false}).code())
	assert.Equal(t, http.StatusOK, fb(b, map[string]any{"direction": "from_campus", "departs": "14:30", "date": "2026-10-26", "status": "no_show", "crowded": false}).Status, "yesterday")

	// An alert can be removed.
	assert.Equal(t, http.StatusNoContent, h.do("DELETE", base+"/alert?direction=to_campus", b, nil).Status)
	h.do("GET", "/transport/alerts", b, nil).into(t, &alerts)
	assert.Empty(t, alerts.Alerts)
}

func TestBusLiveLimitAndSweep(t *testing.T) {
	h := newHarness(t)
	admin := h.makeAdmin("admin@test.ac.bd")
	r := h.do("POST", "/admin/transport/routes", admin, map[string]any{"universityId": h.universityID("test-uni"), "name": "Route 9"})
	require.Equal(t, http.StatusCreated, r.Status, r.Raw)
	var route busRouteJSONWithIDs
	r.into(t, &route)
	base := "/transport/routes/" + route.ID
	at := func(lng float64) map[string]float64 { return map[string]float64{"lat": 23.80, "lng": lng} }
	r = h.do("PUT", base+"/stops", admin, map[string]any{"stops": []map[string]any{
		{"name": "Far end", "location": at(90.40)}, {"name": "Campus", "location": at(90.43)},
	}})
	require.Equal(t, http.StatusOK, r.Status, r.Raw)

	// A bus not on the timetable can be shared. Eight shares a day, each
	// replacing the one before; the ninth is refused.
	d := h.signIn("d@test.ac.bd").Tokens.AccessToken
	var first string
	for i := 0; i < 8; i++ {
		r = h.busShare(d, route.ID, shareBody(nil, 90.405))
		require.Equal(t, http.StatusCreated, r.Status, r.Raw)
		var s shareJSON
		r.into(t, &s)
		if i == 0 {
			first = s.SessionID
		}
	}
	r = h.busShare(d, route.ID, shareBody(nil, 90.405))
	assert.Equal(t, "SHARE_LIMIT", r.code())
	assert.Equal(t, http.StatusTooManyRequests, r.Status)
	assert.Equal(t, 7, h.count(`SELECT count(*) FROM bus_live_sessions WHERE end_reason = 'replaced'`))
	_, pg := h.busPing(d, first, 90.406)
	assert.True(t, pg.Ended)
	assert.Equal(t, "replaced", *pg.Reason)
	h.sql(`DELETE FROM bus_live_sessions`)

	// Without a timetable a run has a place and riders but no delay.
	a := h.signIn("a@test.ac.bd").Tokens.AccessToken
	b := h.signIn("b@test.ac.bd").Tokens.AccessToken
	r = h.busShare(a, route.ID, shareBody(nil, 90.405))
	require.Equal(t, http.StatusCreated, r.Status, r.Raw)
	var s shareJSON
	r.into(t, &s)
	live := h.busLive(b, route.ID)
	require.Len(t, live.Runs, 1)
	assert.Nil(t, live.Runs[0].Departs)
	assert.Nil(t, live.Runs[0].DelayMin)
	assert.Contains(t, h.do("GET", base+"/live", b, nil).Raw, `"departs":null`)

	// The phone goes quiet; the sweeper ends the share.
	h.advance(11 * time.Minute)
	b = h.signIn("b@test.ac.bd").Tokens.AccessToken
	assert.Empty(t, h.busLive(b, route.ID).Runs)
	require.NoError(t, h.app.Transport.Sweep(context.Background()))
	assert.Equal(t, 0, h.count(`SELECT count(*) FROM bus_live_sessions WHERE ended_at IS NULL`))
	assert.Equal(t, 1, h.count(`SELECT count(*) FROM bus_live_sessions WHERE end_reason = 'expired'`))
	_, pg = h.busPing(a, s.SessionID, 90.406)
	assert.True(t, pg.Ended)
	assert.Equal(t, "expired", *pg.Reason)

	// A day later the share and its points are gone.
	h.advance(25 * time.Hour)
	require.NoError(t, h.app.Transport.Sweep(context.Background()))
	assert.Equal(t, 0, h.count(`SELECT count(*) FROM bus_live_sessions`))
	assert.Equal(t, 0, h.count(`SELECT count(*) FROM bus_live_pings`))
}

// busRouteJSONWithIDs is a route with stop ids.
type busRouteJSONWithIDs struct {
	ID    string `json:"id"`
	Stops []struct {
		ID string `json:"id"`
	} `json:"stops"`
}
