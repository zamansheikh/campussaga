package classgroups

import (
	"context"
	"strings"
	"time"

	"github.com/google/uuid"

	"github.com/zamansheikh/campussaga/backend/internal/modules/classgroups/store"
	"github.com/zamansheikh/campussaga/backend/internal/platform/apperr"
	"github.com/zamansheikh/campussaga/backend/internal/platform/auth"
	"github.com/zamansheikh/campussaga/backend/internal/platform/db"
)

const (
	// Announcements older than this are no longer sent (unless pinned).
	AnnouncementDays = 30
	// Most recent announcements sent per group.
	MaxAnnouncementsShown = 20
)

// Announcement is a message from the CR to the group.
type Announcement struct {
	ID        uuid.UUID `json:"id"`
	Body      string    `json:"body"`
	Pinned    bool      `json:"pinned"`
	CreatedAt time.Time `json:"createdAt"`
}

// AnnouncementInput posts a message (CR).
type AnnouncementInput struct {
	Body   string `json:"body" validate:"required,max=1000"`
	Pinned bool   `json:"pinned"`
}

// Post adds an announcement; pinning it unpins the previous one.
func (s *Service) Post(ctx context.Context, groupID uuid.UUID, in *AnnouncementInput) (*Announcement, error) {
	c := auth.MustUser(ctx)
	body := cleanBody(in.Body)
	if body == "" {
		return nil, apperr.Validation(map[string]string{"body": "is required"})
	}
	var out *Announcement
	err := s.d.InTx(ctx, func(ctx context.Context) error {
		q := store.New(s.d.Q(ctx))
		if err := s.requireCR(ctx, q, groupID, c.UserID); err != nil {
			return err
		}
		if in.Pinned {
			if err := q.UnpinAnnouncements(ctx, groupID); err != nil {
				return err
			}
		}
		a, err := q.CreateAnnouncement(ctx, store.CreateAnnouncementParams{
			GroupID: groupID, Body: body, Pinned: in.Pinned, CreatedBy: &c.UserID,
		})
		if err != nil {
			return err
		}
		v := announcementView(a)
		out = &v
		return q.TouchGroup(ctx, groupID)
	})
	return out, err
}

// SetPinned pins (unpinning any other) or unpins an announcement (CR).
func (s *Service) SetPinned(ctx context.Context, groupID, id uuid.UUID, pinned bool) (*Announcement, error) {
	c := auth.MustUser(ctx)
	var out *Announcement
	err := s.d.InTx(ctx, func(ctx context.Context) error {
		q := store.New(s.d.Q(ctx))
		if err := s.requireCR(ctx, q, groupID, c.UserID); err != nil {
			return err
		}
		if pinned {
			if err := q.UnpinAnnouncements(ctx, groupID); err != nil {
				return err
			}
		}
		a, err := q.SetAnnouncementPinned(ctx, store.SetAnnouncementPinnedParams{ID: id, GroupID: groupID, Pinned: pinned})
		if db.IsNoRows(err) {
			return ErrAnnouncementNotFound
		}
		if err != nil {
			return err
		}
		v := announcementView(a)
		out = &v
		return q.TouchGroup(ctx, groupID)
	})
	return out, err
}

// DeleteAnnouncement removes a message for everyone (CR).
func (s *Service) DeleteAnnouncement(ctx context.Context, groupID, id uuid.UUID) error {
	c := auth.MustUser(ctx)
	return s.d.InTx(ctx, func(ctx context.Context) error {
		q := store.New(s.d.Q(ctx))
		if err := s.requireCR(ctx, q, groupID, c.UserID); err != nil {
			return err
		}
		n, err := q.DeleteAnnouncement(ctx, store.DeleteAnnouncementParams{ID: id, GroupID: groupID})
		if err != nil {
			return err
		}
		if n == 0 {
			return ErrAnnouncementNotFound
		}
		return q.TouchGroup(ctx, groupID)
	})
}

// announcementsByGroup: the pinned one first, then newest, at most
// MaxAnnouncementsShown (+ the pinned one) per group.
func (s *Service) announcementsByGroup(ctx context.Context, q *store.Queries, userID uuid.UUID) (map[uuid.UUID][]Announcement, error) {
	rows, err := q.ListAnnouncementsForUser(ctx, store.ListAnnouncementsForUserParams{
		UserID: userID, Since: s.now().AddDate(0, 0, -AnnouncementDays),
	})
	if err != nil {
		return nil, err
	}
	out := map[uuid.UUID][]Announcement{}
	recent := map[uuid.UUID]int{}
	for _, a := range rows {
		if !a.Pinned {
			if recent[a.GroupID] >= MaxAnnouncementsShown {
				continue
			}
			recent[a.GroupID]++
		}
		out[a.GroupID] = append(out[a.GroupID], announcementView(a))
	}
	return out, nil
}

func announcementView(a store.Announcement) Announcement {
	return Announcement{ID: a.ID, Body: a.Body, Pinned: a.Pinned, CreatedAt: a.CreatedAt}
}

// cleanBody trims each line and drops runs of blank lines, keeping the
// CR's line breaks.
func cleanBody(s string) string {
	lines := strings.Split(strings.ReplaceAll(s, "\r\n", "\n"), "\n")
	out := make([]string, 0, len(lines))
	blank := false
	for _, l := range lines {
		l = strings.TrimSpace(l)
		if l == "" {
			if blank || len(out) == 0 {
				continue
			}
			blank = true
		} else {
			blank = false
		}
		out = append(out, l)
	}
	return strings.TrimSpace(strings.Join(out, "\n"))
}
