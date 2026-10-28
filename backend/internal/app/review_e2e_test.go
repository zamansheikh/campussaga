package app

import (
	"context"
	"net/http"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/zamansheikh/varsitykotha/backend/internal/platform/config"
)

const (
	reviewEmail = "play-review@review.varsitykotha.com"
	reviewCode  = "483920"
)

// reviewHarness has review sign-in on and the demo university in place.
func reviewHarness(t *testing.T) *harness {
	t.Helper()
	h := newHarnessFull(t, nil, func(c *config.Config) {
		c.ReviewEmail, c.ReviewCode = reviewEmail, reviewCode
	})
	h.addDemoUniversity()
	return h
}

func (h *harness) addDemoUniversity() {
	h.t.Helper()
	_, err := h.app.DB.Pool.Exec(context.Background(), `
		WITH u AS (INSERT INTO universities (slug, name, is_demo) VALUES ('demo-review', 'VarsityKotha Demo University', true) RETURNING id)
		INSERT INTO university_domains (domain, university_id) SELECT 'review.varsitykotha.com', id FROM u`)
	require.NoError(h.t, err)
}

func (h *harness) verifyReq(email, code string) *response {
	return h.do("POST", "/auth/verify", "", map[string]string{"email": email, "code": code})
}

func (h *harness) signInReview() signedIn {
	h.t.Helper()
	require.Equal(h.t, http.StatusAccepted, h.do("POST", "/auth/code", "", map[string]string{"email": reviewEmail}).Status)
	r := h.verifyReq(reviewEmail, reviewCode)
	require.Equal(h.t, http.StatusOK, r.Status, r.Raw)
	var s signedIn
	r.into(h.t, &s)
	return s
}

func TestReviewSignInDisabledByDefault(t *testing.T) {
	h := newHarness(t)
	h.addDemoUniversity()

	// The demo domain is not a way in: nobody can request a code for it.
	r := h.do("POST", "/auth/code", "", map[string]string{"email": reviewEmail})
	assert.Equal(t, "UNIVERSITY_EMAIL_REQUIRED", r.code(), r.Raw)
	r = h.verifyReq(reviewEmail, reviewCode)
	assert.NotEqual(t, http.StatusOK, r.Status, r.Raw)
	assert.Empty(t, h.mail.Sent())

	// The normal flow is untouched.
	s := h.signIn("alice@test.ac.bd")
	assert.True(t, s.IsNewUser)
	assert.Equal(t, "test-uni", s.User.University.Slug)
	assert.Len(t, h.mail.Sent(), 1)
	// A fixed code means nothing to a normal address.
	r = h.do("POST", "/auth/code", "", map[string]string{"email": "bob@test.ac.bd"})
	require.Equal(t, http.StatusAccepted, r.Status, r.Raw)
	assert.NotEqual(t, http.StatusOK, h.verifyReq("bob@test.ac.bd", reviewCode).Status)
}

func TestReviewSignIn(t *testing.T) {
	h := reviewHarness(t)

	r := h.do("POST", "/auth/code", "", map[string]string{"email": "  Play-Review@Review.VarsityKotha.com "})
	require.Equal(t, http.StatusAccepted, r.Status, r.Raw)
	assert.Empty(t, h.mail.Sent(), "no email for the reviewer")

	// A wrong code fails and counts as an attempt.
	r = h.verifyReq(reviewEmail, "000000")
	assert.Equal(t, "CODE_INVALID", r.code(), r.Raw)
	assert.Contains(t, string(r.Error.Details), `"remainingAttempts":4`)

	r = h.verifyReq(reviewEmail, reviewCode)
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	var s signedIn
	r.into(t, &s)
	assert.True(t, s.IsNewUser)
	assert.Equal(t, reviewEmail, s.User.Email)
	assert.Equal(t, "demo-review", s.User.University.Slug)
	assert.Empty(t, h.mail.Sent())
	assert.Equal(t, http.StatusOK, h.do("GET", "/me", s.Tokens.AccessToken, nil).Status)

	// The code row is used up, like any other.
	assert.NotEqual(t, http.StatusOK, h.verifyReq(reviewEmail, reviewCode).Status)
	// Signing in again later works the same way.
	h.advance(61 * time.Second)
	r = h.do("POST", "/auth/code", "", map[string]string{"email": reviewEmail})
	require.Equal(t, http.StatusAccepted, r.Status, r.Raw)
	assert.Equal(t, http.StatusOK, h.verifyReq(reviewEmail, reviewCode).Status, "can sign in again")
	assert.Empty(t, h.mail.Sent())
}

