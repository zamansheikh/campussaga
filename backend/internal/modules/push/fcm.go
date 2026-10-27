package push

import (
	"bytes"
	"context"
	"crypto/rsa"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"log/slog"
	"net/http"
	"net/url"
	"os"
	"strings"
	"sync"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

// ErrTokenGone: Firebase says the app was removed from that phone.
var ErrTokenGone = errors.New("push: token no longer registered")

// FCM sends through the Firebase Cloud Messaging HTTP v1 API, signed in
// with a service account (OAuth2 JWT bearer grant; no SDK needed).
type FCM struct {
	projectID   string
	clientEmail string
	tokenURI    string
	key         *rsa.PrivateKey
	sendURL     string
	http        *http.Client
	now         func() time.Time

	mu      sync.Mutex
	access  string
	expires time.Time
}

// NewFCMFromFile reads a Firebase service-account key (JSON).
func NewFCMFromFile(path string, now func() time.Time) (*FCM, error) {
	raw, err := os.ReadFile(path)
	if err != nil {
		return nil, fmt.Errorf("push: read service account: %w", err)
	}
	var sa struct {
		ProjectID   string `json:"project_id"`
		ClientEmail string `json:"client_email"`
		PrivateKey  string `json:"private_key"`
		TokenURI    string `json:"token_uri"`
	}
	if err := json.Unmarshal(raw, &sa); err != nil {
		return nil, fmt.Errorf("push: parse service account: %w", err)
	}
	key, err := jwt.ParseRSAPrivateKeyFromPEM([]byte(sa.PrivateKey))
	if err != nil {
		return nil, fmt.Errorf("push: service account key: %w", err)
	}
	if sa.TokenURI == "" {
		sa.TokenURI = "https://oauth2.googleapis.com/token"
	}
	return &FCM{
		projectID: sa.ProjectID, clientEmail: sa.ClientEmail, tokenURI: sa.TokenURI, key: key,
		sendURL: "https://fcm.googleapis.com/v1/projects/" + sa.ProjectID + "/messages:send",
		http:    &http.Client{Timeout: 15 * time.Second}, now: now,
	}, nil
}

func (f *FCM) token(ctx context.Context) (string, error) {
	f.mu.Lock()
	defer f.mu.Unlock()
	if f.access != "" && f.now().Before(f.expires.Add(-5*time.Minute)) {
		return f.access, nil
	}
	now := f.now()
	assertion, err := jwt.NewWithClaims(jwt.SigningMethodRS256, jwt.MapClaims{
		"iss": f.clientEmail, "aud": f.tokenURI,
		"scope": "https://www.googleapis.com/auth/firebase.messaging",
		"iat":   now.Unix(), "exp": now.Add(time.Hour).Unix(),
	}).SignedString(f.key)
	if err != nil {
		return "", err
	}
	form := url.Values{
		"grant_type": {"urn:ietf:params:oauth:grant-type:jwt-bearer"},
		"assertion":  {assertion},
	}
	req, _ := http.NewRequestWithContext(ctx, http.MethodPost, f.tokenURI, strings.NewReader(form.Encode()))
	req.Header.Set("Content-Type", "application/x-www-form-urlencoded")
	res, err := f.http.Do(req)
	if err != nil {
		return "", err
	}
	defer res.Body.Close()
	var out struct {
		AccessToken string `json:"access_token"`
		ExpiresIn   int    `json:"expires_in"`
	}
	if res.StatusCode != http.StatusOK {
		b, _ := io.ReadAll(io.LimitReader(res.Body, 2048))
		return "", fmt.Errorf("push: oauth %d: %s", res.StatusCode, b)
	}
	if err := json.NewDecoder(res.Body).Decode(&out); err != nil {
		return "", err
	}
	f.access, f.expires = out.AccessToken, now.Add(time.Duration(out.ExpiresIn)*time.Second)
	return f.access, nil
}

func (f *FCM) Send(ctx context.Context, n Notification) error {
	access, err := f.token(ctx)
	if err != nil {
		return err
	}
	body, _ := json.Marshal(map[string]any{"message": fcmMessage(n)})
	req, _ := http.NewRequestWithContext(ctx, http.MethodPost, f.sendURL, bytes.NewReader(body))
	req.Header.Set("Authorization", "Bearer "+access)
	req.Header.Set("Content-Type", "application/json")
	res, err := f.http.Do(req)
	if err != nil {
		return err
	}
	defer res.Body.Close()
	if res.StatusCode == http.StatusOK {
		return nil
	}
	b, _ := io.ReadAll(io.LimitReader(res.Body, 4096))
	if res.StatusCode == http.StatusNotFound || bytes.Contains(b, []byte("UNREGISTERED")) {
		return ErrTokenGone
	}
	return fmt.Errorf("push: fcm %d: %s", res.StatusCode, b)
}

// fcmMessage: shown by the phone itself when the app is closed; the app
// uses data (type, groupId) to refresh and open the group.
func fcmMessage(n Notification) map[string]any {
	return map[string]any{
		"token":        n.Token,
		"notification": map[string]string{"title": n.Title, "body": n.Body},
		"data":         n.Data,
		"android": map[string]any{
			"priority": "HIGH",
			"notification": map[string]string{
				"channel_id": "class_updates", "icon": "ic_notification", "color": "#0F766E",
			},
		},
		"apns": map[string]any{
			"payload": map[string]any{"aps": map[string]any{"sound": "default"}},
		},
	}
}

// LogSender only logs (development, or before the key is configured).
type LogSender struct{ Log *slog.Logger }

func (l LogSender) Send(_ context.Context, n Notification) error {
	l.Log.Info("push (not sent: FCM_CREDENTIALS_FILE not set)",
		"platform", n.Platform, "title", n.Title, "body", n.Body, "data", n.Data)
	return nil
}

// MemorySender records notifications (tests). Tokens in Gone fail with
// ErrTokenGone.
type MemorySender struct {
	mu   sync.Mutex
	Sent []Notification
	Gone map[string]bool
}

func (m *MemorySender) Send(_ context.Context, n Notification) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	if m.Gone[n.Token] {
		return ErrTokenGone
	}
	m.Sent = append(m.Sent, n)
	return nil
}

// Take returns and clears what was sent.
func (m *MemorySender) Take() []Notification {
	m.mu.Lock()
	defer m.mu.Unlock()
	out := m.Sent
	m.Sent = nil
	return out
}
