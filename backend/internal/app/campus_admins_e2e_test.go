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

// ---- helpers ---------------------------------------------------------------------

type caStudent struct {
	Tok, ID, Refresh string
}

// caVerified signs in a student with a university email (verified by email).
func (h *harness) caVerified(email, name string) caStudent {
	h.t.Helper()
	s := h.signIn(email)
	require.Equal(h.t, http.StatusOK, h.do("PATCH", "/me", s.Tokens.AccessToken, map[string]string{"displayName": name}).Status)
	return caStudent{Tok: s.Tokens.AccessToken, ID: s.User.ID, Refresh: s.Tokens.RefreshToken}
}

// caUnverified: a Gmail student who picked the university.
func (h *harness) caUnverified(email, name, uniID string) caStudent {
	h.t.Helper()
	r := h.do("POST", "/auth/google", "", map[string]string{"idToken": h.googleToken(email, true)})
	require.Equal(h.t, http.StatusOK, r.Status, r.Raw)
	var out struct {
		Tokens tokens `json:"tokens"`
		User   meJSON `json:"user"`
	}
	r.into(h.t, &out)
	tok := out.Tokens.AccessToken
	require.Equal(h.t, http.StatusOK, h.do("PUT", "/me/university", tok, map[string]string{"universityId": uniID}).Status)
	require.Equal(h.t, http.StatusOK, h.do("PATCH", "/me", tok, map[string]string{"displayName": name}).Status)
	return caStudent{Tok: tok, ID: out.User.ID, Refresh: out.Tokens.RefreshToken}
}

// caOtherUniversity makes a second university with a verified student.
func (h *harness) caOtherUniversity() (uniID string, st caStudent) {
	h.t.Helper()
	_, err := h.app.DB.Pool.Exec(context.Background(), `
		WITH u AS (INSERT INTO universities (slug, name) VALUES ('other-uni', 'Other University') RETURNING id)
		INSERT INTO university_domains (domain, university_id) SELECT 'other.ac.bd', id FROM u`)
	require.NoError(h.t, err)
	return h.universityID("other-uni"), h.caVerified("zed@other.ac.bd", "Zed Other")
}

func (h *harness) caAppoint(central string, st caStudent) {
	h.t.Helper()
	r := h.do("POST", "/admin/campus-admins", central, map[string]string{"userId": st.ID})
	require.Equal(h.t, http.StatusCreated, r.Status, r.Raw)
}

type caStudentJSON struct {
	ID           string  `json:"id"`
	Name         string  `json:"name"`
	Verified     bool    `json:"verified"`
	Via          *string `json:"via"`
	Vouches      int     `json:"vouches"`
	VouchBlocked bool    `json:"vouchBlocked"`
	Groups       []struct {
		ID   string `json:"id"`
		Name string `json:"name"`
		Role string `json:"role"`
	} `json:"groups"`
	History []struct {
		Method    string  `json:"method"`
		RevokedAt *string `json:"revokedAt"`
		Reason    string  `json:"reason"`
		Actor     *struct {
			Name string `json:"name"`
		} `json:"actor"`
	} `json:"history"`
	VouchedBy []struct {
		Name string `json:"name"`
	} `json:"vouchedBy"`
	ConfirmedOrVouchedFor int `json:"confirmedOrVouchedFor"`
}

func (h *harness) caStudentGet(tok, id string) caStudentJSON {
	h.t.Helper()
	r := h.do("GET", "/campus-admin/students/"+id, tok, nil)
	require.Equal(h.t, http.StatusOK, r.Status, r.Raw)
	var s caStudentJSON
	r.into(h.t, &s)
	return s
}

type caVouchJSON struct {
	Student        struct{ ID, Name string } `json:"student"`
	University     struct{ Name string }     `json:"university"`
	Vouches        int                       `json:"vouches"`
	Needed         int                       `json:"needed"`
	Verified       bool                      `json:"verified"`
	AlreadyVouched bool                      `json:"alreadyVouched"`
	CanVouch       bool                      `json:"canVouch"`
	Reason         *string                   `json:"reason"`
}

type caMyVerification struct {
	Verified      bool    `json:"verified"`
	Via           *string `json:"via"`
	EmailPossible bool    `json:"emailPossible"`
	Vouches       int     `json:"vouches"`
	Needed        int     `json:"needed"`
	Code          *string `json:"code"`
	Link          *string `json:"link"`
	CRs           []struct {
		GroupID, GroupName, CRID, CRName string
	} `json:"crs"`
	VouchedBy []struct{ Name string } `json:"vouchedBy"`
}

func (h *harness) caMine(tok string) caMyVerification {
	h.t.Helper()
	r := h.do("GET", "/me/verification", tok, nil)
	require.Equal(h.t, http.StatusOK, r.Status, r.Raw)
	var v caMyVerification
	r.into(h.t, &v)
	return v
}

func (h *harness) caVouchGet(tok, code string) caVouchJSON {
	h.t.Helper()
	r := h.do("GET", "/vouch/"+code, tok, nil)
	require.Equal(h.t, http.StatusOK, r.Status, r.Raw)
	var v caVouchJSON
	r.into(h.t, &v)
	return v
}

func (h *harness) caExec(sql string, args ...any) {
	h.t.Helper()
	_, err := h.app.DB.Pool.Exec(context.Background(), sql, args...)
	require.NoError(h.t, err)
}

// ---- vouching ------------------------------------------------------------------------

