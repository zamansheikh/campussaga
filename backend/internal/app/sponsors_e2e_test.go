package app

import (
	"bytes"
	"context"
	"crypto/rand"
	"encoding/json"
	"image"
	_ "image/jpeg"
	"io"
	"mime/multipart"
	"net/http"
	"strings"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/zamansheikh/varsitykotha/backend/internal/platform/config"
)

// ---- helpers ------------------------------------------------------------------------

// newSponsorHarness: access tokens outlive the clock jumps of these tests
// (days, a week), so students needn't refresh.
func newSponsorHarness(t *testing.T) *harness {
	t.Helper()
	return newHarnessFull(t, nil, func(c *config.Config) { c.AccessTTL = 90 * 24 * time.Hour })
}

type spSponsor struct {
	ID           string  `json:"id"`
	Name         string  `json:"name"`
	Category     string  `json:"category"`
	LogoURL      *string `json:"logoUrl"`
	Website      string  `json:"website"`
	ContactEmail string  `json:"contactEmail"`
	ArchivedAt   *string `json:"archivedAt"`
	Promos       struct {
		Live  int `json:"live"`
		Total int `json:"total"`
	} `json:"promos"`
}

type spAdminPromo struct {
	ID      string `json:"id"`
	Sponsor struct {
		ID       string  `json:"id"`
		Name     string  `json:"name"`
		Category string  `json:"category"`
		LogoURL  *string `json:"logoUrl"`
		Archived bool    `json:"archived"`
	} `json:"sponsor"`
	Kind          string   `json:"kind"`
	Placement     string   `json:"placement"`
	CampaignID    *string  `json:"campaignId"`
	TitleEn       string   `json:"titleEn"`
	TitleBn       string   `json:"titleBn"`
	ImageURL      *string  `json:"imageUrl"`
	LinkKind      string   `json:"linkKind"`
	Link          string   `json:"link"`
	Code          *string  `json:"code"`
	UniversityIDs []string `json:"universityIds"`
	Cities        []string `json:"cities"`
	StartsAt      *string  `json:"startsAt"`
	EndsAt        *string  `json:"endsAt"`
	Status        string   `json:"status"`
	Delivered     bool     `json:"delivered"`
	DailyCap      int      `json:"dailyCap"`
	TotalViews    *int     `json:"totalViews"`
	Priority      int      `json:"priority"`
	Stats         struct {
		ViewsToday int `json:"viewsToday"`
		TapsToday  int `json:"tapsToday"`
		Views      int `json:"views"`
		Taps       int `json:"taps"`
	} `json:"stats"`
}

type spPromo struct {
	ID        string `json:"id"`
	Kind      string `json:"kind"`
	Placement string `json:"placement"`
	Sponsor   struct {
		Name     string  `json:"name"`
		LogoURL  *string `json:"logoUrl"`
		Category string  `json:"category"`
	} `json:"sponsor"`
	Title    string  `json:"title"`
	Body     string  `json:"body"`
	Cta      string  `json:"cta"`
	ImageURL *string `json:"imageUrl"`
	Link     *struct {
		Kind string `json:"kind"`
		URL  string `json:"url"`
	} `json:"link"`
	Code      *string `json:"code"`
	ExpiresAt *string `json:"expiresAt"`
	Terms     string  `json:"terms"`
	Targeted  bool    `json:"targeted"`
	Why       string  `json:"why"`
}

type spStats struct {
	From string `json:"from"`
	To   string `json:"to"`
	Days []struct {
		Day     string `json:"day"`
		Views   int    `json:"views"`
		Viewers int    `json:"viewers"`
		Taps    int    `json:"taps"`
		Copies  int    `json:"copies"`
		Hides   int    `json:"hides"`
	} `json:"days"`
	Totals struct {
		Views   int     `json:"views"`
		Viewers int     `json:"viewers"`
		Taps    int     `json:"taps"`
		Copies  int     `json:"copies"`
		Hides   int     `json:"hides"`
		CTR     float64 `json:"ctr"`
	} `json:"totals"`
}

func (h *harness) spSponsor(tok string, body map[string]any) spSponsor {
	h.t.Helper()
	r := h.do("POST", "/admin/sponsors", tok, body)
	require.Equal(h.t, http.StatusCreated, r.Status, r.Raw)
	var s spSponsor
	r.into(h.t, &s)
	return s
}

func (h *harness) spCreate(tok string, body map[string]any) spAdminPromo {
	h.t.Helper()
	r := h.do("POST", "/admin/promos", tok, body)
	require.Equal(h.t, http.StatusCreated, r.Status, r.Raw)
	var p spAdminPromo
	r.into(h.t, &p)
	return p
}

func (h *harness) spPatch(tok, id string, body map[string]any) spAdminPromo {
	h.t.Helper()
	r := h.do("PATCH", "/admin/promos/"+id, tok, body)
	require.Equal(h.t, http.StatusOK, r.Status, r.Raw)
	var p spAdminPromo
	r.into(h.t, &p)
	return p
}

func (h *harness) spGet(tok, id string) spAdminPromo {
	h.t.Helper()
	r := h.do("GET", "/admin/promos/"+id, tok, nil)
	require.Equal(h.t, http.StatusOK, r.Status, r.Raw)
	var p spAdminPromo
	r.into(h.t, &p)
	return p
}

func (h *harness) spStatus(tok, id, status string) *response {
	h.t.Helper()
	return h.do("POST", "/admin/promos/"+id+"/status", tok, map[string]any{"status": status})
}

func (h *harness) spLive(tok, id string) spAdminPromo {
	h.t.Helper()
	r := h.spStatus(tok, id, "live")
	require.Equal(h.t, http.StatusOK, r.Status, r.Raw)
	var p spAdminPromo
	r.into(h.t, &p)
	require.Equal(h.t, "live", p.Status)
	return p
}

// spUpload posts data as the multipart field "image" to an admin path.
func (h *harness) spUpload(tok, path string, data []byte) *response {
	h.t.Helper()
	var body bytes.Buffer
	mw := multipart.NewWriter(&body)
	fw, err := mw.CreateFormFile("image", "image.png")
	require.NoError(h.t, err)
	_, _ = fw.Write(data)
	require.NoError(h.t, mw.Close())
	req, err := http.NewRequest("POST", h.srv.URL+"/api/v1"+path, &body)
	require.NoError(h.t, err)
	req.Header.Set("Content-Type", mw.FormDataContentType())
	req.Header.Set("Authorization", "Bearer "+tok)
	res, err := http.DefaultClient.Do(req)
	require.NoError(h.t, err)
	defer res.Body.Close()
	raw, _ := io.ReadAll(res.Body)
	out := &response{Status: res.StatusCode, Header: res.Header, Raw: string(raw)}
	if len(raw) > 0 {
		require.NoError(h.t, json.Unmarshal(raw, out), string(raw))
	}
	return out
}

