package sponsors

import (
	"context"
	"crypto/sha256"
	"encoding/binary"
	"math"
	"sort"
	"strings"
	"time"

	"github.com/google/uuid"

	"github.com/zamansheikh/varsitykotha/backend/internal/platform/auth"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/db"
)

// ---- who is asking ------------------------------------------------------------------

// viewer: the signed-in student, their university and its city. Staff
// (anyone who isn't a student) see ads, but their events aren't counted.
type viewer struct {
	ID        uuid.UUID
	Staff     bool
	Uni       *uuid.UUID
	UniName   string
	UniNameBn string
	City      *string
}

func (s *Service) viewer(ctx context.Context) (viewer, error) {
	me := auth.MustUser(ctx)
	v := viewer{ID: me.UserID}
	var role string
	var name, nameBn *string
	err := s.d.Q(ctx).QueryRow(ctx, `SELECT u.role::text, u.university_id, un.name, un.name_bn, nullif(trim(un.city), '')
		FROM users u LEFT JOIN universities un ON un.id = u.university_id WHERE u.id = $1`, me.UserID).
		Scan(&role, &v.Uni, &name, &nameBn, &v.City)
	if err != nil {
		return v, err
	}
	v.Staff = role != "student"
	if name != nil {
		v.UniName = *name
	}
	if nameBn != nil {
		v.UniNameBn = *nameBn
	}
	return v, nil
}

// ---- what may be shown --------------------------------------------------------------

// eligibleSQL: live ads of a placement ($1) for a viewer at $2 (now), with
// university $3 and city $4, student $5, today $6 (Asia/Dhaka):
// in their dates, the sponsor not archived, targeting matches, not
// delivered (total views), not hidden by the student, under the student's
// daily cap (cards and feed posts), a deal not expired, and the Blood page
// for health sponsors only.
const eligibleSQL = `SELECT ` + promoCols + `, s.name, s.category, s.logo_key, s.logo_version
	FROM promos p JOIN sponsors s ON s.id = p.sponsor_id
	WHERE p.status = 'live' AND p.placement = $1 AND p.starts_at <= $2 AND p.ends_at > $2
	  AND s.archived_at IS NULL
	  AND (p.university_ids IS NULL OR $3::uuid = ANY (p.university_ids))
	  AND (p.cities IS NULL OR EXISTS (SELECT 1 FROM unnest(p.cities) c WHERE lower(c) = lower($4::text)))
	  AND (p.total_views IS NULL OR coalesce((SELECT sum(d.views) FROM promo_days d WHERE d.promo_id = p.id), 0) < p.total_views)
	  AND NOT EXISTS (SELECT 1 FROM promo_hides h WHERE h.user_id = $5 AND h.promo_id = p.id AND h.until > $2)
	  AND (p.kind NOT IN ('card', 'feed') OR coalesce((SELECT u.views FROM promo_user_days u
	        WHERE u.promo_id = p.id AND u.user_id = $5 AND u.day = $6::date), 0) < p.daily_cap)
	  AND (p.placement <> 'line:blood' OR s.category = 'health')
	  AND (p.expires_at IS NULL OR p.expires_at > $2)`

// servable is an eligible ad with its sponsor.
type servable struct {
	promo
	SponsorName     string
	SponsorCategory string
	LogoKey         *string
	LogoVersion     *string
}

func (s *Service) eligible(ctx context.Context, v viewer, placement string) ([]servable, error) {
	now := s.now()
	rows, err := s.d.Q(ctx).Query(ctx, eligibleSQL, placement, now, v.Uni, v.City, v.ID, dhakaDay(now))
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var out []servable
	for rows.Next() {
		var x servable
		dest := append(x.targets(), &x.SponsorName, &x.SponsorCategory, &x.LogoKey, &x.LogoVersion)
		if err := rows.Scan(dest...); err != nil {
			return nil, err
		}
		out = append(out, x)
	}
	return out, rows.Err()
}

