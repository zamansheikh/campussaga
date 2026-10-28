// Package transport serves university bus routes and timetables. Students
// read their university's routes; transport reps (students an admin names
// for one university) and admins edit them. No live tracking.
//
// Timetable model: a stop has a minute offset from the start of a trip in
// each direction; a trip is a departure time, a direction and weekdays. The
// time at a stop is departure + offset (see migrations/00550_transport.sql).
package transport

import (
	"context"
	"encoding/json"
	"fmt"
	"log/slog"
	"math"
	"regexp"
	"slices"
	"strconv"
	"strings"
	"time"

	"github.com/google/uuid"

	"github.com/zamansheikh/varsitykotha/backend/internal/modules/transport/store"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/apperr"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/auth"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/db"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/httpx"
)

const (
	MaxRoutes = 50  // per university
	MaxStops  = 60  // per route
	MaxTrips  = 150 // per route

	ToCampus   = "to_campus"
	FromCampus = "from_campus"
)

var (
	ErrRouteNotFound = apperr.New(404, "ROUTE_NOT_FOUND", "This bus route was not found")
	ErrNotRep        = apperr.New(403, "NOT_TRANSPORT_REP", "Only your university's transport rep or an admin can change bus routes")
	ErrRouteLimit    = apperr.New(409, "ROUTE_LIMIT_REACHED", "This university already has the most bus routes allowed")
	ErrUserNotFound  = apperr.New(404, "USER_NOT_FOUND", "No such user")
	ErrUniNotFound   = apperr.New(404, "UNIVERSITY_NOT_FOUND", "No such university")
)

type Service struct {
	d     *db.DB
	now   func() time.Time
	roads RoadRouter // nil: maps draw straight lines between stops
	log   *slog.Logger
}

func NewService(d *db.DB, now func() time.Time, roads RoadRouter, log *slog.Logger) *Service {
	if log == nil {
		log = slog.Default()
	}
	return &Service{d: d, now: now, roads: roads, log: log}
}

// Routes mounts the module's endpoints.
func (s *Service) Routes(r *httpx.Router) {
	r.Student().Get("/transport/routes", httpx.Handle(s.handleList))
	r.Student().Get("/transport/routes/{id}", httpx.Handle(s.handleGet))
	e := r.Student().With(r.LimitUser("transport-edit", 300, time.Hour))
	e.Post("/transport/routes", httpx.Handle(s.handleCreate, httpx.Status(201)))
	e.Put("/transport/routes/{id}", httpx.Handle(s.handleUpdate))
	e.Delete("/transport/routes/{id}", httpx.Handle(s.handleDelete, httpx.NoContent()))
	e.Put("/transport/routes/{id}/stops", httpx.Handle(s.handleStops))
	e.Put("/transport/routes/{id}/trips", httpx.Handle(s.handleTrips))
	a := r.Admin()
	a.Get("/admin/transport/routes", httpx.Handle(s.handleAdminList))
	a.Post("/admin/transport/routes", httpx.Handle(s.handleAdminCreate, httpx.Status(201)))
	a.Get("/admin/transport/reps", httpx.Handle(s.handleListReps))
	a.Put("/admin/transport/reps", httpx.Handle(s.handleSetRep))
	a.Delete("/admin/transport/reps/{user}", httpx.Handle(s.handleRemoveRep, httpx.NoContent()))
}

// ---- views ------------------------------------------------------------------

type Route struct {
	ID           uuid.UUID `json:"id"`
	UniversityID uuid.UUID `json:"universityId"`
	Name         string    `json:"name"`
	Color        string    `json:"color"`
	Notes        string    `json:"notes"`
	Active       bool      `json:"active"`
	Stops        []Stop    `json:"stops"`
	Trips        []Trip    `json:"trips"`
	// Path is the road path through the placed stops, an encoded polyline
	// (precision 5); null: draw straight lines.
	Path      *string   `json:"path"`
	UpdatedAt time.Time `json:"updatedAt"`
}

