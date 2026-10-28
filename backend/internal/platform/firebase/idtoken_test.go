package firebase_test

import (
	"context"
	"crypto/rand"
	"crypto/rsa"
	"crypto/x509"
	"crypto/x509/pkix"
	"encoding/json"
	"encoding/pem"
	"math/big"
	"net/http"
	"net/http/httptest"
	"sync/atomic"
	"testing"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/zamansheikh/varsitykotha/backend/internal/platform/firebase"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/firebase/firebasetest"
)

func TestVerify(t *testing.T) {
	now := time.Date(2026, 10, 27, 10, 0, 0, 0, time.UTC)
	s := firebasetest.New("campus-test")
	v := firebase.NewVerifier("campus-test", s.Keys(), func() time.Time { return now })
	ctx := context.Background()

	id, err := v.Verify(ctx, s.Sign(firebasetest.Token{Email: "a@test.ac.bd", EmailVerified: true, IssuedAt: now}))
	require.NoError(t, err)
	assert.Equal(t, "a@test.ac.bd", id.Email)
	assert.True(t, id.EmailVerified)
	assert.Equal(t, "google.com", id.Provider)

	bad := map[string]string{
		"other project": s.Sign(firebasetest.Token{Email: "a@x", IssuedAt: now, Audience: "someone-else"}),
		"wrong issuer":  s.Sign(firebasetest.Token{Email: "a@x", IssuedAt: now, Issuer: "https://evil.example"}),
		"expired":       s.Sign(firebasetest.Token{Email: "a@x", IssuedAt: now.Add(-2 * time.Hour)}),
		"issued later":  s.Sign(firebasetest.Token{Email: "a@x", IssuedAt: now.Add(time.Hour)}),
		"other key":     firebasetest.New("campus-test").Sign(firebasetest.Token{Email: "a@x", IssuedAt: now}),
		"garbage":       "not.a.token",
	}
	for name, tok := range bad {
		_, err := v.Verify(ctx, tok)
		assert.ErrorIs(t, err, firebase.ErrInvalidToken, name)
	}

	// An HS256 token signed with the public key as secret (alg confusion) is refused.
	hs := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{"sub": "x", "aud": "campus-test"})
	hs.Header["kid"] = s.KeyID
	hsTok, _ := hs.SignedString([]byte("whatever"))
	_, err = v.Verify(ctx, hsTok)
	assert.ErrorIs(t, err, firebase.ErrInvalidToken, "HS256")
}

func TestGoogleKeysFetchAndCache(t *testing.T) {
	key, err := rsa.GenerateKey(rand.Reader, 2048)
	require.NoError(t, err)
	tmpl := &x509.Certificate{SerialNumber: big.NewInt(1), Subject: pkix.Name{CommonName: "test"},
		NotBefore: time.Now().Add(-time.Hour), NotAfter: time.Now().Add(time.Hour)}
	der, err := x509.CreateCertificate(rand.Reader, tmpl, tmpl, &key.PublicKey, key)
	require.NoError(t, err)
	certPEM := string(pem.EncodeToMemory(&pem.Block{Type: "CERTIFICATE", Bytes: der}))

	var hits atomic.Int32
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		hits.Add(1)
		w.Header().Set("Cache-Control", "public, max-age=3600, must-revalidate")
		_ = json.NewEncoder(w).Encode(map[string]string{"kid1": certPEM})
	}))
	defer srv.Close()

	now := time.Date(2026, 10, 27, 10, 0, 0, 0, time.UTC)
	g := firebase.NewGoogleKeys(func() time.Time { return now })
	g.URL = srv.URL

	keys, err := g.Keys(context.Background(), false)
	require.NoError(t, err)
	assert.Equal(t, key.PublicKey.N, keys["kid1"].N)

	_, _ = g.Keys(context.Background(), false)
	_, _ = g.Keys(context.Background(), true)
	assert.Equal(t, int32(1), hits.Load(), "cached; forced refresh limited to once a minute")

	now = now.Add(2 * time.Hour)
	_, _ = g.Keys(context.Background(), false)
	assert.Equal(t, int32(2), hits.Load(), "refetched after max-age")
}