func TestCampusVouchFlow(t *testing.T) {
	h := newHarness(t)
	uni := h.universityID("test-uni")
	a := h.caVerified("a@test.ac.bd", "Aisha")
	b := h.caVerified("b@test.ac.bd", "Bashar")
	c := h.caVerified("c@test.ac.bd", "Chowdhury")
	u := h.caUnverified("rafi@gmail.com", "Rafi", uni)
	x := h.caUnverified("xena@gmail.com", "Xena", uni)
	_, other := h.caOtherUniversity()
	h.register(u.Tok, "device-u", "android", "en")

	mine := h.caMine(u.Tok)
	assert.False(t, mine.Verified)
	assert.True(t, mine.EmailPossible)
	assert.Equal(t, 2, mine.Needed)
	require.NotNil(t, mine.Code)
	assert.Len(t, *mine.Code, 8)
	assert.Equal(t, "https://varsitykotha.com/v/"+*mine.Code, *mine.Link)
	assert.Equal(t, *mine.Code, *h.caMine(u.Tok).Code, "the code is made once")
	code := *mine.Code

	// Every refusal reason, on the page and on the vouch.
	reason := func(tok string) string {
		v := h.caVouchGet(tok, code)
		assert.False(t, v.CanVouch)
		require.NotNil(t, v.Reason)
		return *v.Reason
	}
	assert.Equal(t, "self", reason(u.Tok))
	assert.Equal(t, "not_verified", reason(x.Tok))
	assert.Equal(t, "other_university", reason(other.Tok))
	assert.Equal(t, "VOUCH_SELF", h.do("POST", "/vouch/"+code, u.Tok, nil).code())
	assert.Equal(t, "VERIFY_YOURSELF_FIRST", h.do("POST", "/vouch/"+code, x.Tok, nil).code())
	assert.Equal(t, "OTHER_UNIVERSITY", h.do("POST", "/vouch/"+code, other.Tok, nil).code())
	assert.Equal(t, "VOUCH_NOT_FOUND", h.do("GET", "/vouch/zzzzzzzz", a.Tok, nil).code())

	v := h.caVouchGet(a.Tok, code)
	assert.True(t, v.CanVouch)
	assert.Nil(t, v.Reason)
	assert.Equal(t, "Rafi", v.Student.Name)
	assert.Equal(t, "Test University", v.University.Name)
	assert.Equal(t, 2, v.Needed)

	// Verified-only actions refuse until verified.
	r, _ := h.postBlood(u.Tok, bloodBody("A+", h.Now().Add(5*time.Hour), false))
	assert.Equal(t, "VERIFY_REQUIRED", r.code())

	// First vouch: 1 of 2. Again is a no-op.
	r = h.do("POST", "/vouch/"+code, a.Tok, nil)
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	var after caVouchJSON
	r.into(t, &after)
	assert.Equal(t, 1, after.Vouches)
	assert.True(t, after.AlreadyVouched)
	assert.False(t, after.CanVouch)
	assert.False(t, after.Verified)
	require.Equal(t, http.StatusOK, h.do("POST", "/vouch/"+code, a.Tok, nil).Status)
	assert.Equal(t, 1, h.caMine(u.Tok).Vouches)
	assert.Empty(t, h.pushes(), "no push before verified")

	// Second vouch verifies.
	r = h.do("POST", "/vouch/"+code, b.Tok, nil)
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	r.into(t, &after)
	assert.True(t, after.Verified)
	assert.Equal(t, 2, after.Vouches)
	mine = h.caMine(u.Tok)
	assert.True(t, mine.Verified)
	assert.Equal(t, "vouch", *mine.Via)
	assert.Len(t, mine.VouchedBy, 2)

	// The push, in both languages.
	ns := h.pushes()
	require.Len(t, ns, 1)
	assert.Equal(t, "campus_verified", ns[0].Data["type"])
	assert.Equal(t, "You're verified at Test University", ns[0].Title)

	// The next token refresh carries it: a verified-only action works.
	rr := h.do("POST", "/auth/refresh", "", map[string]string{"refreshToken": u.Refresh})
	require.Equal(t, http.StatusOK, rr.Status, rr.Raw)
	var fresh tokens
	rr.into(t, &fresh)
	r, _ = h.postBlood(fresh.AccessToken, bloodBody("A+", h.Now().Add(5*time.Hour), false))
	assert.Equal(t, http.StatusCreated, r.Status, r.Raw)
	assert.True(t, h.me(fresh.AccessToken).Verified)

	// A verified student's link: nothing to vouch for.
	assert.Equal(t, "already_verified", reason(c.Tok))
	assert.Equal(t, "ALREADY_VERIFIED", h.do("POST", "/vouch/"+code, c.Tok, nil).code())

	// Five vouches in 30 days at most (a has done one: Rafi).
	for i := range 4 {
		st := h.caUnverified(fmt.Sprintf("kid%d@gmail.com", i), fmt.Sprintf("Kid %d", i), uni)
		cd := *h.caMine(st.Tok).Code
		require.Equal(t, http.StatusOK, h.do("POST", "/vouch/"+cd, a.Tok, nil).Status)
	}
	last := h.caUnverified("kid9@gmail.com", "Kid 9", uni)
	cd := *h.caMine(last.Tok).Code
	assert.Equal(t, "limit", func() string { v := h.caVouchGet(a.Tok, cd); return *v.Reason }())
	lr := h.do("POST", "/vouch/"+cd, a.Tok, nil)
	assert.Equal(t, "VOUCH_LIMIT", lr.code())
	assert.Equal(t, http.StatusTooManyRequests, lr.Status)

	// A vouch block stops vouching.
	h.caExec(`INSERT INTO vouch_blocks (user_id, reason) VALUES ($1, 'test')`, b.ID)
	assert.Equal(t, "VOUCH_BLOCKED", h.do("POST", "/vouch/"+cd, b.Tok, nil).code())
	assert.Equal(t, "blocked", func() string { v := h.caVouchGet(b.Tok, cd); return *v.Reason }())
}

// ---- CR confirms -----------------------------------------------------------------------

func TestCampusCRConfirm(t *testing.T) {
	h := newHarness(t)
	uni := h.universityID("test-uni")
	cr := h.caVerified("cr@test.ac.bd", "Rafi CR")
	mate := h.caVerified("mate@test.ac.bd", "Mate")
	g := h.createGroup(cr.Tok)
	u := h.caUnverified("new@gmail.com", "Newbie", uni)
	require.Equal(t, http.StatusOK, h.do("POST", "/groups/join", u.Tok, map[string]string{"code": g.JoinCode}).Status)
	require.Equal(t, http.StatusOK, h.do("POST", "/groups/join", mate.Tok, map[string]string{"code": g.JoinCode}).Status)
	h.register(u.Tok, "device-new", "android", "bn")

	// The newcomer sees the CR to ask.
	mine := h.caMine(u.Tok)
	require.Len(t, mine.CRs, 1)
	assert.Equal(t, "Rafi CR", mine.CRs[0].CRName)
	assert.Equal(t, "CSE 61", mine.CRs[0].GroupName)

	path := "/groups/" + g.ID + "/members/" + u.ID + "/confirm"
	assert.Equal(t, "NOT_CR", h.do("POST", path, mate.Tok, nil).code())
	assert.Equal(t, http.StatusForbidden, h.do("POST", path, mate.Tok, nil).Status)
	assert.Equal(t, "NOT_CR", h.do("POST", path, u.Tok, nil).code())

	// A member of another university.
	_, other := h.caOtherUniversity()
	h.caExec(`INSERT INTO class_group_members (group_id, user_id, role) VALUES ($1, $2, 'member')`, g.ID, other.ID)
	h.caExec(`UPDATE users SET verified_at = NULL, university_email = NULL WHERE id = $1`, other.ID)
	assert.Equal(t, "OTHER_UNIVERSITY", h.do("POST", "/groups/"+g.ID+"/members/"+other.ID+"/confirm", cr.Tok, nil).code())
	stranger := h.caVerified("stranger@test.ac.bd", "Stranger")
	assert.Equal(t, "MEMBER_NOT_FOUND", h.do("POST", "/groups/"+g.ID+"/members/"+stranger.ID+"/confirm", cr.Tok, nil).code())

	// A CR who isn't verified.
	gmailCR := h.caUnverified("crg@gmail.com", "Gmail CR", uni)
	g2 := h.createGroup(gmailCR.Tok)
	m2 := h.caUnverified("m2@gmail.com", "Member Two", uni)
	require.Equal(t, http.StatusOK, h.do("POST", "/groups/join", m2.Tok, map[string]string{"code": g2.JoinCode}).Status)
	assert.Equal(t, "VERIFY_YOURSELF_FIRST", h.do("POST", "/groups/"+g2.ID+"/members/"+m2.ID+"/confirm", gmailCR.Tok, nil).code())

	// The confirm.
	r := h.do("POST", path, cr.Tok, nil)
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	var m struct {
		UserID   string `json:"userId"`
		Name     string `json:"name"`
		Role     string `json:"role"`
		Verified bool   `json:"verified"`
	}
	r.into(t, &m)
	assert.Equal(t, u.ID, m.UserID)
	assert.True(t, m.Verified)
	assert.Equal(t, "cr", *h.caMine(u.Tok).Via)
	ns := h.pushes()
	require.Len(t, ns, 1)
	assert.Equal(t, "campus_verified", ns[0].Data["type"])
	assert.Equal(t, "Test University-এ তুমি এখন ভেরিফায়েড", ns[0].Title, "device language bn")
	assert.Equal(t, "ALREADY_VERIFIED", h.do("POST", path, cr.Tok, nil).code())

	// Eighty in 30 days at most.
	m3 := h.caUnverified("m3@gmail.com", "Third", uni)
	require.Equal(t, http.StatusOK, h.do("POST", "/groups/join", m3.Tok, map[string]string{"code": g.JoinCode}).Status)
	h.caExec(`INSERT INTO verification_events (user_id, university_id, method, actor_id, created_at)
		SELECT $1, $2, 'cr', $3, $4 FROM generate_series(1, 79)`, mate.ID, uni, cr.ID, h.Now())
	lr := h.do("POST", "/groups/"+g.ID+"/members/"+m3.ID+"/confirm", cr.Tok, nil)
	assert.Equal(t, "CONFIRM_LIMIT", lr.code())
	assert.Equal(t, http.StatusTooManyRequests, lr.Status)
}

