package sponsors

import (
	"context"
	"errors"
	"slices"
	"strings"
	"time"

	"github.com/google/uuid"

	"github.com/zamansheikh/varsitykotha/backend/internal/platform/auth"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/db"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/media"
)

// AdminPromo is an ad for the admin panel: both languages, targeting,
// schedule, limits, and today's and all-time counts.
type AdminPromo struct {
	ID            uuid.UUID         `json:"id"`
	Sponsor       AdminPromoSponsor `json:"sponsor"`
	Kind          string            `json:"kind"`
	Placement     string            `json:"placement"`
	CampaignID    *uuid.UUID        `json:"campaignId"`
	TitleEn       string            `json:"titleEn"`
	TitleBn       string            `json:"titleBn"`
	BodyEn        string            `json:"bodyEn"`
	BodyBn        string            `json:"bodyBn"`
	CtaEn         string            `json:"ctaEn"`
	CtaBn         string            `json:"ctaBn"`
	ImageURL      *string           `json:"imageUrl"`
	LinkKind      string            `json:"linkKind"`
	Link          string            `json:"link"`
	Code          *string           `json:"code"`
	ExpiresAt     *time.Time        `json:"expiresAt"`
	TermsEn       string            `json:"termsEn"`
	TermsBn       string            `json:"termsBn"`
	UniversityIDs []uuid.UUID       `json:"universityIds"` // null: all
	Cities        []string          `json:"cities"`        // null: all
	StartsAt      *time.Time        `json:"startsAt"`
	EndsAt        *time.Time        `json:"endsAt"`
	Status        string            `json:"status"`
	// Delivered: totalViews reached; a live ad is then no longer shown.
	Delivered  bool       `json:"delivered"`
	DailyCap   int        `json:"dailyCap"`
	TotalViews *int       `json:"totalViews"`
	Priority   int        `json:"priority"`
	Stats      PromoCount `json:"stats"`
	CreatedAt  time.Time  `json:"createdAt"`
	UpdatedAt  time.Time  `json:"updatedAt"`
}

type AdminPromoSponsor struct {
	ID       uuid.UUID `json:"id"`
	Name     string    `json:"name"`
	Category string    `json:"category"`
	LogoURL  *string   `json:"logoUrl"`
	Archived bool      `json:"archived"`
}

// PromoCount: views and taps today (Asia/Dhaka) and in all.
type PromoCount struct {
	ViewsToday int `json:"viewsToday"`
	TapsToday  int `json:"tapsToday"`
	Views      int `json:"views"`
	Taps       int `json:"taps"`
}

// adminPromoSQL selects an ad with its sponsor and counts; $1 is today.
const adminPromoSQL = `SELECT ` + promoCols + `, s.name, s.category, s.logo_key, s.logo_version, s.archived_at IS NOT NULL,
	coalesce((SELECT d.views FROM promo_days d WHERE d.promo_id = p.id AND d.day = $1::date), 0)::int,
	coalesce((SELECT d.taps FROM promo_days d WHERE d.promo_id = p.id AND d.day = $1::date), 0)::int,
	coalesce((SELECT sum(d.views) FROM promo_days d WHERE d.promo_id = p.id), 0)::int,
	coalesce((SELECT sum(d.taps) FROM promo_days d WHERE d.promo_id = p.id), 0)::int
	FROM promos p JOIN sponsors s ON s.id = p.sponsor_id`

func scanAdminPromo(r scanner) (AdminPromo, error) {
	var p promo
	var sp AdminPromoSponsor
	var logoKey, logoVersion *string
	var c PromoCount
	dest := append(p.targets(), &sp.Name, &sp.Category, &logoKey, &logoVersion, &sp.Archived,
		&c.ViewsToday, &c.TapsToday, &c.Views, &c.Taps)
	if err := r.Scan(dest...); err != nil {
		return AdminPromo{}, err
	}
	sp.ID, sp.LogoURL = p.SponsorID, logoURL(p.SponsorID, logoKey, logoVersion)
	return adminView(p, sp, c), nil
}

