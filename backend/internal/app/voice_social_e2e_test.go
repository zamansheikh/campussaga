package app

import (
	"fmt"
	"net/http"
	"strings"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/zamansheikh/varsitykotha/backend/internal/platform/media/mediatest"
)

// Campus social (docs/CAMPUS_SOCIAL.md): post, question and poll kinds,
// reactions, poll votes, replies and comment likes.

type reactionRes struct {
	MeTooCount int            `json:"meTooCount"`
	Voted      bool           `json:"voted"`
	Reactions  map[string]int `json:"reactions"`
	MyReaction *string        `json:"myReaction"`
}

func postBody(kind, body string, extra ...map[string]any) map[string]any {
	b := map[string]any{"kind": kind, "body": body}
	for _, e := range extra {
		for k, v := range e {
			b[k] = v
		}
	}
	return b
}

func pollBody(question string, opts ...string) map[string]any {
	return postBody("poll", question, map[string]any{"pollOptions": opts})
}

func (h *harness) third() string { return h.named("third@test.ac.bd", "Third Student") }

func (h *harness) react(tok, id string, body any) (*response, reactionRes) {
	h.t.Helper()
	r := h.do("PUT", "/issues/"+id+"/vote", tok, body)
	var out reactionRes
	if r.Status == http.StatusOK {
		r.into(h.t, &out)
	}
	return r, out
}

