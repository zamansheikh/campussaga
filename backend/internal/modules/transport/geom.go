package transport

import (
	"math"
	"slices"
	"sort"
	"time"

	"github.com/google/uuid"
)

// The maths of live buses: where a point is along a route line, which stops
// are ahead, and when the bus gets to them. No database in here.

const earthRadius = 6371000.0 // metres

// metres is the local flat-earth offset of b from a (x east, y north); good
// at the scale of a city.
func metres(a, b LatLng) (x, y float64) {
	k := math.Pi / 180 * earthRadius
	return (b.Lng - a.Lng) * k * math.Cos(a.Lat*math.Pi/180), (b.Lat - a.Lat) * k
}

func distance(a, b LatLng) float64 {
	x, y := metres(a, b)
	return math.Hypot(x, y)
}

// decodePolyline reads an encoded polyline (precision 5). It fails on
// anything that is not one (text, out-of-range coordinates).
func decodePolyline(s string) ([]LatLng, bool) {
	var out []LatLng
	var lat, lng int
	i := 0
	next := func() (int, bool) {
		shift, v := 0, 0
		for {
			if i >= len(s) || shift > 30 {
				return 0, false
			}
			b := int(s[i]) - 63
			i++
			if b < 0 || b > 63 {
				return 0, false
			}
			v |= (b & 0x1f) << shift
			shift += 5
			if b < 0x20 {
				break
			}
		}
		if v&1 != 0 {
			return ^(v >> 1), true
		}
		return v >> 1, true
	}
	for i < len(s) {
		dlat, ok := next()
		if !ok {
			return nil, false
		}
		dlng, ok := next()
		if !ok {
			return nil, false
		}
		lat, lng = lat+dlat, lng+dlng
		p := LatLng{Lat: float64(lat) / 1e5, Lng: float64(lng) / 1e5}
		if p.Lat < -90 || p.Lat > 90 || p.Lng < -180 || p.Lng > 180 {
			return nil, false
		}
		out = append(out, p)
	}
	return out, len(out) > 0
}

// routeLine is a route's line from the far end to campus.
type routeLine struct {
	pts    []LatLng
	cum    []float64 // metres from the start to each point
	length float64
}

// newLine is nil when the points make no line (fewer than 2, or all on one spot).
func newLine(pts []LatLng) *routeLine {
	if len(pts) < 2 {
		return nil
	}
	l := &routeLine{pts: pts, cum: make([]float64, len(pts))}
	for i := 1; i < len(pts); i++ {
		l.cum[i] = l.cum[i-1] + distance(pts[i-1], pts[i])
	}
	l.length = l.cum[len(pts)-1]
	if l.length < 1 {
		return nil
	}
	return l
}

// project: metres along the line to the point nearest p, and how far p is
// from the line.
func (l *routeLine) project(p LatLng) (progress, off float64) {
	off = math.Inf(1)
	for i := 0; i+1 < len(l.pts); i++ {
		ax, ay := metres(p, l.pts[i])
		bx, by := metres(p, l.pts[i+1])
		dx, dy := bx-ax, by-ay
		t := 0.0
		if d2 := dx*dx + dy*dy; d2 > 0 {
			t = math.Max(0, math.Min(1, -(ax*dx+ay*dy)/d2))
		}
		if d := math.Hypot(ax+t*dx, ay+t*dy); d < off {
			off, progress = d, l.cum[i]+t*(l.cum[i+1]-l.cum[i])
		}
	}
	return progress, off
}

// at is the point progress metres along the line.
func (l *routeLine) at(progress float64) LatLng {
	progress = math.Max(0, math.Min(l.length, progress))
	i := sort.SearchFloat64s(l.cum, progress)
	if i == 0 {
		return l.pts[0]
	}
	seg := l.cum[i] - l.cum[i-1]
	if seg <= 0 {
		return l.pts[i]
	}
	t := (progress - l.cum[i-1]) / seg
	a, b := l.pts[i-1], l.pts[i]
	return LatLng{Lat: a.Lat + t*(b.Lat-a.Lat), Lng: a.Lng + t*(b.Lng-a.Lng)}
}

// along turns progress on the line (to-campus order) into progress in a
// direction of travel, and back (it is its own inverse).
func (l *routeLine) along(direction string, progress float64) float64 {
	if direction == FromCampus {
		return l.length - progress
	}
	return progress
}