// ---- campus admin scope, verify and unverify ----------------------------------------------

func TestCampusAdminScopeAndVerify(t *testing.T) {
	h := newHarness(t)
	uni := h.universityID("test-uni")
	central := h.makeAdmin("root@test.ac.bd")
	ca := h.caVerified("ca@test.ac.bd", "Campus Amin")
	plain := h.caVerified("plain@test.ac.bd", "Plain Student")
	u := h.caUnverified("v@gmail.com", "Vera", uni)
	otherUni, zed := h.caOtherUniversity()
	zedUnverified := h.caUnverified("zoe@gmail.com", "Zoe Other", otherUni)
	h.register(u.Tok, "device-v", "android", "en")

	// Not a campus admin yet: everything is 403 NOT_CAMPUS_ADMIN.
	for _, call := range [][2]string{
		{"GET", "/campus-admin/inbox"}, {"GET", "/campus-admin/students"}, {"GET", "/campus-admin/students/" + u.ID},
		{"POST", "/campus-admin/students/" + u.ID + "/verify"}, {"GET", "/campus-admin/sections"},
		{"GET", "/campus-admin/bus-reps"}, {"GET", "/campus-admin/reports"}, {"GET", "/campus-admin/blood"},
	} {
		r := h.do(call[0], call[1], plain.Tok, nil)
		assert.Equal(t, "NOT_CAMPUS_ADMIN", r.code(), call[1])
		assert.Equal(t, http.StatusForbidden, r.Status)
	}
	assert.False(t, h.meCampus(ca.Tok))

	// The central admin appoints.
	assert.Equal(t, http.StatusForbidden, h.do("POST", "/admin/campus-admins", plain.Tok, map[string]string{"userId": ca.ID}).Status)
	assert.Equal(t, "NOT_VERIFIED", h.do("POST", "/admin/campus-admins", central, map[string]string{"userId": u.ID}).code())
	h.caAppoint(central, ca)
	assert.True(t, h.meCampus(ca.Tok))
	assert.False(t, h.meCampus(plain.Tok))
	r := h.do("GET", "/admin/campus-admins?universityId="+uni, central, nil)
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	var list []struct {
		User        struct{ ID, Name, Email string } `json:"user"`
		University  struct{ ID, Name string }        `json:"university"`
		AppointedAt string                           `json:"appointedAt"`
	}
	r.into(t, &list)
	require.Len(t, list, 1)
	assert.Equal(t, "ca@test.ac.bd", list[0].User.Email)
	assert.Equal(t, "Test University", list[0].University.Name)

	// Students: names, never emails.
	r = h.do("GET", "/campus-admin/students?status=unverified", ca.Tok, nil)
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	var page struct {
		Items    []caStudentJSON `json:"items"`
		Total    int             `json:"total"`
		Page     int             `json:"page"`
		PageSize int             `json:"pageSize"`
	}
	r.into(t, &page)
	require.Len(t, page.Items, 1)
	assert.Equal(t, u.ID, page.Items[0].ID)
	assert.Equal(t, 1, page.Total)
	assert.Equal(t, 25, page.PageSize)
	for _, path := range []string{"/campus-admin/students?status=all", "/campus-admin/students/" + u.ID, "/campus-admin/inbox"} {
		raw := h.do("GET", path, ca.Tok, nil).Raw
		assert.NotContains(t, raw, "@test.ac.bd", path)
		assert.NotContains(t, raw, "@gmail.com", path)
	}
	r = h.do("GET", "/campus-admin/students?q=Plain", ca.Tok, nil)
	r.into(t, &page)
	require.Len(t, page.Items, 1)
	assert.Equal(t, "Plain Student", page.Items[0].Name)

	// Another university's student: not found, and absent from lists.
	for _, call := range [][3]any{
		{"GET", "/campus-admin/students/" + zed.ID, nil}, {"POST", "/campus-admin/students/" + zedUnverified.ID + "/verify", nil},
		{"POST", "/campus-admin/students/" + zed.ID + "/unverify", map[string]string{"reason": "x"}},
		{"PUT", "/campus-admin/students/" + zed.ID + "/vouch-block", map[string]string{"reason": "x"}},
		{"DELETE", "/campus-admin/students/" + zed.ID + "/vouch-block", nil},
	} {
		rr := h.do(call[0].(string), call[1].(string), ca.Tok, call[2])
		assert.Equal(t, "USER_NOT_FOUND", rr.code(), call[1])
		assert.Equal(t, http.StatusNotFound, rr.Status)
	}
	assert.NotContains(t, h.do("GET", "/campus-admin/students?status=all", ca.Tok, nil).Raw, "Zed")

	// Verify.
	r = h.do("POST", "/campus-admin/students/"+u.ID+"/verify", ca.Tok, nil)
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	var st caStudentJSON
	r.into(t, &st)
	assert.True(t, st.Verified)
	assert.Equal(t, "campus_admin", *st.Via)
	assert.Equal(t, "ALREADY_VERIFIED", h.do("POST", "/campus-admin/students/"+u.ID+"/verify", ca.Tok, nil).code())
	ns := h.pushes()
	require.Len(t, ns, 1)
	assert.Equal(t, "campus_verified", ns[0].Data["type"])
	assert.True(t, h.me(u.Tok).Verified)

	// Unverify needs a reason; email-proven verification is out of reach.
	assert.Equal(t, "VALIDATION_FAILED", h.do("POST", "/campus-admin/students/"+u.ID+"/unverify", ca.Tok, map[string]string{"reason": ""}).code())
	assert.Equal(t, "EMAIL_VERIFIED", h.do("POST", "/campus-admin/students/"+plain.ID+"/unverify", ca.Tok, map[string]string{"reason": "test"}).code())
	assert.Equal(t, http.StatusConflict, h.do("POST", "/campus-admin/students/"+plain.ID+"/unverify", ca.Tok, map[string]string{"reason": "test"}).Status)
	r = h.do("POST", "/campus-admin/students/"+u.ID+"/unverify", ca.Tok, map[string]string{"reason": "Not in our department"})
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	r.into(t, &st)
	assert.False(t, st.Verified)
	assert.Nil(t, st.Via)
	assert.False(t, h.me(u.Tok).Verified, "the next request sees it")
	assert.Equal(t, "NOT_VERIFIED", h.do("POST", "/campus-admin/students/"+u.ID+"/unverify", ca.Tok, map[string]string{"reason": "again"}).code())

	// History keeps every event, newest first.
	h.advance(time.Minute)
	require.Equal(t, http.StatusOK, h.do("POST", "/campus-admin/students/"+u.ID+"/verify", ca.Tok, nil).Status)
	d := h.caStudentGet(ca.Tok, u.ID)
	require.Len(t, d.History, 2)
	assert.Nil(t, d.History[0].RevokedAt)
	require.NotNil(t, d.History[1].RevokedAt)
	assert.Equal(t, "Not in our department", d.History[1].Reason)
	assert.Equal(t, "campus_admin", d.History[1].Method)
	assert.Equal(t, "Campus Amin", d.History[1].Actor.Name)
	// The email-verified student's history says so, with no actor.
	pd := h.caStudentGet(ca.Tok, plain.ID)
	require.Len(t, pd.History, 1)
	assert.Equal(t, "email", pd.History[0].Method)
	assert.Nil(t, pd.History[0].Actor)

	// A team member who verified by hand can't be undone by a campus admin.
	h.caExec(`UPDATE users SET verified_at = NULL WHERE id = $1`, u.ID)
	h.caExec(`UPDATE users SET verified_at = now() WHERE id = $1`, u.ID)
	assert.Equal(t, "admin", *h.caStudentGet(ca.Tok, u.ID).Via)
	assert.Equal(t, "ADMIN_VERIFIED", h.do("POST", "/campus-admin/students/"+u.ID+"/unverify", ca.Tok, map[string]string{"reason": "x"}).code())

	// Vouch block by hand, and off again.
	r = h.do("PUT", "/campus-admin/students/"+plain.ID+"/vouch-block", ca.Tok, map[string]string{"reason": "Vouched strangers"})
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	r.into(t, &st)
	assert.True(t, st.VouchBlocked)
	r = h.do("DELETE", "/campus-admin/students/"+plain.ID+"/vouch-block", ca.Tok, nil)
	r.into(t, &st)
	assert.False(t, st.VouchBlocked)

	// Campus admins: five at most.
	for i := range 4 {
		h.caAppoint(central, h.caVerified(fmt.Sprintf("more%d@test.ac.bd", i), fmt.Sprintf("More %d", i)))
	}
	extra := h.caVerified("extra@test.ac.bd", "Extra")
	lr := h.do("POST", "/admin/campus-admins", central, map[string]string{"userId": extra.ID})
	assert.Equal(t, "CAMPUS_ADMIN_LIMIT", lr.code())
	assert.Equal(t, http.StatusConflict, lr.Status)
	require.Equal(t, http.StatusNoContent, h.do("DELETE", "/admin/campus-admins/"+ca.ID, central, nil).Status)
	assert.False(t, h.meCampus(ca.Tok))
	assert.Equal(t, "CAMPUS_ADMIN_NOT_FOUND", h.do("DELETE", "/admin/campus-admins/"+ca.ID, central, nil).code())
	h.caAppoint(central, extra)
}

