package app

import (
	"bytes"
	"context"
	"encoding/json"
	"io"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"regexp"
	"sync"
	"testing"
	"time"

	"github.com/stretchr/testify/require"

	"github.com/zamansheikh/campussaga/backend/internal/modules/push"
	"github.com/zamansheikh/campussaga/backend/internal/platform/config"
	"github.com/zamansheikh/campussaga/backend/internal/platform/firebase"
	"github.com/zamansheikh/campussaga/backend/internal/platform/firebase/firebasetest"
	"github.com/zamansheikh/campussaga/backend/internal/platform/mail"
	"github.com/zamansheikh/campussaga/backend/internal/platform/media"
	"github.com/zamansheikh/campussaga/backend/internal/testkit"
)

// harness runs the real HTTP API on a fresh database with a fake clock and
// an in-memory mailbox.
type harness struct {
	t      *testing.T
	srv    *httptest.Server
	mail   *mail.Memory
	app    *App
	google *firebasetest.Signer
	push   *push.MemorySender
	media  *media.Disk

	mu  sync.Mutex
	now time.Time
}

func newHarness(t *testing.T) *harness {
	t.Helper()
	d := testkit.NewDB(t)
	h := &harness{t: t, mail: &mail.Memory{}, google: firebasetest.New("campus-test"), push: &push.MemorySender{}, now: time.Date(2026, 10, 27, 9, 0, 0, 0, time.UTC)}
	cfg := &config.Config{
		Env: "development", APIPrefix: "/api/v1",
		JWTSecret:  []byte("test-jwt-secret-test-jwt-secret-xx"),
		CodeSecret: []byte("test-code-secret-test-code-secret"),
		AccessTTL:  15 * time.Minute, RefreshTTL: 60 * 24 * time.Hour,
		CodeTTL: 10 * time.Minute, CodeResendAfter: 60 * time.Second,
		CodeMaxPerHour: 5, CodeMaxAttempts: 5, ShutdownTimeout: time.Second,
		VoiceHMACSecret: []byte("test-voice-secret-test-voice-secret"),
	}
	h.media, _ = media.NewDisk(t.TempDir())
	log := slog.New(slog.NewTextHandler(io.Discard, nil))
	h.app = New(cfg, log, d, Options{Now: h.Now, Mailer: h.mail, Google: firebase.NewVerifier("campus-test", h.google.Keys(), h.Now), Push: h.push, Media: h.media})
	h.srv = httptest.NewServer(h.app.Handler())
	t.Cleanup(h.srv.Close)

	_, err := d.Pool.Exec(context.Background(), `
		WITH u AS (INSERT INTO universities (slug, name, name_bn) VALUES ('test-uni', 'Test University', 'টেস্ট বিশ্ববিদ্যালয়') RETURNING id)
		INSERT INTO university_domains (domain, university_id) SELECT 'test.ac.bd', id FROM u`)
	require.NoError(t, err)
	return h
}

func (h *harness) Now() time.Time {
	h.mu.Lock()
	defer h.mu.Unlock()
	return h.now
}

func (h *harness) advance(d time.Duration) {
	h.mu.Lock()
	defer h.mu.Unlock()
	h.now = h.now.Add(d)
}

type apiError struct {
	Code    string          `json:"code"`
	Message string          `json:"message"`
	Details json.RawMessage `json:"details"`
}

type response struct {
	Status  int
	Header  http.Header
	Success bool            `json:"success"`
	Data    json.RawMessage `json:"data"`
	Error   *apiError       `json:"error"`
	Raw     string
}

func (r *response) code() string {
	if r.Error == nil {
		return ""
	}
	return r.Error.Code
}

func (r *response) into(t *testing.T, v any) {
	t.Helper()
	require.NoError(t, json.Unmarshal(r.Data, v), r.Raw)
}

// do calls the API. body may be nil, a string (sent as-is) or a value (JSON).
func (h *harness) do(method, path, token string, body any) *response {
	h.t.Helper()
	var rd io.Reader
	switch b := body.(type) {
	case nil:
	case string:
		rd = bytes.NewBufferString(b)
	default:
		buf, err := json.Marshal(b)
		require.NoError(h.t, err)
		rd = bytes.NewReader(buf)
	}
	req, err := http.NewRequest(method, h.srv.URL+"/api/v1"+path, rd)
	require.NoError(h.t, err)
	if rd != nil {
		req.Header.Set("Content-Type", "application/json")
	}
	if token != "" {
		req.Header.Set("Authorization", "Bearer "+token)
	}
	res, err := http.DefaultClient.Do(req)
	require.NoError(h.t, err)
	defer res.Body.Close()
	raw, err := io.ReadAll(res.Body)
	require.NoError(h.t, err)
	out := &response{Status: res.StatusCode, Header: res.Header, Raw: string(raw)}
	if len(raw) > 0 {
		require.NoError(h.t, json.Unmarshal(raw, out), string(raw))
	}
	return out
}

var codeRe = regexp.MustCompile(`\b(\d{6})\b`)

// lastCode returns the code in the last email sent to addr.
func (h *harness) lastCode(addr string) string {
	h.t.Helper()
	m, ok := h.mail.Last(addr)
	require.True(h.t, ok, "no email sent to %s", addr)
	match := codeRe.FindStringSubmatch(m.Text)
	require.NotNil(h.t, match, "no code in email: %s", m.Text)
	return match[1]
}

type tokens struct {
	AccessToken  string `json:"accessToken"`
	RefreshToken string `json:"refreshToken"`
}

type signedIn struct {
	Tokens    tokens `json:"tokens"`
	IsNewUser bool   `json:"isNewUser"`
	User      me     `json:"user"`
}

type me struct {
	ID          string  `json:"id"`
	Email       string  `json:"email"`
	DisplayName *string `json:"displayName"`
	Department  *string `json:"department"`
	Role        string  `json:"role"`
	University  struct {
		Slug string `json:"slug"`
		Name string `json:"name"`
	} `json:"university"`
}

// signIn runs the whole code flow and returns the session.
func (h *harness) signIn(email string) signedIn {
	h.t.Helper()
	r := h.do("POST", "/auth/code", "", map[string]string{"email": email})
	require.Equal(h.t, http.StatusAccepted, r.Status, r.Raw)
	r = h.do("POST", "/auth/verify", "", map[string]string{"email": email, "code": h.lastCode(email)})
	require.Equal(h.t, http.StatusOK, r.Status, r.Raw)
	var s signedIn
	r.into(h.t, &s)
	h.advance(61 * time.Second) // so the next code request is not "too soon"
	return s
}