func TestReviewSignInAttemptLimit(t *testing.T) {
	h := reviewHarness(t)
	require.Equal(t, http.StatusAccepted, h.do("POST", "/auth/code", "", map[string]string{"email": reviewEmail}).Status)
	for i := 0; i < 5; i++ {
		assert.NotEqual(t, http.StatusOK, h.verifyReq(reviewEmail, "111111").Status)
	}
	// Locked out: even the right code is refused until a new request.
	r := h.verifyReq(reviewEmail, reviewCode)
	assert.Equal(t, "CODE_TOO_MANY_ATTEMPTS", r.code(), r.Raw)
}

func TestReviewCodeOnlyWorksForReviewEmail(t *testing.T) {
	h := reviewHarness(t)

	// Another email, normal flow: the review code is just a wrong code.
	r := h.do("POST", "/auth/code", "", map[string]string{"email": "alice@test.ac.bd"})
	require.Equal(t, http.StatusAccepted, r.Status, r.Raw)
	real := h.lastCode("alice@test.ac.bd")
	require.NotEqual(t, reviewCode, real) // (1 in a million otherwise)
	assert.Equal(t, "CODE_INVALID", h.verifyReq("alice@test.ac.bd", reviewCode).code())
	assert.Equal(t, http.StatusOK, h.verifyReq("alice@test.ac.bd", real).Status)

	// No code requested for the email at all.
	assert.NotEqual(t, http.StatusOK, h.verifyReq("carol@test.ac.bd", reviewCode).Status)

	// Others on the demo domain can't get in, nor pick the demo university.
	r = h.do("POST", "/auth/code", "", map[string]string{"email": "someone@review.varsitykotha.com"})
	assert.Equal(t, "UNIVERSITY_EMAIL_REQUIRED", r.code(), r.Raw)
	s := h.signIn("dave@test.ac.bd")
	var demoID string
	require.NoError(t, h.app.DB.Pool.QueryRow(context.Background(), `SELECT id::text FROM universities WHERE is_demo`).Scan(&demoID))
	r = h.do("PUT", "/me/university", s.Tokens.AccessToken, map[string]any{"universityId": demoID, "leaveVerified": true})
	assert.GreaterOrEqual(t, r.Status, 400, r.Raw)
	r = h.do("POST", "/me/verify/code", s.Tokens.AccessToken, map[string]string{"email": reviewEmail})
	assert.GreaterOrEqual(t, r.Status, 400, r.Raw)
}

func TestReviewCodeDoesNotOpenAdminPanel(t *testing.T) {
	h := reviewHarness(t)
	s := h.signInReview()
	_, err := h.app.DB.Pool.Exec(context.Background(), `UPDATE users SET role = 'admin' WHERE id = $1`, s.User.ID)
	require.NoError(t, err)

	// Even an admin account on the review email: the stored review code is
	// refused by the admin sign-in.
	h.advance(61 * time.Second)
	require.Equal(t, http.StatusAccepted, h.do("POST", "/auth/code", "", map[string]string{"email": reviewEmail}).Status)
	r := h.do("POST", "/admin/auth/verify", "", map[string]string{"email": reviewEmail, "code": reviewCode})
	assert.Equal(t, http.StatusForbidden, r.Status, r.Raw)
	// Asking the panel for a code emails a normal random one, never the review code.
	h.advance(61 * time.Second)
	require.Equal(t, http.StatusAccepted, h.do("POST", "/admin/auth/code", "", map[string]string{"email": reviewEmail}).Status)
	assert.NotEqual(t, reviewCode, h.lastCode(reviewEmail))
}

func TestDemoUniversityIsHidden(t *testing.T) {
	h := reviewHarness(t)

	// Public picker.
	r := h.do("GET", "/universities", "", nil)
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	var list struct {
		Universities []struct {
			Slug string `json:"slug"`
		} `json:"universities"`
	}
	r.into(t, &list)
	for _, u := range list.Universities {
		assert.NotEqual(t, "demo-review", u.Slug)
	}
	assert.Greater(t, len(list.Universities), 150)

	// The reviewer's group is only findable at the demo university.
	rev := h.signInReview().Tokens.AccessToken
	g := h.createGroup(rev)
	h.addSlot(rev, g.ID, "CSE 311", 2, "09:00", "10:30")
	assert.Len(t, h.search(rev, "cse").Items, 1, "the reviewer finds it")
	student := h.signIn("student@test.ac.bd").Tokens.AccessToken
	assert.Empty(t, h.search(student, "").Items)
	assert.Empty(t, h.search(student, "cse").Items)
}
