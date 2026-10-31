package universities

import (
	"context"
	"encoding/base64"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/google/uuid"

	"github.com/zamansheikh/varsitykotha/backend/internal/modules/universities/store"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/apperr"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/auth"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/db"
)

// Visit other campuses (docs/CAMPUS_VISITS.md §3.3): the universities a
// student can look at, with counts of what they could read there.

var (
	ErrFeatureDisabled    = apperr.New(http.StatusForbidden, "FEATURE_DISABLED", "Visiting other campuses isn't open yet")
	ErrUniversityNotFound = apperr.New(http.StatusNotFound, "UNIVERSITY_NOT_FOUND", "This university was not found")
	ErrBadCursor          = apperr.New(http.StatusBadRequest, "BAD_CURSOR", "This page link is no longer valid")
)

const (
	campusPageSize = 30
	postsWindow    = 7 * 24 * time.Hour
)

type CampusSummary struct {
	ID       uuid.UUID `json:"id"`
	Slug     string    `json:"slug"`
	Name     string    `json:"name"`
	NameBn   *string   `json:"nameBn"`
	City     *string   `json:"city"`
	Kind     *string   `json:"kind"`
	Students int       `json:"students"`
	Posts7d  int       `json:"posts7d"`
}

type CampusProfile struct {
	CampusSummary
	Website     *string `json:"website"`
	ClassGroups int     `json:"classGroups"`
	BusRoutes   int     `json:"busRoutes"`
	Mine        bool    `json:"mine"`
}

type campusesReq struct {
	Q      string `json:"-" query:"q" validate:"max=60"`
	Cursor string `json:"-" query:"cursor" validate:"max=100"`
}

type campusesRes struct {
	Items      []CampusSummary `json:"items"`
	NextCursor *string         `json:"nextCursor"`
}

type campusReq struct {
	Slug string `json:"-" path:"slug" validate:"required,max=80"`
}

// gate: students need features.visitCampus; staff are unaffected.
func (s *Service) gate(ctx context.Context, q *store.Queries) (*auth.Claims, error) {
	c := auth.MustUser(ctx)
	if c.Role == "student" || c.Role == "" {
		on, err := q.VisitCampusOn(ctx)
		if err != nil && !db.IsNoRows(err) {
			return nil, err
		}
		if !on {
			return nil, ErrFeatureDisabled
		}
	}
	return c, nil
}

func (s *Service) listCampuses(ctx context.Context, in *campusesReq) (*campusesRes, error) {
	q := store.New(s.d.Q(ctx))
	c, err := s.gate(ctx, q)
	if err != nil {
		return nil, err
	}
	off := 0
	if in.Cursor != "" {
		raw, err := base64.RawURLEncoding.DecodeString(in.Cursor)
		parts := strings.Split(string(raw), "|")
		if err != nil || len(parts) != 2 || parts[0] != "o" {
			return nil, ErrBadCursor
		}
		if off, err = strconv.Atoi(parts[1]); err != nil || off < 0 {
			return nil, ErrBadCursor
		}
	}
	search := strings.TrimSpace(in.Q)
	rows, err := q.ListCampuses(ctx, store.ListCampusesParams{Own: c.UniversityID, Q: search, QLike: likePattern(search),
		Since: s.now().Add(-postsWindow), Lim: campusPageSize, Off: int32(off)})
	if err != nil {
		return nil, err
	}
	out := &campusesRes{Items: make([]CampusSummary, 0, len(rows))}
	for _, r := range rows {
		out.Items = append(out.Items, CampusSummary{ID: r.ID, Slug: r.Slug, Name: r.Name, NameBn: r.NameBn,
			City: r.City, Kind: r.Kind, Students: int(r.Students), Posts7d: int(r.Posts7d)})
	}
	if len(rows) == campusPageSize {
		n := base64.RawURLEncoding.EncodeToString([]byte("o|" + strconv.Itoa(off+campusPageSize)))
		out.NextCursor = &n
	}
	return out, nil
}

func (s *Service) getCampus(ctx context.Context, in *campusReq) (*CampusProfile, error) {
	q := store.New(s.d.Q(ctx))
	c, err := s.gate(ctx, q)
	if err != nil {
		return nil, err
	}
	r, err := q.GetCampus(ctx, store.GetCampusParams{Slug: strings.ToLower(in.Slug), Since: s.now().Add(-postsWindow)})
	if db.IsNoRows(err) {
		return nil, ErrUniversityNotFound
	}
	if err != nil {
		return nil, err
	}
	out := &CampusProfile{
		CampusSummary: CampusSummary{ID: r.ID, Slug: r.Slug, Name: r.Name, NameBn: r.NameBn, City: r.City, Kind: r.Kind,
			Students: int(r.Students), Posts7d: int(r.Posts7d)},
		ClassGroups: int(r.ClassGroups), BusRoutes: int(r.BusRoutes), Mine: r.ID == c.UniversityID,
	}
	if r.Website != nil && *r.Website != "" {
		w := "https://" + *r.Website
		out.Website = &w
	}
	return out, nil
}

func likePattern(q string) string {
	return "%" + strings.NewReplacer(`\`, `\\`, `%`, `\%`, `_`, `\_`).Replace(q) + "%"
}
