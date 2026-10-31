package app

import (
	"context"
	"fmt"
	"net/http"
	"sort"
	"strings"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/zamansheikh/varsitykotha/backend/internal/modules/push"
)

// The harness clock is Tuesday 27 October 2026, 15:00 in Dhaka (09:00 UTC).

type bloodDonorJSON struct {
	BloodGroup    string  `json:"bloodGroup"`
	Available     bool    `json:"available"`
	Phone         string  `json:"phone"`
	LastDonated   *string `json:"lastDonated"`
	Donations     int     `json:"donations"`
	CanDonateFrom *string `json:"canDonateFrom"`
	Eligible      bool    `json:"eligible"`
}

type bloodResponseJSON struct {
	Name       string `json:"name"`
	BloodGroup string `json:"bloodGroup"`
	Phone      string `json:"phone"`
}

type bloodReqJSON struct {
	ID             string              `json:"id"`
	BloodGroup     string              `json:"bloodGroup"`
	Units          int                 `json:"units"`
	Hospital       string              `json:"hospital"`
	Area           string              `json:"area"`
	NeededBy       time.Time           `json:"neededBy"`
	Urgent         bool                `json:"urgent"`
	ContactName    string              `json:"contactName"`
	ContactPhone   string              `json:"contactPhone"`
	Status         string              `json:"status"`
	ResponseCount  int                 `json:"responseCount"`
	Notified       int                 `json:"notified"`
	MatchingDonors int                 `json:"matchingDonors"`
	Mine           bool                `json:"mine"`
	Responded      bool                `json:"responded"`
	Responses      []bloodResponseJSON `json:"responses"`
}

type bloodPageJSON struct {
	Items      []bloodReqJSON `json:"items"`
	NextCursor *string        `json:"nextCursor"`
}

// bloodUser signs a verified student in and names them.
func (h *harness) bloodUser(email, name string) string {
	h.t.Helper()
	tok := h.signIn(email).Tokens.AccessToken
	r := h.do("PATCH", "/me", tok, map[string]string{"displayName": name})
	require.Equal(h.t, http.StatusOK, r.Status, r.Raw)
	return tok
}

// bloodDonor makes tok a donor.
func (h *harness) bloodDonor(tok, group, phone string, available bool, last *string) bloodDonorJSON {
	h.t.Helper()
	r := h.do("PUT", "/blood/me", tok, map[string]any{"bloodGroup": group, "available": available, "phone": phone, "lastDonated": last})
	require.Equal(h.t, http.StatusOK, r.Status, r.Raw)
	var d bloodDonorJSON
	r.into(h.t, &d)
	return d
}

func bloodBody(group string, neededBy time.Time, urgent bool) map[string]any {
	return map[string]any{
		"bloodGroup": group, "units": 2, "hospital": "Enam Medical College Hospital", "area": "Savar",
		"neededBy": neededBy.UTC().Format(time.RFC3339), "urgent": urgent,
		"contactName": "Rafi", "contactPhone": "01712345678", "note": "Thalassemia patient",
	}
}

func (h *harness) postBlood(tok string, body map[string]any) (*response, bloodReqJSON) {
	h.t.Helper()
	r := h.do("POST", "/blood/requests", tok, body)
	var b bloodReqJSON
	if r.Status == http.StatusCreated {
		r.into(h.t, &b)
	}
	return r, b
}

func (h *harness) bloodGet(tok, id string) bloodReqJSON {
	h.t.Helper()
	r := h.do("GET", "/blood/requests/"+id, tok, nil)
	require.Equal(h.t, http.StatusOK, r.Status, r.Raw)
	var b bloodReqJSON
	r.into(h.t, &b)
	return b
}

func (h *harness) bloodList(tok, query string) bloodPageJSON {
	h.t.Helper()
	r := h.do("GET", "/blood/requests?"+query, tok, nil)
	require.Equal(h.t, http.StatusOK, r.Status, r.Raw)
	var p bloodPageJSON
	r.into(h.t, &p)
	return p
}

// pushes waits for background sends and returns everything sent.
func (h *harness) pushes() []push.Notification {
	h.app.Push.Wait()
	return h.push.Take()
}

func tokensOf(ns []push.Notification) []string {
	out := make([]string, 0, len(ns))
	for _, n := range ns {
		out = append(out, n.Token)
	}
	sort.Strings(out)
	return out
}

