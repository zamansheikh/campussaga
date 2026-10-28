package auth

import (
	"testing"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestIssueAndVerify(t *testing.T) {
	now := time.Date(2026, 10, 27, 10, 0, 0, 0, time.UTC)
	tok := NewTokens([]byte("0123456789abcdef0123456789abcdef"), 15*time.Minute, func() time.Time { return now })
	in := Claims{UserID: uuid.New(), SessionID: uuid.New(), UniversityID: uuid.New(), Role: "student"}

	s, exp, err := tok.Issue(in)
	require.NoError(t, err)
	assert.Equal(t, now.Add(15*time.Minute), exp)

	got, err := tok.Verify(s)
	require.NoError(t, err)
	assert.Equal(t, in.UserID, got.UserID)
	assert.Equal(t, in.SessionID, got.SessionID)
	assert.Equal(t, in.UniversityID, got.UniversityID)
	assert.Equal(t, "student", got.Role)

	now = now.Add(16 * time.Minute)
	_, err = tok.Verify(s)
	assert.ErrorIs(t, err, ErrTokenExpired)
}

func TestVerifyRejectsForeignTokens(t *testing.T) {
	ours := NewTokens([]byte("0123456789abcdef0123456789abcdef"), time.Minute, nil)
	theirs := NewTokens([]byte("another-secret-another-secret-xx"), time.Minute, nil)
	s, _, err := theirs.Issue(Claims{UserID: uuid.New(), SessionID: uuid.New(), UniversityID: uuid.New()})
	require.NoError(t, err)

	_, err = ours.Verify(s)
	assert.ErrorIs(t, err, ErrTokenInvalid, "wrong signature")

	_, err = ours.Verify("not-a-jwt")
	assert.ErrorIs(t, err, ErrTokenInvalid)

	// alg=none must never be accepted.
	none := "eyJhbGciOiJub25lIiwidHlwIjoiSldUIn0.eyJzdWIiOiJ4In0."
	_, err = ours.Verify(none)
	assert.ErrorIs(t, err, ErrTokenInvalid)
}

// Tokens from before the rename (issuer "campussaga") still work until they
// expire, so the switch signs nobody out; other issuers don't.
func TestVerifyAcceptsTokensFromBeforeTheRename(t *testing.T) {
	secret := []byte("0123456789abcdef0123456789abcdef")
	now := time.Date(2026, 10, 29, 9, 0, 0, 0, time.UTC)
	tok := NewTokens(secret, 15*time.Minute, func() time.Time { return now })
	mint := func(iss, aud string, exp time.Time) string {
		c := jwtClaims{
			SID: uuid.NewString(), Uni: uuid.NewString(), Role: "student",
			RegisteredClaims: jwt.RegisteredClaims{
				Subject: uuid.NewString(), Issuer: iss, Audience: jwt.ClaimStrings{aud},
				ExpiresAt: jwt.NewNumericDate(exp), IssuedAt: jwt.NewNumericDate(now),
			},
		}
		s, err := jwt.NewWithClaims(jwt.SigningMethodHS256, c).SignedString(secret)
		require.NoError(t, err)
		return s
	}
	_, err := tok.Verify(mint("campussaga", "campussaga-app", now.Add(time.Minute)))
	assert.NoError(t, err)
	_, err = tok.Verify(mint("campussaga", "campussaga-app", now.Add(-time.Minute)))
	assert.ErrorIs(t, err, ErrTokenExpired)
	_, err = tok.Verify(mint("someone-else", "campussaga-app", now.Add(time.Minute)))
	assert.ErrorIs(t, err, ErrTokenInvalid)
}
