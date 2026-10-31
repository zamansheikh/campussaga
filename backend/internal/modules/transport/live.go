package transport

import (
	"context"
	"fmt"
	"math"
	"slices"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"

	"github.com/zamansheikh/varsitykotha/backend/internal/modules/transport/store"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/apperr"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/auth"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/db"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/httpx"
)

// Live buses (docs/BUS_LIVE.md): a student on a bus shares where it is;
// everyone on the route sees the run's combined position, never who shares.

const (
	freshFor        = 2 * time.Minute  // a sharer is current this long after their last point
	sessionLimit    = 8                // shares a student may start per day
	maxSessionAge   = 3 * time.Hour    // then the server ends it
	shareRadius     = 600.0            // metres from the line to start sharing
	arriveWithin    = 150.0            // metres from the end of the line: arrived
	offRouteFar     = 1000.0           // metres from the line...
	offRouteFor     = 10 * time.Minute // ...for this long ends the share
	windowBefore    = 30               // minutes before a departure a share may start
	windowAfter     = 90               // minutes after the last stop
	minStatsPings   = 3                // a share counts as a trip with this many points...
	minStatsElapsed = 2 * time.Minute  // ...over this long
)

var (
	ErrSessionNotFound = apperr.New(404, "SESSION_NOT_FOUND", "This live share was not found")
	ErrTripNotRunning  = apperr.New(409, "TRIP_NOT_RUNNING", "That bus is not running now")
	ErrNotOnRoute      = apperr.New(409, "NOT_ON_ROUTE", "You are not on this bus route")
	ErrShareLimit      = apperr.New(429, "SHARE_LIMIT", "You have shared the most buses allowed today")
)

var dhaka = mustZone("Asia/Dhaka")

func mustZone(name string) *time.Location {
	l, err := time.LoadLocation(name)
	if err != nil {
		return time.FixedZone(name, 6*3600)
	}
	return l
}

func (s *Service) liveRoutes(r *httpx.Router) {
	st := r.Student()
	read := st.With(r.LimitUser("transport-live-read", 900, time.Hour))
	read.Get("/transport/routes/{id}/live", httpx.Handle(s.handleLive))
	read.Get("/transport/live", httpx.Handle(s.handleLiveAll))
	read.Get("/transport/routes/{id}/insights", httpx.Handle(s.handleInsights))
	read.Get("/transport/alerts", httpx.Handle(s.handleAlerts))
	write := st.With(r.LimitUser("transport-live-write", 120, time.Hour))
	write.Post("/transport/routes/{id}/live/share", httpx.Handle(s.handleShare, httpx.Status(201)))
	write.Post("/transport/live/{session}/stop", httpx.Handle(s.handleStopShare))
	write.Post("/transport/routes/{id}/feedback", httpx.Handle(s.handleFeedback))
	write.Put("/transport/routes/{id}/alert", httpx.Handle(s.handleSetAlert))
	write.Delete("/transport/routes/{id}/alert", httpx.Handle(s.handleDeleteAlert, httpx.NoContent()))
	st.With(r.LimitUser("transport-live-pings", 400, time.Hour)).
		Post("/transport/live/{session}/pings", httpx.Handle(s.handlePings))
}

// ---- dates -------------------------------------------------------------------

const dateLayout = "2006-01-02"

// serviceDay is the Bangladesh date of t and its midnight there.
func serviceDay(t time.Time) (string, time.Time) {
	t = t.In(dhaka)
	return t.Format(dateLayout), time.Date(t.Year(), t.Month(), t.Day(), 0, 0, 0, 0, dhaka)
}

func dayStart(date string) time.Time {
	t, _ := time.ParseInLocation(dateLayout, date, dhaka)
	return t
}

func pgDate(date string) pgtype.Date {
	t, _ := time.Parse(dateLayout, date)
	return pgtype.Date{Time: t, Valid: true}
}

func dateText(d pgtype.Date) string { return d.Time.Format(dateLayout) }

