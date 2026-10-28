package app

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"image"
	"image/png"
	"net/http"
	"os"
	"path/filepath"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/zamansheikh/varsitykotha/backend/internal/platform/media/mediatest"
)

// Test 7: the auto check holds personal info, bad language and posts by
// not-verified students; moderators approve or remove, and the author hears.
func TestVoiceAutoCheckAndModeration(t *testing.T) {
	h := newHarness(t)
	c := newVoiceCast(h)
	h.register(c.author, "tok-author", "android", "en")
	h.register(c.mate, "tok-mate", "android", "en")

	for body, reason := range map[string]string{
		"Call the caretaker at 01712345678 now":    "personal_info",
		"নম্বর ০১৭১২৩৪৫৬৭৮ এ ফোন দিন সবাই":         "personal_info",
		"Email the warden at warden.h3@gmail.com":  "personal_info",
		"The night guard is a bastard to everyone": "language",
	} {
		is := h.postIssue(c.author, issueBody("Problem in the hall office", map[string]any{"body": body}))
		assert.Equal(t, "held", is.Visibility, body)
		assert.Equal(t, reason, is.HoldReason, body)
		assert.Equal(t, "ISSUE_NOT_FOUND", h.do("GET", "/issues/"+is.ID, c.mate, nil).code(), "held: not public")
	}
	// A not-verified (Gmail) student's posts wait for a moderator.
	gmail, me := h.gmailSignIn("nabila.gmail@gmail.com")
	require.Equal(t, http.StatusOK, h.do("PUT", "/me/university", gmail, map[string]any{"universityId": h.universityID("test-uni")}).Status)
	_ = me
	held := h.postIssue(gmail, issueBody("Canteen food is cold every day"))
	assert.Equal(t, "unverified", held.HoldReason)
	cm := h.comment(gmail, c.authorIssue(h), map[string]any{"body": "Agreed"})
	assert.Equal(t, "held", cm.Visibility)

	// The moderation queue lists them, with no author.
	var q voicePage[struct {
		TargetType string `json:"targetType"`
		HoldReason string `json:"holdReason"`
		Issue      issueJSON
	}]
	r := h.do("GET", "/moderation/queue?kind=held", c.mod, nil)
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	r.into(t, &q)
	assert.Len(t, q.Items, 6) // 5 issues + 1 comment
	for _, it := range q.Items {
		assert.False(t, it.Issue.Mine)
	}
	assert.Equal(t, "FORBIDDEN", h.do("GET", "/moderation/queue?kind=held", c.mate, nil).code())
	assert.Equal(t, "FORBIDDEN", h.do("GET", "/moderation/queue?kind=held", c.authority, nil).code())

	// Approve: public, and the author hears (pushes go to the author only).
	h.sent()
	approve := h.do("POST", "/moderation/issues/"+held.ID, c.mod, map[string]string{"action": "approve"})
	require.Equal(t, http.StatusOK, approve.Status, approve.Raw)
	assert.Equal(t, held.ID, h.getIssue(c.mate, held.ID).ID)

	// Remove needs a reason, which the author sees.
	assert.Equal(t, "VALIDATION_FAILED", h.do("POST", "/moderation/issues/"+held.ID, c.mod, map[string]string{"action": "remove"}).code())
	mine := h.postIssue(c.mate, issueBody("Rude message about a teacher", map[string]any{"body": "The caretaker is a bastard and lazy"}))
	h.sent()
	r = h.do("POST", "/moderation/issues/"+mine.ID, c.mod, map[string]string{"action": "remove", "reason": "Insulting language"})
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	n := h.sent()["tok-mate"]
	assert.Equal(t, "Your issue was removed", n.Title)
	assert.Equal(t, "Insulting language", n.Body)
	got := h.getIssue(c.mate, mine.ID)
	assert.Equal(t, "removed", got.Visibility)
	assert.Equal(t, "Insulting language", got.RemovedReason)
	assert.Equal(t, "ISSUE_CLOSED", h.do("POST", "/issues/"+mine.ID+"/comments", c.mate, map[string]string{"body": "why"}).code())

	// Audit rows name the content, never the author.
	var audit struct {
		Items []struct {
			Action string          `json:"action"`
			Meta   json.RawMessage `json:"meta"`
		} `json:"items"`
	}
	h.do("GET", "/admin/audit", c.admin, nil).into(t, &audit)
	seen := map[string]bool{}
	for _, a := range audit.Items {
		seen[a.Action] = true
		assert.NotContains(t, string(a.Meta), c.authorID)
	}
	assert.True(t, seen["moderation.approve"] && seen["moderation.remove"])
}

