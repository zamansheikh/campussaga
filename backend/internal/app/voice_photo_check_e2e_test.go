package app

import (
	"context"
	"net/http"
	"os"
	"sync"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/zamansheikh/varsitykotha/backend/internal/platform/media/mediatest"
)

// queueChecker answers the photo check with the next queued score.
type queueChecker struct {
	mu     sync.Mutex
	scores []float64
	seen   int
}

func (q *queueChecker) Score(_ context.Context, jpeg []byte) (float64, error) {
	q.mu.Lock()
	defer q.mu.Unlock()
	q.seen++
	s := q.scores[0]
	q.scores = q.scores[1:]
	return s, nil
}

// The photo check: explicit photos are refused and never stored, borderline
// ones hold their issue for a moderator (who sees the score), safe ones
// pass. Defaults: refuse ≥ 0.98, hold ≥ 0.70.
func TestVoicePhotoCheck(t *testing.T) {
	check := &queueChecker{}
	h := newHarnessWith(t, func(o *Options) { o.PhotoChecker = check })
	c := newVoiceCast(h)
	photo := mediatest.JPEGWithExif(t, 800, 600, 1)
	stored := func() int {
		files, err := os.ReadDir(h.media.Dir)
		require.NoError(t, err)
		return len(files)
	}
	upload := func(score float64) *response {
		check.scores = append(check.scores, score)
		return h.upload(c.author, photo)
	}
	id := func(r *response) string {
		require.Equal(t, http.StatusCreated, r.Status, r.Raw)
		var up struct {
			ID string `json:"id"`
		}
		r.into(t, &up)
		return up.ID
	}

	// Explicit: refused, nothing kept.
	r := upload(0.995)
	assert.Equal(t, http.StatusUnprocessableEntity, r.Status)
	assert.Equal(t, "PHOTO_NOT_ALLOWED", r.code())
	assert.Equal(t, 0, stored())

	// Safe: the issue is posted as usual.
	safe := id(upload(0.05))
	is := h.postIssue(c.author, issueBody("Broken water pump in Hall 3", map[string]any{"imageIds": []string{safe}}))
	assert.Equal(t, "visible", is.Visibility)
	assert.Equal(t, 1, h.getIssue(c.mate, is.ID).ImageCount)

	// Borderline: posted, but held for a moderator until approved.
	flagged := id(upload(0.85))
	held := h.postIssue(c.author, issueBody("Broken window in the reading room",
		map[string]any{"imageIds": []string{safe2(t, h, c, check), flagged}}))
	assert.Equal(t, "held", held.Visibility)
	assert.Equal(t, "photo_check", held.HoldReason)
	assert.Equal(t, "ISSUE_NOT_FOUND", h.do("GET", "/issues/"+held.ID, c.mate, nil).code(), "classmates can't see it yet")

	var mod struct {
		PhotoChecks []struct {
			ImageID string   `json:"imageId"`
			Score   *float64 `json:"score"`
			Flagged bool     `json:"flagged"`
		} `json:"photoChecks"`
	}
	r = h.do("GET", "/moderation/issues/"+held.ID, c.mod, nil)
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	r.into(t, &mod)
	require.Len(t, mod.PhotoChecks, 2)
	assert.False(t, mod.PhotoChecks[0].Flagged)
	assert.Equal(t, flagged, mod.PhotoChecks[1].ImageID)
	assert.True(t, mod.PhotoChecks[1].Flagged)
	require.NotNil(t, mod.PhotoChecks[1].Score)
	assert.InDelta(t, 0.85, *mod.PhotoChecks[1].Score, 0.001)

	// Students never see the check's numbers.
	r = h.do("GET", "/issues/"+is.ID, c.author, nil)
	assert.NotContains(t, r.Raw, "photoChecks")
	assert.NotContains(t, r.Raw, "nsfw")

	// The moderator approves: now everyone sees it.
	r = h.do("POST", "/moderation/issues/"+held.ID, c.mod, map[string]string{"action": "approve"})
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	assert.Equal(t, "visible", h.getIssue(c.mate, held.ID).Visibility)
	assert.Equal(t, 4, check.seen)
}

// safe2 uploads another safe photo.
func safe2(t *testing.T, h *harness, c voiceCast, check *queueChecker) string {
	t.Helper()
	check.scores = append(check.scores, 0.1)
	r := h.upload(c.author, mediatest.JPEGWithExif(t, 640, 480, 1))
	require.Equal(t, http.StatusCreated, r.Status, r.Raw)
	var up struct {
		ID string `json:"id"`
	}
	r.into(t, &up)
	return up.ID
}