func TestBloodDonorProfile(t *testing.T) {
	h := newHarness(t)
	tok := h.bloodUser("rafi@test.ac.bd", "Rafi")

	var none struct {
		Donor *bloodDonorJSON `json:"donor"`
	}
	r := h.do("GET", "/blood/me", tok, nil)
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	r.into(t, &none)
	assert.Nil(t, none.Donor)
	assert.Contains(t, r.Raw, `"donor":null`)

	assert.Equal(t, "DONOR_REQUIRED", h.do("POST", "/blood/me/donated", tok, map[string]string{}).code())

	// Validation.
	put := func(b map[string]any) *response { return h.do("PUT", "/blood/me", tok, b) }
	assert.Equal(t, "VALIDATION_FAILED", put(map[string]any{"bloodGroup": "C+", "available": true}).code())
	assert.Equal(t, "VALIDATION_FAILED", put(map[string]any{"bloodGroup": "A+", "available": true, "phone": "12345"}).code())
	assert.Equal(t, "VALIDATION_FAILED", put(map[string]any{"bloodGroup": "A+", "available": true, "lastDonated": "2026-10-28"}).code(), "tomorrow")
	assert.Equal(t, "VALIDATION_FAILED", put(map[string]any{"bloodGroup": "A+", "available": true, "lastDonated": "yesterday"}).code())

	// Bangla digits and +88 are fine; stored as 01XXXXXXXXX.
	last := "2026-07-01"
	d := h.bloodDonor(tok, "A+", "+৮৮০১৭১২-৩৪৫৬৭৮", true, &last)
	assert.Equal(t, "01712345678", d.Phone)
	require.NotNil(t, d.LastDonated)
	assert.Equal(t, "2026-07-01", *d.LastDonated)
	require.NotNil(t, d.CanDonateFrom)
	assert.Equal(t, "2026-10-29", *d.CanDonateFrom, "119 days on 27 Oct")
	assert.False(t, d.Eligible)

	// Exactly 120 days ago (29 Jun) is eligible, 119 days (30 Jun) is not.
	edge := "2026-06-29"
	d = h.bloodDonor(tok, "A+", "", true, &edge)
	assert.True(t, d.Eligible)
	assert.Equal(t, "2026-10-27", *d.CanDonateFrom)
	edge = "2026-06-30"
	d = h.bloodDonor(tok, "A+", "", true, &edge)
	assert.False(t, d.Eligible)
	assert.Equal(t, "2026-10-28", *d.CanDonateFrom)
	var got struct {
		Donor bloodDonorJSON `json:"donor"`
	}
	r = h.do("GET", "/blood/me", tok, nil)
	r.into(t, &got)
	assert.Equal(t, d, got.Donor)

	// Not available: not eligible, no matter the date.
	d = h.bloodDonor(tok, "A+", "", false, nil)
	assert.False(t, d.Eligible)
	assert.Nil(t, d.LastDonated)
	assert.Nil(t, d.CanDonateFrom, "never donated: now")
	assert.Equal(t, "", d.Phone)
	d = h.bloodDonor(tok, "A+", "01712345678", true, nil)
	assert.True(t, d.Eligible)

	// "I donated": today by default; an older date counts but doesn't move last.
	r = h.do("POST", "/blood/me/donated", tok, map[string]string{})
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	r.into(t, &d)
	assert.Equal(t, 1, d.Donations)
	assert.Equal(t, "2026-10-27", *d.LastDonated)
	assert.Equal(t, "2027-02-24", *d.CanDonateFrom)
	assert.False(t, d.Eligible)
	r = h.do("POST", "/blood/me/donated", tok, map[string]string{"date": "2026-01-05"})
	r.into(t, &d)
	assert.Equal(t, 2, d.Donations)
	assert.Equal(t, "2026-10-27", *d.LastDonated)
	assert.Equal(t, "VALIDATION_FAILED", h.do("POST", "/blood/me/donated", tok, map[string]string{"date": "2030-01-01"}).code())

	// Updating keeps the count; stopping removes the profile.
	d = h.bloodDonor(tok, "O-", "", true, nil)
	assert.Equal(t, 2, d.Donations)
	require.Equal(t, http.StatusNoContent, h.do("DELETE", "/blood/me", tok, nil).Status)
	assert.Contains(t, h.do("GET", "/blood/me", tok, nil).Raw, `"donor":null`)
}