// minuteOfDay: minutes after midnight in Dhaka, with seconds as a fraction.
func minuteOfDay(t time.Time) float64 {
	t = t.In(dhaka)
	return float64(t.Hour()*60+t.Minute()) + float64(t.Second())/60
}

// isoWeekday: 1 = Monday ... 7 = Sunday, in Dhaka.
func isoWeekday(t time.Time) int16 {
	if w := t.In(dhaka).Weekday(); w != time.Sunday {
		return int16(w)
	}
	return 7
}

func departsText(d int16) *string {
	if d < 0 {
		return nil
	}
	c := clock(d)
	return &c
}

func f32(v float64) *float32 { x := float32(v); return &x }

// ---- the route as geometry ---------------------------------------------------

type geoStop struct {
	ID       uuid.UUID
	Name     string
	Prog     float64 // metres along the line, to-campus order; -1: not placed or no line
	To, From int     // minute offsets, -1: the bus does not stop here that way
}

// routeGeo is what live buses need to know about a route, cached until the
// route changes.
type routeGeo struct {
	updated time.Time
	line    *routeLine // nil: no line (fewer than 2 placed stops and no path)
	stops   []geoStop
	span    map[string]int // largest stop offset per direction
}

func offset(m *int16) int {
	if m == nil {
		return -1
	}
	return int(*m)
}

func (s *Service) geoOf(ctx context.Context, q *store.Queries, r store.BusRoute) (*routeGeo, error) {
	if v, ok := s.geos.Load(r.ID); ok && v.(*routeGeo).updated.Equal(r.UpdatedAt) {
		return v.(*routeGeo), nil
	}
	rows, err := q.StopsOfRoute(ctx, r.ID)
	if err != nil {
		return nil, err
	}
	g := &routeGeo{updated: r.UpdatedAt, span: map[string]int{ToCampus: 0, FromCampus: 0}}
	var placed []LatLng
	for _, st := range rows {
		gs := geoStop{ID: st.ID, Name: st.Name, Prog: -1, To: offset(st.ToCampusMin), From: offset(st.FromCampusMin)}
		g.stops = append(g.stops, gs)
		g.span[ToCampus] = max(g.span[ToCampus], gs.To)
		g.span[FromCampus] = max(g.span[FromCampus], gs.From)
		if p := latLng(st.Lat, st.Lng); p != nil {
			placed = append(placed, *p)
		}
	}
	if r.Path != nil {
		if pts, ok := decodePolyline(*r.Path); ok {
			g.line = newLine(pts)
		}
	}
	if g.line == nil {
		g.line = newLine(placed)
	}
	if g.line != nil {
		for i, st := range rows {
			if p := latLng(st.Lat, st.Lng); p != nil {
				g.stops[i].Prog, _ = g.line.project(*p)
			}
		}
	}
	s.geos.Store(r.ID, g)
	return g, nil
}

// dirStops: the placed stops in the order the bus meets them.
func (g *routeGeo) dirStops(direction string) []dirStop {
	if g.line == nil {
		return nil
	}
	var out []dirStop
	for _, st := range g.stops {
		if st.Prog < 0 {
			continue
		}
		m := st.To
		if direction == FromCampus {
			m = st.From
		}
		out = append(out, dirStop{ID: st.ID, Name: st.Name, Prog: g.line.along(direction, st.Prog), Min: m})
	}
	slices.SortStableFunc(out, func(a, b dirStop) int { return cmpFloat(a.Prog, b.Prog) })
	return out
}

func (g *routeGeo) stopName(id uuid.UUID) string {
	for _, st := range g.stops {
		if st.ID == id {
			return st.Name
		}
	}
	return ""
}

// ---- runs --------------------------------------------------------------------

type runKey struct {
	Direction string
	Date      string // service date, YYYY-MM-DD
	Departs   int16
}

