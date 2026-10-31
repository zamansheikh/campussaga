package app

import (
	"context"
	"fmt"
	"net/http"
	"strings"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// Growth (docs/GROWTH.md): invites, badges, profiles, campaigns.

// ---- helpers -------------------------------------------------------------------------

type gwUser struct {
	Tok, Refresh, ID, Email string
}

// gwStudent signs in a verified student, names them and dates the account to
// the test clock (created_at is the database's own now() otherwise).
func (h *harness) gwStudent(email, name string) *gwUser {
	h.t.Helper()
	s := h.signIn(email)
	require.Equal(h.t, http.StatusOK, h.do("PATCH", "/me", s.Tokens.AccessToken, map[string]string{"displayName": name}).Status)
	h.sql(`UPDATE users SET created_at = $2 WHERE id = $1`, s.User.ID, h.Now())
	return &gwUser{Tok: s.Tokens.AccessToken, Refresh: s.Tokens.RefreshToken, ID: s.User.ID, Email: email}
}

func (h *harness) gwRefresh(u *gwUser) {
	h.t.Helper()
	r := h.do("POST", "/auth/refresh", "", map[string]string{"refreshToken": u.Refresh})
	require.Equal(h.t, http.StatusOK, r.Status, r.Raw)
	var t tokens
	r.into(h.t, &t)
	u.Tok, u.Refresh = t.AccessToken, t.RefreshToken
}

// gwNextDay moves the clock one day and has each student open the app.
func (h *harness) gwNextDay(users ...*gwUser) {
	h.t.Helper()
	h.advance(24 * time.Hour)
	for _, u := range users {
		h.gwRefresh(u)
		require.Equal(h.t, http.StatusOK, h.do("GET", "/me", u.Tok, nil).Status)
	}
}

// gwFake inserts a verified student straight into the database.
func (h *harness) gwFake(name string, at time.Time) string {
	h.t.Helper()
	var id string
	email := strings.ToLower(strings.ReplaceAll(name, " ", ".")) + fmt.Sprint(at.UnixNano()%100000) + "@test.ac.bd"
	require.NoError(h.t, h.app.DB.Pool.QueryRow(context.Background(), `INSERT INTO users (email, university_id, university_email, verified_at, display_name, created_at)
		SELECT $1, id, $1, $2, $3, $2 FROM universities WHERE slug = 'test-uni' RETURNING id`, email, at, name).Scan(&id))
	return id
}

// gwInvite records an invite by referrer of a new fake student.
func (h *harness) gwInvite(referrer, name string, created time.Time, qualified *time.Time, sameDevice bool) string {
	h.t.Helper()
	id := h.gwFake(name, created)
	h.sql(`INSERT INTO referrals (referred_id, referrer_id, source, created_at, qualified_at, same_device) VALUES ($1, $2, 'link', $3, $4, $5)`,
		id, referrer, created, qualified, sameDevice)
	return id
}

func (h *harness) gwSweep() {
	h.t.Helper()
	require.NoError(h.t, h.app.Growth.Sweep(context.Background()))
}

type gwReferrals struct {
	Code    string `json:"code"`
	Link    string `json:"link"`
	Invited int    `json:"invited"`
	Joined  int    `json:"joined"`
	Pending []struct {
		Name       string `json:"name"`
		Verified   bool   `json:"verified"`
		ActiveDays int    `json:"activeDays"`
	} `json:"pending"`
	Recent []struct {
		Name        string `json:"name"`
		QualifiedAt string `json:"qualifiedAt"`
	} `json:"recent"`
}

func (h *harness) gwReferrals(tok string) gwReferrals {
	h.t.Helper()
	r := h.do("GET", "/me/referrals", tok, nil)
	require.Equal(h.t, http.StatusOK, r.Status, r.Raw)
	var out gwReferrals
	r.into(h.t, &out)
	return out
}

func (h *harness) gwClaim(tok, code string) *response {
	h.t.Helper()
	return h.do("POST", "/me/referral", tok, map[string]string{"code": code, "source": "link"})
}

// ---- claim rules -----------------------------------------------------------------------

func TestGrowthReferralClaim(t *testing.T) {
	h := newHarness(t)
	a := h.gwStudent("a@test.ac.bd", "Aisha Rahman")
	b := h.gwStudent("b@test.ac.bd", "Bashar Khan")
	c := h.gwStudent("c@test.ac.bd", "Chowdhury Ali")

	// The code is made on first use: 8 characters, a link, and zero counts.
	ra := h.gwReferrals(a.Tok)
	assert.Regexp(t, `^[a-z0-9]{8}$`, ra.Code)
	assert.Equal(t, "https://varsitykotha.com/r/"+ra.Code, ra.Link)
	assert.Equal(t, ra.Code, h.gwReferrals(a.Tok).Code, "the code is made once")
	assert.Equal(t, 0, ra.Invited)
	assert.NotNil(t, ra.Pending)
	assert.NotNil(t, ra.Recent)
	var me struct {
		LeaderboardHidden bool    `json:"leaderboardHidden"`
		FeaturedBadge     any     `json:"featuredBadge"`
		ReferralCode      *string `json:"referralCode"`
	}
	r := h.do("GET", "/me", a.Tok, nil)
	r.into(t, &me)
	require.NotNil(t, me.ReferralCode)
	assert.Equal(t, ra.Code, *me.ReferralCode)
	assert.False(t, me.LeaderboardHidden)
	assert.Nil(t, me.FeaturedBadge)
	// A student whose code was never asked for still gets one on GET /me.
	var cme struct {
		ReferralCode *string `json:"referralCode"`
	}
	h.do("GET", "/me", c.Tok, nil).into(t, &cme)
	require.NotNil(t, cme.ReferralCode)
	assert.Regexp(t, `^[a-z0-9]{8}$`, *cme.ReferralCode)

	// Every error. Not found, self, then the happy path, then once only.
	assert.Equal(t, "REFERRAL_NOT_FOUND", h.gwClaim(b.Tok, "zzzzzzzz").code())
	assert.Equal(t, http.StatusNotFound, h.gwClaim(b.Tok, "zzzzzzzz").Status)
	assert.Equal(t, "REFERRAL_SELF", h.gwClaim(a.Tok, ra.Code).code())
	assert.Equal(t, "VALIDATION_FAILED", h.do("POST", "/me/referral", b.Tok, map[string]string{"code": ra.Code, "source": "sms"}).code())
	assert.Equal(t, http.StatusUnauthorized, h.do("POST", "/me/referral", "", map[string]string{"code": ra.Code}).Status)
	assert.Equal(t, http.StatusNoContent, h.gwClaim(b.Tok, strings.ToUpper(ra.Code)).Status, "codes are not case sensitive")
	r = h.gwClaim(b.Tok, ra.Code)
	assert.Equal(t, "ALREADY_REFERRED", r.code())
	assert.Equal(t, http.StatusConflict, r.Status)
	assert.Equal(t, "ALREADY_REFERRED", h.gwClaim(b.Tok, "zzzzzzzz").code(), "already referred wins")

	// Class invite source.
	rc := h.do("POST", "/me/referral", c.Tok, map[string]string{"code": ra.Code, "source": "join"})
	assert.Equal(t, http.StatusNoContent, rc.Status, rc.Raw)
	var src string
	require.NoError(t, h.app.DB.Pool.QueryRow(context.Background(), `SELECT source FROM referrals WHERE referred_id = $1`, c.ID).Scan(&src))
	assert.Equal(t, "join", src)

	// After a week it is too late.
	d := h.gwStudent("d@test.ac.bd", "Dina Sultana")
	h.sql(`UPDATE users SET created_at = $2 WHERE id = $1`, d.ID, h.Now().Add(-8*24*time.Hour))
	r = h.gwClaim(d.Tok, ra.Code)
	assert.Equal(t, "REFERRAL_TOO_LATE", r.code())
	assert.Less(t, r.Status, 500)
	assert.GreaterOrEqual(t, r.Status, 400)

	// The inviter must be a student, not blocked; admins are not.
	e := h.gwStudent("e@test.ac.bd", "Emon Hossain")
	f := h.gwStudent("f@test.ac.bd", "Farhana Islam")
	g := h.gwStudent("g@test.ac.bd", "Gias Uddin")
	codeE, codeF := h.gwReferrals(e.Tok).Code, h.gwReferrals(f.Tok).Code
	h.sql(`UPDATE users SET blocked_at = now() WHERE id = $1`, e.ID)
	h.sql(`UPDATE users SET role = 'admin' WHERE id = $1`, f.ID)
	assert.Equal(t, "REFERRAL_NOT_FOUND", h.gwClaim(g.Tok, codeE).code())
	assert.Equal(t, "REFERRAL_NOT_FOUND", h.gwClaim(g.Tok, codeF).code())

	// Counts: two invited, none joined yet; both pending, with 1 day each (today).
	ra = h.gwReferrals(a.Tok)
	assert.Equal(t, 2, ra.Invited)
	assert.Equal(t, 0, ra.Joined)
	require.Len(t, ra.Pending, 2)
	assert.True(t, ra.Pending[0].Verified)

	// The public lookup needs no sign-in and gives a name and a university.
	r = h.do("GET", "/referral/"+ra.Code, "", nil)
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	var pub struct {
		Name       string `json:"name"`
		University struct {
			Name string `json:"name"`
		} `json:"university"`
	}
	r.into(t, &pub)
	assert.Equal(t, "Aisha Rahman", pub.Name)
	assert.Equal(t, "Test University", pub.University.Name)
	assert.NotContains(t, r.Raw, "@")
	nf := h.do("GET", "/referral/zzzzzzzz", "", nil)
	assert.Equal(t, http.StatusNotFound, nf.Status)
	assert.Equal(t, "REFERRAL_NOT_FOUND", nf.code())
	assert.Equal(t, http.StatusNotFound, h.do("GET", "/referral/"+codeE, "", nil).Status, "a blocked inviter's page is generic")

	// leaderboardHidden is edited with PATCH /me.
	r = h.do("PATCH", "/me", a.Tok, map[string]any{"leaderboardHidden": true})
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	r.into(t, &me)
	assert.True(t, me.LeaderboardHidden)
	h.do("GET", "/me", a.Tok, nil).into(t, &me)
	assert.True(t, me.LeaderboardHidden)
}

// ---- same phone ------------------------------------------------------------------------

func TestGrowthReferralSameDevice(t *testing.T) {
	h := newHarness(t)
	admin := h.gwStudent("admin@test.ac.bd", "Admin One")
	h.sql(`UPDATE users SET role = 'admin' WHERE id = $1`, admin.ID)
	a := h.gwStudent("a@test.ac.bd", "Aisha Rahman")
	b := h.gwStudent("b@test.ac.bd", "Bashar Khan")
	c := h.gwStudent("c@test.ac.bd", "Chowdhury Ali")
	code := h.gwReferrals(a.Tok).Code

	// Aisha's phone is then used by Bashar (the push token moves to him).
	h.register(a.Tok, "shared-phone", "android", "en")
	h.register(b.Tok, "shared-phone", "android", "en")
	h.register(c.Tok, "own-phone", "android", "en")
	require.Equal(t, http.StatusNoContent, h.gwClaim(b.Tok, code).Status)
	require.Equal(t, http.StatusNoContent, h.gwClaim(c.Tok, code).Status)

	var flagB, flagC bool
	require.NoError(t, h.app.DB.Pool.QueryRow(context.Background(), `SELECT same_device FROM referrals WHERE referred_id = $1`, b.ID).Scan(&flagB))
	require.NoError(t, h.app.DB.Pool.QueryRow(context.Background(), `SELECT same_device FROM referrals WHERE referred_id = $1`, c.ID).Scan(&flagC))
	assert.True(t, flagB, "same phone")
	assert.False(t, flagC)

	// A claim made before the phone shows up is flagged when it does.
	d := h.gwStudent("d@test.ac.bd", "Dina Sultana")
	require.Equal(t, http.StatusNoContent, h.gwClaim(d.Tok, code).Status)
	h.register(d.Tok, "own-phone", "android", "en") // Chowdhury's phone
	h.register(a.Tok, "own-phone", "android", "en")
	for _, u := range []*gwUser{b, c, d} {
		h.sql(`INSERT INTO user_active_days (user_id, day) SELECT $1, (($2::timestamptz AT TIME ZONE 'Asia/Dhaka')::date + i) FROM generate_series(0, 2) i ON CONFLICT DO NOTHING`, u.ID, h.Now())
	}
	h.gwSweep()
	rows := map[string]bool{}
	rs, err := h.app.DB.Pool.Query(context.Background(), `SELECT referred_id::text, same_device FROM referrals`)
	require.NoError(t, err)
	for rs.Next() {
		var id string
		var f bool
		require.NoError(t, rs.Scan(&id, &f))
		rows[id] = f
	}
	rs.Close()
	assert.True(t, rows[b.ID])
	assert.True(t, rows[c.ID], "flagged when the second phone showed up")
	assert.True(t, rows[d.ID])

	// Never qualifies, and the admin sees it.
	h.pushes()
	assert.Equal(t, 0, h.gwReferrals(a.Tok).Joined)
	var q int
	require.NoError(t, h.app.DB.Pool.QueryRow(context.Background(), `SELECT count(*) FROM referrals WHERE qualified_at IS NOT NULL`).Scan(&q))
	assert.Zero(t, q)
	r := h.do("GET", "/admin/referrals?flag=same_device", admin.Tok, nil)
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	var page struct {
		Items []struct {
			Referred struct{ Name string } `json:"referred"`
			Referrer struct{ Name string } `json:"referrer"`
			Flags    []string              `json:"flags"`
		} `json:"items"`
		Total int `json:"total"`
	}
	r.into(t, &page)
	assert.Equal(t, 3, page.Total)
	assert.Contains(t, page.Items[0].Flags, "same_device")
	assert.Equal(t, "Aisha Rahman", page.Items[0].Referrer.Name)
}

// ---- qualification -----------------------------------------------------------------------

func TestGrowthReferralQualifies(t *testing.T) {
	h := newHarness(t)
	a := h.gwStudent("a@test.ac.bd", "Aisha Rahman")
	f := h.gwStudent("f@test.ac.bd", "Farid Hasan")
	code := h.gwReferrals(a.Tok).Code
	// Two phones for Aisha: one in each language.
	h.register(a.Tok, "a-en", "android", "en")
	h.register(a.Tok, "a-bn", "android", "bn")
	h.register(f.Tok, "f-phone", "android", "en")
	require.Equal(t, http.StatusNoContent, h.gwClaim(f.Tok, code).Status)

	// Day 1 was the claim itself (the app is open); 2 of 3 days is not enough.
	ra := h.gwReferrals(a.Tok)
	require.Len(t, ra.Pending, 1)
	assert.Equal(t, 1, ra.Pending[0].ActiveDays)
	h.gwNextDay(f, a)
	ra = h.gwReferrals(a.Tok)
	require.Len(t, ra.Pending, 1)
	assert.Equal(t, 2, ra.Pending[0].ActiveDays)
	assert.Equal(t, "Farid Hasan", ra.Pending[0].Name)
	assert.Empty(t, h.pushes(), "nothing yet")

	// Opening the app twice on one day adds no day; the third day qualifies at once.
	require.Equal(t, http.StatusOK, h.do("GET", "/me", f.Tok, nil).Status)
	assert.Equal(t, 2, h.gwReferrals(a.Tok).Pending[0].ActiveDays)
	h.gwNextDay(f)
	ns := h.pushes()
	require.Len(t, ns, 2)
	titles := map[string]string{}
	for _, n := range ns {
		assert.Equal(t, "referral_joined", n.Data["type"])
		titles[n.Token] = n.Title
	}
	assert.Equal(t, "Farid Hasan joined VarsityKotha with your link", titles["a-en"])
	assert.Equal(t, "Farid Hasan তোমার লিংক দিয়ে ভার্সিটি কথায় যোগ দিয়েছে", titles["a-bn"])

	h.gwRefresh(a)
	ra = h.gwReferrals(a.Tok)
	assert.Equal(t, 1, ra.Joined)
	assert.Equal(t, 1, ra.Invited)
	assert.Empty(t, ra.Pending)
	require.Len(t, ra.Recent, 1)
	assert.Equal(t, "Farid Hasan", ra.Recent[0].Name)

	// It is counted once: a fourth day sends nothing.
	h.gwNextDay(f)
	assert.Empty(t, h.pushes())
}

func TestGrowthReferralWindowAndVerification(t *testing.T) {
	h := newHarness(t)
	ctx := context.Background()
	uni := h.universityID("test-uni")
	a := h.gwStudent("a@test.ac.bd", "Aisha Rahman")
	v1 := h.gwStudent("v1@test.ac.bd", "Voucher One")
	v2 := h.gwStudent("v2@test.ac.bd", "Voucher Two")
	code := h.gwReferrals(a.Tok).Code
	h.register(a.Tok, "a-phone", "android", "en")
	day := func(u string, n int) {
		h.sql(`INSERT INTO user_active_days (user_id, day) VALUES ($1, ($2::timestamptz AT TIME ZONE 'Asia/Dhaka')::date + $3::int) ON CONFLICT DO NOTHING`, u, h.Now(), n)
	}
	joined := func() int { return h.gwReferrals(a.Tok).Joined }

	// Not verified: three active days are not enough, however long they take.
	u := h.caUnverified("rafi@gmail.com", "Rafi Hasan", uni)
	h.sql(`UPDATE users SET created_at = $2 WHERE id = $1`, u.ID, h.Now())
	require.Equal(t, http.StatusNoContent, h.gwClaim(u.Tok, code).Status)
	for i := range 3 {
		day(u.ID, i)
	}
	h.gwSweep()
	assert.Zero(t, joined())
	assert.Empty(t, h.pushes())
	h.gwRefresh(a)
	pend := h.gwReferrals(a.Tok).Pending
	require.Len(t, pend, 1)
	assert.False(t, pend[0].Verified)
	assert.Equal(t, 3, pend[0].ActiveDays)

	// Verified later (two vouches), still inside the 14 days: qualifies at once.
	cd := *h.caMine(u.Tok).Code
	require.Equal(t, http.StatusOK, h.do("POST", "/vouch/"+cd, v1.Tok, nil).Status)
	assert.Zero(t, joined())
	require.Equal(t, http.StatusOK, h.do("POST", "/vouch/"+cd, v2.Tok, nil).Status)
	ns := h.pushes()
	var joinedPush bool
	for _, n := range ns {
		if n.Data["type"] == "referral_joined" {
			joinedPush = true
			assert.Equal(t, "Rafi Hasan joined VarsityKotha with your link", n.Title)
		}
	}
	assert.True(t, joinedPush, "referral_joined after verification")
	assert.Equal(t, 1, joined())

	// Verified after 14 days: never counts (the days were all inside the window).
	late := h.caUnverified("late@gmail.com", "Late Student", uni)
	h.sql(`UPDATE users SET created_at = $2 WHERE id = $1`, late.ID, h.Now())
	require.Equal(t, http.StatusNoContent, h.gwClaim(late.Tok, code).Status)
	for i := range 3 {
		day(late.ID, i)
	}
	h.sql(`UPDATE users SET verified_at = $2, university_email = 'late@test.ac.bd' WHERE id = $1`, late.ID, h.Now().Add(15*24*time.Hour))
	h.advance(16 * 24 * time.Hour)
	h.gwSweep()
	var qa *time.Time
	require.NoError(t, h.app.DB.Pool.QueryRow(ctx, `SELECT qualified_at FROM referrals WHERE referred_id = $1`, late.ID).Scan(&qa))
	assert.Nil(t, qa)

	// Only two days inside the window, a third on day 15: never.
	slow := h.gwStudent("slow@test.ac.bd", "Slow Student")
	require.Equal(t, http.StatusNoContent, h.gwClaim(slow.Tok, code).Status)
	day(slow.ID, 1)
	day(slow.ID, 15)
	h.gwSweep()
	require.NoError(t, h.app.DB.Pool.QueryRow(ctx, `SELECT qualified_at FROM referrals WHERE referred_id = $1`, slow.ID).Scan(&qa))
	assert.Nil(t, qa)

	// A disqualified invite does not qualify, and counts again once restored.
	fresh := h.gwStudent("fresh@test.ac.bd", "Fresh Student")
	require.Equal(t, http.StatusNoContent, h.gwClaim(fresh.Tok, code).Status)
	for i := range 3 {
		day(fresh.ID, i)
	}
	h.sql(`UPDATE referrals SET disqualified_at = now() WHERE referred_id = $1`, fresh.ID)
	h.gwSweep()
	require.NoError(t, h.app.DB.Pool.QueryRow(ctx, `SELECT qualified_at FROM referrals WHERE referred_id = $1`, fresh.ID).Scan(&qa))
	assert.Nil(t, qa)
	h.sql(`UPDATE referrals SET disqualified_at = NULL WHERE referred_id = $1`, fresh.ID)
	h.gwSweep()
	require.NoError(t, h.app.DB.Pool.QueryRow(ctx, `SELECT qualified_at FROM referrals WHERE referred_id = $1`, fresh.ID).Scan(&qa))
	assert.NotNil(t, qa)
}

// Active days are kept 30 days and written once per day.
func TestGrowthActiveDaysKept(t *testing.T) {
	h := newHarness(t)
	u := h.gwStudent("a@test.ac.bd", "Aisha Rahman")
	for range 3 {
		require.Equal(t, http.StatusOK, h.do("GET", "/me", u.Tok, nil).Status)
	}
	var n int
	require.NoError(t, h.app.DB.Pool.QueryRow(context.Background(), `SELECT count(*) FROM user_active_days WHERE user_id = $1`, u.ID).Scan(&n))
	assert.Equal(t, 1, n)
	h.sql(`INSERT INTO user_active_days (user_id, day) VALUES ($1, ($2::timestamptz AT TIME ZONE 'Asia/Dhaka')::date - 31)`, u.ID, h.Now())
	h.gwSweep()
	require.NoError(t, h.app.DB.Pool.QueryRow(context.Background(), `SELECT count(*) FROM user_active_days WHERE user_id = $1`, u.ID).Scan(&n))
	assert.Equal(t, 1, n, "the day older than 30 is gone")
}
