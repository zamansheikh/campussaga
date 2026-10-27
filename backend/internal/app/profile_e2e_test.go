package app

import (
	"context"
	"net/http"
	"net/url"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestDepartmentSuggestions(t *testing.T) {
	h := newHarness(t)

	setDept := func(email, dept string) {
		s := h.signIn(email)
		r := h.do("PATCH", "/me", s.Tokens.AccessToken, map[string]string{"department": dept})
		require.Equal(t, http.StatusOK, r.Status, r.Raw)
	}
	setDept("a@test.ac.bd", "CSE")
	setDept("b@test.ac.bd", "CSE")
	setDept("c@test.ac.bd", "cse")
	setDept("d@test.ac.bd", "EEE")
	setDept("e@test.ac.bd", "Computer Science")

	// A student at another university must never see these.
	_, err := h.app.DB.Pool.Exec(context.Background(), `
		WITH u AS (INSERT INTO universities (slug, name) VALUES ('other-uni', 'Other University') RETURNING id)
		INSERT INTO university_domains (domain, university_id) SELECT 'other.ac.bd', id FROM u`)
	require.NoError(t, err)
	setDept("x@other.ac.bd", "CSE Secret Dept")

	me := h.signIn("me@test.ac.bd")
	get := func(q string) []string {
		r := h.do("GET", "/me/department-suggestions?q="+url.QueryEscape(q), me.Tokens.AccessToken, nil)
		require.Equal(t, http.StatusOK, r.Status, r.Raw)
		var out struct {
			Departments []string `json:"departments"`
		}
		r.into(t, &out)
		return out.Departments
	}

	assert.Equal(t, []string{"CSE", "Computer Science", "EEE"}, get(""),
		"most used first; CSE/cse grouped, shown in the most common spelling")
	assert.Equal(t, []string{"CSE", "Computer Science"}, get("c"), "case-insensitive match")
	assert.Equal(t, []string{"CSE"}, get("cs"))
	assert.Empty(t, get("secret"), "other universities' departments never leak")
	assert.Empty(t, get("%"), "% is a plain character, not a wildcard")

	assert.Equal(t, "UNAUTHORIZED", h.do("GET", "/me/department-suggestions", "", nil).code())
}