func (h *harness) meCampus(tok string) bool {
	h.t.Helper()
	r := h.do("GET", "/me", tok, nil)
	require.Equal(h.t, http.StatusOK, r.Status, r.Raw)
	var m struct {
		CampusAdmin bool `json:"campusAdmin"`
	}
	r.into(h.t, &m)
	return m.CampusAdmin
}

// ---- automatic vouch block ---------------------------------------------------------------------

func TestCampusAutoVouchBlock(t *testing.T) {
	h := newHarness(t)
	uni := h.universityID("test-uni")
	central := h.makeAdmin("root@test.ac.bd")
	ca := h.caVerified("ca@test.ac.bd", "Campus Amin")
	h.caAppoint(central, ca)
	cr := h.caVerified("cr@test.ac.bd", "Rafi CR")
	g := h.createGroup(cr.Tok)
	var kids []caStudent
	for i := range 3 {
		k := h.caUnverified(fmt.Sprintf("kid%d@gmail.com", i), fmt.Sprintf("Kid %d", i), uni)
		require.Equal(t, http.StatusOK, h.do("POST", "/groups/join", k.Tok, map[string]string{"code": g.JoinCode}).Status)
		require.Equal(t, http.StatusOK, h.do("POST", "/groups/"+g.ID+"/members/"+k.ID+"/confirm", cr.Tok, nil).Status)
		kids = append(kids, k)
	}
	unverify := func(k caStudent) {
		r := h.do("POST", "/campus-admin/students/"+k.ID+"/unverify", ca.Tok, map[string]string{"reason": "Not in the section"})
		require.Equal(t, http.StatusOK, r.Status, r.Raw)
	}
	unverify(kids[0])
	assert.False(t, h.caStudentGet(ca.Tok, cr.ID).VouchBlocked, "one is not enough")
	assert.Equal(t, 3, h.caStudentGet(ca.Tok, cr.ID).ConfirmedOrVouchedFor)
	unverify(kids[1])
	assert.True(t, h.caStudentGet(ca.Tok, cr.ID).VouchBlocked)

	// The central inbox lists it.
	r := h.do("GET", "/admin/inbox", central, nil)
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	var inbox struct {
		AutoVouchBlocks []struct {
			User   struct{ ID, Name string } `json:"user"`
			Reason string                    `json:"reason"`
		} `json:"autoVouchBlocks"`
	}
	r.into(t, &inbox)
	require.Len(t, inbox.AutoVouchBlocks, 1)
	assert.Equal(t, cr.ID, inbox.AutoVouchBlocks[0].User.ID)

	// The blocked CR can't confirm any more; unblocking restores it.
	assert.Equal(t, "VOUCH_BLOCKED", h.do("POST", "/groups/"+g.ID+"/members/"+kids[0].ID+"/confirm", cr.Tok, nil).code())
	require.Equal(t, http.StatusOK, h.do("DELETE", "/campus-admin/students/"+cr.ID+"/vouch-block", ca.Tok, nil).Status)
	require.Equal(t, http.StatusOK, h.do("POST", "/groups/"+g.ID+"/members/"+kids[0].ID+"/confirm", cr.Tok, nil).Status)

	// Two vouch-verified students taken away blocks both vouchers.
	va := h.caVerified("va@test.ac.bd", "Voucher A")
	vb := h.caVerified("vb@test.ac.bd", "Voucher B")
	for i := range 2 {
		k := h.caUnverified(fmt.Sprintf("vk%d@gmail.com", i), fmt.Sprintf("Vk %d", i), uni)
		cd := *h.caMine(k.Tok).Code
		require.Equal(t, http.StatusOK, h.do("POST", "/vouch/"+cd, va.Tok, nil).Status)
		require.Equal(t, http.StatusOK, h.do("POST", "/vouch/"+cd, vb.Tok, nil).Status)
		unverify(k)
		// Their vouches no longer count: two fresh ones are needed.
		assert.Equal(t, 0, h.caMine(k.Tok).Vouches)
	}
	assert.True(t, h.caStudentGet(ca.Tok, va.ID).VouchBlocked)
	assert.True(t, h.caStudentGet(ca.Tok, vb.ID).VouchBlocked)
}

