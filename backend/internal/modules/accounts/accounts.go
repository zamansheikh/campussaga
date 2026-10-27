// Package accounts is sign-in and the student's own profile:
//
//   - POST /auth/code    send a 6-digit code to a university email
//   - POST /auth/verify  exchange the code for tokens (creates the account
//     on first sign-in, so every account is a verified student)
//   - POST /auth/refresh rotate the refresh token, get a new access token
//   - POST /auth/logout, /auth/logout-all
//   - GET/PATCH/DELETE /me
//
// Security notes:
//   - Codes are stored only as HMAC-SHA256(secret, email:code), expire after
//     CodeTTL and allow MaxAttempts wrong tries.
//   - Refresh tokens are 256-bit random, stored as SHA-256, rotated on every
//     use. Presenting an already-rotated token (theft) revokes the session.
//   - No endpoint takes another user's id: a student can only ever reach
//     their own account.
package accounts

import (
	"context"
	"crypto/hmac"
	"crypto/rand"
	"crypto/sha256"
	"fmt"
	"log/slog"
	"math/big"
	"net/mail"
	"strings"
	"time"
	"unicode/utf8"

	"github.com/google/uuid"

	"github.com/zamansheikh/campussaga/backend/internal/modules/accounts/store"
	"github.com/zamansheikh/campussaga/backend/internal/platform/apperr"
	"github.com/zamansheikh/campussaga/backend/internal/platform/auth"
	"github.com/zamansheikh/campussaga/backend/internal/platform/db"
	"github.com/zamansheikh/campussaga/backend/internal/platform/firebase"
	"github.com/zamansheikh/campussaga/backend/internal/platform/httpx"
	mailer "github.com/zamansheikh/campussaga/backend/internal/platform/mail"
)

// University is what accounts needs to know about a university.
type University struct {
	ID      uuid.UUID `json:"id"`
	Slug    string    `json:"slug"`
	Name    string    `json:"name"`
	NameBn  *string   `json:"nameBn"`
	City    *string   `json:"city,omitempty"`
	Domains []string  `json:"domains,omitempty"`
}

// Universities is the port to the universities module (wired in app).
type Universities struct {
	ForEmail func(ctx context.Context, email string) (*University, error)
	Get      func(ctx context.Context, id uuid.UUID) (*University, error)
}

// GoogleVerifier checks Firebase ID tokens from Google sign-in.
type GoogleVerifier interface {
	Verify(ctx context.Context, idToken string) (*firebase.Identity, error)
}

// Config tunes sign-in.
type Config struct {
	CodeSecret  []byte
	CodeTTL     time.Duration
	ResendAfter time.Duration
	MaxPerHour  int
	MaxAttempts int
	RefreshTTL  time.Duration
	// LogCodes writes codes to the log (development only).
	LogCodes bool
}

// Service is the accounts module.
type Service struct {
	d      *db.DB
	tokens *auth.Tokens
	mail   mailer.Sender
	unis   Universities
	google GoogleVerifier // nil = Google sign-in off
	cfg    Config
	now    func() time.Time
	log    *slog.Logger
}

func NewService(d *db.DB, tokens *auth.Tokens, m mailer.Sender, unis Universities, google GoogleVerifier, cfg Config, now func() time.Time, log *slog.Logger) *Service {
	if now == nil {
		now = time.Now
	}
	return &Service{d: d, tokens: tokens, mail: m, unis: unis, google: google, cfg: cfg, now: now, log: log}
}

// ---- sign-in codes --------------------------------------------------------

// CodeSent answers POST /auth/code.
type CodeSent struct {
	Email              string      `json:"email"`
	University         *University `json:"university"`
	ExpiresInSeconds   int         `json:"expiresInSeconds"`
	ResendAfterSeconds int         `json:"resendAfterSeconds"`
}