func (h *harness) spServe(tok, placement, lang string) []spPromo {
	h.t.Helper()
	path := "/promos?placement=" + placement
	if lang != "" {
		path += "&lang=" + lang
	}
	r := h.do("GET", path, tok, nil)
	require.Equal(h.t, http.StatusOK, r.Status, r.Raw)
	var out struct {
		Items []spPromo `json:"items"`
	}
	r.into(h.t, &out)
	return out.Items
}

func spIDs(ps []spPromo) []string {
	out := make([]string, len(ps))
	for i, p := range ps {
		out[i] = p.ID
	}
	return out
}

func spEv(id, typ string) map[string]any { return map[string]any{"promoId": id, "type": typ} }

func (h *harness) spEvents(tok string, events ...map[string]any) {
	h.t.Helper()
	r := h.do("POST", "/promos/events", tok, map[string]any{"events": events})
	require.Equal(h.t, http.StatusNoContent, r.Status, r.Raw)
}

func (h *harness) spStats(tok, path string) spStats {
	h.t.Helper()
	r := h.do("GET", path, tok, nil)
	require.Equal(h.t, http.StatusOK, r.Status, r.Raw)
	var s spStats
	r.into(h.t, &s)
	return s
}

// spWindow: an ad running from an hour ago for 10 days.
func (h *harness) spWindow() map[string]any {
	now := h.Now()
	return map[string]any{
		"startsAt": now.Add(-time.Hour).UTC().Format(time.RFC3339),
		"endsAt":   now.Add(10 * 24 * time.Hour).UTC().Format(time.RFC3339),
	}
}

func merge(ms ...map[string]any) map[string]any {
	out := map[string]any{}
	for _, m := range ms {
		for k, v := range m {
			out[k] = v
		}
	}
	return out
}

// spLiveAd creates an ad of kind, with an image for cards and feed posts,
// and puts it live.
func (h *harness) spLiveAd(tok, sponsorID, kind string, extra map[string]any) spAdminPromo {
	h.t.Helper()
	p := h.spCreate(tok, merge(map[string]any{"sponsorId": sponsorID, "kind": kind, "titleEn": kind + " offer"}, h.spWindow(), extra))
	if kind == "card" || kind == "feed" {
		r := h.spUpload(tok, "/admin/promos/"+p.ID+"/image", bannerPNG(h.t, 400, 200))
		require.Equal(h.t, http.StatusOK, r.Status, r.Raw)
	}
	return h.spLive(tok, p.ID)
}

func (h *harness) spAdmin() string {
	h.t.Helper()
	a := h.gwStudent("admin@test.ac.bd", "Admin One")
	h.sql(`UPDATE users SET role = 'admin' WHERE id = $1`, a.ID)
	return a.Tok
}

func (h *harness) spCount(q string, args ...any) int {
	h.t.Helper()
	var n int
	require.NoError(h.t, h.app.DB.Pool.QueryRow(context.Background(), q, args...).Scan(&n))
	return n
}

// ---- admin: sponsors and validation -------------------------------------------------