// authorIssue: a visible issue by the cast's author (for comments).
func (c voiceCast) authorIssue(h *harness) string {
	return h.postIssue(c.author, issueBody("Broken water pump in Hall 3")).ID
}

// Test 8: reports.
func TestVoiceReports(t *testing.T) {
	h := newHarness(t)
	c := newVoiceCast(h)
	is := h.postIssue(c.author, issueBody("Broken water pump in Hall 3"))
	report := func(tok string) *response {
		return h.do("POST", "/issues/"+is.ID+"/report", tok, map[string]string{"reason": "false_info", "details": "Not true"})
	}
	require.Equal(t, http.StatusNoContent, report(c.mate).Status)
	assert.Equal(t, "ALREADY_REPORTED", report(c.mate).code())
	assert.Equal(t, "VALIDATION_FAILED", h.do("POST", "/issues/"+is.ID+"/report", c.mate, map[string]string{"reason": "boring"}).code())
	for i := range 4 {
		tok := h.signIn(fmt.Sprintf("reporter%d@test.ac.bd", i)).Tokens.AccessToken
		require.Equal(t, http.StatusNoContent, report(tok).Status)
	}
	// Five people: hidden until reviewed.
	assert.Equal(t, "ISSUE_NOT_FOUND", h.do("GET", "/issues/"+is.ID, c.mate, nil).code())
	assert.Equal(t, "hidden", h.getIssue(c.author, is.ID).Visibility)
	var mod struct {
		Reports []struct {
			Reason string `json:"reason"`
		} `json:"reports"`
		ReportCount int `json:"reportCount"`
	}
	h.do("GET", "/moderation/issues/"+is.ID, c.mod, nil).into(t, &mod)
	assert.Len(t, mod.Reports, 5)
	assert.Equal(t, 5, mod.ReportCount)

	// Dismissing the reports brings it back.
	require.Equal(t, http.StatusNoContent, h.do("POST", "/moderation/reports/dismiss", c.mod,
		map[string]string{"targetType": "issue", "targetId": is.ID}).Status)
	assert.Equal(t, "visible", h.getIssue(c.mod, is.ID).Visibility)
	assert.Equal(t, 0, h.getIssue(c.mod, is.ID).ReportCount)

	// Comments: the same rules.
	cm := h.comment(c.author, is.ID, map[string]any{"body": "Still broken"})
	for i := range 5 {
		tok := h.signIn(fmt.Sprintf("creporter%d@test.ac.bd", i)).Tokens.AccessToken
		require.Equal(t, http.StatusNoContent, h.do("POST", "/issues/"+is.ID+"/comments/"+cm.ID+"/report", tok,
			map[string]string{"reason": "spam"}).Status)
	}
	assert.Empty(t, h.comments(c.mate, is.ID), "hidden after 5 reports")
	assert.Equal(t, 0, h.getIssue(c.mate, is.ID).CommentCount)
}