func keyOf(se store.BusLiveSession) runKey {
	return runKey{Direction: se.Direction, Date: dateText(se.ServiceDate), Departs: se.Departs}
}

// liveRun is one bus on the road, as the app gets it.
type liveRun struct {
	Direction  string      `json:"direction"`
	Departs    *string     `json:"departs"`
	Riders     int         `json:"riders"`
	Position   LatLng      `json:"position"`
	OnRoute    bool        `json:"onRoute"`
	Progress   float64     `json:"progress"`
	Length     float64     `json:"length"`
	Speed      float64     `json:"speed"`
	DelayMin   *int        `json:"delayMin"`
	NextStopID *uuid.UUID  `json:"nextStopId"`
	Passed     []uuid.UUID `json:"passed"`
	ETAs       []eta       `json:"etas"`
	UpdatedAt  time.Time   `json:"updatedAt"`
	Mine       bool        `json:"mine"`

	key    runKey
	passed []dirStop
}

func sharerOf(se store.BusLiveSession) (sharer, bool) {
	if se.LastLat == nil || se.LastLng == nil {
		return sharer{}, false
	}
	sh := sharer{Pos: LatLng{Lat: *se.LastLat, Lng: *se.LastLng}, Pings: int(se.Pings)}
	if se.LastAccuracy != nil {
		sh.Accuracy = float64(*se.LastAccuracy)
	}
	if se.LastProgress != nil {
		sh.Progress = float64(*se.LastProgress)
	}
	if se.LastOff != nil {
		sh.Off = float64(*se.LastOff)
	}
	if se.Speed != nil {
		sh.Speed = float64(*se.Speed)
	}
	return sh, true
}

func medianPos(ss []sharer) LatLng {
	lat, lng := make([]float64, len(ss)), make([]float64, len(ss))
	for i, s := range ss {
		lat[i], lng[i] = s.Pos.Lat, s.Pos.Lng
	}
	return LatLng{Lat: median(lat), Lng: median(lng)}
}

// buildRun works out a run from the sharers on it (3.4 of the spec).
func buildRun(geo *routeGeo, k runKey, ss []sharer, updated, now time.Time) *liveRun {
	g := pickGroup(ss, geo.line != nil)
	run := &liveRun{
		Direction: k.Direction, Departs: departsText(k.Departs), Riders: g.Riders, OnRoute: g.OnRoute,
		Passed: []uuid.UUID{}, ETAs: []eta{}, UpdatedAt: updated, key: k,
	}
	speeds := make([]float64, len(g.Core))
	for i, s := range g.Core {
		speeds[i] = s.Speed
	}
	run.Speed = median(speeds)
	run.Position = medianPos(g.Core)
	if geo.line == nil {
		return run
	}
	run.Length = geo.line.length
	run.Progress = median(progresses(g.Core))
	if !g.OnRoute {
		return run
	}
	run.Position = geo.line.at(geo.line.along(k.Direction, run.Progress))
	stops := geo.dirStops(k.Direction)
	n := noteStops(stops, run.Progress, run.Speed, now)
	run.ETAs, run.passed = n.ETAs, n.Passed
	for _, p := range n.Passed {
		run.Passed = append(run.Passed, p.ID)
	}
	if n.Next != nil {
		run.NextStopID = &n.Next.ID
	}
	if k.Departs >= 0 {
		if sched, ok := scheduledMinute(stops, run.Progress); ok {
			d := delayMinutes(now, dayStart(k.Date), int(k.Departs), sched)
			run.DelayMin = &d
		}
	}
	return run
}

