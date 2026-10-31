package app

import (
	"fmt"
	"net/http"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

type gwAuthor struct {
	ID            *string `json:"id"`
	Name          *string `json:"name"`
	Verified      bool    `json:"verified"`
	FeaturedBadge *struct {
		Key  string `json:"key"`
		Tier int    `json:"tier"`
	} `json:"featuredBadge"`
}

type gwProfile struct {
	ID         string `json:"id"`
	Name       string `json:"name"`
	Verified   bool   `json:"verified"`
	University *struct {
		ID   string `json:"id"`
		Name string `json:"name"`
		Slug string `json:"slug"`
	} `json:"university"`
	Department     *string `json:"department"`
	Batch          *string `json:"batch"`
	JoinedAt       string  `json:"joinedAt"`
	PhotoVersion   *string `json:"photoVersion"`
	GooglePhotoURL *string `json:"googlePhotoUrl"`
	FeaturedBadge  *struct {
		Key  string `json:"key"`
		Tier int    `json:"tier"`
	} `json:"featuredBadge"`
	Badges []struct {
		Key      string `json:"key"`
		Tier     int    `json:"tier"`
		EarnedAt string `json:"earnedAt"`
		Private  bool   `json:"private"`
	} `json:"badges"`
	Roles         []string `json:"roles"`
	InvitesJoined int      `json:"invitesJoined"`
	Posts         []struct {
		ID         string    `json:"id"`
		Kind       string    `json:"kind"`
		Title      string    `json:"title"`
		Preview    string    `json:"preview"`
		CampusOnly bool      `json:"campusOnly"`
		Author     *gwAuthor `json:"author"`
	} `json:"posts"`
}

func (h *harness) gwProfile(tok, id string) (gwProfile, *response) {
	h.t.Helper()
	r := h.do("GET", "/users/"+id+"/profile", tok, nil)
	var p gwProfile
	if r.Status == http.StatusOK {
		r.into(h.t, &p)
	}
	return p, r
}

func (p gwProfile) hasBadge(key string) bool {
	for _, b := range p.Badges {
		if b.Key == key {
			return true
		}
	}
	return false
}

func (p gwProfile) postIDs() []string {
	out := []string{}
	for _, x := range p.Posts {
		out = append(out, x.ID)
	}
	return out
}

func TestGrowthProfile(t *testing.T) {
	h := newHarness(t)
	h.voiceOn(true)
	h.visitOn(true)
	admin := h.gwStudent("admin@test.ac.bd", "Admin One")
	h.sql(`UPDATE users SET role = 'admin' WHERE id = $1`, admin.ID)
	p := h.gwStudent("p@test.ac.bd", "Priya Das")
	mate := h.gwStudent("mate@test.ac.bd", "Mate Student")
	stranger := h.gwStudent("stranger@test.ac.bd", "Stranger Two")
	_, other := h.caOtherUniversity()
	require.Equal(t, http.StatusOK, h.do("PATCH", "/me", p.Tok, map[string]string{"displayName": "Priya Das", "department": "CSE", "batch": "61"}).Status)
	h.sql(`UPDATE users SET photo_key = 'avatar-abcdef12.jpg', google_photo_url = 'https://example.com/p.jpg' WHERE id = $1`, p.ID)

	// Priya is CR of a group; her classmate joins it. She shows the CR badge.
	g := h.createGroup(p.Tok)
	require.Equal(t, http.StatusOK, h.do("POST", "/groups/join", mate.Tok, map[string]string{"code": g.JoinCode}).Status)
	require.Equal(t, http.StatusOK, h.do("PUT", "/me/featured-badge", p.Tok, map[string]any{"key": "cr"}).Status)

	// Named and anonymous content.
	named := h.postIssue(p.Tok, postBody("post", "Open to everyone, with my name", map[string]any{"anonymous": false}))
	campusOnly := h.postIssue(p.Tok, postBody("post", "Only our campus, with my name", map[string]any{"anonymous": false, "campusOnly": true}))
	namedIssue := h.postIssue(p.Tok, issueBody("Named complaint about the canteen", map[string]any{"anonymous": false}))
	anon := h.postIssue(p.Tok, postBody("post", "This one has no name on it"))
	anonIssue := h.postIssue(p.Tok, issueBody("Anonymous complaint about the lift"))
	require.Nil(t, anon.Author)
	require.Nil(t, anonIssue.Author)

	// ---- a classmate: photo, posts, badges, no email ----
	pr, r := h.gwProfile(mate.Tok, p.ID)
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	assert.Equal(t, p.ID, pr.ID)
	assert.Equal(t, "Priya Das", pr.Name)
	assert.True(t, pr.Verified)
	require.NotNil(t, pr.University)
	assert.Equal(t, "test-uni", pr.University.Slug)
	assert.Equal(t, "Test University", pr.University.Name)
	assert.Equal(t, "CSE", *pr.Department)
	assert.Equal(t, "61", *pr.Batch)
	assert.Regexp(t, `^\d{4}-\d{2}-01T00:00:00Z$`, pr.JoinedAt, "month precision")
	require.NotNil(t, pr.PhotoVersion)
	assert.Equal(t, "avatar-abcdef12.jpg", *pr.PhotoVersion)
	require.NotNil(t, pr.GooglePhotoURL)
	require.NotNil(t, pr.FeaturedBadge)
	assert.Equal(t, "cr", pr.FeaturedBadge.Key)
	assert.Equal(t, []string{"cr"}, pr.Roles)
	assert.True(t, pr.hasBadge("verified"))
	assert.True(t, pr.hasBadge("cr"))
	assert.Equal(t, 0, pr.InvitesJoined)
	assert.ElementsMatch(t, []string{named.ID, campusOnly.ID, namedIssue.ID}, pr.postIDs(), "named posts only, never the anonymous ones")
	for _, post := range pr.Posts {
		require.NotNil(t, post.Author)
		require.NotNil(t, post.Author.ID)
		assert.Equal(t, p.ID, *post.Author.ID)
	}
	assert.NotContains(t, r.Raw, "p@test.ac.bd")
	assert.NotContains(t, r.Raw, `"email"`)
	assert.NotContains(t, r.Raw, anon.ID)
	assert.NotContains(t, r.Raw, anonIssue.ID)

	// ---- a stranger of the same university: initials, same posts ----
	pr, r = h.gwProfile(stranger.Tok, p.ID)
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	assert.Nil(t, pr.PhotoVersion)
	assert.Nil(t, pr.GooglePhotoURL)
	assert.Len(t, pr.Posts, 3)
	assert.Equal(t, "Priya Das", pr.Name)

	// ---- another university: no photo, campus-only posts and issues filtered ----
	pr, r = h.gwProfile(other.Tok, p.ID)
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	assert.Nil(t, pr.PhotoVersion)
	assert.Equal(t, []string{named.ID}, pr.postIDs())
	h.visitOn(false)
	pr, _ = h.gwProfile(other.Tok, p.ID)
	assert.Empty(t, pr.Posts, "visits are off")
	assert.NotNil(t, pr.Posts)
	h.visitOn(true)

	// ---- an admin sees the photo; the owner sees theirs ----
	pr, _ = h.gwProfile(admin.Tok, p.ID)
	assert.NotNil(t, pr.PhotoVersion)
	pr, _ = h.gwProfile(p.Tok, p.ID)
	assert.NotNil(t, pr.PhotoVersion)

	// ---- private badges: only the owner ----
	poster := h.gwStudent("poster@test.ac.bd", "Post Author")
	topic := h.postIssue(poster.Tok, postBody("post", "What do you think about the new bus timing"))
	cm := h.comment(p.Tok, topic.ID, map[string]any{"body": "I think it is fine"})
	for i := range 10 {
		h.sql(`INSERT INTO comment_likes (comment_id, user_id) VALUES ($1, $2)`, cm.ID, h.gwFake(fmt.Sprintf("Liker %d", i), h.Now()))
	}
	own, _ := h.gwProfile(p.Tok, p.ID)
	assert.True(t, own.hasBadge("helper"), "the owner sees private badges")
	for _, b := range own.Badges {
		if b.Key == "helper" {
			assert.True(t, b.Private)
		}
	}
	for _, viewer := range []*gwUser{mate, stranger, admin} {
		pr, r = h.gwProfile(viewer.Tok, p.ID)
		assert.False(t, pr.hasBadge("helper"), "private badges are only for the owner")
		assert.NotContains(t, r.Raw, "helper")
	}
	// A private badge can't be the badge by the name, even if the database says so.
	h.sql(`UPDATE users SET featured_badge = 'helper' WHERE id = $1`, p.ID)
	pr, _ = h.gwProfile(mate.Tok, p.ID)
	assert.Nil(t, pr.FeaturedBadge)
	h.sql(`UPDATE users SET featured_badge = 'cr' WHERE id = $1`, p.ID)

	// ---- not found, blocked, bad id ----
	_, r = h.gwProfile(mate.Tok, "00000000-0000-0000-0000-0000000000aa")
	assert.Equal(t, http.StatusNotFound, r.Status)
	assert.Equal(t, "USER_NOT_FOUND", r.code())
	_, r = h.gwProfile(mate.Tok, "nope")
	assert.Equal(t, "VALIDATION_FAILED", r.code())
	assert.Equal(t, http.StatusUnauthorized, h.do("GET", "/users/"+p.ID+"/profile", "", nil).Status)
	h.sql(`UPDATE users SET blocked_at = now() WHERE id = $1`, stranger.ID)
	_, r = h.gwProfile(mate.Tok, stranger.ID)
	assert.Equal(t, http.StatusNotFound, r.Status)

	// ---- named authors carry an id and the badge; anonymous content none ----
	author := func(tok, id string) *gwAuthor {
		var is struct {
			Author *gwAuthor `json:"author"`
		}
		r := h.do("GET", "/issues/"+id, tok, nil)
		require.Equal(t, http.StatusOK, r.Status, r.Raw)
		r.into(t, &is)
		return is.Author
	}
	a := author(mate.Tok, named.ID)
	require.NotNil(t, a)
	require.NotNil(t, a.ID)
	assert.Equal(t, p.ID, *a.ID)
	assert.Equal(t, "Priya Das", *a.Name)
	require.NotNil(t, a.FeaturedBadge)
	assert.Equal(t, "cr", a.FeaturedBadge.Key)
	assert.Nil(t, author(mate.Tok, anon.ID))
	assert.Nil(t, author(mate.Tok, anonIssue.ID))
	// In the feed too.
	var feed struct {
		Items []struct {
			ID     string    `json:"id"`
			Author *gwAuthor `json:"author"`
		} `json:"items"`
	}
	h.do("GET", "/issues?sort=new&kinds=post,issue", mate.Tok, nil).into(t, &feed)
	seen := 0
	for _, it := range feed.Items {
		switch it.ID {
		case named.ID, campusOnly.ID, namedIssue.ID:
			require.NotNil(t, it.Author, it.ID)
			require.NotNil(t, it.Author.ID, it.ID)
			assert.Equal(t, p.ID, *it.Author.ID)
			seen++
		case anon.ID, anonIssue.ID:
			assert.Nil(t, it.Author, "anonymous stays anonymous")
			seen++
		}
	}
	assert.Equal(t, 5, seen)
	// Comments: a named one carries id and badge, an anonymous one nothing.
	namedCm := h.comment(p.Tok, topic.ID, map[string]any{"body": "With my name", "anonymous": false})
	require.NotNil(t, namedCm.Author)
	var cms struct {
		Items []struct {
			ID     string    `json:"id"`
			Author *gwAuthor `json:"author"`
		} `json:"items"`
	}
	h.do("GET", "/issues/"+topic.ID+"/comments", mate.Tok, nil).into(t, &cms)
	require.Len(t, cms.Items, 2)
	for _, c := range cms.Items {
		if c.ID == namedCm.ID {
			require.NotNil(t, c.Author)
			require.NotNil(t, c.Author.ID)
			assert.Equal(t, p.ID, *c.Author.ID)
			require.NotNil(t, c.Author.FeaturedBadge)
			assert.Equal(t, "cr", c.Author.FeaturedBadge.Key)
		} else {
			assert.Nil(t, c.Author, "the anonymous comment")
		}
	}
	assert.NotContains(t, h.do("GET", "/issues/"+topic.ID+"/comments", mate.Tok, nil).Raw, "helper")

	// ---- class group members carry the badge ----
	r = h.do("GET", "/groups/"+g.ID+"/members", p.Tok, nil)
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	var membersRes struct {
		Members []struct {
			UserID        string `json:"userId"`
			FeaturedBadge *struct {
				Key  string `json:"key"`
				Tier int    `json:"tier"`
			} `json:"featuredBadge"`
		} `json:"members"`
	}
	r.into(t, &membersRes)
	require.Len(t, membersRes.Members, 2)
	for _, m := range membersRes.Members {
		if m.UserID == p.ID {
			require.NotNil(t, m.FeaturedBadge)
			assert.Equal(t, "cr", m.FeaturedBadge.Key)
		} else {
			assert.Nil(t, m.FeaturedBadge)
		}
	}
	// The badge is gone when the role is: it stops showing (no error).
	h.sql(`UPDATE class_group_members SET role = 'member' WHERE user_id = $1`, p.ID)
	h.gwBadges(p.Tok)
	pr, _ = h.gwProfile(mate.Tok, p.ID)
	assert.Nil(t, pr.FeaturedBadge)
	assert.Nil(t, author(mate.Tok, named.ID).FeaturedBadge)
	assert.Empty(t, pr.Roles)
}