// ---- picking ------------------------------------------------------------------------

// weightedOrder orders ads for one student, day and placement: a weighted
// random order (Efraimidis–Spirakis: key = ln(u) / priority, highest
// first) where u comes from hash(student, day, placement, ad), so the order
// is the same all day and the first is chosen with odds proportional to
// priority.
func weightedOrder(ads []servable, user uuid.UUID, day, placement string) []servable {
	type keyed struct {
		ad  servable
		key float64
	}
	ks := make([]keyed, len(ads))
	for i, a := range ads {
		ks[i] = keyed{a, pickKey(user, day, placement, a.ID, float64(a.Priority))}
	}
	sort.SliceStable(ks, func(i, j int) bool {
		if ks[i].key != ks[j].key {
			return ks[i].key > ks[j].key
		}
		return ks[i].ad.ID.String() < ks[j].ad.ID.String()
	})
	out := make([]servable, len(ks))
	for i, k := range ks {
		out[i] = k.ad
	}
	return out
}

// pickKey is ln(u) / weight with u in (0, 1] from the hash.
func pickKey(user uuid.UUID, day, placement string, ad uuid.UUID, weight float64) float64 {
	h := sha256.New()
	h.Write(user[:])
	h.Write([]byte("|" + day + "|" + placement + "|"))
	h.Write(ad[:])
	x := binary.BigEndian.Uint64(h.Sum(nil)[:8]) >> 11 // 53 bits
	u := (float64(x) + 1) / float64(uint64(1)<<53)
	return math.Log(u) / math.Max(weight, 1)
}

// ---- GET /promos --------------------------------------------------------------------

// Promo is an ad as the app draws it, in the student's language.
type Promo struct {
	ID        uuid.UUID    `json:"id"`
	Kind      string       `json:"kind"`
	Placement string       `json:"placement"`
	Sponsor   PromoSponsor `json:"sponsor"`
	Title     string       `json:"title"`
	Body      string       `json:"body"`
	Cta       string       `json:"cta"`
	ImageURL  *string      `json:"imageUrl"`
	Link      *Link        `json:"link"`
	Code      *string      `json:"code"`
	ExpiresAt *time.Time   `json:"expiresAt"`
	Terms     string       `json:"terms"`
	// Targeted: shown only to some universities or cities ("Near you").
	Targeted bool `json:"targeted"`
	// Why: why this student sees it ("Shown to students at …").
	Why string `json:"why"`
}

type PromoSponsor struct {
	Name     string  `json:"name"`
	LogoURL  *string `json:"logoUrl"`
	Category string  `json:"category"`
}

// Link is where the button goes: a website (kind "web") or an app screen
// (kind "app").
type Link struct {
	Kind string `json:"kind"`
	URL  string `json:"url"`
}

func linkOf(kind, link string) *Link {
	if kind == "none" || link == "" {
		return nil
	}
	return &Link{Kind: kind, URL: link}
}

type promosReq struct {
	Placement string `json:"-" query:"placement" validate:"required,oneof=deals today campus line:bus line:groups line:cgpa line:blood"`
}

type PromoList struct {
	Items []Promo `json:"items"`
}

func (s *Service) handlePromos(ctx context.Context, in *promosReq) (*PromoList, error) {
	v, err := s.viewer(ctx)
	if err != nil {
		return nil, err
	}
	ads, err := s.eligible(ctx, v, in.Placement)
	if err != nil {
		return nil, err
	}
	limit := 1
	switch in.Placement {
	case "deals":
		limit = MaxDeals
		sort.SliceStable(ads, func(i, j int) bool {
			a, b := ads[i], ads[j]
			if a.Priority != b.Priority {
				return a.Priority > b.Priority
			}
			if !a.EndsAt.Equal(*b.EndsAt) {
				return a.EndsAt.Before(*b.EndsAt)
			}
			return a.ID.String() < b.ID.String()
		})
	case "campus":
		limit = MaxCampus
		ads = weightedOrder(ads, v.ID, dhakaDay(s.now()), in.Placement)
	default:
		ads = weightedOrder(ads, v.ID, dhakaDay(s.now()), in.Placement)
	}
	if len(ads) > limit {
		ads = ads[:limit]
	}
	l := lang(ctx)
	out := &PromoList{Items: make([]Promo, 0, len(ads))}
	for _, a := range ads {
		out.Items = append(out.Items, a.view(l, v))
	}
	return out, nil
}