// ---- sections and bus reps ---------------------------------------------------------------------

type caSection struct {
	ID             string `json:"id"`
	Name           string `json:"name"`
	Term           string `json:"term"`
	Members        int    `json:"members"`
	LastActivityAt string `json:"lastActivityAt"`
	CR             []struct {
		ID   string `json:"id"`
		Name string `json:"name"`
	} `json:"cr"`
}

func (h *harness) caSections(tok string) []caSection {
	h.t.Helper()
	r := h.do("GET", "/campus-admin/sections", tok, nil)
	require.Equal(h.t, http.StatusOK, r.Status, r.Raw)
	var s []caSection
	r.into(h.t, &s)
	return s
}

func TestCampusSections(t *testing.T) {
	h := newHarness(t)
	uni := h.universityID("test-uni")
	central := h.makeAdmin("root@test.ac.bd")
	ca := h.caVerified("ca@test.ac.bd", "Campus Amin")
	h.caAppoint(central, ca)
	cr := h.caVerified("cr@test.ac.bd", "Rafi CR")
	mate := h.caVerified("mate@test.ac.bd", "Mate")
	gmail := h.caUnverified("g@gmail.com", "Gee", uni)
	g := h.createGroup(cr.Tok)
	for _, s := range []caStudent{mate, gmail} {
		require.Equal(t, http.StatusOK, h.do("POST", "/groups/join", s.Tok, map[string]string{"code": g.JoinCode}).Status)
	}
	otherUni, zed := h.caOtherUniversity()
	_ = otherUni
	og := h.createGroup(zed.Tok)

	secs := h.caSections(ca.Tok)
	require.Len(t, secs, 1)
	assert.Equal(t, "CSE 61", secs[0].Name)
	assert.Equal(t, "Fall 2026", secs[0].Term)
	assert.Equal(t, 3, secs[0].Members)
	require.Len(t, secs[0].CR, 1)
	assert.Equal(t, "Rafi CR", secs[0].CR[0].Name)

	path := "/campus-admin/sections/" + g.ID
	assert.Equal(t, "NOT_VERIFIED", h.do("PUT", path+"/cr", ca.Tok, map[string]string{"userId": gmail.ID}).code())
	assert.Equal(t, "GROUP_NOT_FOUND", h.do("PUT", "/campus-admin/sections/"+og.ID+"/cr", ca.Tok, map[string]string{"userId": zed.ID}).code())
	assert.Equal(t, "MEMBER_NOT_FOUND", h.do("PUT", path+"/cr", ca.Tok, map[string]string{"userId": "00000000-0000-0000-0000-0000000000aa"}).code())
	r := h.do("PUT", path+"/cr", ca.Tok, map[string]string{"userId": mate.ID})
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	var after []caSection
	r.into(t, &after)
	assert.Len(t, after[0].CR, 2)
	// The new CR can use CR powers.
	require.Equal(t, http.StatusOK, h.do("POST", "/groups/"+g.ID+"/members/"+gmail.ID+"/confirm", mate.Tok, nil).Status)

	assert.Equal(t, "CR_NOT_FOUND", h.do("DELETE", path+"/cr/"+gmail.ID, ca.Tok, nil).code())
	r = h.do("DELETE", path+"/cr/"+cr.ID, ca.Tok, nil)
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	r.into(t, &after)
	require.Len(t, after[0].CR, 1)
	assert.Equal(t, "Mate", after[0].CR[0].Name)
	assert.Equal(t, "LAST_CR", h.do("DELETE", path+"/cr/"+mate.ID, ca.Tok, nil).code())
	assert.Equal(t, "GROUP_NOT_FOUND", h.do("DELETE", "/campus-admin/sections/"+og.ID+"/cr/"+zed.ID, ca.Tok, nil).code())

	// A section left without a CR (e.g. the account was deleted) comes first.
	g2 := h.createGroup(h.caVerified("cr2@test.ac.bd", "CR Two").Tok)
	h.caExec(`DELETE FROM class_group_members WHERE group_id = $1 AND role = 'cr'`, g2.ID)
	h.caExec(`UPDATE class_groups SET batch = '10' WHERE id = $1`, g2.ID)
	secs = h.caSections(ca.Tok)
	require.Len(t, secs, 2)
	assert.Equal(t, g2.ID, secs[0].ID)
	assert.Empty(t, secs[0].CR)
	var inbox struct {
		SectionsWithoutCr int `json:"sectionsWithoutCr"`
		WaitingCount      int `json:"waitingCount"`
	}
	h.do("GET", "/campus-admin/inbox", ca.Tok, nil).into(t, &inbox)
	assert.Equal(t, 1, inbox.SectionsWithoutCr)
}

func TestCampusBusReps(t *testing.T) {
	h := newHarness(t)
	central := h.makeAdmin("root@test.ac.bd")
	ca := h.caVerified("ca@test.ac.bd", "Campus Amin")
	h.caAppoint(central, ca)
	rep := h.caVerified("rep@test.ac.bd", "Bus Rep")
	_, zed := h.caOtherUniversity()

	assert.Equal(t, "USER_NOT_FOUND", h.do("PUT", "/campus-admin/bus-reps", ca.Tok, map[string]string{"userId": zed.ID}).code())
	r := h.do("PUT", "/campus-admin/bus-reps", ca.Tok, map[string]string{"userId": rep.ID})
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	var reps struct {
		Items []struct {
			UserID     string  `json:"userId"`
			Email      string  `json:"email"`
			Name       *string `json:"name"`
			University string  `json:"university"`
		} `json:"items"`
	}
	r.into(t, &reps)
	require.Len(t, reps.Items, 1)
	assert.Equal(t, rep.ID, reps.Items[0].UserID)
	assert.Equal(t, "Bus Rep", *reps.Items[0].Name)
	assert.Empty(t, reps.Items[0].Email, "campus admins never see emails")
	assert.NotContains(t, r.Raw, "@test.ac.bd")

	// The rep really is a transport rep (the admin list sees them).
	assert.Contains(t, h.do("GET", "/admin/transport/reps", central, nil).Raw, rep.ID)
	r = h.do("GET", "/campus-admin/bus-reps", ca.Tok, nil)
	r.into(t, &reps)
	assert.Len(t, reps.Items, 1)

	assert.Equal(t, "REP_NOT_FOUND", h.do("DELETE", "/campus-admin/bus-reps/"+zed.ID, ca.Tok, nil).code())
	require.Equal(t, http.StatusNoContent, h.do("DELETE", "/campus-admin/bus-reps/"+rep.ID, ca.Tok, nil).Status)
	r = h.do("GET", "/campus-admin/bus-reps", ca.Tok, nil)
	r.into(t, &reps)
	assert.Empty(t, reps.Items)
	assert.NotContains(t, h.do("GET", "/admin/transport/reps", central, nil).Raw, rep.ID)
}