// runsOf builds the live runs of one route from its sharers heard from in
// the last two minutes, ordered by direction and departure.
func (s *Service) runsOf(ctx context.Context, q *store.Queries, geo *routeGeo, sessions []store.BusLiveSession, now time.Time) []*liveRun {
	by := map[runKey][]sharer{}
	updated := map[runKey]time.Time{}
	for _, se := range sessions {
		sh, ok := sharerOf(se)
		if !ok {
			continue
		}
		k := keyOf(se)
		by[k] = append(by[k], sh)
		if se.LastAt.After(updated[k]) {
			updated[k] = se.LastAt
		}
	}
	runs := make([]*liveRun, 0, len(by))
	for k, ss := range by {
		runs = append(runs, buildRun(geo, k, ss, updated[k], now))
	}
	slices.SortFunc(runs, func(a, b *liveRun) int {
		return strings.Compare(fmt.Sprintf("%s %05d %s", a.key.Direction, a.key.Departs+1, a.key.Date),
			fmt.Sprintf("%s %05d %s", b.key.Direction, b.key.Departs+1, b.key.Date))
	})
	return runs
}

func (s *Service) freshSessions(ctx context.Context, q *store.Queries, route *uuid.UUID, now time.Time) ([]store.BusLiveSession, error) {
	return q.FreshSessions(ctx, store.FreshSessionsParams{Since: now.Add(-freshFor), RouteID: route})
}

// ---- reading -----------------------------------------------------------------

type mySession struct {
	ID        uuid.UUID `json:"id"`
	Direction string    `json:"direction"`
	Departs   *string   `json:"departs"`
}

type liveRes struct {
	Runs      []*liveRun `json:"runs"`
	MySession *mySession `json:"mySession"`
}

// liveFor is the live view of a route for a student; it notes that they looked.
func (s *Service) liveFor(ctx context.Context, q *store.Queries, route store.BusRoute, user uuid.UUID, now time.Time) (*liveRes, error) {
	geo, err := s.geoOf(ctx, q, route)
	if err != nil {
		return nil, err
	}
	sessions, err := s.freshSessions(ctx, q, &route.ID, now)
	if err != nil {
		return nil, err
	}
	out := &liveRes{Runs: s.runsOf(ctx, q, geo, sessions, now)}
	mine, err := q.MyOpenSession(ctx, store.MyOpenSessionParams{UserID: user, RouteID: route.ID})
	if err != nil && !db.IsNoRows(err) {
		return nil, err
	}
	if err == nil {
		out.MySession = &mySession{ID: mine.ID, Direction: mine.Direction, Departs: departsText(mine.Departs)}
	}
	for _, run := range out.Runs {
		run.Mine = out.MySession != nil && keyOf(mine) == run.key
		err := q.UpsertLiveView(ctx, store.UpsertLiveViewParams{
			RouteID: route.ID, Direction: run.key.Direction, ServiceDate: pgDate(run.key.Date),
			Departs: run.key.Departs, UserID: user, Now: now,
		})
		if err != nil {
			return nil, err
		}
	}
	return out, nil
}

// liveRoute: an active route the caller may read.
func (s *Service) liveRoute(ctx context.Context, q *store.Queries, id string) (store.BusRoute, error) {
	r, err := s.readableRoute(ctx, q, uuid.MustParse(id))
	if err == nil && !r.Active {
		err = ErrRouteNotFound
	}
	return r, err
}

func (s *Service) handleLive(ctx context.Context, in *routeReq) (*liveRes, error) {
	q := store.New(s.d.Q(ctx))
	r, err := s.liveRoute(ctx, q, in.ID)
	if err != nil {
		return nil, err
	}
	return s.liveFor(ctx, q, r, auth.MustUser(ctx).UserID, s.now())
}

type liveBadge struct {
	RouteID uuid.UUID `json:"routeId"`
	Runs    int       `json:"runs"`
	Riders  int       `json:"riders"`
}

type liveAllRes struct {
	Routes []liveBadge `json:"routes"`
}