func TestBloodVerifyAndUniversityRequired(t *testing.T) {
	h := newHarness(t)
	tok, _ := h.gmailSignIn("rafi.student@gmail.com")

	// No university yet.
	assert.Equal(t, "UNIVERSITY_REQUIRED", h.do("GET", "/blood/me", tok, nil).code())
	assert.Equal(t, "UNIVERSITY_REQUIRED", h.do("GET", "/blood/requests", tok, nil).code())

	require.Equal(t, http.StatusOK, h.do("PUT", "/me/university", tok, map[string]string{"universityId": h.universityID("test-uni")}).Status)

	// Not verified: can be a donor, can't ask for blood.
	h.bloodDonor(tok, "B+", "01712345678", true, nil)
	r, _ := h.postBlood(tok, bloodBody("A+", h.Now().Add(5*time.Hour), false))
	assert.Equal(t, http.StatusForbidden, r.Status)
	assert.Equal(t, "VERIFY_REQUIRED", r.code())

	// ...and can respond to a verified student's request.
	req := h.bloodUser("asker@test.ac.bd", "Asker")
	_, b := h.postBlood(req, bloodBody("B+", h.Now().Add(5*time.Hour), false))
	r = h.do("POST", "/blood/requests/"+b.ID+"/respond", tok, map[string]string{"phone": "01712345678"})
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
}

func TestBloodPostValidation(t *testing.T) {
	h := newHarness(t)
	tok := h.bloodUser("rafi@test.ac.bd", "Rafi")
	now := h.Now()
	with := func(k string, v any) map[string]any {
		b := bloodBody("A+", now.Add(5*time.Hour), false)
		b[k] = v
		return b
	}
	for name, body := range map[string]map[string]any{
		"group":       with("bloodGroup", "X+"),
		"units 0":     with("units", 0),
		"units 11":    with("units", 11),
		"hospital":    with("hospital", " a "),
		"area":        with("area", strings.Repeat("x", 81)),
		"contactName": with("contactName", "  "),
		"phone":       with("contactPhone", "0171234"),
		"landline":    with("contactPhone", "029876543"),
		"note":        with("note", strings.Repeat("x", 501)),
		"past":        with("neededBy", now.Add(-2*time.Hour).UTC().Format(time.RFC3339)),
		"too far":     with("neededBy", now.AddDate(0, 0, 31).UTC().Format(time.RFC3339)),
		"no neededBy": with("neededBy", nil),
	} {
		r, _ := h.postBlood(tok, body)
		assert.Equal(t, "VALIDATION_FAILED", r.code(), name+": "+r.Raw)
	}
	// An hour ago and a month ahead are fine; Bangla digits in the phone too.
	b := bloodBody("A+", now.Add(-50*time.Minute), false)
	b["contactPhone"] = "০১৭১২ ৩৪৫৬৭৮"
	r, got := h.postBlood(tok, b)
	require.Equal(t, http.StatusCreated, r.Status, r.Raw)
	assert.Equal(t, "01712345678", got.ContactPhone)
	assert.Equal(t, "open", got.Status)
	assert.True(t, got.Mine)
	assert.Empty(t, got.Responses)
	assert.Contains(t, r.Raw, `"responses":[]`)
	r, _ = h.postBlood(tok, bloodBody("O-", now.AddDate(0, 0, 30).Add(-time.Minute), false))
	require.Equal(t, http.StatusCreated, r.Status, r.Raw)
}

