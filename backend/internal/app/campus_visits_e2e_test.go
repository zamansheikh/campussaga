package app

import (
	"context"
	"fmt"
	"net/http"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// Visit other campuses (docs/CAMPUS_VISITS.md).

func (h *harness) sql(q string, args ...any) {
	h.t.Helper()
	_, err := h.app.DB.Pool.Exec(context.Background(), q, args...)
	require.NoError(h.t, err)
}

// onlyTestUni drops the universities the migrations seed, so lists are predictable.
func (h *harness) onlyTestUni() {
	h.t.Helper()
	h.sql(`DELETE FROM universities WHERE slug <> 'test-uni'`)
}

func (h *harness) visitOn(on bool) {
	h.t.Helper()
	h.sql(`UPDATE app_config SET value = jsonb_set(value, '{visitCampus}', $1::jsonb) WHERE key = 'features'`, fmt.Sprint(on))
}

// addUni creates a university (with the email domain slug.ac.bd) and returns its id.
func (h *harness) addUni(slug, name string, extra ...string) string {
	h.t.Helper()
	city := "Dhaka"
	if len(extra) > 0 {
		city = extra[0]
	}
	h.sql(`WITH u AS (INSERT INTO universities (slug, name, name_bn, city, kind, website) VALUES ($1, $2, $2, $3, 'private', $1 || '.ac.bd') RETURNING id)
		INSERT INTO university_domains (domain, university_id) SELECT $1 || '.ac.bd', id FROM u`, slug, name, city)
	return h.universityID(slug)
}

type campusJSON struct {
	ID          string  `json:"id"`
	Slug        string  `json:"slug"`
	Name        string  `json:"name"`
	NameBn      *string `json:"nameBn"`
	City        string  `json:"city"`
	Kind        string  `json:"kind"`
	Students    int     `json:"students"`
	Posts7d     int     `json:"posts7d"`
	Website     string  `json:"website"`
	ClassGroups int     `json:"classGroups"`
	BusRoutes   int     `json:"busRoutes"`
	Mine        bool    `json:"mine"`
}

func (h *harness) campuses(tok, query string) voicePage[campusJSON] {
	h.t.Helper()
	r := h.do("GET", "/campuses"+query, tok, nil)
	require.Equal(h.t, http.StatusOK, r.Status, r.Raw)
	var p voicePage[campusJSON]
	r.into(h.t, &p)
	return p
}

type visitorIssue struct {
	issueJSON
	CampusOnly bool `json:"campusOnly"`
	Visitor    bool `json:"visitor"`
}

func ids(items []issueJSON) []string {
	out := make([]string, 0, len(items))
	for _, it := range items {
		out = append(out, it.ID)
	}
	return out
}

func TestCampusVisitorReadsAndReacts(t *testing.T) {
	h := newHarness(t)
	c := newVoiceCast(h)
	other := h.addUni("other", "Other University")
	visitor := h.named("visitor@other.ac.bd", "Visitor Vee")
	visitorID := h.me(visitor).ID
	home := h.universityID("test-uni")
	q := "?universityId=" + home

	post := h.postIssue(c.author, postBody("post", "Fresh samosas at the canteen"))
	question := h.postIssue(c.author, postBody("question", "Where is the physics lab?"))
	poll := h.postIssue(c.author, pollBody("Best canteen day?", "Friday", "Saturday"))
	secret := h.postIssue(c.author, postBody("post", "Only for us here", map[string]any{"campusOnly": true}))
	issue := h.postIssue(c.author, issueBody("Broken water pump in Hall 3"))
	safety := h.postIssue(c.author, issueBody("Someone follows students at night", map[string]any{"category": "safety"}))
	hidden := h.postIssue(c.author, postBody("post", "This one gets hidden"))
	removed := h.postIssue(c.author, postBody("post", "This one gets deleted"))
	h.sql(`UPDATE issues SET visibility = 'hidden' WHERE id = $1`, hidden.ID)
	require.Equal(t, http.StatusNoContent, h.do("DELETE", "/issues/"+removed.ID, c.author, nil).Status)
	held := h.postIssue(c.author, postBody("post", "This one is held"))
	h.sql(`UPDATE issues SET visibility = 'held', hold_reason = 'moderator' WHERE id = $1`, held.ID)
	answer := h.comment(c.mate, question.ID, map[string]any{"body": "Block C, third floor."})
	require.Equal(t, http.StatusOK, h.do("POST", "/issues/"+poll.ID+"/poll-vote", c.mate, map[string]string{"optionId": poll.Poll.Options[0].ID}).Status)

	// campusOnly is ignored for issues, kept for posts.
	var own visitorIssue
	h.do("GET", "/issues/"+secret.ID, c.mate, nil).into(t, &own)
	assert.True(t, own.CampusOnly)
	assert.False(t, own.Visitor)
	h.do("GET", "/issues/"+issue.ID, c.mate, nil).into(t, &own)
	assert.False(t, own.CampusOnly)
	asIssue := h.postIssue(c.author, issueBody("Cracked tiles in the corridor", map[string]any{"campusOnly": true}))
	h.do("GET", "/issues/"+asIssue.ID, c.mate, nil).into(t, &own)
	assert.False(t, own.CampusOnly, "ignored for issues")

	// The feed: posts, questions and polls only.
	want := []string{poll.ID, question.ID, post.ID}
	for _, query := range []string{q + "&kinds=all&sort=new", q + "&kinds=post,question,poll&sort=new", q + "&kinds=all", q + "&kinds=all&sort=new&category=general"} {
		got := h.feed(visitor, query)
		assert.ElementsMatch(t, want, ids(got), query)
	}
	assert.ElementsMatch(t, []string{question.ID}, ids(h.feed(visitor, q+"&kinds=all&sort=new&q=physics")))
	assert.Empty(t, h.feed(visitor, q+"&kinds=issue&sort=new"))
	assert.Empty(t, h.feed(visitor, q+"&kinds=issue"))
	assert.Empty(t, h.feed(visitor, q+"&kinds=all&sort=solved"))
	assert.Empty(t, h.feed(visitor, q+"&kinds=all&private=true"))
	assert.Empty(t, h.feed(visitor, q+"&kinds=all&category=safety"))
	for _, it := range h.feed(visitor, q+"&kinds=all&sort=new") {
		assert.True(t, it.Visibility == "visible")
	}
	var raw voicePage[visitorIssue]
	h.do("GET", "/issues"+q+"&kinds=all&sort=new", visitor, nil).into(t, &raw)
	for _, it := range raw.Items {
		assert.True(t, it.Visitor)
		assert.False(t, it.Mine)
		assert.False(t, it.Following)
	}
	// The home university still sees everything, including the campus-only one.
	home1 := h.feed(c.mate, "?kinds=all&sort=new")
	assert.Contains(t, ids(home1), secret.ID)
	assert.NotContains(t, ids(h.feed(c.mate, "?kinds=all&sort=new&universityId="+other)), secret.ID, "a student's universityId elsewhere is a visit too")

	// Details: only what the feed shows.
	for _, id := range []string{issue.ID, safety.ID, secret.ID, hidden.ID, removed.ID, held.ID, asIssue.ID} {
		assert.Equal(t, "ISSUE_NOT_FOUND", h.do("GET", "/issues/"+id, visitor, nil).code(), id)
		assert.Equal(t, "ISSUE_NOT_FOUND", h.do("GET", "/issues/"+id+"/comments", visitor, nil).code(), id)
	}
	var d struct {
		visitorIssue
		Can map[string]bool `json:"can"`
	}
	r := h.do("GET", "/issues/"+poll.ID, visitor, nil)
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	r.into(t, &d)
	assert.True(t, d.Visitor)
	assert.False(t, d.Mine)
	assert.False(t, d.Following)
	require.NotEmpty(t, d.Can)
	for k, v := range d.Can {
		assert.False(t, v, k)
	}
	require.NotNil(t, d.Poll)
	assert.Nil(t, d.Poll.MyVote)
	for _, o := range d.Poll.Options {
		require.NotNil(t, o.Votes, "visitors see the results")
	}
	assert.Equal(t, 1, d.Poll.TotalVotes)
	cms := h.comments(visitor, question.ID)
	require.Len(t, cms, 1)
	assert.Equal(t, answer.ID, cms[0].ID)
	assert.False(t, cms[0].Mine)

	// Reactions work and count; so do reports.
	r, res := h.react(visitor, post.ID, map[string]string{"reaction": "wow"})
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	assert.Equal(t, 1, res.Reactions["wow"])
	assert.Equal(t, 1, h.getIssue(c.mate, post.ID).Reactions["wow"])
	got := h.getIssue(visitor, post.ID)
	require.NotNil(t, got.MyReaction)
	assert.Equal(t, "wow", *got.MyReaction)
	assert.False(t, got.Following, "a visitor follows nothing")
	assert.Equal(t, http.StatusOK, h.do("DELETE", "/issues/"+post.ID+"/vote", visitor, nil).Status)
	assert.Equal(t, 0, h.getIssue(c.mate, post.ID).Reactions["wow"])
	assert.Equal(t, http.StatusNoContent, h.do("POST", "/issues/"+post.ID+"/report", visitor, map[string]string{"reason": "spam"}).Status)
	assert.Equal(t, http.StatusNoContent, h.do("POST", "/issues/"+question.ID+"/comments/"+answer.ID+"/report", visitor, map[string]string{"reason": "spam"}).Status)
	assert.Equal(t, "ISSUE_NOT_FOUND", h.do("POST", "/issues/"+secret.ID+"/report", visitor, map[string]string{"reason": "spam"}).code())
	assert.Equal(t, "ISSUE_NOT_FOUND", h.do("PUT", "/issues/"+secret.ID+"/vote", visitor, nil).code())

	// Everything else is read-only.
	readOnly := []struct {
		method, path string
		body         any
	}{
		{"POST", "/issues/" + question.ID + "/comments", map[string]any{"body": "Thanks"}},
		{"POST", "/issues/" + question.ID + "/comments", map[string]any{"body": "Reply", "parentId": answer.ID}},
		{"PUT", "/issues/" + question.ID + "/comments/" + answer.ID + "/like", nil},
		{"DELETE", "/issues/" + question.ID + "/comments/" + answer.ID + "/like", nil},
		{"POST", "/issues/" + poll.ID + "/poll-vote", map[string]string{"optionId": poll.Poll.Options[1].ID}},
		{"PUT", "/issues/" + post.ID + "/follow", nil},
		{"DELETE", "/issues/" + post.ID + "/follow", nil},
		{"PATCH", "/issues/" + post.ID, map[string]string{"body": "Edited by a stranger"}},
		{"DELETE", "/issues/" + post.ID, nil},
		{"POST", "/issues/" + post.ID + "/reopen", map[string]string{"note": "again"}},
	}
	for _, w := range readOnly {
		res := h.do(w.method, w.path, visitor, w.body)
		assert.Equal(t, http.StatusForbidden, res.Status, "%s %s: %s", w.method, w.path, res.Raw)
		assert.Equal(t, "VISITOR_READ_ONLY", res.code(), "%s %s", w.method, w.path)
	}
	assert.Equal(t, 1, h.getIssue(c.mate, question.ID).CommentCount, "nothing was written")
	assert.Equal(t, 1, h.getIssue(c.mate, poll.ID).Poll.TotalVotes)

	// The flag off: visitors see nothing; staff and the home university are unaffected.
	h.visitOn(false)
	assert.Equal(t, "ISSUE_NOT_FOUND", h.do("GET", "/issues/"+post.ID, visitor, nil).code())
	assert.Equal(t, "ISSUE_NOT_FOUND", h.do("GET", "/issues/"+post.ID+"/comments", visitor, nil).code())
	assert.Equal(t, "ISSUE_NOT_FOUND", h.do("PUT", "/issues/"+post.ID+"/vote", visitor, nil).code())
	assert.Equal(t, "FEATURE_DISABLED", h.do("GET", "/issues"+q+"&kinds=all", visitor, nil).code())
	assert.Equal(t, "FEATURE_DISABLED", h.do("GET", "/campuses", visitor, nil).code())
	assert.Equal(t, "FEATURE_DISABLED", h.do("GET", "/campuses/test-uni", visitor, nil).code())
	assert.Equal(t, http.StatusOK, h.do("GET", "/campuses", c.mod, nil).Status)
	assert.Equal(t, http.StatusOK, h.do("GET", "/issues/"+post.ID, c.mate, nil).Status)
	assert.NotEmpty(t, h.feed(c.mate, "?kinds=all&sort=new"))
	h.visitOn(true)
	assert.Equal(t, http.StatusOK, h.do("GET", "/issues/"+post.ID, visitor, nil).Status)
	_ = visitorID
}

func TestCampusListOrderAndSearch(t *testing.T) {
	h := newHarness(t)
	h.onlyTestUni()
	c := newVoiceCast(h)
	mk := func(slug, name string, students int, city string) string {
		id := h.addUni(slug, name, city)
		h.sql(`INSERT INTO users (email, university_id, verified_at) SELECT $1 || g || '@x.test', $2, now() FROM generate_series(1, $3::int) g`, slug, id, students)
		return id
	}
	zeta := mk("zeta", "Zeta University", 3, "Khulna")
	alpha := mk("alpha", "Alpha University", 3, "Sylhet")
	mk("beta", "Beta University", 1, "Dhaka")
	busy := mk("busy", "Busy University", 1, "Dhaka")
	camp := mk("camp", "Camp University", 1, "Dhaka")
	demo := mk("demo", "Demo University", 9, "Dhaka")
	dead := mk("dead", "Dead University", 9, "Dhaka")
	h.sql(`UPDATE universities SET is_demo = true WHERE id = $1`, demo)
	h.sql(`UPDATE universities SET is_active = false WHERE id = $1`, dead)
	post := func(uni, kind string, campusOnly bool, visibility string) {
		h.sql(`INSERT INTO issues (university_id, kind, category, private, title, body, campus_only, visibility, created_at, status_changed_at)
			VALUES ($1, $2, 'general', false, '', 'hello there', $3, $4, $5, $5)`, uni, kind, campusOnly, visibility, h.Now())
	}
	post(busy, "post", false, "visible")
	post(busy, "question", false, "visible")
	// None of these count: campus-only, hidden, older than a week, issues, safety.
	post(camp, "post", true, "visible")
	post(camp, "post", false, "hidden")
	h.sql(`INSERT INTO issues (university_id, kind, category, private, title, body, created_at, status_changed_at)
		VALUES ($1, 'post', 'general', false, '', 'old', $2, $2)`, camp, h.Now().AddDate(0, 0, -8))
	h.sql(`INSERT INTO issues (university_id, kind, category, private, title, body, created_at, status_changed_at)
		VALUES ($1, 'issue', 'hostel', false, 'A broken pump', 'The water pump has been broken a week', $2, $2),
		       ($1, 'issue', 'safety', true, 'Someone follows us', 'Someone follows students at night in the lane', $2, $2)`, camp, h.Now())
	post(dead, "post", false, "visible")
	post(demo, "post", false, "visible")
	_ = zeta
	_ = alpha

	p := h.campuses(c.mate, "")
	var slugs []string
	for _, it := range p.Items {
		slugs = append(slugs, it.Slug)
	}
	assert.Equal(t, []string{"busy", "alpha", "zeta", "beta", "camp"}, slugs, "posts7d, students, name; no own, demo or inactive")
	assert.Nil(t, p.NextCursor)
	assert.Equal(t, 2, p.Items[0].Posts7d)
	assert.Equal(t, 1, p.Items[0].Students)
	assert.Equal(t, 3, p.Items[1].Students)
	assert.Equal(t, 0, p.Items[4].Posts7d)
	assert.Equal(t, "private", p.Items[0].Kind)

	for q, want := range map[string][]string{
		"?q=sylhet":   {"alpha"},
		"?q=ZETA":     {"zeta"},
		"?q=univers":  {"busy", "alpha", "zeta", "beta", "camp"},
		"?q=khulna":   {"zeta"},
		"?q=nothing":  {},
		"?q=test-uni": {},
		"?q=%25":      {},
	} {
		var got []string
		for _, it := range h.campuses(c.mate, q).Items {
			got = append(got, it.Slug)
		}
		assert.Equal(t, want, append([]string{}, got...), q)
		if len(want) == 0 {
			assert.Empty(t, got, q)
		}
	}
	assert.Equal(t, "BAD_CURSOR", h.do("GET", "/campuses?cursor=zzz", c.mate, nil).code())
	assert.Equal(t, http.StatusUnauthorized, h.do("GET", "/campuses", "", nil).Status)
}

func TestCampusListPagination(t *testing.T) {
	h := newHarness(t)
	h.onlyTestUni()
	c := newVoiceCast(h)
	h.sql(`INSERT INTO universities (slug, name) SELECT 'page' || to_char(g, 'FM00'), 'Page ' || to_char(g, 'FM00') FROM generate_series(1, 35) g`)
	first := h.campuses(c.mate, "")
	require.Len(t, first.Items, 30)
	require.NotNil(t, first.NextCursor)
	second := h.campuses(c.mate, "?cursor="+*first.NextCursor)
	require.Len(t, second.Items, 5)
	assert.Nil(t, second.NextCursor)
	assert.Equal(t, "page01", first.Items[0].Slug)
	assert.Equal(t, "page31", second.Items[0].Slug)
	assert.Equal(t, "page35", second.Items[4].Slug)
}

func TestCampusProfile(t *testing.T) {
	h := newHarness(t)
	h.onlyTestUni()
	c := newVoiceCast(h)
	id := h.addUni("kuet", "Khulna Engineering", "Khulna")
	h.sql(`INSERT INTO users (email, university_id, verified_at) SELECT 'k' || g || '@x.test', $1, now() FROM generate_series(1, 4) g`, id)
	h.sql(`INSERT INTO class_groups (university_id, department, batch, semester, join_code) VALUES
		($1, 'CSE', '20', '5th', 'ABCDEF'), ($1, 'EEE', '21', '3rd', 'GHJKLM')`, id)
	h.sql(`INSERT INTO bus_routes (university_id, name) VALUES ($1, 'Route 1'), ($1, 'Route 2'), ($1, 'Route 3')`, id)
	h.sql(`INSERT INTO issues (university_id, kind, category, private, title, body, created_at, status_changed_at)
		VALUES ($1, 'post', 'general', false, '', 'hi', $2, $2), ($1, 'question', 'general', false, '', 'question?', $2, $2)`, id, h.Now())
	h.sql(`INSERT INTO issues (university_id, kind, category, private, title, body, created_at, status_changed_at)
		VALUES ($1, 'issue', 'hostel', false, 'A broken pump', 'The water pump has been broken a week', $2, $2)`, id, h.Now())

	r := h.do("GET", "/campuses/kuet", c.mate, nil)
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	var p campusJSON
	r.into(t, &p)
	assert.Equal(t, id, p.ID)
	assert.Equal(t, "Khulna Engineering", p.Name)
	assert.Equal(t, "Khulna", p.City)
	assert.Equal(t, "private", p.Kind)
	assert.Equal(t, "https://kuet.ac.bd", p.Website)
	assert.Equal(t, 4, p.Students)
	assert.Equal(t, 2, p.ClassGroups)
	assert.Equal(t, 3, p.BusRoutes)
	assert.Equal(t, 2, p.Posts7d)
	assert.False(t, p.Mine)

	r = h.do("GET", "/campuses/test-uni", c.mate, nil)
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	var mine campusJSON
	r.into(t, &mine)
	assert.True(t, mine.Mine)
	assert.Equal(t, "Test University", mine.Name)

	nf := h.do("GET", "/campuses/nope", c.mate, nil)
	assert.Equal(t, http.StatusNotFound, nf.Status)
	assert.Equal(t, "UNIVERSITY_NOT_FOUND", nf.code())
	h.sql(`UPDATE universities SET is_demo = true WHERE slug = 'kuet'`)
	assert.Equal(t, "UNIVERSITY_NOT_FOUND", h.do("GET", "/campuses/kuet", c.mate, nil).code())
}