// handleLiveAll: which routes of the caller's university have a bus live.
func (s *Service) handleLiveAll(ctx context.Context, _ *httpx.Empty) (*liveAllRes, error) {
	c := auth.MustUser(ctx)
	out := &liveAllRes{Routes: []liveBadge{}}
	if c.UniversityID == uuid.Nil {
		return out, nil
	}
	q := store.New(s.d.Q(ctx))
	now := s.now()
	sessions, err := q.FreshSessionsOfUniversity(ctx, store.FreshSessionsOfUniversityParams{Since: now.Add(-freshFor), UniversityID: c.UniversityID})
	if err != nil {
		return nil, err
	}
	byRoute := map[uuid.UUID][]store.BusLiveSession{}
	for _, se := range sessions {
		byRoute[se.RouteID] = append(byRoute[se.RouteID], se)
	}
	for id, ss := range byRoute {
		r, err := q.GetRoute(ctx, id)
		if err != nil {
			return nil, err
		}
		geo, err := s.geoOf(ctx, q, r)
		if err != nil {
			return nil, err
		}
		b := liveBadge{RouteID: id}
		for _, run := range s.runsOf(ctx, q, geo, ss, now) {
			b.Runs++
			b.Riders += run.Riders
		}
		if b.Runs > 0 {
			out.Routes = append(out.Routes, b)
		}
	}
	slices.SortFunc(out.Routes, func(a, b liveBadge) int { return strings.Compare(a.RouteID.String(), b.RouteID.String()) })
	return out, nil
}

// ---- sharing -----------------------------------------------------------------

type shareReq struct {
	routeReq
	Direction string   `json:"direction" validate:"required,oneof=to_campus from_campus"`
	Departs   *string  `json:"departs"`
	Lat       *float64 `json:"lat" validate:"required,min=-90,max=90"`
	Lng       *float64 `json:"lng" validate:"required,min=-180,max=180"`
	Accuracy  float64  `json:"accuracy" validate:"min=0,max=100000"`
}

type shareRes struct {
	SessionID uuid.UUID `json:"sessionId"`
	Live      *liveRes  `json:"live"`
}

// inTripWindow: now (minutes after midnight) is from 30 minutes before a
// departure to 90 minutes after the trip's last stop.
func inTripWindow(nowMin float64, departs, span int) bool {
	return nowMin >= float64(departs-windowBefore) && nowMin <= float64(departs+span+windowAfter)
}

func (s *Service) handleShare(ctx context.Context, in *shareReq) (*shareRes, error) {
	c := auth.MustUser(ctx)
	departs := int16(-1)
	if in.Departs != nil {
		d, ok := parseClock(*in.Departs)
		if !ok {
			return nil, apperr.Validation(map[string]string{"departs": "must be a time like 07:30"})
		}
		departs = d
	}
	var res *shareRes
	err := s.d.InTx(ctx, func(ctx context.Context) error {
		q := store.New(s.d.Q(ctx))
		route, err := s.liveRoute(ctx, q, in.ID)
		if err != nil {
			return err
		}
		now := s.now()
		date, midnight := serviceDay(now)
		geo, err := s.geoOf(ctx, q, route)
		if err != nil {
			return err
		}
		if departs >= 0 {
			trips, err := q.TripsForRoutes(ctx, []uuid.UUID{route.ID})
			if err != nil {
				return err
			}
			day := isoWeekday(now)
			running := slices.ContainsFunc(trips, func(t store.BusTrip) bool {
				return t.Direction == in.Direction && t.DepartsMin == departs && slices.Contains(t.Weekdays, day)
			})
			if !running || !inTripWindow(minuteOfDay(now), int(departs), geo.span[in.Direction]) {
				return ErrTripNotRunning
			}
		}
		pos := LatLng{Lat: *in.Lat, Lng: *in.Lng}
		var progress, off *float32
		if geo.line != nil {
			p, o := geo.line.project(pos)
			if o > shareRadius {
				return ErrNotOnRoute
			}
			progress, off = f32(geo.line.along(in.Direction, p)), f32(o)
		}
		n, err := q.CountSessionsSince(ctx, store.CountSessionsSinceParams{UserID: c.UserID, Since: midnight})
		if err != nil {
			return err
		}
		if n >= sessionLimit {
			return ErrShareLimit
		}
		old, err := q.OpenSessionOfUser(ctx, c.UserID)
		if err == nil {
			if _, err := s.endSession(ctx, q, old, "replaced", now); err != nil {
				return err
			}
		} else if !db.IsNoRows(err) {
			return err
		}
		se, err := q.InsertLiveSession(ctx, store.InsertLiveSessionParams{
			RouteID: route.ID, UserID: c.UserID, Direction: in.Direction, ServiceDate: pgDate(date), Departs: departs,
			Now: now, Lat: in.Lat, Lng: in.Lng, Accuracy: f32(in.Accuracy), Progress: progress, Off: off,
		})
		if err != nil {
			return err
		}
		err = q.InsertLivePing(ctx, store.InsertLivePingParams{
			SessionID: se.ID, At: now, Lat: pos.Lat, Lng: pos.Lng, Accuracy: f32(in.Accuracy), Progress: progress, Off: off,
		})
		if err != nil {
			return err
		}
		live, err := s.liveFor(ctx, q, route, c.UserID, now)
		if err != nil {
			return err
		}
		for _, run := range live.Runs {
			if run.key == keyOf(se) {
				if err := s.afterUpdate(ctx, q, route, geo, run, now); err != nil {
					return err
				}
			}
		}
		res = &shareRes{SessionID: se.ID, Live: live}
		return nil
	})
	return res, err
}

