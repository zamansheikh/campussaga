package sponsors

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
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/db"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/httpx"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/media"
)

// Ad images (2:1, within 1600×800) and sponsor logos (within 512×512) are
// re-encoded JPEGs, so no metadata survives. Every upload gets a new random
// version; the public URLs carry it (?v=) and are cached for a year when it
// is current. A draft's image needs the current version, which only the
// admin panel has, so the team can preview it before the ad goes live.

func newVersion() string {
	b := make([]byte, 5)
	_, _ = rand.Read(b)
	return hex.EncodeToString(b)
}

// Media keys allow [a-z0-9-] only.
func promoImageKey(id uuid.UUID, version string) string {
	return "promo-" + id.String() + "-" + version + ".jpg"
}

func logoKey(id uuid.UUID, version string) string {
	return "sponsor-" + id.String() + "-logo-" + version + ".jpg"
}

func (s *Service) readFile(key string) ([]byte, error) {
	f, err := s.media.Open(key)
	if err != nil {
		return nil, err
	}
	defer f.Close()
	return io.ReadAll(f)
}

// dropFile deletes a stored file, logging (not failing) when it can't.
func (s *Service) dropFile(key *string) {
	if key == nil || s.media == nil {
		return
	}
	if err := s.media.Delete(*key); err != nil && !errors.Is(err, media.ErrNotFound) {
		s.log.Warn("sponsors: file not deleted", "key", *key, "err", err)
	}
}

// readImagePart reads the multipart field "image" of at most limit bytes.
func readImagePart(w http.ResponseWriter, r *http.Request, bodyLimit int64, limit int) ([]byte, error) {
	r.Body = http.MaxBytesReader(w, r.Body, bodyLimit)
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
		n, err := io.Copy(&buf, io.LimitReader(part, int64(limit)+1))
		if errors.As(err, &tooBig) || n > int64(limit) {
			return nil, ErrImageTooLarge
		}
		if err != nil {
			return nil, apperr.BadRequest("Could not read the upload")
		}
		return buf.Bytes(), nil
	}
}

// processed turns media errors into API errors.
func processed(data []byte, err error) ([]byte, error) {
	switch {
	case errors.Is(err, media.ErrTooLarge):
		return nil, ErrImageTooLarge
	case err != nil:
		return nil, ErrInvalidImage
	}
	return data, nil
}

// ---- ad images ----------------------------------------------------------------------

// handleAdminImage: POST /admin/promos/{id}/image, multipart "image"; a
// draft or paused ad only.
func (s *Service) handleAdminImage(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	id, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		httpx.WriteError(w, r, ErrPromoNotFound)
		return
	}
	if s.media == nil {
		httpx.WriteError(w, r, ErrMediaUnavailable)
		return
	}
	p, err := s.loadPromo(ctx, id, false)
	if err != nil {
		httpx.WriteError(w, r, err)
		return
	}
	if p.Status != "draft" && p.Status != "paused" {
		httpx.WriteError(w, r, ErrPromoLocked)
		return
	}
	raw, err := readImagePart(w, r, UploadLimit, media.MaxBytes)
	if err != nil {
		httpx.WriteError(w, r, err)
		return
	}
	jpg, err := processed(media.ProcessPromo(raw))
	if err != nil {
		httpx.WriteError(w, r, err)
		return
	}
	version := newVersion()
	key := promoImageKey(id, version)
	if err := s.media.Put(key, jpg); err != nil {
		httpx.WriteError(w, r, err)
		return
	}
	var old *string
	err = s.d.InTx(ctx, func(ctx context.Context) error {
		p, err := s.loadPromo(ctx, id, true)
		if err != nil {
			return err
		}
		if p.Status != "draft" && p.Status != "paused" {
			return ErrPromoLocked
		}
		old = p.ImageKey
		if _, err := s.d.Q(ctx).Exec(ctx, `UPDATE promos SET image_key = $2, image_version = $3, updated_at = $4 WHERE id = $1`,
			id, key, version, s.now()); err != nil {
			return err
		}
		return s.audit(ctx, "promo.image", "promo", id.String(), map[string]any{"title": p.TitleEn})
	})
	if err != nil {
		s.dropFile(&key)
		httpx.WriteError(w, r, err)
		return
	}
	if old != nil && *old != key {
		s.dropFile(old)
	}
	out, err := s.adminPromo(ctx, id)
	if err != nil {
		httpx.WriteError(w, r, err)
		return
	}
	httpx.WriteOK(w, r, http.StatusOK, out)
}

// handleAdminImageDelete: DELETE /admin/promos/{id}/image (draft or paused).
func (s *Service) handleAdminImageDelete(ctx context.Context, in *promoReq) (*AdminPromo, error) {
	id := uuid.MustParse(in.ID)
	var old *string
	err := s.d.InTx(ctx, func(ctx context.Context) error {
		p, err := s.loadPromo(ctx, id, true)
		if err != nil {
			return err
		}
		if p.Status != "draft" && p.Status != "paused" {
			return ErrPromoLocked
		}
		old = p.ImageKey
		if _, err := s.d.Q(ctx).Exec(ctx, `UPDATE promos SET image_key = NULL, image_version = NULL, updated_at = $2 WHERE id = $1`,
			id, s.now()); err != nil {
			return err
		}
		return s.audit(ctx, "promo.image_remove", "promo", id.String(), map[string]any{"title": p.TitleEn})
	})
	if err != nil {
		return nil, err
	}
	s.dropFile(old)
	return s.adminPromo(ctx, id)
}

