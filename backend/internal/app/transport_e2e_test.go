package app

import (
	"context"
	"net/http"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

type busRouteJSON struct {
	ID    string `json:"id"`
	Name  string `json:"name"`
	Color string `json:"color"`
	Stops []struct {
		Name          string `json:"name"`
		ToCampusMin   *int   `json:"toCampusMin"`
		FromCampusMin *int   `json:"fromCampusMin"`
		Location      *struct {
			Lat float64 `json:"lat"`
			Lng float64 `json:"lng"`
		} `json:"location"`
	} `json:"stops"`
	Trips []struct {
		Direction string `json:"direction"`
		Departs   string `json:"departs"`
		Weekdays  []int  `json:"weekdays"`
	} `json:"trips"`
	Active bool `json:"active"`
}

type busListJSON struct {
	Routes  []busRouteJSON `json:"routes"`
	CanEdit bool           `json:"canEdit"`
}

func (h *harness) busRoutes(token string) busListJSON {
	h.t.Helper()
	r := h.do("GET", "/transport/routes", token, nil)
	require.Equal(h.t, http.StatusOK, r.Status, r.Raw)
	var out busListJSON
	r.into(h.t, &out)
	return out
}

func TestBusRoutes(t *testing.T) {
	h := newHarness(t)
	admin := h.makeAdmin("admin@test.ac.bd")
	rep := h.signIn("rep@test.ac.bd")
	student := h.signIn("student@test.ac.bd").Tokens.AccessToken
	uni := h.universityID("test-uni")

	// Nothing yet; students can't edit.
	got := h.busRoutes(student)
	assert.Empty(t, got.Routes)
	assert.False(t, got.CanEdit)
	assert.Equal(t, "NOT_TRANSPORT_REP", h.do("POST", "/transport/routes", student, map[string]any{"name": "Route 1"}).code())

	// The admin names a transport rep.
	r := h.do("PUT", "/admin/transport/reps", admin, map[string]string{"userId": rep.User.ID, "universityId": uni})
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	assert.Equal(t, "NOT_ADMIN", h.do("GET", "/admin/transport/reps", student, nil).code())
	repTok := rep.Tokens.AccessToken
	assert.True(t, h.busRoutes(repTok).CanEdit)

	// The rep adds a route, its stops and its timetable.
	r = h.do("POST", "/transport/routes", repTok, map[string]any{"name": "  Route 4 ·  Mirpur ", "color": "#0f766e"})
	require.Equal(t, http.StatusCreated, r.Status, r.Raw)
	var route busRouteJSON
	r.into(t, &route)
	assert.Equal(t, "Route 4 · Mirpur", route.Name)
	assert.Equal(t, "#0F766E", route.Color)
	base := "/transport/routes/" + route.ID

	r = h.do("PUT", base+"/stops", repTok, map[string]any{"stops": []map[string]any{
		{"name": "Mirpur 10", "toCampusMin": 0, "fromCampusMin": 50, "location": map[string]float64{"lat": 23.8069, "lng": 90.3687}},
		{"name": "Agargaon", "landmark": "near the metro", "toCampusMin": 20, "fromCampusMin": 30, "location": nil},
		{"name": "Campus", "toCampusMin": 50, "fromCampusMin": 0},
	}})
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	r.into(t, &route)
	require.Len(t, route.Stops, 3)
	assert.Equal(t, "Agargaon", route.Stops[1].Name)
	require.NotNil(t, route.Stops[0].Location)
	assert.InDelta(t, 23.8069, route.Stops[0].Location.Lat, 1e-9)
	assert.Nil(t, route.Stops[1].Location)

	// An app from before the map sends no location: Mirpur 10 keeps its place.
	r = h.do("PUT", base+"/stops", repTok, map[string]any{"stops": []map[string]any{
		{"name": "Mirpur 10", "toCampusMin": 0, "fromCampusMin": 50},
		{"name": "Agargaon", "landmark": "near the metro", "toCampusMin": 20, "fromCampusMin": 30},
		{"name": "Campus", "toCampusMin": 50, "fromCampusMin": 0},
	}})
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	r.into(t, &route)
	require.NotNil(t, route.Stops[0].Location)
	assert.InDelta(t, 90.3687, route.Stops[0].Location.Lng, 1e-9)

	r = h.do("PUT", base+"/trips", repTok, map[string]any{"trips": []map[string]any{
		{"direction": "to_campus", "departs": "07:30", "weekdays": []int{6, 7, 1, 2, 3, 4, 6}},
		{"direction": "from_campus", "departs": "17:00", "weekdays": []int{6, 7, 1, 2, 3, 4}},
	}})
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	r.into(t, &route)
	require.Len(t, route.Trips, 2)
	assert.Equal(t, []int{1, 2, 3, 4, 6, 7}, route.Trips[1].Weekdays, "sorted, no duplicates")

	// Students of that university read it.
	got = h.busRoutes(student)
	require.Len(t, got.Routes, 1)
	assert.Len(t, got.Routes[0].Trips, 2)
	assert.Equal(t, http.StatusOK, h.do("GET", base, student, nil).Status)

	// Validation.
	bad := func(path string, body map[string]any) string { return h.do("PUT", path, repTok, body).code() }
	assert.Equal(t, "VALIDATION_FAILED", bad(base+"/stops", map[string]any{"stops": []map[string]any{
		{"name": "A", "toCampusMin": 20}, {"name": "B", "toCampusMin": 10},
	}}), "to campus times must not go back")
	assert.Equal(t, "VALIDATION_FAILED", bad(base+"/stops", map[string]any{"stops": []map[string]any{
		{"name": "A", "location": map[string]float64{"lat": 95, "lng": 90}},
	}}), "a point on the map")
	assert.Equal(t, "VALIDATION_FAILED", bad(base+"/trips", map[string]any{"trips": []map[string]any{
		{"direction": "to_campus", "departs": "7:30", "weekdays": []int{1}},
	}}), "HH:MM")
	assert.Equal(t, "VALIDATION_FAILED", bad(base+"/trips", map[string]any{"trips": []map[string]any{
		{"direction": "to_campus", "departs": "07:30", "weekdays": []int{8}},
	}}), "ISO weekdays")
	assert.Equal(t, "VALIDATION_FAILED", h.do("POST", "/transport/routes", repTok, map[string]any{"name": "X", "color": "teal"}).code())

	// Hidden routes: only editors see them.
	r = h.do("PUT", base, repTok, map[string]any{"name": "Route 4 · Mirpur", "active": false})
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	assert.Empty(t, h.busRoutes(student).Routes)
	assert.Len(t, h.busRoutes(repTok).Routes, 1)

	// Another university: the route doesn't exist there, and its rep can't touch it.
	_, err := h.app.DB.Pool.Exec(context.Background(), `INSERT INTO universities (slug, name) VALUES ('other-uni', 'Other University')`)
	require.NoError(t, err)
	other := h.signIn("x@test.ac.bd")
	_, err = h.app.DB.Pool.Exec(context.Background(), `UPDATE users SET university_id = $1 WHERE id = $2`, h.universityID("other-uni"), other.User.ID)
	require.NoError(t, err)
	assert.Equal(t, "ROUTE_NOT_FOUND", h.do("GET", base, other.Tokens.AccessToken, nil).code())
	require.Equal(t, http.StatusOK, h.do("PUT", "/admin/transport/reps", admin, map[string]string{"userId": other.User.ID, "universityId": h.universityID("other-uni")}).Status)
	assert.Equal(t, "ROUTE_NOT_FOUND", h.do("DELETE", base, other.Tokens.AccessToken, nil).code())

	// The admin panel lists and creates for any university, and edits routes.
	var adminList struct {
		Routes []busRouteJSON `json:"routes"`
	}
	h.do("GET", "/admin/transport/routes?universityId="+uni, admin, nil).into(t, &adminList)
	assert.Len(t, adminList.Routes, 1)
	r = h.do("POST", "/admin/transport/routes", admin, map[string]any{"universityId": h.universityID("other-uni"), "name": "Shuttle"})
	require.Equal(t, http.StatusCreated, r.Status, r.Raw)
	assert.Equal(t, http.StatusOK, h.do("PUT", base, admin, map[string]any{"name": "Route 4", "active": true}).Status)

	// Removing a rep ends their editing; deleting a route; audit rows.
	assert.Equal(t, http.StatusNoContent, h.do("DELETE", "/admin/transport/reps/"+rep.User.ID, admin, nil).Status)
	assert.Equal(t, "NOT_TRANSPORT_REP", h.do("DELETE", base, repTok, nil).code())
	assert.Equal(t, http.StatusNoContent, h.do("DELETE", base, admin, nil).Status)
	assert.Empty(t, h.busRoutes(student).Routes)
	var n int
	require.NoError(t, h.app.DB.Pool.QueryRow(context.Background(), `SELECT count(*) FROM audit_log WHERE action LIKE 'transport.%'`).Scan(&n))
	assert.GreaterOrEqual(t, n, 8)
}
