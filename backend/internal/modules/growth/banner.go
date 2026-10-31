package growth

import (
	"bytes"
	"context"
	"crypto/rand"
	"encoding/hex"
	"errors"
	"io"
	"net/http"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"

	"github.com/zamansheikh/varsitykotha/backend/internal/platform/apperr"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/httpx"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/media"
)

// Campaign banners: the team uploads a photo (2:1, e.g. 1600×800); it is
// re-encoded to a JPEG at most media.BannerWidth wide and served publicly,
// so the app and the web rules page can show it without signing in.

var (
	ErrInvalidImage  = apperr.New(http.StatusBadRequest, "INVALID_IMAGE", "Send a JPEG, PNG or WebP image")
	ErrImageTooLarge = apperr.New(http.StatusRequestEntityTooLarge, "IMAGE_TOO_LARGE", "This image is too large (8 MB at most)")
	ErrNoBanner      = apperr.New(http.StatusNotFound, "BANNER_NOT_FOUND", "This campaign has no banner")
)

// BannerUploadLimit caps a banner upload's request body: the photo plus
// room for the multipart framing (app.go raises the API's 64 KB cap to it).
const BannerUploadLimit = media.MaxBytes + 1<<20

// SetMedia gives the service somewhere to keep banner photos.
func (s *Service) SetMedia(m media.Store) { s.media = m }

func bannerVersion() string {
	b := make([]byte, 5)
	_, _ = rand.Read(b)
	return hex.EncodeToString(b)
}

// bannerKey is the stored file name (media keys allow [a-z0-9-] only).
func bannerKey(id uuid.UUID, version string) string {
	return "campaign-" + id.String() + "-banner-" + version + ".jpg"
}

// handleAdminBanner: POST /admin/campaigns/{id}/banner, multipart "image".
func (s *Service) handleAdminBanner(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	id, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		httpx.WriteError(w, r, ErrCampaignNotFound)
		return
	}
	if s.media == nil {
		httpx.WriteError(w, r, apperr.New(http.StatusServiceUnavailable, "MEDIA_UNAVAILABLE", "Photos can't be stored right now"))
		return
	}
	if _, err := s.loadCampaign(ctx, id, false); err != nil {
		httpx.WriteError(w, r, err)
		return
	}
	data, err := readBannerPart(w, r)
	if err != nil {
		httpx.WriteError(w, r, err)
		return
	}
	jpg, err := media.ProcessBanner(data)
	switch {
	case errors.Is(err, media.ErrTooLarge):
		httpx.WriteError(w, r, ErrImageTooLarge)
		return
	case err != nil:
		httpx.WriteError(w, r, ErrInvalidImage)
		return
	}
	version := bannerVersion()
	key := bannerKey(id, version)
	if err := s.media.Put(key, jpg); err != nil {
		httpx.WriteError(w, r, err)
		return
	}
	var out AdminCampaign
	var old *string
	err = s.d.InTx(ctx, func(ctx context.Context) error {
		c, err := s.loadCampaign(ctx, id, true)
		if err != nil {
			return err
		}
		old = c.BannerKey
		if _, err := s.d.Q(ctx).Exec(ctx, `UPDATE campaigns SET banner_key = $2, banner_version = $3, updated_at = $4 WHERE id = $1`,
			id, key, version, s.now()); err != nil {
			return err
		}
		c.BannerKey, c.BannerVersion, c.UpdatedAt = &key, &version, s.now()
		out = s.adminView(c)
		return s.audit(ctx, "campaign.banner", "campaign", id.String(), map[string]any{"title": c.TitleEn})
	})
	if err != nil {
		_ = s.media.Delete(key)
		httpx.WriteError(w, r, err)
		return
	}
	if old != nil && *old != key {
		if err := s.media.Delete(*old); err != nil && !errors.Is(err, media.ErrNotFound) {
			s.log.Warn("growth: old banner not deleted", "key", *old, "err", err)
		}
	}
	httpx.WriteOK(w, r, http.StatusOK, out)
}