func adminView(p promo, sp AdminPromoSponsor, c PromoCount) AdminPromo {
	v := AdminPromo{
		ID: p.ID, Sponsor: sp, Kind: p.Kind, Placement: p.Placement, CampaignID: p.CampaignID,
		TitleEn: p.TitleEn, TitleBn: p.TitleBn, BodyEn: p.BodyEn, BodyBn: p.BodyBn, CtaEn: p.CtaEn, CtaBn: p.CtaBn,
		ImageURL: p.imageURL(), LinkKind: p.LinkKind, Link: p.Link, Code: p.Code, ExpiresAt: utcPtr(p.ExpiresAt),
		TermsEn: p.TermsEn, TermsBn: p.TermsBn, UniversityIDs: p.UniversityIDs, Cities: p.Cities,
		StartsAt: utcPtr(p.StartsAt), EndsAt: utcPtr(p.EndsAt), Status: p.Status,
		DailyCap: int(p.DailyCap), Priority: int(p.Priority), Stats: c,
		CreatedAt: p.CreatedAt.UTC(), UpdatedAt: p.UpdatedAt.UTC(),
	}
	if p.TotalViews != nil {
		n := int(*p.TotalViews)
		v.TotalViews = &n
		v.Delivered = c.Views >= n
	}
	return v
}

func (s *Service) adminPromo(ctx context.Context, id uuid.UUID) (*AdminPromo, error) {
	v, err := scanAdminPromo(s.d.Q(ctx).QueryRow(ctx, adminPromoSQL+` WHERE p.id = $2`, dhakaDay(s.now()), id))
	if db.IsNoRows(err) {
		return nil, ErrPromoNotFound
	}
	if err != nil {
		return nil, err
	}
	return &v, nil
}

// ---- list ---------------------------------------------------------------------------

type promoListReq struct {
	Page      string `json:"-" query:"page" validate:"omitempty,number,min=1,max=1000"`
	PageSize  string `json:"-" query:"pageSize" validate:"omitempty,number"`
	Status    string `json:"-" query:"status" validate:"omitempty,oneof=draft live paused ended"`
	Kind      string `json:"-" query:"kind" validate:"omitempty,oneof=deal card feed line campaign"`
	Placement string `json:"-" query:"placement" validate:"omitempty,oneof=deals today campus line:bus line:groups line:cgpa line:blood campaign"`
	SponsorID string `json:"-" query:"sponsorId" validate:"omitempty,uuid"`
	Q         string `json:"-" query:"q" validate:"max=80"`
}

func (s *Service) handleAdminPromos(ctx context.Context, in *promoListReq) (*Page[AdminPromo], error) {
	page, size := pageOf(in.Page, in.PageSize)
	var sponsorID *uuid.UUID
	if in.SponsorID != "" {
		id := uuid.MustParse(in.SponsorID)
		sponsorID = &id
	}
	q := strings.TrimSpace(in.Q)
	where := ` WHERE ($2 = '' OR p.status = $2) AND ($3 = '' OR p.kind = $3) AND ($4 = '' OR p.placement = $4)
		AND ($5::uuid IS NULL OR p.sponsor_id = $5)
		AND ($6 = '' OR p.title_en ILIKE '%' || $6 || '%' OR p.title_bn ILIKE '%' || $6 || '%' OR s.name ILIKE '%' || $6 || '%')`
	out := &Page[AdminPromo]{Items: []AdminPromo{}, Page: page, PageSize: size}
	dq := s.d.Q(ctx)
	today := dhakaDay(s.now())
	if err := dq.QueryRow(ctx, `SELECT count(*)::int FROM promos p JOIN sponsors s ON s.id = p.sponsor_id`+where+` AND $1::date IS NOT NULL`,
		today, in.Status, in.Kind, in.Placement, sponsorID, q).Scan(&out.Total); err != nil {
		return nil, err
	}
	// Live first, then drafts and paused, then ended; newest first within.
	rows, err := dq.Query(ctx, adminPromoSQL+where+` ORDER BY CASE p.status WHEN 'live' THEN 0 WHEN 'draft' THEN 1 WHEN 'paused' THEN 2 ELSE 3 END,
		p.created_at DESC, p.id LIMIT $7 OFFSET $8`, today, in.Status, in.Kind, in.Placement, sponsorID, q, size, (page-1)*size)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	for rows.Next() {
		v, err := scanAdminPromo(rows)
		if err != nil {
			return nil, err
		}
		out.Items = append(out.Items, v)
	}
	return out, rows.Err()
}