func TestBloodOpenViewOrderExpiryAndScope(t *testing.T) {
	h := newHarness(t)
	_, err := h.app.DB.Pool.Exec(context.Background(), `
		WITH u AS (INSERT INTO universities (slug, name, name_bn) VALUES ('other-uni', 'Other University', 'অন্য') RETURNING id)
		INSERT INTO university_domains (domain, university_id) SELECT 'other.ac.bd', id FROM u`)
	require.NoError(t, err)

	a := h.bloodUser("a@test.ac.bd", "A")
	b := h.bloodUser("b@test.ac.bd", "B")
	c := h.bloodUser("c@test.ac.bd", "C")
	outsider := h.bloodUser("out@other.ac.bd", "Out")
	now := h.Now()

	_, later := h.postBlood(a, bloodBody("A+", now.Add(10*time.Hour), false))
	_, soon := h.postBlood(b, bloodBody("O+", now.Add(2*time.Hour), false))
	_, urgentFar := h.postBlood(c, bloodBody("A+", now.Add(48*time.Hour), true))
	h.advance(time.Second)
	_, urgentNear := h.postBlood(c, bloodBody("B-", now.Add(20*time.Hour), true))

	ids := func(p bloodPageJSON) []string {
		out := []string{}
		for _, x := range p.Items {
			out = append(out, x.ID)
		}
		return out
	}
	assert.Equal(t, []string{urgentNear.ID, urgentFar.ID, soon.ID, later.ID}, ids(h.bloodList(a, "view=open")), "urgent first, then soonest")
	assert.Equal(t, []string{urgentFar.ID, later.ID}, ids(h.bloodList(a, "view=open&group=A%2B")))
	assert.Equal(t, "VALIDATION_FAILED", h.do("GET", "/blood/requests?group=Z", a, nil).code())
	assert.Equal(t, "BAD_CURSOR", h.do("GET", "/blood/requests?cursor=xyz", a, nil).code())

	// Another university sees nothing and gets 404.
	assert.Empty(t, h.bloodList(outsider, "view=open").Items)
	for _, call := range [][2]string{{"GET", ""}, {"POST", "/respond"}, {"DELETE", "/respond"}, {"POST", "/close"}} {
		var body any
		if call[1] == "/respond" && call[0] == "POST" {
			body = map[string]string{"phone": "01712345678"}
		}
		if call[1] == "/close" {
			body = map[string]bool{"fulfilled": true}
		}
		h.bloodDonor(outsider, "A+", "01712345678", true, nil)
		r := h.do(call[0], "/blood/requests/"+later.ID+call[1], outsider, body)
		assert.Equal(t, http.StatusNotFound, r.Status, call[0]+call[1]+r.Raw)
		assert.Equal(t, "BLOOD_REQUEST_NOT_FOUND", r.code())
	}
	assert.Equal(t, "BLOOD_REQUEST_NOT_FOUND", h.do("GET", "/blood/requests/00000000-0000-0000-0000-000000000001", a, nil).code())

	// "mine" lists every status, newest first.
	require.Equal(t, http.StatusOK, h.do("POST", "/blood/requests/"+urgentFar.ID+"/close", c, map[string]bool{"fulfilled": true}).Status)
	mine := h.bloodList(c, "view=mine")
	assert.Equal(t, []string{urgentNear.ID, urgentFar.ID}, ids(mine))
	assert.Equal(t, "fulfilled", mine.Items[1].Status)
	assert.Equal(t, []string{urgentNear.ID, soon.ID, later.ID}, ids(h.bloodList(a, "")))

	// Expiry: more than a day after neededBy it leaves the open view and
	// reads as "expired"; the stored status stays open.
	h.advance(2*time.Hour + 24*time.Hour - 5*time.Minute)
	a, b = h.signIn("a@test.ac.bd").Tokens.AccessToken, h.signIn("b@test.ac.bd").Tokens.AccessToken // tokens last 15 minutes
	assert.Contains(t, ids(h.bloodList(a, "view=open")), soon.ID, "just under a day late")
	h.advance(4 * time.Minute)
	assert.NotContains(t, ids(h.bloodList(a, "view=open")), soon.ID)
	assert.Equal(t, "expired", h.bloodGet(b, soon.ID).Status)
	assert.Equal(t, "expired", h.bloodList(b, "view=mine").Items[0].Status)
	var stored string
	require.NoError(t, h.app.DB.Pool.QueryRow(context.Background(), `SELECT status FROM blood_requests WHERE id = $1`, soon.ID).Scan(&stored))
	assert.Equal(t, "open", stored)

	// Can't respond to an expired request; the requester can still close it.
	d := h.bloodUser("d@test.ac.bd", "D")
	h.bloodDonor(d, "O+", "01712345678", true, nil)
	assert.Equal(t, "REQUEST_CLOSED", h.do("POST", "/blood/requests/"+soon.ID+"/respond", d, map[string]string{"phone": "01712345678"}).code())
	assert.Equal(t, http.StatusOK, h.do("POST", "/blood/requests/"+soon.ID+"/close", b, map[string]bool{"fulfilled": false}).Status)
}