// ---- reports and blood -----------------------------------------------------------------------------

type caReport struct {
	Kind      string         `json:"kind"`
	ID        string         `json:"id"`
	IssueID   string         `json:"issueId"`
	Excerpt   string         `json:"excerpt"`
	Reports   int            `json:"reports"`
	Reasons   map[string]int `json:"reasons"`
	CreatedAt string         `json:"createdAt"`
	Hidden    bool           `json:"hidden"`
}

func (h *harness) caReports(tok string) []caReport {
	h.t.Helper()
	r := h.do("GET", "/campus-admin/reports", tok, nil)
	require.Equal(h.t, http.StatusOK, r.Status, r.Raw)
	var rs []caReport
	r.into(h.t, &rs)
	return rs
}

func TestCampusReports(t *testing.T) {
	h := newHarness(t)
	h.voiceOn(true)
	central := h.makeAdmin("root@test.ac.bd")
	ca := h.caVerified("ca@test.ac.bd", "Campus Amin")
	h.caAppoint(central, ca)
	author := h.caVerified("author@test.ac.bd", "Author")
	mate := h.caVerified("mate@test.ac.bd", "Mate")
	otherUni, zed := h.caOtherUniversity()
	_ = otherUni
	zedAdmin := zed
	h.caAppoint(central, zedAdmin)

	is := h.postIssue(author.Tok, issueBody("Broken water pump in Hall 3"))
	cm := h.comment(mate.Tok, is.ID, map[string]any{"body": "Totally agree with this one"})
	assert.Empty(t, h.caReports(ca.Tok))
	require.Equal(t, http.StatusNoContent, h.do("POST", "/issues/"+is.ID+"/report", mate.Tok, map[string]string{"reason": "false_info", "details": "Not true"}).Status)
	require.Equal(t, http.StatusNoContent, h.do("POST", "/issues/"+is.ID+"/comments/"+cm.ID+"/report", author.Tok, map[string]string{"reason": "spam"}).Status)

	rs := h.caReports(ca.Tok)
	require.Len(t, rs, 2)
	byKind := map[string]caReport{}
	for _, r := range rs {
		byKind[r.Kind] = r
	}
	assert.Equal(t, is.ID, byKind["issue"].ID)
	assert.Equal(t, 1, byKind["issue"].Reasons["false_info"])
	assert.Equal(t, 1, byKind["issue"].Reports)
	assert.Equal(t, cm.ID, byKind["comment"].ID)
	assert.Equal(t, is.ID, byKind["comment"].IssueID)
	assert.Contains(t, byKind["comment"].Excerpt, "Totally agree")
	assert.False(t, byKind["issue"].Hidden)
	assert.Empty(t, h.caReports(zedAdmin.Tok), "another university's campus admin sees none")
	var inbox struct {
		Reports int `json:"reports"`
	}
	h.do("GET", "/campus-admin/inbox", ca.Tok, nil).into(t, &inbox)
	assert.Equal(t, 2, inbox.Reports)

	// Scoped: the other university's admin can't touch it.
	for _, p := range []string{"/campus-admin/reports/issue/" + is.ID, "/campus-admin/reports/comment/" + cm.ID} {
		assert.Contains(t, []string{"ISSUE_NOT_FOUND", "COMMENT_NOT_FOUND"}, h.do("POST", p, zedAdmin.Tok, map[string]string{"action": "hide"}).code())
	}
	assert.Equal(t, "NOT_CAMPUS_ADMIN", h.do("POST", "/campus-admin/reports/issue/"+is.ID, mate.Tok, map[string]string{"action": "hide"}).code())
	assert.Equal(t, "VALIDATION_FAILED", h.do("POST", "/campus-admin/reports/issue/"+is.ID, ca.Tok, map[string]string{"action": "remove"}).code())

	// Hide, then restore.
	require.Equal(t, http.StatusNoContent, h.do("POST", "/campus-admin/reports/issue/"+is.ID, ca.Tok, map[string]string{"action": "hide"}).Status)
	assert.Equal(t, "hidden", h.getIssue(author.Tok, is.ID).Visibility)
	assert.Equal(t, "ISSUE_NOT_FOUND", h.do("GET", "/issues/"+is.ID, mate.Tok, nil).code())
	require.Equal(t, http.StatusNoContent, h.do("POST", "/campus-admin/reports/issue/"+is.ID, ca.Tok, map[string]string{"action": "restore"}).Status)
	assert.Equal(t, "visible", h.getIssue(author.Tok, is.ID).Visibility)

	// Dismiss clears the report.
	require.Equal(t, http.StatusNoContent, h.do("POST", "/campus-admin/reports/comment/"+cm.ID, ca.Tok, map[string]string{"action": "dismiss"}).Status)
	require.Equal(t, http.StatusNoContent, h.do("POST", "/campus-admin/reports/issue/"+is.ID, ca.Tok, map[string]string{"action": "dismiss"}).Status)
	assert.Empty(t, h.caReports(ca.Tok))

	var audits int
	require.NoError(t, h.app.DB.Pool.QueryRow(context.Background(),
		`SELECT count(*) FROM audit_log WHERE action LIKE 'campus.report_%' OR action LIKE 'moderation.%'`).Scan(&audits))
	assert.GreaterOrEqual(t, audits, 4)
}

