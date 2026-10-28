package app

import (
	"context"
	"net/http"
	"regexp"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

type groupJSON struct {
	ID          string     `json:"id"`
	Department  string     `json:"department"`
	Batch       string     `json:"batch"`
	Section     string     `json:"section"`
	Semester    string     `json:"semester"`
	JoinCode    string     `json:"joinCode"`
	Role        string     `json:"role"`
	MemberCount int        `json:"memberCount"`
	Slots       []slotJSON `json:"slots"`
}

type slotJSON struct {
	ID          string `json:"id"`
	CourseCode  string `json:"courseCode"`
	CourseTitle string `json:"courseTitle"`
	Teacher     string `json:"teacher"`
	Room        string `json:"room"`
	Weekday     int    `json:"weekday"`
	Start       string `json:"start"`
	End         string `json:"end"`
	Kind        string `json:"kind"`
}

func slotBody(code string, weekday int, start, end string) map[string]any {
	return map[string]any{
		"courseCode": code, "courseTitle": "Database Systems", "teacher": "Dr. Rahman",
		"room": "504", "weekday": weekday, "start": start, "end": end, "kind": "theory",
	}
}

func (h *harness) myGroups(token string) []groupJSON {
	h.t.Helper()
	r := h.do("GET", "/groups", token, nil)
	require.Equal(h.t, http.StatusOK, r.Status, r.Raw)
	var out struct {
		Groups []groupJSON `json:"groups"`
	}
	r.into(h.t, &out)
	return out.Groups
}

func TestClassGroupLifecycle(t *testing.T) {
	h := newHarness(t)
	cr := h.signIn("cr@test.ac.bd").Tokens.AccessToken
	mate := h.signIn("mate@test.ac.bd").Tokens.AccessToken

	// The CR creates the group; text is tidied.
	r := h.do("POST", "/groups", cr, map[string]string{
		"department": "  CSE ", "batch": "61", "section": "A", "semester": "Fall  2026",
	})
	require.Equal(t, http.StatusCreated, r.Status, r.Raw)
	var g groupJSON
	r.into(t, &g)
	assert.Regexp(t, regexp.MustCompile(`^[A-HJ-NP-Z]{6}$`), g.JoinCode)
	assert.Equal(t, "CSE", g.Department)
	assert.Equal(t, "Fall 2026", g.Semester)
	assert.Equal(t, "cr", g.Role)
	assert.Equal(t, 1, g.MemberCount)
	assert.Empty(t, g.Slots)

	// Routine entry, with validation.
	slots := "/groups/" + g.ID + "/slots"
	assert.Equal(t, "VALIDATION_FAILED", h.do("POST", slots, cr, slotBody("CSE311", 2, "10:00", "09:00")).code())
	assert.Equal(t, "VALIDATION_FAILED", h.do("POST", slots, cr, slotBody("CSE311", 2, "25:00", "26:00")).code())
	assert.Equal(t, "VALIDATION_FAILED", h.do("POST", slots, cr, slotBody("  ", 2, "09:00", "10:00")).code())
	assert.Equal(t, "VALIDATION_FAILED", h.do("POST", slots, cr, slotBody("CSE311", 8, "09:00", "10:00")).code())
	r = h.do("POST", slots, cr, slotBody("CSE313", 2, "11:30", "13:00"))
	require.Equal(t, http.StatusCreated, r.Status, r.Raw)
	r = h.do("POST", slots, cr, slotBody("CSE311", 2, "08:30", "10:00"))
	require.Equal(t, http.StatusCreated, r.Status, r.Raw)
	var first slotJSON
	r.into(t, &first)
	assert.Equal(t, "08:30", first.Start)

	// A classmate previews the code (any case), then joins.
	r = h.do("GET", "/groups/preview?code="+lower(g.JoinCode), mate, nil)
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	var p struct {
		Department  string `json:"department"`
		MemberCount int    `json:"memberCount"`
		ClassCount  int    `json:"classCount"`
		IsMember    bool   `json:"isMember"`
	}
	r.into(t, &p)
	assert.Equal(t, "CSE", p.Department)
	assert.Equal(t, 1, p.MemberCount)
	assert.Equal(t, 2, p.ClassCount)
	assert.False(t, p.IsMember)

	r = h.do("POST", "/groups/join", mate, map[string]string{"code": g.JoinCode})
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	var joined groupJSON
	r.into(t, &joined)
	assert.Equal(t, "member", joined.Role)
	assert.Equal(t, 2, joined.MemberCount)
	require.Len(t, joined.Slots, 2)
	assert.Equal(t, "CSE311", joined.Slots[0].CourseCode, "earliest class first")

	// Joining again is harmless.
	require.Equal(t, http.StatusOK, h.do("POST", "/groups/join", mate, map[string]string{"code": g.JoinCode}).Status)
	assert.Len(t, h.myGroups(mate), 1)

	// Only the CR edits.
	assert.Equal(t, "NOT_GROUP_CR", h.do("POST", slots, mate, slotBody("X1", 1, "09:00", "10:00")).code())
	assert.Equal(t, "NOT_GROUP_CR", h.do("DELETE", "/groups/"+g.ID, mate, nil).code())

	// Edit and delete a class; the classmate sees the change.
	r = h.do("PUT", slots+"/"+first.ID, cr, slotBody("CSE311", 3, "08:30", "10:00"))
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	mine := h.myGroups(mate)
	require.Len(t, mine[0].Slots, 2)
	assert.Equal(t, 3, mine[0].Slots[1].Weekday)
	require.Equal(t, http.StatusNoContent, h.do("DELETE", slots+"/"+first.ID, cr, nil).Status)
	assert.Equal(t, "SLOT_NOT_FOUND", h.do("DELETE", slots+"/"+first.ID, cr, nil).code())
	assert.Len(t, h.myGroups(mate)[0].Slots, 1)

	// Group details.
	r = h.do("PUT", "/groups/"+g.ID, cr, map[string]string{
		"department": "CSE", "batch": "61", "section": "B", "semester": "Fall 2026",
	})
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	assert.Equal(t, "B", h.myGroups(mate)[0].Section)

	// The only CR can't walk away from classmates; a member can leave.
	assert.Equal(t, "CR_CANNOT_LEAVE", h.do("POST", "/groups/"+g.ID+"/leave", cr, nil).code())
	require.Equal(t, http.StatusNoContent, h.do("POST", "/groups/"+g.ID+"/leave", mate, nil).Status)
	assert.Empty(t, h.myGroups(mate))
	assert.Equal(t, 1, h.myGroups(cr)[0].MemberCount)

	// The last member leaving deletes the group.
	require.Equal(t, http.StatusNoContent, h.do("POST", "/groups/"+g.ID+"/leave", cr, nil).Status)
	assert.Equal(t, "GROUP_NOT_FOUND", h.do("GET", "/groups/preview?code="+g.JoinCode, mate, nil).code())
}

func TestClassGroupDeleteRemovesItForEveryone(t *testing.T) {
	h := newHarness(t)
	cr := h.signIn("cr@test.ac.bd").Tokens.AccessToken
	mate := h.signIn("mate@test.ac.bd").Tokens.AccessToken
	g := h.createGroup(cr)
	require.Equal(t, http.StatusOK, h.do("POST", "/groups/join", mate, map[string]string{"code": g.JoinCode}).Status)

	require.Equal(t, http.StatusNoContent, h.do("DELETE", "/groups/"+g.ID, cr, nil).Status)
	assert.Empty(t, h.myGroups(mate))
	assert.Empty(t, h.myGroups(cr))
}

func TestClassGroupsArePrivate(t *testing.T) {
	h := newHarness(t)
	cr := h.signIn("cr@test.ac.bd").Tokens.AccessToken
	stranger := h.signIn("stranger@test.ac.bd").Tokens.AccessToken
	g := h.createGroup(cr)

	// Not a member: as if the group didn't exist.
	assert.Equal(t, "GROUP_NOT_FOUND", h.do("POST", "/groups/"+g.ID+"/slots", stranger, slotBody("X1", 1, "09:00", "10:00")).code())
	assert.Equal(t, "GROUP_NOT_FOUND", h.do("DELETE", "/groups/"+g.ID, stranger, nil).code())
	assert.Equal(t, "GROUP_NOT_FOUND", h.do("POST", "/groups/"+g.ID+"/leave", stranger, nil).code())
	assert.Equal(t, "VALIDATION_FAILED", h.do("DELETE", "/groups/not-a-uuid", stranger, nil).code())

	// A student of another university can't use the code.
	_, err := h.app.DB.Pool.Exec(context.Background(), `
		WITH u AS (INSERT INTO universities (slug, name) VALUES ('other-uni', 'Other University') RETURNING id)
		INSERT INTO university_domains (domain, university_id) SELECT 'other.ac.bd', id FROM u`)
	require.NoError(t, err)
	other := h.signIn("x@other.ac.bd").Tokens.AccessToken
	assert.Equal(t, "GROUP_NOT_FOUND", h.do("GET", "/groups/preview?code="+g.JoinCode, other, nil).code())
	assert.Equal(t, "GROUP_NOT_FOUND", h.do("POST", "/groups/join", other, map[string]string{"code": g.JoinCode}).code())

	// The join code is never in the URL path, and member lists are never sent.
	r := h.do("GET", "/groups", cr, nil)
	assert.NotContains(t, r.Raw, "cr@test.ac.bd")
	assert.Equal(t, "UNAUTHORIZED", h.do("GET", "/groups", "", nil).code())
}

func TestClassGroupCodesCantBeGuessed(t *testing.T) {
	h := newHarness(t)
	me := h.signIn("me@test.ac.bd").Tokens.AccessToken
	for range 30 {
		assert.Equal(t, "GROUP_NOT_FOUND", h.do("GET", "/groups/preview?code=ZZZZZZ", me, nil).code())
	}
	assert.Equal(t, "TOO_MANY_REQUESTS", h.do("POST", "/groups/join", me, map[string]string{"code": "ZZZZZZ"}).code())
	assert.Equal(t, "VALIDATION_FAILED", h.do("GET", "/groups/preview?code=AB12", h.signIn("you@test.ac.bd").Tokens.AccessToken, nil).code())
}

func (h *harness) createGroup(token string) groupJSON {
	h.t.Helper()
	r := h.do("POST", "/groups", token, map[string]string{"department": "CSE", "batch": "61", "semester": "Fall 2026"})
	require.Equal(h.t, http.StatusCreated, r.Status, r.Raw)
	var g groupJSON
	r.into(h.t, &g)
	return g
}

func lower(s string) string {
	b := []byte(s)
	for i, c := range b {
		if c >= 'A' && c <= 'Z' {
			b[i] = c + 32
		}
	}
	return string(b)
}

// A routine an admin published (kept when empty) stays when its last member
// leaves; it can be found and joined again.
func TestKeptGroupSurvivesLastLeave(t *testing.T) {
	h := newHarness(t)
	tok := h.signIn("pmscs@test.ac.bd").Tokens.AccessToken
	var id string
	require.NoError(t, h.app.DB.Pool.QueryRow(context.Background(), `
		INSERT INTO class_groups (university_id, department, batch, semester, join_code, keep_when_empty)
		VALUES ($1, 'CSE', 'PMSCS', 'Fall 2026', 'TJMSLP', true) RETURNING id::text`, h.universityID("test-uni")).Scan(&id))
	require.Equal(t, http.StatusOK, h.do("POST", "/groups/join", tok, map[string]string{"code": "TJMSLP"}).Status)
	require.Equal(t, http.StatusNoContent, h.do("POST", "/groups/"+id+"/leave", tok, nil).Status)
	r := h.do("POST", "/groups/join", tok, map[string]string{"code": "TJMSLP"})
	require.Equal(t, http.StatusOK, r.Status, "still there: "+r.Raw)
}
