package app

import (
	"net/http"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/zamansheikh/campussaga/backend/internal/platform/firebase/firebasetest"
)

func (h *harness) googleToken(email string, verified bool) string {
	return h.google.Sign(firebasetest.Token{Email: email, EmailVerified: verified, IssuedAt: h.Now()})
}

func TestGoogleSignInWithUniversityAccount(t *testing.T) {
	h := newHarness(t)

	r := h.do("POST", "/auth/google", "", map[string]string{"idToken": h.googleToken("Lina@cse.test.ac.bd", true)})
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	var s signedIn
	r.into(t, &s)
	assert.True(t, s.IsNewUser)
	assert.Equal(t, "lina@cse.test.ac.bd", s.User.Email)
	assert.Equal(t, "test-uni", s.User.University.Slug)
	assert.Empty(t, h.mail.Sent(), "no email code needed")
	assert.Equal(t, http.StatusOK, h.do("GET", "/me", s.Tokens.AccessToken, nil).Status)

	// The same person signing in with an email code gets the same account.
	again := h.signIn("lina@cse.test.ac.bd")
	assert.False(t, again.IsNewUser)
	assert.Equal(t, s.User.ID, again.User.ID)
}

func TestGoogleSignInRejections(t *testing.T) {
	h := newHarness(t)
	post := func(tok string) *response {
		return h.do("POST", "/auth/google", "", map[string]string{"idToken": tok})
	}

	r := post(h.googleToken("someone@gmail.com", true))
	assert.Equal(t, http.StatusForbidden, r.Status)
	assert.Equal(t, "UNIVERSITY_EMAIL_REQUIRED", r.code(), "personal Gmail is not enough")

	assert.Equal(t, "GOOGLE_TOKEN_INVALID", post(h.googleToken("x@test.ac.bd", false)).code(), "unverified email")
	assert.Equal(t, "GOOGLE_TOKEN_INVALID", post("garbage").code())

	other := firebasetest.New("campus-test") // a key Google never published
	assert.Equal(t, "GOOGLE_TOKEN_INVALID", post(other.Sign(firebasetest.Token{Email: "x@test.ac.bd", EmailVerified: true, IssuedAt: h.Now()})).code())

	wrongProject := h.google.Sign(firebasetest.Token{Email: "x@test.ac.bd", EmailVerified: true, IssuedAt: h.Now(), Audience: "another-app"})
	assert.Equal(t, "GOOGLE_TOKEN_INVALID", post(wrongProject).code(), "token from another Firebase project")

	password := h.google.Sign(firebasetest.Token{Email: "x@test.ac.bd", EmailVerified: true, IssuedAt: h.Now(), Provider: "password"})
	assert.Equal(t, "GOOGLE_TOKEN_INVALID", post(password).code(), "only Google provider tokens")

	old := h.googleToken("x@test.ac.bd", true)
	h.advance(2 * time.Hour)
	assert.Equal(t, "GOOGLE_TOKEN_INVALID", post(old).code(), "expired token")

	assert.Equal(t, "VALIDATION_FAILED", h.do("POST", "/auth/google", "", map[string]string{}).code())
}