type promoReq struct {
	ID string `json:"-" path:"id" validate:"required,uuid"`
}

func (s *Service) handleAdminPromo(ctx context.Context, in *promoReq) (*AdminPromo, error) {
	return s.adminPromo(ctx, uuid.MustParse(in.ID))
}

// ---- create and edit ----------------------------------------------------------------

// promoInput is the body of create and PATCH. Nullable fields take null to
// clear them (universityIds/cities null: everyone; totalViews null: no limit).
type promoInput struct {
	ID         string              `json:"-" path:"id" validate:"omitempty,uuid"`
	SponsorID  *string             `json:"sponsorId" validate:"omitnil,uuid"`
	Kind       *string             `json:"kind" validate:"omitnil,oneof=deal card feed line campaign"`
	Placement  *string             `json:"placement" validate:"omitnil,oneof=deals today campus line:bus line:groups line:cgpa line:blood campaign"`
	CampaignID Nullable[uuid.UUID] `json:"campaignId"`
	TitleEn    *string             `json:"titleEn" validate:"omitnil,max=60"`
	TitleBn    *string             `json:"titleBn" validate:"omitnil,max=60"`
	BodyEn     *string             `json:"bodyEn" validate:"omitnil,max=140"`
	BodyBn     *string             `json:"bodyBn" validate:"omitnil,max=140"`
	CtaEn      *string             `json:"ctaEn" validate:"omitnil,max=20"`
	CtaBn      *string             `json:"ctaBn" validate:"omitnil,max=20"`
	LinkKind   *string             `json:"linkKind" validate:"omitnil,oneof=none web app"`
	Link       *string             `json:"link" validate:"omitnil,max=500"`
	Code       Nullable[string]    `json:"code"`
	ExpiresAt  Nullable[time.Time] `json:"expiresAt"`
	TermsEn    *string             `json:"termsEn" validate:"omitnil,max=500"`
	TermsBn    *string             `json:"termsBn" validate:"omitnil,max=500"`
	// Targeting: null for everyone.
	UniversityIDs Nullable[[]uuid.UUID] `json:"universityIds"`
	Cities        Nullable[[]string]    `json:"cities"`
	StartsAt      Nullable[time.Time]   `json:"startsAt"`
	EndsAt        Nullable[time.Time]   `json:"endsAt"`
	DailyCap      *int                  `json:"dailyCap" validate:"omitnil,min=1,max=20"`
	TotalViews    Nullable[int]         `json:"totalViews"`
	Priority      *int                  `json:"priority" validate:"omitnil,min=1,max=10"`
	// Status (PATCH only): the same as POST /admin/promos/{id}/status.
	Status *string `json:"status" validate:"omitnil,oneof=live paused ended"`
}

// onlyLiveEditable: nothing but what may change while an ad is live (§4).
func (in *promoInput) onlyLiveEditable() bool {
	return in.SponsorID == nil && in.Kind == nil && in.Placement == nil && !in.CampaignID.Set &&
		in.TitleEn == nil && in.TitleBn == nil && in.BodyEn == nil && in.BodyBn == nil && in.CtaEn == nil && in.CtaBn == nil &&
		in.LinkKind == nil && in.Link == nil && !in.Code.Set && !in.ExpiresAt.Set && in.TermsEn == nil && in.TermsBn == nil &&
		!in.UniversityIDs.Set && !in.Cities.Set && !in.StartsAt.Set
}

