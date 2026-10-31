package transport

import (
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// An L-shaped line: 1 km east, then 1.1 km north (about).
func testLine(t *testing.T) *routeLine {
	t.Helper()
	l := newLine([]LatLng{{Lat: 23.80, Lng: 90.400}, {Lat: 23.80, Lng: 90.410}, {Lat: 23.81, Lng: 90.410}})
	require.NotNil(t, l)
	return l
}

func TestDecodePolyline(t *testing.T) {
	pts, ok := decodePolyline("_p~iF~ps|U_ulLnnqC_mqNvxq`@")
	require.True(t, ok)
	require.Len(t, pts, 3)
	assert.InDelta(t, 38.5, pts[0].Lat, 1e-9)
	assert.InDelta(t, -120.2, pts[0].Lng, 1e-9)
	assert.InDelta(t, 43.252, pts[2].Lat, 1e-9)
	assert.InDelta(t, -126.453, pts[2].Lng, 1e-9)

	for _, bad := range []string{"", "path-3", "_p~iF"} {
		_, ok := decodePolyline(bad)
		assert.False(t, ok, bad)
	}
	assert.Nil(t, newLine([]LatLng{{Lat: 1, Lng: 1}}))
	assert.Nil(t, newLine([]LatLng{{Lat: 1, Lng: 1}, {Lat: 1, Lng: 1}}))
}

func TestProjectProgressAndOff(t *testing.T) {
	l := testLine(t)
	seg1 := l.cum[1]
	assert.InDelta(t, 1020, seg1, 20)

	p, off := l.project(LatLng{Lat: 23.80, Lng: 90.405}) // halfway along the first leg
	assert.InDelta(t, seg1/2, p, 2)
	assert.Less(t, off, 1.0)

	p, off = l.project(LatLng{Lat: 23.8009, Lng: 90.405}) // 100 m north of it
	assert.InDelta(t, seg1/2, p, 2)
	assert.InDelta(t, 100, off, 2)

	p, off = l.project(LatLng{Lat: 23.805, Lng: 90.4101}) // second leg, 10 m east
	assert.InDelta(t, seg1+l.cum[2]-l.cum[1]-(l.cum[2]-l.cum[1])/2, p, 5)
	assert.InDelta(t, 10, off, 2)

	p, _ = l.project(LatLng{Lat: 23.79, Lng: 90.39}) // before the start: clamped
	assert.Equal(t, 0.0, p)
	p, _ = l.project(LatLng{Lat: 23.9, Lng: 90.5}) // past the end
	assert.InDelta(t, l.length, p, 1e-6)

	// at() is the inverse of project().
	back := l.at(seg1 / 2)
	assert.InDelta(t, 23.80, back.Lat, 1e-6)
	assert.InDelta(t, 90.405, back.Lng, 1e-4)
}

func TestProgressBothDirections(t *testing.T) {
	l := testLine(t)
	p, _ := l.project(LatLng{Lat: 23.80, Lng: 90.401}) // near the far end
	assert.Less(t, p, 150.0)
	// Travelling to campus (the end of the line) progress grows with p; from
	// campus it is measured from the other end.
	assert.InDelta(t, p, l.along(ToCampus, p), 1e-9)
	assert.InDelta(t, l.length-p, l.along(FromCampus, p), 1e-9)
	assert.InDelta(t, p, l.along(FromCampus, l.along(FromCampus, p)), 1e-9)
}

func timedStops() []dirStop {
	return []dirStop{
		{ID: uuid.New(), Name: "A", Prog: 0, Min: 0},
		{ID: uuid.New(), Name: "B", Prog: 1000, Min: 10},
		{ID: uuid.New(), Name: "skip", Prog: 1500, Min: -1},
		{ID: uuid.New(), Name: "C", Prog: 2000, Min: 30},
	}
}

func TestScheduledMinute(t *testing.T) {
	st := timedStops()
	for prog, want := range map[float64]float64{-50: 0, 0: 0, 500: 5, 1000: 10, 1500: 20, 2000: 30, 2500: 30} {
		got, ok := scheduledMinute(st, prog)
		assert.True(t, ok)
		assert.InDelta(t, want, got, 1e-9, prog)
	}
	_, ok := scheduledMinute(st[:1], 0)
	assert.False(t, ok, "needs two timed stops")
	_, ok = scheduledMinute([]dirStop{{Prog: 0, Min: -1}, {Prog: 10, Min: -1}}, 5)
	assert.False(t, ok)
}

func TestDelayMinutes(t *testing.T) {
	day := time.Date(2026, 10, 27, 0, 0, 0, 0, dhaka)
	// 7:30 trip, scheduled minute 10 at this spot: due 7:40.
	assert.Equal(t, 4, delayMinutes(day.Add(7*time.Hour+44*time.Minute), day, 7*60+30, 10))
	assert.Equal(t, -2, delayMinutes(day.Add(7*time.Hour+38*time.Minute), day, 7*60+30, 10))
	assert.Equal(t, 0, delayMinutes(day.Add(7*time.Hour+40*time.Minute+10*time.Second), day, 7*60+30, 10))
}

func TestNoteStopsETAs(t *testing.T) {
	now := time.Date(2026, 10, 27, 1, 0, 0, 0, time.UTC)
	st := timedStops()

	// At 1500 m the schedule says minute 20; stop C (minute 30) is 10 min
	// away. A and B are behind; "skip" has no offset and is not served.
	n := noteStops(st, 1500, 8, now)
	require.Len(t, n.Passed, 2)
	require.NotNil(t, n.Next)
	assert.Equal(t, "C", n.Next.Name)
	require.Len(t, n.ETAs, 1)
	assert.Equal(t, st[3].ID, n.ETAs[0].StopID)
	assert.Equal(t, now.Add(10*time.Minute), n.ETAs[0].At)

	// Just before B (20 m): not passed, but within 50 m so no ETA for it;
	// C comes from the schedule: minute 30 - 9.8.
	n = noteStops(st, 980, 8, now)
	require.Len(t, n.Passed, 1)
	assert.Equal(t, "B", n.Next.Name)
	require.Len(t, n.ETAs, 1)
	assert.WithinDuration(t, now.Add(time.Duration(20.2*float64(time.Minute))), n.ETAs[0].At, time.Second)

	// Without a timetable the ETA is distance over speed, the speed clamped
	// to 3-15 m/s and 5 m/s when not moving.
	plain := []dirStop{{ID: uuid.New(), Prog: 0, Min: -1}, {ID: uuid.New(), Prog: 3000, Min: -1}}
	for speed, secs := range map[float64]float64{0: 600, 0.5: 600, 1.5: 1000, 10: 300, 40: 200} {
		n = noteStops(plain, 0, speed, now)
		// the first stop is under the bus; the second is ahead
		require.Len(t, n.ETAs, 1, speed)
		assert.InDelta(t, secs, n.ETAs[0].At.Sub(now).Seconds(), 1, speed)
	}
	// One timed stop is not enough to use the schedule either.
	one := []dirStop{{ID: uuid.New(), Prog: 1000, Min: 10}}
	n = noteStops(one, 0, 10, now)
	assert.Equal(t, now.Add(100*time.Second), n.ETAs[0].At)

	// An ETA is never before now (a stop the schedule says is already behind).
	odd := []dirStop{{ID: uuid.New(), Prog: 0, Min: 20}, {ID: uuid.New(), Prog: 1000, Min: 30}, {ID: uuid.New(), Prog: 1100, Min: 5}}
	n = noteStops(odd, 100, 8, now)
	for _, e := range n.ETAs {
		assert.False(t, e.At.Before(now))
	}
}

func sh(progress, off float64, pings int) sharer {
	return sharer{Progress: progress, Off: off, Pings: pings, Accuracy: 10}
}

func TestPickGroup(t *testing.T) {
	// Two clusters: the bigger one (3) wins.
	g := pickGroup([]sharer{sh(100, 5, 1), sh(900, 5, 1), sh(5000, 5, 1), sh(5400, 5, 1), sh(5900, 5, 1)}, true)
	assert.True(t, g.OnRoute)
	assert.Equal(t, 3, g.Riders)
	assert.InDelta(t, 5400, median(progresses(g.Core)), 1e-9)

	// A tie goes to the cluster with more pings.
	g = pickGroup([]sharer{sh(100, 5, 2), sh(200, 5, 2), sh(8000, 5, 9), sh(8100, 5, 9)}, true)
	assert.InDelta(t, 8050, median(progresses(g.Core)), 1e-9)

	// Off-route sharers close to the group join it; far ones do not.
	g = pickGroup([]sharer{sh(1000, 5, 1), sh(1100, 5, 1), sh(1200, 400, 1), sh(9000, 400, 1)}, true)
	assert.True(t, g.OnRoute)
	assert.Equal(t, 2, len(g.Core))
	assert.Equal(t, 3, g.Riders)

	// Most off the route: the run is off the route.
	g = pickGroup([]sharer{sh(1000, 5, 1), sh(1100, 800, 1), sh(1200, 900, 1)}, true)
	assert.False(t, g.OnRoute)
	assert.Equal(t, 2, g.Riders)

	// GPS accuracy widens the on-route band: 1.5 x 300 = 450 m.
	s := sh(1000, 400, 1)
	s.Accuracy = 300
	assert.True(t, s.onRoute())
	s.Accuracy = 10
	assert.False(t, s.onRoute())

	// No line: everybody is one group, on the route.
	g = pickGroup([]sharer{sh(0, 0, 1), sh(0, 0, 1)}, false)
	assert.True(t, g.OnRoute)
	assert.Equal(t, 2, g.Riders)
	assert.Equal(t, 0, pickGroup(nil, true).Riders)
}

func TestFilterPoints(t *testing.T) {
	now := time.Date(2026, 10, 27, 9, 0, 0, 0, time.UTC)
	at := func(sec int, lat, lng, acc float64) fix {
		return fix{At: now.Add(time.Duration(sec) * time.Second), Pos: LatLng{Lat: lat, Lng: lng}, Accuracy: acc}
	}
	// 0.0001 degrees of latitude is about 11 m.
	pts := []fix{
		at(-700, 23.80, 90.40, 10),    // older than 10 minutes
		at(-120, 23.8000, 90.40, 10),  // kept
		at(-118, 23.8001, 90.40, 10),  // 2 s after the last kept: too close in time
		at(-110, 23.8002, 90.40, 10),  // kept (10 s later, 22 m)
		at(-100, 23.8003, 90.40, 500), // accuracy over 200 m
		at(-90, 23.9000, 90.40, 10),   // 11 km in 20 s: too fast
		at(-60, 23.8004, 90.40, 10),   // kept
		at(45, 23.8005, 90.40, 10),    // more than 30 s in the future
		at(20, 23.8006, 90.40, 10),    // kept (the batch may arrive in any order)
	}
	pts[0], pts[8] = pts[8], pts[0]
	got := filterPoints(pts, lastFix{}, now)
	var secs []int
	for _, p := range got {
		secs = append(secs, int(p.At.Sub(now).Seconds()))
	}
	assert.Equal(t, []int{-120, -110, -60, 20}, secs)

	// Against the session's previous point: a point 3 s later is dropped,
	// one 10 s later kept.
	prev := lastFix{Have: true, At: now.Add(-30 * time.Second), Pos: LatLng{Lat: 23.8, Lng: 90.4}}
	assert.Empty(t, filterPoints([]fix{at(-27, 23.8, 90.4, 10)}, prev, now))
	assert.Len(t, filterPoints([]fix{at(-20, 23.8001, 90.4, 10)}, prev, now), 1)
	assert.Empty(t, filterPoints([]fix{at(-40, 23.8001, 90.4, 10)}, prev, now), "older than the last kept point")
}

func TestSmoothSpeed(t *testing.T) {
	assert.Equal(t, 6.0, smoothSpeed(nil, 6))
	prev := 4.0
	assert.Equal(t, 6.0, smoothSpeed(&prev, 8))
}

func TestTripWindow(t *testing.T) {
	dep, span := 7*60+30, 50
	assert.False(t, inTripWindow(float64(dep-31), dep, span))
	assert.True(t, inTripWindow(float64(dep-30), dep, span))
	assert.True(t, inTripWindow(float64(dep+span+90), dep, span))
	assert.False(t, inTripWindow(float64(dep+span+91), dep, span))
}

func TestBusNearNotice(t *testing.T) {
	n := busNearNotice("Route 1", "Mirpur 10", 12, 3, uuid.Nil, uuid.Nil)
	assert.Equal(t, "Bus coming: Route 1", n.Texts["en"].Title)
	assert.Equal(t, "About 12 min from Mirpur 10 · 3 sharing live", n.Texts["en"].Body)
	assert.Equal(t, "বাস আসছে: Route 1", n.Texts["bn"].Title)
	assert.Contains(t, n.Texts["bn"].Body, "১২")
	assert.Contains(t, n.Texts["bn"].Body, "৩ ")
	assert.NotRegexp(t, "[0-9]", strings.ReplaceAll(n.Texts["bn"].Body, "Mirpur 10", ""))
	assert.Equal(t, "bus_near", n.Data["type"])
}