func TestSocialCreateKinds(t *testing.T) {
	h := newHarness(t)
	c := newVoiceCast(h)
	tries := 0
	var tester string
	invalid := func(body map[string]any, field string) {
		t.Helper()
		if tries%10 == 0 { // refused requests count toward the route limit: rotate users
			tester = h.named(fmt.Sprintf("tester%d@test.ac.bd", tries), "Tester")
		}
		tries++
		r := h.do("POST", "/issues", tester, body)
		assert.Equal(t, "VALIDATION_FAILED", r.code(), "%v: %s", body, r.Raw)
		assert.Contains(t, r.Raw, field, r.Raw)
	}

	// Post: text, default category, no title.
	p := h.postIssue(c.author, postBody("post", "Fresh samosas at the canteen today"))
	assert.Equal(t, "post", p.Kind)
	assert.Equal(t, "general", p.Category)
	assert.Equal(t, "", p.Title)
	assert.Equal(t, "open", p.Status)
	assert.Nil(t, p.Poll)
	assert.Equal(t, map[string]int{}, p.Reactions)
	assert.False(t, p.Can["changeStatus"] || p.Can["officialReply"] || p.Can["reopen"])
	assert.True(t, h.postIssue(c.author, postBody("post", "Lost my umbrella", map[string]any{"category": "lost_found"})).Category == "lost_found")

	// A post needs text or a photo; a photo alone is enough.
	invalid(postBody("post", ""), "body")
	invalid(postBody("post", strings.Repeat("a", 3001)), "body")
	invalid(postBody("post", "hello there", map[string]any{"title": "A title"}), "title")
	up := h.upload(c.author, mediatest.JPEGWithExif(t, 800, 600, 1))
	require.Equal(t, http.StatusCreated, up.Status, up.Raw)
	var photo struct {
		ID string `json:"id"`
	}
	up.into(t, &photo)
	withPhoto := h.postIssue(c.author, postBody("post", "", map[string]any{"imageIds": []string{photo.ID}}))
	require.Len(t, withPhoto.Images, 1)
	assert.Equal(t, 1, withPhoto.ImageCount)

	// Question 8 to 3000, poll question 4 to 300.
	invalid(postBody("question", "Why?"), "body")
	assert.Equal(t, "question", h.postIssue(c.author, postBody("question", "Where is the lab?")).Kind)
	invalid(pollBody("Yes", "a", "b"), "body")
	invalid(pollBody(strings.Repeat("q", 301), "a", "b"), "body")

	// Poll options: 2 to 4, 1 to 80 characters, unique ignoring case.
	invalid(pollBody("Best canteen day?", "only one"), "pollOptions")
	invalid(pollBody("Best canteen day?", "a", "b", "c", "d", "e"), "pollOptions")
	invalid(pollBody("Best canteen day?", "Friday", "friday"), "pollOptions")
	invalid(pollBody("Best canteen day?", "Friday", ""), "pollOptions")
	invalid(pollBody("Best canteen day?", "Friday", strings.Repeat("x", 81)), "pollOptions")
	invalid(postBody("poll", "Best canteen day?", map[string]any{"pollOptions": []string{"a", "b"}, "pollDays": 2}), "pollDays")
	invalid(postBody("post", "hello there", map[string]any{"pollOptions": []string{"a", "b"}}), "pollOptions")

	poll := h.postIssue(c.author, pollBody("Best canteen day?", "Friday", " Saturday "))
	require.NotNil(t, poll.Poll)
	assert.Equal(t, "Saturday", poll.Poll.Options[1].Label)
	assert.WithinDuration(t, h.Now().Add(72*time.Hour), poll.Poll.ClosesAt, 2*time.Second, "3 days by default")
	assert.False(t, poll.Poll.Closed)
	week := h.postIssue(c.author, postBody("poll", "Exam week poll", map[string]any{"pollOptions": []string{"yes", "no"}, "pollDays": 7}))
	assert.WithinDuration(t, h.Now().Add(7*24*time.Hour), week.Poll.ClosesAt, 2*time.Second)

	// Safety stays issue-only; social topics stay post-only.
	invalid(postBody("post", "someone follows me", map[string]any{"category": "safety"}), "category")
	invalid(issueBody("Fresh samosas at the canteen", map[string]any{"category": "general"}), "category")
	invalid(map[string]any{"title": "No category on this issue", "body": "The water pump on the third floor has been broken."}, "category")
	invalid(postBody("post", "hello there", map[string]any{"category": "bogus"}), "category")
	invalid(postBody("video", "hello there"), "kind")

	// The auto text check covers posts and poll options.
	h.advance(25 * time.Hour) // a new day: the route limit starts over
	c = h.refresh(c)
	held := h.postIssue(c.author, postBody("post", "Call me on 01712345678"))
	assert.Equal(t, "held", held.Visibility)
	assert.Equal(t, "personal_info", held.HoldReason)
	heldPoll := h.postIssue(c.author, pollBody("Who wants to chat?", "Call 01712345678", "No"))
	assert.Equal(t, "held", heldPoll.Visibility)
	assert.Equal(t, "personal_info", heldPoll.HoldReason)

	// ...and both reach the moderators with their kind and poll.
	r := h.do("GET", "/moderation/queue?kind=held", c.mod, nil)
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	var q voicePage[struct {
		Issue issueJSON `json:"issue"`
	}]
	r.into(t, &q)
	var sawPoll bool
	for _, it := range q.Items {
		if it.Issue.ID == heldPoll.ID {
			sawPoll = true
			assert.Equal(t, "poll", it.Issue.Kind)
			require.NotNil(t, it.Issue.Poll)
			assert.Len(t, it.Issue.Poll.Options, 2)
			require.NotNil(t, it.Issue.Poll.Options[0].Votes, "moderators see the counts")
		}
	}
	assert.True(t, sawPoll, r.Raw)
	r = h.do("GET", "/moderation/issues/"+heldPoll.ID, c.mod, nil)
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	assert.Contains(t, r.Raw, `"kind":"poll"`)
	// Moderating works for every kind.
	r = h.do("POST", "/moderation/issues/"+held.ID, c.mod, map[string]string{"action": "approve"})
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	assert.Equal(t, "visible", h.getIssue(c.mate, held.ID).Visibility)
}