// Test 9: bans.
func TestVoiceBans(t *testing.T) {
	h := newHarness(t)
	c := newVoiceCast(h)
	is := h.postIssue(c.author, issueBody("Broken water pump in Hall 3"))
	cm := h.comment(c.mate, is.ID, map[string]any{"body": "Spam spam spam"})
	r := h.do("POST", "/moderation/comments/"+cm.ID+"/ban-author", c.mod, map[string]any{"days": 7, "reason": "Spam"})
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	var ban struct {
		BannedUntil *time.Time `json:"bannedUntil"`
	}
	r.into(t, &ban)
	require.NotNil(t, ban.BannedUntil)

	// Writes refused, reading works.
	assert.Equal(t, "VOICE_BANNED", h.do("POST", "/issues", c.mate, issueBody("Another broken thing here")).code())
	assert.Equal(t, "VOICE_BANNED", h.do("POST", "/issues/"+is.ID+"/comments", c.mate, map[string]string{"body": "x"}).code())
	assert.Equal(t, "VOICE_BANNED", h.do("PUT", "/issues/"+is.ID+"/vote", c.mate, nil).code())
	assert.Equal(t, "VOICE_BANNED", h.do("POST", "/issues/"+is.ID+"/report", c.mate, map[string]string{"reason": "spam"}).code())
	assert.Equal(t, http.StatusOK, h.do("GET", "/issues/"+is.ID, c.mate, nil).Status)

	// Official replies can't be "banned".
	r = h.do("POST", "/issues/"+is.ID+"/official-replies", c.authority, map[string]string{"body": "We are on it"})
	var off voiceCommentJSON
	r.into(t, &off)
	assert.Equal(t, "CANNOT_BAN_OFFICIAL", h.do("POST", "/moderation/comments/"+off.ID+"/ban-author", c.mod,
		map[string]any{"reason": "x"}).code())

	// The ban ends after 7 days.
	h.advance(8 * 24 * time.Hour)
	mate := h.signIn("mate@test.ac.bd").Tokens.AccessToken
	assert.Equal(t, http.StatusCreated, h.do("POST", "/issues", mate, issueBody("Another broken thing here")).Status)

	// Permanent bans through an issue.
	author := h.signIn(c.authorEmail).Tokens.AccessToken
	mod := h.signIn("mod@test.ac.bd").Tokens.AccessToken
	require.Equal(t, http.StatusOK, h.do("POST", "/moderation/issues/"+is.ID+"/ban-author", mod, map[string]any{"reason": "Repeated abuse"}).Status)
	assert.Equal(t, "VOICE_BANNED", h.do("POST", "/issues", author, issueBody("Yet another broken thing")).code())
}

// Test 10: photos.
func TestVoicePhotos(t *testing.T) {
	h := newHarness(t)
	c := newVoiceCast(h)

	photo := mediatest.JPEGWithExif(t, 800, 600, 1)
	require.True(t, bytes.Contains(photo, []byte("GPS")))
	r := h.upload(c.author, photo)
	require.Equal(t, http.StatusCreated, r.Status, r.Raw)
	var up struct {
		ID     string `json:"id"`
		Width  int    `json:"width"`
		Height int    `json:"height"`
	}
	r.into(t, &up)
	assert.Equal(t, 800, up.Width)

	// Stored files carry no metadata, no file name.
	files, err := os.ReadDir(h.media.Dir)
	require.NoError(t, err)
	require.Len(t, files, 2)
	for _, f := range files {
		b, err := os.ReadFile(filepath.Join(h.media.Dir, f.Name()))
		require.NoError(t, err)
		assert.False(t, bytes.Contains(b, []byte("Exif")), f.Name())
		assert.False(t, bytes.Contains(b, []byte("GPS")), f.Name())
		assert.NotContains(t, f.Name(), "IMG_")
	}

	// Before it's attached: only its uploader can see it.
	status, _ := h.raw(c.author, "/uploads/"+up.ID+"?size=thumb")
	assert.Equal(t, http.StatusOK, status)
	status, _ = h.raw(c.mate, "/uploads/"+up.ID)
	assert.Equal(t, http.StatusNotFound, status)
	assert.Equal(t, "UPLOAD_NOT_FOUND", h.do("POST", "/issues", c.mate, issueBody("Broken water pump in Hall 3",
		map[string]any{"imageIds": []string{up.ID}})).code(), "someone else's upload")

	// Attached to a safety issue: its privacy rules apply to the photo.
	is := h.postIssue(c.author, issueBody("Someone follows students at night",
		map[string]any{"category": "safety", "imageIds": []string{up.ID}}))
	require.Len(t, is.Images, 1)
	img := "/issues/images/" + is.Images[0].ID
	status, body := h.raw(c.author, img)
	assert.Equal(t, http.StatusOK, status)
	_, _, err = image.DecodeConfig(bytes.NewReader(body))
	assert.NoError(t, err)
	status, _ = h.raw(c.mate, img)
	assert.Equal(t, http.StatusNotFound, status, "a classmate can't see a private issue's photo")
	status, _ = h.raw(c.authority, img+"?size=thumb")
	assert.Equal(t, http.StatusOK, status)
	assert.Equal(t, "UPLOAD_NOT_FOUND", h.do("POST", "/issues", c.author, issueBody("Broken water pump in Hall 3",
		map[string]any{"imageIds": []string{up.ID}})).code(), "already attached")

	// Refused: not an image, too large.
	assert.Equal(t, "IMAGE_INVALID", h.upload(c.author, []byte("hello, not an image")).code())
	var big bytes.Buffer
	require.NoError(t, png.Encode(&big, image.NewGray(image.Rect(0, 0, 8001, 2))))
	assert.Equal(t, "IMAGE_TOO_LARGE", h.upload(c.author, big.Bytes()).code())
	assert.Equal(t, "IMAGE_TOO_LARGE", h.upload(c.author, make([]byte, 9<<20)).code())

	// Unattached uploads are deleted after a day.
	r = h.upload(c.author, photo)
	require.Equal(t, http.StatusCreated, r.Status)
	h.advance(25 * time.Hour)
	require.NoError(t, h.app.Voice.Cleanup(context.Background()))
	files, err = os.ReadDir(h.media.Dir)
	require.NoError(t, err)
	assert.Len(t, files, 2, "only the attached photo's two files are left")
}