// RequestCode sends a new sign-in code to a university email address.
func (s *Service) RequestCode(ctx context.Context, rawEmail string) (*CodeSent, error) {
	email, err := normalizeEmail(rawEmail)
	if err != nil {
		return nil, err
	}
	uni, err := s.unis.ForEmail(ctx, email)
	if err != nil {
		return nil, err
	}
	if uni == nil {
		return nil, ErrUniversityEmailRequired
	}
	if err := s.sendCode(ctx, email, uni); err != nil {
		return nil, err
	}
	return &CodeSent{
		Email: email, University: uni,
		ExpiresInSeconds:   int(s.cfg.CodeTTL.Seconds()),
		ResendAfterSeconds: int(s.cfg.ResendAfter.Seconds()),
	}, nil
}

// sendCode emails a fresh 6-digit code to a university address, with the
// resend and hourly limits. Used by sign-in and by verifying a university
// email later.
func (s *Service) sendCode(ctx context.Context, email string, uni *University) error {
	now := s.now()
	return s.d.InTx(ctx, func(ctx context.Context) error {
		q := store.New(s.d.Q(ctx))
		if err := q.LockEmail(ctx, email); err != nil {
			return err
		}
		sends, windowStart := int32(1), now
		prev, err := q.LockSignInCode(ctx, email)
		switch {
		case err == nil:
			if wait := prev.LastSentAt.Add(s.cfg.ResendAfter).Sub(now); wait > 0 {
				return ErrCodeResendTooSoon.WithDetails(retryAfter(wait))
			}
			if now.Sub(prev.WindowStart) < time.Hour {
				if int(prev.Sends) >= s.cfg.MaxPerHour {
					return ErrCodeLimitReached.WithDetails(retryAfter(prev.WindowStart.Add(time.Hour).Sub(now)))
				}
				sends, windowStart = prev.Sends+1, prev.WindowStart
			}
		case !db.IsNoRows(err):
			return err
		}

		code, err := newCode()
		if err != nil {
			return err
		}
		if err := q.UpsertSignInCode(ctx, store.UpsertSignInCodeParams{
			Email: email, UniversityID: uni.ID, CodeHash: s.codeHash(email, code),
			Sends: sends, WindowStart: windowStart, LastSentAt: now, ExpiresAt: now.Add(s.cfg.CodeTTL),
		}); err != nil {
			return err
		}
		if s.cfg.LogCodes {
			httpx.Logger(ctx).Info("DEV ONLY: sign-in code", "email", email, "code", code)
		}
		msg, err := mailer.LoginCode(email, code, s.cfg.CodeTTL)
		if err != nil {
			return err
		}
		// Sent inside the transaction: if the email fails, the code row is
		// rolled back and the student can retry immediately.
		sendCtx, cancel := context.WithTimeout(ctx, 15*time.Second)
		defer cancel()
		if err := s.mail.Send(sendCtx, msg); err != nil {
			return ErrEmailSendFailed.Wrap(err)
		}
		return nil
	})
}

// SignedIn answers POST /auth/verify.
type SignedIn struct {
	Tokens    Tokens `json:"tokens"`
	User      *Me    `json:"user"`
	IsNewUser bool   `json:"isNewUser"`
}

// Tokens is an access + refresh token pair.
type Tokens struct {
	AccessToken           string    `json:"accessToken"`
	AccessTokenExpiresAt  time.Time `json:"accessTokenExpiresAt"`
	RefreshToken          string    `json:"refreshToken"`
	RefreshTokenExpiresAt time.Time `json:"refreshTokenExpiresAt"`
}

