package voice

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strings"
	"time"

	"github.com/zamansheikh/varsitykotha/backend/internal/platform/apperr"
)

// Photo check: every photo is scored by an NSFW classifier running on our
// own server (backend/nsfw) before anyone can see it. Photos never leave
// our systems for this.
const (
	// HoldPhotoCheck: a photo scored high enough for a moderator to look.
	HoldPhotoCheck = "photo_check"
	// HoldPhotoCheckUnavailable: the checker didn't answer (production
	// never lets an unchecked photo through).
	HoldPhotoCheckUnavailable = "photo_check_unavailable"
)

// ErrPhotoNotAllowed: the photo is clearly explicit; it is not stored.
var ErrPhotoNotAllowed = apperr.New(http.StatusUnprocessableEntity, "PHOTO_NOT_ALLOWED",
	"This photo can't be posted. Choose another photo")

// PhotoChecker scores a JPEG: 0 = safe … 1 = explicit.
type PhotoChecker interface {
	Score(ctx context.Context, jpeg []byte) (float64, error)
}

// PhotoCheck configures the check. Checker nil = not configured.
type PhotoCheck struct {
	Checker PhotoChecker
	Reject  float64 // score ≥ Reject: refused
	Hold    float64 // score ≥ Hold: stored, flagged, its issue held for review
	// Required (production): an unchecked photo is held, never let through.
	Required bool
}

// SetPhotoCheck turns the photo check on.
func (s *Service) SetPhotoCheck(c PhotoCheck) { s.photo = c }

// checkPhoto scores a photo. It returns the score (nil = not checked) and
// whether it must be held for a moderator, or ErrPhotoNotAllowed. Logs carry
// the score only: nothing about the photo or who sent it.
func (s *Service) checkPhoto(ctx context.Context, jpeg []byte) (*float32, bool, error) {
	c := s.photo
	if c.Checker == nil {
		if c.Required {
			s.log.Warn("voice: photo check not configured; photo held")
			return nil, true, nil
		}
		s.log.Debug("voice: photo check skipped (NSFW_URL not set)")
		return nil, false, nil
	}
	score, err := c.Checker.Score(ctx, jpeg)
	if err != nil {
		if c.Required {
			s.log.Warn("voice: photo check unavailable; photo held", "err", err)
			return nil, true, nil
		}
		s.log.Warn("voice: photo check unavailable; skipped (not production)", "err", err)
		return nil, false, nil
	}
	v := float32(score)
	switch {
	case score >= c.Reject:
		s.log.Info("voice: photo refused by the photo check", "score", score)
		return &v, true, ErrPhotoNotAllowed
	case score >= c.Hold:
		s.log.Info("voice: photo flagged by the photo check", "score", score)
		return &v, true, nil
	}
	return &v, false, nil
}

// HTTPChecker calls the backend/nsfw service: POST /classify with the image
// bytes, answer {"nsfw": 0.97, ...}.
type HTTPChecker struct {
	URL    string // e.g. http://nsfw:8000
	Client *http.Client
}

func NewHTTPChecker(url string) *HTTPChecker {
	return &HTTPChecker{URL: strings.TrimRight(url, "/"), Client: &http.Client{Timeout: 15 * time.Second}}
}

func (c *HTTPChecker) Score(ctx context.Context, jpeg []byte) (float64, error) {
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, c.URL+"/classify", bytes.NewReader(jpeg))
	if err != nil {
		return 0, err
	}
	req.Header.Set("Content-Type", "image/jpeg")
	res, err := c.Client.Do(req)
	if err != nil {
		return 0, err
	}
	defer res.Body.Close()
	if res.StatusCode != http.StatusOK {
		b, _ := io.ReadAll(io.LimitReader(res.Body, 200))
		return 0, fmt.Errorf("photo check: %d %s", res.StatusCode, strings.TrimSpace(string(b)))
	}
	var out struct {
		NSFW *float64 `json:"nsfw"`
	}
	if err := json.NewDecoder(io.LimitReader(res.Body, 4096)).Decode(&out); err != nil || out.NSFW == nil {
		return 0, fmt.Errorf("photo check: bad answer")
	}
	if *out.NSFW < 0 || *out.NSFW > 1 {
		return 0, fmt.Errorf("photo check: score out of range")
	}
	return *out.NSFW, nil
}
