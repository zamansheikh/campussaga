package transport

import (
	"cmp"
	"context"
	"math"
	"slices"
	"time"

	"github.com/google/uuid"

	"github.com/zamansheikh/varsitykotha/backend/internal/modules/transport/store"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/apperr"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/auth"
)

// Trip feedback: one tap after a ride says how it went. With the stop times
// the live buses record, it gives each trip its usual character.

const (
	insightDays = 30
	minRuns     = 3 // measured runs before a delay is told
)

var (
	ErrTripNotFound     = apperr.New(404, "TRIP_NOT_FOUND", "That trip is not on this route")
	ErrFeedbackTooEarly = apperr.New(409, "FEEDBACK_TOO_EARLY", "That bus has not left yet")
	errInvalidFeedback  = apperr.New(400, "INVALID_FEEDBACK", "Feedback can be given for today or yesterday only")
)

// TripInsight is what riders and live buses say about one trip.
type TripInsight struct {
	Direction string `json:"direction"`
	Departs   string `json:"departs"`
	Votes     int    `json:"votes"`
	OnTime    int    `json:"onTime"`
	Late      int    `json:"late"`
	NoShow    int    `json:"noShow"`
	Crowded   int    `json:"crowded"`
	// DelayMin: the median delay at stops over measured runs; null until
	// there are enough runs.
	DelayMin *int `json:"delayMin"`
	// Runs: runs measured live.
	Runs int `json:"runs"`
}

type feedbackReq struct {
	routeReq
	Direction string `json:"direction" validate:"required,oneof=to_campus from_campus"`
	Departs   string `json:"departs" validate:"required"`
	Date      string `json:"date" validate:"required"`
	Status    string `json:"status" validate:"required,oneof=on_time late no_show"`
	Crowded   bool   `json:"crowded"`
}

func (s *Service) handleFeedback(ctx context.Context, in *feedbackReq) (*TripInsight, error) {
	departs, ok := parseClock(in.Departs)
	date, err := time.ParseInLocation(dateLayout, in.Date, dhaka)
	if !ok || err != nil {
		return nil, errInvalidFeedback
	}
	now := s.now()
	today, midnight := serviceDay(now)
	if in.Date != today && in.Date != midnight.AddDate(0, 0, -1).Format(dateLayout) {
		return nil, errInvalidFeedback
	}
	q := store.New(s.d.Q(ctx))
	route, err := s.readableRoute(ctx, q, uuid.MustParse(in.ID))
	if err != nil {
		return nil, err
	}
	trips, err := q.TripsForRoutes(ctx, []uuid.UUID{route.ID})
	if err != nil {
		return nil, err
	}
	day := isoWeekday(date)
	if !slices.ContainsFunc(trips, func(t store.BusTrip) bool {
		return t.Direction == in.Direction && t.DepartsMin == departs && slices.Contains(t.Weekdays, day)
	}) {
		return nil, ErrTripNotFound
	}
	if in.Date == today && minuteOfDay(now) < float64(departs) {
		return nil, ErrFeedbackTooEarly
	}
	err = q.UpsertFeedback(ctx, store.UpsertFeedbackParams{
		RouteID: route.ID, UserID: auth.MustUser(ctx).UserID, Direction: in.Direction, ServiceDate: pgDate(in.Date),
		Departs: departs, Status: in.Status, Crowded: in.Crowded,
	})
	if err != nil {
		return nil, err
	}
	all, err := s.insights(ctx, q, route.ID, trips, now)
	if err != nil {
		return nil, err
	}
	for _, t := range all {
		if t.Direction == in.Direction && t.Departs == in.Departs {
			return &t, nil
		}
	}
	return &TripInsight{Direction: in.Direction, Departs: clock(departs)}, nil
}

type insightsRes struct {
	Trips []TripInsight `json:"trips"`
}

func (s *Service) handleInsights(ctx context.Context, in *routeReq) (*insightsRes, error) {
	q := store.New(s.d.Q(ctx))
	route, err := s.readableRoute(ctx, q, uuid.MustParse(in.ID))
	if err != nil {
		return nil, err
	}
	trips, err := q.TripsForRoutes(ctx, []uuid.UUID{route.ID})
	if err != nil {
		return nil, err
	}
	out, err := s.insights(ctx, q, route.ID, trips, s.now())
	if err != nil {
		return nil, err
	}
	return &insightsRes{Trips: out}, nil
}

// insights: the route's current trips with any votes or measured runs in the
// last 30 days.
func (s *Service) insights(ctx context.Context, q *store.Queries, route uuid.UUID, trips []store.BusTrip, now time.Time) ([]TripInsight, error) {
	_, midnight := serviceDay(now)
	since := pgDate(midnight.AddDate(0, 0, -insightDays).Format(dateLayout))
	votes, err := q.FeedbackTotals(ctx, store.FeedbackTotalsParams{RouteID: route, Since: since})
	if err != nil {
		return nil, err
	}
	runs, err := q.RunDelays(ctx, store.RunDelaysParams{RouteID: route, Since: since})
	if err != nil {
		return nil, err
	}
	type key struct {
		dir     string
		departs int16
	}
	by := map[key]*TripInsight{}
	delays := map[key][]float64{}
	get := func(k key) *TripInsight {
		if by[k] == nil {
			by[k] = &TripInsight{Direction: k.dir, Departs: clock(k.departs)}
		}
		return by[k]
	}
	for _, v := range votes {
		t := get(key{v.Direction, v.Departs})
		t.Votes, t.OnTime, t.Late, t.NoShow, t.Crowded = int(v.Votes), int(v.OnTime), int(v.Late), int(v.NoShow), int(v.Crowded)
	}
	for _, r := range runs {
		k := key{r.Direction, r.Departs}
		get(k).Runs++
		if r.Timed > 0 {
			delays[k] = append(delays[k], r.DelayMin)
		}
	}
	out := []TripInsight{}
	for k, t := range by {
		if !slices.ContainsFunc(trips, func(tr store.BusTrip) bool { return tr.Direction == k.dir && tr.DepartsMin == k.departs }) {
			continue
		}
		if len(delays[k]) >= minRuns {
			d := int(math.Round(median(delays[k])))
			t.DelayMin = &d
		}
		out = append(out, *t)
	}
	slices.SortFunc(out, func(a, b TripInsight) int {
		return cmp.Or(cmp.Compare(a.Direction, b.Direction), cmp.Compare(a.Departs, b.Departs))
	})
	return out, nil
}
