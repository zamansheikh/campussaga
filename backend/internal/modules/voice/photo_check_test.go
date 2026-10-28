package voice

import (
	"context"
	"errors"
	"io"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

type fixedChecker struct {
	score float64
	err   error
}

func (f fixedChecker) Score(context.Context, []byte) (float64, error) { return f.score, f.err }

func TestCheckPhoto(t *testing.T) {
	quiet := slog.New(slog.NewTextHandler(io.Discard, nil))
	down := fixedChecker{err: errors.New("connection refused")}
	for _, c := range []struct {
		name     string
		check    PhotoCheck
		flagged  bool
		scored   bool
		rejected bool
	}{
		{"safe", PhotoCheck{Checker: fixedChecker{score: 0.12}, Reject: 0.98, Hold: 0.7}, false, true, false},
		{"borderline: held", PhotoCheck{Checker: fixedChecker{score: 0.81}, Reject: 0.98, Hold: 0.7}, true, true, false},
		{"explicit: refused", PhotoCheck{Checker: fixedChecker{score: 0.995}, Reject: 0.98, Hold: 0.7}, true, true, true},
		{"checker down in production: held", PhotoCheck{Checker: down, Reject: 0.98, Hold: 0.7, Required: true}, true, false, false},
		{"not configured in production: held", PhotoCheck{Reject: 0.98, Hold: 0.7, Required: true}, true, false, false},
		{"checker down in development: skipped", PhotoCheck{Checker: down, Reject: 0.98, Hold: 0.7}, false, false, false},
		{"not configured in development: skipped", PhotoCheck{Reject: 0.98, Hold: 0.7}, false, false, false},
	} {
		t.Run(c.name, func(t *testing.T) {
			s := &Service{log: quiet}
			s.SetPhotoCheck(c.check)
			score, flagged, err := s.checkPhoto(context.Background(), []byte("jpeg"))
			assert.Equal(t, c.rejected, errors.Is(err, ErrPhotoNotAllowed))
			assert.Equal(t, c.flagged, flagged)
			assert.Equal(t, c.scored, score != nil)
		})
	}
}

func TestHTTPChecker(t *testing.T) {
	var got []byte
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != "/classify" || r.Method != http.MethodPost {
			http.NotFound(w, r)
			return
		}
		got, _ = io.ReadAll(r.Body)
		switch string(got) {
		case "bad":
			http.Error(w, `{"error":"not an image"}`, http.StatusBadRequest)
		case "weird":
			_, _ = io.WriteString(w, `{"nsfw": 3}`)
		default:
			_, _ = io.WriteString(w, `{"sfw": 0.2, "nsfw": 0.8, "model": "test"}`)
		}
	}))
	defer srv.Close()
	c := NewHTTPChecker(srv.URL + "/")

	score, err := c.Score(context.Background(), []byte("jpeg-bytes"))
	require.NoError(t, err)
	assert.InDelta(t, 0.8, score, 1e-9)
	assert.Equal(t, "jpeg-bytes", string(got), "the photo bytes are sent as the body")

	_, err = c.Score(context.Background(), []byte("bad"))
	assert.Error(t, err)
	_, err = c.Score(context.Background(), []byte("weird"))
	assert.Error(t, err, "a score outside 0..1 is not trusted")
	srv.Close()
	_, err = c.Score(context.Background(), []byte("jpeg"))
	assert.Error(t, err, "service down")
}
