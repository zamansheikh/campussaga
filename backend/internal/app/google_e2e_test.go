package app

import (
	"net/http"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/zamansheikh/varsitykotha/backend/internal/platform/firebase/firebasetest"
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

func TestLaunchUniversityGoogleAccount(t *testing.T) {
	h := newHarness(t)
	r := h.do("POST", "/auth/google", "", map[string]string{"idToken": h.googleToken("student@diu.edu.bd", true)})
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	var s signedIn
	r.into(t, &s)
	assert.Equal(t, "diu", s.User.University.Slug)
	assert.Equal(t, "Daffodil International University", s.User.University.Name)
}

// The Google name fills an empty profile name: the token's own name first,
// else the name the phone sends; a name the student already has is kept.
func TestGoogleSignInName(t *testing.T) {
	h := newHarness(t)
	post := func(tok, name string) signedIn {
		t.Helper()
		r := h.do("POST", "/auth/google", "", map[string]string{"idToken": tok, "name": name})
		require.Equal(t, http.StatusOK, r.Status, r.Raw)
		var s signedIn
		r.into(t, &s)
		return s
	}

	withName := h.google.Sign(firebasetest.Token{Email: "a@gmail.com", EmailVerified: true, IssuedAt: h.Now(), Name: "Token Name"})
	s := post(withName, "Phone Name")
	require.NotNil(t, s.User.DisplayName)
	assert.Equal(t, "Token Name", *s.User.DisplayName)

	s = post(h.googleToken("b@gmail.com", true), "  Phone Name  ")
	require.NotNil(t, s.User.DisplayName)
	assert.Equal(t, "Phone Name", *s.User.DisplayName)

	// An account made without any name gets one on a later sign-in.
	s = post(h.googleToken("c@gmail.com", true), "")
	assert.True(t, s.User.DisplayName == nil || *s.User.DisplayName == "")
	s = post(h.googleToken("c@gmail.com", true), "Later Name")
	require.NotNil(t, s.User.DisplayName)
	assert.Equal(t, "Later Name", *s.User.DisplayName)

	// Never overwrites a name the student has.
	s = post(h.googleToken("b@gmail.com", true), "Someone Else")
	assert.Equal(t, "Phone Name", *s.User.DisplayName)
}
