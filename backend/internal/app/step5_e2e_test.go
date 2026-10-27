package app

import (
	"net/http"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

type memberJSON struct {
	UserID string `json:"userId"`
	Name   string `json:"name"`
	Role   string `json:"role"`
	IsMe   bool   `json:"isMe"`
}

func (h *harness) members(token, groupID string) []memberJSON {
	h.t.Helper()
	r := h.do("GET", "/groups/"+groupID+"/members", token, nil)
	require.Equal(h.t, http.StatusOK, r.Status, r.Raw)
	var out struct {
		Members []memberJSON `json:"members"`
	}
	r.into(h.t, &out)
	return out.Members
}

func (h *harness) named(email, name string) string {
	h.t.Helper()
	tok := h.signIn(email).Tokens.AccessToken
	require.Equal(h.t, http.StatusOK, h.do("PATCH", "/me", tok, map[string]string{"displayName": name}).Status)
	return tok
}

func TestCoCRsAndMembers(t *testing.T) {
	h := newHarness(t)
	cr := h.named("cr@test.ac.bd", "Rafiul Islam")
	mate := h.named("mate@test.ac.bd", "Nabila Rahman")
	third := h.named("third@test.ac.bd", "Tanvir Ahmed")
	fourth := h.named("fourth@test.ac.bd", "Sadia Khan")
	g := h.createGroup(cr)
	for _, tok := range []string{mate, third, fourth} {
		require.Equal(t, http.StatusOK, h.do("POST", "/groups/join", tok, map[string]string{"code": g.JoinCode}).Status)
	}

	// Only CRs see the member list: names and roles, never emails.
	assert.Equal(t, "NOT_GROUP_CR", h.do("GET", "/groups/"+g.ID+"/members", mate, nil).code())
	r := h.do("GET", "/groups/"+g.ID+"/members", cr, nil)
	assert.NotContains(t, r.Raw, "@test.ac.bd")
	ms := h.members(cr, g.ID)
	require.Len(t, ms, 4)
	assert.Equal(t, memberJSON{UserID: ms[0].UserID, Name: "Rafiul Islam", Role: "cr", IsMe: true}, ms[0])
	ids := map[string]string{}
	for _, m := range ms {
		ids[m.Name] = m.UserID
	}
	role := func(tok, user, role string) *response {
		return h.do("PUT", "/groups/"+g.ID+"/members/"+user, tok, map[string]string{"role": role})
	}

	// A co-CR can edit the routine; at most 3 CRs; never zero.
	require.Equal(t, http.StatusNoContent, role(cr, ids["Nabila Rahman"], "cr").Status)
	require.Equal(t, http.StatusCreated, h.do("POST", "/groups/"+g.ID+"/slots", mate, slotBody("CSE311", 2, "09:00", "10:00")).Status)
	require.Equal(t, http.StatusNoContent, role(mate, ids["Tanvir Ahmed"], "cr").Status)
	assert.Equal(t, "CR_LIMIT_REACHED", role(cr, ids["Sadia Khan"], "cr").code())
	require.Equal(t, http.StatusNoContent, role(third, ids["Tanvir Ahmed"], "member").Status, "stepping down")
	require.Equal(t, http.StatusNoContent, role(cr, ids["Nabila Rahman"], "member").Status)
	assert.Equal(t, "LAST_CR", role(cr, ids["Rafiul Islam"], "member").code())
	assert.Equal(t, "NOT_GROUP_CR", role(mate, ids["Sadia Khan"], "cr").code())
	assert.Equal(t, "VALIDATION_FAILED", role(cr, ids["Sadia Khan"], "admin").code())

	// Remove a student who shouldn't be there; CRs must step down first.
	require.Equal(t, http.StatusNoContent, h.do("DELETE", "/groups/"+g.ID+"/members/"+ids["Sadia Khan"], cr, nil).Status)
	assert.Empty(t, h.myGroups(fourth))
	assert.Equal(t, "MEMBER_NOT_FOUND", h.do("DELETE", "/groups/"+g.ID+"/members/"+ids["Sadia Khan"], cr, nil).code())
	require.Equal(t, http.StatusNoContent, role(cr, ids["Nabila Rahman"], "cr").Status)
	assert.Equal(t, "REMOVE_CR", h.do("DELETE", "/groups/"+g.ID+"/members/"+ids["Nabila Rahman"], cr, nil).code())

	// With a co-CR, the CR can leave.
	require.Equal(t, http.StatusNoContent, h.do("POST", "/groups/"+g.ID+"/leave", cr, nil).Status)
	assert.Equal(t, "cr", h.myGroups(mate)[0].Role)
}

func TestLastCRDeletingTheirAccountHandsTheGroupOn(t *testing.T) {
	h := newHarness(t)
	cr := h.named("cr@test.ac.bd", "Rafiul")
	first := h.named("first@test.ac.bd", "First")
	second := h.named("second@test.ac.bd", "Second")
	g := h.createGroup(cr)
	require.Equal(t, http.StatusOK, h.do("POST", "/groups/join", first, map[string]string{"code": g.JoinCode}).Status)
	h.advance(1)
	require.Equal(t, http.StatusOK, h.do("POST", "/groups/join", second, map[string]string{"code": g.JoinCode}).Status)

	require.Equal(t, http.StatusNoContent, h.do("DELETE", "/me", cr, nil).Status)
	assert.Equal(t, "cr", h.myGroups(first)[0].Role, "the longest member takes over")
	assert.Equal(t, "member", h.myGroups(second)[0].Role)
}

func TestHiddenCoursesAndNewSemester(t *testing.T) {
	h := newHarness(t)
	cr := h.signIn("cr@test.ac.bd").Tokens.AccessToken
	mate := h.signIn("mate@test.ac.bd").Tokens.AccessToken
	g := h.createGroup(cr)
	require.Equal(t, http.StatusOK, h.do("POST", "/groups/join", mate, map[string]string{"code": g.JoinCode}).Status)
	r := h.do("POST", "/groups/"+g.ID+"/slots", cr, slotBody("CSE311", 3, "09:00", "10:00"))
	require.Equal(t, http.StatusCreated, r.Status)
	var slot slotJSON
	r.into(t, &slot)
	require.Equal(t, http.StatusCreated, h.do("POST", "/groups/"+g.ID+"/changes", cr, map[string]any{"kind": "cancelled", "slotId": slot.ID, "date": "2026-10-28"}).Status)

	// A retake student hides the courses they don't take: only for them.
	r = h.do("PUT", "/groups/"+g.ID+"/hidden", mate, map[string]any{"courses": []string{"cse 311", " MAT201 ", ""}})
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	var out struct {
		HiddenCourses []string `json:"hiddenCourses"`
	}
	r.into(t, &out)
	assert.Equal(t, []string{"CSE311", "MAT201"}, out.HiddenCourses)
	var crView struct {
		Groups []struct {
			HiddenCourses []string `json:"hiddenCourses"`
		} `json:"groups"`
	}
	h.do("GET", "/groups", cr, nil).into(t, &crView)
	assert.Empty(t, crView.Groups[0].HiddenCourses)
	require.Equal(t, http.StatusOK, h.do("PUT", "/groups/"+g.ID+"/hidden", mate, map[string]any{"courses": []string{}}).Status)
	assert.Equal(t, "GROUP_NOT_FOUND", h.do("PUT", "/groups/"+g.ID+"/hidden", h.signIn("x@test.ac.bd").Tokens.AccessToken, map[string]any{"courses": []string{"A"}}).code())

	// New semester: routine and changes cleared, members and code kept.
	h.sent()
	h.register(mate, "phone-mate", "android", "en")
	assert.Equal(t, "NOT_GROUP_CR", h.do("POST", "/groups/"+g.ID+"/new-semester", mate, map[string]string{"semester": "Spring 2027"}).code())
	r = h.do("POST", "/groups/"+g.ID+"/new-semester", cr, map[string]string{"semester": " Spring  2027 "})
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	got := h.myGroups(mate)[0]
	assert.Equal(t, "Spring 2027", got.Semester)
	assert.Empty(t, got.Slots)
	assert.Equal(t, 2, got.MemberCount)
	assert.Equal(t, g.JoinCode, got.JoinCode)
	assert.Empty(t, h.changes(mate))
	assert.Equal(t, "CSE 61: Spring 2027 started", h.sent()["phone-mate"].Title)
}

func TestPersonalClasses(t *testing.T) {
	h := newHarness(t)
	me := h.signIn("me@test.ac.bd").Tokens.AccessToken
	other := h.signIn("other@test.ac.bd").Tokens.AccessToken
	body := map[string]any{"title": " Tuition ", "details": "Class 9 maths", "place": "Dhanmondi", "weekday": 6, "start": "17:00", "end": "18:30"}

	r := h.do("POST", "/me/classes", me, body)
	require.Equal(t, http.StatusCreated, r.Status, r.Raw)
	var p struct {
		ID    string `json:"id"`
		Title string `json:"title"`
		Start string `json:"start"`
	}
	r.into(t, &p)
	assert.Equal(t, "Tuition", p.Title)
	assert.Equal(t, "17:00", p.Start)
	assert.Equal(t, "VALIDATION_FAILED", h.do("POST", "/me/classes", me, map[string]any{"title": "x", "weekday": 1, "start": "10:00", "end": "09:00"}).code())

	list := func(tok string) []map[string]any {
		var out struct {
			Classes []map[string]any `json:"classes"`
		}
		h.do("GET", "/me/classes", tok, nil).into(t, &out)
		return out.Classes
	}
	require.Len(t, list(me), 1)
	assert.Empty(t, list(other), "only the owner sees them")

	body["place"] = "Mirpur"
	assert.Equal(t, "SLOT_NOT_FOUND", h.do("PUT", "/me/classes/"+p.ID, other, body).code())
	require.Equal(t, http.StatusOK, h.do("PUT", "/me/classes/"+p.ID, me, body).Status)
	assert.Equal(t, "Mirpur", list(me)[0]["place"])
	assert.Equal(t, "SLOT_NOT_FOUND", h.do("DELETE", "/me/classes/"+p.ID, other, nil).code())
	require.Equal(t, http.StatusNoContent, h.do("DELETE", "/me/classes/"+p.ID, me, nil).Status)
	assert.Empty(t, list(me))
}
