package app

import (
	"context"
	"net/http"
	"net/url"
	"sort"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

type foundJSON struct {
	ID          string  `json:"id"`
	Title       string  `json:"title"`
	MemberCount int     `json:"memberCount"`
	CRName      *string `json:"crName"`
	IsMember    bool    `json:"isMember"`
	Courses     []struct {
		Key     string `json:"key"`
		Code    string `json:"code"`
		Teacher string `json:"teacher"`
	} `json:"courses"`
}

type searchJSON struct {
	Items []foundJSON `json:"items"`
	More  bool        `json:"more"`
}

func (h *harness) search(token, q string) searchJSON {
	h.t.Helper()
	r := h.do("GET", "/groups/search?q="+url.QueryEscape(q), token, nil)
	require.Equal(h.t, http.StatusOK, r.Status, r.Raw)
	var out searchJSON
	r.into(h.t, &out)
	return out
}

// hiddenIn returns the caller's hidden courses in the group (sorted).
func (h *harness) hiddenIn(token, groupID string) []string {
	h.t.Helper()
	r := h.do("GET", "/groups", token, nil)
	require.Equal(h.t, http.StatusOK, r.Status, r.Raw)
	var out struct {
		Groups []struct {
			ID     string   `json:"id"`
			Hidden []string `json:"hiddenCourses"`
		} `json:"groups"`
	}
	r.into(h.t, &out)
	for _, g := range out.Groups {
		if g.ID == groupID {
			sort.Strings(g.Hidden)
			return g.Hidden
		}
	}
	h.t.Fatalf("not a member of %s", groupID)
	return nil
}

func (h *harness) addSlot(token, groupID, code string, weekday int, start, end string) {
	h.t.Helper()
	r := h.do("POST", "/groups/"+groupID+"/slots", token, slotBody(code, weekday, start, end))
	require.Equal(h.t, http.StatusCreated, r.Status, r.Raw)
}

// The harness clock is Tuesday 27 October 2026, 15:00 in Dhaka.
func TestFindYourClass(t *testing.T) {
	h := newHarness(t)
	cr := h.named("cr@test.ac.bd", "Rafiul Islam")
	cse := h.createGroup(cr) // CSE 61
	h.addSlot(cr, cse.ID, "CSE 311", 2, "09:00", "10:30")
	h.addSlot(cr, cse.ID, "CSE313", 3, "11:00", "12:30")
	h.addSlot(cr, cse.ID, "MAT201", 4, "14:00", "15:30")

	cr2 := h.signIn("cr2@test.ac.bd").Tokens.AccessToken
	r := h.do("POST", "/groups", cr2, map[string]string{"department": "EEE", "batch": "55", "semester": "Fall 2026"})
	require.Equal(t, http.StatusCreated, r.Status, r.Raw)
	var eee groupJSON
	r.into(t, &eee)
	h.addSlot(cr2, eee.ID, "EEE201", 1, "09:00", "10:30")

	student := h.signIn("student@test.ac.bd").Tokens.AccessToken

	// Search by department + batch, a course code (either spelling) or teacher.
	got := h.search(student, "cse 61")
	require.Len(t, got.Items, 1)
	f := got.Items[0]
	assert.Equal(t, cse.ID, f.ID)
	assert.Equal(t, "CSE 61", f.Title)
	assert.Equal(t, 1, f.MemberCount)
	require.NotNil(t, f.CRName)
	assert.Equal(t, "Rafiul Islam", *f.CRName)
	assert.False(t, f.IsMember)
	keys := []string{}
	for _, c := range f.Courses {
		keys = append(keys, c.Key)
	}
	assert.ElementsMatch(t, []string{"CSE311", "CSE313", "MAT201"}, keys)
	assert.Len(t, h.search(student, "CSE311").Items, 1, "compact code")
	assert.Len(t, h.search(student, "cse 311").Items, 1, "spaced code")
	assert.Len(t, h.search(student, "rahman").Items, 2, "teacher")
	assert.Equal(t, eee.ID, h.search(student, "eee").Items[0].ID)
	assert.Empty(t, h.search(student, "physics").Items)
	assert.Len(t, h.search(student, "").Items, 2, "everything findable at my university")
	assert.Empty(t, h.search(student, "100%").Items, "% is literal")

	// Another university sees nothing and can't look or join.
	_, err := h.app.DB.Pool.Exec(context.Background(), `
		WITH u AS (INSERT INTO universities (slug, name) VALUES ('other-uni', 'Other University') RETURNING id)
		INSERT INTO university_domains (domain, university_id) SELECT 'other.ac.bd', id FROM u`)
	require.NoError(t, err)
	outsider := h.signIn("x@other.ac.bd").Tokens.AccessToken
	assert.Empty(t, h.search(outsider, "cse").Items)
	assert.Empty(t, h.search(outsider, cse.JoinCode).Items)
	assert.Equal(t, "GROUP_NOT_FOUND", h.do("GET", "/groups/"+cse.ID+"/routine-preview", outsider, nil).code())
	assert.Equal(t, "GROUP_NOT_FOUND", h.do("POST", "/groups/"+cse.ID+"/join-courses", outsider,
		map[string]any{"courses": []string{"CSE311"}}).code())

	// Preview: routine and courses, no members.
	r = h.do("GET", "/groups/"+cse.ID+"/routine-preview", student, nil)
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	var prev struct {
		foundJSON
		Slots []slotJSON `json:"slots"`
	}
	r.into(t, &prev)
	assert.Len(t, prev.Slots, 3)
	assert.NotContains(t, r.Raw, "cr@test.ac.bd", "no emails")

	// Join for one course only: the others are hidden, also ones added later.
	bad := func(courses ...string) string {
		return h.do("POST", "/groups/"+cse.ID+"/join-courses", student, map[string]any{"courses": courses}).code()
	}
	assert.Equal(t, "VALIDATION_FAILED", bad())
	assert.Equal(t, "VALIDATION_FAILED", bad("PHY101"))
	r = h.do("POST", "/groups/"+cse.ID+"/join-courses", student, map[string]any{"courses": []string{"cse 311"}})
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	assert.Equal(t, []string{"CSE313", "MAT201"}, h.hiddenIn(student, cse.ID))
	assert.True(t, h.search(student, "cse 61").Items[0].IsMember)

	full := h.signIn("full@test.ac.bd").Tokens.AccessToken
	require.Equal(t, http.StatusOK, h.do("POST", "/groups/join", full, map[string]string{"code": cse.JoinCode}).Status)

	h.addSlot(cr, cse.ID, "CSE399", 5, "09:00", "10:00")
	assert.Equal(t, []string{"CSE313", "CSE399", "MAT201"}, h.hiddenIn(student, cse.ID), "new course stays hidden")
	assert.Empty(t, h.hiddenIn(full, cse.ID), "whole-section members see it")
	h.addSlot(cr, cse.ID, "CSE 311", 4, "16:00", "17:00") // another CSE311 class
	assert.NotContains(t, h.hiddenIn(student, cse.ID), "CSE311", "a course they take stays shown")

	// Change of mind: all courses = the whole section again.
	r = h.do("POST", "/groups/"+cse.ID+"/join-courses", student, map[string]any{
		"courses": []string{"CSE311", "CSE313", "MAT201", "CSE399"}})
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	assert.Empty(t, h.hiddenIn(student, cse.ID))
	h.addSlot(cr, cse.ID, "CSE400", 6, "09:00", "10:00")
	assert.Empty(t, h.hiddenIn(student, cse.ID))

	// Code only: hidden from search and preview, still reachable with the code.
	r = h.do("PUT", "/groups/"+cse.ID, cr, map[string]any{
		"department": "CSE", "batch": "61", "semester": "Fall 2026", "discoverable": false})
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	var upd struct {
		Discoverable bool `json:"discoverable"`
	}
	r.into(t, &upd)
	assert.False(t, upd.Discoverable)
	assert.Equal(t, "NOT_GROUP_CR", h.do("PUT", "/groups/"+cse.ID, student, map[string]any{
		"department": "CSE", "batch": "61", "semester": "Fall 2026", "discoverable": true}).code())
	late := h.signIn("late@test.ac.bd").Tokens.AccessToken
	assert.Empty(t, h.search(late, "cse 61").Items)
	byCode := h.search(late, cse.JoinCode)
	require.Len(t, byCode.Items, 1, "an exact join code still finds it")
	assert.Equal(t, "GROUP_NOT_FOUND", h.do("GET", "/groups/"+cse.ID+"/routine-preview", late, nil).code())
	assert.Equal(t, http.StatusOK, h.do("GET", "/groups/"+cse.ID+"/routine-preview?code="+cse.JoinCode, late, nil).Status)
	r = h.do("POST", "/groups/"+cse.ID+"/join-courses", late, map[string]any{"courses": []string{"MAT201"}, "code": cse.JoinCode})
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	assert.Equal(t, http.StatusOK, h.do("GET", "/groups/"+cse.ID+"/routine-preview", student, nil).Status,
		"members still see it")
}

func TestSimilarGroupsAndLimits(t *testing.T) {
	h := newHarness(t)
	cr := h.signIn("cr@test.ac.bd").Tokens.AccessToken
	r := h.do("POST", "/groups", cr, map[string]string{"department": "CSE", "batch": "61", "section": "A", "semester": "Fall 2026"})
	require.Equal(t, http.StatusCreated, r.Status, r.Raw)
	var a groupJSON
	r.into(t, &a)
	h.addSlot(cr, a.ID, "CSE311", 2, "09:00", "10:30")

	other := h.signIn("other@test.ac.bd").Tokens.AccessToken
	similar := func(dept, batch, section string) []foundJSON {
		r := h.do("GET", "/groups/similar?department="+url.QueryEscape(dept)+"&batch="+batch+"&section="+section, other, nil)
		require.Equal(t, http.StatusOK, r.Status, r.Raw)
		var out struct {
			Items []foundJSON `json:"items"`
		}
		r.into(t, &out)
		return out.Items
	}
	require.Len(t, similar("cse", "61", "a"), 1, "case-insensitive")
	assert.Len(t, similar("CSE", "61", ""), 1)
	assert.Empty(t, similar("CSE", "61", "B"))
	assert.Empty(t, similar("CSE", "62", "A"))

	// A routine with no classes yet: join it whole, no courses picked.
	r = h.do("POST", "/groups", cr, map[string]string{"department": "CSE", "batch": "70", "semester": "Fall 2026"})
	require.Equal(t, http.StatusCreated, r.Status, r.Raw)
	var empty groupJSON
	r.into(t, &empty)
	early := h.signIn("early@test.ac.bd").Tokens.AccessToken
	assert.Equal(t, http.StatusOK, h.do("POST", "/groups/"+empty.ID+"/join-courses", early,
		map[string]any{"courses": []string{}}).Status)

	// Not-verified students without a university can't search.
	gmail, _ := h.gmailSignIn("nouni@gmail.com")
	assert.Equal(t, "UNIVERSITY_REQUIRED", h.do("GET", "/groups/search?q=cse", gmail, nil).code())

	// The group limit counts course-only joins too.
	for i := range 10 {
		r := h.do("POST", "/groups", other, map[string]string{"department": "X", "batch": string(rune('0' + i)), "semester": "Fall 2026"})
		require.Equal(t, http.StatusCreated, r.Status, r.Raw)
	}
	assert.Equal(t, "GROUP_LIMIT_REACHED", h.do("POST", "/groups/"+a.ID+"/join-courses", other,
		map[string]any{"courses": []string{"CSE311"}}).code())

	// Joining by courses is rate-limited per student.
	limited := h.signIn("limited@test.ac.bd").Tokens.AccessToken
	last := ""
	for range 61 {
		last = h.do("POST", "/groups/"+a.ID+"/join-courses", limited, map[string]any{"courses": []string{"CSE311"}}).code()
	}
	assert.Equal(t, "TOO_MANY_REQUESTS", last)
}
