package transport

import (
	"context"
	"time"

	"github.com/zamansheikh/varsitykotha/backend/internal/modules/transport/store"
)

const (
	silentFor     = 10 * time.Minute     // a share with no point for this long is over
	keepSessions  = 24 * time.Hour       // ended sessions, their points and views
	keepAlerts    = 48 * time.Hour       // "already pushed" marks
	keepLearnings = 180 * 24 * time.Hour // stop passages and trip feedback
)

// Sweep ends shares that went quiet and deletes what is past its keep time.
func (s *Service) Sweep(ctx context.Context) error {
	now := s.now()
	err := s.d.InTx(ctx, func(ctx context.Context) error {
		q := store.New(s.d.Q(ctx))
		stale, err := q.StaleSessions(ctx, now.Add(-silentFor))
		if err != nil {
			return err
		}
		for _, se := range stale {
			// The share ended when its phone went quiet.
			if _, err := s.endSession(ctx, q, se, "expired", se.LastAt); err != nil {
				return err
			}
		}
		return nil
	})
	if err != nil {
		return err
	}
	q := store.New(s.d.Q(ctx))
	for _, purge := range []func() (int64, error){
		func() (int64, error) { return q.PurgeLiveSessions(ctx, ptr(now.Add(-keepSessions))) },
		func() (int64, error) { return q.PurgeLiveViews(ctx, now.Add(-keepSessions)) },
		func() (int64, error) { return q.PurgeAlertsSent(ctx, now.Add(-keepAlerts)) },
		func() (int64, error) { return q.PurgeRunStops(ctx, now.Add(-keepLearnings)) },
		func() (int64, error) { return q.PurgeFeedback(ctx, now.Add(-keepLearnings)) },
	} {
		if _, err := purge(); err != nil {
			return err
		}
	}
	return nil
}

// SweepLoop runs Sweep every interval until ctx ends.
func (s *Service) SweepLoop(ctx context.Context, every time.Duration) {
	t := time.NewTicker(every)
	defer t.Stop()
	for {
		select {
		case <-ctx.Done():
			return
		case <-t.C:
			if err := s.Sweep(ctx); err != nil {
				s.log.Error("transport: sweep live buses", "err", err)
			}
		}
	}
}
