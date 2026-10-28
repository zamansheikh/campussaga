package media

import (
	"io"
	"net/http"
	"net/http/httptest"
	"strings"
	"sync"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// fakeNimbus implements the four Nimbus calls the store uses.
type fakeNimbus struct {
	mu      sync.Mutex
	objects map[string][]byte // object key → bytes
	ids     map[string]string // id → object key
	fields  map[string]string // last upload's form fields
	lookups int
}

func newFakeNimbus(t *testing.T) (*fakeNimbus, *httptest.Server) {
	f := &fakeNimbus{objects: map[string][]byte{}, ids: map[string]string{}}
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Header.Get("Authorization") != "Bearer test-key" {
			http.Error(w, `{"error":"unauthorized"}`, http.StatusUnauthorized)
			return
		}
		f.mu.Lock()
		defer f.mu.Unlock()
		switch {
		case r.Method == http.MethodPost && r.URL.Path == "/api/v1/assets/upload":
			require.NoError(t, r.ParseMultipartForm(1<<20))
			f.fields = map[string]string{}
			for k, v := range r.MultipartForm.Value {
				f.fields[k] = v[0]
			}
			file, _, err := r.FormFile("file")
			require.NoError(t, err)
			data, _ := io.ReadAll(file)
			key := f.fields["key"]
			id := "id-" + strings.ReplaceAll(key, "/", "_")
			f.objects[key], f.ids[id] = data, key
			_, _ = io.WriteString(w, `{"uploaded":[{"_id":"`+id+`","key":"`+key+`"}],"count":1}`)
		case r.Method == http.MethodGet && r.URL.Path == "/api/v1/assets/by-url":
			f.lookups++
			key := r.URL.Query().Get("url")
			for id, k := range f.ids {
				if k == key {
					_, _ = io.WriteString(w, `{"_id":"`+id+`","key":"`+k+`"}`)
					return
				}
			}
			http.Error(w, `{"error":"not found"}`, http.StatusNotFound)
		case r.Method == http.MethodGet && strings.HasSuffix(r.URL.Path, "/raw"):
			id := strings.TrimSuffix(strings.TrimPrefix(r.URL.Path, "/api/v1/assets/"), "/raw")
			key, ok := f.ids[id]
			if !ok {
				http.Error(w, `{"error":"not found"}`, http.StatusNotFound)
				return
			}
			_, _ = w.Write(f.objects[key])
		case r.Method == http.MethodDelete && r.URL.Path == "/api/v1/assets/by-url":
			key := r.URL.Query().Get("url")
			for id, k := range f.ids {
				if k == key {
					delete(f.ids, id)
					delete(f.objects, k)
					_, _ = io.WriteString(w, `{"deleted":true}`)
					return
				}
			}
			http.Error(w, `{"error":"not found"}`, http.StatusNotFound)
		default:
			http.NotFound(w, r)
		}
	}))
	t.Cleanup(srv.Close)
	return f, srv
}

func TestNimbusStore(t *testing.T) {
	f, srv := newFakeNimbus(t)
	n := NewNimbus(srv.URL+"/api/v1/", "test-key", "varsitykotha/voice/")
	key := "0b6f1c2e-5a9d-4c1e-9b7a-3d2f1e0c9b8a-full.jpg"

	require.NoError(t, n.Put(key, []byte("jpeg-bytes")))
	assert.Equal(t, "varsitykotha/voice/"+key, f.fields["key"])
	assert.Equal(t, "false", f.fields["optimize"], "already re-encoded: upload byte for byte")
	assert.Equal(t, "image/jpeg", f.fields["contentType"])

	r, err := n.Open(key)
	require.NoError(t, err)
	b, _ := io.ReadAll(r)
	assert.Equal(t, "jpeg-bytes", string(b))
	assert.Equal(t, 0, f.lookups, "the id from the upload is remembered")

	// A fresh store (another process) finds it by key.
	n2 := NewNimbus(srv.URL+"/api/v1", "test-key", "varsitykotha/voice/")
	r, err = n2.Open(key)
	require.NoError(t, err)
	b, _ = io.ReadAll(r)
	assert.Equal(t, "jpeg-bytes", string(b))
	assert.Equal(t, 1, f.lookups)

	require.NoError(t, n.Delete(key))
	_, err = n2.Open(key)
	assert.ErrorIs(t, err, ErrNotFound)
	require.NoError(t, n.Delete(key), "deleting twice is fine")

	_, err = n.Open("../etc/passwd")
	assert.ErrorIs(t, err, ErrNotFound, "only our own key format")
	assert.Error(t, NewNimbus(srv.URL+"/api/v1", "wrong", "p/").Put(key, []byte("x")))
}