// Stop: offsets are minutes after a trip starts, per direction (null: the
// bus doesn't stop here that way). Stops run from the far end to campus.
// Location is where the stop is, for the map (null: not placed yet).
type Stop struct {
	ID            uuid.UUID `json:"id"`
	Name          string    `json:"name"`
	Landmark      string    `json:"landmark"`
	ToCampusMin   *int16    `json:"toCampusMin"`
	FromCampusMin *int16    `json:"fromCampusMin"`
	Location      *LatLng   `json:"location"`
}

// LatLng is a point in WGS 84 degrees.
type LatLng struct {
	Lat float64 `json:"lat"`
	Lng float64 `json:"lng"`
}

func latLng(lat, lng *float64) *LatLng {
	if lat == nil || lng == nil {
		return nil
	}
	return &LatLng{Lat: *lat, Lng: *lng}
}

// Trip: departs "HH:MM" from the first stop (to_campus) or from campus
// (from_campus); weekdays ISO (1 = Monday ... 7 = Sunday).
type Trip struct {
	ID        uuid.UUID `json:"id"`
	Direction string    `json:"direction"`
	Departs   string    `json:"departs"`
	Weekdays  []int     `json:"weekdays"`
	Note      string    `json:"note"`
}

func clock(m int16) string { return fmt.Sprintf("%02d:%02d", m/60, m%60) }

// routesView loads the stops and trips of the given routes.
func routesView(ctx context.Context, q *store.Queries, rows []store.BusRoute) ([]Route, error) {
	out := make([]Route, 0, len(rows))
	if len(rows) == 0 {
		return out, nil
	}
	ids := make([]uuid.UUID, len(rows))
	at := map[uuid.UUID]int{}
	for i, r := range rows {
		ids[i], at[r.ID] = r.ID, i
		out = append(out, Route{
			ID: r.ID, UniversityID: r.UniversityID, Name: r.Name, Color: r.Color, Notes: r.Notes,
			Active: r.Active, Stops: []Stop{}, Trips: []Trip{}, Path: r.Path, UpdatedAt: r.UpdatedAt,
		})
	}
	stops, err := q.StopsForRoutes(ctx, ids)
	if err != nil {
		return nil, err
	}
	for _, st := range stops {
		r := &out[at[st.RouteID]]
		r.Stops = append(r.Stops, Stop{
			ID: st.ID, Name: st.Name, Landmark: st.Landmark,
			ToCampusMin: st.ToCampusMin, FromCampusMin: st.FromCampusMin, Location: latLng(st.Lat, st.Lng),
		})
	}
	trips, err := q.TripsForRoutes(ctx, ids)
	if err != nil {
		return nil, err
	}
	for _, t := range trips {
		r := &out[at[t.RouteID]]
		days := make([]int, len(t.Weekdays))
		for i, d := range t.Weekdays {
			days[i] = int(d)
		}
		r.Trips = append(r.Trips, Trip{ID: t.ID, Direction: t.Direction, Departs: clock(t.DepartsMin), Weekdays: days, Note: t.Note})
	}
	return out, nil
}

// ---- access -----------------------------------------------------------------

// editsUniversity: an admin edits any university; a rep only theirs.
func (s *Service) editsUniversity(ctx context.Context, q *store.Queries, uni uuid.UUID) (bool, error) {
	c := auth.MustUser(ctx)
	if c.Role == "admin" {
		return true, nil
	}
	repUni, err := q.RepUniversity(ctx, c.UserID)
	if db.IsNoRows(err) {
		return false, nil
	}
	if err != nil {
		return false, err
	}
	return repUni == uni, nil
}

// editableRoute locks nothing: route edits replace whole lists in one
// transaction, and the last write wins.
func (s *Service) editableRoute(ctx context.Context, q *store.Queries, id uuid.UUID) (store.BusRoute, error) {
	r, err := q.GetRoute(ctx, id)
	if db.IsNoRows(err) {
		return r, ErrRouteNotFound
	}
	if err != nil {
		return r, err
	}
	ok, err := s.editsUniversity(ctx, q, r.UniversityID)
	if err != nil {
		return r, err
	}
	if !ok {
		if auth.MustUser(ctx).UniversityID != r.UniversityID {
			return r, ErrRouteNotFound // other universities' routes don't exist for you
		}
		return r, ErrNotRep
	}
	return r, nil
}

