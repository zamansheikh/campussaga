package admin

import (
	"context"
	"regexp"
	"slices"
	"strings"

	"github.com/google/uuid"

	"github.com/zamansheikh/campussaga/backend/internal/modules/admin/store"
	"github.com/zamansheikh/campussaga/backend/internal/platform/apperr"
	"github.com/zamansheikh/campussaga/backend/internal/platform/db"
)

// University is a university as the panel sees it.
type University struct {
	ID      uuid.UUID `json:"id"`
	Slug    string    `json:"slug"`
	Name    string    `json:"name"`
	NameBn  *string   `json:"nameBn"`
	City    *string   `json:"city"`
	Kind    *string   `json:"kind"`
	Website *string   `json:"website"`
	Active  bool      `json:"active"`
	Domains []string  `json:"domains"`
	Users   int       `json:"users"`
	Groups  int       `json:"groups"`
}

func universityView(r store.GetUniversityRow) University {
	return University{
		ID: r.ID, Slug: r.Slug, Name: r.Name, NameBn: r.NameBn, City: r.City, Kind: r.Kind,
		Website: r.Website, Active: r.IsActive, Domains: r.Domains, Users: int(r.Users), Groups: int(r.Groups),
	}
}

var (
	slugRe   = regexp.MustCompile(`^[a-z0-9]+(-[a-z0-9]+)*$`)
	domainRe = regexp.MustCompile(`^[a-z0-9-]+(\.[a-z0-9-]+)+$`)
)

type listUniversitiesReq struct {
	Q      string `json:"-" query:"q" validate:"max=100"`
	Active string `json:"-" query:"active" validate:"omitempty,oneof=true false"`
}

type universitiesRes struct {
	Items []University `json:"items"`
}

func (s *Service) handleListUniversities(ctx context.Context, in *listUniversitiesReq) (*universitiesRes, error) {
	var active *bool
	if in.Active != "" {
		v := in.Active == "true"
		active = &v
	}
	search := strings.TrimSpace(in.Q)
	rows, err := store.New(s.d.Q(ctx)).ListUniversities(ctx, store.ListUniversitiesParams{Q: search, QLike: like(search), Active: active})
	if err != nil {
		return nil, err
	}
	out := &universitiesRes{Items: make([]University, 0, len(rows))}
	for _, r := range rows {
		out.Items = append(out.Items, universityView(store.GetUniversityRow(r)))
	}
	return out, nil
}

type createUniversityReq struct {
	Slug    string   `json:"slug" validate:"required,min=2,max=40"`
	Name    string   `json:"name" validate:"required,min=2,max=120"`
	NameBn  string   `json:"nameBn" validate:"max=120"`
	City    string   `json:"city" validate:"max=60"`
	Kind    string   `json:"kind" validate:"omitempty,oneof=public private"`
	Website string   `json:"website" validate:"max=100"`
	Domains []string `json:"domains" validate:"max=50,dive,max=100"`
}

func (s *Service) handleCreateUniversity(ctx context.Context, in *createUniversityReq) (*University, error) {
	slug := strings.ToLower(strings.TrimSpace(in.Slug))
	website := normalizeHost(in.Website)
	bad := map[string]string{}
	if !slugRe.MatchString(slug) {
		bad["slug"] = "use lowercase letters, digits and dashes"
	}
	if website != "" && !domainRe.MatchString(website) {
		bad["website"] = "use a bare host like diu.edu.bd"
	}
	domains, domErr := normalizeDomains(in.Domains)
	if domErr != "" {
		bad["domains"] = domErr
	}
	if len(bad) > 0 {
		return nil, apperr.Validation(bad)
	}
	var id uuid.UUID
	err := s.d.InTx(ctx, func(ctx context.Context) error {
		q := store.New(s.d.Q(ctx))
		var err error
		id, err = q.InsertUniversity(ctx, store.InsertUniversityParams{
			Slug: slug, Name: strings.TrimSpace(in.Name), NameBn: strPtr(strings.TrimSpace(in.NameBn)),
			City: strPtr(strings.TrimSpace(in.City)), Kind: strPtr(in.Kind), Website: strPtr(website),
		})
		if db.IsUniqueViolation(err) {
			return ErrSlugTaken
		}
		if err != nil {
			return err
		}
		if err := insertDomains(ctx, q, id, domains); err != nil {
			return err
		}
		return s.audit(ctx, q, "university.create", "university", id.String(),
			map[string]any{"slug": slug, "name": in.Name, "domains": domains})
	})
	if err != nil {
		return nil, err
	}
	return s.university(ctx, id)
}

type patchUniversityReq struct {
	ID     string  `json:"-" path:"id" validate:"required,uuid"`
	Name   *string `json:"name" validate:"omitempty,min=2,max=120"`
	NameBn *string `json:"nameBn" validate:"omitempty,max=120"`
	City   *string `json:"city" validate:"omitempty,max=60"`
	// Kind: public, private, or "" to clear it.
	Kind    *string `json:"kind" validate:"omitempty,max=10"`
	Website *string `json:"website" validate:"omitempty,max=100"`
	Active  *bool   `json:"active"`
}