// VerifyCode checks the code and signs the student in.
func (s *Service) VerifyCode(ctx context.Context, rawEmail, code string) (*SignedIn, error) {
	email, err := normalizeEmail(rawEmail)
	if err != nil {
		return nil, err
	}
	now := s.now()
	var (
		out     *SignedIn
		failure error // returned after a commit that must keep the attempt count
	)
	err = s.d.InTx(ctx, func(ctx context.Context) error {
		failure, out = nil, nil
		q := store.New(s.d.Q(ctx))
		if err := q.LockEmail(ctx, email); err != nil {
			return err
		}
		row, bad, err := s.consumeCode(ctx, q, email, code, now)
		if err != nil {
			return err
		}
		if bad != nil {
			failure = bad
			return nil // commit the attempt count
		}

		user, err := q.GetUserByEmail(ctx, email)
		isNew := false
		if db.IsNoRows(err) {
			isNew = true
			user, err = q.InsertUser(ctx, store.InsertUserParams{
				Email: email, UniversityID: &row.UniversityID, UniversityEmail: &email, VerifiedAt: &now,
			})
		}
		if err != nil {
			return err
		}
		tokens, err := s.startSession(ctx, q, user, now)
		if err != nil {
			return err
		}
		me, err := s.meView(ctx, user)
		if err != nil {
			return err
		}
		out = &SignedIn{Tokens: *tokens, User: me, IsNewUser: isNew}
		return nil
	})
	if err != nil {
		return nil, err
	}
	if failure != nil {
		return nil, failure
	}
	return out, nil
}

// consumeCode checks a code for email inside the caller's transaction:
// bad (wrong code; the caller commits the attempt count) or the code row,
// deleted so it can't be used twice.
func (s *Service) consumeCode(ctx context.Context, q *store.Queries, email, code string, now time.Time) (row store.SignInCode, bad error, err error) {
	row, err = q.LockSignInCode(ctx, email)
	if db.IsNoRows(err) {
		return row, nil, ErrCodeExpired
	}
	if err != nil {
		return row, nil, err
	}
	if !now.Before(row.ExpiresAt) {
		return row, nil, ErrCodeExpired
	}
	if int(row.Attempts) >= s.cfg.MaxAttempts {
		return row, nil, ErrCodeTooManyAttempts
	}
	if !hmac.Equal(s.codeHash(email, code), row.CodeHash) {
		attempts, err := q.CountFailedAttempt(ctx, email)
		if err != nil {
			return row, nil, err
		}
		left := s.cfg.MaxAttempts - int(attempts)
		if left <= 0 {
			bad = ErrCodeTooManyAttempts
		} else {
			bad = ErrCodeInvalid.WithDetails(map[string]int{"remainingAttempts": left})
		}
		return row, bad, nil // the caller commits the attempt count
	}
	if err := q.DeleteSignInCode(ctx, email); err != nil {
		return row, nil, err
	}
	return row, nil, nil
}

// ---- Google -----------------------------------------------------------------

// SignInWithGoogle signs a student in with a Firebase ID token from Google
// sign-in. A university Google account (most universities give students a
// Google Workspace address) is a verified student of that university. Any
// other Google account (Gmail; some universities give no email) becomes a
// NOT verified student who picks their university and can verify later
// with a university email.
// The same email always maps to the same account, whichever way they sign in.
// nameHint is the Google account name sent by the app; the token's own name
// wins when it has one. Either fills in a name the account doesn't have yet.
func (s *Service) SignInWithGoogle(ctx context.Context, idToken, nameHint string) (*SignedIn, error) {
	if s.google == nil {
		return nil, ErrGoogleUnavailable
	}
	id, err := s.google.Verify(ctx, idToken)
	if err != nil {
		httpx.Logger(ctx).Info("google sign-in: token rejected", "err", err)
		return nil, ErrGoogleTokenInvalid
	}
	if id.Provider != "google.com" || !id.EmailVerified || id.Email == "" {
		return nil, ErrGoogleTokenInvalid
	}
	email, err := normalizeEmail(id.Email)
	if err != nil {
		return nil, ErrGoogleTokenInvalid
	}
	uni, err := s.unis.ForEmail(ctx, email)
	if err != nil {
		return nil, err
	}
	now := s.now()
	params := store.InsertUserParams{Email: email} // not verified
	if uni != nil {
		params = store.InsertUserParams{Email: email, UniversityID: &uni.ID, UniversityEmail: &email, VerifiedAt: &now}
	}
	var out *SignedIn
	err = s.d.InTx(ctx, func(ctx context.Context) error {
		q := store.New(s.d.Q(ctx))
		if err := q.LockEmail(ctx, email); err != nil {
			return err
		}
		user, err := q.GetUserByEmail(ctx, email)
		isNew := false
		if db.IsNoRows(err) {
			isNew = true
			user, err = q.InsertUser(ctx, params)
		}
		if err != nil {
			return err
		}
		name := strings.TrimSpace(id.Name)
		if name == "" {
			name = strings.TrimSpace(nameHint)
		}
		if name != "" && (user.DisplayName == nil || *user.DisplayName == "") {
			for utf8.RuneCountInString(name) > 60 {
				name = string([]rune(name)[:60])
			}
			if user, err = q.UpdateProfile(ctx, store.UpdateProfileParams{ID: user.ID, DisplayName: apply(nil, &name)}); err != nil {
				return err
			}
		}
		tokens, err := s.startSession(ctx, q, user, now)
		if err != nil {
			return err
		}
		me, err := s.meView(ctx, user)
		if err != nil {
			return err
		}
		out = &SignedIn{Tokens: *tokens, User: me, IsNewUser: isNew}
		return nil
	})
	return out, err
}

