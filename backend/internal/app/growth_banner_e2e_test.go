package app

import (
	"bytes"
	"context"
	"encoding/json"
	"image"
	"image/color"
	"image/jpeg"
	"image/png"
	"io"
	"mime/multipart"
	"net/http"
	"strings"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// bannerPNG is a w×h test image. Its top tenth is noise, so the file is as
// large as a real photo's (well over the API's usual 64 KB body cap).
func bannerPNG(t *testing.T, w, h int) []byte {
	t.Helper()
	img := image.NewRGBA(image.Rect(0, 0, w, h))
	seed := uint32(7)
	for x := range w {
		for y := range h {
			c := color.RGBA{R: uint8(x % 256), G: 118, B: 110, A: 255}
			if y < h/10 {
				seed = seed*1664525 + 1013904223
				c = color.RGBA{R: uint8(seed >> 24), G: uint8(seed >> 16), B: uint8(seed >> 8), A: 255}
			}
			img.Set(x, y, c)
		}
	}
	var buf bytes.Buffer
	require.NoError(t, png.Encode(&buf, img))
	return buf.Bytes()
}

// postBanner uploads a banner as multipart/form-data.
func (h *harness) postBanner(tok, id string, data []byte) *response {
	h.t.Helper()
	var body bytes.Buffer
	mw := multipart.NewWriter(&body)
	fw, err := mw.CreateFormFile("image", "banner.png")
	require.NoError(h.t, err)
	_, _ = fw.Write(data)
	require.NoError(h.t, mw.Close())
	req, err := http.NewRequest("POST", h.srv.URL+"/api/v1/admin/campaigns/"+id+"/banner", &body)
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

// publicGet fetches an API path without signing in.
func (h *harness) publicGet(path string) (*http.Response, []byte) {
	h.t.Helper()
	res, err := http.Get(h.srv.URL + "/api/v1" + path)
	require.NoError(h.t, err)
	defer res.Body.Close()
	b, _ := io.ReadAll(res.Body)
	return res, b
}

type gwBanner struct {
	ID        string  `json:"id"`
	BannerURL *string `json:"bannerUrl"`
}

func TestGrowthCampaignBanner(t *testing.T) {
	h := newHarness(t)
	now := h.Now()
	admin := h.gwStudent("admin@test.ac.bd", "Admin One")
	h.sql(`UPDATE users SET role = 'admin' WHERE id = $1`, admin.ID)
	student := h.gwStudent("s1@test.ac.bd", "Sara One")

	c := h.gwAdminCampaign(admin.Tok, "POST", "/admin/campaigns", campaignBody(now.Add(-time.Hour), now.Add(48*time.Hour), nil), http.StatusCreated)
	var b gwBanner
	h.do("GET", "/admin/campaigns/"+c.ID, admin.Tok, nil).into(t, &b)
	assert.Nil(t, b.BannerURL, "no banner yet")

	// Only admins upload; a non-image is refused.
	assert.Equal(t, http.StatusForbidden, h.postBanner(student.Tok, c.ID, bannerPNG(t, 40, 20)).Status)
	assert.Equal(t, "INVALID_IMAGE", h.postBanner(admin.Tok, c.ID, []byte("not an image")).code())

	// Upload: re-encoded JPEG, at most 1600 px wide, shape kept.
	big := bannerPNG(t, 2000, 1000)
	require.Greater(t, len(big), 256<<10, "a photo-sized upload")
	r := h.postBanner(admin.Tok, c.ID, big)
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	r.into(t, &b)
	require.NotNil(t, b.BannerURL)
	first := *b.BannerURL
	assert.True(t, strings.HasPrefix(first, "/campaigns/"+c.ID+"/banner?v="), first)

	// A draft's banner: only with the current version (the admin preview).
	res, _ := h.publicGet(first)
	assert.Equal(t, http.StatusOK, res.StatusCode)
	res, _ = h.publicGet("/campaigns/" + c.ID + "/banner")
	assert.Equal(t, http.StatusNotFound, res.StatusCode, "a draft's banner needs the current version")
	res, _ = h.publicGet("/campaigns/" + c.ID + "/banner?v=old")
	assert.Equal(t, http.StatusNotFound, res.StatusCode)

	h.gwAdminCampaign(admin.Tok, "PATCH", "/admin/campaigns/"+c.ID, map[string]any{"status": "live"}, http.StatusOK)

	// Public, no sign-in: image/jpeg, long-cached for the current version.
	res, body := h.publicGet(first)
	require.Equal(t, http.StatusOK, res.StatusCode, string(body))
	assert.Equal(t, "image/jpeg", res.Header.Get("Content-Type"))
	assert.Contains(t, res.Header.Get("Cache-Control"), "immutable")
	cfg, err := jpeg.DecodeConfig(bytes.NewReader(body))
	require.NoError(t, err)
	assert.Equal(t, 1600, cfg.Width)
	assert.Equal(t, 800, cfg.Height)
	res, _ = h.publicGet("/campaigns/" + c.ID + "/banner?v=old")
	assert.Equal(t, http.StatusOK, res.StatusCode)
	assert.NotContains(t, res.Header.Get("Cache-Control"), "immutable", "an old version link is only cached briefly")

	// Every campaign view carries the same bannerUrl.
	var detail gwBanner
	h.do("GET", "/campaigns/"+c.ID, student.Tok, nil).into(t, &detail)
	require.NotNil(t, detail.BannerURL)
	assert.Equal(t, first, *detail.BannerURL)
	var list []gwBanner
	h.do("GET", "/campaigns", student.Tok, nil).into(t, &list)
	require.Len(t, list, 1)
	require.NotNil(t, list[0].BannerURL)
	assert.Equal(t, first, *list[0].BannerURL)
	res, body = h.publicGet("/campaigns/" + c.ID + "/public")
	require.Equal(t, http.StatusOK, res.StatusCode)
	assert.Contains(t, string(body), `"bannerUrl":"`+first+`"`)
	var page struct {
		Items []gwBanner `json:"items"`
	}
	h.do("GET", "/admin/campaigns", admin.Tok, nil).into(t, &page)
	require.Len(t, page.Items, 1)
	require.NotNil(t, page.Items[0].BannerURL)

	// Replacing changes the version.
	r = h.postBanner(admin.Tok, c.ID, bannerPNG(t, 800, 400))
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	r.into(t, &b)
	require.NotNil(t, b.BannerURL)
	assert.NotEqual(t, first, *b.BannerURL)
	res, body = h.publicGet(*b.BannerURL)
	require.Equal(t, http.StatusOK, res.StatusCode)
	cfg, err = jpeg.DecodeConfig(bytes.NewReader(body))
	require.NoError(t, err)
	assert.Equal(t, 800, cfg.Width, "never enlarged")

	// Remove.
	assert.Equal(t, http.StatusForbidden, h.do("DELETE", "/admin/campaigns/"+c.ID+"/banner", student.Tok, nil).Status)
	r = h.do("DELETE", "/admin/campaigns/"+c.ID+"/banner", admin.Tok, nil)
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	r.into(t, &b)
	assert.Nil(t, b.BannerURL)
	res, _ = h.publicGet("/campaigns/" + c.ID + "/banner")
	assert.Equal(t, http.StatusNotFound, res.StatusCode)

	var audits int
	require.NoError(t, h.app.DB.Pool.QueryRow(context.Background(),
		`SELECT count(*) FROM audit_log WHERE action IN ('campaign.banner', 'campaign.banner_remove') AND target_id = $1`, c.ID).Scan(&audits))
	assert.Equal(t, 3, audits)
}
