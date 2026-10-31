package sponsors

import (
	"context"
	"math"
	"time"

	"github.com/google/uuid"
)

// ---- reports ------------------------------------------------------------------------

// StatsDay is one day of an ad (Asia/Dhaka).
type StatsDay struct {
	Day     string `json:"day"`
	Views   int    `json:"views"`
	Viewers int    `json:"viewers"`
	Taps    int    `json:"taps"`
	Copies  int    `json:"copies"`
	Hides   int    `json:"hides"`
}

// StatsTotals sums a range. Viewers are distinct students over the range
// (per-student rows are kept 90 days, so older ranges count fewer); CTR is
// taps / views (0 without views), to 4 decimals.
type StatsTotals struct {
	Views   int     `json:"views"`
	Viewers int     `json:"viewers"`
	Taps    int     `json:"taps"`
	Copies  int     `json:"copies"`
	Hides   int     `json:"hides"`
	CTR     float64 `json:"ctr"`
}

func ctr(taps, views int) float64 {
	if views == 0 {
		return 0
	}
	return math.Round(float64(taps)/float64(views)*10000) / 10000
}

type PromoStats struct {
	From   string      `json:"from"`
	To     string      `json:"to"`
	Days   []StatsDay  `json:"days"`
	Totals StatsTotals `json:"totals"`
}

type statsReq struct {
	ID   string `json:"-" path:"id" validate:"required,uuid"`
	From string `json:"-" query:"from" validate:"omitempty,datetime=2006-01-02"`
	To   string `json:"-" query:"to" validate:"omitempty,datetime=2006-01-02"`
}

// rangeOf: from..to (inclusive days); defaults: the last 30 days to today.
func (s *Service) rangeOf(in *statsReq) (time.Time, time.Time, error) {
	to, _ := time.Parse(time.DateOnly, dhakaDay(s.now()))
	if in.To != "" {
		to, _ = time.Parse(time.DateOnly, in.To)
	}
	from := to.AddDate(0, 0, -29)
	if in.From != "" {
		from, _ = time.Parse(time.DateOnly, in.From)
	}
	if from.After(to) {
		return from, to, invalid("from", "must not be after to")
	}
	if to.Sub(from) >= MaxStatsDays*24*time.Hour {
		return from, to, invalid("from", "the range is longer than a year")
	}
	return from, to, nil
}

func (s *Service) handleAdminPromoStats(ctx context.Context, in *statsReq) (*PromoStats, error) {
	id := uuid.MustParse(in.ID)
	if _, err := s.loadPromo(ctx, id, false); err != nil {
		return nil, err
	}
	from, to, err := s.rangeOf(in)
	if err != nil {
		return nil, err
	}
	out := &PromoStats{From: from.Format(time.DateOnly), To: to.Format(time.DateOnly), Days: []StatsDay{}}
	byDay := map[string]StatsDay{}
	rows, err := s.d.Q(ctx).Query(ctx, `SELECT day::text, views, viewers, taps, copies, hides FROM promo_days
		WHERE promo_id = $1 AND day BETWEEN $2::date AND $3::date`, id, out.From, out.To)
	if err != nil {
		return nil, err
	}
	for rows.Next() {
		var d StatsDay
		if err := rows.Scan(&d.Day, &d.Views, &d.Viewers, &d.Taps, &d.Copies, &d.Hides); err != nil {
			rows.Close()
			return nil, err
		}
		byDay[d.Day] = d
	}
	rows.Close()
	if err := rows.Err(); err != nil {
		return nil, err
	}
	// Every day of the range, zeros included (charts).
	for d := from; !d.After(to); d = d.AddDate(0, 0, 1) {
		k := d.Format(time.DateOnly)
		day, ok := byDay[k]
		if !ok {
			day = StatsDay{Day: k}
		}
		out.Days = append(out.Days, day)
		out.Totals.Views += day.Views
		out.Totals.Taps += day.Taps
		out.Totals.Copies += day.Copies
		out.Totals.Hides += day.Hides
	}
	if err := s.d.Q(ctx).QueryRow(ctx, `SELECT count(DISTINCT user_id)::int FROM promo_user_days
		WHERE promo_id = $1 AND day BETWEEN $2::date AND $3::date AND views > 0`, id, out.From, out.To).Scan(&out.Totals.Viewers); err != nil {
		return nil, err
	}
	out.Totals.CTR = ctr(out.Totals.Taps, out.Totals.Views)
	return out, nil
}