func TestSponsorsAdminValidation(t *testing.T) {
	h := newSponsorHarness(t)
	admin := h.spAdmin()
	student := h.gwStudent("rafi@test.ac.bd", "Rafi")
	uni := h.universityID("test-uni")

	// Admin only.
	assert.Equal(t, http.StatusForbidden, h.do("POST", "/admin/sponsors", student.Tok, map[string]any{"name": "X"}).Status)
	assert.Equal(t, http.StatusForbidden, h.do("GET", "/admin/promos", student.Tok, nil).Status)

	// Sponsors.
	assert.Equal(t, "INVALID_PROMO", h.do("POST", "/admin/sponsors", admin, map[string]any{"name": "  "}).code())
	assert.Equal(t, "INVALID_PROMO", h.do("POST", "/admin/sponsors", admin, map[string]any{"name": "Cafe", "website": "http://cafe.example.com"}).code())
	assert.Equal(t, "INVALID_PROMO", h.do("POST", "/admin/sponsors", admin, map[string]any{"name": "Cafe", "contactEmail": "nope"}).code())
	assert.Equal(t, "VALIDATION_FAILED", h.do("POST", "/admin/sponsors", admin, map[string]any{"name": strings.Repeat("x", 81)}).code())
	assert.Equal(t, "VALIDATION_FAILED", h.do("POST", "/admin/sponsors", admin, map[string]any{"name": "Cafe", "category": "bank"}).code())
	cafe := h.spSponsor(admin, map[string]any{"name": " Café Nirob ", "website": "https://cafe.example.com", "contactEmail": "hi@cafe.example.com"})
	assert.Equal(t, "Café Nirob", cafe.Name)
	assert.Equal(t, "general", cafe.Category)
	assert.Nil(t, cafe.LogoURL)
	assert.Equal(t, 0, cafe.Promos.Total)
	clinic := h.spSponsor(admin, map[string]any{"name": "City Clinic", "category": "health"})

	// Ads: what each kind needs at create.
	base := map[string]any{"sponsorId": cafe.ID}
	bad := func(code string, body map[string]any) {
		t.Helper()
		assert.Equal(t, code, h.do("POST", "/admin/promos", admin, merge(base, body)).code(), body)
	}
	bad("INVALID_PROMO", map[string]any{"sponsorId": nil, "kind": "deal"})
	bad("INVALID_PROMO", map[string]any{})
	bad("INVALID_PROMO", map[string]any{"kind": "deal", "placement": "today"})
	bad("INVALID_PROMO", map[string]any{"kind": "line"})
	bad("HEALTH_SPONSOR_ONLY", map[string]any{"kind": "line", "placement": "line:blood"})
	bad("INVALID_PROMO", map[string]any{"kind": "campaign"})
	bad("INVALID_PROMO", map[string]any{"kind": "deal", "campaignId": uni})
	bad("INVALID_PROMO", map[string]any{"kind": "card", "linkKind": "web", "link": "http://x.example.com"})
	bad("INVALID_PROMO", map[string]any{"kind": "card", "linkKind": "app", "link": "/profile"})
	bad("INVALID_PROMO", map[string]any{"kind": "card", "linkKind": "none", "link": "/deals"})
	bad("INVALID_PROMO", map[string]any{"kind": "card", "universityIds": []string{"00000000-0000-0000-0000-000000000001"}})
	bad("INVALID_PROMO", map[string]any{"kind": "card", "universityIds": []string{}})
	bad("INVALID_PROMO", map[string]any{"kind": "card", "cities": []string{" "}})
	bad("INVALID_PROMO", map[string]any{"kind": "card", "totalViews": 0})
	bad("INVALID_PROMO", map[string]any{"kind": "card", "status": "live"})
	bad("INVALID_PROMO", map[string]any{"kind": "card", "startsAt": h.Now().Format(time.RFC3339), "endsAt": h.Now().Add(-time.Hour).Format(time.RFC3339)})
	bad("VALIDATION_FAILED", map[string]any{"kind": "card", "titleEn": strings.Repeat("x", 61)})
	bad("VALIDATION_FAILED", map[string]any{"kind": "card", "bodyBn": strings.Repeat("ক", 141)})
	bad("VALIDATION_FAILED", map[string]any{"kind": "card", "dailyCap": 21})
	bad("VALIDATION_FAILED", map[string]any{"kind": "card", "priority": 0})
	bad("BAD_REQUEST", map[string]any{"kind": "card", "colour": "red"})
	assert.Equal(t, "INVALID_PROMO", h.do("POST", "/admin/promos", admin, map[string]any{"sponsorId": "00000000-0000-0000-0000-000000000001", "kind": "deal"}).code())

	// Line ads go on one of four pages; Blood only for health sponsors.
	line := h.spCreate(admin, map[string]any{"sponsorId": cafe.ID, "kind": "line", "placement": "line:bus"})
	assert.Equal(t, "line:bus", line.Placement)
	blood := h.spCreate(admin, map[string]any{"sponsorId": clinic.ID, "kind": "line", "placement": "line:blood"})
	assert.Equal(t, "line:blood", blood.Placement)
	assert.Equal(t, "HEALTH_SPONSOR_ONLY", h.do("PATCH", "/admin/promos/"+blood.ID, admin, map[string]any{"sponsorId": cafe.ID}).code())

	// A card: placement from the kind; defaults; going live needs dates, a title and an image.
	card := h.spCreate(admin, map[string]any{"sponsorId": cafe.ID, "kind": "card", "linkKind": "app", "link": "/deals",
		"universityIds": []string{uni, uni}, "cities": []string{" Dhaka", "dhaka", "Sylhet"}, "code": "  "})
	assert.Equal(t, "today", card.Placement)
	assert.Equal(t, "draft", card.Status)
	assert.Equal(t, 2, card.DailyCap)
	assert.Equal(t, 5, card.Priority)
	assert.Equal(t, []string{uni}, card.UniversityIDs, "repeats dropped")
	assert.Equal(t, []string{"Dhaka", "Sylhet"}, card.Cities, "trimmed, repeats dropped")
	assert.Nil(t, card.Code, "an empty code is none")
	live := func(id string) string { t.Helper(); return h.spStatus(admin, id, "live").code() }
	assert.Equal(t, "INVALID_PROMO", live(card.ID), "no dates")
	card = h.spPatch(admin, card.ID, h.spWindow())
	assert.Equal(t, "INVALID_PROMO", live(card.ID), "no title")
	card = h.spPatch(admin, card.ID, map[string]any{"titleEn": "Coffee for students"})
	r := h.spStatus(admin, card.ID, "live")
	require.Equal(t, "INVALID_PROMO", r.code(), "no image")
	assert.Contains(t, r.Raw, `"image"`)
	require.Equal(t, http.StatusOK, h.spUpload(admin, "/admin/promos/"+card.ID+"/image", bannerPNG(t, 400, 200)).Status)
	card = h.spLive(admin, card.ID)
	assert.Equal(t, "INVALID_PROMO", h.do("PATCH", "/admin/promos/"+card.ID, admin, map[string]any{"endsAt": h.Now().Add(-time.Minute).Format(time.RFC3339)}).code())

	// A deal needs a title and an expiry still to come; a line ad only dates.
	deal := h.spCreate(admin, merge(map[string]any{"sponsorId": cafe.ID, "kind": "deal", "code": "VK20",
		"expiresAt": h.Now().Add(-time.Hour).Format(time.RFC3339)}, h.spWindow()))
	assert.Equal(t, "INVALID_PROMO", live(deal.ID), "no title")
	deal = h.spPatch(admin, deal.ID, map[string]any{"titleEn": "20% off"})
	assert.Equal(t, "INVALID_PROMO", live(deal.ID), "expired")
	deal = h.spPatch(admin, deal.ID, map[string]any{"expiresAt": nil})
	assert.Equal(t, "VK20", *deal.Code)
	h.spLive(admin, deal.ID)
	line = h.spPatch(admin, line.ID, h.spWindow())
	h.spLive(admin, line.ID)

	// Already ended: can't go live.
	old := h.spCreate(admin, map[string]any{"sponsorId": cafe.ID, "kind": "line", "placement": "line:cgpa",
		"startsAt": h.Now().Add(-48 * time.Hour).Format(time.RFC3339), "endsAt": h.Now().Add(-24 * time.Hour).Format(time.RFC3339)})
	assert.Equal(t, "INVALID_PROMO", live(old.ID))

	// Lists and filters.
	var page struct {
		Items []spAdminPromo `json:"items"`
		Total int            `json:"total"`
	}
	h.do("GET", "/admin/promos?status=live", admin, nil).into(t, &page)
	assert.Equal(t, 3, page.Total)
	h.do("GET", "/admin/promos?kind=line&sponsorId="+cafe.ID, admin, nil).into(t, &page)
	assert.Equal(t, 2, page.Total)
	h.do("GET", "/admin/promos?q=coffee", admin, nil).into(t, &page)
	require.Equal(t, 1, page.Total)
	assert.Equal(t, card.ID, page.Items[0].ID)
	var sps struct {
		Items []spSponsor `json:"items"`
		Total int         `json:"total"`
	}
	h.do("GET", "/admin/sponsors", admin, nil).into(t, &sps)
	require.Equal(t, 2, sps.Total)
	assert.Equal(t, "Café Nirob", sps.Items[0].Name, "by name")
	assert.Equal(t, 3, sps.Items[0].Promos.Live)
	assert.Equal(t, 4, sps.Items[0].Promos.Total)

	// Archiving pauses its live ads; a new ad can't use it; restoring brings the sponsor back (ads stay paused).
	var archived spSponsor
	r = h.do("DELETE", "/admin/sponsors/"+cafe.ID, admin, nil)
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	r.into(t, &archived)
	assert.NotNil(t, archived.ArchivedAt)
	assert.Equal(t, 0, archived.Promos.Live)
	assert.Equal(t, "paused", h.spGet(admin, card.ID).Status)
	assert.Equal(t, "INVALID_PROMO", h.do("POST", "/admin/promos", admin, map[string]any{"sponsorId": cafe.ID, "kind": "deal"}).code())
	assert.Equal(t, "INVALID_PROMO", live(card.ID), "an archived sponsor's ad can't go live")
	h.do("GET", "/admin/sponsors?archived=true", admin, nil).into(t, &sps)
	assert.Equal(t, 1, sps.Total)
	r = h.do("PATCH", "/admin/sponsors/"+cafe.ID, admin, map[string]any{"archived": false})
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	h.spLive(admin, card.ID)

	// A health sponsor with a Blood ad can't stop being one.
	blood = h.spPatch(admin, blood.ID, h.spWindow())
	h.spLive(admin, blood.ID)
	assert.Equal(t, "HEALTH_SPONSOR_ONLY", h.do("PATCH", "/admin/sponsors/"+clinic.ID, admin, map[string]any{"category": "general"}).code())

	// Every write is audited.
	assert.Equal(t, 2, h.spCount(`SELECT count(*)::int FROM audit_log WHERE action = 'sponsor.create'`))
	assert.GreaterOrEqual(t, h.spCount(`SELECT count(*)::int FROM audit_log WHERE action = 'promo.status'`), 5)
	assert.Equal(t, 1, h.spCount(`SELECT count(*)::int FROM audit_log WHERE action = 'sponsor.archive'`))
	assert.Equal(t, 1, h.spCount(`SELECT count(*)::int FROM audit_log WHERE action = 'sponsor.restore'`))
}

