// Package voice is Campus Voice (docs/CAMPUS_VOICE.md): campus issues,
// anonymous by default, with me too, comments, official replies, reports
// and moderation.
//
// Anonymity rule: the *_authors tables answer questions about the caller
// only ("is this mine?"), resolve push recipients and ban an author. No
// response, log line or audit row ever carries who wrote anonymous content.
package voice

import (
	"context"
	"crypto/hmac"
	"crypto/sha256"
	"encoding/base64"
	"encoding/json"
	"log/slog"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/google/uuid"

	"github.com/zamansheikh/campussaga/backend/internal/modules/voice/store"
	"github.com/zamansheikh/campussaga/backend/internal/platform/auth"
	"github.com/zamansheikh/campussaga/backend/internal/platform/db"
	"github.com/zamansheikh/campussaga/backend/internal/platform/media"
)

const (
	RoleAuthority = "authority"
	RoleModerator = "moderator"
	RoleAdmin     = "admin"
)

// NoticeText is a push in one language.
type NoticeText struct{ Title, Body string }

// Notice is a push; Texts are keyed by language ("en", "bn").
type Notice struct {
	Texts map[string]NoticeText
	Data  map[string]string
}

// Notifier sends a Notice to users' phones (wired to the push module).
type Notifier func(userIDs []uuid.UUID, n Notice)

type Service struct {
	d      *db.DB
	media  media.Store
	secret []byte
	now    func() time.Time
	log    *slog.Logger
	notify Notifier

	mu          sync.Mutex
	lastComment map[uuid.UUID]time.Time // issue → last "new comment" push
}

func NewService(d *db.DB, store media.Store, handleSecret []byte, now func() time.Time, log *slog.Logger) *Service {
	return &Service{d: d, media: store, secret: handleSecret, now: now, log: log, lastComment: map[uuid.UUID]time.Time{}}
}

// SetNotifier turns pushes on.
func (s *Service) SetNotifier(n Notifier) { s.notify = n }

// ---- the caller -----------------------------------------------------------------

type viewer struct {
	id       uuid.UUID
	uni      uuid.UUID // uuid.Nil: no university yet
	role     string
	verified bool
	// Staff scope/title (authority and moderator only).
	staffUni   *uuid.UUID
	staffTitle string
}

func (v viewer) isMod() bool { return v.role == RoleModerator || v.role == RoleAdmin }

func (v viewer) isStaff() bool { return v.isMod() || v.role == RoleAuthority }

// authorityOf: an authority of that university.
func (v viewer) authorityOf(uni uuid.UUID) bool {
	return v.role == RoleAuthority && v.staffUni != nil && *v.staffUni == uni
}

// modOf: a moderator or admin whose scope includes that university.
func (v viewer) modOf(uni uuid.UUID) bool {
	if v.role == RoleAdmin {
		return true
	}
	return v.role == RoleModerator && (v.staffUni == nil || *v.staffUni == uni)
}

// begin loads the caller and checks the feature flag (staff always pass).
func (s *Service) begin(ctx context.Context, q *store.Queries) (viewer, error) {
	c := auth.MustUser(ctx)
	v := viewer{id: c.UserID, uni: c.UniversityID, role: c.Role, verified: c.Verified}
	if v.role == RoleAuthority || v.role == RoleModerator {
		st, err := q.Staff(ctx, c.UserID)
		if err != nil && !db.IsNoRows(err) {
			return v, err
		}
		if err == nil {
			v.staffUni, v.staffTitle = st.UniversityID, st.Title
		}
	}
	if !v.isStaff() {
		on, err := q.CampusVoiceOn(ctx)
		if err != nil && !db.IsNoRows(err) {
			return v, err
		}
		if !on {
			return v, ErrFeatureDisabled
		}
	}
	return v, nil
}

// requireNoBan refuses writes from a banned caller.
func (s *Service) requireNoBan(ctx context.Context, q *store.Queries, v viewer) error {
	until, err := q.ActiveBan(ctx, store.ActiveBanParams{UserID: v.id, Now: s.now()})
	if db.IsNoRows(err) {
		return nil
	}
	if err != nil {
		return err
	}
	return ErrBanned.WithDetails(map[string]*time.Time{"until": until})
}