// Staff management, moderator sign-in to the panel, dashboard numbers.
func TestVoiceStaffAndPanel(t *testing.T) {
	h := newHarness(t)
	c := newVoiceCast(h)
	var list struct {
		Items []struct {
			User struct {
				Email string `json:"email"`
			} `json:"user"`
			Kind  string `json:"kind"`
			Title string `json:"title"`
		} `json:"items"`
	}
	h.do("GET", "/admin/staff", c.admin, nil).into(t, &list)
	require.Len(t, list.Items, 2)

	adminID := h.me(c.admin).ID
	assert.Equal(t, "CANNOT_CHANGE_SELF", h.do("POST", "/admin/staff", c.admin, map[string]any{"userId": adminID, "kind": "moderator"}).code())
	other := h.makeAdmin("admin2@test.ac.bd")
	assert.Equal(t, "ROLE_CONFLICT", h.do("POST", "/admin/staff", c.admin, map[string]any{"userId": h.me(other).ID, "kind": "moderator"}).code())
	assert.Equal(t, "VALIDATION_FAILED", h.do("POST", "/admin/staff", c.admin, map[string]any{"userId": h.me(c.mate).ID, "kind": "authority"}).code(),
		"an authority needs a university and a title")

	// Moderators may sign in to the panel, but only moderation routes work.
	r := h.do("POST", "/admin/auth/code", "", map[string]string{"email": "mod@test.ac.bd"})
	require.Equal(t, http.StatusAccepted, r.Status)
	r = h.do("POST", "/admin/auth/verify", "", map[string]string{"email": "mod@test.ac.bd", "code": h.lastCode("mod@test.ac.bd")})
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	var s signedIn
	r.into(t, &s)
	assert.Equal(t, "NOT_ADMIN", h.do("GET", "/admin/stats", s.Tokens.AccessToken, nil).code())
	assert.Equal(t, http.StatusOK, h.do("GET", "/moderation/queue?kind=held", s.Tokens.AccessToken, nil).Status)

	// Removing staff puts the role back.
	require.Equal(t, http.StatusNoContent, h.do("DELETE", "/admin/staff/"+c.authorityID, c.admin, nil).Status)
	assert.Equal(t, "FORBIDDEN", h.do("POST", "/issues/"+c.authorIssue(h)+"/status", c.authority, map[string]string{"to": "solved"}).code())

	// Dashboard numbers.
	h.postIssue(c.author, issueBody("Problem in the hall office", map[string]any{"body": "Call 01712345678 for the key please"}))
	var stats struct {
		Voice struct {
			Open, Held, IssuesLast7Days int
		} `json:"voice"`
	}
	h.do("GET", "/admin/stats", c.admin, nil).into(t, &stats)
	assert.Equal(t, 2, stats.Voice.Open)
	assert.Equal(t, 1, stats.Voice.Held)
	assert.Equal(t, 2, stats.Voice.IssuesLast7Days)
}