// ---- serving ------------------------------------------------------------------------

func TestSponsorsServing(t *testing.T) {
	h := newSponsorHarness(t)
	admin := h.spAdmin()
	h.sql(`UPDATE universities SET city = 'Dhaka' WHERE slug = 'test-uni'`)
	north := h.addUni("north", "North University", "Sylhet")
	a := h.gwStudent("rafi@test.ac.bd", "Rafi") // Test University, Dhaka
	b := h.gwStudent("mim@north.ac.bd", "Mim")  // North University, Sylhet
	uni := h.universityID("test-uni")
	sp := h.spSponsor(admin, map[string]any{"name": "Café Nirob"})
	clinic := h.spSponsor(admin, map[string]any{"name": "City Clinic", "category": "health"})

	// Deals: targeting by university and city; dates; expiry; order by priority, then end.
	dAll := h.spLiveAd(admin, sp.ID, "deal", map[string]any{"titleEn": "Everyone", "titleBn": "সবাই", "priority": 5,
		"code": "ALL10", "termsEn": "One per student", "linkKind": "web", "link": "https://cafe.example.com/deal"})
	dUni := h.spLiveAd(admin, sp.ID, "deal", map[string]any{"titleEn": "Test only", "priority": 9, "universityIds": []string{uni}})
	dCity := h.spLiveAd(admin, sp.ID, "deal", map[string]any{"titleEn": "Sylhet only", "priority": 5, "cities": []string{"sylhet"},
		"endsAt": h.Now().Add(3 * 24 * time.Hour).Format(time.RFC3339)})
	dSoon := h.spLiveAd(admin, sp.ID, "deal", map[string]any{"titleEn": "Tomorrow",
		"startsAt": h.Now().Add(24 * time.Hour).Format(time.RFC3339), "endsAt": h.Now().Add(5 * 24 * time.Hour).Format(time.RFC3339)})
	dExp := h.spLiveAd(admin, sp.ID, "deal", map[string]any{"titleEn": "Expiring", "priority": 1, "expiresAt": h.Now().Add(2 * time.Hour).Format(time.RFC3339)})
	dPaused := h.spLiveAd(admin, sp.ID, "deal", map[string]any{"titleEn": "Paused"})
	require.Equal(t, http.StatusOK, h.spStatus(admin, dPaused.ID, "paused").Status)
	_ = north

	got := h.spServe(a.Tok, "deals", "")
	assert.Equal(t, []string{dUni.ID, dAll.ID, dExp.ID}, spIDs(got), "Test University: priority 9, then 5, then 1")
	assert.Equal(t, []string{dCity.ID, dAll.ID, dExp.ID}, spIDs(h.spServe(b.Tok, "deals", "")), "Sylhet: same priority, the one ending first first")

	// The Promo shape.
	all := got[1]
	assert.Equal(t, "deal", all.Kind)
	assert.Equal(t, "deals", all.Placement)
	assert.Equal(t, "Café Nirob", all.Sponsor.Name)
	assert.Equal(t, "general", all.Sponsor.Category)
	assert.Equal(t, "Everyone", all.Title)
	assert.Equal(t, "ALL10", *all.Code)
	assert.Equal(t, "One per student", all.Terms)
	require.NotNil(t, all.Link)
	assert.Equal(t, "web", all.Link.Kind)
	assert.Equal(t, "https://cafe.example.com/deal", all.Link.URL)
	assert.False(t, all.Targeted)
	assert.Equal(t, "Shown to all students", all.Why)
	assert.True(t, got[0].Targeted)
	assert.Equal(t, "Shown to students at Test University", got[0].Why)
	assert.Nil(t, got[0].Link)
	city := h.spServe(b.Tok, "deals", "")[0]
	assert.True(t, city.Targeted)
	assert.Equal(t, "Shown to students in Sylhet", city.Why)
	// Bangla, falling back to English per field.
	bn := h.spServe(a.Tok, "deals", "bn")
	assert.Equal(t, "Test only", bn[0].Title, "no Bangla title: English")
	assert.Equal(t, "টেস্ট বিশ্ববিদ্যালয়-এর শিক্ষার্থীদের দেখানো হচ্ছে", bn[0].Why)
	assert.Equal(t, "সবাই", bn[1].Title)
	assert.Equal(t, "সব শিক্ষার্থীকে দেখানো হচ্ছে", bn[1].Why)

	// Time: the expiring deal goes, tomorrow's comes.
	h.advance(25 * time.Hour)
	assert.Equal(t, []string{dUni.ID, dSoon.ID, dAll.ID}, spIDs(h.spServe(a.Tok, "deals", "")), "tomorrow's ends sooner than the 10-day one")

	// Today: one card, the same all day; after its daily cap the other; a new day starts over.
	c1 := h.spLiveAd(admin, sp.ID, "card", nil)
	c2 := h.spLiveAd(admin, sp.ID, "card", nil)
	first := h.spServe(a.Tok, "today", "")
	require.Len(t, first, 1)
	for range 4 {
		assert.Equal(t, first[0].ID, h.spServe(a.Tok, "today", "")[0].ID, "stable all day")
	}
	require.NotNil(t, first[0].ImageURL)
	assert.True(t, strings.HasPrefix(*first[0].ImageURL, "/promos/"+first[0].ID+"/image?v="))
	other := c1.ID
	if first[0].ID == c1.ID {
		other = c2.ID
	}
	h.spEvents(a.Tok, spEv(first[0].ID, "view"), spEv(first[0].ID, "view"))
	assert.Equal(t, other, h.spServe(a.Tok, "today", "")[0].ID, "daily cap 2 reached: the other card")
	h.spEvents(a.Tok, spEv(other, "view"), spEv(other, "view"))
	assert.Empty(t, h.spServe(a.Tok, "today", ""), "both capped")
	assert.Len(t, h.spServe(b.Tok, "today", ""), 1, "caps are per student")
	h.advance(24 * time.Hour)
	assert.Len(t, h.spServe(a.Tok, "today", ""), 1, "a new day")

	// Campus feed: at most 3, in a stable order.
	for range 4 {
		h.spLiveAd(admin, sp.ID, "feed", nil)
	}
	feed := h.spServe(a.Tok, "campus", "")
	require.Len(t, feed, 3)
	assert.Equal(t, spIDs(feed), spIDs(h.spServe(a.Tok, "campus", "")))

	// Line ads: one; the Blood page only for health sponsors (the sponsor can't stop being one while it runs).
	lb := h.spLiveAd(admin, sp.ID, "line", map[string]any{"placement": "line:bus"})
	assert.Equal(t, []string{lb.ID}, spIDs(h.spServe(a.Tok, "line:bus", "")))
	bl := h.spLiveAd(admin, clinic.ID, "line", map[string]any{"placement": "line:blood"})
	blood := h.spServe(a.Tok, "line:blood", "")
	require.Len(t, blood, 1)
	assert.Equal(t, bl.ID, blood[0].ID)
	assert.Equal(t, "health", blood[0].Sponsor.Category)
	assert.Empty(t, h.spServe(a.Tok, "line:cgpa", ""))
	assert.Equal(t, "VALIDATION_FAILED", h.do("GET", "/promos?placement=campaign", a.Tok, nil).code())
	assert.Equal(t, "VALIDATION_FAILED", h.do("GET", "/promos", a.Tok, nil).code())
	assert.Equal(t, http.StatusUnauthorized, h.do("GET", "/promos?placement=deals", "", nil).Status)

	// Hide: gone for 7 days, then back.
	h.spEvents(b.Tok, spEv(dCity.ID, "hide"))
	assert.NotContains(t, spIDs(h.spServe(b.Tok, "deals", "")), dCity.ID)
	h.advance(6 * 24 * time.Hour)
	assert.NotContains(t, spIDs(h.spServe(b.Tok, "deals", "")), dCity.ID, "still hidden on day 6")
	h.advance(24*time.Hour + time.Minute)
	h.spPatch(admin, dCity.ID, map[string]any{"endsAt": h.Now().Add(5 * 24 * time.Hour).Format(time.RFC3339)})
	assert.Contains(t, spIDs(h.spServe(b.Tok, "deals", "")), dCity.ID, "back after 7 days")

	// Delivered: total views reached stops it for everyone.
	h.spPatch(admin, dAll.ID, map[string]any{"totalViews": 2})
	h.spEvents(a.Tok, spEv(dAll.ID, "view"))
	h.spEvents(b.Tok, spEv(dAll.ID, "view"))
	assert.NotContains(t, spIDs(h.spServe(a.Tok, "deals", "")), dAll.ID)
	assert.NotContains(t, spIDs(h.spServe(b.Tok, "deals", "")), dAll.ID)
	gotAll := h.spGet(admin, dAll.ID)
	assert.True(t, gotAll.Delivered)
	assert.Equal(t, "live", gotAll.Status, "it stays live; it's just delivered")
	h.spPatch(admin, dAll.ID, map[string]any{"totalViews": nil})
	assert.Contains(t, spIDs(h.spServe(a.Tok, "deals", "")), dAll.ID, "no limit again")

	// An archived sponsor's ads stop at once.
	require.Equal(t, http.StatusOK, h.do("DELETE", "/admin/sponsors/"+sp.ID, admin, nil).Status)
	assert.Empty(t, h.spServe(a.Tok, "deals", ""))
	assert.Empty(t, h.spServe(a.Tok, "line:bus", ""))
}