// canSee: may the viewer read this issue at all?
func canSee(v viewer, r store.GetIssueRow) bool {
	if v.isMod() {
		return v.modOf(r.UniversityID)
	}
	if r.UniversityID != v.uni {
		return false
	}
	if r.Mine {
		return true
	}
	if r.Visibility != "visible" {
		return false
	}
	if r.Private {
		return v.authorityOf(r.UniversityID)
	}
	return true
}

// getIssue loads an issue the viewer may see (ISSUE_NOT_FOUND otherwise,
// never 403: existence isn't revealed).
func (s *Service) getIssue(ctx context.Context, q *store.Queries, v viewer, id uuid.UUID) (store.GetIssueRow, error) {
	r, err := q.GetIssue(ctx, store.GetIssueParams{ID: id, Viewer: v.id})
	if db.IsNoRows(err) {
		return r, ErrIssueNotFound
	}
	if err != nil {
		return r, err
	}
	if !canSee(v, r) {
		return r, ErrIssueNotFound
	}
	return r, nil
}

// ---- handles, times, cursors ------------------------------------------------------

// handleAlphabet: base32 without I, O, 0, 1.
const handleAlphabet = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"

// handle is a person's anonymous name on one issue: the same person gets
// the same handle on an issue, unrelated ones on different issues.
func handle(secret []byte, issueID, userID uuid.UUID) string {
	m := hmac.New(sha256.New, secret)
	m.Write(issueID[:])
	m.Write(userID[:])
	sum := m.Sum(nil)
	var b strings.Builder
	bits, n := uint32(0), 0
	for _, by := range sum {
		bits = bits<<8 | uint32(by)
		n += 8
		for n >= 5 && b.Len() < 4 {
			b.WriteByte(handleAlphabet[(bits>>(n-5))&31])
			n -= 5
		}
		if b.Len() == 4 {
			break
		}
	}
	return b.String()
}

// roughTime: anonymous content shows its time rounded down to 5 minutes.
func roughTime(t time.Time) time.Time { return t.UTC().Truncate(5 * time.Minute) }

// Cursors are opaque to clients: "k|<unixnano>|<uuid>" (keyset) or "o|<offset>".
func keyCursor(t time.Time, id uuid.UUID) string {
	return base64.RawURLEncoding.EncodeToString([]byte("k|" + strconv.FormatInt(t.UnixNano(), 10) + "|" + id.String()))
}

func offsetCursor(off int) string {
	return base64.RawURLEncoding.EncodeToString([]byte("o|" + strconv.Itoa(off)))
}

func parseKeyCursor(c string) (*time.Time, *uuid.UUID, error) {
	if c == "" {
		return nil, nil, nil
	}
	raw, err := base64.RawURLEncoding.DecodeString(c)
	parts := strings.Split(string(raw), "|")
	if err != nil || len(parts) != 3 || parts[0] != "k" {
		return nil, nil, ErrBadCursor
	}
	n, err := strconv.ParseInt(parts[1], 10, 64)
	if err != nil {
		return nil, nil, ErrBadCursor
	}
	id, err := uuid.Parse(parts[2])
	if err != nil {
		return nil, nil, ErrBadCursor
	}
	t := time.Unix(0, n).UTC()
	return &t, &id, nil
}

func parseOffsetCursor(c string) (int, error) {
	if c == "" {
		return 0, nil
	}
	raw, err := base64.RawURLEncoding.DecodeString(c)
	parts := strings.Split(string(raw), "|")
	if err != nil || len(parts) != 2 || parts[0] != "o" {
		return 0, ErrBadCursor
	}
	n, err := strconv.Atoi(parts[1])
	if err != nil || n < 0 {
		return 0, ErrBadCursor
	}
	return n, nil
}

// Page is a page of a list.
type Page[T any] struct {
	Items      []T     `json:"items"`
	NextCursor *string `json:"nextCursor"`
}

func like(q string) string {
	return "%" + strings.NewReplacer(`\`, `\\`, `%`, `\%`, `_`, `\_`).Replace(q) + "%"
}

func mustJSON(v any) json.RawMessage {
	b, err := json.Marshal(v)
	if err != nil {
		return json.RawMessage("{}")
	}
	return b
}
