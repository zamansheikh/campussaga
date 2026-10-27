// Package firebase verifies Firebase Authentication ID tokens.
//
// The app signs in with Google through Firebase Auth and sends the Firebase
// ID token to POST /auth/google. We verify it locally, exactly as the
// Firebase docs describe for third-party JWT libraries: RS256, a key id
// published by Google's securetoken service, audience = our project id,
// issuer = https://securetoken.google.com/<project id>, unexpired, issued and
// authenticated in the past, non-empty subject. No service account or admin
// SDK is needed for this.
package firebase

import (
	"context"
	"crypto/rsa"
	"errors"
	"fmt"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

// Identity is what a verified token says about the user.
type Identity struct {
	UID           string
	Email         string
	EmailVerified bool
	Name          string
	// Provider is how the user signed in to Firebase, e.g. "google.com".
	Provider string
}

// KeySource returns Google's current signing keys by key id.
type KeySource interface {
	Keys(ctx context.Context, refresh bool) (map[string]*rsa.PublicKey, error)
}

// ErrInvalidToken is returned for every rejected token (details are logged
// by the caller, never shown to clients).
var ErrInvalidToken = errors.New("firebase: invalid ID token")

// Verifier checks Firebase ID tokens for one project.
type Verifier struct {
	projectID string
	keys      KeySource
	now       func() time.Time
}

// NewVerifier; now may be nil.
func NewVerifier(projectID string, keys KeySource, now func() time.Time) *Verifier {
	if now == nil {
		now = time.Now
	}
	return &Verifier{projectID: projectID, keys: keys, now: now}
}

type claims struct {
	Email         string `json:"email"`
	EmailVerified bool   `json:"email_verified"`
	Name          string `json:"name"`
	AuthTime      int64  `json:"auth_time"`
	Firebase      struct {
		SignInProvider string `json:"sign_in_provider"`
		Tenant         string `json:"tenant"`
	} `json:"firebase"`
	jwt.RegisteredClaims
}

// Verify checks the token and returns the identity it carries.
func (v *Verifier) Verify(ctx context.Context, token string) (*Identity, error) {
	if len(token) > 8192 {
		return nil, fmt.Errorf("%w: too long", ErrInvalidToken)
	}
	var c claims
	keyFunc := func(t *jwt.Token) (any, error) {
		kid, _ := t.Header["kid"].(string)
		if kid == "" {
			return nil, errors.New("missing kid")
		}
		keys, err := v.keys.Keys(ctx, false)
		if err != nil {
			return nil, err
		}
		if k, ok := keys[kid]; ok {
			return k, nil
		}
		// Google rotates keys; refetch once before giving up.
		keys, err = v.keys.Keys(ctx, true)
		if err != nil {
			return nil, err
		}
		if k, ok := keys[kid]; ok {
			return k, nil
		}
		return nil, fmt.Errorf("unknown kid %q", kid)
	}
	_, err := jwt.ParseWithClaims(token, &c, keyFunc,
		jwt.WithValidMethods([]string{jwt.SigningMethodRS256.Alg()}),
		jwt.WithAudience(v.projectID),
		jwt.WithIssuer("https://securetoken.google.com/"+v.projectID),
		jwt.WithExpirationRequired(),
		jwt.WithIssuedAt(),
		jwt.WithLeeway(30*time.Second),
		jwt.WithTimeFunc(v.now),
	)
	if err != nil {
		return nil, fmt.Errorf("%w: %v", ErrInvalidToken, err)
	}
	if c.Subject == "" || len(c.Subject) > 128 {
		return nil, fmt.Errorf("%w: bad subject", ErrInvalidToken)
	}
	if c.AuthTime == 0 || time.Unix(c.AuthTime, 0).After(v.now().Add(30*time.Second)) {
		return nil, fmt.Errorf("%w: bad auth_time", ErrInvalidToken)
	}
	if c.Firebase.Tenant != "" {
		return nil, fmt.Errorf("%w: unexpected tenant", ErrInvalidToken)
	}
	return &Identity{
		UID: c.Subject, Email: c.Email, EmailVerified: c.EmailVerified,
		Name: c.Name, Provider: c.Firebase.SignInProvider,
	}, nil
}
