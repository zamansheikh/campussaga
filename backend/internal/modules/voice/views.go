package voice

import (
	"time"
	"unicode/utf8"

	"github.com/google/uuid"

	"github.com/zamansheikh/campussaga/backend/internal/modules/voice/store"
)

// Author is shown only for named posts and official replies: a display
// name, never an id or email. Name null = the account was deleted.
type Author struct {
	Name     *string `json:"name"`
	Verified bool    `json:"verified"`
}

type IssueCard struct {
	ID              uuid.UUID `json:"id"`
	Category        string    `json:"category"`
	Private         bool      `json:"private"`
	Title           string    `json:"title"`
	Preview         string    `json:"preview"`
	Status          string    `json:"status"`
	Visibility      string    `json:"visibility"`
	MeTooCount      int       `json:"meTooCount"`
	CommentCount    int       `json:"commentCount"`
	ImageCount      int       `json:"imageCount"`
	Thumbnail       *string   `json:"thumbnail"`
	Voted           bool      `json:"voted"`
	Following       bool      `json:"following"`
	Mine            bool      `json:"mine"`
	Author          *Author   `json:"author"`
	LocationLabel   string    `json:"locationLabel"`
	CreatedAt       time.Time `json:"createdAt"`
	StatusChangedAt time.Time `json:"statusChangedAt"`
}

type Image struct {
	ID     uuid.UUID `json:"id"`
	Width  int       `json:"width"`
	Height int       `json:"height"`
}

type TimelineEntry struct {
	From       string    `json:"from"`
	To         string    `json:"to"`
	ActorKind  string    `json:"actorKind"`
	ActorTitle string    `json:"actorTitle"`
	Note       string    `json:"note"`
	CreatedAt  time.Time `json:"createdAt"`
}

type Can struct {
	Edit          bool `json:"edit"`
	Delete        bool `json:"delete"`
	Reopen        bool `json:"reopen"`
	ChangeStatus  bool `json:"changeStatus"`
	OfficialReply bool `json:"officialReply"`
	Moderate      bool `json:"moderate"`
}

type Issue struct {
	IssueCard
	Body          string          `json:"body"`
	Images        []Image         `json:"images"`
	Timeline      []TimelineEntry `json:"timeline"`
	HoldReason    string          `json:"holdReason"`
	RemovedReason string          `json:"removedReason"`
	ReportCount   int             `json:"reportCount"`
	Can           Can             `json:"can"`
}

type Comment struct {
	ID            uuid.UUID `json:"id"`
	Kind          string    `json:"kind"`
	Handle        string    `json:"handle"`
	IsIssueAuthor bool      `json:"isIssueAuthor"`
	Mine          bool      `json:"mine"`
	Author        *Author   `json:"author"`
	OfficialTitle string    `json:"officialTitle"`
	Body          string    `json:"body"`
	Visibility    string    `json:"visibility"`
	RemovedReason string    `json:"removedReason"`
	CreatedAt     time.Time `json:"createdAt"`
}

const (
	EditWindow   = 60 * time.Minute
	ReopenWindow = 30 * 24 * time.Hour
)

func namedAuthor(named, exists bool, name string, verified bool) *Author {
	if !named {
		return nil
	}
	if !exists {
		return &Author{} // deleted account
	}
	return &Author{Name: &name, Verified: verified}
}

func preview(body string) string {
	if utf8.RuneCountInString(body) <= 160 {
		return body
	}
	return string([]rune(body)[:159]) + "…"
}

// cardView: the card as this viewer may see it.
func cardView(v viewer, r store.GetIssueRow) IssueCard {
	c := IssueCard{
		ID: r.ID, Category: r.Category, Private: r.Private, Title: r.Title, Preview: preview(r.Body),
		Status: r.Status, Visibility: "visible", MeTooCount: int(r.MeTooCount), CommentCount: int(r.CommentCount),
		ImageCount: int(r.ImageCount), Voted: r.Voted, Following: r.Following, Mine: r.Mine,
		Author:        namedAuthor(r.Named, r.AuthorExists, r.AuthorName, r.AuthorVerified),
		LocationLabel: r.LocationLabel, CreatedAt: r.CreatedAt.UTC(), StatusChangedAt: r.StatusChangedAt.UTC(),
	}
	if !r.Named {
		c.CreatedAt = roughTime(r.CreatedAt)
	}
	if r.Thumbnail != "" {
		t := r.Thumbnail
		c.Thumbnail = &t
	}
	if r.Mine || v.isMod() {
		c.Visibility = r.Visibility
	}
	return c
}

// issueView: the full issue; images and timeline are loaded by the caller.
func (s *Service) issueView(v viewer, r store.GetIssueRow, images []Image, timeline []TimelineEntry) Issue {
	now := s.now()
	out := Issue{IssueCard: cardView(v, r), Body: r.Body, Images: images, Timeline: timeline}
	if out.Images == nil {
		out.Images = []Image{}
	}
	if out.Timeline == nil {
		out.Timeline = []TimelineEntry{}
	}
	if r.Mine || v.isMod() {
		out.HoldReason, out.RemovedReason = r.HoldReason, r.RemovedReason
	}
	if v.isMod() {
		out.ReportCount = int(r.ReportCount)
	}
	removed := r.Visibility == "removed"
	out.Can = Can{
		Edit:   r.Mine && !removed && now.Sub(r.CreatedAt) < EditWindow,
		Delete: r.Mine && !removed,
		Reopen: r.Mine && r.Status == "solved" && r.SolvedAt != nil && now.Sub(*r.SolvedAt) < ReopenWindow,
		ChangeStatus: v.authorityOf(r.UniversityID) && r.Visibility == "visible" &&
			(r.Status == "open" || r.Status == "acknowledged" || r.Status == "in_progress"),
		OfficialReply: v.authorityOf(r.UniversityID) && r.Visibility == "visible",
		Moderate:      v.modOf(r.UniversityID) && v.isMod(),
	}
	return out
}

func commentView(v viewer, c store.GetCommentRow) Comment {
	out := Comment{
		ID: c.ID, Kind: c.Kind, Handle: c.Handle, IsIssueAuthor: c.IsIssueAuthor, Mine: c.Mine,
		OfficialTitle: c.OfficialTitle, Body: c.Body, Visibility: "visible", CreatedAt: c.CreatedAt.UTC(),
	}
	if c.Kind == "official" || c.Named {
		out.Author = namedAuthor(true, c.AuthorExists, c.AuthorName, c.Kind == "official" || c.AuthorVerified)
	} else {
		out.CreatedAt = roughTime(c.CreatedAt)
	}
	if c.Mine || v.isMod() {
		out.Visibility, out.RemovedReason = c.Visibility, c.RemovedReason
	}
	return out
}