// ---- stops and the timetable -----------------------------------------------

// dirStop is a placed stop as seen travelling one way.
type dirStop struct {
	ID   uuid.UUID
	Name string
	Prog float64 // metres along, in the direction of travel
	Min  int     // minutes after the trip starts; -1: the bus does not stop here this way
}

// servedStops: the stops the bus stops at, or all of them when the timetable
// gives no offsets this way.
func servedStops(stops []dirStop) []dirStop {
	served := slices.DeleteFunc(slices.Clone(stops), func(s dirStop) bool { return s.Min < 0 })
	if len(served) == 0 {
		return stops
	}
	return served
}

// scheduledMinute: the minute after the trip starts at which the timetable
// has the bus at prog, between the neighbouring timed stops. False when
// fewer than two stops are timed.
func scheduledMinute(stops []dirStop, prog float64) (float64, bool) {
	var timed []dirStop
	for _, s := range stops {
		if s.Min >= 0 {
			timed = append(timed, s)
		}
	}
	if len(timed) < 2 {
		return 0, false
	}
	if prog <= timed[0].Prog {
		return float64(timed[0].Min), true
	}
	for i := 1; i < len(timed); i++ {
		a, b := timed[i-1], timed[i]
		if prog < b.Prog {
			if b.Prog <= a.Prog {
				return float64(a.Min), true
			}
			t := (prog - a.Prog) / (b.Prog - a.Prog)
			return float64(a.Min) + t*float64(b.Min-a.Min), true
		}
	}
	return float64(timed[len(timed)-1].Min), true
}

// delayMinutes: minutes the bus is late (negative: early) when it is at
// scheduled minute sched of a trip that left at departs (minutes after
// midnight) on the service day starting at dayStart.
func delayMinutes(now, dayStart time.Time, departs int, sched float64) int {
	due := dayStart.Add(time.Duration((float64(departs) + sched) * float64(time.Minute)))
	return int(math.Round(now.Sub(due).Minutes()))
}

type eta struct {
	StopID uuid.UUID `json:"stopId"`
	At     time.Time `json:"at"`
}

// progressNote is what a run at some progress knows about the stops.
type progressNote struct {
	Passed []dirStop // behind the bus (by 30 m)
	Next   *dirStop  // the first stop not passed
	ETAs   []eta     // stops more than 50 m ahead
}

const (
	passedBy = 30.0 // metres past a stop before it counts as passed
	aheadBy  = 50.0 // metres before a stop counts as ahead (for an ETA)
)

// noteStops works out passed stops, the next stop and ETAs for a bus at prog
// moving at speed m/s. An ETA is the timetable's time between here and the
// stop when it has one, else the distance at the bus's speed (3-15 m/s, 5
// when it is not moving or unknown). Never before now.
func noteStops(stops []dirStop, prog, speed float64, now time.Time) progressNote {
	var n progressNote
	n.ETAs = []eta{}
	sched, haveSched := scheduledMinute(stops, prog)
	v := speed
	if v < 1 {
		v = 5
	}
	v = math.Max(3, math.Min(15, v))
	for _, s := range servedStops(stops) {
		if s.Prog+passedBy <= prog {
			n.Passed = append(n.Passed, s)
			continue
		}
		if n.Next == nil {
			s := s
			n.Next = &s
		}
		if s.Prog <= prog+aheadBy {
			continue
		}
		at := now.Add(time.Duration((s.Prog - prog) / v * float64(time.Second)))
		if haveSched && s.Min >= 0 {
			at = now.Add(time.Duration((float64(s.Min) - sched) * float64(time.Minute)))
		}
		if at.Before(now) {
			at = now
		}
		n.ETAs = append(n.ETAs, eta{StopID: s.ID, At: at})
	}
	return n
}

// ---- who is on the bus -------------------------------------------------------

// sharer is one student's last known place on a run.
type sharer struct {
	Pos      LatLng
	Accuracy float64
	Progress float64 // in the direction of travel
	Off      float64 // metres from the line
	Speed    float64 // m/s; 0 when unknown
	Pings    int
}