func (a servable) view(l string, v viewer) Promo {
	p := Promo{
		ID: a.ID, Kind: a.Kind, Placement: a.Placement,
		Sponsor: PromoSponsor{Name: a.SponsorName, LogoURL: logoURL(a.SponsorID, a.LogoKey, a.LogoVersion), Category: a.SponsorCategory},
		Title:   pick(l, a.TitleEn, a.TitleBn), Body: pick(l, a.BodyEn, a.BodyBn), Cta: pick(l, a.CtaEn, a.CtaBn),
		ImageURL: a.imageURL(), Link: linkOf(a.LinkKind, a.Link), Code: a.Code, ExpiresAt: utcPtr(a.ExpiresAt),
		Terms: pick(l, a.TermsEn, a.TermsBn), Targeted: a.UniversityIDs != nil || a.Cities != nil,
	}
	p.Why = whyText(l, a.promo, v)
	return p
}

// whyText says why a student sees an ad (§0.7).
func whyText(l string, p promo, v viewer) string {
	uni := v.UniName
	if l == "bn" && strings.TrimSpace(v.UniNameBn) != "" {
		uni = v.UniNameBn
	}
	switch {
	case p.UniversityIDs != nil && uni != "":
		if l == "bn" {
			return uni + "-এর শিক্ষার্থীদের দেখানো হচ্ছে"
		}
		return "Shown to students at " + uni
	case p.Cities != nil && v.City != nil:
		if l == "bn" {
			return *v.City + "-এর শিক্ষার্থীদের দেখানো হচ্ছে"
		}
		return "Shown to students in " + *v.City
	}
	if l == "bn" {
		return "সব শিক্ষার্থীকে দেখানো হচ্ছে"
	}
	return "Shown to all students"
}

// ---- POST /promos/events ------------------------------------------------------------

type eventsReq struct {
	Events []eventIn `json:"events" validate:"required,min=1,max=50,dive"`
}

type eventIn struct {
	PromoID string `json:"promoId" validate:"required,uuid"`
	Type    string `json:"type" validate:"required,oneof=view tap copy hide"`
	// At: when it happened on the phone; informational (the server's clock
	// decides the day).
	At *time.Time `json:"at"`
}

