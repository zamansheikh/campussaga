package app

import (
	"encoding/json"
	"net/http"
	"strings"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestPublicEndpoints(t *testing.T) {
	h := newHarness(t)

	r := h.do("GET", "/health", "", nil)
	assert.Equal(t, http.StatusOK, r.Status, r.Raw)

	r = h.do("GET", "/universities", "", nil)
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	var list struct {
		Universities []struct {
			Slug    string   `json:"slug"`
			Domains []string `json:"domains"`
		} `json:"universities"`
	}
	r.into(t, &list)
	domains := map[string][]string{}
	for _, u := range list.Universities {
		domains[u.Slug] = u.Domains
	}
	assert.Equal(t, []string{"test.ac.bd"}, domains["test-uni"])
	assert.Contains(t, domains["diu"], "diu.edu.bd", "universities ship with the migrations")
	assert.Greater(t, len(list.Universities), 150, "all Bangladeshi universities are seeded")

	r = h.do("GET", "/config", "", nil)
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	var cfg map[string]json.RawMessage
	r.into(t, &cfg)
	assert.JSONEq(t, "1", string(cfg["minSupportedBuild"]))
	assert.Contains(t, cfg, "features")
	assert.JSONEq(t, `{"android":"https://play.google.com/store/apps/details?id=com.silifton.campussaga","ios":null}`,
		string(cfg["storeUrls"]))

	r = h.do("GET", "/nope", "", nil)
	assert.Equal(t, http.StatusNotFound, r.Status)
	assert.Equal(t, "NOT_FOUND", r.code())
}

func TestOnlyUniversityEmailsCanSignUp(t *testing.T) {
	h := newHarness(t)

	for _, email := range []string{"someone@gmail.com", "x@nottest.ac.bd", "x@ac.bd"} {
		r := h.do("POST", "/auth/code", "", map[string]string{"email": email})
		assert.Equal(t, http.StatusForbidden, r.Status, email)
		assert.Equal(t, "UNIVERSITY_EMAIL_REQUIRED", r.code(), email)
	}
	for _, email := range []string{"not-an-email", "Bob <bob@test.ac.bd>", "a@b@test.ac.bd"} {
		r := h.do("POST", "/auth/code", "", map[string]string{"email": email})
		assert.Equal(t, http.StatusBadRequest, r.Status, email)
		assert.Equal(t, "VALIDATION_FAILED", r.code(), email)
	}
	assert.Empty(t, h.mail.Sent(), "no email may be sent for rejected addresses")
}

func TestSignInFlow(t *testing.T) {
	h := newHarness(t)

	// Department subdomain + upper case: normalised, matched to the university.
	r := h.do("POST", "/auth/code", "", map[string]string{"email": "  Alice@CSE.Test.ac.bd "})
	require.Equal(t, http.StatusAccepted, r.Status, r.Raw)
	var sent struct {
		Email            string `json:"email"`
		ExpiresInSeconds int    `json:"expiresInSeconds"`
		University       struct {
			Name string `json:"name"`
		} `json:"university"`
	}
	r.into(t, &sent)
	assert.Equal(t, "alice@cse.test.ac.bd", sent.Email)
	assert.Equal(t, "Test University", sent.University.Name)
	assert.Equal(t, 600, sent.ExpiresInSeconds)

	msg, ok := h.mail.Last("alice@cse.test.ac.bd")
	require.True(t, ok)
	assert.Contains(t, msg.HTML, h.lastCode("alice@cse.test.ac.bd"), "HTML part shows the code too")
	assert.Contains(t, msg.Text, "সাইন-ইন কোড", "email is bilingual")

	code := h.lastCode("alice@cse.test.ac.bd")
	wrong := "000000"
	if code == wrong {
		wrong = "111111"
	}
	r = h.do("POST", "/auth/verify", "", map[string]string{"email": "alice@cse.test.ac.bd", "code": wrong})
	assert.Equal(t, http.StatusBadRequest, r.Status)
	assert.Equal(t, "CODE_INVALID", r.code())
	assert.JSONEq(t, `{"remainingAttempts":4}`, string(r.Error.Details))

	r = h.do("POST", "/auth/verify", "", map[string]string{"email": "ALICE@cse.test.ac.bd", "code": code})
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	var s signedIn
	r.into(t, &s)
	assert.True(t, s.IsNewUser)
	assert.Equal(t, "alice@cse.test.ac.bd", s.User.Email)
	assert.Equal(t, "test-uni", s.User.University.Slug)
	assert.Equal(t, "student", s.User.Role)
	assert.NotEmpty(t, s.Tokens.AccessToken)
	assert.NotEmpty(t, s.Tokens.RefreshToken)
	assert.NotContains(t, r.Raw, code, "the code is never echoed back")

	// A used code cannot be used again.
	r = h.do("POST", "/auth/verify", "", map[string]string{"email": "alice@cse.test.ac.bd", "code": code})
	assert.Equal(t, "CODE_EXPIRED", r.code())

	r = h.do("GET", "/me", s.Tokens.AccessToken, nil)
	require.Equal(t, http.StatusOK, r.Status, r.Raw)

	// Signing in again on another device: same account.
	h.advance(time.Minute)
	again := h.signIn("alice@cse.test.ac.bd")
	assert.False(t, again.IsNewUser)
	assert.Equal(t, s.User.ID, again.User.ID)
}

func TestCodeLimits(t *testing.T) {
	h := newHarness(t)
	email := "bob@test.ac.bd"
	ask := func() *response { return h.do("POST", "/auth/code", "", map[string]string{"email": email}) }

	require.Equal(t, http.StatusAccepted, ask().Status)
	first := h.lastCode(email)

	r := ask()
	assert.Equal(t, http.StatusTooManyRequests, r.Status)
	assert.Equal(t, "CODE_RESEND_TOO_SOON", r.code())
	assert.Equal(t, "60", r.Header.Get("Retry-After"))

	// A new code replaces the old one.
	h.advance(61 * time.Second)
	require.Equal(t, http.StatusAccepted, ask().Status)
	second := h.lastCode(email)
	if first != second {
		r = h.do("POST", "/auth/verify", "", map[string]string{"email": email, "code": first})
		assert.Equal(t, "CODE_INVALID", r.code(), "old code no longer works")
	}

	// At most 5 codes per hour.
	for i := 0; i < 3; i++ {
		h.advance(61 * time.Second)
		require.Equal(t, http.StatusAccepted, ask().Status, "send %d", i+3)
	}
	h.advance(61 * time.Second)
	r = ask()
	assert.Equal(t, "CODE_LIMIT_REACHED", r.code())

	// Expired code.
	h.advance(time.Hour)
	require.Equal(t, http.StatusAccepted, ask().Status)
	code := h.lastCode(email)
	h.advance(10*time.Minute + time.Second)
	r = h.do("POST", "/auth/verify", "", map[string]string{"email": email, "code": code})
	assert.Equal(t, "CODE_EXPIRED", r.code())
}

func TestTooManyWrongCodesLocksTheCode(t *testing.T) {
	h := newHarness(t)
	email := "carol@test.ac.bd"
	require.Equal(t, http.StatusAccepted, h.do("POST", "/auth/code", "", map[string]string{"email": email}).Status)
	code := h.lastCode(email)
	wrong := "123456"
	if code == wrong {
		wrong = "654321"
	}
	for i := 0; i < 4; i++ {
		assert.Equal(t, "CODE_INVALID", h.do("POST", "/auth/verify", "", map[string]string{"email": email, "code": wrong}).code())
	}
	assert.Equal(t, "CODE_TOO_MANY_ATTEMPTS", h.do("POST", "/auth/verify", "", map[string]string{"email": email, "code": wrong}).code())

	r := h.do("POST", "/auth/verify", "", map[string]string{"email": email, "code": code})
	assert.Equal(t, "CODE_TOO_MANY_ATTEMPTS", r.code(), "even the right code fails after 5 wrong tries")

	r = h.do("POST", "/auth/verify", "", map[string]string{"email": email, "code": "12ab56"})
	assert.Equal(t, "VALIDATION_FAILED", r.code())
}

func TestEmailFailureCanBeRetriedAtOnce(t *testing.T) {
	h := newHarness(t)
	h.mail.Fail = assert.AnError
	r := h.do("POST", "/auth/code", "", map[string]string{"email": "dan@test.ac.bd"})
	assert.Equal(t, http.StatusBadGateway, r.Status)
	assert.Equal(t, "EMAIL_SEND_FAILED", r.code())
	assert.NotContains(t, r.Raw, assert.AnError.Error(), "internal errors never reach the client")

	h.mail.Fail = nil
	r = h.do("POST", "/auth/code", "", map[string]string{"email": "dan@test.ac.bd"})
	assert.Equal(t, http.StatusAccepted, r.Status, "no resend wait after a failed send")
}

func TestAccessTokens(t *testing.T) {
	h := newHarness(t)
	s := h.signIn("erin@test.ac.bd")

	assert.Equal(t, "UNAUTHORIZED", h.do("GET", "/me", "", nil).code())
	assert.Equal(t, "TOKEN_INVALID", h.do("GET", "/me", "garbage", nil).code())
	tampered := s.Tokens.AccessToken[:len(s.Tokens.AccessToken)-2] + "xx"
	assert.Equal(t, "TOKEN_INVALID", h.do("GET", "/me", tampered, nil).code())

	h.advance(16 * time.Minute)
	assert.Equal(t, "TOKEN_EXPIRED", h.do("GET", "/me", s.Tokens.AccessToken, nil).code())

	r := h.do("POST", "/auth/refresh", "", map[string]string{"refreshToken": s.Tokens.RefreshToken})
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	var next tokens
	r.into(t, &next)
	assert.NotEqual(t, s.Tokens.RefreshToken, next.RefreshToken, "refresh token rotates")
	assert.Equal(t, http.StatusOK, h.do("GET", "/me", next.AccessToken, nil).Status)
}

func TestStolenRefreshTokenEndsTheSession(t *testing.T) {
	h := newHarness(t)
	s := h.signIn("fay@test.ac.bd")

	r := h.do("POST", "/auth/refresh", "", map[string]string{"refreshToken": s.Tokens.RefreshToken})
	require.Equal(t, http.StatusOK, r.Status)
	var next tokens
	r.into(t, &next)

	// Someone replays the old (already rotated) refresh token.
	r = h.do("POST", "/auth/refresh", "", map[string]string{"refreshToken": s.Tokens.RefreshToken})
	assert.Equal(t, "REFRESH_INVALID", r.code())

	// The whole session is now dead, for the thief and the real device.
	assert.Equal(t, "REFRESH_INVALID", h.do("POST", "/auth/refresh", "", map[string]string{"refreshToken": next.RefreshToken}).code())
	assert.Equal(t, "SESSION_ENDED", h.do("GET", "/me", next.AccessToken, nil).code())
}

func TestLogout(t *testing.T) {
	h := newHarness(t)
	phone := h.signIn("gina@test.ac.bd")
	tablet := h.signIn("gina@test.ac.bd")

	assert.Equal(t, http.StatusNoContent, h.do("POST", "/auth/logout", phone.Tokens.AccessToken, nil).Status)
	assert.Equal(t, "SESSION_ENDED", h.do("GET", "/me", phone.Tokens.AccessToken, nil).code(), "takes effect at once")
	assert.Equal(t, "REFRESH_INVALID", h.do("POST", "/auth/refresh", "", map[string]string{"refreshToken": phone.Tokens.RefreshToken}).code())
	assert.Equal(t, http.StatusOK, h.do("GET", "/me", tablet.Tokens.AccessToken, nil).Status, "other device unaffected")

	laptop := h.signIn("gina@test.ac.bd")
	assert.Equal(t, http.StatusNoContent, h.do("POST", "/auth/logout-all", laptop.Tokens.AccessToken, nil).Status)
	assert.Equal(t, "SESSION_ENDED", h.do("GET", "/me", tablet.Tokens.AccessToken, nil).code())
	assert.Equal(t, "SESSION_ENDED", h.do("GET", "/me", laptop.Tokens.AccessToken, nil).code())
}

func TestProfileRules(t *testing.T) {
	h := newHarness(t)
	s := h.signIn("hana@test.ac.bd")
	tok := s.Tokens.AccessToken

	r := h.do("PATCH", "/me", tok, map[string]string{"displayName": "  Hana   Rahman ", "department": "CSE"})
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	var m me
	r.into(t, &m)
	require.NotNil(t, m.DisplayName)
	assert.Equal(t, "Hana Rahman", *m.DisplayName, "spaces are tidied")
	assert.Equal(t, "CSE", *m.Department)

	r = h.do("PATCH", "/me", tok, map[string]string{"department": ""})
	r.into(t, &m)
	assert.Nil(t, m.Department, "empty string clears a field")
	assert.Equal(t, "Hana Rahman", *m.DisplayName, "absent field is unchanged")

	// Privilege escalation attempts are rejected outright.
	for _, body := range []string{`{"role":"admin"}`, `{"email":"x@test.ac.bd"}`, `{"universityId":"00000000-0000-0000-0000-000000000000"}`, `{"displayName":"ok","role":"admin"}`} {
		r = h.do("PATCH", "/me", tok, body)
		assert.Equal(t, http.StatusBadRequest, r.Status, body)
		assert.Equal(t, "BAD_REQUEST", r.code(), body)
	}
	r = h.do("GET", "/me", tok, nil)
	r.into(t, &m)
	assert.Equal(t, "student", m.Role)
	assert.Equal(t, "hana@test.ac.bd", m.Email)

	r = h.do("PATCH", "/me", tok, map[string]string{"displayName": strings.Repeat("ক", 61)})
	assert.Equal(t, "VALIDATION_FAILED", r.code(), "61 Bangla characters is too long")
	r = h.do("PATCH", "/me", tok, map[string]string{"displayName": strings.Repeat("ক", 60)})
	assert.Equal(t, http.StatusOK, r.Status, "60 Bangla characters fits")

	r = h.do("PATCH", "/me", tok, `{"displayName": "`+strings.Repeat("x", 70000)+`"}`)
	assert.Equal(t, http.StatusRequestEntityTooLarge, r.Status, "large bodies are refused")
}

func TestStudentsOnlyReachTheirOwnAccount(t *testing.T) {
	h := newHarness(t)
	alice := h.signIn("ivy@test.ac.bd")
	bob := h.signIn("jon@test.ac.bd")

	r := h.do("GET", "/me", bob.Tokens.AccessToken, nil)
	var m me
	r.into(t, &m)
	assert.Equal(t, "jon@test.ac.bd", m.Email)
	assert.NotContains(t, r.Raw, "ivy@test.ac.bd")

	// There is no endpoint that takes another user's id.
	for _, path := range []string{"/users/" + alice.User.ID, "/me/" + alice.User.ID, "/profiles/" + alice.User.ID} {
		assert.Equal(t, http.StatusNotFound, h.do("GET", path, bob.Tokens.AccessToken, nil).Status, path)
	}
}

func TestDeleteAccount(t *testing.T) {
	h := newHarness(t)
	s := h.signIn("kim@test.ac.bd")

	assert.Equal(t, http.StatusNoContent, h.do("DELETE", "/me", s.Tokens.AccessToken, nil).Status)
	assert.Equal(t, "SESSION_ENDED", h.do("GET", "/me", s.Tokens.AccessToken, nil).code())
	assert.Equal(t, "REFRESH_INVALID", h.do("POST", "/auth/refresh", "", map[string]string{"refreshToken": s.Tokens.RefreshToken}).code())

	again := h.signIn("kim@test.ac.bd")
	assert.True(t, again.IsNewUser, "signing in again creates a fresh account")
	assert.NotEqual(t, s.User.ID, again.User.ID)
}