// onRoute: within 150 m of the line, or 1.5 times the GPS accuracy.
func (s sharer) onRoute() bool { return s.Off <= math.Max(150, 1.5*s.Accuracy) }

const (
	clusterGap = 1500.0 // metres between sharers that still ride the same bus
)

// busGroup is the sharers that make up a run.
type busGroup struct {
	Core    []sharer // the sharers the position comes from
	Riders  int      // the core plus off-route sharers close to it
	OnRoute bool
}

// pickGroup chooses the sharers that are the bus: when most are off the
// route, those; else the biggest cluster of on-route sharers (tie: the one
// with the most pings), with off-route sharers within 1500 m of its median
// joining it. Without a line (hasLine false) everybody is one group.
func pickGroup(all []sharer, hasLine bool) busGroup {
	if len(all) == 0 {
		return busGroup{}
	}
	if !hasLine {
		return busGroup{Core: all, Riders: len(all), OnRoute: true}
	}
	var on, off []sharer
	for _, s := range all {
		if s.onRoute() {
			on = append(on, s)
		} else {
			off = append(off, s)
		}
	}
	if len(off) > len(on) {
		return busGroup{Core: off, Riders: len(off)}
	}
	slices.SortFunc(on, func(a, b sharer) int { return cmpFloat(a.Progress, b.Progress) })
	var best []sharer
	bestPings := -1
	for start := 0; start < len(on); {
		end, pings := start+1, on[start].Pings
		for end < len(on) && on[end].Progress-on[end-1].Progress <= clusterGap {
			pings += on[end].Pings
			end++
		}
		if n := end - start; n > len(best) || (n == len(best) && pings > bestPings) {
			best, bestPings = on[start:end], pings
		}
		start = end
	}
	med := median(progresses(best))
	g := busGroup{Core: best, Riders: len(best), OnRoute: true}
	for _, s := range off {
		if math.Abs(s.Progress-med) <= clusterGap {
			g.Riders++
		}
	}
	return g
}

func cmpFloat(a, b float64) int {
	switch {
	case a < b:
		return -1
	case a > b:
		return 1
	}
	return 0
}

func progresses(ss []sharer) []float64 {
	out := make([]float64, len(ss))
	for i, s := range ss {
		out[i] = s.Progress
	}
	return out
}

func median(v []float64) float64 {
	if len(v) == 0 {
		return 0
	}
	v = slices.Clone(v)
	slices.Sort(v)
	if n := len(v); n%2 == 0 {
		return (v[n/2-1] + v[n/2]) / 2
	}
	return v[len(v)/2]
}

// ---- points ------------------------------------------------------------------

// fix is one reported point.
type fix struct {
	At       time.Time
	Pos      LatLng
	Accuracy float64
	Speed    *float64
	Heading  *float64
}

// lastFix is the previous kept point of a session.
type lastFix struct {
	Have bool
	At   time.Time
	Pos  LatLng
}

const (
	maxPointAge   = 10 * time.Minute
	maxPointAhead = 30 * time.Second
	minPointGap   = 5 * time.Second
	maxAccuracy   = 200.0
	maxSpeed      = 120 / 3.6 // m/s
)

// filterPoints keeps, oldest first, the points worth keeping: not older
// than 10 minutes or more than 30 s ahead, at least 5 s after the previous
// kept point, accurate to 200 m, and not implying over 120 km/h.
func filterPoints(pts []fix, prev lastFix, now time.Time) []fix {
	pts = slices.Clone(pts)
	slices.SortStableFunc(pts, func(a, b fix) int { return a.At.Compare(b.At) })
	var kept []fix
	for _, p := range pts {
		switch {
		case now.Sub(p.At) > maxPointAge, p.At.Sub(now) > maxPointAhead, p.Accuracy > maxAccuracy:
			continue
		}
		if prev.Have {
			dt := p.At.Sub(prev.At)
			if dt < minPointGap || distance(prev.Pos, p.Pos)/dt.Seconds() > maxSpeed {
				continue
			}
		}
		kept = append(kept, p)
		prev = lastFix{Have: true, At: p.At, Pos: p.Pos}
	}
	return kept
}

// smoothSpeed blends a new speed reading into the running one.
func smoothSpeed(prev *float64, reading float64) float64 {
	if prev == nil {
		return reading
	}
	return 0.5**prev + 0.5*reading
}