// handleEvents counts views, taps, copies and hides. Each view, tap and copy
// counts up to MaxPerUserDay times per ad, student and day; a hide hides the
// ad for HideDays (and counts once while it lasts). Events for ads the
// student couldn't be shown (not live, not targeted to them) and all staff
// events are ignored. Nothing is reported back.
func (s *Service) handleEvents(ctx context.Context, in *eventsReq) (*struct{}, error) {
	v, err := s.viewer(ctx)
	if err != nil {
		return nil, err
	}
	if v.Staff {
		return nil, nil
	}
	ids := make([]uuid.UUID, 0, len(in.Events))
	seen := map[uuid.UUID]bool{}
	for _, e := range in.Events {
		id := uuid.MustParse(e.PromoID)
		if !seen[id] {
			seen[id] = true
			ids = append(ids, id)
		}
	}
	now := s.now()
	day := dhakaDay(now)
	return nil, s.d.InTx(ctx, func(ctx context.Context) error {
		q := s.d.Q(ctx)
		ok, err := s.countable(ctx, v, ids, now)
		if err != nil {
			return err
		}
		type sums struct{ views, viewers, taps, copies, hides int }
		totals := map[uuid.UUID]*sums{}
		for _, e := range in.Events {
			id := uuid.MustParse(e.PromoID)
			if !ok[id] {
				continue
			}
			t := totals[id]
			if t == nil {
				t = &sums{}
				totals[id] = t
			}
			switch e.Type {
			case "view", "tap", "copy":
				col := map[string]string{"view": "views", "tap": "taps", "copy": "copies"}[e.Type]
				var n int16
				err := q.QueryRow(ctx, `INSERT INTO promo_user_days (promo_id, user_id, day, `+col+`) VALUES ($1, $2, $3, 1)
					ON CONFLICT (promo_id, user_id, day) DO UPDATE SET `+col+` = promo_user_days.`+col+` + 1
					WHERE promo_user_days.`+col+` < $4
					RETURNING `+col, id, v.ID, day, MaxPerUserDay).Scan(&n)
				if db.IsNoRows(err) {
					continue // over the daily cap
				}
				if err != nil {
					return err
				}
				switch e.Type {
				case "view":
					t.views++
					if n == 1 {
						t.viewers++
					}
				case "tap":
					t.taps++
				default:
					t.copies++
				}
			case "hide":
				// A hide counts once while it lasts; hiding again extends it.
				var active bool
				if err := q.QueryRow(ctx, `SELECT EXISTS (SELECT 1 FROM promo_hides WHERE user_id = $1 AND promo_id = $2 AND until > $3)`,
					v.ID, id, now).Scan(&active); err != nil {
					return err
				}
				if _, err := q.Exec(ctx, `INSERT INTO promo_hides (user_id, promo_id, until) VALUES ($1, $2, $3)
					ON CONFLICT (user_id, promo_id) DO UPDATE SET until = EXCLUDED.until`,
					v.ID, id, now.Add(HideDays*24*time.Hour)); err != nil {
					return err
				}
				if !active {
					t.hides++
				}
			}
		}
		for id, t := range totals {
			if *t == (sums{}) {
				continue
			}
			if _, err := q.Exec(ctx, `INSERT INTO promo_days (promo_id, day, views, viewers, taps, copies, hides)
				VALUES ($1, $2, $3, $4, $5, $6, $7)
				ON CONFLICT (promo_id, day) DO UPDATE SET views = promo_days.views + EXCLUDED.views,
					viewers = promo_days.viewers + EXCLUDED.viewers, taps = promo_days.taps + EXCLUDED.taps,
					copies = promo_days.copies + EXCLUDED.copies, hides = promo_days.hides + EXCLUDED.hides`,
				id, day, t.views, t.viewers, t.taps, t.copies, t.hides); err != nil {
				return err
			}
		}
		return nil
	})
}

// countable: which of ids the student could be shown now (live, in their
// dates, the sponsor not archived, targeted to them). Hides and caps don't
// matter here: the events themselves are capped.
func (s *Service) countable(ctx context.Context, v viewer, ids []uuid.UUID, now time.Time) (map[uuid.UUID]bool, error) {
	rows, err := s.d.Q(ctx).Query(ctx, `SELECT p.id FROM promos p JOIN sponsors s ON s.id = p.sponsor_id
		WHERE p.id = ANY ($1) AND p.status = 'live' AND p.starts_at <= $2 AND p.ends_at > $2 AND s.archived_at IS NULL
		  AND (p.university_ids IS NULL OR $3::uuid = ANY (p.university_ids))
		  AND (p.cities IS NULL OR EXISTS (SELECT 1 FROM unnest(p.cities) c WHERE lower(c) = lower($4::text)))`,
		ids, now, v.Uni, v.City)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := map[uuid.UUID]bool{}
	for rows.Next() {
		var id uuid.UUID
		if err := rows.Scan(&id); err != nil {
			return nil, err
		}
		out[id] = true
	}
	return out, rows.Err()
}