func TestSocialFeedKinds(t *testing.T) {
	h := newHarness(t)
	c := newVoiceCast(h)
	h.advance(time.Minute)
	long := strings.Repeat("word ", 130) // 650 characters
	issue := h.postIssue(c.author, issueBody("Broken water pump in Hall 3", map[string]any{"body": long}))
	post := h.postIssue(c.author, postBody("post", long))
	question := h.postIssue(c.author, postBody("question", "Where is the physics lab?"))
	poll := h.postIssue(c.author, pollBody("Best canteen day?", "Friday", "Saturday"))

	ids := func(items []issueJSON) []string {
		out := make([]string, 0, len(items))
		for _, i := range items {
			out = append(out, i.ID)
		}
		return out
	}
	// Absent = issues only (apps before this release).
	assert.Equal(t, []string{issue.ID}, ids(h.feed(c.mate, "")))
	assert.Equal(t, []string{issue.ID}, ids(h.feed(c.mate, "?sort=new")))
	assert.ElementsMatch(t, []string{issue.ID, post.ID, question.ID, poll.ID}, ids(h.feed(c.mate, "?kinds=all")))
	assert.ElementsMatch(t, []string{issue.ID, post.ID, question.ID, poll.ID}, ids(h.feed(c.mate, "?kinds=all&sort=new")))
	assert.ElementsMatch(t, []string{question.ID}, ids(h.feed(c.mate, "?kinds=question&sort=new")))
	assert.ElementsMatch(t, []string{post.ID, poll.ID}, ids(h.feed(c.mate, "?kinds=post,poll")))
	assert.Equal(t, "VALIDATION_FAILED", h.do("GET", "/issues?kinds=bogus", c.mate, nil).code())
	// Topics.
	assert.Empty(t, h.feed(c.mate, "?kinds=all&category=fun"))
	assert.ElementsMatch(t, []string{post.ID, question.ID, poll.ID}, ids(h.feed(c.mate, "?kinds=post,question,poll&category=general")))
	// My posts.
	assert.Equal(t, []string{issue.ID}, ids(func() []issueJSON {
		r := h.do("GET", "/me/issues", c.author, nil)
		require.Equal(t, http.StatusOK, r.Status)
		var p voicePage[issueJSON]
		r.into(t, &p)
		return p.Items
	}()))
	r := h.do("GET", "/me/issues?kinds=all", c.author, nil)
	var mine voicePage[issueJSON]
	r.into(t, &mine)
	assert.Len(t, mine.Items, 4)

	// Solved = issues only, whatever kinds says.
	require.Equal(t, http.StatusOK, h.do("POST", "/issues/"+issue.ID+"/status", c.authority, map[string]string{"to": "solved"}).Status)
	assert.Equal(t, []string{issue.ID}, ids(h.feed(c.mate, "?sort=solved&kinds=all")))
	// Trending: non-issues are always open, so they qualify.
	assert.ElementsMatch(t, []string{post.ID, question.ID, poll.ID}, ids(h.feed(c.mate, "?kinds=post,question,poll&sort=trending")))

	// Previews: 160 for issues, 500 for the rest, with previewCut.
	got := h.getIssue(c.mate, issue.ID)
	assert.Equal(t, 160, len([]rune(got.Preview)))
	assert.True(t, got.PreviewCut)
	got = h.getIssue(c.mate, post.ID)
	assert.Equal(t, 500, len([]rune(got.Preview)))
	assert.True(t, got.PreviewCut)
	got = h.getIssue(c.mate, question.ID)
	assert.Equal(t, "Where is the physics lab?", got.Preview)
	assert.False(t, got.PreviewCut)

	// Anonymous times are rounded for every kind.
	assert.Equal(t, 0, got.CreatedAt.Minute()%5)
	assert.Zero(t, got.CreatedAt.Second())
}

