package app

import (
	"net/http"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// Test 5: safety issues are private to the author, the university's
// authorities and moderators.
func TestVoicePrivateSafetyIssues(t *testing.T) {
	h := newHarness(t)
	c := newVoiceCast(h)
	r := h.do("POST", "/admin/universities", c.admin, map[string]any{"slug": "other-uni", "name": "Other University", "domains": []string{"other.ac.bd"}})
	require.Equal(t, http.StatusCreated, r.Status, r.Raw)
	var other struct {
		ID string `json:"id"`
	}
	r.into(t, &other)
	outsiderTok := h.signIn("official@other.ac.bd").Tokens.AccessToken
	outsiderID := h.me(outsiderTok).ID
	require.Equal(t, http.StatusCreated, h.do("POST", "/admin/staff", c.admin, map[string]any{
		"userId": outsiderID, "kind": "authority", "universityId": other.ID, "title": "Other Proctor"}).Status)
	outsider := h.signIn("official@other.ac.bd").Tokens.AccessToken

	safety := h.postIssue(c.author, issueBody("Someone follows students at night", map[string]any{"category": "safety"}))
	assert.True(t, safety.Private)
	pub := h.postIssue(c.author, issueBody("Broken water pump in Hall 3"))

	// Not for classmates, nor other universities' officials.
	assert.Equal(t, "ISSUE_NOT_FOUND", h.do("GET", "/issues/"+safety.ID, c.mate, nil).code())
	assert.Equal(t, "ISSUE_NOT_FOUND", h.do("GET", "/issues/"+safety.ID, outsider, nil).code())
	assert.Equal(t, "ISSUE_NOT_FOUND", h.do("GET", "/issues/"+pub.ID, outsider, nil).code(), "other university")
	for _, it := range h.feed(c.mate, "?sort=new") {
		assert.NotEqual(t, safety.ID, it.ID)
	}
	for _, it := range h.feed(c.mate, "?sort=new&private=true") {
		assert.NotEqual(t, safety.ID, it.ID, "students can't ask for private ones")
	}
	// The university's authority, moderators and the author do see it.
	got := h.feed(c.authority, "?sort=new&private=true")
	require.Len(t, got, 1)
	assert.Equal(t, safety.ID, got[0].ID)
	assert.Equal(t, safety.ID, h.getIssue(c.authority, safety.ID).ID)
	assert.Equal(t, safety.ID, h.getIssue(c.mod, safety.ID).ID)
	assert.True(t, h.getIssue(c.author, safety.ID).Mine)
	// Its photos follow the same rule (checked in the image test).
}

// Test 6: statuses, roles, reopen and edit windows, counts and pushes.
func TestVoiceStatusesAndCounts(t *testing.T) {
	h := newHarness(t)
	c := newVoiceCast(h)
	h.register(c.author, "tok-author", "android", "en")
	h.register(c.mate, "tok-mate", "android", "bn")

	is := h.postIssue(c.author, issueBody("Broken water pump in Hall 3"))
	assert.Equal(t, "open", is.Status)
	assert.True(t, is.Can["edit"] && is.Can["delete"])
	assert.Empty(t, h.sent(), "no push when an issue is posted")

	// Me too: not on your own; counts and "voted"; voting follows.
	assert.Equal(t, "CANNOT_VOTE_OWN", h.do("PUT", "/issues/"+is.ID+"/vote", c.author, nil).code())
	r := h.do("PUT", "/issues/"+is.ID+"/vote", c.mate, nil)
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	require.Equal(t, http.StatusOK, h.do("PUT", "/issues/"+is.ID+"/vote", c.mate, nil).Status, "idempotent")
	got := h.getIssue(c.mate, is.ID)
	assert.Equal(t, 1, got.MeTooCount)
	assert.True(t, got.Voted && got.Following)

	// Comments: count and a push to the author (once per 15 minutes).
	h.comment(c.mate, is.ID, map[string]any{"body": "Same on the 2nd floor"})
	sent := h.sent()
	assert.Equal(t, "New comment on your issue", sent["tok-author"].Title)
	assert.Equal(t, "issue_comment", sent["tok-author"].Data["type"])
	assert.NotContains(t, sent, "tok-mate", "not to the commenter")
	second := h.comment(c.mate, is.ID, map[string]any{"body": "And the 1st floor"})
	assert.Empty(t, h.sent(), "throttled")
	assert.Equal(t, 2, h.getIssue(c.mate, is.ID).CommentCount)
	require.Equal(t, http.StatusNoContent, h.do("DELETE", "/issues/"+is.ID+"/comments/"+second.ID, c.mate, nil).Status)
	assert.Equal(t, 1, h.getIssue(c.mate, is.ID).CommentCount)
	assert.Equal(t, "COMMENT_NOT_FOUND", h.do("DELETE", "/issues/"+is.ID+"/comments/"+second.ID, c.author, nil).code())

	// Status: authority only, along the allowed steps.
	status := func(tok, to, note string) *response {
		return h.do("POST", "/issues/"+is.ID+"/status", tok, map[string]string{"to": to, "note": note})
	}
	assert.Equal(t, "FORBIDDEN", status(c.mate, "acknowledged", "").code())
	r = status(c.authority, "in_progress", "Plumber called")
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	r.into(t, &got)
	require.Len(t, got.Timeline, 1)
	assert.Equal(t, "Proctor Office", got.Timeline[0].ActorTitle)
	sent = h.sent()
	assert.Equal(t, "Issue update: In progress", sent["tok-author"].Title)
	assert.Equal(t, "ইস্যু আপডেট: কাজ চলছে", sent["tok-mate"].Title, "voters follow")
	assert.Equal(t, "STATUS_CHANGE_INVALID", status(c.authority, "acknowledged", "").code())
	assert.Equal(t, "NOTE_REQUIRED", status(c.authority, "rejected", "").code())

	// Official reply: public, with the office's title.
	r = h.do("POST", "/issues/"+is.ID+"/official-replies", c.authority, map[string]string{"body": "Fixed by Friday."})
	require.Equal(t, http.StatusCreated, r.Status, r.Raw)
	var off voiceCommentJSON
	r.into(t, &off)
	assert.Equal(t, "official", off.Kind)
	assert.Equal(t, "Proctor Office", off.OfficialTitle)
	require.NotNil(t, off.Author)
	assert.Equal(t, "Dr. Proctor", *off.Author.Name)
	assert.Equal(t, "Official reply from Proctor Office", h.sent()["tok-author"].Title)

	// Solved, then the author reopens within 30 days.
	h.advance(time.Minute)
	require.Equal(t, http.StatusOK, status(c.authority, "solved", "Done").Status)
	h.advance(time.Minute)
	h.sent()
	assert.True(t, h.getIssue(c.author, is.ID).Can["reopen"])
	assert.Equal(t, "ISSUE_NOT_FOUND", h.do("POST", "/issues/"+is.ID+"/reopen", c.mate, map[string]string{"note": "no"}).code())
	r = h.do("POST", "/issues/"+is.ID+"/reopen", c.author, map[string]string{"note": "Broken again"})
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	r.into(t, &got)
	assert.Equal(t, "open", got.Status)
	assert.Equal(t, "author", got.Timeline[len(got.Timeline)-1].ActorKind)
	require.Equal(t, http.StatusOK, status(c.authority, "solved", "").Status)
	h.advance(31 * 24 * time.Hour)
	author := h.signIn(c.authorEmail).Tokens.AccessToken
	assert.Equal(t, "REOPEN_NOT_ALLOWED", h.do("POST", "/issues/"+is.ID+"/reopen", author, map[string]string{"note": "again"}).code())

	// Edit window: 60 minutes.
	fresh := h.postIssue(author, issueBody("Lift in Block B is stuck"))
	r = h.do("PATCH", "/issues/"+fresh.ID, author, map[string]string{"title": "Lift in Block B stuck again"})
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	h.advance(61 * time.Minute)
	author = h.signIn(c.authorEmail).Tokens.AccessToken
	assert.Equal(t, "EDIT_WINDOW_CLOSED", h.do("PATCH", "/issues/"+fresh.ID, author, map[string]string{"title": "Too late to edit this"}).code())

	// Feed sorts and the solved list.
	mate := h.signIn("mate@test.ac.bd").Tokens.AccessToken
	assert.NotEmpty(t, h.feed(mate, "?sort=new"))
	solved := h.feed(mate, "?sort=solved")
	require.Len(t, solved, 1)
	assert.Equal(t, is.ID, solved[0].ID)
	for _, it := range h.feed(mate, "") {
		assert.NotEqual(t, is.ID, it.ID, "trending leaves out solved issues")
	}
	assert.Len(t, h.feed(mate, "?q=lift"), 1)
	assert.Equal(t, "BAD_CURSOR", h.do("GET", "/issues?sort=new&cursor=nope", mate, nil).code())

	// My issues: the author's own, newest first.
	var mine voicePage[issueJSON]
	h.do("GET", "/me/issues", author, nil).into(t, &mine)
	require.Len(t, mine.Items, 2)
	assert.Equal(t, fresh.ID, mine.Items[0].ID)
	var none voicePage[issueJSON]
	h.do("GET", "/me/issues", mate, nil).into(t, &none)
	assert.Empty(t, none.Items)
}

// Similar issues before posting.
func TestVoiceSimilar(t *testing.T) {
	h := newHarness(t)
	c := newVoiceCast(h)
	is := h.postIssue(c.author, issueBody("Water pump broken in Hall 3"))
	r := h.do("GET", "/issues/similar?q=Hall+3+water+pump+broken", c.mate, nil)
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	var out struct {
		Items []issueJSON `json:"items"`
	}
	r.into(t, &out)
	require.Len(t, out.Items, 1)
	assert.Equal(t, is.ID, out.Items[0].ID)
	assert.Equal(t, "VALIDATION_FAILED", h.do("GET", "/issues/similar?q=short", c.mate, nil).code())
}

// Test 11: the feature flag.
func TestVoiceFeatureFlag(t *testing.T) {
	h := newHarness(t)
	c := newVoiceCast(h)
	h.voiceOn(false)
	assert.Equal(t, "FEATURE_DISABLED", h.do("GET", "/issues", c.mate, nil).code())
	assert.Equal(t, "FEATURE_DISABLED", h.do("POST", "/issues", c.mate, issueBody("Broken water pump in Hall 3")).code())
	// Staff can seed and test while it's off.
	assert.Equal(t, http.StatusOK, h.do("GET", "/issues", c.authority, nil).Status)
	assert.Equal(t, http.StatusOK, h.do("GET", "/moderation/queue?kind=held", c.mod, nil).Status)
	// Students with no university yet.
	h.voiceOn(true)
	gmail, _ := h.gmailSignIn("nouni@gmail.com")
	assert.Equal(t, "UNIVERSITY_REQUIRED", h.do("GET", "/issues", gmail, nil).code())
	assert.Equal(t, "UNAUTHORIZED", h.do("GET", "/issues", "", nil).code())
}
