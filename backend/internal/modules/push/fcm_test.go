package push

import (
	"context"
	"crypto/rand"
	"crypto/rsa"
	"crypto/x509"
	"encoding/json"
	"encoding/pem"
	"io"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"strings"
	"sync/atomic"
	"testing"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestFCMSend(t *testing.T) {
	key, err := rsa.GenerateKey(rand.Reader, 2048)
	require.NoError(t, err)
	pemKey := pem.EncodeToMemory(&pem.Block{Type: "RSA PRIVATE KEY", Bytes: x509.MarshalPKCS1PrivateKey(key)})
	now := time.Date(2026, 10, 27, 9, 0, 0, 0, time.UTC)

	var oauthCalls atomic.Int32
	var lastMessage map[string]any
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		switch r.URL.Path {
		case "/token":
			oauthCalls.Add(1)
			require.NoError(t, r.ParseForm())
			assert.Equal(t, "urn:ietf:params:oauth:grant-type:jwt-bearer", r.Form.Get("grant_type"))
			tok, err := jwt.Parse(r.Form.Get("assertion"), func(*jwt.Token) (any, error) { return &key.PublicKey, nil },
				jwt.WithTimeFunc(func() time.Time { return now }))
			require.NoError(t, err)
			claims := tok.Claims.(jwt.MapClaims)
			assert.Equal(t, "push@test.iam.gserviceaccount.com", claims["iss"])
			assert.Equal(t, "https://www.googleapis.com/auth/firebase.messaging", claims["scope"])
			_, _ = io.WriteString(w, `{"access_token":"at-1","expires_in":3600}`)
		case "/send":
			assert.Equal(t, "Bearer at-1", r.Header.Get("Authorization"))
			var body map[string]map[string]any
			require.NoError(t, json.NewDecoder(r.Body).Decode(&body))
			lastMessage = body["message"]
			if lastMessage["token"] == "gone" {
				w.WriteHeader(http.StatusNotFound)
				_, _ = io.WriteString(w, `{"error":{"status":"NOT_FOUND","details":[{"errorCode":"UNREGISTERED"}]}}`)
				return
			}
			_, _ = io.WriteString(w, `{"name":"projects/p/messages/1"}`)
		default:
			http.NotFound(w, r)
		}
	}))
	defer srv.Close()

	sa, _ := json.Marshal(map[string]string{
		"project_id": "p", "client_email": "push@test.iam.gserviceaccount.com",
		"private_key": string(pemKey), "token_uri": srv.URL + "/token",
	})
	path := filepath.Join(t.TempDir(), "sa.json")
	require.NoError(t, os.WriteFile(path, sa, 0o600))
	f, err := NewFCMFromFile(path, func() time.Time { return now })
	require.NoError(t, err)
	f.sendURL = srv.URL + "/send"

	n := Notification{Token: "t1", Platform: "android", Title: "CSE311 cancelled tomorrow", Body: "CSE 61", Data: map[string]string{"groupId": "g"}}
	require.NoError(t, f.Send(context.Background(), n))
	require.NoError(t, f.Send(context.Background(), n))
	assert.EqualValues(t, 1, oauthCalls.Load(), "access token reused")
	assert.Equal(t, map[string]any{"title": "CSE311 cancelled tomorrow", "body": "CSE 61"}, lastMessage["notification"])
	assert.Equal(t, "class_updates", lastMessage["android"].(map[string]any)["notification"].(map[string]any)["channel_id"])

	n.Token = "gone"
	assert.ErrorIs(t, f.Send(context.Background(), n), ErrTokenGone)

	_, err = NewFCMFromFile(filepath.Join(t.TempDir(), "missing.json"), time.Now)
	assert.Error(t, err)
	bad := filepath.Join(t.TempDir(), "bad.json")
	require.NoError(t, os.WriteFile(bad, []byte(`{"private_key":"nope"}`), 0o600))
	_, err = NewFCMFromFile(bad, time.Now)
	assert.True(t, err != nil && strings.Contains(err.Error(), "key"))
}
