package app

import (
	"context"
	"encoding/json"
	"net/http"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// makeAdmin signs in email (a student) and promotes them by hand, the way
// the first admin is made on a real server.
func (h *harness) makeAdmin(email string) string {
	h.t.Helper()
	s := h.signIn(email)
	_, err := h.app.DB.Pool.Exec(context.Background(), `UPDATE users SET role = 'admin' WHERE id = $1`, s.User.ID)
	require.NoError(h.t, err)
	return s.Tokens.AccessToken
}

// adminSignIn signs in to the panel with an emailed code.
func (h *harness) adminSignIn(email string) string {
	h.t.Helper()
	r := h.do("POST", "/admin/auth/code", "", map[string]string{"email": email})
	require.Equal(h.t, http.StatusAccepted, r.Status, r.Raw)
	r = h.do("POST", "/admin/auth/verify", "", map[string]string{"email": email, "code": h.lastCode(email)})
	require.Equal(h.t, http.StatusOK, r.Status, r.Raw)
	var s signedIn
	r.into(h.t, &s)
	h.advance(61e9)
	return s.Tokens.AccessToken
}

type adminUserJSON struct {
	ID         string  `json:"id"`
	Email      string  `json:"email"`
	Role       string  `json:"role"`
	Verified   bool    `json:"verified"`
	BlockedAt  *string `json:"blockedAt"`
	University *struct {
		Slug string `json:"slug"`
	} `json:"university"`
	Memberships []struct {
		GroupID string `json:"groupId"`
		Role    string `json:"role"`
	} `json:"memberships"`
}

func TestAdminSignInAndAccess(t *testing.T) {
	h := newHarness(t)
	student := h.signIn("student@test.ac.bd").Tokens.AccessToken
	assert.Equal(t, "NOT_ADMIN", h.do("GET", "/admin/stats", student, nil).code())
	assert.Equal(t, "UNAUTHORIZED", h.do("GET", "/admin/stats", "", nil).code())

	// The first admin: a Gmail account promoted by hand.
	_, gmail := h.gmailSignIn("owner@gmail.com")
	_, err := h.app.DB.Pool.Exec(context.Background(), `UPDATE users SET role = 'admin' WHERE id = $1`, gmail.ID)
	require.NoError(t, err)

	// Not an admin: same answer, but no email.
	sent := len(h.mail.Sent())
	r := h.do("POST", "/admin/auth/code", "", map[string]string{"email": "student@test.ac.bd"})
	assert.Equal(t, http.StatusAccepted, r.Status)
	r = h.do("POST", "/admin/auth/code", "", map[string]string{"email": "nobody@gmail.com"})
	assert.Equal(t, http.StatusAccepted, r.Status)
	assert.Len(t, h.mail.Sent(), sent, "no code for non-admins")

	// A student's own app code doesn't open the panel.
	h.advance(61e9)
	require.Equal(t, http.StatusAccepted, h.do("POST", "/auth/code", "", map[string]string{"email": "student@test.ac.bd"}).Status)
	assert.Equal(t, "NOT_ADMIN", h.do("POST", "/admin/auth/verify", "", map[string]string{
		"email": "student@test.ac.bd", "code": h.lastCode("student@test.ac.bd"),
	}).code())

	admin := h.adminSignIn("owner@gmail.com")
	assert.Equal(t, http.StatusOK, h.do("GET", "/admin/stats", admin, nil).Status)

	// Demoted (by another admin, here by hand): access ends at once.
	_, err = h.app.DB.Pool.Exec(context.Background(), `UPDATE users SET role = 'student' WHERE id = $1`, gmail.ID)
	require.NoError(t, err)
	assert.Equal(t, "NOT_ADMIN", h.do("GET", "/admin/stats", admin, nil).code())
}

func TestAdminUsers(t *testing.T) {
	h := newHarness(t)
	admin := h.makeAdmin("admin@test.ac.bd")
	adminID := h.me(admin).ID
	student := h.signIn("rafi@test.ac.bd")
	_, gmail := h.gmailSignIn("mina@gmail.com")

	var list struct {
		Items []adminUserJSON `json:"items"`
		Total int             `json:"total"`
	}
	h.do("GET", "/admin/users?q=rafi", admin, nil).into(t, &list)
	require.Equal(t, 1, list.Total)
	assert.Equal(t, "rafi@test.ac.bd", list.Items[0].Email)
	h.do("GET", "/admin/users?status=notVerified", admin, nil).into(t, &list)
	require.Equal(t, 1, list.Total)
	assert.Equal(t, gmail.ID, list.Items[0].ID)
	h.do("GET", "/admin/users?pageSize=1&page=2", admin, nil).into(t, &list)
	assert.Equal(t, 3, list.Total)
	assert.Len(t, list.Items, 1)

	// Verify by hand: needs a university first.
	patch := func(id string, body map[string]any) *response { return h.do("PATCH", "/admin/users/"+id, admin, body) }
	assert.Equal(t, "UNIVERSITY_REQUIRED", patch(gmail.ID, map[string]any{"verified": true}).code())
	var u adminUserJSON
	r := patch(gmail.ID, map[string]any{"universityId": h.universityID("test-uni"), "verified": true})
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	r.into(t, &u)
	assert.True(t, u.Verified)
	assert.Equal(t, "test-uni", u.University.Slug)

	// Block: signed out at once and can't sign in again; unblock works.
	r = patch(student.User.ID, map[string]any{"blocked": true})
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	assert.Equal(t, http.StatusUnauthorized, h.do("GET", "/me", student.Tokens.AccessToken, nil).Status)
	assert.Equal(t, "REFRESH_INVALID", h.do("POST", "/auth/refresh", "", map[string]string{"refreshToken": student.Tokens.RefreshToken}).code(),
		"blocking ended the session")
	require.Equal(t, http.StatusAccepted, h.do("POST", "/auth/code", "", map[string]string{"email": "rafi@test.ac.bd"}).Status)
	assert.Equal(t, "ACCOUNT_BLOCKED", h.do("POST", "/auth/verify", "", map[string]string{
		"email": "rafi@test.ac.bd", "code": h.lastCode("rafi@test.ac.bd"),
	}).code())
	require.Equal(t, http.StatusOK, patch(student.User.ID, map[string]any{"blocked": false}).Status)
	h.advance(61e9)
	h.signIn("rafi@test.ac.bd")

	// Admins can't lock themselves out.
	assert.Equal(t, "CANNOT_CHANGE_SELF", patch(adminID, map[string]any{"role": "student"}).code())
	assert.Equal(t, "CANNOT_CHANGE_SELF", patch(adminID, map[string]any{"blocked": true}).code())
	assert.Equal(t, "CANNOT_CHANGE_SELF", h.do("DELETE", "/admin/users/"+adminID, admin, nil).code())

	// Make another admin, then delete a student.
	patch(gmail.ID, map[string]any{"role": "admin"}).into(t, &u)
	assert.Equal(t, "admin", u.Role)
	assert.Equal(t, http.StatusNoContent, h.do("DELETE", "/admin/users/"+student.User.ID, admin, nil).Status)
	assert.Equal(t, "USER_NOT_FOUND", h.do("GET", "/admin/users/"+student.User.ID, admin, nil).code())

	var audit struct {
		Items []struct {
			Action string `json:"action"`
			Actor  struct {
				Email string `json:"email"`
			} `json:"actor"`
		} `json:"items"`
	}
	h.do("GET", "/admin/audit", admin, nil).into(t, &audit)
	require.NotEmpty(t, audit.Items)
	assert.Equal(t, "user.delete", audit.Items[0].Action)
	assert.Equal(t, "admin@test.ac.bd", audit.Items[0].Actor.Email)
}

func TestAdminUniversities(t *testing.T) {
	h := newHarness(t)
	admin := h.makeAdmin("admin@test.ac.bd")

	var uni struct {
		ID      string   `json:"id"`
		Slug    string   `json:"slug"`
		Active  bool     `json:"active"`
		Domains []string `json:"domains"`
	}
	r := h.do("POST", "/admin/universities", admin, map[string]any{
		"slug": "new-uni", "name": "New University", "city": "Khulna", "kind": "private",
		"website": "https://www.new.edu.bd/", "domains": []string{"@NEW.edu.bd", "new.edu.bd"},
	})
	require.Equal(t, http.StatusCreated, r.Status, r.Raw)
	r.into(t, &uni)
	assert.Equal(t, []string{"new.edu.bd"}, uni.Domains)
	assert.True(t, uni.Active)

	// Students of the new university can sign in at once.
	assert.Equal(t, "new-uni", h.signIn("a@new.edu.bd").User.University.Slug)

	assert.Equal(t, "SLUG_TAKEN", h.do("POST", "/admin/universities", admin, map[string]any{"slug": "new-uni", "name": "Again"}).code())
	put := func(domains ...string) *response {
		return h.do("PUT", "/admin/universities/"+uni.ID+"/domains", admin, map[string]any{"domains": domains})
	}
	assert.Equal(t, "DOMAIN_NOT_ALLOWED", put("gmail.com").code())
	assert.Equal(t, "DOMAIN_TAKEN", put("test.ac.bd").code())
	assert.Equal(t, "VALIDATION_FAILED", put("not a domain").code())
	r = put("new.edu.bd", "cse.new.edu.bd")
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	r.into(t, &uni)
	assert.Equal(t, []string{"cse.new.edu.bd", "new.edu.bd"}, uni.Domains)

	assert.Equal(t, "VALIDATION_FAILED", h.do("PATCH", "/admin/universities/"+uni.ID, admin, map[string]any{"kind": "other"}).code())
	r = h.do("PATCH", "/admin/universities/"+uni.ID, admin, map[string]any{"active": false, "city": "", "kind": ""})
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	var cleared struct {
		Active bool    `json:"active"`
		City   *string `json:"city"`
		Kind   *string `json:"kind"`
	}
	r.into(t, &cleared)
	assert.False(t, cleared.Active)
	assert.Nil(t, cleared.City)
	assert.Nil(t, cleared.Kind)

	var list struct {
		Items []struct {
			Slug  string `json:"slug"`
			Users int    `json:"users"`
		} `json:"items"`
	}
	h.do("GET", "/admin/universities?active=false", admin, nil).into(t, &list)
	require.Len(t, list.Items, 1)
	assert.Equal(t, 1, list.Items[0].Users)
}

func TestAdminGroups(t *testing.T) {
	h := newHarness(t)
	admin := h.makeAdmin("admin@test.ac.bd")
	cr := h.signIn("cr@test.ac.bd")
	mate := h.signIn("mate@test.ac.bd")
	g := h.createGroup(cr.Tokens.AccessToken)
	require.Equal(t, http.StatusOK, h.do("POST", "/groups/join", mate.Tokens.AccessToken, map[string]string{"code": g.JoinCode}).Status)

	var list struct {
		Items []struct {
			ID      string `json:"id"`
			Title   string `json:"title"`
			Members int    `json:"members"`
			CRs     []struct {
				Email string `json:"email"`
			} `json:"crs"`
		} `json:"items"`
		Total int `json:"total"`
	}
	h.do("GET", "/admin/groups?q="+g.JoinCode, admin, nil).into(t, &list)
	require.Equal(t, 1, list.Total)
	assert.Equal(t, "CSE 61", list.Items[0].Title)
	assert.Equal(t, 2, list.Items[0].Members)
	assert.Equal(t, "cr@test.ac.bd", list.Items[0].CRs[0].Email)

	role := func(userID, role string) *response {
		return h.do("PUT", "/admin/groups/"+g.ID+"/members/"+userID, admin, map[string]string{"role": role})
	}
	assert.Equal(t, "LAST_CR", role(cr.User.ID, "member").code())
	assert.Equal(t, http.StatusNoContent, role(mate.User.ID, "cr").Status)
	assert.Equal(t, http.StatusNoContent, role(cr.User.ID, "member").Status)

	var detail struct {
		MemberList []struct {
			Email string `json:"email"`
			Role  string `json:"role"`
		} `json:"memberList"`
	}
	h.do("GET", "/admin/groups/"+g.ID, admin, nil).into(t, &detail)
	require.Len(t, detail.MemberList, 2)
	assert.Equal(t, "mate@test.ac.bd", detail.MemberList[0].Email, "CRs first")
	assert.Equal(t, "cr", detail.MemberList[0].Role)

	// Removing the only CR passes the role on.
	assert.Equal(t, http.StatusNoContent, h.do("DELETE", "/admin/groups/"+g.ID+"/members/"+mate.User.ID, admin, nil).Status)
	h.do("GET", "/admin/groups/"+g.ID, admin, nil).into(t, &detail)
	require.Len(t, detail.MemberList, 1)
	assert.Equal(t, "cr", detail.MemberList[0].Role)

	assert.Equal(t, http.StatusNoContent, h.do("DELETE", "/admin/groups/"+g.ID, admin, nil).Status)
	assert.Empty(t, h.myGroups(cr.Tokens.AccessToken))
}

func TestAdminSettingsPushStats(t *testing.T) {
	h := newHarness(t)
	admin := h.makeAdmin("admin@test.ac.bd")
	student := h.signIn("rafi@test.ac.bd")
	h.register(student.Tokens.AccessToken, "tok-rafi", "android", "bn")

	// Feature flags and the minimum build.
	r := h.do("PUT", "/admin/config/features", admin, map[string]any{"value": map[string]bool{"myClass": true, "campusVoice": true}})
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	assert.Equal(t, "CONFIG_VALUE_INVALID", h.do("PUT", "/admin/config/features", admin, map[string]any{"value": map[string]string{"x": "y"}}).code())
	assert.Equal(t, "CONFIG_VALUE_INVALID", h.do("PUT", "/admin/config/minSupportedBuild", admin, map[string]any{"value": 0}).code())
	assert.Equal(t, "CONFIG_KEY_UNKNOWN", h.do("PUT", "/admin/config/nope", admin, map[string]any{"value": 1}).code())
	var cfg map[string]json.RawMessage
	h.do("GET", "/config", "", nil).into(t, &cfg)
	assert.JSONEq(t, `{"myClass": true, "campusVoice": true}`, string(cfg["features"]))

	// Push to one student, in their language.
	var res struct {
		Users   int `json:"users"`
		Devices int `json:"devices"`
	}
	r = h.do("POST", "/admin/push", admin, map[string]string{
		"target": "user", "userId": student.User.ID, "title": "Hello", "body": "Test", "titleBn": "হ্যালো",
	})
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	r.into(t, &res)
	assert.Equal(t, 1, res.Devices)
	got := h.sent()["tok-rafi"]
	assert.Equal(t, "হ্যালো", got.Title)
	assert.Equal(t, "Test", got.Body, "Bangla body falls back to English")
	assert.Equal(t, "admin", got.Data["type"])
	assert.Equal(t, "VALIDATION_FAILED", h.do("POST", "/admin/push", admin, map[string]string{"target": "user", "title": "x", "body": "y"}).code())

	var stats struct {
		Users struct {
			Total  int `json:"total"`
			Admins int `json:"admins"`
		} `json:"users"`
		Devices struct {
			Android int `json:"android"`
		} `json:"devices"`
		SignupsByDay []struct {
			Date  string `json:"date"`
			Count int    `json:"count"`
		} `json:"signupsByDay"`
	}
	// Sign-up times on the harness clock (the database stamps real time).
	_, err := h.app.DB.Pool.Exec(context.Background(), `UPDATE users SET created_at = $1`, h.Now())
	require.NoError(t, err)
	h.do("GET", "/admin/stats", admin, nil).into(t, &stats)
	assert.Equal(t, 2, stats.Users.Total)
	assert.Equal(t, 1, stats.Users.Admins)
	assert.Equal(t, 1, stats.Devices.Android)
	require.Len(t, stats.SignupsByDay, 30)
	assert.Equal(t, "2026-10-27", stats.SignupsByDay[29].Date)
	assert.Equal(t, 2, stats.SignupsByDay[29].Count)
}
