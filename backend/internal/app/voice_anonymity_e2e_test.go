package app

import (
	"net/http"
	"strings"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// voiceCast: a university with an author, a classmate, an authority, a
// moderator and an admin, Campus Voice on.
type voiceCast struct {
	authorID, authorEmail, authorName   string
	author, mate, authority, mod, admin string
	authorityID                         string
}

func newVoiceCast(h *harness) voiceCast {
	h.t.Helper()
	var c voiceCast
	c.admin = h.makeAdmin("admin@test.ac.bd")
	c.authorEmail, c.authorName = "alpha.author@test.ac.bd", "Alpha Unique Author"
	c.author = h.named(c.authorEmail, c.authorName)
	c.authorID = h.me(c.author).ID
	c.mate = h.named("mate@test.ac.bd", "Mate Student")
	c.authority = h.named("proctor@test.ac.bd", "Dr. Proctor")
	c.authorityID = h.me(c.authority).ID
	modTok := h.named("mod@test.ac.bd", "Mod Erator")
	h.addStaff(c.admin, c.authorityID, "authority", "Proctor Office")
	h.addStaff(c.admin, h.me(modTok).ID, "moderator", "")
	c.mod = h.signIn("mod@test.ac.bd").Tokens.AccessToken // the role is read per request; a fresh token is fine too
	c.authority = h.signIn("proctor@test.ac.bd").Tokens.AccessToken
	h.voiceOn(true)
	return c
}

// Test 1 (the release gate) and 12: no read endpoint, for any role, ever
// shows who wrote anonymous content; audit rows don't either.
func TestVoiceAnonymitySweep(t *testing.T) {
	h := newHarness(t)
	c := newVoiceCast(h)
	h.advance(3 * 60e9)

	pub := h.postIssue(c.author, issueBody("Broken water pump in Hall 3"))
	safety := h.postIssue(c.author, issueBody("Someone follows students at night", map[string]any{"category": "safety"}))
	authorComment := h.comment(c.author, pub.ID, map[string]any{"body": "Still broken today."})
	mateComment := h.comment(c.mate, pub.ID, map[string]any{"body": "Same on the 2nd floor."})
	require.Equal(t, http.StatusOK, h.do("PUT", "/issues/"+pub.ID+"/vote", c.mate, nil).Status)
	require.Equal(t, http.StatusNoContent, h.do("POST", "/issues/"+pub.ID+"/report", c.mate, map[string]string{"reason": "other"}).Status)
	require.Equal(t, http.StatusNoContent, h.do("POST", "/issues/"+pub.ID+"/comments/"+authorComment.ID+"/report", c.mate,
		map[string]string{"reason": "spam"}).Status)
	require.Equal(t, http.StatusOK, h.do("POST", "/issues/"+pub.ID+"/status", c.authority,
		map[string]string{"to": "acknowledged", "note": "We are on it"}).Status)
	require.Equal(t, http.StatusCreated, h.do("POST", "/issues/"+pub.ID+"/official-replies", c.authority,
		map[string]string{"body": "A plumber comes on Thursday."}).Status)
	require.Equal(t, http.StatusOK, h.do("POST", "/moderation/comments/"+mateComment.ID, c.mod,
		map[string]string{"action": "hide"}).Status)
	require.Equal(t, http.StatusOK, h.do("POST", "/moderation/comments/"+mateComment.ID, c.mod,
		map[string]string{"action": "restore"}).Status)

	// Campus social: posts, reactions, poll votes, replies and comment likes
	// are anonymous too, for the author and for the voter.
	mateID := h.me(c.mate).ID
	forbidden := func(t *testing.T, body string) {
		t.Helper()
		for _, s := range []string{c.authorID, c.authorEmail, c.authorName, "alpha.author", mateID, "mate@test.ac.bd", "Mate Student"} {
			assert.NotContains(t, body, s)
		}
	}
	post := h.postIssue(c.author, postBody("post", "Fresh samosas at the canteen today"))
	question := h.postIssue(c.author, postBody("question", "Where is the physics lab?"))
	poll := h.postIssue(c.author, pollBody("Best canteen day?", "Friday", "Saturday"))
	mateQuestion := h.postIssue(c.mate, postBody("question", "Is the library open on Friday?"))
	answer := h.comment(c.mate, question.ID, map[string]any{"body": "Block C, third floor."})
	reply := h.comment(c.author, question.ID, map[string]any{"body": "Thank you!", "parentId": answer.ID})
	for _, w := range []*response{
		h.do("PUT", "/issues/"+post.ID+"/vote", c.mate, map[string]string{"reaction": "haha"}),
		h.do("PUT", "/issues/"+post.ID+"/vote", c.author, map[string]string{"reaction": "wow"}),
		h.do("PUT", "/issues/"+mateQuestion.ID+"/vote", c.author, map[string]string{"reaction": "clap"}),
		h.do("POST", "/issues/"+poll.ID+"/poll-vote", c.mate, map[string]string{"optionId": poll.Poll.Options[0].ID}),
		h.do("PUT", "/issues/"+question.ID+"/comments/"+answer.ID+"/like", c.author, nil),
		h.do("PUT", "/issues/"+question.ID+"/comments/"+reply.ID+"/like", c.mate, nil),
		h.do("DELETE", "/issues/"+post.ID+"/vote", c.author, nil),
	} {
		require.Equal(t, http.StatusOK, w.Status, w.Raw)
		forbidden(t, w.Raw)
	}
	_, replyBody := h.raw(c.mate, "/issues/"+question.ID+"/comments")
	forbidden(t, string(replyBody))
	require.Equal(t, http.StatusOK, h.do("PUT", "/issues/"+post.ID+"/vote", c.author, nil).Status)
	_ = reply
	voiceReads := func(id string) []string {
		return []string{
			"/issues", "/issues?sort=new", "/issues?sort=solved", "/issues?private=true",
			"/issues/similar?q=" + "Broken+water+pump", "/issues/" + id, "/issues/" + id + "/comments",
			"/issues/" + safety.ID, "/issues/" + safety.ID + "/comments", "/me/issues",
			"/issues?kinds=all", "/issues?kinds=all&sort=new", "/issues?kinds=post,question,poll&sort=trending",
			"/issues?kinds=all&sort=solved", "/me/issues?kinds=all",
			"/issues/" + post.ID, "/issues/" + question.ID, "/issues/" + question.ID + "/comments",
			"/issues/" + poll.ID, "/issues/" + mateQuestion.ID,
		}
	}
	modReads := func(id string) []string {
		return []string{
			"/moderation/queue?kind=reported", "/moderation/queue?kind=held", "/moderation/queue?kind=hidden",
			"/moderation/queue?kind=private", "/moderation/issues/" + id, "/moderation/issues/" + safety.ID,
		}
	}
	// A visitor from another university (docs/CAMPUS_VISITS.md): reads and
	// reacts, and learns nothing about authors that classmates don't.
	h.addUni("visiting", "Visiting University")
	visitor := h.named("visitor@visiting.ac.bd", "Visitor Vee")
	home := "universityId=" + h.universityID("test-uni")
	require.Equal(t, http.StatusOK, h.do("PUT", "/issues/"+post.ID+"/vote", visitor, map[string]string{"reaction": "clap"}).Status)
	visitorReads := []string{
		"/issues?" + home + "&kinds=all", "/issues?" + home + "&kinds=all&sort=new", "/issues?" + home + "&kinds=all&sort=solved",
		"/issues?" + home + "&kinds=issue", "/issues?" + home + "&kinds=all&private=true",
		"/issues/" + post.ID, "/issues/" + question.ID, "/issues/" + question.ID + "/comments",
		"/issues/" + poll.ID, "/issues/" + mateQuestion.ID, "/issues/" + mateQuestion.ID + "/comments",
		"/issues/" + pub.ID, "/issues/" + pub.ID + "/comments", "/issues/" + safety.ID,
		"/campuses", "/campuses/test-uni",
	}
	sweep := func(t *testing.T, stage string) {
		t.Helper()
		for _, p := range visitorReads {
			status, body := h.raw(visitor, p)
			require.Less(t, status, 500, "%s visitor %s", stage, p)
			forbidden(t, string(body))
			if p == "/issues/"+pub.ID || p == "/issues/"+safety.ID || p == "/issues/"+pub.ID+"/comments" {
				assert.Equal(t, http.StatusNotFound, status, "issues stay inside: %s", p)
			}
		}
		for name, tok := range map[string]string{"student": c.mate, "authority": c.authority, "moderator": c.mod, "admin": c.admin} {
			paths := voiceReads(pub.ID)
			if name == "moderator" || name == "admin" {
				paths = append(paths, modReads(pub.ID)...)
			}
			if name == "admin" {
				paths = append(paths, "/admin/audit", "/admin/audit?page=2", "/admin/stats")
			}
			for _, p := range paths {
				status, body := h.raw(tok, p)
				require.Less(t, status, 500, "%s %s %s", stage, name, p)
				forbidden(t, string(body))
			}
		}
		// The admin's user pages show the person, but never their voice activity.
		for _, p := range []string{"/admin/users?q=alpha", "/admin/users/" + c.authorID} {
			status, body := h.raw(c.admin, p)
			if status == http.StatusOK {
				for _, s := range []string{pub.ID, safety.ID, pub.Title, safety.Title, authorComment.ID} {
					assert.NotContains(t, string(body), s, "%s %s", stage, p)
				}
			}
		}
	}
	sweep(t, "after posting")

	// The author still sees "mine", and the moderation view shows the reports.
	assert.True(t, h.getIssue(c.author, pub.ID).Mine)
	assert.False(t, h.getIssue(c.mate, pub.ID).Mine)

	// Ban the author through their issue: nobody learns who it was.
	r := h.do("POST", "/moderation/issues/"+pub.ID+"/ban-author", c.mod, map[string]any{"days": 7, "reason": "Spam"})
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	forbidden(t, r.Raw)
	sweep(t, "after a ban")

	// The author deletes their account: the issue stays, linked to no one.
	require.Equal(t, http.StatusNoContent, h.do("DELETE", "/me", c.author, nil).Status)
	sweep(t, "after deleting the account")
	assert.Equal(t, "Broken water pump in Hall 3", h.getIssue(c.mate, pub.ID).Title)
	assert.Equal(t, "Fresh samosas at the canteen today", h.getIssue(c.mate, post.ID).Preview)
	for _, cm := range h.comments(c.mate, pub.ID) {
		assert.False(t, cm.IsIssueAuthor, "no author link left")
	}
}

// Test 2: a named post shows the display name only, never the id or email.
func TestVoiceNamedPost(t *testing.T) {
	h := newHarness(t)
	c := newVoiceCast(h)
	is := h.postIssue(c.author, issueBody("Library closes too early", map[string]any{"anonymous": false}))
	r := h.do("GET", "/issues/"+is.ID, c.mate, nil)
	require.Equal(t, http.StatusOK, r.Status)
	var got issueJSON
	r.into(t, &got)
	require.NotNil(t, got.Author)
	assert.Equal(t, c.authorName, *got.Author.Name)
	assert.True(t, got.Author.Verified)
	assert.NotContains(t, r.Raw, c.authorID)
	assert.NotContains(t, r.Raw, c.authorEmail)

	// Named comments too; deleted accounts read as an author with no name.
	h.comment(c.author, is.ID, map[string]any{"body": "Please extend to 10 pm", "anonymous": false})
	require.Equal(t, http.StatusNoContent, h.do("DELETE", "/me", c.author, nil).Status)
	got = h.getIssue(c.mate, is.ID)
	require.NotNil(t, got.Author)
	assert.Nil(t, got.Author.Name)
	cms := h.comments(c.mate, is.ID)
	require.Len(t, cms, 1)
	require.NotNil(t, cms[0].Author)
	assert.Nil(t, cms[0].Author.Name)
}

// Test 3: handles. Test 4: rough times.
func TestVoiceHandlesAndTimes(t *testing.T) {
	h := newHarness(t)
	c := newVoiceCast(h)
	h.advance(2*60e9 + 13e9) // off a 5-minute mark
	one := h.postIssue(c.author, issueBody("Broken water pump in Hall 3"))
	two := h.postIssue(c.author, issueBody("No hot water in Hall 3"))
	a1 := h.comment(c.author, one.ID, map[string]any{"body": "Still broken"})
	a2 := h.comment(c.author, one.ID, map[string]any{"body": "And now the tap leaks"})
	m1 := h.comment(c.mate, one.ID, map[string]any{"body": "Same here"})
	a3 := h.comment(c.author, two.ID, map[string]any{"body": "Any news?"})

	assert.Equal(t, a1.Handle, a2.Handle, "same person, same issue")
	assert.NotEqual(t, a1.Handle, m1.Handle)
	assert.NotEqual(t, a1.Handle, a3.Handle, "unrelated across issues")
	byID := map[string]voiceCommentJSON{}
	for _, cm := range h.comments(c.mate, one.ID) {
		byID[cm.ID] = cm
	}
	assert.True(t, byID[a1.ID].IsIssueAuthor)
	assert.False(t, byID[m1.ID].IsIssueAuthor)
	assert.False(t, byID[a1.ID].Mine, "the classmate sees no 'mine'")
	for _, cm := range h.comments(c.author, one.ID) {
		assert.Equal(t, cm.ID != m1.ID, cm.Mine, "the author sees only their own as mine")
	}

	now := h.Now().UTC()
	assert.True(t, one.CreatedAt.Equal(now.Truncate(5*60e9)), "rounded down to 5 minutes: %v at %v", one.CreatedAt, now)
	assert.True(t, a1.CreatedAt.Equal(now.Truncate(5*60e9)))
	assert.NotEqual(t, 0, now.Minute()%5+now.Second(), "the clock is not on a 5-minute mark")
	named := h.postIssue(c.mate, issueBody("Named issue about the canteen", map[string]any{"anonymous": false}))
	assert.True(t, named.CreatedAt.Equal(now), "named: exact")

	assert.True(t, strings.ToUpper(a1.Handle) == a1.Handle && len(a1.Handle) == 4)
}
