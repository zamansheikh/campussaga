package app

import (
	"bytes"
	"encoding/json"
	"io"
	"mime/multipart"
	"net/http"
	"os"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/zamansheikh/varsitykotha/backend/internal/platform/firebase/firebasetest"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/media/mediatest"
)

type photoMeJSON struct {
	ID             string  `json:"id"`
	PhotoVersion   *string `json:"photoVersion"`
	GooglePhotoURL *string `json:"googlePhotoUrl"`
	Department     *string `json:"department"`
}

// putPhoto sends a profile photo as multipart/form-data.
func (h *harness) putPhoto(tok string, data []byte) *response {
	h.t.Helper()
	var body bytes.Buffer
	mw := multipart.NewWriter(&body)
	fw, err := mw.CreateFormFile("image", "me.jpg")
	require.NoError(h.t, err)
	_, _ = fw.Write(data)
	require.NoError(h.t, mw.Close())
	req, err := http.NewRequest("PUT", h.srv.URL+"/api/v1/me/photo", &body)
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

// Google sign-in brings the account photo; it keeps department and batch.
func TestGooglePhoto(t *testing.T) {
	h := newHarness(t)
	pic := "https://lh3.googleusercontent.com/a/abc=s96-c"
	sign := func(name, picture string) signedIn {
		tok := h.google.Sign(firebasetest.Token{Email: "lina@cse.test.ac.bd", EmailVerified: true, Name: name, Picture: picture, IssuedAt: h.Now()})
		r := h.do("POST", "/auth/google", "", map[string]string{"idToken": tok})
		require.Equal(t, http.StatusOK, r.Status, r.Raw)
		var s signedIn
		r.into(t, &s)
		return s
	}
	s := sign("", pic)
	var me photoMeJSON
	h.do("GET", "/me", s.Tokens.AccessToken, nil).into(t, &me)
	require.NotNil(t, me.GooglePhotoURL)
	assert.Equal(t, pic, *me.GooglePhotoURL)

	// Department set, then a sign-in that fills the empty name: kept.
	require.Equal(t, http.StatusOK, h.do("PATCH", "/me", s.Tokens.AccessToken, map[string]any{"department": "CSE"}).Status)
	s = sign("Lina Akter", "http://insecure.example/x.jpg") // not https: ignored
	h.do("GET", "/me", s.Tokens.AccessToken, nil).into(t, &me)
	require.NotNil(t, me.Department)
	assert.Equal(t, "CSE", *me.Department)
	assert.Equal(t, pic, *me.GooglePhotoURL)
}

func TestProfilePhoto(t *testing.T) {
	check := &queueChecker{}
	h := newHarnessWith(t, func(o *Options) { o.PhotoChecker = check })
	me := h.signIn("me@test.ac.bd")
	tok := me.Tokens.AccessToken
	other := h.signIn("other@test.ac.bd").Tokens.AccessToken
	admin := h.makeAdmin("admin@test.ac.bd")
	photo := mediatest.JPEGWithExif(t, 900, 700, 1)
	files := func() int {
		f, err := os.ReadDir(h.media.Dir)
		require.NoError(t, err)
		return len(f)
	}

	// Refused by the photo check: nothing stored.
	check.scores = []float64{0.9}
	assert.Equal(t, "PHOTO_NOT_ALLOWED", h.putPhoto(tok, photo).code())
	assert.Equal(t, 0, files())

	// A fine photo.
	check.scores = []float64{0.01}
	r := h.putPhoto(tok, photo)
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	var m photoMeJSON
	r.into(t, &m)
	require.NotNil(t, m.PhotoVersion)
	assert.Equal(t, 1, files())
	path := "/users/" + me.User.ID + "/photo?v=" + *m.PhotoVersion

	status, body := h.raw(tok, path)
	assert.Equal(t, http.StatusOK, status)
	assert.Equal(t, []byte{0xFF, 0xD8}, body[:2], "a JPEG")
	status, _ = h.raw(admin, path)
	assert.Equal(t, http.StatusOK, status, "admins see it")
	status, _ = h.raw(other, path)
	assert.Equal(t, http.StatusNotFound, status, "not a classmate")

	// A new photo replaces the old file.
	check.scores = []float64{0.01}
	require.Equal(t, http.StatusOK, h.putPhoto(tok, photo).Status)
	assert.Equal(t, 1, files())

	// Removing it.
	r = h.do("DELETE", "/me/photo", tok, nil)
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	r.into(t, &m)
	assert.Nil(t, m.PhotoVersion)
	assert.Equal(t, 0, files())

	// Deleting the account deletes the photo file.
	check.scores = []float64{0.01}
	require.Equal(t, http.StatusOK, h.putPhoto(tok, photo).Status)
	require.Equal(t, 1, files())
	require.Equal(t, http.StatusNoContent, h.do("DELETE", "/me", tok, nil).Status)
	assert.Equal(t, 0, files())
}