func TestCampusBlood(t *testing.T) {
	h := newHarness(t)
	central := h.makeAdmin("root@test.ac.bd")
	ca := h.caVerified("ca@test.ac.bd", "Campus Amin")
	h.caAppoint(central, ca)
	asker := h.caVerified("asker@test.ac.bd", "Asker")
	_, zed := h.caOtherUniversity()
	h.caAppoint(central, zed)

	r, b := h.postBlood(asker.Tok, bloodBody("O+", h.Now().Add(6*time.Hour), true))
	require.Equal(t, http.StatusCreated, r.Status, r.Raw)

	r = h.do("GET", "/campus-admin/blood", ca.Tok, nil)
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	var list []struct {
		ID        string `json:"id"`
		Status    string `json:"status"`
		Hospital  string `json:"hospital"`
		Requester *struct {
			Name  string `json:"name"`
			Email string `json:"email"`
		} `json:"requester"`
	}
	r.into(t, &list)
	require.Len(t, list, 1)
	assert.Equal(t, b.ID, list[0].ID)
	assert.Equal(t, "Asker", list[0].Requester.Name)
	assert.Empty(t, list[0].Requester.Email)
	assert.NotContains(t, r.Raw, "asker@test.ac.bd")
	h.do("GET", "/campus-admin/blood", zed.Tok, nil).into(t, &list)
	assert.Empty(t, list)

	assert.Equal(t, "BLOOD_REQUEST_NOT_FOUND", h.do("POST", "/campus-admin/blood/"+b.ID+"/close", zed.Tok, map[string]string{"reason": "x"}).code())
	assert.Equal(t, "NOT_CAMPUS_ADMIN", h.do("POST", "/campus-admin/blood/"+b.ID+"/close", asker.Tok, nil).code())
	r = h.do("POST", "/campus-admin/blood/"+b.ID+"/close", ca.Tok, map[string]string{"reason": "Duplicate"})
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	assert.NotContains(t, r.Raw, "asker@test.ac.bd")
	assert.Equal(t, "closed", h.bloodGet(asker.Tok, b.ID).Status)
	assert.Equal(t, "BLOOD_REQUEST_NOT_OPEN", h.do("POST", "/campus-admin/blood/"+b.ID+"/close", ca.Tok, nil).code())
	h.do("GET", "/campus-admin/blood", ca.Tok, nil).into(t, &list)
	assert.Empty(t, list)
	var n int
	require.NoError(t, h.app.DB.Pool.QueryRow(context.Background(), `SELECT count(*) FROM audit_log WHERE action = 'campus.blood_close'`).Scan(&n))
	assert.Equal(t, 1, n)
}

// ---- escalations, inbox, domains, health -------------------------------------------------------------

func TestCampusEscalationAndInbox(t *testing.T) {
	h := newHarness(t)
	uni := h.universityID("test-uni")
	central := h.makeAdmin("root@test.ac.bd")
	ca := h.caVerified("ca@test.ac.bd", "Campus Amin")
	h.caAppoint(central, ca)
	otherUni, _ := h.caOtherUniversity()
	for i := range 5 {
		h.caUnverified(fmt.Sprintf("o%d@gmail.com", i), fmt.Sprintf("O %d", i), otherUni)
	}
	_ = uni

	assert.Equal(t, "VALIDATION_FAILED", h.do("POST", "/campus-admin/escalations", ca.Tok, map[string]string{"kind": "weird", "note": "x"}).code())
	assert.Equal(t, "VALIDATION_FAILED", h.do("POST", "/campus-admin/escalations", ca.Tok, map[string]string{"kind": "other", "note": ""}).code())
	assert.Equal(t, "NOT_CAMPUS_ADMIN", h.do("POST", "/campus-admin/escalations", central, map[string]string{"kind": "other", "note": "hi"}).code())
	r := h.do("POST", "/campus-admin/escalations", ca.Tok, map[string]string{"kind": "student", "targetId": ca.ID, "note": "This student claims two accounts"})
	require.Equal(t, http.StatusCreated, r.Status, r.Raw)
	var esc struct {
		ID         string                `json:"id"`
		Kind       string                `json:"kind"`
		Note       string                `json:"note"`
		TargetID   string                `json:"targetId"`
		University struct{ Name string } `json:"university"`
		CreatedBy  struct{ Name string } `json:"createdBy"`
	}
	r.into(t, &esc)

	type inboxT struct {
		Escalations []struct {
			ID string `json:"id"`
		} `json:"escalations"`
		DomainRequests                 []any `json:"domainRequests"`
		UniversitiesWithoutCampusAdmin []struct {
			Name     string `json:"name"`
			Students int    `json:"students"`
		} `json:"universitiesWithoutCampusAdmin"`
		AutoVouchBlocks []any `json:"autoVouchBlocks"`
		ReportsWaiting  int   `json:"reportsWaiting"`
		FeedbackNew     int   `json:"feedbackNew"`
	}
	var inbox inboxT
	r = h.do("GET", "/admin/inbox", central, nil)
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	r.into(t, &inbox)
	require.Len(t, inbox.Escalations, 1)
	assert.Equal(t, esc.ID, inbox.Escalations[0].ID)
	assert.Equal(t, "Test University", esc.University.Name)
	assert.Equal(t, "Campus Amin", esc.CreatedBy.Name)
	require.Len(t, inbox.UniversitiesWithoutCampusAdmin, 1)
	assert.Equal(t, "Other University", inbox.UniversitiesWithoutCampusAdmin[0].Name)
	assert.GreaterOrEqual(t, inbox.UniversitiesWithoutCampusAdmin[0].Students, 5)
	assert.NotNil(t, inbox.DomainRequests)
	assert.NotNil(t, inbox.AutoVouchBlocks)
	assert.Equal(t, http.StatusForbidden, h.do("GET", "/admin/inbox", ca.Tok, nil).Status)

	r = h.do("POST", "/admin/escalations/"+esc.ID+"/resolve", central, map[string]string{"resolution": "Handled"})
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	assert.Equal(t, "ESCALATION_RESOLVED", h.do("POST", "/admin/escalations/"+esc.ID+"/resolve", central, map[string]string{"resolution": "again"}).code())
	assert.Equal(t, "ESCALATION_NOT_FOUND", h.do("POST", "/admin/escalations/00000000-0000-0000-0000-0000000000aa/resolve", central, map[string]string{}).code())
	h.do("GET", "/admin/inbox", central, nil).into(t, &inbox)
	assert.Empty(t, inbox.Escalations)

	// Appointing there clears the "no campus admin" line.
	zed := h.caVerified("zed@other.ac.bd", "Zed")
	_ = zed
	h.caAppoint(central, zed)
	h.do("GET", "/admin/inbox", central, nil).into(t, &inbox)
	assert.Empty(t, inbox.UniversitiesWithoutCampusAdmin)
}

