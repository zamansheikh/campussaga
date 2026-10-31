// Package universities owns the list of supported universities and their
// student email domains.
package universities

import (
	"context"
	"strings"
	"time"

	"github.com/google/uuid"

	"github.com/zamansheikh/varsitykotha/backend/internal/modules/universities/store"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/db"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/httpx"
)

// Service is the universities module.
type Service struct {
	d   *db.DB
	now func() time.Time
}

func NewService(d *db.DB) *Service { return &Service{d: d, now: time.Now} }

// SetClock replaces the clock (the app's fake time in tests).
func (s *Service) SetClock(now func() time.Time) { s.now = now }

// Routes mounts the module's endpoints.
func (s *Service) Routes(r *httpx.Router) {
	r.Public().Get("/universities", httpx.Handle(s.list))
	r.Student().Get("/campuses", httpx.Handle(s.listCampuses))
	r.Student().Get("/campuses/{slug}", httpx.Handle(s.getCampus))
}

// View is a university as the app sees it. The domain list is public so the
// app can tell a student before sending a code that their email won't work.
type View struct {
	ID        uuid.UUID `json:"id"`
	Slug      string    `json:"slug"`
	Name      string    `json:"name"`
	NameBn    *string   `json:"nameBn"`
	City      *string   `json:"city"`
	Timezone  string    `json:"timezone"`
	WeekStart int16     `json:"weekStart"`
	Domains   []string  `json:"domains"`
}

// Summary is the short form embedded in other responses. City and Domains
// are filled by Get only (the student's own university in /me).
type Summary struct {
	ID      uuid.UUID `json:"id"`
	Slug    string    `json:"slug"`
	Name    string    `json:"name"`
	NameBn  *string   `json:"nameBn"`
	City    *string   `json:"city,omitempty"`
	Domains []string  `json:"domains,omitempty"`
	// IsDemo: the reviewer-only demo university. Never sent to the app.
	IsDemo bool `json:"-"`
}

type listRes struct {
	Universities []View `json:"universities"`
}

func (s *Service) list(ctx context.Context, _ *httpx.Empty) (*listRes, error) {
	rows, err := store.New(s.d.Q(ctx)).ListActive(ctx)
	if err != nil {
		return nil, err
	}
	out := make([]View, 0, len(rows))
	for _, r := range rows {
		out = append(out, View{
			ID: r.ID, Slug: r.Slug, Name: r.Name, NameBn: r.NameBn, City: r.City,
			Timezone: r.Timezone, WeekStart: r.WeekStart, Domains: r.Domains,
		})
	}
	return &listRes{Universities: out}, nil
}

// ForEmail returns the active university an email address belongs to, or
// nil when there is none.
func (s *Service) ForEmail(ctx context.Context, email string) (*Summary, error) {
	cands := DomainCandidates(email)
	if len(cands) == 0 {
		return nil, nil
	}
	r, err := store.New(s.d.Q(ctx)).MatchDomain(ctx, cands)
	if db.IsNoRows(err) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	return &Summary{ID: r.ID, Slug: r.Slug, Name: r.Name, NameBn: r.NameBn, IsDemo: r.IsDemo}, nil
}

// Get returns one university's summary (also inactive ones: existing
// students keep their profile if a university is paused).
func (s *Service) Get(ctx context.Context, id uuid.UUID) (*Summary, error) {
	r, err := store.New(s.d.Q(ctx)).GetUniversity(ctx, id)
	if err != nil {
		return nil, err
	}
	return &Summary{ID: r.ID, Slug: r.Slug, Name: r.Name, NameBn: r.NameBn, City: r.City, Domains: r.Domains, IsDemo: r.IsDemo}, nil
}

// DomainCandidates returns the email's host and each parent domain with at
// least two labels: "a@cse.du.ac.bd" → [cse.du.ac.bd du.ac.bd ac.bd].
// Matching on whole labels means "nottest.ac.bd" never matches "test.ac.bd".
func DomainCandidates(email string) []string {
	at := strings.LastIndexByte(email, '@')
	if at < 1 || at == len(email)-1 {
		return nil
	}
	host := strings.ToLower(strings.TrimSuffix(email[at+1:], "."))
	labels := strings.Split(host, ".")
	for _, l := range labels {
		if l == "" {
			return nil
		}
	}
	var out []string
	for i := 0; i+2 <= len(labels); i++ {
		out = append(out, strings.Join(labels[i:], "."))
	}
	return out
}