// apply copies the set fields onto p.
func (in *promoInput) apply(p *promo) error {
	trim := func(v *string) string { return strings.TrimSpace(*v) }
	if in.Kind != nil {
		p.Kind = *in.Kind
		if in.Placement == nil {
			p.Placement = placementFor(p.Kind)
		}
	}
	if in.Placement != nil {
		p.Placement = *in.Placement
	}
	if in.CampaignID.Set {
		p.CampaignID = in.CampaignID.Value
	}
	set := func(dst *string, v *string) {
		if v != nil {
			*dst = trim(v)
		}
	}
	set(&p.TitleEn, in.TitleEn)
	set(&p.TitleBn, in.TitleBn)
	set(&p.BodyEn, in.BodyEn)
	set(&p.BodyBn, in.BodyBn)
	set(&p.CtaEn, in.CtaEn)
	set(&p.CtaBn, in.CtaBn)
	set(&p.LinkKind, in.LinkKind)
	set(&p.Link, in.Link)
	set(&p.TermsEn, in.TermsEn)
	set(&p.TermsBn, in.TermsBn)
	if in.LinkKind != nil && *in.LinkKind == "none" && in.Link == nil {
		p.Link = ""
	}
	if in.Code.Set {
		p.Code = nil
		if in.Code.Value != nil {
			if c := strings.TrimSpace(*in.Code.Value); c != "" {
				if len([]rune(c)) > 30 {
					return invalid("code", "is too long")
				}
				p.Code = &c
			}
		}
	}
	if in.ExpiresAt.Set {
		p.ExpiresAt = in.ExpiresAt.Value
	}
	if in.UniversityIDs.Set {
		p.UniversityIDs = nil
		if in.UniversityIDs.Value != nil {
			ids := slices.Clone(*in.UniversityIDs.Value)
			slices.SortFunc(ids, func(a, b uuid.UUID) int { return strings.Compare(a.String(), b.String()) })
			p.UniversityIDs = slices.Compact(ids)
			if p.UniversityIDs == nil {
				p.UniversityIDs = []uuid.UUID{}
			}
		}
	}
	if in.Cities.Set {
		p.Cities = nil
		if in.Cities.Value != nil {
			p.Cities = normCities(*in.Cities.Value)
		}
	}
	if in.StartsAt.Set {
		p.StartsAt = in.StartsAt.Value
	}
	if in.EndsAt.Set {
		p.EndsAt = in.EndsAt.Value
	}
	if in.DailyCap != nil {
		p.DailyCap = int16(*in.DailyCap)
	}
	if in.TotalViews.Set {
		p.TotalViews = nil
		if in.TotalViews.Value != nil {
			if *in.TotalViews.Value < 1 {
				return invalid("totalViews", "must be at least 1, or null for no limit")
			}
			n := int32(*in.TotalViews.Value)
			p.TotalViews = &n
		}
	}
	if in.Priority != nil {
		p.Priority = int16(*in.Priority)
	}
	return nil
}

func (s *Service) handleAdminPromoCreate(ctx context.Context, in *promoInput) (*AdminPromo, error) {
	if in.SponsorID == nil {
		return nil, invalid("sponsorId", "is required")
	}
	if in.Kind == nil {
		return nil, invalid("kind", "is required")
	}
	if in.Status != nil {
		return nil, invalid("status", "a new ad starts as a draft")
	}
	p := promo{LinkKind: "none", Status: "draft", DailyCap: DefaultDayCap, Priority: DefaultPriority}
	if err := in.apply(&p); err != nil {
		return nil, err
	}
	sp, err := s.loadSponsor(ctx, uuid.MustParse(*in.SponsorID), false)
	if errors.Is(err, ErrSponsorNotFound) {
		return nil, invalid("sponsorId", "is not a sponsor")
	}
	if err != nil {
		return nil, err
	}
	if sp.ArchivedAt != nil {
		return nil, invalid("sponsorId", "is archived")
	}
	p.SponsorID = sp.ID
	if err := s.checkFields(ctx, p, sp); err != nil {
		return nil, err
	}
	var id uuid.UUID
	err = s.d.InTx(ctx, func(ctx context.Context) error {
		now := s.now()
		if err := s.d.Q(ctx).QueryRow(ctx, `INSERT INTO promos (sponsor_id, kind, placement, campaign_id, title_en, title_bn, body_en, body_bn,
				cta_en, cta_bn, link_kind, link, code, expires_at, terms_en, terms_bn, university_ids, cities, starts_at, ends_at,
				daily_cap, total_views, priority, created_by, created_at, updated_at)
			VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21, $22, $23, $24, $25, $25)
			RETURNING id`,
			p.SponsorID, p.Kind, p.Placement, p.CampaignID, p.TitleEn, p.TitleBn, p.BodyEn, p.BodyBn, p.CtaEn, p.CtaBn,
			p.LinkKind, p.Link, p.Code, p.ExpiresAt, p.TermsEn, p.TermsBn, p.UniversityIDs, p.Cities, p.StartsAt, p.EndsAt,
			p.DailyCap, p.TotalViews, p.Priority, auth.MustUser(ctx).UserID, now).Scan(&id); err != nil {
			return err
		}
		return s.audit(ctx, "promo.create", "promo", id.String(), map[string]any{"sponsor": sp.Name, "kind": p.Kind, "title": p.TitleEn})
	})
	if err != nil {
		return nil, err
	}
	return s.adminPromo(ctx, id)
}

