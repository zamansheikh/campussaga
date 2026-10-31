package sponsors

import (
	"bytes"
	"context"
	"encoding/json"
	"net/url"
	"regexp"
	"slices"
	"strings"
	"time"
	"unicode"

	"github.com/google/uuid"

	"github.com/zamansheikh/varsitykotha/backend/internal/platform/db"
)

// ---- rows ---------------------------------------------------------------------------

// promo is a promos row.
type promo struct {
	ID            uuid.UUID
	SponsorID     uuid.UUID
	Kind          string
	Placement     string
	CampaignID    *uuid.UUID
	TitleEn       string
	TitleBn       string
	BodyEn        string
	BodyBn        string
	CtaEn         string
	CtaBn         string
	ImageKey      *string
	ImageVersion  *string
	LinkKind      string
	Link          string
	Code          *string
	ExpiresAt     *time.Time
	TermsEn       string
	TermsBn       string
	UniversityIDs []uuid.UUID // nil: every university
	Cities        []string    // nil: every city
	StartsAt      *time.Time
	EndsAt        *time.Time
	Status        string
	DailyCap      int16
	TotalViews    *int32
	Priority      int16
	CreatedAt     time.Time
	UpdatedAt     time.Time
}

const promoCols = `p.id, p.sponsor_id, p.kind, p.placement, p.campaign_id, p.title_en, p.title_bn, p.body_en, p.body_bn,
	p.cta_en, p.cta_bn, p.image_key, p.image_version, p.link_kind, p.link, p.code, p.expires_at, p.terms_en, p.terms_bn,
	p.university_ids, p.cities, p.starts_at, p.ends_at, p.status, p.daily_cap, p.total_views, p.priority, p.created_at, p.updated_at`

type scanner interface{ Scan(dest ...any) error }

func (p *promo) targets() []any {
	return []any{&p.ID, &p.SponsorID, &p.Kind, &p.Placement, &p.CampaignID, &p.TitleEn, &p.TitleBn, &p.BodyEn, &p.BodyBn,
		&p.CtaEn, &p.CtaBn, &p.ImageKey, &p.ImageVersion, &p.LinkKind, &p.Link, &p.Code, &p.ExpiresAt, &p.TermsEn, &p.TermsBn,
		&p.UniversityIDs, &p.Cities, &p.StartsAt, &p.EndsAt, &p.Status, &p.DailyCap, &p.TotalViews, &p.Priority, &p.CreatedAt, &p.UpdatedAt}
}

func scanPromo(r scanner) (promo, error) {
	var p promo
	err := r.Scan(p.targets()...)
	return p, err
}

func (s *Service) loadPromo(ctx context.Context, id uuid.UUID, forUpdate bool) (promo, error) {
	q := `SELECT ` + promoCols + ` FROM promos p WHERE p.id = $1`
	if forUpdate {
		q += ` FOR UPDATE`
	}
	p, err := scanPromo(s.d.Q(ctx).QueryRow(ctx, q, id))
	if db.IsNoRows(err) {
		return p, ErrPromoNotFound
	}
	return p, err
}

// imageURL: the public image path ("/promos/{id}/image?v=…"), or nil.
func (p promo) imageURL() *string {
	if p.ImageKey == nil || p.ImageVersion == nil {
		return nil
	}
	u := "/promos/" + p.ID.String() + "/image?v=" + *p.ImageVersion
	return &u
}

// sponsor is a sponsors row.
type sponsor struct {
	ID           uuid.UUID
	Name         string
	Category     string
	LogoKey      *string
	LogoVersion  *string
	Website      string
	ContactName  string
	ContactPhone string
	ContactEmail string
	Notes        string
	ArchivedAt   *time.Time
	CreatedAt    time.Time
	UpdatedAt    time.Time
}

const sponsorCols = `s.id, s.name, s.category, s.logo_key, s.logo_version, s.website, s.contact_name, s.contact_phone,
	s.contact_email, s.notes, s.archived_at, s.created_at, s.updated_at`