// handlePromoImage: GET /promos/{id}/image?v=, public.
func (s *Service) handlePromoImage(w http.ResponseWriter, r *http.Request) {
	id, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		httpx.WriteError(w, r, ErrNoImage)
		return
	}
	var key, version *string
	var status string
	err = s.d.Q(r.Context()).QueryRow(r.Context(), `SELECT image_key, image_version, status FROM promos WHERE id = $1`, id).
		Scan(&key, &version, &status)
	if err != nil && !db.IsNoRows(err) {
		httpx.WriteError(w, r, err)
		return
	}
	s.serveImage(w, r, key, version, status == "draft")
}

// handleSponsorLogo: GET /sponsors/{id}/logo?v=, public.
func (s *Service) handleSponsorLogo(w http.ResponseWriter, r *http.Request) {
	id, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		httpx.WriteError(w, r, ErrNoImage)
		return
	}
	var key, version *string
	err = s.d.Q(r.Context()).QueryRow(r.Context(), `SELECT logo_key, logo_version FROM sponsors WHERE id = $1`, id).Scan(&key, &version)
	if err != nil && !db.IsNoRows(err) {
		httpx.WriteError(w, r, err)
		return
	}
	s.serveImage(w, r, key, version, false)
}

// serveImage sends a stored JPEG: immutable for a year when ?v= is the
// current version, else five minutes; a draft's only with the current one.
func (s *Service) serveImage(w http.ResponseWriter, r *http.Request, key, version *string, draft bool) {
	if key == nil || version == nil || s.media == nil {
		httpx.WriteError(w, r, ErrNoImage)
		return
	}
	current := r.URL.Query().Get("v") == *version
	if draft && !current {
		httpx.WriteError(w, r, ErrNoImage)
		return
	}
	f, err := s.media.Open(*key)
	if err != nil {
		httpx.WriteError(w, r, ErrNoImage)
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

// ---- logos --------------------------------------------------------------------------

// handleAdminLogo: POST /admin/sponsors/{id}/logo, multipart "image".
func (s *Service) handleAdminLogo(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	id, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		httpx.WriteError(w, r, ErrSponsorNotFound)
		return
	}
	if s.media == nil {
		httpx.WriteError(w, r, ErrMediaUnavailable)
		return
	}
	if _, err := s.loadSponsor(ctx, id, false); err != nil {
		httpx.WriteError(w, r, err)
		return
	}
	raw, err := readImagePart(w, r, LogoUploadLimit, media.LogoMaxBytes)
	if err != nil {
		httpx.WriteError(w, r, err)
		return
	}
	jpg, err := processed(media.ProcessLogo(raw))
	if err != nil {
		httpx.WriteError(w, r, err)
		return
	}
	version := newVersion()
	key := logoKey(id, version)
	if err := s.media.Put(key, jpg); err != nil {
		httpx.WriteError(w, r, err)
		return
	}
	var old *string
	var out *AdminSponsor
	err = s.d.InTx(ctx, func(ctx context.Context) error {
		x, err := s.loadSponsor(ctx, id, true)
		if err != nil {
			return err
		}
		old = x.LogoKey
		now := s.now()
		if _, err := s.d.Q(ctx).Exec(ctx, `UPDATE sponsors SET logo_key = $2, logo_version = $3, updated_at = $4 WHERE id = $1`,
			id, key, version, now); err != nil {
			return err
		}
		x.LogoKey, x.LogoVersion, x.UpdatedAt = &key, &version, now
		if out, err = s.sponsorView(ctx, x); err != nil {
			return err
		}
		return s.audit(ctx, "sponsor.logo", "sponsor", id.String(), map[string]any{"name": x.Name})
	})
	if err != nil {
		s.dropFile(&key)
		httpx.WriteError(w, r, err)
		return
	}
	if old != nil && *old != key {
		s.dropFile(old)
	}
	httpx.WriteOK(w, r, http.StatusOK, out)
}

// handleAdminLogoDelete: DELETE /admin/sponsors/{id}/logo.
func (s *Service) handleAdminLogoDelete(ctx context.Context, in *sponsorReq) (*AdminSponsor, error) {
	id := uuid.MustParse(in.ID)
	var old *string
	var out *AdminSponsor
	err := s.d.InTx(ctx, func(ctx context.Context) error {
		x, err := s.loadSponsor(ctx, id, true)
		if err != nil {
			return err
		}
		old = x.LogoKey
		now := s.now()
		if _, err := s.d.Q(ctx).Exec(ctx, `UPDATE sponsors SET logo_key = NULL, logo_version = NULL, updated_at = $2 WHERE id = $1`,
			id, now); err != nil {
			return err
		}
		x.LogoKey, x.LogoVersion, x.UpdatedAt = nil, nil, now
		if out, err = s.sponsorView(ctx, x); err != nil {
			return err
		}
		return s.audit(ctx, "sponsor.logo_remove", "sponsor", id.String(), map[string]any{"name": x.Name})
	})
	if err != nil {
		return nil, err
	}
	s.dropFile(old)
	return out, nil
}
