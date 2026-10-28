// Package photos is students' profile photos: an uploaded photo (re-encoded
// with every detail such as location removed, and checked for nudity before
// anything is stored), shown to the student, classmates who share a class
// group, and admins. Without one, apps show the Google account photo, then
// initials. Campus Voice never shows photos (it stays anonymous).
package photos

import (
	"bytes"
	"context"
	"errors"
	"io"
	"log/slog"
	"net/http"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"

	"github.com/zamansheikh/varsitykotha/backend/internal/modules/photos/store"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/apperr"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/auth"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/db"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/httpx"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/media"
)

// UploadLimit is the request body cap for PUT /me/photo.
const UploadLimit = media.MaxBytes + 1<<20

var (
	ErrPhotoNotFound   = apperr.New(404, "PHOTO_NOT_FOUND", "No photo")
	ErrImageTooLarge   = apperr.New(413, "IMAGE_TOO_LARGE", "The photo is too large")
	ErrImageInvalid    = apperr.New(422, "IMAGE_INVALID", "This file isn't a photo we can use (JPEG, PNG or WebP)")
	ErrPhotoNotAllowed = apperr.New(422, "PHOTO_NOT_ALLOWED", "This photo can't be used")
	ErrCheckDown       = apperr.New(503, "PHOTO_CHECK_UNAVAILABLE", "Photos can't be checked right now. Try again later")
)

// Scorer rates how likely a photo is to be nudity, 0..1 (the backend/nsfw
// service; voice.HTTPChecker fits).
type Scorer interface {
	Score(ctx context.Context, jpeg []byte) (float64, error)
}

// Check: photos scoring at least Max are refused. Required (production): a
// photo that can't be checked is refused too (a profile photo is shown
// straight away, so it can't wait for a moderator).
type Check struct {
	Scorer   Scorer
	Max      float64
	Required bool
}

type Service struct {
	d     *db.DB
	media media.Store
	check Check
	// me is the caller's profile, returned after a change (accounts.GetMe).
	me  func(ctx context.Context) (any, error)
	log *slog.Logger
}

func NewService(d *db.DB, m media.Store, check Check, me func(ctx context.Context) (any, error), log *slog.Logger) *Service {
	if check.Max <= 0 {
		check.Max = 0.70
	}
	if log == nil {
		log = slog.Default()
	}
	return &Service{d: d, media: m, check: check, me: me, log: log}
}

func (s *Service) Routes(r *httpx.Router) {
	st := r.Student()
	st.With(r.LimitUser("profile-photo", 10, 24*time.Hour)).Put("/me/photo", s.handlePut)
	st.Delete("/me/photo", s.handleDelete)
	st.Get("/users/{id}/photo", s.handleGet)
}

func (s *Service) handlePut(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	c := auth.MustUser(ctx)
	if s.media == nil {
		httpx.WriteError(w, r, ErrCheckDown)
		return
	}
	data, err := readImage(r)
	if err != nil {
		httpx.WriteError(w, r, err)
		return
	}
	p, err := media.Process(data)
	switch {
	case errors.Is(err, media.ErrTooLarge):
		httpx.WriteError(w, r, ErrImageTooLarge)
		return
	case err != nil:
		httpx.WriteError(w, r, ErrImageInvalid)
		return
	}
	if err := s.allowed(ctx, p.Thumb); err != nil {
		httpx.WriteError(w, r, err)
		return
	}
	key := "avatar-" + uuid.New().String() + ".jpg"
	if err := s.media.Put(key, p.Thumb); err != nil {
		httpx.WriteError(w, r, err)
		return
	}
	q := store.New(s.d.Q(ctx))
	old, err := q.PhotoKey(ctx, c.UserID)
	if err == nil {
		err = q.SetPhotoKey(ctx, store.SetPhotoKeyParams{ID: c.UserID, PhotoKey: &key})
	}
	if err != nil {
		_ = s.media.Delete(key)
		httpx.WriteError(w, r, err)
		return
	}
	s.remove(old)
	s.writeMe(w, r)
}

func (s *Service) handleDelete(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	c := auth.MustUser(ctx)
	q := store.New(s.d.Q(ctx))
	old, err := q.PhotoKey(ctx, c.UserID)
	if err == nil {
		err = q.SetPhotoKey(ctx, store.SetPhotoKeyParams{ID: c.UserID})
	}
	if err != nil {
		httpx.WriteError(w, r, err)
		return
	}
	s.remove(old)
	s.writeMe(w, r)
}

// handleGet serves a student's uploaded photo (400 px JPEG) to themselves,
// classmates sharing a group, or an admin. ?v= is the photo key, so the
// app can cache each version for long.
func (s *Service) handleGet(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	c := auth.MustUser(ctx)
	owner, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		httpx.WriteError(w, r, ErrPhotoNotFound)
		return
	}
	q := store.New(s.d.Q(ctx))
	if owner != c.UserID && c.Role != "admin" {
		ok, err := q.ShareGroup(ctx, store.ShareGroupParams{Viewer: c.UserID, Owner: owner})
		if err != nil || !ok {
			httpx.WriteError(w, r, ErrPhotoNotFound)
			return
		}
	}
	key, err := q.PhotoKey(ctx, owner)
	if err != nil || key == nil || s.media == nil {
		httpx.WriteError(w, r, ErrPhotoNotFound)
		return
	}
	f, err := s.media.Open(*key)
	if err != nil {
		httpx.WriteError(w, r, ErrPhotoNotFound)
		return
	}
	defer f.Close()
	w.Header().Set("Content-Type", "image/jpeg")
	w.Header().Set("Cache-Control", "private, max-age=604800")
	http.ServeContent(w, r, "", time.Time{}, f)
}

// Remove deletes a stored photo (after the account or the photo is gone).
func (s *Service) Remove(key *string) { s.remove(key) }

func (s *Service) remove(key *string) {
	if key == nil || s.media == nil {
		return
	}
	if err := s.media.Delete(*key); err != nil && !errors.Is(err, media.ErrNotFound) {
		s.log.Warn("photos: deleting an old photo", "err", err)
	}
}

// allowed runs the nudity check; logs carry the score only.
func (s *Service) allowed(ctx context.Context, jpeg []byte) error {
	if s.check.Scorer == nil {
		if s.check.Required {
			return ErrCheckDown
		}
		return nil
	}
	score, err := s.check.Scorer.Score(ctx, jpeg)
	if err != nil {
		s.log.Warn("photos: photo check unavailable", "err", err)
		if s.check.Required {
			return ErrCheckDown
		}
		return nil
	}
	if score >= s.check.Max {
		s.log.Info("photos: profile photo refused by the photo check", "score", score)
		return ErrPhotoNotAllowed
	}
	return nil
}

func (s *Service) writeMe(w http.ResponseWriter, r *http.Request) {
	me, err := s.me(r.Context())
	if err != nil {
		httpx.WriteError(w, r, err)
		return
	}
	httpx.WriteOK(w, r, http.StatusOK, me)
}

func readImage(r *http.Request) ([]byte, error) {
	mr, err := r.MultipartReader()
	if err != nil {
		return nil, apperr.BadRequest("Send the photo as multipart/form-data, field \"image\"")
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