func scanSponsor(r scanner) (sponsor, error) {
	var x sponsor
	err := r.Scan(&x.ID, &x.Name, &x.Category, &x.LogoKey, &x.LogoVersion, &x.Website, &x.ContactName, &x.ContactPhone,
		&x.ContactEmail, &x.Notes, &x.ArchivedAt, &x.CreatedAt, &x.UpdatedAt)
	return x, err
}

func (s *Service) loadSponsor(ctx context.Context, id uuid.UUID, forUpdate bool) (sponsor, error) {
	q := `SELECT ` + sponsorCols + ` FROM sponsors s WHERE s.id = $1`
	if forUpdate {
		q += ` FOR UPDATE`
	}
	x, err := scanSponsor(s.d.Q(ctx).QueryRow(ctx, q, id))
	if db.IsNoRows(err) {
		return x, ErrSponsorNotFound
	}
	return x, err
}

// logoURL: the public logo path ("/sponsors/{id}/logo?v=…"), or nil.
func logoURL(id uuid.UUID, key, version *string) *string {
	if key == nil || version == nil {
		return nil
	}
	u := "/sponsors/" + id.String() + "/logo?v=" + *version
	return &u
}

// ---- JSON fields that can be set to null --------------------------------------------

// Nullable is a PATCH field: Set when the key was in the body; Value nil
// when it was null.
type Nullable[T any] struct {
	Set   bool
	Value *T
}

func (n *Nullable[T]) UnmarshalJSON(b []byte) error {
	n.Set = true
	if bytes.Equal(bytes.TrimSpace(b), []byte("null")) {
		n.Value = nil
		return nil
	}
	var v T
	if err := json.Unmarshal(b, &v); err != nil {
		return err
	}
	n.Value = &v
	return nil
}

// ---- kinds, placements, links --------------------------------------------------------

var (
	kinds         = []string{"deal", "card", "feed", "line", "campaign"}
	linePlacement = []string{"line:bus", "line:groups", "line:cgpa", "line:blood"}
	// Placements the app asks for (GET /promos); "campaign" comes on the
	// campaign JSON instead.
	servedPlacements = []string{"deals", "today", "campus", "line:bus", "line:groups", "line:cgpa", "line:blood"}
)

// placementFor: the only placement of a kind, or "" for line (one of four).
func placementFor(kind string) string {
	switch kind {
	case "deal":
		return "deals"
	case "card":
		return "today"
	case "feed":
		return "campus"
	case "campaign":
		return "campaign"
	}
	return ""
}

// fitsKind: placement is right for kind.
func fitsKind(kind, placement string) bool {
	if kind == "line" {
		return slices.Contains(linePlacement, placement)
	}
	return placementFor(kind) == placement
}

// AppRoutes are the app screens an ad may open (§4).
var AppRoutes = []string{"/explore", "/deals", "/bus", "/blood", "/groups", "/find-class", "/cgpa", "/campus"}

var campaignRoute = regexp.MustCompile(`^/campaigns/([0-9a-fA-F-]{36})$`)

func allowedAppRoute(link string) bool {
	if slices.Contains(AppRoutes, link) {
		return true
	}
	m := campaignRoute.FindStringSubmatch(link)
	if m == nil {
		return false
	}
	_, err := uuid.Parse(m[1])
	return err == nil
}

// validWebLink: an https URL with a host and no spaces.
func validWebLink(link string) bool {
	if strings.IndexFunc(link, unicode.IsSpace) >= 0 || !strings.HasPrefix(strings.ToLower(link), "https://") {
		return false
	}
	u, err := url.Parse(link)
	return err == nil && strings.EqualFold(u.Scheme, "https") && u.Host != "" && !strings.HasPrefix(u.Host, ".")
}

var emailRe = regexp.MustCompile(`^[^\s@]+@[^\s@]+\.[^\s@]+$`)

// normCities trims, drops empties and repeats (ignoring case), keeps order.
func normCities(in []string) []string {
	out := []string{}
	seen := map[string]bool{}
	for _, c := range in {
		c = strings.TrimSpace(c)
		k := strings.ToLower(c)
		if c == "" || seen[k] {
			continue
		}
		seen[k] = true
		out = append(out, c)
	}
	return out
}