func (s *Service) handleAdminPromoPatch(ctx context.Context, in *promoInput) (*AdminPromo, error) {
	id, err := uuid.Parse(in.ID)
	if err != nil {
		return nil, ErrPromoNotFound
	}
	err = s.d.InTx(ctx, func(ctx context.Context) error {
		p, err := s.loadPromo(ctx, id, true)
		if err != nil {
			return err
		}
		switch p.Status {
		case "ended":
			return ErrPromoLocked.WithMessage("This ad has ended; duplicate it to run it again")
		case "live":
			if !in.onlyLiveEditable() {
				return ErrPromoLocked
			}
		}
		sponsorID := p.SponsorID
		if in.SponsorID != nil {
			sponsorID = uuid.MustParse(*in.SponsorID)
		}
		sp, err := s.loadSponsor(ctx, sponsorID, false)
		if errors.Is(err, ErrSponsorNotFound) {
			return invalid("sponsorId", "is not a sponsor")
		}
		if err != nil {
			return err
		}
		if sponsorID != p.SponsorID && sp.ArchivedAt != nil {
			return invalid("sponsorId", "is archived")
		}
		p.SponsorID = sponsorID
		if err := in.apply(&p); err != nil {
			return err
		}
		if err := s.checkFields(ctx, p, sp); err != nil {
			return err
		}
		if p.Status == "live" && p.EndsAt != nil && !p.EndsAt.After(s.now()) {
			return invalid("endsAt", "is already past")
		}
		now := s.now()
		if _, err := s.d.Q(ctx).Exec(ctx, `UPDATE promos SET sponsor_id = $2, kind = $3, placement = $4, campaign_id = $5, title_en = $6,
				title_bn = $7, body_en = $8, body_bn = $9, cta_en = $10, cta_bn = $11, link_kind = $12, link = $13, code = $14,
				expires_at = $15, terms_en = $16, terms_bn = $17, university_ids = $18, cities = $19, starts_at = $20, ends_at = $21,
				daily_cap = $22, total_views = $23, priority = $24, updated_at = $25 WHERE id = $1`,
			id, p.SponsorID, p.Kind, p.Placement, p.CampaignID, p.TitleEn, p.TitleBn, p.BodyEn, p.BodyBn, p.CtaEn, p.CtaBn,
			p.LinkKind, p.Link, p.Code, p.ExpiresAt, p.TermsEn, p.TermsBn, p.UniversityIDs, p.Cities, p.StartsAt, p.EndsAt,
			p.DailyCap, p.TotalViews, p.Priority, now); err != nil {
			return err
		}
		if err := s.audit(ctx, "promo.update", "promo", id.String(), map[string]any{"title": p.TitleEn}); err != nil {
			return err
		}
		if in.Status != nil && *in.Status != p.Status {
			return s.setStatus(ctx, p, sp, *in.Status)
		}
		return nil
	})
	if err != nil {
		return nil, err
	}
	return s.adminPromo(ctx, id)
}

// ---- status -------------------------------------------------------------------------

type statusReq struct {
	ID     string `json:"-" path:"id" validate:"required,uuid"`
	Status string `json:"status" validate:"required,oneof=live paused ended"`
}

func (s *Service) handleAdminPromoStatus(ctx context.Context, in *statusReq) (*AdminPromo, error) {
	id := uuid.MustParse(in.ID)
	err := s.d.InTx(ctx, func(ctx context.Context) error {
		p, err := s.loadPromo(ctx, id, true)
		if err != nil {
			return err
		}
		if p.Status == in.Status {
			return nil
		}
		sp, err := s.loadSponsor(ctx, p.SponsorID, false)
		if err != nil {
			return err
		}
		return s.setStatus(ctx, p, sp, in.Status)
	})
	if err != nil {
		return nil, err
	}
	return s.adminPromo(ctx, id)
}