func TestBloodPagination(t *testing.T) {
	h := newHarness(t)
	tok := h.bloodUser("a@test.ac.bd", "A")
	var uid, uni string
	require.NoError(t, h.app.DB.Pool.QueryRow(context.Background(), `SELECT id, university_id FROM users WHERE email = 'a@test.ac.bd'`).Scan(&uid, &uni))
	for i := 0; i < 25; i++ {
		_, err := h.app.DB.Pool.Exec(context.Background(), `
			INSERT INTO blood_requests (university_id, requester_id, blood_group, hospital, needed_by, urgent, contact_name, contact_phone, created_at)
			VALUES ($1, $2, 'A+', 'Hospital', $3, $4, 'A', '01712345678', $5)`,
			uni, uid, h.Now().Add(time.Duration(i+1)*time.Hour), i%5 == 0, h.Now().Add(-time.Duration(i)*time.Minute))
		require.NoError(t, err)
	}
	for _, view := range []string{"open", "mine"} {
		var seen []bloodReqJSON
		q := "view=" + view
		pages := 0
		for {
			p := h.bloodList(tok, q)
			pages++
			seen = append(seen, p.Items...)
			if p.NextCursor == nil {
				break
			}
			assert.Len(t, p.Items, 20)
			q = "view=" + view + "&cursor=" + *p.NextCursor
		}
		assert.Equal(t, 2, pages, view)
		require.Len(t, seen, 25, view)
		uniq := map[string]bool{}
		for i, x := range seen {
			uniq[x.ID] = true
			if view == "open" && i > 0 {
				prev := seen[i-1]
				ok := (prev.Urgent && !x.Urgent) || (prev.Urgent == x.Urgent && prev.NeededBy.Before(x.NeededBy))
				assert.True(t, ok, "order at %d", i)
			}
		}
		assert.Len(t, uniq, 25, view)
	}
}

func TestBloodPushes(t *testing.T) {
	h := newHarness(t)
	_, err := h.app.DB.Pool.Exec(context.Background(), `
		WITH u AS (INSERT INTO universities (slug, name, name_bn) VALUES ('other-uni', 'Other University', 'অন্য') RETURNING id)
		INSERT INTO university_domains (domain, university_id) SELECT 'other.ac.bd', id FROM u`)
	require.NoError(t, err)

	requester := h.bloodUser("req@test.ac.bd", "Req")
	h.register(requester, "phone-req", "android", "en")
	h.bloodDonor(requester, "A+", "01712345678", true, nil) // the requester is a donor too

	type spec struct {
		email, group string
		available    bool
		last         *string
		lang         string
	}
	old, recent := "2026-06-01", "2026-09-01" // 148 days ago, 56 days ago
	boundary := "2026-06-29"                  // exactly 120 days before 27 Oct
	tooRecent := "2026-06-30"
	specs := []spec{
		{"eligible1@test.ac.bd", "A+", true, nil, "en"},
		{"eligible2@test.ac.bd", "A+", true, &old, "bn"},
		{"boundary@test.ac.bd", "A+", true, &boundary, "en"},
		{"rested@test.ac.bd", "A+", true, &tooRecent, "en"},
		{"recent@test.ac.bd", "A+", true, &recent, "en"},
		{"away@test.ac.bd", "A+", false, nil, "en"},
		{"otherGroup@test.ac.bd", "A-", true, nil, "en"},
		{"o@test.ac.bd", "O-", true, nil, "en"},
		{"outsider@other.ac.bd", "A+", true, nil, "en"},
	}
	toks := map[string]string{}
	for _, s := range specs {
		tok := h.bloodUser(s.email, strings.Split(s.email, "@")[0])
		toks[s.email] = tok
		h.bloodDonor(tok, s.group, "", s.available, s.last)
		h.register(tok, "phone-"+strings.Split(s.email, "@")[0], "android", s.lang)
	}
	nonDonor := h.bloodUser("plain@test.ac.bd", "Plain")
	h.register(nonDonor, "phone-plain", "android", "en")

	// 3:00 PM today in Dhaka; urgent.
	need := time.Date(2026, 10, 27, 15, 0, 0, 0, time.FixedZone("BDT", 6*3600))
	r, req := h.postBlood(requester, bloodBody("A+", need.Add(24*time.Hour), true))
	require.Equal(t, http.StatusCreated, r.Status, r.Raw)
	sent := h.pushes()
	assert.Equal(t, []string{"phone-boundary", "phone-eligible1", "phone-eligible2"}, tokensOf(sent),
		"same group, available, 120+ days, same university, not the requester")
	assert.Equal(t, 3, req.Notified)
	// Donors of the group at the university: the requester, the 6 other A+ ones (not the other university).
	assert.Equal(t, 7, req.MatchingDonors)
	for _, n := range sent {
		assert.Equal(t, map[string]string{"type": "blood_request", "requestId": req.ID}, n.Data)
		if n.Token == "phone-eligible2" {
			assert.Equal(t, "A+ রক্ত প্রয়োজন, জরুরি", n.Title)
			assert.Equal(t, "Enam Medical College Hospital, Savar · আগামীকাল ৩:০০ PM", n.Body)
		} else {
			assert.Equal(t, "A+ blood needed, urgent", n.Title)
			assert.Equal(t, "Enam Medical College Hospital, Savar · tomorrow 3:00 PM", n.Body)
		}
	}
	// notified is stored and shown on reads; matching count for everyone.
	assert.Equal(t, 3, h.bloodGet(requester, req.ID).Notified)
	assert.Equal(t, 7, h.bloodGet(toks["o@test.ac.bd"], req.ID).MatchingDonors)

	// A second request: the same donors again (2 of 3 pushes today).
	_, _ = h.postBlood(requester, bloodBody("A+", need.Add(30*time.Hour), false))
	assert.Equal(t, []string{"phone-boundary", "phone-eligible1", "phone-eligible2"}, tokensOf(h.pushes()))
	// The third one reaches them for the last time...
	_, third := h.postBlood(requester, bloodBody("A+", need.Add(31*time.Hour), false))
	assert.Equal(t, 3, third.Notified)
	assert.Len(t, h.pushes(), 3)
	// ...the fourth (after closing one, to stay under 3 open) reaches nobody: 3 a day.
	require.Equal(t, http.StatusOK, h.do("POST", "/blood/requests/"+third.ID+"/close", requester, map[string]bool{"fulfilled": true}).Status)
	r, fourth := h.postBlood(requester, bloodBody("A+", need.Add(32*time.Hour), false))
	assert.Equal(t, "TOO_MANY_REQUESTS", r.code(), "3 requests a day for the requester")
	_ = fourth

	// Someone else posts: the 3-a-day cap per donor holds.
	other := h.bloodUser("other@test.ac.bd", "Other")
	_, o1 := h.postBlood(other, bloodBody("A+", need.Add(24*time.Hour), false))
	assert.Equal(t, 1, o1.Notified, "only the first requester (a donor too); the others have had 3 today")
	assert.Equal(t, []string{"phone-req"}, tokensOf(h.pushes()))
	// The window is rolling: a day later they can be told again.
	h.advance(24*time.Hour + time.Minute)
	other = h.signIn("other@test.ac.bd").Tokens.AccessToken
	_, o2 := h.postBlood(other, bloodBody("A+", h.Now().Add(5*time.Hour), false))
	assert.Equal(t, 5, o2.Notified, "the 3, the first requester, and 'rested' (120 days by now)")
	assert.Len(t, h.pushes(), 5)

	// Rows: exactly one notice per (request, donor).
	var n int
	require.NoError(t, h.app.DB.Pool.QueryRow(context.Background(), `SELECT count(*) FROM blood_notices WHERE request_id = $1`, req.ID).Scan(&n))
	assert.Equal(t, 3, n)
	require.NoError(t, h.app.DB.Pool.QueryRow(context.Background(), `SELECT count(*) FROM blood_notices n JOIN blood_requests r ON r.id = n.request_id WHERE r.requester_id = n.user_id`).Scan(&n))
	assert.Equal(t, 0, n, "never the requester")
}