func TestSocialReactions(t *testing.T) {
	h := newHarness(t)
	c := newVoiceCast(h)
	third := h.third()
	post := h.postIssue(c.author, postBody("post", "Fresh samosas today"))

	// Set, change, remove; counts per reaction.
	r, res := h.react(c.mate, post.ID, map[string]string{"reaction": "haha"})
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	assert.Equal(t, 1, res.MeTooCount)
	assert.True(t, res.Voted)
	assert.Equal(t, map[string]int{"haha": 1}, res.Reactions)
	require.NotNil(t, res.MyReaction)
	assert.Equal(t, "haha", *res.MyReaction)
	_, res = h.react(c.mate, post.ID, map[string]string{"reaction": "clap"})
	assert.Equal(t, 1, res.MeTooCount, "changing keeps the count")
	assert.Equal(t, map[string]int{"clap": 1}, res.Reactions)
	_, res = h.react(third, post.ID, nil) // empty body = like
	assert.Equal(t, 2, res.MeTooCount)
	assert.Equal(t, map[string]int{"clap": 1, "like": 1}, res.Reactions)
	got := h.getIssue(c.mate, post.ID)
	assert.Equal(t, 2, got.MeTooCount)
	assert.True(t, got.Voted)
	require.NotNil(t, got.MyReaction)
	assert.Equal(t, "clap", *got.MyReaction)
	assert.Equal(t, map[string]int{"clap": 1, "like": 1}, got.Reactions)
	assert.Nil(t, h.getIssue(c.authority, post.ID).MyReaction)

	r = h.do("DELETE", "/issues/"+post.ID+"/vote", c.mate, nil)
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	res = reactionRes{}
	r.into(t, &res)
	assert.Equal(t, 1, res.MeTooCount)
	assert.False(t, res.Voted)
	assert.Nil(t, res.MyReaction)
	assert.Equal(t, map[string]int{"like": 1}, res.Reactions)

	// Your own post can be reacted to; a bad reaction is refused.
	r, res = h.react(c.author, post.ID, map[string]string{"reaction": "wow"})
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	assert.Equal(t, 2, res.MeTooCount)
	r, _ = h.react(c.mate, post.ID, map[string]string{"reaction": "angry"})
	assert.Equal(t, "VALIDATION_FAILED", r.code())

	// Issues: "me too" only, never your own, any reaction sent is ignored,
	// and the old app's empty body still works.
	issue := h.postIssue(c.author, issueBody("Broken water pump in Hall 3"))
	r, _ = h.react(c.author, issue.ID, nil)
	assert.Equal(t, "CANNOT_VOTE_OWN", r.code())
	r, res = h.react(c.mate, issue.ID, nil)
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	assert.Equal(t, map[string]int{"me_too": 1}, res.Reactions)
	_, res = h.react(third, issue.ID, map[string]string{"reaction": "sad"})
	assert.Equal(t, map[string]int{"me_too": 2}, res.Reactions)
	assert.Equal(t, 2, h.getIssue(c.mate, issue.ID).MeTooCount)
	assert.Equal(t, "me_too", *h.getIssue(third, issue.ID).MyReaction)
	require.Equal(t, http.StatusOK, h.do("DELETE", "/issues/"+issue.ID+"/vote", c.mate, nil).Status)
	assert.Equal(t, 1, h.getIssue(c.mate, issue.ID).MeTooCount)
}

