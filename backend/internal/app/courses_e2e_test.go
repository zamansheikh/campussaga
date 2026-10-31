package app

import (
	"net/http"
	"net/url"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

type courseInfoJSON struct {
	CourseKey     string `json:"courseKey"`
	ChatLink      string `json:"chatLink"`
	ClassroomCode string `json:"classroomCode"`
	MaterialsLink string `json:"materialsLink"`
	TeacherEmail  string `json:"teacherEmail"`
	Notes         string `json:"notes"`
}

func (h *harness) courseInfos(token string) []courseInfoJSON {
	h.t.Helper()
	r := h.do("GET", "/groups", token, nil)
	require.Equal(h.t, http.StatusOK, r.Status, r.Raw)
	var out struct {
		Groups []struct {
			Courses []courseInfoJSON `json:"courses"`
		} `json:"groups"`
	}
	r.into(h.t, &out)
	require.Len(h.t, out.Groups, 1)
	return out.Groups[0].Courses
}

func TestCourseInfo(t *testing.T) {
	h := newHarness(t)
	cr := h.signIn("cr@test.ac.bd").Tokens.AccessToken
	mate := h.signIn("mate@test.ac.bd").Tokens.AccessToken
	g := h.createGroup(cr)
	require.Equal(t, http.StatusOK, h.do("POST", "/groups/join", mate, map[string]string{"code": g.JoinCode}).Status)
	h.addSlot(cr, g.ID, "CSE 311", 1, "09:00", "10:30")
	path := "/groups/" + g.ID + "/courses/" + url.PathEscape("cse 311")
	assert.Empty(t, h.courseInfos(mate), "nothing added yet")

	// The CR adds the extras; links get https://, the email is lower-cased.
	r := h.do("PUT", path, cr, map[string]any{
		"chatLink":      "chat.whatsapp.com/AbC123",
		"classroomCode": " ab3x9kq ",
		"materialsLink": "https://drive.google.com/drive/folders/xyz",
		"teacherEmail":  " Samih@JU.ac.bd ",
		"notes":         "Office hours: Sun 2-3 PM, Room 405  \n\n\n bring the lab manual",
	})
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	got := h.courseInfos(mate)
	require.Len(t, got, 1)
	assert.Equal(t, courseInfoJSON{
		CourseKey:     "CSE311",
		ChatLink:      "https://chat.whatsapp.com/AbC123",
		ClassroomCode: "ab3x9kq",
		MaterialsLink: "https://drive.google.com/drive/folders/xyz",
		TeacherEmail:  "samih@ju.ac.bd",
		Notes:         "Office hours: Sun 2-3 PM, Room 405\n\nbring the lab manual",
	}, got[0])

	// Checks.
	r = h.do("PUT", path, cr, map[string]any{"chatLink": "not a link", "teacherEmail": "nope", "classroomCode": "a b"})
	assert.Equal(t, "VALIDATION_FAILED", r.code())
	assert.Contains(t, r.Raw, "chatLink")
	assert.Contains(t, r.Raw, "teacherEmail")
	assert.Contains(t, r.Raw, "classroomCode")
	assert.Equal(t, "VALIDATION_FAILED",
		h.do("PUT", "/groups/"+g.ID+"/courses/EEE101", cr, map[string]any{"chatLink": "t.me/x"}).code(),
		"not in the routine")
	assert.Equal(t, "NOT_GROUP_CR", h.do("PUT", path, mate, map[string]any{"chatLink": "t.me/x"}).code())

	// All empty removes it.
	require.Equal(t, http.StatusOK, h.do("PUT", path, cr, map[string]any{}).Status)
	assert.Empty(t, h.courseInfos(mate))

	// A new semester clears the extras with the routine.
	require.Equal(t, http.StatusOK, h.do("PUT", path, cr, map[string]any{"classroomCode": "abc1234"}).Status)
	require.Len(t, h.courseInfos(mate), 1)
	r = h.do("POST", "/groups/"+g.ID+"/new-semester", cr, map[string]any{"semester": "Spring 2027"})
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	assert.Empty(t, h.courseInfos(mate))
}
