package growth

import (
	"context"
	"time"

	"github.com/google/uuid"
)

// Sweep is the hourly job: invites that can still qualify are re-checked,
// badges are recomputed for students active in the last day, campaigns past
// their end become "ended", and old rows are deleted (active days after 30
// days, prize claims 90 days after delivery).
func (s *Service) Sweep(ctx context.Context) error {
	now := s.now()
	if err := s.QualifyPending(ctx); err != nil {
		return err
	}
	rows, err := s.d.Q(ctx).Query(ctx, `SELECT DISTINCT user_id FROM user_active_days WHERE day >= $1`,
		now.In(dhaka).AddDate(0, 0, -1).Format(time.DateOnly))
	if err != nil {
		return err
	}
	var ids []uuid.UUID
	for rows.Next() {
		var id uuid.UUID
		if err := rows.Scan(&id); err != nil {
			rows.Close()
			return err
		}
		ids = append(ids, id)
	}
	rows.Close()
	if err := rows.Err(); err != nil {
		return err
	}
	for _, id := range ids {
		if err := s.Recompute(ctx, id); err != nil {
			s.log.Warn("growth: badges", "err", err)
		}
	}
	q := s.d.Q(ctx)
	if _, err := q.Exec(ctx, `UPDATE campaigns SET status = 'ended' WHERE status = 'live' AND ends_at < $1`, now); err != nil {
		return err
	}
	if _, err := q.Exec(ctx, `DELETE FROM user_active_days WHERE day < $1`,
		now.In(dhaka).AddDate(0, 0, -KeepActiveDays).Format(time.DateOnly)); err != nil {
		return err
	}
	_, err = q.Exec(ctx, `DELETE FROM campaign_claims c USING campaign_winners w
		WHERE w.campaign_id = c.campaign_id AND w.user_id = c.user_id AND w.delivered_at < $1`,
		now.Add(-KeepClaimsDays*24*time.Hour))
	return err
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
				s.log.Error("growth: sweep", "err", err)
			}
		}
	}
}