// ---- sessions -------------------------------------------------------------

func (s *Service) startSession(ctx context.Context, q *store.Queries, u store.User, now time.Time) (*Tokens, error) {
	refresh := auth.RandomToken(32)
	sess, err := q.InsertSession(ctx, store.InsertSessionParams{
		UserID: u.ID, RefreshHash: auth.HashToken(refresh), UserAgent: userAgent(ctx),
		Now: now, ExpiresAt: now.Add(s.cfg.RefreshTTL),
	})
	if err != nil {
		return nil, err
	}
	return s.issue(u, sess.ID, refresh, sess.ExpiresAt)
}

func (s *Service) issue(u store.User, sessionID uuid.UUID, refresh string, refreshExp time.Time) (*Tokens, error) {
	access, exp, err := s.tokens.Issue(auth.Claims{
		UserID: u.ID, SessionID: sessionID, UniversityID: deref(u.UniversityID), Role: string(u.Role),
	})
	if err != nil {
		return nil, err
	}
	return &Tokens{AccessToken: access, AccessTokenExpiresAt: exp, RefreshToken: refresh, RefreshTokenExpiresAt: refreshExp}, nil
}

// Refresh rotates the refresh token. The app must send one refresh at a
// time: replaying a rotated token is treated as theft and ends the session.
func (s *Service) Refresh(ctx context.Context, refresh string) (*Tokens, error) {
	h := auth.HashToken(refresh)
	now := s.now()
	var (
		out     *Tokens
		failure error
	)
	err := s.d.InTx(ctx, func(ctx context.Context) error {
		failure, out = nil, nil
		q := store.New(s.d.Q(ctx))
		sess, err := q.LockSessionByRefresh(ctx, h)
		if db.IsNoRows(err) {
			prev, perr := q.FindSessionByPrevious(ctx, h)
			if perr == nil && prev.RevokedAt == nil {
				if _, err := q.RevokeSession(ctx, store.RevokeSessionParams{ID: prev.ID, UserID: prev.UserID, Now: now}); err != nil {
					return err
				}
				httpx.Logger(ctx).Warn("refresh token reused; session revoked", "sessionId", prev.ID, "userId", prev.UserID)
			} else if perr != nil && !db.IsNoRows(perr) {
				return perr
			}
			failure = ErrRefreshInvalid
			return nil // commit the revocation
		}
		if err != nil {
			return err
		}
		if sess.RevokedAt != nil || !now.Before(sess.ExpiresAt) {
			return ErrRefreshInvalid
		}
		user, err := q.GetUser(ctx, sess.UserID)
		if db.IsNoRows(err) {
			return ErrRefreshInvalid
		}
		if err != nil {
			return err
		}
		next := auth.RandomToken(32)
		exp := now.Add(s.cfg.RefreshTTL)
		if err := q.RotateSession(ctx, store.RotateSessionParams{ID: sess.ID, NewHash: auth.HashToken(next), Now: now, ExpiresAt: exp}); err != nil {
			return err
		}
		out, err = s.issue(user, sess.ID, next, exp)
		return err
	})
	if err != nil {
		return nil, err
	}
	if failure != nil {
		return nil, failure
	}
	return out, nil
}

