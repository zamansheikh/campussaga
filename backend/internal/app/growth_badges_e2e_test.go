package app

import (
	"context"
	"fmt"
	"net/http"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

type gwBadges struct {
	Badges []struct {
		Key      string `json:"key"`
		Tier     int    `json:"tier"`
		Private  bool   `json:"private"`
		EarnedAt string `json:"earnedAt"`
	} `json:"badges"`
	Featured *struct {
		Key  string `json:"key"`
		Tier int    `json:"tier"`
	} `json:"featured"`
	All []struct {
		Key     string `json:"key"`
		Tiers   []int  `json:"tiers"`
		Private bool   `json:"private"`
	} `json:"all"`
}

func (h *harness) gwBadges(tok string) gwBadges {
	h.t.Helper()
	r := h.do("GET", "/me/badges", tok, nil)
	require.Equal(h.t, http.StatusOK, r.Status, r.Raw)
	var b gwBadges
	r.into(h.t, &b)
	return b
}

func (b gwBadges) tier(key string) (int, bool) {
	for _, x := range b.Badges {
		if x.Key == key {
			return x.Tier, true
		}
	}
	return 0, false
}

func (b gwBadges) has(key string) bool { _, ok := b.tier(key); return ok }

func TestGrowthBadges(t *testing.T) {
	h := newHarness(t)
	ctx := context.Background()
	uni := h.universityID("test-uni")
	admin := h.gwStudent("admin@test.ac.bd", "Admin One")
	h.sql(`UPDATE users SET role = 'admin' WHERE id = $1`, admin.ID)
	a := h.gwStudent("a@test.ac.bd", "Aisha Rahman")
	h.register(a.Tok, "a-en", "android", "en")
	h.register(a.Tok, "a-bn", "android", "bn")

	// The first computation seeds silently: verified and founding, no push.
	first := h.gwBadges(a.Tok)
	assert.True(t, first.has("verified"))
	assert.True(t, first.has("founding"))
	assert.Len(t, first.Badges, 2)
	assert.Nil(t, first.Featured)
	assert.Empty(t, h.pushes())
	// The catalog, for locked badges.
	require.Len(t, first.All, 14)
	byKey := map[string]struct {
		Tiers   []int
		Private bool
	}{}
	for _, x := range first.All {
		require.NotNil(t, x.Tiers, x.Key)
		byKey[x.Key] = struct {
			Tiers   []int
			Private bool
		}{x.Tiers, x.Private}
	}
	assert.Equal(t, []int{1, 3, 5}, byKey["life_saver"].Tiers)
	assert.Equal(t, []int{1, 10, 30}, byKey["bus_buddy"].Tiers)
	assert.Equal(t, []int{20, 40, 60}, byKey["section_builder"].Tiers)
	assert.Equal(t, []int{5, 25, 100}, byKey["connector"].Tiers)
	assert.Equal(t, []int{1, 3, 10}, byKey["bug_hunter"].Tiers)
	assert.Equal(t, []int{10, 50, 200}, byKey["helper"].Tiers)
	assert.True(t, byKey["helper"].Private)
	assert.True(t, byKey["campus_voice"].Private)
	assert.False(t, byKey["cr"].Private)
	assert.Empty(t, byKey["cr"].Tiers)

	// ---- role badges appear and disappear, with a push each time they appear ----
	g := h.createGroup(a.Tok)
	assert.True(t, h.gwBadges(a.Tok).has("cr"))
	ns := h.pushes()
	require.Len(t, ns, 2)
	titles := map[string]string{}
	for _, n := range ns {
		assert.Equal(t, "badge_earned", n.Data["type"])
		assert.Equal(t, "cr", n.Data["badge"])
		assert.Equal(t, "0", n.Data["tier"])
		titles[n.Token] = n.Title
	}
	assert.Equal(t, "New badge: CR", titles["a-en"])
	assert.Equal(t, "নতুন ব্যাজ: সিআর", titles["a-bn"])
	h.gwBadges(a.Tok)
	assert.Empty(t, h.pushes(), "no push when nothing changed")

	h.sql(`UPDATE class_group_members SET role = 'member' WHERE user_id = $1`, a.ID)
	assert.False(t, h.gwBadges(a.Tok).has("cr"), "the role ended")
	h.sql(`UPDATE class_group_members SET role = 'cr' WHERE user_id = $1`, a.ID)

	h.caAppoint(admin.Tok, caStudent{Tok: a.Tok, ID: a.ID})
	assert.True(t, h.gwBadges(a.Tok).has("campus_admin"))
	h.sql(`DELETE FROM campus_admins WHERE user_id = $1`, a.ID)
	assert.False(t, h.gwBadges(a.Tok).has("campus_admin"))

	h.sql(`INSERT INTO transport_reps (user_id, university_id) VALUES ($1, $2)`, a.ID, uni)
	assert.True(t, h.gwBadges(a.Tok).has("bus_rep"))
	h.sql(`DELETE FROM transport_reps WHERE user_id = $1`, a.ID)
	assert.False(t, h.gwBadges(a.Tok).has("bus_rep"))

	h.addStaff(admin.Tok, a.ID, "authority", "Proctor Office")
	assert.True(t, h.gwBadges(a.Tok).has("official"))
	h.sql(`DELETE FROM staff WHERE user_id = $1`, a.ID)
	assert.False(t, h.gwBadges(a.Tok).has("official"))

	h.bloodDonor(a.Tok, "O+", "01712345678", true, nil)
	assert.True(t, h.gwBadges(a.Tok).has("blood_donor"))
	h.pushes()

	// ---- tiers: life saver 1 / 3 / 5, kept at the best tier -------------------------
	h.sql(`UPDATE blood_donors SET donations = 1 WHERE user_id = $1`, a.ID)
	tier, ok := h.gwBadges(a.Tok).tier("life_saver")
	assert.True(t, ok)
	assert.Equal(t, 1, tier)
	ns = h.pushes()
	require.Len(t, ns, 2)
	assert.Equal(t, "life_saver", ns[0].Data["badge"])
	assert.Equal(t, "1", ns[0].Data["tier"])
	h.sql(`UPDATE blood_donors SET donations = 4 WHERE user_id = $1`, a.ID)
	tier, _ = h.gwBadges(a.Tok).tier("life_saver")
	assert.Equal(t, 2, tier)
	ns = h.pushes()
	require.Len(t, ns, 2)
	assert.Equal(t, "2", ns[0].Data["tier"])
	h.sql(`UPDATE blood_donors SET donations = 0 WHERE user_id = $1`, a.ID)
	tier, _ = h.gwBadges(a.Tok).tier("life_saver")
	assert.Equal(t, 2, tier, "activity badges keep their best tier")
	assert.Empty(t, h.pushes())
	h.sql(`UPDATE blood_donors SET donations = 5 WHERE user_id = $1`, a.ID)
	tier, _ = h.gwBadges(a.Tok).tier("life_saver")
	assert.Equal(t, 3, tier)
	h.pushes()

	for _, c := range []struct {
		trips, tier int
	}{{0, 0}, {1, 1}, {9, 1}, {10, 2}, {30, 3}} {
		h.sql(`INSERT INTO bus_share_stats (user_id, trips) VALUES ($1, $2) ON CONFLICT (user_id) DO UPDATE SET trips = EXCLUDED.trips`, a.ID, c.trips)
		got, has := h.gwBadges(a.Tok).tier("bus_buddy")
		assert.Equal(t, c.tier > 0, has, "trips %d", c.trips)
		assert.Equal(t, c.tier, got, "trips %d", c.trips)
	}

	// Section builder: CR of a group with N members.
	for i := range 18 {
		h.sql(`INSERT INTO class_group_members (group_id, user_id, role) VALUES ($1, $2, 'member')`, g.ID, h.gwFake(fmt.Sprintf("Member %d", i), h.Now()))
	}
	assert.False(t, h.gwBadges(a.Tok).has("section_builder"), "19 members including the CR")
	h.sql(`INSERT INTO class_group_members (group_id, user_id, role) VALUES ($1, $2, 'member')`, g.ID, h.gwFake("Member 19", h.Now()))
	tier, ok = h.gwBadges(a.Tok).tier("section_builder")
	assert.True(t, ok)
	assert.Equal(t, 1, tier)
	h.pushes()

	// Connector: qualified invites; a disqualified one doesn't count.
	for i := range 5 {
		q := h.Now()
		h.gwInvite(a.ID, fmt.Sprintf("Friend %d", i), h.Now(), &q, false)
	}
	tier, ok = h.gwBadges(a.Tok).tier("connector")
	assert.True(t, ok)
	assert.Equal(t, 1, tier)
	h.sql(`UPDATE referrals SET disqualified_at = now() WHERE referrer_id = $1`, a.ID)
	tier, _ = h.gwBadges(a.Tok).tier("connector")
	assert.Equal(t, 1, tier, "kept")
	h.pushes()

	// Bug hunter: a bug report the team marks done.
	f := h.fbSend(a.Tok, fbBody("bug", "The class routine does not open at all"))
	assert.False(t, h.gwBadges(a.Tok).has("bug_hunter"))
	require.Equal(t, http.StatusOK, h.do("PATCH", "/admin/feedback/"+f.ID, admin.Tok, map[string]string{"status": "done"}).Status)
	assert.True(t, h.gwBadges(a.Tok).has("bug_hunter"))
	idea := h.fbSend(a.Tok, fbBody("idea", "A dark mode would be really nice"))
	require.Equal(t, http.StatusOK, h.do("PATCH", "/admin/feedback/"+idea.ID, admin.Tok, map[string]string{"status": "done"}).Status)
	tier, _ = h.gwBadges(a.Tok).tier("bug_hunter")
	assert.Equal(t, 1, tier, "ideas don't count")
	h.pushes()

	// ---- private badges: from anonymous activity, aggregate counts only -------------
	h.voiceOn(true)
	poster := h.gwStudent("poster@test.ac.bd", "Post Author")
	post := h.postIssue(poster.Tok, postBody("post", "A question about the exam routine"))
	cm := h.comment(a.Tok, post.ID, map[string]any{"body": "Check the notice board"}) // anonymous
	require.Nil(t, cm.Author)
	for i := range 10 {
		h.sql(`INSERT INTO comment_likes (comment_id, user_id) VALUES ($1, $2)`, cm.ID, h.gwFake(fmt.Sprintf("Liker %d", i), h.Now()))
	}
	issue := h.postIssue(a.Tok, issueBody("The library AC has been broken"))
	assert.Nil(t, issue.Author)
	b := h.gwBadges(a.Tok)
	assert.False(t, b.has("campus_voice"))
	h.sql(`UPDATE issues SET status = 'solved', solved_at = now() WHERE id = $1`, issue.ID)
	b = h.gwBadges(a.Tok)
	for _, k := range []string{"helper", "campus_voice"} {
		tier, ok := b.tier(k)
		assert.True(t, ok, k)
		assert.Equal(t, 1, tier, k)
		for _, x := range b.Badges {
			if x.Key == k {
				assert.True(t, x.Private, k)
			}
		}
	}
	// A self-like doesn't count.
	h.sql(`INSERT INTO comment_likes (comment_id, user_id) VALUES ($1, $2)`, cm.ID, a.ID)
	tier, _ = h.gwBadges(a.Tok).tier("helper")
	assert.Equal(t, 1, tier)

	// ---- the featured badge ---------------------------------------------------------
	r := h.do("PUT", "/me/featured-badge", a.Tok, map[string]any{"key": "helper"})
	assert.Equal(t, "BADGE_PRIVATE", r.code())
	assert.Equal(t, "BADGE_NOT_HELD", h.do("PUT", "/me/featured-badge", a.Tok, map[string]any{"key": "campus_admin"}).code())
	assert.Equal(t, "BADGE_NOT_HELD", h.do("PUT", "/me/featured-badge", a.Tok, map[string]any{"key": "nonsense"}).code())
	r = h.do("PUT", "/me/featured-badge", a.Tok, map[string]any{"key": "life_saver"})
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	var fe struct {
		Featured *struct {
			Key  string `json:"key"`
			Tier int    `json:"tier"`
		} `json:"featured"`
	}
	r.into(t, &fe)
	require.NotNil(t, fe.Featured)
	assert.Equal(t, "life_saver", fe.Featured.Key)
	assert.Equal(t, 3, fe.Featured.Tier)
	b = h.gwBadges(a.Tok)
	require.NotNil(t, b.Featured)
	assert.Equal(t, "life_saver", b.Featured.Key)
	var mine struct {
		FeaturedBadge *struct {
			Key  string `json:"key"`
			Tier int    `json:"tier"`
		} `json:"featuredBadge"`
	}
	h.do("GET", "/me", a.Tok, nil).into(t, &mine)
	require.NotNil(t, mine.FeaturedBadge)
	assert.Equal(t, 3, mine.FeaturedBadge.Tier)

	// Show a role badge instead; when the role ends it drops off, with no error.
	r = h.do("PUT", "/me/featured-badge", a.Tok, map[string]any{"key": "cr"})
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	mine.FeaturedBadge = nil
	h.do("GET", "/me", a.Tok, nil).into(t, &mine)
	require.NotNil(t, mine.FeaturedBadge)
	assert.Equal(t, "cr", mine.FeaturedBadge.Key)
	h.sql(`UPDATE class_group_members SET role = 'member' WHERE user_id = $1`, a.ID)
	b = h.gwBadges(a.Tok)
	assert.False(t, b.has("cr"))
	assert.Nil(t, b.Featured)
	mine.FeaturedBadge = nil
	h.do("GET", "/me", a.Tok, nil).into(t, &mine)
	assert.Nil(t, mine.FeaturedBadge)
	var col *string
	require.NoError(t, h.app.DB.Pool.QueryRow(ctx, `SELECT featured_badge FROM users WHERE id = $1`, a.ID).Scan(&col))
	assert.Nil(t, col)
	// Clearing it takes null.
	require.Equal(t, http.StatusOK, h.do("PUT", "/me/featured-badge", a.Tok, map[string]any{"key": "verified"}).Status)
	r = h.do("PUT", "/me/featured-badge", a.Tok, map[string]any{"key": nil})
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	fe.Featured = &struct {
		Key  string `json:"key"`
		Tier int    `json:"tier"`
	}{}
	r.into(t, &fe)
	assert.Nil(t, fe.Featured)
}

// A badge earned later than the account's first computation, such as being
// verified by a vouch, sends a push; one given at signup does not.
func TestGrowthBadgeVerifiedPush(t *testing.T) {
	h := newHarness(t)
	uni := h.universityID("test-uni")
	v1 := h.gwStudent("v1@test.ac.bd", "Voucher One")
	v2 := h.gwStudent("v2@test.ac.bd", "Voucher Two")
	u := h.caUnverified("rafi@gmail.com", "Rafi Hasan", uni)
	h.register(u.Tok, "u-phone", "android", "en")
	b := h.gwBadges(u.Tok)
	assert.False(t, b.has("verified"))
	assert.True(t, b.has("founding"))
	h.pushes()
	cd := *h.caMine(u.Tok).Code
	require.Equal(t, http.StatusOK, h.do("POST", "/vouch/"+cd, v1.Tok, nil).Status)
	require.Equal(t, http.StatusOK, h.do("POST", "/vouch/"+cd, v2.Tok, nil).Status)
	var types []string
	for _, n := range h.pushes() {
		types = append(types, n.Data["type"])
		if n.Data["type"] == "badge_earned" {
			assert.Equal(t, "verified", n.Data["badge"])
			assert.Equal(t, "New badge: Verified student", n.Title)
		}
	}
	assert.Contains(t, types, "badge_earned", "the verified badge arrives with the verification")
	assert.True(t, h.gwBadges(u.Tok).has("verified"))
}

// The hourly sweep recomputes badges of students active in the last day.
func TestGrowthBadgeSweep(t *testing.T) {
	h := newHarness(t)
	a := h.gwStudent("a@test.ac.bd", "Aisha Rahman")
	idle := h.gwFake("Idle Student", h.Now()) // never opened the app
	h.register(a.Tok, "a-phone", "android", "en")
	h.gwBadges(a.Tok)
	h.pushes()
	g := h.createGroup(a.Tok)
	h.sql(`INSERT INTO class_group_members (group_id, user_id, role) VALUES ($1, $2, 'cr')`, g.ID, idle)
	h.advance(2 * time.Hour)
	h.gwSweep()
	ns := h.pushes()
	require.Len(t, ns, 1)
	assert.Equal(t, "cr", ns[0].Data["badge"])
	var n int
	require.NoError(t, h.app.DB.Pool.QueryRow(context.Background(), `SELECT count(*) FROM user_badges WHERE user_id = $1`, idle).Scan(&n))
	assert.Zero(t, n, "students who were not active are left to /me/badges")
}
