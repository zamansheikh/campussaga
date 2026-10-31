package app

import (
	"context"
	"fmt"
	"net/http"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

type announcementJSON struct {
	ID        string     `json:"id"`
	Body      string     `json:"body"`
	Pinned    bool       `json:"pinned"`
	CreatedAt time.Time  `json:"createdAt"`
	EditedAt  *time.Time `json:"editedAt"`
}

func (h *harness) announcements(token string) []announcementJSON {
	h.t.Helper()
	r := h.do("GET", "/groups", token, nil)
	require.Equal(h.t, http.StatusOK, r.Status, r.Raw)
	var out struct {
		Groups []struct {
			Announcements []announcementJSON `json:"announcements"`
		} `json:"groups"`
	}
	r.into(h.t, &out)
	require.Len(h.t, out.Groups, 1)
	return out.Groups[0].Announcements
}

func bodies(as []announcementJSON) []string {
	out := make([]string, 0, len(as))
	for _, a := range as {
		out = append(out, a.Body)
	}
	return out
}

func TestAnnouncements(t *testing.T) {
	h := newHarness(t)
	cr := h.signIn("cr@test.ac.bd").Tokens.AccessToken
	mate := h.signIn("mate@test.ac.bd").Tokens.AccessToken
	g := h.createGroup(cr)
	require.Equal(t, http.StatusOK, h.do("POST", "/groups/join", mate, map[string]string{"code": g.JoinCode}).Status)
	path := "/groups/" + g.ID + "/announcements"

	post := func(body string, pinned bool) announcementJSON {
		t.Helper()
		r := h.do("POST", path, cr, map[string]any{"body": body, "pinned": pinned})
		require.Equal(t, http.StatusCreated, r.Status, r.Raw)
		var a announcementJSON
		r.into(t, &a)
		h.advance(time.Minute)
		return a
	}

	// Line breaks are kept; extra blank lines and spaces are not.
	first := post("  Quiz on Sunday  \n\n\n Chapters 3-4 ", false)
	assert.Equal(t, "Quiz on Sunday\n\nChapters 3-4", first.Body)
	assert.Equal(t, "VALIDATION_FAILED", h.do("POST", path, cr, map[string]any{"body": " \n "}).code())
	assert.Equal(t, "NOT_GROUP_CR", h.do("POST", path, mate, map[string]any{"body": "hi"}).code())

	rules := post("Class rules: phones silent", true)
	post("Bring a calculator tomorrow", false)
	assert.Equal(t,
		[]string{"Class rules: phones silent", "Bring a calculator tomorrow", "Quiz on Sunday\n\nChapters 3-4"},
		bodies(h.announcements(mate)), "pinned first, then newest")

	// Pinning another one unpins the first; unpinning works too.
	r := h.do("PATCH", path+"/"+first.ID, cr, map[string]any{"pinned": true})
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	got := h.announcements(mate)
	assert.True(t, got[0].Pinned)
	assert.Equal(t, first.ID, got[0].ID)
	for _, a := range got[1:] {
		assert.False(t, a.Pinned, a.Body)
	}
	require.Equal(t, http.StatusOK, h.do("PATCH", path+"/"+first.ID, cr, map[string]any{"pinned": false}).Status)
	assert.Equal(t, "VALIDATION_FAILED", h.do("PATCH", path+"/"+first.ID, cr, map[string]any{}).code())
	assert.Equal(t, "NOT_GROUP_CR", h.do("PATCH", path+"/"+first.ID, mate, map[string]any{"pinned": true}).code())

	// Edit the text: classmates see the new text, marked edited; pinning
	// alone isn't an edit.
	assert.Nil(t, h.announcements(mate)[0].EditedAt, "pinned, not edited")
	r = h.do("PATCH", path+"/"+first.ID, cr, map[string]any{"body": " Quiz moved to Monday \n\n\n Chapters 3-5 "})
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	var edited announcementJSON
	r.into(t, &edited)
	assert.Equal(t, "Quiz moved to Monday\n\nChapters 3-5", edited.Body)
	require.NotNil(t, edited.EditedAt)
	assert.Contains(t, bodies(h.announcements(mate)), "Quiz moved to Monday\n\nChapters 3-5")
	assert.Equal(t, "VALIDATION_FAILED", h.do("PATCH", path+"/"+first.ID, cr, map[string]any{"body": "  "}).code())
	assert.Equal(t, "NOT_GROUP_CR", h.do("PATCH", path+"/"+first.ID, mate, map[string]any{"body": "hacked"}).code())
	// Text and pin together.
	r = h.do("PATCH", path+"/"+first.ID, cr, map[string]any{"body": "Quiz on Sunday\n\nChapters 3-4", "pinned": false})
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	r.into(t, &edited)
	assert.False(t, edited.Pinned)
	assert.Equal(t, "Quiz on Sunday\n\nChapters 3-4", edited.Body)

	// Delete.
	assert.Equal(t, "NOT_GROUP_CR", h.do("DELETE", path+"/"+rules.ID, mate, nil).code())
	require.Equal(t, http.StatusNoContent, h.do("DELETE", path+"/"+rules.ID, cr, nil).Status)
	assert.Equal(t, "ANNOUNCEMENT_NOT_FOUND", h.do("DELETE", path+"/"+rules.ID, cr, nil).code())
	assert.Len(t, h.announcements(mate), 2)

	// Old messages drop off after 30 days; a pinned one stays.
	_, err := h.app.DB.Pool.Exec(context.Background(),
		`UPDATE announcements SET created_at = now() - interval '40 days'`)
	require.NoError(t, err)
	assert.Empty(t, h.announcements(mate))
	require.Equal(t, http.StatusOK, h.do("PATCH", path+"/"+first.ID, cr, map[string]any{"pinned": true}).Status)
	assert.Equal(t, []string{"Quiz on Sunday\n\nChapters 3-4"}, bodies(h.announcements(mate)))
}

func TestAnnouncementLimits(t *testing.T) {
	h := newHarness(t)
	cr := h.signIn("cr@test.ac.bd").Tokens.AccessToken
	g := h.createGroup(cr)
	path := "/groups/" + g.ID + "/announcements"
	for i := range 25 {
		r := h.do("POST", path, cr, map[string]any{"body": fmt.Sprintf("note %d", i)})
		require.Equal(t, http.StatusCreated, r.Status, r.Raw)
		h.advance(time.Second)
	}
	got := h.announcements(cr)
	assert.Len(t, got, 20, "the newest 20")
	assert.Equal(t, "note 24", got[0].Body)

	// 30 posts a day per CR.
	for range 5 {
		require.Equal(t, http.StatusCreated, h.do("POST", path, cr, map[string]any{"body": "x"}).Status)
	}
	assert.Equal(t, "TOO_MANY_REQUESTS", h.do("POST", path, cr, map[string]any{"body": "x"}).code())
}