// endSession closes an open session and, for a real trip, adds it to the
// sharer's totals. False when it was already closed.
func (s *Service) endSession(ctx context.Context, q *store.Queries, se store.BusLiveSession, reason string, at time.Time) (bool, error) {
	row, err := q.EndLiveSession(ctx, store.EndLiveSessionParams{ID: se.ID, Now: &at, Reason: &reason})
	if db.IsNoRows(err) {
		return false, nil
	}
	if err != nil {
		return false, err
	}
	if row.Pings < minStatsPings || at.Sub(row.StartedAt) < minStatsElapsed {
		return true, nil
	}
	helped, err := s.viewers(ctx, q, row)
	if err != nil {
		return false, err
	}
	_, err = q.AddShareStats(ctx, store.AddShareStatsParams{UserID: row.UserID, Helped: int32(helped)})
	return true, err
}

// viewers: students other than the sharer who looked at the run while the
// session was open.
func (s *Service) viewers(ctx context.Context, q *store.Queries, se store.BusLiveSession) (int64, error) {
	to := s.now()
	if se.EndedAt != nil {
		to = *se.EndedAt
	}
	return q.CountViewers(ctx, store.CountViewersParams{
		RouteID: se.RouteID, Direction: se.Direction, ServiceDate: se.ServiceDate, Departs: se.Departs,
		Sharer: se.UserID, FromAt: se.StartedAt, ToAt: to,
	})
}

type sessionReq struct {
	Session string `json:"-" path:"session" validate:"required,uuid"`
}

type stopRes struct {
	Helped int `json:"helped"`
	Trips  int `json:"trips"`
}

// handleStopShare ends the caller's share (if it is still open) and says how
// many students saw the bus. It works on a share the server already ended,
// and twice, without counting the trip twice.
func (s *Service) handleStopShare(ctx context.Context, in *sessionReq) (*stopRes, error) {
	c := auth.MustUser(ctx)
	var res *stopRes
	err := s.d.InTx(ctx, func(ctx context.Context) error {
		q := store.New(s.d.Q(ctx))
		se, err := q.GetLiveSessionForUpdate(ctx, uuid.MustParse(in.Session))
		if db.IsNoRows(err) || (err == nil && se.UserID != c.UserID) {
			return ErrSessionNotFound
		}
		if err != nil {
			return err
		}
		if se.EndedAt == nil {
			now := s.now()
			if _, err := s.endSession(ctx, q, se, "stopped", now); err != nil {
				return err
			}
			se.EndedAt = &now
		}
		helped, err := s.viewers(ctx, q, se)
		if err != nil {
			return err
		}
		st, err := q.GetShareStats(ctx, c.UserID)
		if err != nil && !db.IsNoRows(err) {
			return err
		}
		res = &stopRes{Helped: int(helped), Trips: int(st.Trips)}
		return nil
	})
	return res, err
}

