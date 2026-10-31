// Package sponsors is our own ads (docs/SPONSORS.md). The team creates
// sponsors and their ads in the admin panel; the app asks which ad to show
// in a place and reports views, taps, copies and hides; reports are daily
// totals. There are no ad networks, and nothing about a student leaves the
// server: per-student rows exist only for caps and unique viewers and are
// deleted after 90 days.
package sponsors

import (
	"context"
	"encoding/json"
	"log/slog"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/zamansheikh/varsitykotha/backend/internal/platform/apperr"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/auth"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/db"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/httpx"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/media"
)

// Rules of docs/SPONSORS.md.
const (
	KeepUserDays    = 90 // per-student rows are deleted after this many days
	HideDays        = 7  // "Hide this ad"
	MaxPerUserDay   = 20 // views (and taps, copies) of one ad counted per student and day
	MaxEvents       = 50 // events per POST /promos/events
	MaxDeals        = 50
	MaxCampus       = 3
	MaxStatsDays    = 366
	MaxTargetUnis   = 500
	MaxTargetCity   = 50
	DefaultDayCap   = 2
	DefaultPriority = 5
)

var (
	ErrInvalidPromo     = apperr.New(http.StatusBadRequest, "INVALID_PROMO", "This ad isn't complete or valid")
	ErrPromoNotFound    = apperr.New(http.StatusNotFound, "PROMO_NOT_FOUND", "This ad was not found")
	ErrSponsorNotFound  = apperr.New(http.StatusNotFound, "SPONSOR_NOT_FOUND", "This sponsor was not found")
	ErrInvalidImage     = apperr.New(http.StatusBadRequest, "INVALID_IMAGE", "Send a JPEG, PNG or WebP image")
	ErrImageTooLarge    = apperr.New(http.StatusRequestEntityTooLarge, "IMAGE_TOO_LARGE", "This image is too large")
	ErrHealthOnly       = apperr.New(http.StatusUnprocessableEntity, "HEALTH_SPONSOR_ONLY", "Only a health sponsor (hospital or NGO) can appear on the Blood page")
	ErrPromoLocked      = apperr.New(http.StatusConflict, "PROMO_LOCKED", "Pause this ad to change this")
	ErrMediaUnavailable = apperr.New(http.StatusServiceUnavailable, "MEDIA_UNAVAILABLE", "Images can't be stored right now")
	ErrNoImage          = apperr.New(http.StatusNotFound, "IMAGE_NOT_FOUND", "There is no image here")
)

// invalid is INVALID_PROMO with the field that is wrong.
func invalid(field, reason string) error {
	return ErrInvalidPromo.WithDetails(map[string]string{field: reason})
}

type Service struct {
	d     *db.DB
	now   func() time.Time
	log   *slog.Logger
	media media.Store // images and logos; nil until SetMedia
}

func NewService(d *db.DB, now func() time.Time, log *slog.Logger) *Service {
	if log == nil {
		log = slog.Default()
	}
	return &Service{d: d, now: now, log: log}
}

// SetMedia gives the service somewhere to keep ad images and logos.
func (s *Service) SetMedia(m media.Store) { s.media = m }

// UploadLimit caps an ad image upload's body (the photo plus multipart
// framing); LogoUploadLimit a logo's. app.go raises the API's 64 KB cap.
const (
	UploadLimit     = media.MaxBytes + 1<<20
	LogoUploadLimit = media.LogoMaxBytes + 1<<20
)