// setStatus moves an ad: draft → live, live ⇄ paused, live/paused → ended.
// Going live checks the whole ad.
func (s *Service) setStatus(ctx context.Context, p promo, sp sponsor, to string) error {
	allowed := map[string][]string{
		"draft":  {"live"},
		"live":   {"paused", "ended"},
		"paused": {"live", "ended"},
	}
	if !slices.Contains(allowed[p.Status], to) {
		return ErrPromoLocked.WithMessage("An ad can't go from %s to %s", p.Status, to)
	}
	if to == "live" {
		if err := s.checkComplete(ctx, p, sp); err != nil {
			return err
		}
	}
	_, err := s.d.Q(ctx).Exec(ctx, `UPDATE promos SET status = $2, updated_at = $3 WHERE id = $1`, p.ID, to, s.now())
	if db.IsUniqueViolation(err, "promos_campaign_live_idx") {
		return invalid("campaignId", "already has a live sponsor")
	}
	if err != nil {
		return err
	}
	return s.audit(ctx, "promo.status", "promo", p.ID.String(), map[string]any{"from": p.Status, "to": to, "title": p.TitleEn})
}

// ---- delete and duplicate -----------------------------------------------------------

// handleAdminPromoDelete deletes a draft (anything else keeps its reports).
func (s *Service) handleAdminPromoDelete(ctx context.Context, in *promoReq) (*struct{}, error) {
	id := uuid.MustParse(in.ID)
	var key *string
	err := s.d.InTx(ctx, func(ctx context.Context) error {
		p, err := s.loadPromo(ctx, id, true)
		if err != nil {
			return err
		}
		if p.Status != "draft" {
			return ErrPromoLocked.WithMessage("Only a draft can be deleted; end the ad instead")
		}
		key = p.ImageKey
		if _, err := s.d.Q(ctx).Exec(ctx, `DELETE FROM promos WHERE id = $1`, id); err != nil {
			return err
		}
		return s.audit(ctx, "promo.delete", "promo", id.String(), map[string]any{"title": p.TitleEn})
	})
	if err != nil {
		return nil, err
	}
	s.dropFile(key)
	return nil, nil
}

// handleAdminPromoDuplicate copies an ad (and its image) as a new draft.
func (s *Service) handleAdminPromoDuplicate(ctx context.Context, in *promoReq) (*AdminPromo, error) {
	src, err := s.loadPromo(ctx, uuid.MustParse(in.ID), false)
	if err != nil {
		return nil, err
	}
	newID := uuid.New()
	var imgKey, imgVersion *string
	if src.ImageKey != nil && s.media != nil {
		data, err := s.readFile(*src.ImageKey)
		if err != nil && !errors.Is(err, media.ErrNotFound) {
			return nil, err
		}
		if err == nil {
			v := newVersion()
			k := promoImageKey(newID, v)
			if err := s.media.Put(k, data); err != nil {
				return nil, err
			}
			imgKey, imgVersion = &k, &v
		}
	}
	err = s.d.InTx(ctx, func(ctx context.Context) error {
		now := s.now()
		if _, err := s.d.Q(ctx).Exec(ctx, `INSERT INTO promos (id, sponsor_id, kind, placement, campaign_id, title_en, title_bn, body_en,
				body_bn, cta_en, cta_bn, image_key, image_version, link_kind, link, code, expires_at, terms_en, terms_bn, university_ids,
				cities, starts_at, ends_at, status, daily_cap, total_views, priority, created_by, created_at, updated_at)
			SELECT $2, sponsor_id, kind, placement, campaign_id, title_en, title_bn, body_en, body_bn, cta_en, cta_bn, $3, $4,
				link_kind, link, code, expires_at, terms_en, terms_bn, university_ids, cities, starts_at, ends_at, 'draft', daily_cap,
				total_views, priority, $5, $6, $6
			FROM promos WHERE id = $1`, src.ID, newID, imgKey, imgVersion, auth.MustUser(ctx).UserID, now); err != nil {
			return err
		}
		return s.audit(ctx, "promo.duplicate", "promo", newID.String(), map[string]any{"from": src.ID.String(), "title": src.TitleEn})
	})
	if err != nil {
		s.dropFile(imgKey)
		return nil, err
	}
	return s.adminPromo(ctx, newID)
}