// ---- events and reports -------------------------------------------------------------

func TestSponsorsEventsAndStats(t *testing.T) {
	h := newSponsorHarness(t)
	admin := h.spAdmin()
	h.addUni("north", "North University", "Sylhet")
	a := h.gwStudent("rafi@test.ac.bd", "Rafi")
	b := h.gwStudent("mim@north.ac.bd", "Mim")
	uni := h.universityID("test-uni")
	sp := h.spSponsor(admin, map[string]any{"name": "Café Nirob"})
	deal := h.spLiveAd(admin, sp.ID, "deal", map[string]any{"code": "VK20"})
	mine := h.spLiveAd(admin, sp.ID, "deal", map[string]any{"universityIds": []string{uni}})
	other := h.spLiveAd(admin, sp.ID, "line", map[string]any{"placement": "line:groups"})

	// Views, taps, copies; viewers count once a day.
	h.spEvents(a.Tok, spEv(deal.ID, "view"), spEv(deal.ID, "view"), spEv(deal.ID, "view"),
		spEv(deal.ID, "tap"), spEv(deal.ID, "tap"), spEv(deal.ID, "copy"))
	h.spEvents(b.Tok, spEv(deal.ID, "view"), spEv(other.ID, "view"), spEv(other.ID, "tap"))
	// Ignored: an ad not shown to that student, and the staff.
	h.spEvents(b.Tok, spEv(mine.ID, "view"), spEv(mine.ID, "tap"))
	h.spEvents(admin, spEv(deal.ID, "view"), spEv(deal.ID, "tap"))
	// The daily cap: 20 views per ad and student.
	views := []map[string]any{}
	for range 25 {
		views = append(views, spEv(mine.ID, "view"))
	}
	h.spEvents(a.Tok, views...)
	// A hide counts once while it lasts.
	h.spEvents(a.Tok, spEv(other.ID, "hide"))
	h.spEvents(a.Tok, spEv(other.ID, "hide"))

	// Limits on the batch.
	many := []map[string]any{}
	for range 51 {
		many = append(many, spEv(deal.ID, "view"))
	}
	assert.Equal(t, "VALIDATION_FAILED", h.do("POST", "/promos/events", a.Tok, map[string]any{"events": many}).code())
	assert.Equal(t, "VALIDATION_FAILED", h.do("POST", "/promos/events", a.Tok, map[string]any{"events": []any{spEv(deal.ID, "like")}}).code())
	assert.Equal(t, "VALIDATION_FAILED", h.do("POST", "/promos/events", a.Tok, map[string]any{"events": []any{}}).code())
	assert.Equal(t, http.StatusUnauthorized, h.do("POST", "/promos/events", "", map[string]any{"events": []any{spEv(deal.ID, "view")}}).Status)

	s := h.spStats(admin, "/admin/promos/"+deal.ID+"/stats")
	require.Len(t, s.Days, 30, "the last 30 days, zeros included")
	today := s.Days[29]
	assert.Equal(t, dhakaDate(h.Now()), today.Day)
	assert.Equal(t, 4, today.Views)
	assert.Equal(t, 2, today.Viewers)
	assert.Equal(t, 2, today.Taps)
	assert.Equal(t, 1, today.Copies)
	assert.Equal(t, 4, s.Totals.Views)
	assert.Equal(t, 2, s.Totals.Viewers)
	assert.InDelta(t, 0.5, s.Totals.CTR, 1e-9)
	assert.Equal(t, 20, h.spStats(admin, "/admin/promos/"+mine.ID+"/stats").Totals.Views, "capped at 20; Mim's events ignored")
	o := h.spStats(admin, "/admin/promos/"+other.ID+"/stats")
	assert.Equal(t, 1, o.Totals.Hides)
	assert.Equal(t, 1, o.Totals.Taps)

	// A second day adds up; viewers are distinct over the range.
	h.advance(24 * time.Hour)
	h.spEvents(a.Tok, spEv(deal.ID, "view"))
	s = h.spStats(admin, "/admin/promos/"+deal.ID+"/stats")
	assert.Equal(t, 5, s.Totals.Views)
	assert.Equal(t, 2, s.Totals.Viewers, "Rafi on two days is one viewer")
	assert.Equal(t, 1, s.Days[29].Viewers)
	from := h.Now().In(dhakaZone()).AddDate(0, 0, -1).Format(time.DateOnly)
	s = h.spStats(admin, "/admin/promos/"+deal.ID+"/stats?from="+from+"&to="+from)
	require.Len(t, s.Days, 1)
	assert.Equal(t, 4, s.Totals.Views)
	assert.Equal(t, "INVALID_PROMO", h.do("GET", "/admin/promos/"+deal.ID+"/stats?from=2026-11-05&to=2026-11-01", admin, nil).code())
	assert.Equal(t, "INVALID_PROMO", h.do("GET", "/admin/promos/"+deal.ID+"/stats?from=2024-01-01&to=2026-11-01", admin, nil).code())
	assert.Equal(t, "VALIDATION_FAILED", h.do("GET", "/admin/promos/"+deal.ID+"/stats?from=yesterday", admin, nil).code())

	// The admin list's counts, the sponsor's report, the dashboard.
	g := h.spGet(admin, deal.ID)
	assert.Equal(t, 1, g.Stats.ViewsToday)
	assert.Equal(t, 5, g.Stats.Views)
	assert.Equal(t, 2, g.Stats.Taps)
	var rep struct {
		Sponsor struct {
			Name string `json:"name"`
		} `json:"sponsor"`
		Promos []struct {
			ID    string `json:"id"`
			Views int    `json:"views"`
			Taps  int    `json:"taps"`
		} `json:"promos"`
		Totals struct {
			Views   int `json:"views"`
			Viewers int `json:"viewers"`
			Taps    int `json:"taps"`
			Copies  int `json:"copies"`
			Hides   int `json:"hides"`
		} `json:"totals"`
	}
	h.do("GET", "/admin/sponsors/"+sp.ID+"/stats", admin, nil).into(t, &rep)
	assert.Equal(t, "Café Nirob", rep.Sponsor.Name)
	require.Len(t, rep.Promos, 3)
	assert.Equal(t, 5+20+1, rep.Totals.Views)
	assert.Equal(t, 2, rep.Totals.Viewers)
	assert.Equal(t, 3, rep.Totals.Taps)
	assert.Equal(t, 1, rep.Totals.Copies)
	assert.Equal(t, 1, rep.Totals.Hides)
	var st struct {
		Sponsors struct {
			LivePromos int `json:"livePromos"`
			ViewsToday int `json:"viewsToday"`
			TapsToday  int `json:"tapsToday"`
		} `json:"sponsors"`
	}
	h.do("GET", "/admin/stats", admin, nil).into(t, &st)
	assert.Equal(t, 3, st.Sponsors.LivePromos)
	assert.Equal(t, 1, st.Sponsors.ViewsToday)
	assert.Equal(t, 0, st.Sponsors.TapsToday)

	// Nothing about a student is in a report.
	assert.NotContains(t, h.do("GET", "/admin/sponsors/"+sp.ID+"/stats", admin, nil).Raw, a.ID)
}

