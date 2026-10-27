package app

import (
	"context"
	"net/http"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

type changeJSON struct {
	ID         string  `json:"id"`
	Kind       string  `json:"kind"`
	SlotID     *string `json:"slotId"`
	Date       string  `json:"date"`
	CourseCode string  `json:"courseCode"`
	Room       string  `json:"room"`
	Start      *string `json:"start"`
	End        *string `json:"end"`
	Note       string  `json:"note"`
}

func (h *harness) changes(token string) []changeJSON {
	h.t.Helper()
	r := h.do("GET", "/groups", token, nil)
	require.Equal(h.t, http.StatusOK, r.Status, r.Raw)
	var out struct {
		Groups []struct {
			Changes []changeJSON `json:"changes"`
		} `json:"groups"`
	}
	r.into(h.t, &out)
	require.Len(h.t, out.Groups, 1)
	return out.Groups[0].Changes
}

// The harness clock is Tuesday 27 October 2026, 15:00 in Dhaka.
func TestRoutineChanges(t *testing.T) {
	h := newHarness(t)
	cr := h.signIn("cr@test.ac.bd").Tokens.AccessToken
	mate := h.signIn("mate@test.ac.bd").Tokens.AccessToken
	g := h.createGroup(cr)
	require.Equal(t, http.StatusOK, h.do("POST", "/groups/join", mate, map[string]string{"code": g.JoinCode}).Status)

	r := h.do("POST", "/groups/"+g.ID+"/slots", cr, slotBody("CSE311", 3, "09:00", "10:30")) // Wednesday
	require.Equal(t, http.StatusCreated, r.Status, r.Raw)
	var slot slotJSON
	r.into(t, &slot)
	changes := "/groups/" + g.ID + "/changes"
	body := func(kind, date string, extra map[string]any) map[string]any {
		b := map[string]any{"kind": kind, "date": date}
		if kind != "extra" {
			b["slotId"] = slot.ID
		}
		for k, v := range extra {
			b[k] = v
		}
		return b
	}

	// Cancel tomorrow's class, with a note; classmates see it.
	r = h.do("POST", changes, cr, body("cancelled", "2026-10-28", map[string]any{"note": " Teacher is sick "}))
	require.Equal(t, http.StatusCreated, r.Status, r.Raw)
	seen := h.changes(mate)
	require.Len(t, seen, 1)
	assert.Equal(t, "cancelled", seen[0].Kind)
	assert.Equal(t, "2026-10-28", seen[0].Date)
	assert.Equal(t, slot.ID, *seen[0].SlotID)
	assert.Equal(t, "Teacher is sick", seen[0].Note)
	assert.Nil(t, seen[0].Start)

	// Wrong dates are refused.
	assert.Equal(t, "VALIDATION_FAILED", h.do("POST", changes, cr, body("cancelled", "2026-10-29", nil)).code(), "not a Wednesday")
	assert.Equal(t, "VALIDATION_FAILED", h.do("POST", changes, cr, body("cancelled", "2026-10-21", nil)).code(), "in the past")
	assert.Equal(t, "VALIDATION_FAILED", h.do("POST", changes, cr, body("cancelled", "2027-10-27", nil)).code(), "too far")
	assert.Equal(t, "VALIDATION_FAILED", h.do("POST", changes, cr, body("cancelled", "28/10/2026", nil)).code())

	// Moved next week; then cancelled instead: one change per class per date.
	r = h.do("POST", changes, cr, body("moved", "2026-11-04", map[string]any{"start": "11:00", "end": "12:30", "room": "805"}))
	require.Equal(t, http.StatusCreated, r.Status, r.Raw)
	assert.Equal(t, "VALIDATION_FAILED", h.do("POST", changes, cr, body("moved", "2026-11-04", map[string]any{"start": "11:00", "end": "10:00"})).code())
	seen = h.changes(mate)
	require.Len(t, seen, 2)
	assert.Equal(t, "moved", seen[1].Kind)
	assert.Equal(t, "11:00", *seen[1].Start)
	assert.Equal(t, "805", seen[1].Room)
	require.Equal(t, http.StatusCreated, h.do("POST", changes, cr, body("cancelled", "2026-11-04", nil)).Status)
	seen = h.changes(mate)
	require.Len(t, seen, 2)
	assert.Equal(t, "cancelled", seen[1].Kind)

	// An extra class on Thursday.
	assert.Equal(t, "VALIDATION_FAILED", h.do("POST", changes, cr, body("extra", "2026-10-29", map[string]any{"start": "14:00", "end": "15:30"})).code(), "needs a course")
	assert.Equal(t, "VALIDATION_FAILED", h.do("POST", changes, cr, body("extra", "2026-10-29", map[string]any{"slotId": slot.ID, "courseCode": "CSE311", "start": "14:00", "end": "15:30"})).code())
	r = h.do("POST", changes, cr, body("extra", "2026-10-29", map[string]any{"courseCode": "CSE311", "start": "14:00", "end": "15:30", "room": "Lab 2"}))
	require.Equal(t, http.StatusCreated, r.Status, r.Raw)
	var extra changeJSON
	r.into(t, &extra)
	assert.Nil(t, extra.SlotID)
	assert.Equal(t, []string{"2026-10-28", "2026-10-29", "2026-11-04"}, dates(h.changes(mate)))

	// Only the CR changes the routine; undo works once.
	assert.Equal(t, "NOT_GROUP_CR", h.do("POST", changes, mate, body("cancelled", "2026-11-11", nil)).code())
	assert.Equal(t, "NOT_GROUP_CR", h.do("DELETE", changes+"/"+extra.ID, mate, nil).code())
	require.Equal(t, http.StatusNoContent, h.do("DELETE", changes+"/"+extra.ID, cr, nil).Status)
	assert.Equal(t, "CHANGE_NOT_FOUND", h.do("DELETE", changes+"/"+extra.ID, cr, nil).code())
	assert.Len(t, h.changes(mate), 2)

	// Changes before yesterday are no longer sent.
	_, err := h.app.DB.Pool.Exec(context.Background(), `
		INSERT INTO routine_changes (group_id, slot_id, date, kind) VALUES
		($1, $2, '2026-10-21', 'cancelled'), ($1, $2, '2026-10-26', 'cancelled')`, g.ID, slot.ID)
	require.NoError(t, err)
	assert.Equal(t, []string{"2026-10-26", "2026-10-28", "2026-11-04"}, dates(h.changes(mate)))

	// Moving the weekly class to another day drops its one-date changes.
	require.Equal(t, http.StatusOK, h.do("PUT", "/groups/"+g.ID+"/slots/"+slot.ID, cr, slotBody("CSE311", 4, "09:00", "10:30")).Status)
	assert.Empty(t, h.changes(mate))

	// Deleting the class removes its changes too (cascade).
	require.Equal(t, http.StatusCreated, h.do("POST", changes, cr, body("cancelled", "2026-10-29", nil)).Status)
	require.Equal(t, http.StatusNoContent, h.do("DELETE", "/groups/"+g.ID+"/slots/"+slot.ID, cr, nil).Status)
	assert.Empty(t, h.changes(mate))
}

func dates(cs []changeJSON) []string {
	out := make([]string, 0, len(cs))
	for _, c := range cs {
		out = append(out, c.Date)
	}
	return out
}