func (s *Service) audit(ctx context.Context, q *store.Queries, action string, target uuid.UUID, meta any) error {
	c := auth.MustUser(ctx)
	b, err := json.Marshal(meta)
	if err != nil || meta == nil {
		b = []byte("{}")
	}
	tt, tid := "bus_route", target.String()
	if strings.HasPrefix(action, "transport.rep") {
		tt = "user"
	}
	return q.InsertAudit(ctx, store.InsertAuditParams{ActorID: &c.UserID, Action: action, TargetType: &tt, TargetID: &tid, Meta: b})
}

// ---- read -------------------------------------------------------------------

type listRes struct {
	Routes []Route `json:"routes"`
	// CanEdit: the caller is this university's transport rep (or an admin).
	CanEdit bool `json:"canEdit"`
}

func (s *Service) handleList(ctx context.Context, _ *httpx.Empty) (*listRes, error) {
	c := auth.MustUser(ctx)
	out := &listRes{Routes: []Route{}}
	if c.UniversityID == uuid.Nil {
		return out, nil
	}
	q := store.New(s.d.Q(ctx))
	can, err := s.editsUniversity(ctx, q, c.UniversityID)
	if err != nil {
		return nil, err
	}
	rows, err := q.ListRoutes(ctx, store.ListRoutesParams{UniversityID: c.UniversityID, IncludeInactive: can})
	if err != nil {
		return nil, err
	}
	if out.Routes, err = routesView(ctx, q, rows); err != nil {
		return nil, err
	}
	out.CanEdit = can
	return out, nil
}

type routeReq struct {
	ID string `json:"-" path:"id" validate:"required,uuid"`
}

func (s *Service) handleGet(ctx context.Context, in *routeReq) (*Route, error) {
	c := auth.MustUser(ctx)
	q := store.New(s.d.Q(ctx))
	r, err := q.GetRoute(ctx, uuid.MustParse(in.ID))
	if db.IsNoRows(err) {
		return nil, ErrRouteNotFound
	}
	if err != nil {
		return nil, err
	}
	if r.UniversityID != c.UniversityID {
		if ok, err := s.editsUniversity(ctx, q, r.UniversityID); err != nil {
			return nil, err
		} else if !ok {
			return nil, ErrRouteNotFound
		}
	}
	return s.one(ctx, q, r)
}

func (s *Service) one(ctx context.Context, q *store.Queries, r store.BusRoute) (*Route, error) {
	v, err := routesView(ctx, q, []store.BusRoute{r})
	if err != nil {
		return nil, err
	}
	return &v[0], nil
}

// ---- route edits ------------------------------------------------------------

// RouteInput is a route's own fields.
type RouteInput struct {
	Name   string `json:"name" validate:"required,max=60"`
	Color  string `json:"color" validate:"omitempty,max=7"`
	Notes  string `json:"notes" validate:"max=500"`
	Active *bool  `json:"active"`
}

var colorRe = regexp.MustCompile(`^#[0-9A-F]{6}$`)

func (in *RouteInput) clean() error {
	in.Name, in.Notes = strings.Join(strings.Fields(in.Name), " "), strings.TrimSpace(in.Notes)
	if in.Name == "" {
		return apperr.Validation(map[string]string{"name": "is required"})
	}
	in.Color = strings.ToUpper(strings.TrimSpace(in.Color))
	if in.Color == "" {
		in.Color = "#0F766E"
	}
	if !colorRe.MatchString(in.Color) {
		return apperr.Validation(map[string]string{"color": "must be a color like #0F766E"})
	}
	return nil
}

func (in *RouteInput) active() bool { return in.Active == nil || *in.Active }