// CheckSession runs on every signed-in request, so signing out, signing out
// everywhere and deleting the account take effect immediately instead of
// when the access token expires.
func (s *Service) CheckSession(ctx context.Context, c *auth.Claims) error {
	u, err := store.New(s.d.Q(ctx)).SessionUser(ctx, store.SessionUserParams{ID: c.SessionID, UserID: c.UserID, Now: s.now()})
	if db.IsNoRows(err) {
		return ErrSessionEnded
	}
	if err != nil {
		return err
	}
	// Fresh from the database, not the token: picking a university or
	// verifying applies to the very next request.
	c.UniversityID, c.Verified = deref(u.UniversityID), u.Verified
	return nil
}

func deref(id *uuid.UUID) uuid.UUID {
	if id == nil {
		return uuid.Nil
	}
	return *id
}

// Logout ends the current session.
func (s *Service) Logout(ctx context.Context) error {
	c := auth.MustUser(ctx)
	_, err := store.New(s.d.Q(ctx)).RevokeSession(ctx, store.RevokeSessionParams{ID: c.SessionID, UserID: c.UserID, Now: s.now()})
	return err
}

// LogoutAll ends every session of the user (all devices).
func (s *Service) LogoutAll(ctx context.Context) error {
	c := auth.MustUser(ctx)
	_, err := store.New(s.d.Q(ctx)).RevokeUserSessions(ctx, store.RevokeUserSessionsParams{UserID: c.UserID, Now: s.now()})
	return err
}

// Purge deletes finished codes and dead sessions.
func (s *Service) Purge(ctx context.Context) error {
	now := s.now()
	q := store.New(s.d.Q(ctx))
	if _, err := q.PurgeSignInCodes(ctx, now.Add(-time.Hour)); err != nil {
		return err
	}
	_, err := q.PurgeSessions(ctx, now.Add(-7*24*time.Hour))
	return err
}

// PurgeLoop runs Purge every interval until ctx ends.
func (s *Service) PurgeLoop(ctx context.Context, every time.Duration) {
	t := time.NewTicker(every)
	defer t.Stop()
	for {
		select {
		case <-ctx.Done():
			return
		case <-t.C:
			if err := s.Purge(ctx); err != nil {
				s.log.Error("accounts: purge", "err", err)
			}
		}
	}
}

// ---- helpers ----------------------------------------------------------------

func (s *Service) codeHash(email, code string) []byte {
	m := hmac.New(sha256.New, s.cfg.CodeSecret)
	m.Write([]byte(email + ":" + code))
	return m.Sum(nil)
}

func newCode() (string, error) {
	n, err := rand.Int(rand.Reader, big.NewInt(1_000_000))
	if err != nil {
		return "", err
	}
	return fmt.Sprintf("%06d", n.Int64()), nil
}

var errBadEmail = apperr.Validation(map[string]string{"email": "must be a valid email address"})

// normalizeEmail lower-cases and checks a bare address ("a@b.c", no name).
func normalizeEmail(raw string) (string, error) {
	e := strings.ToLower(strings.TrimSpace(raw))
	if len(e) > 254 {
		return "", errBadEmail
	}
	a, err := mail.ParseAddress(e)
	if err != nil || a.Address != e || a.Name != "" {
		return "", errBadEmail
	}
	return e, nil
}

func userAgent(ctx context.Context) *string {
	ua := httpx.ClientInfo(ctx).UserAgent
	if ua == "" {
		return nil
	}
	for utf8.RuneCountInString(ua) > 300 {
		ua = string([]rune(ua)[:300])
	}
	return &ua
}

func retryAfter(d time.Duration) httpx.RetryAfter {
	secs := int((d + time.Second - 1) / time.Second)
	if secs < 1 {
		secs = 1
	}
	return httpx.RetryAfter{RetryAfterSeconds: secs}
}