func TestSocialPoll(t *testing.T) {
	h := newHarness(t)
	c := newVoiceCast(h)
	third := h.third()
	p := h.postIssue(c.author, pollBody("Best canteen day?", "Friday", "Saturday", "Sunday"))
	friday, saturday := p.Poll.Options[0].ID, p.Poll.Options[1].ID
	vote := func(tok, id, option string) *response {
		return h.do("POST", "/issues/"+id+"/poll-vote", tok, map[string]string{"optionId": option})
	}

	// Counts are hidden until you vote, except on your own poll.
	got := h.getIssue(c.mate, p.ID)
	assert.Equal(t, 0, got.Poll.TotalVotes)
	assert.Nil(t, got.Poll.MyVote)
	for _, o := range got.Poll.Options {
		assert.Nil(t, o.Votes)
	}
	require.NotNil(t, h.getIssue(c.author, p.ID).Poll.Options[0].Votes)

	r := vote(c.mate, p.ID, friday)
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	var poll pollJSON
	r.into(t, &poll)
	assert.Equal(t, 1, poll.TotalVotes)
	require.NotNil(t, poll.MyVote)
	assert.Equal(t, friday, *poll.MyVote)
	require.NotNil(t, poll.Options[0].Votes)
	assert.Equal(t, 1, *poll.Options[0].Votes)
	assert.Equal(t, 0, *poll.Options[1].Votes)

	// Seen by others: still hidden for a non-voter, total shown.
	got = h.getIssue(third, p.ID)
	assert.Equal(t, 1, got.Poll.TotalVotes)
	assert.Nil(t, got.Poll.Options[0].Votes)
	feed := h.feed(c.mate, "?kinds=poll")
	require.Len(t, feed, 1)
	require.NotNil(t, feed[0].Poll.Options[0].Votes)

	// One vote, never changed; unknown option; not a poll; banned.
	assert.Equal(t, "ALREADY_VOTED", vote(c.mate, p.ID, saturday).code())
	assert.Equal(t, "VALIDATION_FAILED", vote(third, p.ID, "7a1c8a6e-0000-4000-8000-000000000000").code())
	assert.Equal(t, "VALIDATION_FAILED", h.do("POST", "/issues/"+p.ID+"/poll-vote", third, map[string]string{"optionId": "x"}).code())
	post := h.postIssue(c.author, postBody("post", "Fresh samosas today"))
	assert.Equal(t, "POLL_CLOSED", vote(third, post.ID, saturday).code())
	require.Equal(t, http.StatusOK, vote(third, p.ID, saturday).Status)
	assert.Equal(t, 2, h.getIssue(c.mate, p.ID).Poll.TotalVotes)

	// Closed after closesAt: no votes, counts shown to everyone.
	h.advance(73 * time.Hour)
	fourth := h.named("fourth@test.ac.bd", "Fourth Student") // sign-in tokens last 15 minutes
	assert.Equal(t, "POLL_CLOSED", vote(fourth, p.ID, friday).code())
	got = h.getIssue(fourth, p.ID)
	assert.True(t, got.Poll.Closed)
	require.NotNil(t, got.Poll.Options[0].Votes)
	assert.Equal(t, 1, *got.Poll.Options[0].Votes)
	assert.Equal(t, 1, *got.Poll.Options[1].Votes)
}

func TestSocialPollVoteBanned(t *testing.T) {
	h := newHarness(t)
	c := newVoiceCast(h)
	p := h.postIssue(c.author, pollBody("Best canteen day?", "Friday", "Saturday"))
	bad := h.postIssue(c.mate, postBody("post", "spam spam spam"))
	r := h.do("POST", "/moderation/issues/"+bad.ID+"/ban-author", c.mod, map[string]any{"days": 7, "reason": "Spam"})
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	r = h.do("POST", "/issues/"+p.ID+"/poll-vote", c.mate, map[string]string{"optionId": p.Poll.Options[0].ID})
	assert.Equal(t, "VOICE_BANNED", r.code())
}