func (s *Service) create(ctx context.Context, uni uuid.UUID, in *RouteInput) (*Route, error) {
	if err := in.clean(); err != nil {
		return nil, err
	}
	var out *Route
	err := s.d.InTx(ctx, func(ctx context.Context) error {
		q := store.New(s.d.Q(ctx))
		ok, err := s.editsUniversity(ctx, q, uni)
		if err != nil {
			return err
		}
		if !ok {
			return ErrNotRep
		}
		n, err := q.CountRoutes(ctx, uni)
		if err != nil {
			return err
		}
		if n >= MaxRoutes {
			return ErrRouteLimit
		}
		r, err := q.CreateRoute(ctx, store.CreateRouteParams{UniversityID: uni, Name: in.Name, Color: in.Color, Notes: in.Notes, Active: in.active()})
		if err != nil {
			return err
		}
		if err := s.audit(ctx, q, "transport.route.create", r.ID, map[string]any{"name": r.Name, "universityId": uni}); err != nil {
			return err
		}
		out, err = s.one(ctx, q, r)
		return err
	})
	return out, err
}

func (s *Service) handleCreate(ctx context.Context, in *RouteInput) (*Route, error) {
	c := auth.MustUser(ctx)
	q := store.New(s.d.Q(ctx))
	uni, err := q.RepUniversity(ctx, c.UserID)
	if db.IsNoRows(err) {
		if c.Role == "admin" && c.UniversityID != uuid.Nil {
			uni, err = c.UniversityID, nil
		} else {
			return nil, ErrNotRep
		}
	}
	if err != nil {
		return nil, err
	}
	return s.create(ctx, uni, in)
}

type updateRouteReq struct {
	routeReq
	RouteInput
}

func (s *Service) handleUpdate(ctx context.Context, in *updateRouteReq) (*Route, error) {
	if err := in.RouteInput.clean(); err != nil {
		return nil, err
	}
	var out *Route
	err := s.d.InTx(ctx, func(ctx context.Context) error {
		q := store.New(s.d.Q(ctx))
		r, err := s.editableRoute(ctx, q, uuid.MustParse(in.ID))
		if err != nil {
			return err
		}
		r, err = q.UpdateRoute(ctx, store.UpdateRouteParams{ID: r.ID, Name: in.Name, Color: in.Color, Notes: in.Notes, Active: in.active()})
		if err != nil {
			return err
		}
		if err := s.audit(ctx, q, "transport.route.update", r.ID, map[string]any{"name": r.Name, "active": r.Active}); err != nil {
			return err
		}
		out, err = s.one(ctx, q, r)
		return err
	})
	return out, err
}

func (s *Service) handleDelete(ctx context.Context, in *routeReq) (*httpx.Empty, error) {
	return nil, s.d.InTx(ctx, func(ctx context.Context) error {
		q := store.New(s.d.Q(ctx))
		r, err := s.editableRoute(ctx, q, uuid.MustParse(in.ID))
		if err != nil {
			return err
		}
		if _, err := q.DeleteRoute(ctx, r.ID); err != nil {
			return err
		}
		return s.audit(ctx, q, "transport.route.delete", r.ID, map[string]any{"name": r.Name})
	})
}

// ---- stops and trips ----------------------------------------------------------

type StopInput struct {
	Name          string      `json:"name" validate:"required,max=60"`
	Landmark      string      `json:"landmark" validate:"max=100"`
	ToCampusMin   *int16      `json:"toCampusMin" validate:"omitempty,min=0,max=600"`
	FromCampusMin *int16      `json:"fromCampusMin" validate:"omitempty,min=0,max=600"`
	Location      OptLocation `json:"location"`
}

// OptLocation tells "location": null (remove it) from no "location" key at
// all: app versions from before the map send no key, and their edits keep
// the stop's saved location (matched by name).
type OptLocation struct {
	Set   bool
	Value *LatLng
}

func (o *OptLocation) UnmarshalJSON(b []byte) error {
	o.Set = true
	if string(b) == "null" {
		o.Value = nil
		return nil
	}
	var v LatLng
	if err := json.Unmarshal(b, &v); err != nil {
		return err
	}
	o.Value = &v
	return nil
}

type stopsReq struct {
	routeReq
	Stops []StopInput `json:"stops" validate:"max=60,dive"`
}