func dhakaZone() *time.Location {
	l, err := time.LoadLocation("Asia/Dhaka")
	if err != nil {
		return time.FixedZone("Asia/Dhaka", 6*3600)
	}
	return l
}

func dhakaDate(t time.Time) string { return t.In(dhakaZone()).Format(time.DateOnly) }

// ---- editing a live ad, status, delete, duplicate -----------------------------------

func TestSponsorsLiveEditsAndDuplicate(t *testing.T) {
	h := newSponsorHarness(t)
	admin := h.spAdmin()
	sp := h.spSponsor(admin, map[string]any{"name": "Café Nirob"})
	card := h.spLiveAd(admin, sp.ID, "card", map[string]any{"titleBn": "কফি", "linkKind": "app", "link": "/deals", "ctaEn": "Get offer"})

	// Live: only the end, limits, priority and status change.
	for _, body := range []map[string]any{{"titleEn": "New"}, {"linkKind": "none"}, {"cities": []string{"Dhaka"}},
		{"startsAt": h.Now().Format(time.RFC3339)}, {"code": "X"}, {"universityIds": nil}} {
		assert.Equal(t, "PROMO_LOCKED", h.do("PATCH", "/admin/promos/"+card.ID, admin, body).code(), body)
	}
	assert.Equal(t, "PROMO_LOCKED", h.spUpload(admin, "/admin/promos/"+card.ID+"/image", bannerPNG(t, 400, 200)).code())
	assert.Equal(t, "PROMO_LOCKED", h.do("DELETE", "/admin/promos/"+card.ID+"/image", admin, nil).code())
	end := h.Now().Add(20 * 24 * time.Hour).UTC().Format(time.RFC3339)
	card = h.spPatch(admin, card.ID, map[string]any{"priority": 9, "dailyCap": 3, "totalViews": 1000, "endsAt": end})
	assert.Equal(t, 9, card.Priority)
	assert.Equal(t, 3, card.DailyCap)
	assert.Equal(t, 1000, *card.TotalViews)
	assert.Equal(t, end, *card.EndsAt)
	assert.Equal(t, "live", card.Status)

	// Paused: anything; back live checks the whole ad again.
	card = h.spPatch(admin, card.ID, map[string]any{"status": "paused"})
	assert.Equal(t, "paused", card.Status)
	card = h.spPatch(admin, card.ID, map[string]any{"titleEn": "Coffee, half price"})
	r := h.spUpload(admin, "/admin/promos/"+card.ID+"/image", bannerPNG(t, 600, 300))
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	var withImage spAdminPromo
	r.into(t, &withImage)
	assert.NotEqual(t, *card.ImageURL, *withImage.ImageURL, "a new version")
	r = h.do("DELETE", "/admin/promos/"+card.ID+"/image", admin, nil)
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	assert.Equal(t, "INVALID_PROMO", h.do("PATCH", "/admin/promos/"+card.ID, admin, map[string]any{"status": "live"}).code(), "no image")
	require.Equal(t, http.StatusOK, h.spUpload(admin, "/admin/promos/"+card.ID+"/image", bannerPNG(t, 400, 200)).Status)
	card = h.spPatch(admin, card.ID, map[string]any{"status": "live"})
	assert.Equal(t, "live", card.Status)

	// Status moves.
	draft := h.spCreate(admin, map[string]any{"sponsorId": sp.ID, "kind": "deal", "titleEn": "Draft"})
	assert.Equal(t, "PROMO_LOCKED", h.spStatus(admin, draft.ID, "paused").code())
	assert.Equal(t, "PROMO_LOCKED", h.spStatus(admin, draft.ID, "ended").code())
	assert.Equal(t, "VALIDATION_FAILED", h.spStatus(admin, draft.ID, "draft").code())
	require.Equal(t, http.StatusOK, h.spStatus(admin, card.ID, "ended").Status)
	assert.Equal(t, "PROMO_LOCKED", h.spStatus(admin, card.ID, "live").code(), "ended is final")
	assert.Equal(t, "PROMO_LOCKED", h.do("PATCH", "/admin/promos/"+card.ID, admin, map[string]any{"priority": 2}).code())

	// Delete: drafts only.
	assert.Equal(t, "PROMO_LOCKED", h.do("DELETE", "/admin/promos/"+card.ID, admin, nil).code())
	img := h.spCreate(admin, map[string]any{"sponsorId": sp.ID, "kind": "card"})
	require.Equal(t, http.StatusOK, h.spUpload(admin, "/admin/promos/"+img.ID+"/image", bannerPNG(t, 400, 200)).Status)
	key := ""
	require.NoError(t, h.app.DB.Pool.QueryRow(context.Background(), `SELECT image_key FROM promos WHERE id = $1`, img.ID).Scan(&key))
	assert.Equal(t, http.StatusNoContent, h.do("DELETE", "/admin/promos/"+img.ID, admin, nil).Status)
	assert.Equal(t, "PROMO_NOT_FOUND", h.do("GET", "/admin/promos/"+img.ID, admin, nil).code())
	_, err := h.media.Open(key)
	assert.Error(t, err, "its image is gone too")

	// Duplicate: a draft copy with its own image file.
	r = h.do("POST", "/admin/promos/"+card.ID+"/duplicate", admin, nil)
	require.Equal(t, http.StatusCreated, r.Status, r.Raw)
	var dup spAdminPromo
	r.into(t, &dup)
	assert.NotEqual(t, card.ID, dup.ID)
	assert.Equal(t, "draft", dup.Status)
	assert.Equal(t, "Coffee, half price", dup.TitleEn)
	assert.Equal(t, "কফি", dup.TitleBn)
	assert.Equal(t, "app", dup.LinkKind)
	assert.Equal(t, "/deals", dup.Link)
	assert.Equal(t, 9, dup.Priority)
	assert.Equal(t, 0, dup.Stats.Views)
	require.NotNil(t, dup.ImageURL)
	assert.NotEqual(t, *card.ImageURL, *dup.ImageURL)
	res, body := h.publicGet(*dup.ImageURL)
	assert.Equal(t, http.StatusOK, res.StatusCode, "a draft's image with the current version")
	assert.NotEmpty(t, body)
	dup = h.spPatch(admin, dup.ID, map[string]any{"endsAt": h.Now().Add(48 * time.Hour).Format(time.RFC3339)})
	h.spLive(admin, dup.ID)
	assert.Equal(t, 1, h.spCount(`SELECT count(*)::int FROM audit_log WHERE action = 'promo.duplicate'`))
	assert.Equal(t, 1, h.spCount(`SELECT count(*)::int FROM audit_log WHERE action = 'promo.delete'`))
	assert.GreaterOrEqual(t, h.spCount(`SELECT count(*)::int FROM audit_log WHERE action = 'promo.image'`), 3)
}