func TestSocialRepliesAndPushes(t *testing.T) {
	h := newHarness(t)
	c := newVoiceCast(h)
	third := h.third()
	h.register(c.author, "tok-author", "android", "en")
	h.register(c.mate, "tok-mate", "android", "bn")
	h.register(third, "tok-third", "android", "en")
	q := h.postIssue(c.author, postBody("question", "Where is the physics lab?"))

	// A comment on a question is an answer.
	top := h.comment(c.mate, q.ID, map[string]any{"body": "Block C, third floor."})
	assert.Nil(t, top.ParentID)
	sent := h.sent()
	assert.Equal(t, "New answer to your question", sent["tok-author"].Title)
	assert.Equal(t, "Where is the physics lab?", sent["tok-author"].Body)
	assert.NotContains(t, sent, "tok-mate")

	// A reply goes to the author of the comment, not the replier.
	h.advance(time.Minute)
	reply := h.comment(c.author, q.ID, map[string]any{"body": "Thank you, found it", "parentId": top.ID})
	require.NotNil(t, reply.ParentID)
	assert.Equal(t, top.ID, *reply.ParentID)
	sent = h.sent()
	require.Contains(t, sent, "tok-mate")
	assert.Equal(t, "তোমার মন্তব্যে নতুন উত্তর", sent["tok-mate"].Title, "in the reader's language")
	assert.Equal(t, "issue_reply", sent["tok-mate"].Data["type"])
	assert.Equal(t, q.ID, sent["tok-mate"].Data["issueId"])
	assert.Equal(t, "Thank you, found it", sent["tok-mate"].Body)
	assert.NotContains(t, sent, "tok-author", "not to the replier, even as the post's author")

	// Replying to a reply attaches to the same parent (one level); the
	// reply's author gets the one push (not a second "new answer").
	flat := h.comment(third, q.ID, map[string]any{"body": "Is it open on Fridays?", "parentId": reply.ID})
	require.NotNil(t, flat.ParentID)
	assert.Equal(t, top.ID, *flat.ParentID)
	sent = h.sent()
	assert.Equal(t, "New reply to your comment", sent["tok-author"].Title)
	assert.Equal(t, "issue_reply", sent["tok-author"].Data["type"])
	assert.Len(t, sent, 1)

	// Throttled: one push per comment every 15 minutes.
	h.comment(third, q.ID, map[string]any{"body": "Anyone?", "parentId": top.ID})
	assert.NotContains(t, h.sent(), "tok-mate", "mate was told a minute ago")
	h.advance(16 * time.Minute)
	c, third = h.refresh(c), h.signIn("third@test.ac.bd").Tokens.AccessToken
	h.comment(third, q.ID, map[string]any{"body": "Anyone there?", "parentId": top.ID})
	sent = h.sent()
	assert.Equal(t, "তোমার মন্তব্যে নতুন উত্তর", sent["tok-mate"].Title)
	assert.Equal(t, "New answer to your question", sent["tok-author"].Title)

	// Your own comment: no push to yourself.
	h.comment(c.mate, q.ID, map[string]any{"body": "Also: bring your ID", "parentId": top.ID})
	assert.NotContains(t, h.sent(), "tok-mate")

	// The parent must be a visible comment of the same issue.
	other := h.postIssue(c.author, postBody("post", "Another post here"))
	r := h.do("POST", "/issues/"+other.ID+"/comments", c.mate, map[string]any{"body": "x", "parentId": top.ID})
	assert.Equal(t, "COMMENT_NOT_FOUND", r.code())
	r = h.do("POST", "/issues/"+q.ID+"/comments", c.mate, map[string]any{"body": "x", "parentId": "7a1c8a6e-0000-4000-8000-000000000000"})
	assert.Equal(t, "COMMENT_NOT_FOUND", r.code())
	r = h.do("POST", "/issues/"+q.ID+"/comments", c.mate, map[string]any{"body": "x", "parentId": "nope"})
	assert.Equal(t, "VALIDATION_FAILED", r.code())
	require.Equal(t, http.StatusOK, h.do("POST", "/moderation/comments/"+top.ID, c.mod, map[string]string{"action": "hide"}).Status)
	r = h.do("POST", "/issues/"+q.ID+"/comments", third, map[string]any{"body": "x", "parentId": top.ID})
	assert.Equal(t, "COMMENT_NOT_FOUND", r.code())

	// Comments list carries parentId; a post's comment push says "post".
	var withParent int
	for _, cm := range h.comments(c.mod, q.ID) {
		if cm.ParentID != nil {
			withParent++
		}
	}
	assert.GreaterOrEqual(t, withParent, 3)
	h.advance(time.Hour)
	c = h.refresh(c)
	post := h.postIssue(c.author, postBody("post", "Fresh samosas today"))
	h.comment(c.mate, post.ID, map[string]any{"body": "Yum"})
	sent = h.sent()
	assert.Equal(t, "New comment on your post", sent["tok-author"].Title)
	assert.Equal(t, "Fresh samosas today", sent["tok-author"].Body)
}