func TestBloodPushCap(t *testing.T) {
	h := newHarness(t)
	h.app.Blood.SetMaxDonorsPerRequest(4)
	requester := h.bloodUser("req@test.ac.bd", "Req")
	for i := 0; i < 6; i++ {
		tok := h.bloodUser(fmt.Sprintf("d%d@test.ac.bd", i), "Donor")
		h.bloodDonor(tok, "B+", "", true, nil)
		h.register(tok, fmt.Sprintf("phone-%d", i), "android", "en")
	}
	_, req := h.postBlood(requester, bloodBody("B+", h.Now().Add(5*time.Hour), false))
	assert.Equal(t, 4, req.Notified)
	assert.Equal(t, 6, req.MatchingDonors)
	assert.Len(t, h.pushes(), 4)
}

func TestBloodRespondPrivacyAndClose(t *testing.T) {
	h := newHarness(t)
	requester := h.bloodUser("req@test.ac.bd", "Rafi Ahmed")
	h.register(requester, "phone-req", "android", "en")
	donor := h.bloodUser("nusrat@test.ac.bd", "Nusrat Jahan")
	other := h.bloodUser("other@test.ac.bd", "Other Student")
	third := h.bloodUser("third@test.ac.bd", "Third Student")
	h.bloodDonor(donor, "A+", "", true, nil) // no phone on the profile yet
	h.bloodDonor(third, "A+", "01999999999", true, nil)
	h.bloodDonor(requester, "A+", "01700000000", true, nil)

	need := h.Now().Add(6 * time.Hour)
	_, req := h.postBlood(requester, bloodBody("A+", need, false))
	h.pushes()
	path := "/blood/requests/" + req.ID

	// Validation and eligibility to respond.
	assert.Equal(t, "VALIDATION_FAILED", h.do("POST", path+"/respond", donor, map[string]string{"phone": ""}).code())
	assert.Equal(t, "VALIDATION_FAILED", h.do("POST", path+"/respond", donor, map[string]string{"phone": "123"}).code())
	assert.Equal(t, "CANNOT_RESPOND_OWN", h.do("POST", path+"/respond", requester, map[string]string{"phone": "01700000000"}).code())
	assert.Equal(t, "DONOR_REQUIRED", h.do("POST", path+"/respond", other, map[string]string{"phone": "01712345678"}).code())
	assert.Equal(t, http.StatusConflict, h.do("POST", path+"/respond", other, map[string]string{"phone": "01712345678"}).Status)

	// Respond; the phone is saved to the donor's profile.
	r := h.do("POST", path+"/respond", donor, map[string]string{"phone": "০১৮১২৩৪৫৬৭৮"})
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	var got bloodReqJSON
	r.into(t, &got)
	assert.True(t, got.Responded)
	assert.Equal(t, 1, got.ResponseCount)
	assert.Empty(t, got.Responses, "a donor doesn't see responses")
	assert.NotContains(t, r.Raw, "01812345678")
	var me struct {
		Donor bloodDonorJSON `json:"donor"`
	}
	h.do("GET", "/blood/me", donor, nil).into(t, &me)
	assert.Equal(t, "01812345678", me.Donor.Phone)

	// The requester gets one push; asking again is idempotent (no second push).
	sent := h.pushes()
	require.Len(t, sent, 1)
	assert.Equal(t, "phone-req", sent[0].Token)
	assert.Equal(t, "Nusrat Jahan can donate A+", sent[0].Title)
	assert.Equal(t, "Tap to call", sent[0].Body)
	assert.Equal(t, map[string]string{"type": "blood_response", "requestId": req.ID}, sent[0].Data)
	r = h.do("POST", path+"/respond", donor, map[string]string{"phone": "01812345678"})
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	assert.Empty(t, h.pushes())
	assert.Equal(t, 1, h.bloodGet(requester, req.ID).ResponseCount)

	// A donor who already has a phone keeps it.
	h.advance(time.Second) // responses are listed in the order they came
	require.Equal(t, http.StatusOK, h.do("POST", path+"/respond", third, map[string]string{"phone": "01555555555"}).Status)
	h.do("GET", "/blood/me", third, nil).into(t, &me)
	assert.Equal(t, "01999999999", me.Donor.Phone)
	h.pushes()

	// Privacy: names, groups and phones reach the requester only.
	mine := h.bloodGet(requester, req.ID)
	require.Len(t, mine.Responses, 2)
	assert.Equal(t, 2, mine.ResponseCount)
	assert.Equal(t, bloodResponseJSON{Name: "Nusrat Jahan", BloodGroup: "A+", Phone: "01812345678"}, mine.Responses[0])
	assert.Equal(t, "01555555555", mine.Responses[1].Phone)
	secrets := []string{"01812345678", "01555555555", "Nusrat Jahan", "Third Student"}
	rawViews := map[string]string{
		"get other":   h.do("GET", path, other, nil).Raw,
		"get donor":   h.do("GET", path, donor, nil).Raw,
		"list other":  h.do("GET", "/blood/requests?view=open", other, nil).Raw,
		"list donor":  h.do("GET", "/blood/requests", donor, nil).Raw,
		"mine other":  h.do("GET", "/blood/requests?view=mine", other, nil).Raw,
		"get third":   h.do("GET", path, third, nil).Raw,
		"list third":  h.do("GET", "/blood/requests", third, nil).Raw,
		"respond own": h.do("POST", path+"/respond", donor, map[string]string{"phone": "01812345678"}).Raw,
	}
	for name, raw := range rawViews {
		if !strings.Contains(raw, `"items":[]`) {
			assert.Contains(t, raw, `"responses":[]`, name)
		}
		for _, s := range secrets {
			assert.NotContains(t, raw, s, name)
		}
	}
	// The requester's list entries carry responses too.
	list := h.bloodList(requester, "view=open")
	require.Len(t, list.Items, 1)
	assert.Len(t, list.Items[0].Responses, 2)
	assert.True(t, list.Items[0].Mine)

	// Withdraw.
	r = h.do("DELETE", path+"/respond", third, nil)
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	r.into(t, &got)
	assert.False(t, got.Responded)
	assert.Equal(t, 1, got.ResponseCount)
	assert.Equal(t, http.StatusOK, h.do("DELETE", path+"/respond", third, nil).Status, "withdrawing twice is fine")
	assert.Len(t, h.bloodGet(requester, req.ID).Responses, 1)

	// Stopping being a donor keeps the response (blood group then unknown).
	require.Equal(t, http.StatusNoContent, h.do("DELETE", "/blood/me", donor, nil).Status)
	assert.Len(t, h.bloodGet(requester, req.ID).Responses, 1)

	// Close: requester only; open only.
	assert.Equal(t, "BLOOD_REQUEST_NOT_FOUND", h.do("POST", path+"/close", other, map[string]bool{"fulfilled": true}).code())
	assert.Equal(t, "BLOOD_REQUEST_NOT_FOUND", h.do("POST", path+"/close", donor, map[string]bool{"fulfilled": true}).code())
	r = h.do("POST", path+"/close", requester, map[string]bool{"fulfilled": true})
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	r.into(t, &got)
	assert.Equal(t, "fulfilled", got.Status)
	assert.Equal(t, "REQUEST_CLOSED", h.do("POST", path+"/close", requester, map[string]bool{"fulfilled": false}).code())
	assert.Equal(t, "REQUEST_CLOSED", h.do("POST", path+"/respond", third, map[string]string{"phone": "01555555555"}).code())
	assert.Empty(t, h.bloodList(other, "view=open").Items, "closed leaves the open view")

	// Cancelled.
	_, req2 := h.postBlood(requester, bloodBody("A+", need, false))
	r = h.do("POST", "/blood/requests/"+req2.ID+"/close", requester, map[string]bool{"fulfilled": false})
	r.into(t, &got)
	assert.Equal(t, "closed", got.Status)
}

