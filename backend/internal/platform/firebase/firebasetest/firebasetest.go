// Package firebasetest mints Firebase-style ID tokens for tests.
package firebasetest

import (
	"crypto/rand"
	"crypto/rsa"
	"time"

	"github.com/golang-jwt/jwt/v5"

	"github.com/zamansheikh/varsitykotha/backend/internal/platform/firebase"
)

// Signer holds a test key pair standing in for Google's.
type Signer struct {
	ProjectID string
	KeyID     string
	key       *rsa.PrivateKey
}

// New makes a signer with a fresh 2048-bit key.
func New(projectID string) *Signer {
	k, err := rsa.GenerateKey(rand.Reader, 2048)
	if err != nil {
		panic(err)
	}
	return &Signer{ProjectID: projectID, KeyID: "test-kid", key: k}
}

// Keys is the public side, to plug into firebase.NewVerifier.
func (s *Signer) Keys() firebase.StaticKeys {
	return firebase.StaticKeys{s.KeyID: &s.key.PublicKey}
}

// Token options.
type Token struct {
	UID           string
	Email         string
	EmailVerified bool
	Name          string    // the Google name; empty = no name claim
	Picture       string    // the Google photo URL; empty = no picture claim
	Provider      string    // default google.com
	IssuedAt      time.Time // default now
	Audience      string    // default ProjectID
	Issuer        string    // default securetoken issuer
}

// Sign mints a token valid for one hour from IssuedAt.
func (s *Signer) Sign(t Token) string {
	if t.Provider == "" {
		t.Provider = "google.com"
	}
	if t.IssuedAt.IsZero() {
		t.IssuedAt = time.Now()
	}
	if t.Audience == "" {
		t.Audience = s.ProjectID
	}
	if t.Issuer == "" {
		t.Issuer = "https://securetoken.google.com/" + s.ProjectID
	}
	if t.UID == "" {
		t.UID = "uid-" + t.Email
	}
	claims := jwt.MapClaims{
		"iss":            t.Issuer,
		"aud":            t.Audience,
		"sub":            t.UID,
		"iat":            t.IssuedAt.Unix(),
		"auth_time":      t.IssuedAt.Unix(),
		"exp":            t.IssuedAt.Add(time.Hour).Unix(),
		"email":          t.Email,
		"email_verified": t.EmailVerified,
		"firebase":       map[string]any{"sign_in_provider": t.Provider},
	}
	if t.Name != "" {
		claims["name"] = t.Name
	}
	if t.Picture != "" {
		claims["picture"] = t.Picture
	}
	tok := jwt.NewWithClaims(jwt.SigningMethodRS256, claims)
	tok.Header["kid"] = s.KeyID
	out, err := tok.SignedString(s.key)
	if err != nil {
		panic(err)
	}
	return out
}
