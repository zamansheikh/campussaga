package transport

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"strconv"
	"strings"
	"time"
)

// RoadRouter finds the road path through points in order, as an encoded
// polyline (precision 5).
type RoadRouter interface {
	Path(ctx context.Context, points []LatLng) (string, error)
}

// OSRM is a RoadRouter on an OSRM server, by default OpenStreetMap's
// public one. Paths are worked out once per stop change (not per student),
// which keeps us well inside its fair-use policy.
type OSRM struct {
	Base   string // e.g. https://router.project-osrm.org
	Client *http.Client
}

func NewOSRM(base string) *OSRM {
	return &OSRM{Base: strings.TrimRight(base, "/"), Client: &http.Client{Timeout: 10 * time.Second}}
}

func (o *OSRM) Path(ctx context.Context, points []LatLng) (string, error) {
	if len(points) < 2 {
		return "", errors.New("osrm: need two points")
	}
	coords := make([]string, len(points))
	for i, p := range points {
		coords[i] = strconv.FormatFloat(p.Lng, 'f', 6, 64) + "," + strconv.FormatFloat(p.Lat, 'f', 6, 64)
	}
	url := o.Base + "/route/v1/driving/" + strings.Join(coords, ";") + "?overview=full&geometries=polyline"
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
	if err != nil {
		return "", err
	}
	req.Header.Set("User-Agent", "VarsityKotha/1.0 (+https://varsitykotha.com; hello@silifton.com)")
	res, err := o.Client.Do(req)
	if err != nil {
		return "", err
	}
	defer res.Body.Close()
	var out struct {
		Code   string `json:"code"`
		Routes []struct {
			Geometry string `json:"geometry"`
		} `json:"routes"`
	}
	if err := json.NewDecoder(res.Body).Decode(&out); err != nil {
		return "", fmt.Errorf("osrm: %s: %w", res.Status, err)
	}
	if out.Code != "Ok" || len(out.Routes) == 0 || out.Routes[0].Geometry == "" {
		return "", fmt.Errorf("osrm: %s %s", res.Status, out.Code)
	}
	return out.Routes[0].Geometry, nil
}

// pathKey: the coordinates a path is made from, to skip unchanged routes.
func pathKey(points []LatLng) string {
	var b strings.Builder
	for _, p := range points {
		fmt.Fprintf(&b, "%.6f,%.6f;", p.Lat, p.Lng)
	}
	return b.String()
}