// handleAdminBannerDelete: DELETE /admin/campaigns/{id}/banner.
func (s *Service) handleAdminBannerDelete(ctx context.Context, in *campaignReq) (*AdminCampaign, error) {
	id := uuid.MustParse(in.ID)
	var out AdminCampaign
	var old *string
	err := s.d.InTx(ctx, func(ctx context.Context) error {
		c, err := s.loadCampaign(ctx, id, true)
		if err != nil {
			return err
		}
		old = c.BannerKey
		if _, err := s.d.Q(ctx).Exec(ctx, `UPDATE campaigns SET banner_key = NULL, banner_version = NULL, updated_at = $2 WHERE id = $1`,
			id, s.now()); err != nil {
			return err
		}
		c.BannerKey, c.BannerVersion, c.UpdatedAt = nil, nil, s.now()
		out = s.adminView(c)
		return s.audit(ctx, "campaign.banner_remove", "campaign", id.String(), map[string]any{"title": c.TitleEn})
	})
	if err != nil {
		return nil, err
	}
	if old != nil && s.media != nil {
		if err := s.media.Delete(*old); err != nil && !errors.Is(err, media.ErrNotFound) {
			s.log.Warn("growth: banner not deleted", "key", *old, "err", err)
		}
	}
	return &out, nil
}

// handleBanner: GET /campaigns/{id}/banner, public. Long-cached when ?v=
// names the current version (the URL changes with every new banner). A
// draft's banner needs that exact version, which only the admin panel has,
// so the team can preview it before the campaign goes live.
func (s *Service) handleBanner(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	id, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		httpx.WriteError(w, r, ErrNoBanner)
		return
	}
	c, err := s.loadCampaign(ctx, id, false)
	if err != nil || c.BannerKey == nil || c.BannerVersion == nil || s.media == nil {
		httpx.WriteError(w, r, ErrNoBanner)
		return
	}
	current := r.URL.Query().Get("v") == *c.BannerVersion
	if c.Status == "draft" && !current {
		httpx.WriteError(w, r, ErrNoBanner)
		return
	}
	f, err := s.media.Open(*c.BannerKey)
	if err != nil {
		httpx.WriteError(w, r, ErrNoBanner)
		return
	}
	defer f.Close()
	w.Header().Set("Content-Type", "image/jpeg")
	if current {
		w.Header().Set("Cache-Control", "public, max-age=31536000, immutable")
	} else {
		w.Header().Set("Cache-Control", "public, max-age=300")
	}
	http.ServeContent(w, r, "", time.Time{}, f)
}

// readBannerPart reads the multipart field "image" (at most media.MaxBytes).
func readBannerPart(w http.ResponseWriter, r *http.Request) ([]byte, error) {
	r.Body = http.MaxBytesReader(w, r.Body, BannerUploadLimit)
	mr, err := r.MultipartReader()
	if err != nil {
		return nil, apperr.BadRequest("Send the image as multipart/form-data, field \"image\"")
	}
	for {
		part, err := mr.NextPart()
		if err == io.EOF {
			return nil, apperr.Validation(map[string]string{"image": "is required"})
		}
		var tooBig *http.MaxBytesError
		if errors.As(err, &tooBig) {
			return nil, ErrImageTooLarge
		}
		if err != nil {
			return nil, apperr.BadRequest("Could not read the upload")
		}
		if part.FormName() != "image" {
			_ = part.Close()
			continue
		}
		var buf bytes.Buffer
		n, err := io.Copy(&buf, io.LimitReader(part, media.MaxBytes+1))
		if errors.As(err, &tooBig) || n > media.MaxBytes {
			return nil, ErrImageTooLarge
		}
		if err != nil {
			return nil, apperr.BadRequest("Could not read the upload")
		}
		return buf.Bytes(), nil
	}
}