// checkStops: names given, and times that run one way along the route —
// later stops come later on the way to campus, earlier on the way back.
func checkStops(stops []StopInput) error {
	var lastTo, lastFrom *int16
	for i := range stops {
		st := &stops[i]
		st.Name, st.Landmark = strings.Join(strings.Fields(st.Name), " "), strings.TrimSpace(st.Landmark)
		field := "stops[" + strconv.Itoa(i) + "]"
		if st.Name == "" {
			return apperr.Validation(map[string]string{field + ".name": "is required"})
		}
		if l := st.Location.Value; l != nil {
			if math.IsNaN(l.Lat) || math.IsNaN(l.Lng) || l.Lat < -90 || l.Lat > 90 || l.Lng < -180 || l.Lng > 180 {
				return apperr.Validation(map[string]string{field + ".location": "must be a point on the map"})
			}
		}
		if st.ToCampusMin != nil {
			if lastTo != nil && *st.ToCampusMin < *lastTo {
				return apperr.Validation(map[string]string{field + ".toCampusMin": "must not be earlier than the stop before"})
			}
			lastTo = st.ToCampusMin
		}
		if st.FromCampusMin != nil {
			if lastFrom != nil && *st.FromCampusMin > *lastFrom {
				return apperr.Validation(map[string]string{field + ".fromCampusMin": "must not be later than the stop before (the way back starts at campus)"})
			}
			lastFrom = st.FromCampusMin
		}
	}
	return nil
}

// keptLocations: each new stop's location. A stop sent without a location
// key keeps the location of a saved stop with the same name (each saved stop
// used once), so older apps don't wipe the map.
func keptLocations(old []store.BusStop, stops []StopInput) []*LatLng {
	byName := map[string][]*LatLng{}
	for _, o := range old {
		if l := latLng(o.Lat, o.Lng); l != nil {
			byName[o.Name] = append(byName[o.Name], l)
		}
	}
	out := make([]*LatLng, len(stops))
	for i, st := range stops {
		if st.Location.Set {
			out[i] = st.Location.Value
			continue
		}
		if ls := byName[st.Name]; len(ls) > 0 {
			out[i], byName[st.Name] = ls[0], ls[1:]
		}
	}
	return out
}

func (s *Service) handleStops(ctx context.Context, in *stopsReq) (*Route, error) {
	if err := checkStops(in.Stops); err != nil {
		return nil, err
	}
	var out *Route
	err := s.d.InTx(ctx, func(ctx context.Context) error {
		q := store.New(s.d.Q(ctx))
		r, err := s.editableRoute(ctx, q, uuid.MustParse(in.ID))
		if err != nil {
			return err
		}
		old, err := q.StopsOfRoute(ctx, r.ID)
		if err != nil {
			return err
		}
		locs := keptLocations(old, in.Stops)
		if err := q.DeleteStops(ctx, r.ID); err != nil {
			return err
		}
		for i, st := range in.Stops {
			p := store.InsertStopParams{
				RouteID: r.ID, Position: int16(i), Name: st.Name, Landmark: st.Landmark,
				ToCampusMin: st.ToCampusMin, FromCampusMin: st.FromCampusMin,
			}
			if l := locs[i]; l != nil {
				p.Lat, p.Lng = &l.Lat, &l.Lng
			}
			if err := q.InsertStop(ctx, p); err != nil {
				return err
			}
		}
		if err := q.TouchRoute(ctx, r.ID); err != nil {
			return err
		}
		if err := s.audit(ctx, q, "transport.route.stops", r.ID, map[string]any{"stops": len(in.Stops)}); err != nil {
			return err
		}
		if r, err = q.GetRoute(ctx, r.ID); err != nil {
			return err
		}
		out, err = s.one(ctx, q, r)
		return err
	})
	if err != nil || out == nil {
		return out, err
	}
	if p, changed := s.refreshPath(ctx, out); changed {
		out.Path = p
	}
	return out, nil
}