// ---- pings -------------------------------------------------------------------

type pingPoint struct {
	At       time.Time `json:"at" validate:"required"`
	Lat      float64   `json:"lat" validate:"min=-90,max=90"`
	Lng      float64   `json:"lng" validate:"min=-180,max=180"`
	Accuracy float64   `json:"accuracy" validate:"min=0,max=100000"`
	Speed    *float64  `json:"speed"`
	Heading  *float64  `json:"heading"`
}

type pingsReq struct {
	sessionReq
	Points []pingPoint `json:"points" validate:"required,min=1,max=30,dive"`
}

type pingsRes struct {
	Ended  bool    `json:"ended"`
	Reason *string `json:"reason"`
	Riders int     `json:"riders"`
}

func (s *Service) handlePings(ctx context.Context, in *pingsReq) (*pingsRes, error) {
	c := auth.MustUser(ctx)
	var res *pingsRes
	err := s.d.InTx(ctx, func(ctx context.Context) error {
		q := store.New(s.d.Q(ctx))
		se, err := q.GetLiveSessionForUpdate(ctx, uuid.MustParse(in.Session))
		if db.IsNoRows(err) || (err == nil && se.UserID != c.UserID) {
			return ErrSessionNotFound
		}
		if err != nil {
			return err
		}
		if se.EndedAt != nil {
			res = &pingsRes{Ended: true, Reason: se.EndReason}
			return nil
		}
		now := s.now()
		if now.Sub(se.StartedAt) > maxSessionAge {
			if _, err := s.endSession(ctx, q, se, "expired", now); err != nil {
				return err
			}
			res = &pingsRes{Ended: true, Reason: ptr("expired")}
			return nil
		}
		route, err := q.GetRoute(ctx, se.RouteID)
		if err != nil {
			return err
		}
		geo, err := s.geoOf(ctx, q, route)
		if err != nil {
			return err
		}
		fixes := make([]fix, len(in.Points))
		for i, p := range in.Points {
			fixes[i] = fix{At: p.At, Pos: LatLng{Lat: p.Lat, Lng: p.Lng}, Accuracy: p.Accuracy, Speed: p.Speed, Heading: p.Heading}
		}
		prev := lastFix{}
		if se.LastLat != nil && se.LastLng != nil {
			prev = lastFix{Have: true, At: se.LastAt, Pos: LatLng{Lat: *se.LastLat, Lng: *se.LastLng}}
		}
		kept := filterPoints(fixes, prev, now)
		var speed *float64
		if se.Speed != nil {
			v := float64(*se.Speed)
			speed = &v
		}
		var progress, off float64
		for _, p := range kept {
			progress, off = 0, 0
			var pp, po *float32
			if geo.line != nil {
				pr, o := geo.line.project(p.Pos)
				progress, off = geo.line.along(se.Direction, pr), o
				pp, po = f32(progress), f32(off)
			}
			reading := -1.0
			switch {
			case p.Speed != nil && *p.Speed >= 0:
				reading = *p.Speed
			case prev.Have && p.At.After(prev.At):
				reading = distance(prev.Pos, p.Pos) / p.At.Sub(prev.At).Seconds()
			}
			if reading >= 0 {
				v := smoothSpeed(speed, reading)
				speed = &v
			}
			prev = lastFix{Have: true, At: p.At, Pos: p.Pos}
			err := q.InsertLivePing(ctx, store.InsertLivePingParams{
				SessionID: se.ID, At: p.At, Lat: p.Pos.Lat, Lng: p.Pos.Lng, Accuracy: f32(p.Accuracy),
				Speed: optF32(p.Speed), Heading: optF32(p.Heading), Progress: pp, Off: po,
			})
			if err != nil {
				return err
			}
		}
		if len(kept) > 0 {
			newest := kept[len(kept)-1]
			var pp, po *float32
			if geo.line != nil {
				pp, po = f32(progress), f32(off)
			}
			err := q.UpdateLiveSession(ctx, store.UpdateLiveSessionParams{
				ID: se.ID, LastAt: minTime(newest.At, now), Lat: &newest.Pos.Lat, Lng: &newest.Pos.Lng,
				Accuracy: f32(newest.Accuracy), Progress: pp, Off: po, Speed: optF32(speed), Added: int32(len(kept)),
			})
			if err != nil {
				return err
			}
		}
		riders := 0
		sessions, err := s.freshSessions(ctx, q, &route.ID, now)
		if err != nil {
			return err
		}
		for _, run := range s.runsOf(ctx, q, geo, sessions, now) {
			if run.key != keyOf(se) {
				continue
			}
			riders = run.Riders
			if err := s.afterUpdate(ctx, q, route, geo, run, now); err != nil {
				return err
			}
		}
		res = &pingsRes{Riders: riders}
		if len(kept) == 0 || geo.line == nil {
			return nil
		}
		newest := kept[len(kept)-1]
		reason := ""
		switch {
		case progress >= geo.line.length-arriveWithin:
			reason = "arrived"
		case off > offRouteFar && !se.StartedAt.After(newest.At.Add(-offRouteFor)):
			n, err := q.CountPingsOnLine(ctx, store.CountPingsOnLineParams{SessionID: se.ID, Since: newest.At.Add(-offRouteFor), MaxOff: offRouteFar})
			if err != nil {
				return err
			}
			if n == 0 {
				reason = "off_route"
			}
		}
		if reason != "" {
			if _, err := s.endSession(ctx, q, se, reason, now); err != nil {
				return err
			}
			res.Ended, res.Reason = true, &reason
		}
		return nil
	})
	return res, err
}

