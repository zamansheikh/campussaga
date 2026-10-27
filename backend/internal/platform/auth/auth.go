// Package auth mints and verifies access tokens and carries the signed-in
// user through the request context.
//
// Access token: JWT, HS256, short-lived (15 min by default). It carries the
// user id (sub), session id (sid), university (uni) and role. Refresh
// tokens are opaque random strings stored only as hashes (see accounts).
package auth

import (
	"context"
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"errors"
	"net/http"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"

	"github.com/zamansheikh/campussaga/backend/internal/platform/apperr"
)

const (
	issuer   = "campussaga"
	audience = "campussaga-app"
)

var (
	// ErrUnauthorized: no token sent.
	ErrUnauthorized = apperr.New(http.StatusUnauthorized, "UNAUTHORIZED", "Please sign in")
	// ErrTokenExpired: the app should refresh and retry.
	ErrTokenExpired = apperr.New(http.StatusUnauthorized, "TOKEN_EXPIRED", "Your session expired")
	// ErrTokenInvalid: malformed, wrong signature or wrong audience.
	ErrTokenInvalid = apperr.New(http.StatusUnauthorized, "TOKEN_INVALID", "Please sign in again")
	// ErrNotAdmin: signed in, but not an admin (admin panel).
	ErrNotAdmin = apperr.New(http.StatusForbidden, "NOT_ADMIN", "This account is not an admin")
)

// Claims of a verified access token.
type Claims struct {
	UserID       uuid.UUID
	SessionID    uuid.UUID
	UniversityID uuid.UUID // uuid.Nil: not chosen yet (not verified student)
	Role         string
	ExpiresAt    time.Time

	// Verified: proved a university email. Not in the token: the session
	// check fills it (and refreshes UniversityID) from the database.
	Verified bool
}

type jwtClaims struct {
	SID  string `json:"sid"`
	Uni  string `json:"uni"`
	Role string `json:"role"`
	jwt.RegisteredClaims
}

// Tokens signs and verifies access tokens.
type Tokens struct {
	secret []byte
	ttl    time.Duration
	now    func() time.Time
}

// NewTokens; now may be nil.
func NewTokens(secret []byte, ttl time.Duration, now func() time.Time) *Tokens {
	if now == nil {
		now = time.Now
	}
	return &Tokens{secret: secret, ttl: ttl, now: now}
}

// TTL of issued access tokens.
func (t *Tokens) TTL() time.Duration { return t.ttl }

// Issue signs an access token for c (ExpiresAt is set from the TTL).
func (t *Tokens) Issue(c Claims) (string, time.Time, error) {
	now := t.now()
	exp := now.Add(t.ttl)
	tok := jwt.NewWithClaims(jwt.SigningMethodHS256, jwtClaims{
		SID:  c.SessionID.String(),
		Uni:  c.UniversityID.String(),
		Role: c.Role,
		RegisteredClaims: jwt.RegisteredClaims{
			Issuer:    issuer,
			Audience:  jwt.ClaimStrings{audience},
			Subject:   c.UserID.String(),
			IssuedAt:  jwt.NewNumericDate(now),
			ExpiresAt: jwt.NewNumericDate(exp),
		},
	})
	s, err := tok.SignedString(t.secret)
	return s, exp, err
}

// Verify checks signature, algorithm, issuer, audience and expiry.
func (t *Tokens) Verify(token string) (*Claims, error) {
	var jc jwtClaims
	_, err := jwt.ParseWithClaims(token, &jc,
		func(*jwt.Token) (any, error) { return t.secret, nil },
		jwt.WithValidMethods([]string{jwt.SigningMethodHS256.Alg()}),
		jwt.WithIssuer(issuer),
		jwt.WithAudience(audience),
		jwt.WithExpirationRequired(),
		jwt.WithTimeFunc(t.now),
	)
	if err != nil {
		if errors.Is(err, jwt.ErrTokenExpired) {
			return nil, ErrTokenExpired
		}
		return nil, ErrTokenInvalid
	}
	uid, err1 := uuid.Parse(jc.Subject)
	sid, err2 := uuid.Parse(jc.SID)
	uni, err3 := uuid.Parse(jc.Uni)
	if err1 != nil || err2 != nil || err3 != nil {
		return nil, ErrTokenInvalid
	}
	return &Claims{UserID: uid, SessionID: sid, UniversityID: uni, Role: jc.Role, ExpiresAt: jc.ExpiresAt.Time}, nil
}

type userKey struct{}

// WithUser stores verified claims in ctx.
func WithUser(ctx context.Context, c *Claims) context.Context {
	return context.WithValue(ctx, userKey{}, c)
}

// User returns the signed-in user's claims.
func User(ctx context.Context) (*Claims, bool) {
	c, ok := ctx.Value(userKey{}).(*Claims)
	return c, ok
}

// MustUser is for handlers mounted on Student routes.
func MustUser(ctx context.Context) *Claims {
	c, ok := User(ctx)
	if !ok {
		panic("auth.MustUser on a route without the Student guard")
	}
	return c
}

// RandomToken returns n random bytes, base64url encoded (refresh tokens).
func RandomToken(n int) string {
	b := make([]byte, n)
	_, _ = rand.Read(b)
	return base64.RawURLEncoding.EncodeToString(b)
}

// HashToken is how opaque tokens are stored: SHA-256 (they are 256-bit
// random, so a plain hash is enough; no salt or slow hash needed).
func HashToken(s string) []byte {
	h := sha256.Sum256([]byte(s))
	return h[:]
}