func TestSocialCommentLikes(t *testing.T) {
	h := newHarness(t)
	c := newVoiceCast(h)
	third := h.third()
	post := h.postIssue(c.author, postBody("post", "Fresh samosas today"))
	cm := h.comment(c.mate, post.ID, map[string]any{"body": "Yum"})
	assert.Equal(t, 0, cm.LikeCount)
	assert.False(t, cm.Liked)

	like := func(tok, method string) (*response, likeJSON) {
		r := h.do(method, "/issues/"+post.ID+"/comments/"+cm.ID+"/like", tok, nil)
		var out likeJSON
		if r.Status == http.StatusOK {
			r.into(t, &out)
		}
		return r, out
	}
	r, out := like(c.author, "PUT")
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	assert.Equal(t, likeJSON{LikeCount: 1, Liked: true}, out)
	_, out = like(c.author, "PUT")
	assert.Equal(t, 1, out.LikeCount, "idempotent")
	_, out = like(c.mate, "PUT") // your own comment
	assert.Equal(t, 2, out.LikeCount)
	_, out = like(third, "PUT")
	assert.Equal(t, 3, out.LikeCount)
	var seen []voiceCommentJSON = h.comments(c.author, post.ID)
	require.Len(t, seen, 1)
	assert.Equal(t, 3, seen[0].LikeCount)
	assert.True(t, seen[0].Liked)
	assert.False(t, h.comments(c.authority, post.ID)[0].Liked)
	_, out = like(c.author, "DELETE")
	assert.Equal(t, likeJSON{LikeCount: 2, Liked: false}, out)
	_, out = like(c.author, "DELETE")
	assert.Equal(t, 2, out.LikeCount, "idempotent")

	// Visible comments of that issue only.
	other := h.postIssue(c.author, postBody("post", "Another post here"))
	r = h.do("PUT", "/issues/"+other.ID+"/comments/"+cm.ID+"/like", third, nil)
	assert.Equal(t, "COMMENT_NOT_FOUND", r.code())
	require.Equal(t, http.StatusOK, h.do("POST", "/moderation/comments/"+cm.ID, c.mod, map[string]string{"action": "hide"}).Status)
	r, _ = like(third, "PUT")
	assert.Equal(t, "COMMENT_NOT_FOUND", r.code())
}

type likeJSON struct {
	LikeCount int  `json:"likeCount"`
	Liked     bool `json:"liked"`
}

func TestSocialNotAnIssue(t *testing.T) {
	h := newHarness(t)
	c := newVoiceCast(h)
	for _, p := range []*issueJSON{
		ptr(h.postIssue(c.author, postBody("post", "Fresh samosas today"))),
		ptr(h.postIssue(c.author, postBody("question", "Where is the physics lab?"))),
		ptr(h.postIssue(c.author, pollBody("Best canteen day?", "Friday", "Saturday"))),
	} {
		r := h.do("POST", "/issues/"+p.ID+"/status", c.authority, map[string]string{"to": "solved"})
		assert.Equal(t, "NOT_AN_ISSUE", r.code(), p.Kind)
		assert.Equal(t, http.StatusConflict, r.Status)
		r = h.do("POST", "/issues/"+p.ID+"/official-replies", c.authority, map[string]string{"body": "Noted"})
		assert.Equal(t, "NOT_AN_ISSUE", r.code(), p.Kind)
		r = h.do("POST", "/issues/"+p.ID+"/reopen", c.author, map[string]string{"note": "again"})
		assert.Equal(t, "NOT_AN_ISSUE", r.code(), p.Kind)
		got := h.getIssue(c.authority, p.ID)
		assert.False(t, got.Can["changeStatus"] || got.Can["officialReply"] || got.Can["reopen"])
		assert.Equal(t, "open", got.Status)
	}
	// Similar issues stay issues-only.
	h.postIssue(c.author, postBody("post", "Broken water pump in Hall 3 today"))
	r := h.do("GET", "/issues/similar?q=Broken+water+pump+in+Hall+3", c.mate, nil)
	require.Equal(t, http.StatusOK, r.Status)
	assert.NotContains(t, r.Raw, `"kind":"post"`)
}