// ---- images and logos ---------------------------------------------------------------

func TestSponsorsImages(t *testing.T) {
	h := newSponsorHarness(t)
	admin := h.spAdmin()
	sp := h.spSponsor(admin, map[string]any{"name": "Café Nirob"})
	card := h.spCreate(admin, merge(map[string]any{"sponsorId": sp.ID, "kind": "card", "titleEn": "Coffee"}, h.spWindow()))
	path := "/admin/promos/" + card.ID + "/image"

	// Not an image; too large (in the file, and over the body cap).
	assert.Equal(t, "INVALID_IMAGE", h.spUpload(admin, path, []byte("hello")).code())
	big := make([]byte, 8<<20+10)
	_, _ = rand.Read(big)
	assert.Equal(t, "IMAGE_TOO_LARGE", h.spUpload(admin, path, big).code())
	huge := make([]byte, 10<<20)
	assert.Equal(t, "IMAGE_TOO_LARGE", h.spUpload(admin, path, huge).code())

	// A real photo, bigger than the 64 KB body cap, is re-encoded to fit 1600×800.
	photo := bannerPNG(t, 3200, 2000)
	require.Greater(t, len(photo), 256<<10)
	r := h.spUpload(admin, path, photo)
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	r.into(t, &card)
	require.NotNil(t, card.ImageURL)
	res, body := h.publicGet(*card.ImageURL)
	require.Equal(t, http.StatusOK, res.StatusCode)
	assert.Equal(t, "image/jpeg", res.Header.Get("Content-Type"))
	assert.Equal(t, "public, max-age=31536000, immutable", res.Header.Get("Cache-Control"))
	cfg, format, err := image.DecodeConfig(bytes.NewReader(body))
	require.NoError(t, err)
	assert.Equal(t, "jpeg", format)
	assert.Equal(t, 1280, cfg.Width)
	assert.Equal(t, 800, cfg.Height)
	// A draft's image needs the current version; once live, any version works for 5 minutes.
	bare := strings.SplitN(*card.ImageURL, "?", 2)[0]
	res, _ = h.publicGet(bare)
	assert.Equal(t, http.StatusNotFound, res.StatusCode)
	h.spLive(admin, card.ID)
	res, _ = h.publicGet(bare + "?v=old")
	require.Equal(t, http.StatusOK, res.StatusCode)
	assert.Equal(t, "public, max-age=300", res.Header.Get("Cache-Control"))
	res, _ = h.publicGet("/promos/00000000-0000-0000-0000-000000000001/image?v=x")
	assert.Equal(t, http.StatusNotFound, res.StatusCode)
	res, _ = h.publicGet("/promos/nope/image")
	assert.Equal(t, http.StatusNotFound, res.StatusCode)

	// Logos: within 512 px; at most 4 MB; public with the same caching.
	lpath := "/admin/sponsors/" + sp.ID + "/logo"
	assert.Equal(t, "IMAGE_TOO_LARGE", h.spUpload(admin, lpath, make([]byte, 5<<20)).code())
	r = h.spUpload(admin, lpath, bannerPNG(t, 1000, 600))
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	var withLogo spSponsor
	r.into(t, &withLogo)
	require.NotNil(t, withLogo.LogoURL)
	res, body = h.publicGet(*withLogo.LogoURL)
	require.Equal(t, http.StatusOK, res.StatusCode)
	assert.Equal(t, "public, max-age=31536000, immutable", res.Header.Get("Cache-Control"))
	cfg, _, err = image.DecodeConfig(bytes.NewReader(body))
	require.NoError(t, err)
	assert.Equal(t, 512, cfg.Width)
	assert.Equal(t, 307, cfg.Height)
	// The logo shows on the ad.
	student := h.gwStudent("rafi@test.ac.bd", "Rafi")
	served := h.spServe(student.Tok, "today", "")
	require.Len(t, served, 1)
	assert.Equal(t, *withLogo.LogoURL, *served[0].Sponsor.LogoURL)
	// A new logo replaces the old file; removing it clears the URL.
	oldKey := ""
	require.NoError(t, h.app.DB.Pool.QueryRow(context.Background(), `SELECT logo_key FROM sponsors WHERE id = $1`, sp.ID).Scan(&oldKey))
	require.Equal(t, http.StatusOK, h.spUpload(admin, lpath, bannerPNG(t, 200, 200)).Status)
	_, err = h.media.Open(oldKey)
	assert.Error(t, err)
	r = h.do("DELETE", lpath, admin, nil)
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	r.into(t, &withLogo)
	assert.Nil(t, withLogo.LogoURL)
	assert.Equal(t, 1, h.spCount(`SELECT count(*)::int FROM audit_log WHERE action = 'sponsor.logo_remove'`))
}

