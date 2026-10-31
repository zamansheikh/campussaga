package transport

import (
	"context"
	"time"

	"github.com/google/uuid"

	"github.com/zamansheikh/varsitykotha/backend/internal/modules/transport/store"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/db"
)

// Admin view of live buses on a route (docs/ADMIN.md, "Live buses on a
// route"): any university's route, no user ids.

// adminRun is a live run without the caller's own flag.
type adminRun struct {
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
}

type activityRes struct {
	Live struct {
		Runs []adminRun `json:"runs"`
	} `json:"live"`
	Insights struct {
		Trips []TripInsight `json:"trips"`
	} `json:"insights"`
	SharesLast7Days   int `json:"sharesLast7Days"`
	RatingsLast30Days int `json:"ratingsLast30Days"`
}

func (s *Service) handleAdminActivity(ctx context.Context, in *routeReq) (*activityRes, error) {
	q := store.New(s.d.Q(ctx))
	route, err := q.GetRoute(ctx, uuid.MustParse(in.ID))
	if db.IsNoRows(err) {
		return nil, ErrRouteNotFound
	}
	if err != nil {
		return nil, err
	}
	now := s.now()
	geo, err := s.geoOf(ctx, q, route)
	if err != nil {
		return nil, err
	}
	sessions, err := s.freshSessions(ctx, q, &route.ID, now)
	if err != nil {
		return nil, err
	}
	out := &activityRes{}
	out.Live.Runs = []adminRun{}
	for _, r := range s.runsOf(ctx, q, geo, sessions, now) {
		out.Live.Runs = append(out.Live.Runs, adminRun{
			Direction: r.Direction, Departs: r.Departs, Riders: r.Riders, Position: r.Position, OnRoute: r.OnRoute,
			Progress: r.Progress, Length: r.Length, Speed: r.Speed, DelayMin: r.DelayMin, NextStopID: r.NextStopID,
			Passed: r.Passed, ETAs: r.ETAs, UpdatedAt: r.UpdatedAt,
		})
	}
	trips, err := q.TripsForRoutes(ctx, []uuid.UUID{route.ID})
	if err != nil {
		return nil, err
	}
	if out.Insights.Trips, err = s.insights(ctx, q, route.ID, trips, now); err != nil {
		return nil, err
	}
	c, err := q.RouteActivityCounts(ctx, store.RouteActivityCountsParams{
		RouteID: route.ID, SharesSince: now.Add(-7 * 24 * time.Hour), RatingsSince: now.Add(-30 * 24 * time.Hour),
	})
	if err != nil {
		return nil, err
	}
	out.SharesLast7Days, out.RatingsLast30Days = int(c.Shares), int(c.Ratings)
	return out, nil
}

type endRes struct {
	Ended int `json:"ended"`
}

// handleAdminEnd ends every open share on the route (a fake or stuck bus).
// Trips count for the sharers like any other end; their next ping is told
// the share ended with reason "admin".
func (s *Service) handleAdminEnd(ctx context.Context, in *routeReq) (*endRes, error) {
	id := uuid.MustParse(in.ID)
	out := &endRes{}
	err := s.d.InTx(ctx, func(ctx context.Context) error {
		q := store.New(s.d.Q(ctx))
		if _, err := q.GetRoute(ctx, id); db.IsNoRows(err) {
			return ErrRouteNotFound
		} else if err != nil {
			return err
		}
		open, err := q.OpenSessionsOfRoute(ctx, id)
		if err != nil {
			return err
		}
		now := s.now()
		for _, se := range open {
			ok, err := s.endSession(ctx, q, se, "admin", now)
			if err != nil {
				return err
			}
			if ok {
				out.Ended++
			}
		}
		return s.audit(ctx, q, "transport.live.end", id, map[string]int{"ended": out.Ended})
	})
	if err != nil {
		return nil, err
	}
	return out, nil
}
