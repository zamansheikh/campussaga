package app

import (
	"context"
	"net/http"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// The harness clock is Tuesday 27 October 2026, 15:00 in Dhaka.

func TestMoveClassToAnotherDay(t *testing.T) {
	h := newHarness(t)
	cr := h.signIn("cr@test.ac.bd").Tokens.AccessToken
	mate := h.signIn("mate@test.ac.bd").Tokens.AccessToken
	g := h.createGroup(cr)
	require.Equal(t, http.StatusOK, h.do("POST", "/groups/join", mate, map[string]string{"code": g.JoinCode}).Status)
	h.register(mate, "tok-mate", "android", "en")

	r := h.do("POST", "/groups/"+g.ID+"/slots", cr, slotBody("CSE311", 5, "09:00", "10:30")) // Friday
	require.Equal(t, http.StatusCreated, r.Status, r.Raw)
	var slot slotJSON
	r.into(t, &slot)
	changes := "/groups/" + g.ID + "/changes"

	// Friday 30 Oct moved to Wednesday 28 Oct (earlier), 11:00, room 402.
	move := map[string]any{"kind": "moved", "slotId": slot.ID, "date": "2026-10-30", "newDate": "2026-10-28",
		"start": "11:00", "end": "12:30", "room": "402"}
	r = h.do("POST", changes, cr, move)
	require.Equal(t, http.StatusCreated, r.Status, r.Raw)
	var ch struct {
		ID      string  `json:"id"`
		NewDate *string `json:"newDate"`
	}
	r.into(t, &ch)
	require.NotNil(t, ch.NewDate)
	assert.Equal(t, "2026-10-28", *ch.NewDate)

	n := h.sent()["tok-mate"]
	assert.Equal(t, "CSE311 moved to tomorrow", n.Title)
	assert.Equal(t, "11:00 AM – 12:30 PM · Room 402 · was Fri 30 Oct", n.Body)

	// A same-day time change has no new day; bad new days are refused.
	assert.Equal(t, "VALIDATION_FAILED", h.do("POST", changes, cr, map[string]any{
		"kind": "cancelled", "slotId": slot.ID, "date": "2026-10-30", "newDate": "2026-10-28"}).code(), "only moved")
	move["newDate"] = "2026-10-20"
	assert.Equal(t, "VALIDATION_FAILED", h.do("POST", changes, cr, move).code(), "in the past")

	// Moved later (Fri 30 Oct → Mon 2 Nov): still listed after its own date.
	move["newDate"] = "2026-11-02"
	r = h.do("POST", changes, cr, move)
	require.Equal(t, http.StatusCreated, r.Status, r.Raw)
	r.into(t, &ch)
	require.Len(t, h.changes(mate), 1, "replaces the earlier move")
	h.advance(4 * 24 * time.Hour) // Saturday 31 Oct: the original Friday is past
	mate = h.signIn("mate@test.ac.bd").Tokens.AccessToken
	cr = h.signIn("cr@test.ac.bd").Tokens.AccessToken
	h.register(mate, "tok-mate", "android", "en")
	seen := h.changes(mate)
	require.Len(t, seen, 1, "the class still happens on Monday")

	// The CR can still change that move (its own Friday is past)…
	move["newDate"] = "2026-11-03"
	r = h.do("POST", changes, cr, move)
	require.Equal(t, http.StatusCreated, r.Status, r.Raw)
	r.into(t, &ch)
	require.Len(t, h.changes(mate), 1)
	// …but a past class can't be cancelled or changed on its own day.
	assert.Equal(t, "VALIDATION_FAILED", h.do("POST", changes, cr, map[string]any{
		"kind": "cancelled", "slotId": slot.ID, "date": "2026-10-30"}).code())

	// Undo: one push, back on Friday.
	h.sent()
	require.Equal(t, http.StatusNoContent, h.do("DELETE", changes+"/"+ch.ID, cr, nil).Status)
	assert.Equal(t, "CSE311 is back on Fri 30 Oct", h.sent()["tok-mate"].Title)
}

type assessmentJSON struct {
	ID         string  `json:"id"`
	Kind       string  `json:"kind"`
	CourseCode string  `json:"courseCode"`
	Date       string  `json:"date"`
	Start      *string `json:"start"`
	End        *string `json:"end"`
	Room       string  `json:"room"`
	Topics     string  `json:"topics"`
	CanEdit    bool    `json:"canEdit"`
	CreatedBy  *struct {
		Name *string `json:"name"`
	} `json:"createdBy"`
}

func (h *harness) assessments(token string) []assessmentJSON {
	h.t.Helper()
	r := h.do("GET", "/groups", token, nil)
	require.Equal(h.t, http.StatusOK, r.Status, r.Raw)
	var out struct {
		Groups []struct {
			Assessments []assessmentJSON `json:"assessments"`
		} `json:"groups"`
	}
	r.into(h.t, &out)
	require.Len(h.t, out.Groups, 1)
	return out.Groups[0].Assessments
}

func TestTestsAndDeadlines(t *testing.T) {
	h := newHarness(t)
	cr := h.signIn("cr@test.ac.bd").Tokens.AccessToken
	mate := h.named("mate@test.ac.bd", "Rafi")
	other := h.signIn("other@test.ac.bd").Tokens.AccessToken
	g := h.createGroup(cr)
	for _, tok := range []string{mate, other} {
		require.Equal(t, http.StatusOK, h.do("POST", "/groups/join", tok, map[string]string{"code": g.JoinCode}).Status)
	}
	h.register(cr, "tok-cr", "android", "bn")
	h.register(other, "tok-other", "android", "en")
	path := "/groups/" + g.ID + "/assessments"

	// Any member adds one; classmates get a push in their language.
	r := h.do("POST", path, mate, map[string]any{
		"kind": "class_test", "courseCode": " CSE 101 ", "date": "2026-10-28",
		"start": "10:00", "end": "10:30", "room": "402", "topics": "Chapters 1–3",
	})
	require.Equal(t, http.StatusCreated, r.Status, r.Raw)
	var a assessmentJSON
	r.into(t, &a)
	assert.Equal(t, "CSE 101", a.CourseCode)
	assert.True(t, a.CanEdit)
	require.NotNil(t, a.CreatedBy)
	assert.Equal(t, "Rafi", *a.CreatedBy.Name)
	sent := h.sent()
	assert.Equal(t, "CSE 101: Class test tomorrow", sent["tok-other"].Title)
	assert.Equal(t, "10:00 AM – 10:30 AM · Room 402 · Chapters 1–3", sent["tok-other"].Body)
	assert.Equal(t, "CSE 101: ক্লাস টেস্ট আগামীকাল", sent["tok-cr"].Title)
	assert.Equal(t, "assessment", sent["tok-cr"].Data["type"])

	// Who may change it: the author and the CR, not another member.
	list := h.assessments(other)
	require.Len(t, list, 1)
	assert.False(t, list[0].CanEdit)
	assert.True(t, h.assessments(cr)[0].CanEdit)
	upd := map[string]any{"kind": "class_test", "courseCode": "CSE 101", "date": "2026-10-29", "start": "10:00"}
	assert.Equal(t, "NOT_ASSESSMENT_OWNER", h.do("PUT", path+"/"+a.ID, other, upd).code())

	// The CR moves it: a push about the new day.
	r = h.do("PUT", path+"/"+a.ID, cr, upd)
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	assert.Equal(t, "CSE 101: Class test moved to Thu 29 Oct", h.sent()["tok-other"].Title)
	// Only the topics change: no push.
	upd["topics"] = "Chapter 4 too"
	require.Equal(t, http.StatusOK, h.do("PUT", path+"/"+a.ID, mate, upd).Status)
	assert.Empty(t, h.sent())

	// Rules.
	bad := func(body map[string]any) string { return h.do("POST", path, mate, body).code() }
	assert.Equal(t, "VALIDATION_FAILED", bad(map[string]any{"kind": "exam", "courseCode": "X", "date": "2026-10-28"}))
	assert.Equal(t, "VALIDATION_FAILED", bad(map[string]any{"kind": "quiz", "courseCode": "X", "date": "2026-10-20"}), "past")
	assert.Equal(t, "VALIDATION_FAILED", bad(map[string]any{"kind": "quiz", "courseCode": "X", "date": "2026-10-28", "end": "10:00"}), "end without start")
	assert.Equal(t, "VALIDATION_FAILED", bad(map[string]any{"kind": "quiz", "courseCode": " ", "date": "2026-10-28"}))

	// An assignment due with no time: fine.
	r = h.do("POST", path, other, map[string]any{"kind": "assignment", "courseCode": "CSE 102", "date": "2026-10-30"})
	require.Equal(t, http.StatusCreated, r.Status, r.Raw)
	list = h.assessments(mate)
	require.Len(t, list, 2)
	assert.Equal(t, "2026-10-29", list[0].Date, "earliest first")
	assert.Nil(t, list[1].Start)

	// Delete: a "cancelled" push; non-members can't see or touch it.
	h.sent()
	require.Equal(t, http.StatusNoContent, h.do("DELETE", path+"/"+a.ID, cr, nil).Status)
	assert.Equal(t, "CSE 101: Class test cancelled", h.sent()["tok-other"].Title)
	outsider := h.signIn("outsider@test.ac.bd").Tokens.AccessToken
	assert.Equal(t, "GROUP_NOT_FOUND", h.do("POST", path, outsider, map[string]any{"kind": "quiz", "courseCode": "X", "date": "2026-10-28"}).code())

	// Kept for the record after the date passes; gone from the list a day later.
	h.advance(5 * 24 * time.Hour)
	assert.Empty(t, h.assessments(h.signIn("mate@test.ac.bd").Tokens.AccessToken))
	var n int
	require.NoError(t, h.app.DB.Pool.QueryRow(context.Background(), `SELECT count(*) FROM assessments`).Scan(&n))
	assert.Equal(t, 1, n)
}