func TestCampusDomainRequests(t *testing.T) {
	h := newHarnessWith(t, func(o *Options) {
		o.MXLookup = func(_ context.Context, domain string) bool { return domain == "good.edu.bd" }
	})
	central := h.makeAdmin("root@test.ac.bd")
	uni := h.universityID("test-uni")

	req := func(email string, extra map[string]string) *response {
		body := map[string]string{"email": email}
		for k, v := range extra {
			body[k] = v
		}
		return h.do("POST", "/universities/domain-requests", "", body)
	}
	assert.Equal(t, "VALIDATION_FAILED", req("not-an-email", nil).code())
	r := req("Nadia@Good.edu.bd", map[string]string{"universityName": "Good University"})
	assert.Equal(t, http.StatusAccepted, r.Status, r.Raw)
	assert.Equal(t, http.StatusAccepted, req("x@nomail.edu.bd", map[string]string{"universityId": uni}).Status)
	assert.Equal(t, http.StatusAccepted, req("Nadia@Good.edu.bd", nil).Status, "same email again is a no-op")

	// Not recognized yet.
	assert.Equal(t, "UNIVERSITY_EMAIL_REQUIRED", h.do("POST", "/auth/code", "", map[string]string{"email": "nadia@good.edu.bd"}).code())

	type dr struct {
		ID             string                     `json:"id"`
		Domain         string                     `json:"domain"`
		Email          string                     `json:"email"`
		MXOk           bool                       `json:"mxOk"`
		Status         string                     `json:"status"`
		UniversityName string                     `json:"universityName"`
		University     *struct{ ID, Name string } `json:"university"`
	}
	var page struct {
		Items []dr `json:"items"`
		Total int  `json:"total"`
	}
	r = h.do("GET", "/admin/domain-requests", central, nil)
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	r.into(t, &page)
	require.Equal(t, 2, page.Total)
	by := map[string]dr{}
	for _, d := range page.Items {
		by[d.Domain] = d
	}
	assert.True(t, by["good.edu.bd"].MXOk)
	assert.Equal(t, "nadia@good.edu.bd", by["good.edu.bd"].Email)
	assert.Equal(t, "Good University", by["good.edu.bd"].UniversityName)
	assert.False(t, by["nomail.edu.bd"].MXOk)
	assert.Equal(t, "Test University", by["nomail.edu.bd"].University.Name)

	var inbox struct {
		DomainRequests []dr `json:"domainRequests"`
	}
	h.do("GET", "/admin/inbox", central, nil).into(t, &inbox)
	assert.Len(t, inbox.DomainRequests, 2)

	// Approve: the domain is added; a bad or taken one is refused.
	id := by["good.edu.bd"].ID
	assert.Equal(t, "UNIVERSITY_NOT_FOUND", h.do("POST", "/admin/domain-requests/"+id+"/approve", central,
		map[string]string{"universityId": "00000000-0000-0000-0000-0000000000aa"}).code())
	r = h.do("POST", "/admin/domain-requests/"+id+"/approve", central, map[string]string{"universityId": uni})
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	var done dr
	r.into(t, &done)
	assert.Equal(t, "approved", done.Status)
	assert.Equal(t, "DOMAIN_REQUEST_DECIDED", h.do("POST", "/admin/domain-requests/"+id+"/reject", central, nil).code())
	var n int
	require.NoError(t, h.app.DB.Pool.QueryRow(context.Background(),
		`SELECT count(*) FROM university_domains WHERE domain = 'good.edu.bd' AND university_id = $1`, uni).Scan(&n))
	assert.Equal(t, 1, n)
	require.Equal(t, http.StatusAccepted, h.do("POST", "/auth/code", "", map[string]string{"email": "nadia@good.edu.bd"}).Status)

	// Reject the other.
	r = h.do("POST", "/admin/domain-requests/"+by["nomail.edu.bd"].ID+"/reject", central, nil)
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	r = h.do("GET", "/admin/domain-requests?status=rejected", central, nil)
	r.into(t, &page)
	assert.Equal(t, 1, page.Total)
	r = h.do("GET", "/admin/domain-requests", central, nil)
	r.into(t, &page)
	assert.Equal(t, 0, page.Total)
	assert.Equal(t, "DOMAIN_REQUEST_NOT_FOUND", h.do("POST", "/admin/domain-requests/00000000-0000-0000-0000-0000000000aa/reject", central, nil).code())
}

func TestCampusUniversityHealth(t *testing.T) {
	h := newHarness(t)
	h.voiceOn(true)
	uni := h.universityID("test-uni")
	central := h.makeAdmin("root@test.ac.bd")
	otherUni, _ := h.caOtherUniversity()

	type row struct {
		ID              string   `json:"id"`
		Name            string   `json:"name"`
		Students        int      `json:"students"`
		Verified        int      `json:"verified"`
		VerifiedPct     int      `json:"verifiedPct"`
		CampusAdmins    int      `json:"campusAdmins"`
		Sections        int      `json:"sections"`
		SectionsWithCr  int      `json:"sectionsWithCr"`
		BusRoutes       int      `json:"busRoutes"`
		OpenReports     int      `json:"openReports"`
		OpenEscalations int      `json:"openEscalations"`
		Attention       []string `json:"attention"`
	}
	get := func(query string) (map[string]row, []row) {
		r := h.do("GET", "/admin/universities/health"+query, central, nil)
		require.Equal(t, http.StatusOK, r.Status, r.Raw)
		var p struct {
			Items []row `json:"items"`
			Total int   `json:"total"`
		}
		r.into(t, &p)
		m := map[string]row{}
		for _, x := range p.Items {
			m[x.Name] = x
		}
		return m, p.Items
	}

	// Test University: 12 students, 3 verified, no campus admin, a section
	// without a CR, a reported post. Other University: healthy and tiny.
	cr := h.caVerified("cr@test.ac.bd", "CR")
	h.caVerified("v2@test.ac.bd", "V2")
	for i := range 9 {
		h.caUnverified(fmt.Sprintf("u%d@gmail.com", i), fmt.Sprintf("U %d", i), uni)
	}
	g := h.createGroup(cr.Tok)
	h.caExec(`DELETE FROM class_group_members WHERE group_id = $1 AND role = 'cr'`, g.ID)
	is := h.postIssue(h.caVerified("author@test.ac.bd", "Author").Tok, issueBody("Broken water pump in Hall 3"))
	h.do("POST", "/issues/"+is.ID+"/report", cr.Tok, map[string]string{"reason": "spam"})
	h.caExec(`INSERT INTO escalations (university_id, kind, note) VALUES ($1, 'other', 'x')`, uni)
	h.caExec(`INSERT INTO bus_routes (university_id, name) VALUES ($1, 'Route 1')`, uni)

	m, items := get("")
	tu := m["Test University"]
	assert.Equal(t, 13, tu.Students)
	assert.Equal(t, 4, tu.Verified)
	assert.Equal(t, 30, tu.VerifiedPct)
	assert.Equal(t, 0, tu.CampusAdmins)
	assert.Equal(t, 1, tu.Sections)
	assert.Equal(t, 0, tu.SectionsWithCr)
	assert.Equal(t, 1, tu.BusRoutes)
	assert.Equal(t, 1, tu.OpenReports)
	assert.Equal(t, 1, tu.OpenEscalations)
	assert.ElementsMatch(t, []string{"no_campus_admin", "sections_without_cr", "reports_waiting", "low_verified"}, tu.Attention)
	ou := m["Other University"]
	assert.Equal(t, 1, ou.Students)
	assert.Empty(t, ou.Attention, "tiny and fine")
	assert.NotNil(t, ou.Attention, "an empty list, not null")
	assert.Equal(t, "Test University", items[0].Name, "most students first")

	// Sorting and search.
	_, byPct := get("?sort=verifiedPct")
	assert.Equal(t, "Test University", byPct[0].Name)
	_, byAtt := get("?sort=attention")
	assert.Equal(t, "Test University", byAtt[0].Name)
	m, _ = get("?q=other")
	assert.Len(t, m, 1)
	assert.Equal(t, http.StatusForbidden, h.do("GET", "/admin/universities/health", cr.Tok, nil).Status)

	// Appointing a campus admin drops that reason.
	h.caAppoint(central, cr)
	m, _ = get("")
	assert.NotContains(t, m["Test University"].Attention, "no_campus_admin")
	assert.Equal(t, 1, m["Test University"].CampusAdmins)
	_ = otherUni
	assert.True(t, strings.Contains(h.do("GET", "/admin/universities/health", central, nil).Raw, `"pageSize"`))
}