func (s *Service) handlePatchUniversity(ctx context.Context, in *patchUniversityReq) (*University, error) {
	id := uuid.MustParse(in.ID)
	if in.Kind != nil && *in.Kind != "" && *in.Kind != "public" && *in.Kind != "private" {
		return nil, apperr.Validation(map[string]string{"kind": "must be public, private or empty"})
	}
	if in.Website != nil {
		w := normalizeHost(*in.Website)
		if w != "" && !domainRe.MatchString(w) {
			return nil, apperr.Validation(map[string]string{"website": "use a bare host like diu.edu.bd"})
		}
		in.Website = &w
	}
	trim := func(p *string) *string {
		if p == nil {
			return nil
		}
		t := strings.TrimSpace(*p)
		return &t
	}
	err := s.d.InTx(ctx, func(ctx context.Context) error {
		q := store.New(s.d.Q(ctx))
		n, err := q.UpdateUniversity(ctx, store.UpdateUniversityParams{
			ID: id, Name: trim(in.Name), NameBn: trim(in.NameBn), City: trim(in.City),
			Kind: in.Kind, Website: in.Website, IsActive: in.Active,
		})
		if err != nil {
			return err
		}
		if n == 0 {
			return ErrUniversityNotFound
		}
		return s.audit(ctx, q, "university.update", "university", id.String(), in)
	})
	if err != nil {
		return nil, err
	}
	return s.university(ctx, id)
}

type domainsReq struct {
	ID      string   `json:"-" path:"id" validate:"required,uuid"`
	Domains []string `json:"domains" validate:"max=50,dive,max=100"`
}

func (s *Service) handleSetDomains(ctx context.Context, in *domainsReq) (*University, error) {
	id := uuid.MustParse(in.ID)
	domains, bad := normalizeDomains(in.Domains)
	if bad != "" {
		return nil, apperr.Validation(map[string]string{"domains": bad})
	}
	err := s.d.InTx(ctx, func(ctx context.Context) error {
		q := store.New(s.d.Q(ctx))
		if _, err := q.GetUniversity(ctx, id); db.IsNoRows(err) {
			return ErrUniversityNotFound
		} else if err != nil {
			return err
		}
		if err := q.DeleteUniversityDomains(ctx, id); err != nil {
			return err
		}
		if err := insertDomains(ctx, q, id, domains); err != nil {
			return err
		}
		return s.audit(ctx, q, "university.domains", "university", id.String(), map[string]any{"domains": domains})
	})
	if err != nil {
		return nil, err
	}
	return s.university(ctx, id)
}

func (s *Service) university(ctx context.Context, id uuid.UUID) (*University, error) {
	r, err := store.New(s.d.Q(ctx)).GetUniversity(ctx, id)
	if db.IsNoRows(err) {
		return nil, ErrUniversityNotFound
	}
	if err != nil {
		return nil, err
	}
	u := universityView(r)
	return &u, nil
}

func insertDomains(ctx context.Context, q *store.Queries, id uuid.UUID, domains []string) error {
	for _, d := range domains {
		err := q.InsertUniversityDomain(ctx, store.InsertUniversityDomainParams{Domain: d, UniversityID: id})
		if db.IsUniqueViolation(err) {
			return ErrDomainTaken.WithDetails(map[string]string{"domain": d})
		}
		if pe, ok := pgError(err); ok && pe.Code == "23514" { // check: free mail / shared suffix
			return ErrDomainNotAllowed.WithDetails(map[string]string{"domain": d})
		}
		if err != nil {
			return err
		}
	}
	return nil
}

// normalizeHost lower-cases a host and drops a scheme, "www." or a path
// someone pasted ("https://www.diu.edu.bd/" → "diu.edu.bd").
func normalizeHost(s string) string {
	s = strings.ToLower(strings.TrimSpace(s))
	s = strings.TrimPrefix(strings.TrimPrefix(s, "https://"), "http://")
	s = strings.TrimPrefix(s, "www.")
	if i := strings.IndexAny(s, "/?#"); i >= 0 {
		s = s[:i]
	}
	return s
}

// normalizeDomains cleans email domains ("@DIU.edu.bd" → "diu.edu.bd"),
// drops duplicates, and says what is wrong with a bad one.
func normalizeDomains(in []string) ([]string, string) {
	out := []string{}
	for _, d := range in {
		d = strings.TrimPrefix(normalizeHost(d), "@")
		if d == "" || slices.Contains(out, d) {
			continue
		}
		if !domainRe.MatchString(d) {
			return nil, d + " is not a domain like diu.edu.bd"
		}
		out = append(out, d)
	}
	return out, ""
}