// SponsorStats is a sponsor's report: each of its ads over the range.
type SponsorStats struct {
	Sponsor struct {
		ID   uuid.UUID `json:"id"`
		Name string    `json:"name"`
	} `json:"sponsor"`
	From   string            `json:"from"`
	To     string            `json:"to"`
	Promos []SponsorPromoRow `json:"promos"`
	Totals StatsTotals       `json:"totals"`
}

type SponsorPromoRow struct {
	ID        uuid.UUID  `json:"id"`
	Kind      string     `json:"kind"`
	Placement string     `json:"placement"`
	Title     string     `json:"title"`
	Status    string     `json:"status"`
	StartsAt  *time.Time `json:"startsAt"`
	EndsAt    *time.Time `json:"endsAt"`
	StatsTotals
}

func (s *Service) handleAdminSponsorStats(ctx context.Context, in *statsReq) (*SponsorStats, error) {
	id := uuid.MustParse(in.ID)
	sp, err := s.loadSponsor(ctx, id, false)
	if err != nil {
		return nil, err
	}
	from, to, err := s.rangeOf(in)
	if err != nil {
		return nil, err
	}
	out := &SponsorStats{From: from.Format(time.DateOnly), To: to.Format(time.DateOnly), Promos: []SponsorPromoRow{}}
	out.Sponsor.ID, out.Sponsor.Name = sp.ID, sp.Name
	rows, err := s.d.Q(ctx).Query(ctx, `SELECT p.id, p.kind, p.placement, p.title_en, p.status, p.starts_at, p.ends_at,
			coalesce(sum(d.views), 0)::int, coalesce(sum(d.taps), 0)::int, coalesce(sum(d.copies), 0)::int, coalesce(sum(d.hides), 0)::int,
			(SELECT count(DISTINCT u.user_id) FROM promo_user_days u
			  WHERE u.promo_id = p.id AND u.day BETWEEN $2::date AND $3::date AND u.views > 0)::int
		FROM promos p LEFT JOIN promo_days d ON d.promo_id = p.id AND d.day BETWEEN $2::date AND $3::date
		WHERE p.sponsor_id = $1
		GROUP BY p.id ORDER BY p.created_at, p.id`, id, out.From, out.To)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	for rows.Next() {
		var r SponsorPromoRow
		if err := rows.Scan(&r.ID, &r.Kind, &r.Placement, &r.Title, &r.Status, &r.StartsAt, &r.EndsAt,
			&r.Views, &r.Taps, &r.Copies, &r.Hides, &r.Viewers); err != nil {
			return nil, err
		}
		r.StartsAt, r.EndsAt = utcPtr(r.StartsAt), utcPtr(r.EndsAt)
		r.CTR = ctr(r.Taps, r.Views)
		out.Promos = append(out.Promos, r)
		out.Totals.Views += r.Views
		out.Totals.Taps += r.Taps
		out.Totals.Copies += r.Copies
		out.Totals.Hides += r.Hides
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	if err := s.d.Q(ctx).QueryRow(ctx, `SELECT count(DISTINCT u.user_id)::int FROM promo_user_days u JOIN promos p ON p.id = u.promo_id
		WHERE p.sponsor_id = $1 AND u.day BETWEEN $2::date AND $3::date AND u.views > 0`, id, out.From, out.To).Scan(&out.Totals.Viewers); err != nil {
		return nil, err
	}
	out.Totals.CTR = ctr(out.Totals.Taps, out.Totals.Views)
	return out, nil
}
