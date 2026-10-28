package voice

import (
	"bytes"
	"context"
	"errors"
	"io"
	"net/http"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"

	"github.com/zamansheikh/campussaga/backend/internal/modules/voice/store"
	"github.com/zamansheikh/campussaga/backend/internal/platform/apperr"
	"github.com/zamansheikh/campussaga/backend/internal/platform/db"
	"github.com/zamansheikh/campussaga/backend/internal/platform/httpx"
	"github.com/zamansheikh/campussaga/backend/internal/platform/media"
)

// UploadLimit is the request body cap for POST /uploads (photo + form).
const UploadLimit = media.MaxBytes + 1<<20

// handleUpload: multipart field "image". The photo is read into memory,
// re-encoded (dropping all metadata) and only the result is stored.
func (s *Service) handleUpload(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	q := store.New(s.d.Q(ctx))
	v, err := s.begin(ctx, q)
	if err == nil {
		err = s.requireNoBan(ctx, q, v)
	}
	if err != nil {
		httpx.WriteError(w, r, err)
		return
	}
	data, err := readImagePart(r)
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
	// The photo check sees the re-encoded thumbnail (≤ 480 px) before
	// anything is stored; a refused photo is never kept.
	score, flagged, err := s.checkPhoto(ctx, p.Thumb)
	if err != nil {
		httpx.WriteError(w, r, err)
		return
	}
	key := uuid.New().String()
	full, thumb := key+"-full.jpg", key+"-thumb.jpg"
	if err := s.media.Put(full, p.Full); err != nil {
		httpx.WriteError(w, r, err)
		return
	}
	if err := s.media.Put(thumb, p.Thumb); err != nil {
		_ = s.media.Delete(full)
		httpx.WriteError(w, r, err)
		return
	}
	up, err := q.InsertUpload(ctx, store.InsertUploadParams{UserID: v.id, FullKey: full, ThumbKey: thumb,
		Width: int32(p.Width), Height: int32(p.Height), Now: s.now(), NsfwScore: score, Flagged: flagged})
	if err != nil {
		_ = s.media.Delete(full)
		_ = s.media.Delete(thumb)
		httpx.WriteError(w, r, err)
		return
	}
	httpx.WriteOK(w, r, http.StatusCreated, Image{ID: up.ID, Width: int(up.Width), Height: int(up.Height)})
}

func readImagePart(r *http.Request) ([]byte, error) {
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

// handleImage serves a photo of an issue the caller may see.
func (s *Service) handleImage(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	q := store.New(s.d.Q(ctx))
	v, err := s.begin(ctx, q)
	if err != nil {
		httpx.WriteError(w, r, err)
		return
	}
	id, err := uuid.Parse(chi.URLParam(r, "imageId"))
	if err != nil {
		httpx.WriteError(w, r, ErrIssueNotFound)
		return
	}
	im, err := q.GetImage(ctx, id)
	if err != nil {
		httpx.WriteError(w, r, ErrIssueNotFound)
		return
	}
	if _, err := s.getIssue(ctx, q, v, im.IssueID); err != nil {
		httpx.WriteError(w, r, err)
		return
	}
	s.serve(w, r, im.FullKey, im.ThumbKey)
}

// handleUploadImage: a photo not attached yet, for its uploader only.
func (s *Service) handleUploadImage(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	q := store.New(s.d.Q(ctx))
	v, err := s.begin(ctx, q)
	if err != nil {
		httpx.WriteError(w, r, err)
		return
	}
	id, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		httpx.WriteError(w, r, ErrUploadNotFound)
		return
	}
	up, err := q.GetUpload(ctx, store.GetUploadParams{ID: id, UserID: v.id})
	if err != nil {
		httpx.WriteError(w, r, ErrUploadNotFound)
		return
	}
	s.serve(w, r, up.FullKey, up.ThumbKey)
}

func (s *Service) serve(w http.ResponseWriter, r *http.Request, full, thumb string) {
	key := full
	if r.URL.Query().Get("size") == "thumb" {
		key = thumb
	}
	f, err := s.media.Open(key)
	if err != nil {
		httpx.WriteError(w, r, ErrIssueNotFound)
		return
	}
	defer f.Close()
	w.Header().Set("Content-Type", "image/jpeg")
	w.Header().Set("Cache-Control", "private, max-age=86400")
	http.ServeContent(w, r, "", time.Time{}, f)
}

// CleanupLoop deletes photos uploaded but never attached, after 24 hours.
func (s *Service) CleanupLoop(ctx context.Context, every time.Duration) {
	t := time.NewTicker(every)
	defer t.Stop()
	for {
		if err := s.Cleanup(ctx); err != nil {
			s.log.Error("voice: cleanup uploads", "err", err)
		}
		select {
		case <-ctx.Done():
			return
		case <-t.C:
		}
	}
}

func (s *Service) Cleanup(ctx context.Context) error {
	q := store.New(s.d.Q(ctx))
	rows, err := q.ExpiredUploads(ctx, s.now().Add(-24*time.Hour))
	if err != nil {
		return err
	}
	for _, u := range rows {
		_ = s.media.Delete(u.FullKey)
		_ = s.media.Delete(u.ThumbKey)
		if err := q.DeleteUpload(ctx, u.ID); err != nil && !db.IsNoRows(err) {
			return err
		}
	}
	return nil
}