func ptr[T any](v T) *T { return &v }

func TestSocialEditAndDelete(t *testing.T) {
	h := newHarness(t)
	c := newVoiceCast(h)
	post := h.postIssue(c.author, postBody("post", "Fresh samosas today"))
	r := h.do("PATCH", "/issues/"+post.ID, c.author, map[string]string{"body": "Fresh samosas and tea today", "title": ""})
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	var got issueJSON
	r.into(t, &got)
	assert.Equal(t, "", got.Title)
	assert.Contains(t, got.Preview, "and tea")
	assert.Equal(t, "VALIDATION_FAILED", h.do("PATCH", "/issues/"+post.ID, c.author, map[string]string{"title": "A title"}).code())
	assert.Equal(t, "VALIDATION_FAILED", h.do("PATCH", "/issues/"+post.ID, c.author, map[string]string{"body": ""}).code())
	poll := h.postIssue(c.author, pollBody("Best canteen day?", "Friday", "Saturday"))
	assert.Equal(t, "VALIDATION_FAILED", h.do("PATCH", "/issues/"+poll.ID, c.author, map[string]string{"body": "No"}).code())
	assert.Equal(t, "BAD_REQUEST", h.do("PATCH", "/issues/"+poll.ID, c.author, map[string]any{"pollOptions": []string{"a", "b"}}).code(),
		"options can't be edited")
	assert.Equal(t, "ISSUE_NOT_FOUND", h.do("PATCH", "/issues/"+post.ID, c.mate, map[string]string{"body": "Mine now"}).code())
	require.Equal(t, http.StatusNoContent, h.do("DELETE", "/issues/"+post.ID, c.author, nil).Status)
	assert.Equal(t, "ISSUE_NOT_FOUND", h.do("GET", "/issues/"+post.ID, c.mate, nil).code())
}

func TestSocialDailyLimits(t *testing.T) {
	h := newHarness(t)
	c := newVoiceCast(h)
	for i := 0; i < 5; i++ {
		h.postIssue(c.author, issueBody("Broken water pump in Hall "+string(rune('A'+i))))
	}
	// The sixth issue is refused with the same error as the rate limiter...
	r := h.do("POST", "/issues", c.author, issueBody("Broken water pump in Hall F"))
	assert.Equal(t, http.StatusTooManyRequests, r.Status, r.Raw)
	assert.Equal(t, "TOO_MANY_REQUESTS", r.code())
	// ...but the day still has room for other kinds (25 in all).
	for i := 0; i < 19; i++ { // 5 + the refused one + 19 = 25 requests
		h.postIssue(c.author, postBody("post", "A post number "+string(rune('a'+i))))
	}
	r = h.do("POST", "/issues", c.author, postBody("post", "One too many"))
	assert.Equal(t, http.StatusTooManyRequests, r.Status, r.Raw)
	// Someone else is not affected, and the 5 are counted for the caller only.
	h.postIssue(c.mate, issueBody("Broken water pump in Hall G"))
	// A day later the slots are back.
	h.advance(25 * time.Hour)
	c.author = h.signIn(c.authorEmail).Tokens.AccessToken
	assert.Equal(t, http.StatusCreated, h.do("POST", "/issues", c.author, issueBody("Broken water pump in Hall H")).Status)
}

// refresh signs everyone in again (access tokens last 15 minutes of test time).
func (h *harness) refresh(c voiceCast) voiceCast {
	c.author = h.signIn(c.authorEmail).Tokens.AccessToken
	c.mate = h.signIn("mate@test.ac.bd").Tokens.AccessToken
	c.authority = h.signIn("proctor@test.ac.bd").Tokens.AccessToken
	c.mod = h.signIn("mod@test.ac.bd").Tokens.AccessToken
	return c
}
