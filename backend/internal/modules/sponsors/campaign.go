package sponsors

import (
	"context"
	"time"

	"github.com/google/uuid"

	"github.com/zamansheikh/varsitykotha/backend/internal/platform/db"
)

// CampaignSponsor is "Powered by" on a prize campaign (§5).
type CampaignSponsor struct {
	Name    string  `json:"name"`
	LogoURL *string `json:"logoUrl"`
	// Link: the ad's link, else the sponsor's website; null without either.
	Link *Link `json:"link"`
}

// CampaignSponsor is the campaign's live sponsor, or nil (an untyped nil, so
// the campaign JSON says null). The growth module asks for it through a
// port wired in app.go.
func (s *Service) CampaignSponsor(ctx context.Context, campaignID uuid.UUID) (any, error) {
	var name, website, linkKind, link string
	var sponsorID uuid.UUID
	var key, version *string
	now := s.now()
	err := s.d.Q(ctx).QueryRow(ctx, `SELECT s.id, s.name, s.logo_key, s.logo_version, s.website, p.link_kind, p.link
		FROM promos p JOIN sponsors s ON s.id = p.sponsor_id
		WHERE p.kind = 'campaign' AND p.campaign_id = $1 AND p.status = 'live' AND s.archived_at IS NULL
		  AND p.starts_at <= $2 AND p.ends_at > $2
		LIMIT 1`, campaignID, now).Scan(&sponsorID, &name, &key, &version, &website, &linkKind, &link)
	if db.IsNoRows(err) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	out := &CampaignSponsor{Name: name, LogoURL: logoURL(sponsorID, key, version), Link: linkOf(linkKind, link)}
	if out.Link == nil && website != "" {
		out.Link = &Link{Kind: "web", URL: website}
	}
	return out, nil
}

// ---- sweep --------------------------------------------------------------------------

// Sweep ends ads past their end, deletes per-student rows older than
// KeepUserDays and hides that have run out.
func (s *Service) Sweep(ctx context.Context) error {
	now := s.now()
	q := s.d.Q(ctx)
	if _, err := q.Exec(ctx, `UPDATE promos SET status = 'ended', updated_at = $1
		WHERE status IN ('live', 'paused') AND ends_at IS NOT NULL AND ends_at <= $1`, now); err != nil {
		return err
	}
	cutoff := now.In(dhaka).AddDate(0, 0, -KeepUserDays).Format(time.DateOnly)
	if _, err := q.Exec(ctx, `DELETE FROM promo_user_days WHERE day < $1::date`, cutoff); err != nil {
		return err
	}
	_, err := q.Exec(ctx, `DELETE FROM promo_hides WHERE until <= $1`, now)
	return err
}

// SweepLoop runs Sweep every `every` until ctx ends.
func (s *Service) SweepLoop(ctx context.Context, every time.Duration) {
	t := time.NewTicker(every)
	defer t.Stop()
	for {
		select {
		case <-ctx.Done():
			return
		case <-t.C:
			if err := s.Sweep(ctx); err != nil {
				s.log.Error("sponsors: sweep", "err", err)
			}
		}
	}
}
