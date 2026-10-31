package transport

import (
	"context"
	"math"
	"slices"
	"time"

	"github.com/google/uuid"

	"github.com/zamansheikh/varsitykotha/backend/internal/modules/transport/store"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/apperr"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/auth"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/db"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/httpx"
)

// "Tell me when the bus is N minutes from my stop": one alert per student,
// route and direction, and one push per alert per run.

var ErrStopNotFound = apperr.New(404, "STOP_NOT_FOUND", "This stop is not on the route")

type alertJSON struct {
	RouteID   uuid.UUID `json:"routeId"`
	StopID    uuid.UUID `json:"stopId"`
	Direction string    `json:"direction"`
	LeadMin   int       `json:"leadMin"`
}

func alertOf(a store.BusAlert) alertJSON {
	return alertJSON{RouteID: a.RouteID, StopID: a.StopID, Direction: a.Direction, LeadMin: int(a.LeadMin)}
}

type alertsRes struct {
	Alerts []alertJSON `json:"alerts"`
}

func (s *Service) handleAlerts(ctx context.Context, _ *httpx.Empty) (*alertsRes, error) {
	rows, err := store.New(s.d.Q(ctx)).ListAlerts(ctx, auth.MustUser(ctx).UserID)
	if err != nil {
		return nil, err
	}
	out := &alertsRes{Alerts: make([]alertJSON, len(rows))}
	for i, a := range rows {
		out.Alerts[i] = alertOf(a)
	}
	return out, nil
}

type setAlertReq struct {
	routeReq
	StopID    string `json:"stopId" validate:"required,uuid"`
	Direction string `json:"direction" validate:"required,oneof=to_campus from_campus"`
	LeadMin   int    `json:"leadMin" validate:"required,oneof=5 10 15"`
}

func (s *Service) handleSetAlert(ctx context.Context, in *setAlertReq) (*alertJSON, error) {
	q := store.New(s.d.Q(ctx))
	r, err := s.readableRoute(ctx, q, uuid.MustParse(in.ID))
	if err != nil {
		return nil, err
	}
	stops, err := q.StopsOfRoute(ctx, r.ID)
	if err != nil {
		return nil, err
	}
	stop := uuid.MustParse(in.StopID)
	if !slices.ContainsFunc(stops, func(st store.BusStop) bool { return st.ID == stop }) {
		return nil, ErrStopNotFound
	}
	a, err := q.UpsertAlert(ctx, store.UpsertAlertParams{
		UserID: auth.MustUser(ctx).UserID, RouteID: r.ID, Direction: in.Direction, StopID: stop, LeadMin: int16(in.LeadMin),
	})
	if err != nil {
		return nil, err
	}
	out := alertOf(a)
	return &out, nil
}

type deleteAlertReq struct {
	routeReq
	Direction string `json:"-" query:"direction" validate:"required,oneof=to_campus from_campus"`
}

func (s *Service) handleDeleteAlert(ctx context.Context, in *deleteAlertReq) (*httpx.Empty, error) {
	err := store.New(s.d.Q(ctx)).DeleteAlert(ctx, store.DeleteAlertParams{
		UserID: auth.MustUser(ctx).UserID, RouteID: uuid.MustParse(in.ID), Direction: in.Direction,
	})
	return &httpx.Empty{}, err
}

// sendAlerts pushes to students whose alert is due on this run: their stop
// is ahead and the bus is 1 to leadMin minutes from it. Sharers of the run
// are left out, and each alert fires once per run.
func (s *Service) sendAlerts(ctx context.Context, q *store.Queries, route store.BusRoute, geo *routeGeo, run *liveRun, now time.Time) error {
	if len(run.ETAs) == 0 {
		return nil
	}
	pending, err := q.PendingAlerts(ctx, store.PendingAlertsParams{
		RouteID: route.ID, Direction: run.key.Direction, ServiceDate: pgDate(run.key.Date), Departs: run.key.Departs,
	})
	if err != nil {
		return err
	}
	type due struct {
		user       uuid.UUID
		stop       uuid.UUID
		minutes    int
		stopName   string
		routeName  string
		riderCount int
	}
	var send []due
	for _, a := range pending {
		i := slices.IndexFunc(run.ETAs, func(e eta) bool { return e.StopID == a.StopID })
		if i < 0 {
			continue
		}
		mins := int(math.Round(run.ETAs[i].At.Sub(now).Minutes()))
		if mins < 1 || mins > int(a.LeadMin) {
			continue
		}
		n, err := q.MarkAlertSent(ctx, store.MarkAlertSentParams{
			UserID: a.UserID, RouteID: route.ID, Direction: run.key.Direction, ServiceDate: pgDate(run.key.Date),
			Departs: run.key.Departs, Now: now,
		})
		if err != nil {
			return err
		}
		if n == 1 {
			send = append(send, due{a.UserID, a.StopID, mins, geo.stopName(a.StopID), route.Name, run.Riders})
		}
	}
	if len(send) == 0 || s.notify == nil {
		return nil
	}
	db.AfterCommit(ctx, func(context.Context) {
		for _, d := range send {
			s.notify([]uuid.UUID{d.user}, busNearNotice(d.routeName, d.stopName, d.minutes, d.riderCount, route.ID, d.stop))
		}
	})
	return nil
}