// refreshPath works out the road path through the route's placed stops
// when they changed, and stores it. A failed lookup stores no path (maps
// then draw straight lines) and is tried again on the next save.
func (s *Service) refreshPath(ctx context.Context, r *Route) (*string, bool) {
	var pts []LatLng
	for _, st := range r.Stops {
		if st.Location != nil {
			pts = append(pts, *st.Location)
		}
	}
	key := ""
	if len(pts) >= 2 && s.roads != nil {
		key = pathKey(pts)
	}
	q := store.New(s.d.Q(ctx))
	row, err := q.GetRoute(ctx, r.ID)
	if err != nil || (row.PathKey == key && key != "") || (key == "" && row.Path == nil) {
		return nil, false
	}
	var path *string
	if key != "" {
		c, cancel := context.WithTimeout(ctx, 10*time.Second)
		p, err := s.roads.Path(c, pts)
		cancel()
		if err != nil {
			s.log.Warn("transport: road path failed; maps show straight lines", "route", r.ID, "err", err)
			key = ""
		} else {
			path = &p
		}
	}
	if err := q.SetRoutePath(ctx, store.SetRoutePathParams{ID: r.ID, Path: path, PathKey: key}); err != nil {
		s.log.Warn("transport: saving road path", "route", r.ID, "err", err)
		return nil, false
	}
	return path, true
}

type TripInput struct {
	Direction string `json:"direction" validate:"required,oneof=to_campus from_campus"`
	Departs   string `json:"departs" validate:"required"`
	Weekdays  []int  `json:"weekdays" validate:"required,min=1,max=7,dive,min=1,max=7"`
	Note      string `json:"note" validate:"max=100"`

	departs  int16
	weekdays []int16
}

type tripsReq struct {
	routeReq
	Trips []TripInput `json:"trips" validate:"max=150,dive"`
}

func parseClock(s string) (int16, bool) {
	h, m, ok := strings.Cut(strings.TrimSpace(s), ":")
	if !ok || len(h) != 2 || len(m) != 2 {
		return 0, false
	}
	hh, err1 := strconv.Atoi(h)
	mm, err2 := strconv.Atoi(m)
	if err1 != nil || err2 != nil || hh < 0 || hh > 23 || mm < 0 || mm > 59 {
		return 0, false
	}
	return int16(hh*60 + mm), true
}

func checkTrips(trips []TripInput) error {
	for i := range trips {
		t := &trips[i]
		field := "trips[" + strconv.Itoa(i) + "]"
		m, ok := parseClock(t.Departs)
		if !ok {
			return apperr.Validation(map[string]string{field + ".departs": "must be a time like 07:30"})
		}
		t.departs, t.Note = m, strings.TrimSpace(t.Note)
		days := slices.Clone(t.Weekdays)
		slices.Sort(days)
		days = slices.Compact(days)
		t.weekdays = make([]int16, len(days))
		for j, d := range days {
			t.weekdays[j] = int16(d)
		}
	}
	return nil
}

func (s *Service) handleTrips(ctx context.Context, in *tripsReq) (*Route, error) {
	if err := checkTrips(in.Trips); err != nil {
		return nil, err
	}
	var out *Route
	err := s.d.InTx(ctx, func(ctx context.Context) error {
		q := store.New(s.d.Q(ctx))
		r, err := s.editableRoute(ctx, q, uuid.MustParse(in.ID))
		if err != nil {
			return err
		}
		if err := q.DeleteTrips(ctx, r.ID); err != nil {
			return err
		}
		for _, t := range in.Trips {
			if err := q.InsertTrip(ctx, store.InsertTripParams{
				RouteID: r.ID, Direction: t.Direction, DepartsMin: t.departs, Weekdays: t.weekdays, Note: t.Note,
			}); err != nil {
				return err
			}
		}
		if err := q.TouchRoute(ctx, r.ID); err != nil {
			return err
		}
		if err := s.audit(ctx, q, "transport.route.trips", r.ID, map[string]any{"trips": len(in.Trips)}); err != nil {
			return err
		}
		if r, err = q.GetRoute(ctx, r.ID); err != nil {
			return err
		}
		out, err = s.one(ctx, q, r)
		return err
	})
	return out, err
}

// ---- admin --------------------------------------------------------------------

type adminListReq struct {
	UniversityID string `json:"-" query:"universityId" validate:"required,uuid"`
}

type adminListRes struct {
	Routes []Route `json:"routes"`
}

