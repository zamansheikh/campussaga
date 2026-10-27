package firebase

import (
	"context"
	"crypto/rsa"
	"crypto/x509"
	"encoding/json"
	"encoding/pem"
	"errors"
	"fmt"
	"io"
	"net/http"
	"strconv"
	"strings"
	"sync"
	"time"
)

// GoogleCertsURL publishes the keys that sign Firebase ID tokens.
const GoogleCertsURL = "https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com"

// GoogleKeys fetches and caches Google's signing keys for as long as the
// response's Cache-Control max-age allows.
type GoogleKeys struct {
	URL    string
	Client *http.Client
	now    func() time.Time

	mu          sync.Mutex
	keys        map[string]*rsa.PublicKey
	expires     time.Time
	lastRefresh time.Time
}

// NewGoogleKeys; now may be nil.
func NewGoogleKeys(now func() time.Time) *GoogleKeys {
	if now == nil {
		now = time.Now
	}
	return &GoogleKeys{URL: GoogleCertsURL, Client: &http.Client{Timeout: 10 * time.Second}, now: now}
}

// Keys returns the cached keys, fetching when expired. refresh forces a
// fetch (at most once a minute, so bad tokens cannot hammer Google).
func (g *GoogleKeys) Keys(ctx context.Context, refresh bool) (map[string]*rsa.PublicKey, error) {
	g.mu.Lock()
	defer g.mu.Unlock()
	now := g.now()
	fresh := g.keys != nil && now.Before(g.expires)
	if fresh && (!refresh || now.Sub(g.lastRefresh) < time.Minute) {
		return g.keys, nil
	}
	keys, maxAge, err := g.fetch(ctx)
	if err != nil {
		if g.keys != nil {
			return g.keys, nil // keep serving the last good keys
		}
		return nil, err
	}
	g.keys, g.expires, g.lastRefresh = keys, now.Add(maxAge), now
	return keys, nil
}

func (g *GoogleKeys) fetch(ctx context.Context) (map[string]*rsa.PublicKey, time.Duration, error) {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, g.URL, nil)
	if err != nil {
		return nil, 0, err
	}
	res, err := g.Client.Do(req)
	if err != nil {
		return nil, 0, fmt.Errorf("firebase: fetch keys: %w", err)
	}
	defer res.Body.Close()
	if res.StatusCode != http.StatusOK {
		return nil, 0, fmt.Errorf("firebase: fetch keys: HTTP %d", res.StatusCode)
	}
	var certs map[string]string
	if err := json.NewDecoder(io.LimitReader(res.Body, 1<<20)).Decode(&certs); err != nil {
		return nil, 0, fmt.Errorf("firebase: decode keys: %w", err)
	}
	keys := make(map[string]*rsa.PublicKey, len(certs))
	for kid, certPEM := range certs {
		block, _ := pem.Decode([]byte(certPEM))
		if block == nil {
			continue
		}
		cert, err := x509.ParseCertificate(block.Bytes)
		if err != nil {
			continue
		}
		if k, ok := cert.PublicKey.(*rsa.PublicKey); ok {
			keys[kid] = k
		}
	}
	if len(keys) == 0 {
		return nil, 0, errors.New("firebase: no usable keys")
	}
	return keys, maxAge(res.Header.Get("Cache-Control")), nil
}

func maxAge(cacheControl string) time.Duration {
	for _, part := range strings.Split(cacheControl, ",") {
		part = strings.TrimSpace(part)
		if v, ok := strings.CutPrefix(part, "max-age="); ok {
			if n, err := strconv.Atoi(v); err == nil && n > 0 {
				return time.Duration(n) * time.Second
			}
		}
	}
	return time.Hour
}

// StaticKeys is a fixed key set (tests).
type StaticKeys map[string]*rsa.PublicKey

func (s StaticKeys) Keys(context.Context, bool) (map[string]*rsa.PublicKey, error) { return s, nil }