func ptr[T any](v T) *T { return &v }

func optF32(v *float64) *float32 {
	if v == nil {
		return nil
	}
	return f32(*v)
}

func minTime(a, b time.Time) time.Time {
	if a.Before(b) {
		return a
	}
	return b
}

// afterUpdate records the stops a run has passed (learning) and sends the
// "bus near" pushes that are due.
func (s *Service) afterUpdate(ctx context.Context, q *store.Queries, route store.BusRoute, geo *routeGeo, run *liveRun, now time.Time) error {
	if !run.OnRoute || geo.line == nil {
		return nil
	}
	if err := s.recordPassages(ctx, q, route, run, now); err != nil {
		return err
	}
	return s.sendAlerts(ctx, q, route, geo, run, now)
}

func (s *Service) recordPassages(ctx context.Context, q *store.Queries, route store.BusRoute, run *liveRun, now time.Time) error {
	if len(run.passed) == 0 {
		return nil
	}
	date := pgDate(run.key.Date)
	known, err := q.RunStopIDs(ctx, store.RunStopIDsParams{RouteID: route.ID, Direction: run.key.Direction, ServiceDate: date, Departs: run.key.Departs})
	if err != nil {
		return err
	}
	for _, st := range run.passed {
		if slices.Contains(known, st.ID) {
			continue
		}
		var sched *time.Time
		if run.key.Departs >= 0 && st.Min >= 0 {
			t := dayStart(run.key.Date).Add(time.Duration(int(run.key.Departs)+st.Min) * time.Minute)
			sched = &t
		}
		err := q.InsertRunStop(ctx, store.InsertRunStopParams{
			RouteID: route.ID, Direction: run.key.Direction, ServiceDate: date, Departs: run.key.Departs,
			StopID: st.ID, PassedAt: now, ScheduledAt: sched, Riders: int16(min(run.Riders, math.MaxInt16)),
		})
		if err != nil {
			return err
		}
	}
	return nil
}