// ---- campaign sponsor ---------------------------------------------------------------

func TestSponsorsCampaignSponsor(t *testing.T) {
	h := newSponsorHarness(t)
	admin := h.spAdmin()
	student := h.gwStudent("rafi@test.ac.bd", "Rafi")
	now := h.Now()
	c := h.gwAdminCampaign(admin, "POST", "/admin/campaigns", campaignBody(now.Add(-time.Hour), now.Add(5*24*time.Hour), nil), http.StatusCreated)
	h.gwAdminCampaign(admin, "PATCH", "/admin/campaigns/"+c.ID, map[string]any{"status": "live"}, http.StatusOK)

	type withSponsor struct {
		ID      string `json:"id"`
		Sponsor *struct {
			Name    string  `json:"name"`
			LogoURL *string `json:"logoUrl"`
			Link    *struct {
				Kind string `json:"kind"`
				URL  string `json:"url"`
			} `json:"link"`
		} `json:"sponsor"`
	}
	detail := func() withSponsor {
		t.Helper()
		var v withSponsor
		h.do("GET", "/campaigns/"+c.ID, student.Tok, nil).into(t, &v)
		return v
	}
	assert.Nil(t, detail().Sponsor)
	assert.Contains(t, h.do("GET", "/campaigns/"+c.ID+"/public", "", nil).Raw, `"sponsor":null`)

	gp := h.spSponsor(admin, map[string]any{"name": "Phone Bazar", "website": "https://phones.example.com"})
	require.Equal(t, http.StatusOK, h.spUpload(admin, "/admin/sponsors/"+gp.ID+"/logo", bannerPNG(t, 300, 300)).Status)
	p := h.spCreate(admin, merge(map[string]any{"sponsorId": gp.ID, "kind": "campaign", "campaignId": c.ID}, h.spWindow()))
	assert.Equal(t, "campaign", p.Placement)
	assert.Nil(t, detail().Sponsor, "a draft sponsors nothing")
	h.spLive(admin, p.ID)

	d := detail()
	require.NotNil(t, d.Sponsor)
	assert.Equal(t, "Phone Bazar", d.Sponsor.Name)
	require.NotNil(t, d.Sponsor.LogoURL)
	assert.True(t, strings.HasPrefix(*d.Sponsor.LogoURL, "/sponsors/"+gp.ID+"/logo?v="))
	require.NotNil(t, d.Sponsor.Link)
	assert.Equal(t, "web", d.Sponsor.Link.Kind)
	assert.Equal(t, "https://phones.example.com", d.Sponsor.Link.URL, "the sponsor's website without a link on the ad")
	var list []withSponsor
	h.do("GET", "/campaigns", student.Tok, nil).into(t, &list)
	require.Len(t, list, 1)
	require.NotNil(t, list[0].Sponsor)
	var pub withSponsor
	h.do("GET", "/campaigns/"+c.ID+"/public", "", nil).into(t, &pub)
	require.NotNil(t, pub.Sponsor)
	assert.Equal(t, "Phone Bazar", pub.Sponsor.Name)

	// The ad's own link wins; one live sponsor per campaign.
	h.spStatus(admin, p.ID, "paused")
	h.spPatch(admin, p.ID, map[string]any{"linkKind": "app", "link": "/campaigns/" + c.ID})
	h.spLive(admin, p.ID)
	assert.Equal(t, "/campaigns/"+c.ID, detail().Sponsor.Link.URL)
	second := h.spCreate(admin, merge(map[string]any{"sponsorId": gp.ID, "kind": "campaign", "campaignId": c.ID}, h.spWindow()))
	r := h.spStatus(admin, second.ID, "live")
	assert.Equal(t, "INVALID_PROMO", r.code())
	assert.Contains(t, r.Raw, "campaignId")
	assert.Empty(t, h.spServe(student.Tok, "deals", ""), "a campaign sponsor isn't served as an ad")

	require.Equal(t, http.StatusOK, h.spStatus(admin, p.ID, "paused").Status)
	assert.Nil(t, detail().Sponsor)
}

// ---- sweep --------------------------------------------------------------------------

func TestSponsorsSweep(t *testing.T) {
	h := newSponsorHarness(t)
	admin := h.spAdmin()
	student := h.gwStudent("rafi@test.ac.bd", "Rafi")
	sp := h.spSponsor(admin, map[string]any{"name": "Café Nirob"})
	short := h.spLiveAd(admin, sp.ID, "deal", map[string]any{"endsAt": h.Now().Add(2 * time.Hour).Format(time.RFC3339)})
	long := h.spLiveAd(admin, sp.ID, "deal", nil)
	paused := h.spLiveAd(admin, sp.ID, "deal", map[string]any{"endsAt": h.Now().Add(2 * time.Hour).Format(time.RFC3339)})
	h.spStatus(admin, paused.ID, "paused")
	h.spEvents(student.Tok, spEv(long.ID, "view"), spEv(long.ID, "hide"))
	ctx := context.Background()

	h.advance(3 * time.Hour)
	assert.Empty(t, h.spServe(student.Tok, "deals", ""), "past its end and hidden")
	require.NoError(t, h.app.Sponsors.Sweep(ctx))
	assert.Equal(t, "ended", h.spGet(admin, short.ID).Status)
	assert.Equal(t, "ended", h.spGet(admin, paused.ID).Status)
	assert.Equal(t, "live", h.spGet(admin, long.ID).Status)
	assert.Equal(t, 1, h.spCount(`SELECT count(*)::int FROM promo_user_days`))
	assert.Equal(t, 1, h.spCount(`SELECT count(*)::int FROM promo_hides`))

	// Hides run out; per-student rows go after 90 days; daily totals stay.
	h.advance(8 * 24 * time.Hour)
	require.NoError(t, h.app.Sponsors.Sweep(ctx))
	assert.Equal(t, 0, h.spCount(`SELECT count(*)::int FROM promo_hides`))
	assert.Equal(t, 1, h.spCount(`SELECT count(*)::int FROM promo_user_days`))
	h.sql(`UPDATE promo_user_days SET day = day - 91`)
	require.NoError(t, h.app.Sponsors.Sweep(ctx))
	assert.Equal(t, 0, h.spCount(`SELECT count(*)::int FROM promo_user_days`))
	assert.Equal(t, 1, h.spCount(`SELECT count(*)::int FROM promo_days`))
}