func (s *Service) Routes(r *httpx.Router) {
	st := r.Student()
	st.With(withLang).Get("/promos", httpx.Handle(s.handlePromos))
	st.With(r.LimitUser("promo-events", 600, time.Hour)).Post("/promos/events", httpx.Handle(s.handleEvents, httpx.NoContent()))

	pub := r.Public().With(r.Limit("promo-image", 600, time.Minute))
	pub.Get("/promos/{id}/image", s.handlePromoImage)
	pub.Get("/sponsors/{id}/logo", s.handleSponsorLogo)

	a := r.Admin()
	a.Get("/admin/sponsors", httpx.Handle(s.handleAdminSponsors))
	a.Post("/admin/sponsors", httpx.Handle(s.handleAdminSponsorCreate, httpx.Status(http.StatusCreated)))
	a.Get("/admin/sponsors/{id}", httpx.Handle(s.handleAdminSponsor))
	a.Patch("/admin/sponsors/{id}", httpx.Handle(s.handleAdminSponsorPatch))
	a.Delete("/admin/sponsors/{id}", httpx.Handle(s.handleAdminSponsorArchive))
	a.Post("/admin/sponsors/{id}/logo", s.handleAdminLogo)
	a.Delete("/admin/sponsors/{id}/logo", httpx.Handle(s.handleAdminLogoDelete))
	a.Get("/admin/sponsors/{id}/stats", httpx.Handle(s.handleAdminSponsorStats))

	a.Get("/admin/promos", httpx.Handle(s.handleAdminPromos))
	a.Post("/admin/promos", httpx.Handle(s.handleAdminPromoCreate, httpx.Status(http.StatusCreated)))
	a.Get("/admin/promos/{id}", httpx.Handle(s.handleAdminPromo))
	a.Patch("/admin/promos/{id}", httpx.Handle(s.handleAdminPromoPatch))
	a.Delete("/admin/promos/{id}", httpx.Handle(s.handleAdminPromoDelete, httpx.NoContent()))
	a.Post("/admin/promos/{id}/status", httpx.Handle(s.handleAdminPromoStatus))
	a.Post("/admin/promos/{id}/duplicate", httpx.Handle(s.handleAdminPromoDuplicate, httpx.Status(http.StatusCreated)))
	a.Post("/admin/promos/{id}/image", s.handleAdminImage)
	a.Delete("/admin/promos/{id}/image", httpx.Handle(s.handleAdminImageDelete))
	a.Get("/admin/promos/{id}/stats", httpx.Handle(s.handleAdminPromoStats))
}

// ---- language -----------------------------------------------------------------------

type langKey struct{}

// withLang reads the student's language: the `lang` query parameter, else
// the Accept-Language header, else English.
func withLang(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		next.ServeHTTP(w, r.WithContext(context.WithValue(r.Context(), langKey{}, langOf(r))))
	})
}

func langOf(r *http.Request) string {
	if l := strings.ToLower(strings.TrimSpace(r.URL.Query().Get("lang"))); l == "bn" || l == "en" {
		return l
	}
	for _, part := range strings.Split(r.Header.Get("Accept-Language"), ",") {
		tag := strings.ToLower(strings.TrimSpace(strings.SplitN(part, ";", 2)[0]))
		switch {
		case tag == "bn" || strings.HasPrefix(tag, "bn-"):
			return "bn"
		case tag == "en" || strings.HasPrefix(tag, "en-"):
			return "en"
		}
	}
	return "en"
}

func lang(ctx context.Context) string {
	if l, ok := ctx.Value(langKey{}).(string); ok {
		return l
	}
	return "en"
}

// pick returns bn when the language is Bangla and bn is not empty.
func pick(l, en, bn string) string {
	if l == "bn" && strings.TrimSpace(bn) != "" {
		return bn
	}
	return en
}

// ---- time ---------------------------------------------------------------------------

var dhaka = mustZone("Asia/Dhaka")

func mustZone(name string) *time.Location {
	l, err := time.LoadLocation(name)
	if err != nil {
		return time.FixedZone(name, 6*3600)
	}
	return l
}

// dhakaDay is the calendar day (Asia/Dhaka) of t as YYYY-MM-DD.
func dhakaDay(t time.Time) string { return t.In(dhaka).Format(time.DateOnly) }

// ---- admin helpers ------------------------------------------------------------------

func (s *Service) audit(ctx context.Context, action, targetType, targetID string, meta any) error {
	b, err := json.Marshal(meta)
	if err != nil || meta == nil {
		b = []byte("{}")
	}
	_, err = s.d.Q(ctx).Exec(ctx, `INSERT INTO audit_log (actor_id, action, target_type, target_id, meta) VALUES ($1, $2, $3, $4, $5)`,
		auth.MustUser(ctx).UserID, action, targetType, targetID, b)
	return err
}

func atoi(s string) int { n, _ := strconv.Atoi(s); return n }

func pageOf(page, size string) (int, int) {
	p, n := max(atoi(page), 1), atoi(size)
	if n < 1 {
		n = 25
	}
	return p, min(n, 100)
}

// Page is a paged admin list.
type Page[T any] struct {
	Items    []T `json:"items"`
	Total    int `json:"total"`
	Page     int `json:"page"`
	PageSize int `json:"pageSize"`
}
