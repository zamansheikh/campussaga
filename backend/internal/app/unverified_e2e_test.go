package app

import (
	"context"
	"net/http"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

type meJSON struct {
	ID              string  `json:"id"`
	Email           string  `json:"email"`
	Verified        bool    `json:"verified"`
	UniversityEmail *string `json:"universityEmail"`
	University      *struct {
		ID   string `json:"id"`
		Slug string `json:"slug"`
	} `json:"university"`
}

func (h *harness) universityID(slug string) string {
	h.t.Helper()
	var id string
	require.NoError(h.t, h.app.DB.Pool.QueryRow(context.Background(), `SELECT id FROM universities WHERE slug = $1`, slug).Scan(&id))
	return id
}

func (h *harness) gmailSignIn(email string) (string, meJSON) {
	h.t.Helper()
	r := h.do("POST", "/auth/google", "", map[string]string{"idToken": h.googleToken(email, true)})
	require.Equal(h.t, http.StatusOK, r.Status, r.Raw)
	var out struct {
		Tokens struct {
			AccessToken string `json:"accessToken"`
		} `json:"tokens"`
		User meJSON `json:"user"`
	}
	r.into(h.t, &out)
	return out.Tokens.AccessToken, out.User
}

func (h *harness) me(token string) meJSON {
	h.t.Helper()
	var m meJSON
	r := h.do("GET", "/me", token, nil)
	require.Equal(h.t, http.StatusOK, r.Status, r.Raw)
	r.into(h.t, &m)
	return m
}

// No university email: sign in with Gmail, pick the university, use My
// Class as "not verified", verify later with a university email.
func TestGmailStudentNotVerified(t *testing.T) {
	h := newHarness(t)
	cr := h.signIn("cr@test.ac.bd").Tokens.AccessToken
	g := h.createGroup(cr)

	tok, me := h.gmailSignIn("rafi.student@gmail.com")
	assert.False(t, me.Verified)
	assert.Nil(t, me.University, "picks it next")
	assert.Nil(t, me.UniversityEmail)

	// Groups need a university first.
	assert.Equal(t, "UNIVERSITY_REQUIRED", h.do("POST", "/groups/join", tok, map[string]string{"code": g.JoinCode}).code())
	assert.Equal(t, "UNIVERSITY_REQUIRED", h.do("POST", "/groups", tok, map[string]string{"department": "CSE", "batch": "61", "semester": "Fall 2026"}).code())

	// Pick it; the very next request sees it (no new token needed).
	uni := h.universityID("test-uni")
	r := h.do("PUT", "/me/university", tok, map[string]string{"universityId": uni})
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	assert.Equal(t, "UNIVERSITY_NOT_FOUND", h.do("PUT", "/me/university", tok, map[string]string{"universityId": "00000000-0000-0000-0000-000000000001"}).code())
	require.Equal(t, http.StatusOK, h.do("POST", "/groups/join", tok, map[string]string{"code": g.JoinCode}).Status)

	// The CR sees who is verified.
	ms := h.members(cr, g.ID)
	require.Len(t, ms, 2)
	var crRow, gmailRow map[string]any
	r = h.do("GET", "/groups/"+g.ID+"/members", cr, nil)
	var raw struct {
		Members []map[string]any `json:"members"`
	}
	r.into(t, &raw)
	for _, m := range raw.Members {
		if m["role"] == "cr" {
			crRow = m
		} else {
			gmailRow = m
		}
	}
	assert.Equal(t, true, crRow["verified"])
	assert.Equal(t, false, gmailRow["verified"])

	// Same Gmail later: same account.
	_, again := h.gmailSignIn("rafi.student@gmail.com")
	assert.Equal(t, me.ID, again.ID)

	// Verify with a university email; the code goes to that address.
	assert.Equal(t, "UNIVERSITY_EMAIL_REQUIRED", h.do("POST", "/me/verify/code", tok, map[string]string{"email": "me@yahoo.com"}).code())
	assert.Equal(t, "EMAIL_IN_USE", h.do("POST", "/me/verify/code", tok, map[string]string{"email": "cr@test.ac.bd"}).code())
	require.Equal(t, http.StatusAccepted, h.do("POST", "/me/verify/code", tok, map[string]string{"email": "Rafi@Test.ac.bd"}).Status)
	assert.Equal(t, "CODE_INVALID", h.do("POST", "/me/verify", tok, map[string]string{"email": "rafi@test.ac.bd", "code": "000000"}).code())
	r = h.do("POST", "/me/verify", tok, map[string]string{"email": "rafi@test.ac.bd", "code": h.lastCode("rafi@test.ac.bd")})
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	var verified meJSON
	r.into(t, &verified)
	assert.True(t, verified.Verified)
	assert.Equal(t, "rafi@test.ac.bd", *verified.UniversityEmail)
	assert.Equal(t, "rafi.student@gmail.com", verified.Email, "still signs in with Gmail")
	assert.True(t, h.me(tok).Verified)

	// Now verified: the university comes from the email (changing it means
	// leaving verified, see TestMovingUniversity).
	assert.Equal(t, "ALREADY_VERIFIED", h.do("PUT", "/me/university", tok, map[string]string{"universityId": uni}).code())
	assert.Equal(t, "ALREADY_VERIFIED", h.do("POST", "/me/verify/code", tok, map[string]string{"email": "rafi@test.ac.bd"}).code())

	// Whoever controls the university email gets the same account.
	h.advance(61e9)
	viaCode := h.signIn("rafi@test.ac.bd")
	assert.Equal(t, me.ID, viaCode.User.ID)
}

// A verified student starts a master's at another university.
func TestMovingUniversity(t *testing.T) {
	h := newHarness(t)
	_, err := h.app.DB.Pool.Exec(context.Background(), `
		WITH u AS (INSERT INTO universities (slug, name) VALUES ('other-uni', 'Other University') RETURNING id)
		INSERT INTO university_domains (domain, university_id) SELECT 'other.ac.bd', id FROM u`)
	require.NoError(t, err)
	other := h.universityID("other-uni")

	// With the new university's email: stays verified, there.
	tok := h.signIn("bsc@test.ac.bd").Tokens.AccessToken
	require.Equal(t, http.StatusAccepted, h.do("POST", "/me/verify/code", tok, map[string]string{"email": "msc@other.ac.bd"}).Status)
	r := h.do("POST", "/me/verify", tok, map[string]string{"email": "msc@other.ac.bd", "code": h.lastCode("msc@other.ac.bd")})
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	m := h.me(tok)
	assert.True(t, m.Verified)
	assert.Equal(t, "other-uni", m.University.Slug)
	assert.Equal(t, "msc@other.ac.bd", *m.UniversityEmail)
	assert.Equal(t, "bsc@test.ac.bd", m.Email, "still signs in with the old address")

	// Without an email there: picks it and becomes not verified.
	h.advance(61e9)
	tok2 := h.signIn("student@test.ac.bd").Tokens.AccessToken
	assert.Equal(t, "ALREADY_VERIFIED", h.do("PUT", "/me/university", tok2, map[string]string{"universityId": other}).code(), "must agree to leave verified")
	r = h.do("PUT", "/me/university", tok2, map[string]any{"universityId": other, "leaveVerified": true})
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	m = h.me(tok2)
	assert.False(t, m.Verified)
	assert.Equal(t, "other-uni", m.University.Slug)
	assert.Nil(t, m.UniversityEmail)
	// The next request already sees the new university.
	assert.Equal(t, http.StatusCreated, h.do("POST", "/groups", tok2, map[string]string{"department": "CSE", "batch": "1", "semester": "Fall 2026"}).Status)
}