func TestBloodLimits(t *testing.T) {
	h := newHarness(t)
	tok := h.bloodUser("rafi@test.ac.bd", "Rafi")
	need := h.Now().Add(5 * time.Hour)
	var ids []string
	for i := 0; i < 3; i++ {
		r, b := h.postBlood(tok, bloodBody("A+", need, false))
		require.Equal(t, http.StatusCreated, r.Status, r.Raw)
		ids = append(ids, b.ID)
	}
	r, _ := h.postBlood(tok, bloodBody("A+", need, false))
	assert.Equal(t, http.StatusConflict, r.Status)
	assert.Equal(t, "TOO_MANY_OPEN_REQUESTS", r.code())

	// Closing frees an open slot, but the daily limit of 3 holds.
	require.Equal(t, http.StatusOK, h.do("POST", "/blood/requests/"+ids[0]+"/close", tok, map[string]bool{"fulfilled": true}).Status)
	r, _ = h.postBlood(tok, bloodBody("A+", need, false))
	assert.Equal(t, http.StatusTooManyRequests, r.Status)
	assert.Equal(t, "TOO_MANY_REQUESTS", r.code())

	// A day later it works again.
	h.advance(24*time.Hour + time.Minute)
	tok = h.signIn("rafi@test.ac.bd").Tokens.AccessToken
	r, _ = h.postBlood(tok, bloodBody("A+", h.Now().Add(5*time.Hour), false))
	assert.Equal(t, http.StatusCreated, r.Status, r.Raw)
}

func TestBloodRespondLimit(t *testing.T) {
	h := newHarness(t)
	donor := h.bloodUser("donor@test.ac.bd", "Donor")
	h.bloodDonor(donor, "A+", "01712345678", true, nil)
	asker := h.bloodUser("asker@test.ac.bd", "Asker")
	_, req := h.postBlood(asker, bloodBody("A+", h.Now().Add(5*time.Hour), false))
	for i := 0; i < 30; i++ {
		r := h.do("POST", "/blood/requests/"+req.ID+"/respond", donor, map[string]string{"phone": "01712345678"})
		require.Equal(t, http.StatusOK, r.Status, "%d: %s", i, r.Raw)
	}
	assert.Equal(t, "TOO_MANY_REQUESTS", h.do("POST", "/blood/requests/"+req.ID+"/respond", donor, map[string]string{"phone": "01712345678"}).code())
}