// checkFields validates what a promo says, whatever its status: lengths are
// checked by the request tags and the database; this is the rest.
func (s *Service) checkFields(ctx context.Context, p promo, sp sponsor) error {
	if !slices.Contains(kinds, p.Kind) {
		return invalid("kind", "is not a kind of ad")
	}
	if !fitsKind(p.Kind, p.Placement) {
		return invalid("placement", "doesn't fit this kind of ad")
	}
	if p.Placement == "line:blood" && sp.Category != "health" {
		return ErrHealthOnly
	}
	if p.Kind == "campaign" {
		if p.CampaignID == nil {
			return invalid("campaignId", "is required for a campaign sponsor")
		}
		var ok bool
		if err := s.d.Q(ctx).QueryRow(ctx, `SELECT EXISTS (SELECT 1 FROM campaigns WHERE id = $1)`, *p.CampaignID).Scan(&ok); err != nil {
			return err
		}
		if !ok {
			return invalid("campaignId", "is not a campaign")
		}
	} else if p.CampaignID != nil {
		return invalid("campaignId", "is only for a campaign sponsor")
	}
	switch p.LinkKind {
	case "none":
		if p.Link != "" {
			return invalid("link", "must be empty without a link kind")
		}
	case "web":
		if !validWebLink(p.Link) {
			return invalid("link", "must be an https:// address")
		}
	case "app":
		if !allowedAppRoute(p.Link) {
			return invalid("link", "is not a screen ads may open")
		}
	default:
		return invalid("linkKind", "must be none, web or app")
	}
	if p.StartsAt != nil && p.EndsAt != nil && !p.StartsAt.Before(*p.EndsAt) {
		return invalid("endsAt", "must be after the start")
	}
	if len(p.UniversityIDs) > MaxTargetUnis {
		return invalid("universityIds", "has too many universities")
	}
	if p.UniversityIDs != nil {
		if len(p.UniversityIDs) == 0 {
			return invalid("universityIds", "must name at least one university, or be null for all")
		}
		var n int
		if err := s.d.Q(ctx).QueryRow(ctx, `SELECT count(*)::int FROM universities WHERE id = ANY($1)`, p.UniversityIDs).Scan(&n); err != nil {
			return err
		}
		if n != len(p.UniversityIDs) {
			return invalid("universityIds", "names a university that doesn't exist")
		}
	}
	if p.Cities != nil {
		if len(p.Cities) == 0 {
			return invalid("cities", "must name at least one city, or be null for all")
		}
		if len(p.Cities) > MaxTargetCity {
			return invalid("cities", "has too many cities")
		}
		for _, c := range p.Cities {
			if len([]rune(c)) > 60 {
				return invalid("cities", "has a city name that is too long")
			}
		}
	}
	return nil
}

// checkComplete is what going live needs, on top of checkFields.
func (s *Service) checkComplete(ctx context.Context, p promo, sp sponsor) error {
	if err := s.checkFields(ctx, p, sp); err != nil {
		return err
	}
	if sp.ArchivedAt != nil {
		return invalid("sponsorId", "is archived")
	}
	if p.StartsAt == nil {
		return invalid("startsAt", "is required to go live")
	}
	if p.EndsAt == nil {
		return invalid("endsAt", "is required to go live")
	}
	if !p.EndsAt.After(s.now()) {
		return invalid("endsAt", "is already past")
	}
	switch p.Kind {
	case "card", "feed":
		if strings.TrimSpace(p.TitleEn) == "" {
			return invalid("titleEn", "is required")
		}
		if p.ImageKey == nil {
			return invalid("image", "is required for this kind of ad")
		}
	case "deal":
		if strings.TrimSpace(p.TitleEn) == "" {
			return invalid("titleEn", "is required")
		}
		if p.ExpiresAt != nil && !p.ExpiresAt.After(s.now()) {
			return invalid("expiresAt", "is already past")
		}
	}
	return nil
}
