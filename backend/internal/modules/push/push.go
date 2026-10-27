// Package push sends push notifications (Firebase Cloud Messaging) to the
// phones of given students, in each phone's language.
//
//   - POST /me/devices  {token, platform, language} register this phone
//
// A token belongs to the session that registered it, so signing out (or a
// revoked session) stops pushes to that phone without another call.
//
// Other modules send through Notify (wired in app). Sending never blocks a
// request: it runs in the background after the change is committed, and a
// failure only logs. Tokens Firebase reports as gone are deleted.
package push

import (
	"context"
	"log/slog"
	"sync"
	"time"

	"github.com/google/uuid"

	"github.com/zamansheikh/campussaga/backend/internal/modules/push/store"
	"github.com/zamansheikh/campussaga/backend/internal/platform/auth"
	"github.com/zamansheikh/campussaga/backend/internal/platform/db"
)

// Text is one notification in one language.
type Text struct {
	Title string
	Body  string
}

// Message is what to tell students: a Text per language ("en", "bn"; "en"
// is the fallback) and data the app uses when it's tapped.
type Message struct {
	Texts map[string]Text
	Data  map[string]string
}

// Notification is one push to one phone.
type Notification struct {
	Token    string
	Platform string
	Title    string
	Body     string
	Data     map[string]string
}

// Sender delivers one notification. ErrTokenGone means the token is no
// longer valid (app removed): it is deleted.
type Sender interface {
	Send(ctx context.Context, n Notification) error
}

// Service is the push module.
type Service struct {
	d      *db.DB
	sender Sender
	log    *slog.Logger

	wg  sync.WaitGroup
	sem chan struct{}
}

func NewService(d *db.DB, sender Sender, log *slog.Logger) *Service {
	return &Service{d: d, sender: sender, log: log, sem: make(chan struct{}, 4)}
}

// DeviceInput registers this phone for notifications.
type DeviceInput struct {
	Token    string `json:"token" validate:"required,max=4096"`
	Platform string `json:"platform" validate:"required,oneof=android ios"`
	Language string `json:"language" validate:"omitempty,oneof=en bn"`
}

func (s *Service) Register(ctx context.Context, in *DeviceInput) error {
	c := auth.MustUser(ctx)
	lang := in.Language
	if lang == "" {
		lang = "en"
	}
	return store.New(s.d.Q(ctx)).UpsertDevice(ctx, store.UpsertDeviceParams{
		Token: in.Token, UserID: c.UserID, SessionID: c.SessionID, Platform: in.Platform, Language: lang,
	})
}

// Notify sends m to every phone of userIDs, in the background.
func (s *Service) Notify(userIDs []uuid.UUID, m Message) {
	if len(userIDs) == 0 {
		return
	}
	s.wg.Add(1)
	go func() {
		defer s.wg.Done()
		ctx, cancel := context.WithTimeout(context.Background(), time.Minute)
		defer cancel()
		s.send(ctx, userIDs, m)
	}()
}

// Wait blocks until background sends finish (shutdown, tests).
func (s *Service) Wait() { s.wg.Wait() }

func (s *Service) send(ctx context.Context, userIDs []uuid.UUID, m Message) {
	q := store.New(s.d.Q(ctx))
	devices, err := q.DevicesForUsers(ctx, userIDs)
	if err != nil {
		s.log.Error("push: load devices", "err", err)
		return
	}
	var wg sync.WaitGroup
	for _, d := range devices {
		text, ok := m.Texts[d.Language]
		if !ok {
			text = m.Texts["en"]
		}
		wg.Add(1)
		s.sem <- struct{}{}
		go func() {
			defer func() { <-s.sem; wg.Done() }()
			err := s.sender.Send(ctx, Notification{
				Token: d.Token, Platform: d.Platform, Title: text.Title, Body: text.Body, Data: m.Data,
			})
			switch {
			case err == nil:
			case err == ErrTokenGone:
				if err := q.DeleteToken(ctx, d.Token); err != nil {
					s.log.Error("push: delete gone token", "err", err)
				}
			default:
				s.log.Warn("push: send failed", "err", err)
			}
		}()
	}
	wg.Wait()
}
