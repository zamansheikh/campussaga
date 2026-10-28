// Package appconfig serves public settings the app reads at start: the
// minimum supported build (forced update) and feature flags.
package appconfig

import (
	"context"
	"encoding/json"
	"strings"

	"github.com/zamansheikh/varsitykotha/backend/internal/modules/appconfig/store"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/db"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/httpx"
)

type Service struct {
	d *db.DB
}

func NewService(d *db.DB) *Service { return &Service{d: d} }

func (s *Service) Routes(r *httpx.Router) {
	r.Public().Get("/config", httpx.Handle(s.get))
}

// get returns every key, snake_case keys renamed to camelCase:
// {"minSupportedBuild": 1, "features": {...}}.
func (s *Service) get(ctx context.Context, _ *httpx.Empty) (map[string]json.RawMessage, error) {
	rows, err := store.New(s.d.Q(ctx)).ListConfig(ctx)
	if err != nil {
		return nil, err
	}
	out := make(map[string]json.RawMessage, len(rows))
	for _, r := range rows {
		out[camel(r.Key)] = r.Value
	}
	return out, nil
}

func camel(s string) string {
	parts := strings.Split(s, "_")
	for i := 1; i < len(parts); i++ {
		if parts[i] != "" {
			parts[i] = strings.ToUpper(parts[i][:1]) + parts[i][1:]
		}
	}
	return strings.Join(parts, "")
}
