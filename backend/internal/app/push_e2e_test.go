package app

import (
	"context"
	"net/http"
	"sort"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/zamansheikh/campussaga/backend/internal/modules/push"
)

func (h *harness) register(token, device, platform, lang string) {
	h.t.Helper()
	r := h.do("POST", "/me/devices", token, map[string]string{"token": device, "platform": platform, "language": lang})
	require.Equal(h.t, http.StatusNoContent, r.Status, r.Raw)
}

// sent waits for background sends and returns them by token.
func (h *harness) sent() map[string]push.Notification {
	h.app.Push.Wait()
	out := map[string]push.Notification{}
	for _, n := range h.push.Take() {
		out[n.Token] = n
	}
	return out
}

func keys(m map[string]push.Notification) []string {
	out := make([]string, 0, len(m))
	for k := range m {
		out = append(out, k)
	}
	sort.Strings(out)
	return out
}

// The harness clock is Tuesday 27 October 2026, 15:00 in Dhaka.
func TestPushToClassmates(t *testing.T) {
	h := newHarness(t)
	cr := h.signIn("cr@test.ac.bd").Tokens.AccessToken
	mate := h.signIn("mate@test.ac.bd").Tokens.AccessToken
	other := h.signIn("other@test.ac.bd").Tokens.AccessToken
	stranger := h.signIn("stranger@test.ac.bd").Tokens.AccessToken
	g := h.createGroup(cr)
	for _, tok := range []string{mate, other} {
		require.Equal(t, http.StatusOK, h.do("POST", "/groups/join", tok, map[string]string{"code": g.JoinCode}).Status)
	}
	h.register(cr, "phone-cr", "android", "en")
	h.register(mate, "phone-mate", "android", "bn")
	h.register(other, "phone-other", "ios", "en")
	h.register(stranger, "phone-stranger", "android", "en")
	assert.Equal(t, "VALIDATION_FAILED", h.do("POST", "/me/devices", mate, map[string]string{"token": "x", "platform": "web"}).code())

	r := h.do("POST", "/groups/"+g.ID+"/slots", cr, slotBody("CSE311", 3, "09:00", "10:30"))
	require.Equal(t, http.StatusCreated, r.Status, r.Raw)
	var slot slotJSON
	r.into(t, &slot)
	assert.Empty(t, h.sent(), "editing the weekly routine sends nothing")

	// An announcement reaches classmates, not the CR or other students.
	require.Equal(t, http.StatusCreated, h.do("POST", "/groups/"+g.ID+"/announcements", cr, map[string]any{"body": "Bring a calculator tomorrow"}).Status)
	got := h.sent()
	assert.Equal(t, []string{"phone-mate", "phone-other"}, keys(got))
	assert.Equal(t, "CSE 61: New announcement", got["phone-other"].Title)
	assert.Equal(t, "CSE 61: নতুন ঘোষণা", got["phone-mate"].Title)
	assert.Equal(t, "Bring a calculator tomorrow", got["phone-mate"].Body)
	assert.Equal(t, map[string]string{"type": "announcement", "groupId": g.ID}, got["phone-mate"].Data)

	// A cancellation, in each phone's language.
	changes := "/groups/" + g.ID + "/changes"
	r = h.do("POST", changes, cr, map[string]any{"kind": "cancelled", "slotId": slot.ID, "date": "2026-10-28", "note": "Teacher is sick"})
	require.Equal(t, http.StatusCreated, r.Status, r.Raw)
	var cancel changeJSON
	r.into(t, &cancel)
	got = h.sent()
	assert.Equal(t, "CSE311 cancelled tomorrow", got["phone-other"].Title)
	assert.Equal(t, "Teacher is sick · CSE 61", got["phone-other"].Body)
	assert.Equal(t, "আগামীকাল CSE311 বাতিল", got["phone-mate"].Title)

	// Moved next week, with Bangla time and date.
	require.Equal(t, http.StatusCreated, h.do("POST", changes, cr, map[string]any{
		"kind": "moved", "slotId": slot.ID, "date": "2026-11-04", "start": "11:00", "end": "12:30", "room": "805",
	}).Status)
	got = h.sent()
	assert.Equal(t, "CSE311 changed on Wed 4 Nov", got["phone-other"].Title)
	assert.Equal(t, "11:00 AM – 12:30 PM · Room 805", got["phone-other"].Body)
	assert.Equal(t, "বুধ, ৪ নভেম্বর CSE311 পরিবর্তিত", got["phone-mate"].Title)
	assert.Equal(t, "১১:০০ AM – ১২:৩০ PM · রুম 805", got["phone-mate"].Body)

	// Undo says it's back on.
	require.Equal(t, http.StatusNoContent, h.do("DELETE", changes+"/"+cancel.ID, cr, nil).Status)
	assert.Equal(t, "CSE311 tomorrow is on again", h.sent()["phone-other"].Title)

	// A removed app: Firebase says the token is gone, so it's deleted.
	h.push.Gone = map[string]bool{"phone-other": true}
	require.Equal(t, http.StatusCreated, h.do("POST", "/groups/"+g.ID+"/announcements", cr, map[string]any{"body": "x"}).Status)
	assert.Equal(t, []string{"phone-mate"}, keys(h.sent()))
	var n int
	require.NoError(t, h.app.DB.Pool.QueryRow(context.Background(), `SELECT count(*) FROM device_tokens WHERE token = 'phone-other'`).Scan(&n))
	assert.Zero(t, n)

	// Signing out stops pushes to that phone; signing in as someone else
	// moves it.
	require.Equal(t, http.StatusNoContent, h.do("POST", "/auth/logout", mate, nil).Status)
	h.register(stranger, "phone-cr", "android", "en") // the CR's phone, now a stranger's
	require.Equal(t, http.StatusCreated, h.do("POST", "/groups/"+g.ID+"/announcements", cr, map[string]any{"body": "y"}).Status)
	assert.Empty(t, h.sent())
}