func (s *Service) handleAdminList(ctx context.Context, in *adminListReq) (*adminListRes, error) {
	q := store.New(s.d.Q(ctx))
	rows, err := q.ListRoutes(ctx, store.ListRoutesParams{UniversityID: uuid.MustParse(in.UniversityID), IncludeInactive: true})
	if err != nil {
		return nil, err
	}
	v, err := routesView(ctx, q, rows)
	if err != nil {
		return nil, err
	}
	return &adminListRes{Routes: v}, nil
}

type adminCreateReq struct {
	UniversityID string `json:"universityId" validate:"required,uuid"`
	RouteInput
}

func (s *Service) handleAdminCreate(ctx context.Context, in *adminCreateReq) (*Route, error) {
	uni := uuid.MustParse(in.UniversityID)
	ok, err := store.New(s.d.Q(ctx)).UniversityExists(ctx, uni)
	if err != nil {
		return nil, err
	}
	if !ok {
		return nil, ErrUniNotFound
	}
	return s.create(ctx, uni, &in.RouteInput)
}

type Rep struct {
	UserID       uuid.UUID `json:"userId"`
	Email        string    `json:"email"`
	Name         *string   `json:"name"`
	UniversityID uuid.UUID `json:"universityId"`
	University   string    `json:"university"`
	Slug         string    `json:"universitySlug"`
	CreatedAt    time.Time `json:"createdAt"`
}

type repsReq struct {
	UniversityID string `json:"-" query:"universityId" validate:"omitempty,uuid"`
}

type repsRes struct {
	Items []Rep `json:"items"`
}

func (s *Service) handleListReps(ctx context.Context, in *repsReq) (*repsRes, error) {
	var uni *uuid.UUID
	if in.UniversityID != "" {
		u := uuid.MustParse(in.UniversityID)
		uni = &u
	}
	rows, err := store.New(s.d.Q(ctx)).ListReps(ctx, uni)
	if err != nil {
		return nil, err
	}
	out := &repsRes{Items: make([]Rep, 0, len(rows))}
	for _, r := range rows {
		out.Items = append(out.Items, Rep{
			UserID: r.UserID, Email: r.Email, Name: r.DisplayName, UniversityID: r.UniversityID,
			University: r.UniversityName, Slug: r.UniversitySlug, CreatedAt: r.CreatedAt,
		})
	}
	return out, nil
}

type setRepReq struct {
	UserID       string `json:"userId" validate:"required,uuid"`
	UniversityID string `json:"universityId" validate:"required,uuid"`
}

func (s *Service) handleSetRep(ctx context.Context, in *setRepReq) (*repsRes, error) {
	user, uni := uuid.MustParse(in.UserID), uuid.MustParse(in.UniversityID)
	err := s.d.InTx(ctx, func(ctx context.Context) error {
		q := store.New(s.d.Q(ctx))
		if ok, err := q.UserExists(ctx, user); err != nil {
			return err
		} else if !ok {
			return ErrUserNotFound
		}
		if ok, err := q.UniversityExists(ctx, uni); err != nil {
			return err
		} else if !ok {
			return ErrUniNotFound
		}
		if err := q.UpsertRep(ctx, store.UpsertRepParams{UserID: user, UniversityID: uni}); err != nil {
			return err
		}
		return s.audit(ctx, q, "transport.rep.set", user, map[string]any{"universityId": uni})
	})
	if err != nil {
		return nil, err
	}
	return s.handleListReps(ctx, &repsReq{})
}

type removeRepReq struct {
	User string `json:"-" path:"user" validate:"required,uuid"`
}

func (s *Service) handleRemoveRep(ctx context.Context, in *removeRepReq) (*httpx.Empty, error) {
	user := uuid.MustParse(in.User)
	return nil, s.d.InTx(ctx, func(ctx context.Context) error {
		q := store.New(s.d.Q(ctx))
		n, err := q.DeleteRep(ctx, user)
		if err != nil {
			return err
		}
		if n == 0 {
			return ErrUserNotFound
		}
		return s.audit(ctx, q, "transport.rep.remove", user, nil)
	})
}
