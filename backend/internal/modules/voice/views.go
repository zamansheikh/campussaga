package voice

import (
	"encoding/json"
	"time"
	"unicode/utf8"

	"github.com/google/uuid"

	"github.com/zamansheikh/varsitykotha/backend/internal/modules/voice/store"
)

// Author is shown only for named posts and official replies: a display
// name, never an id or email. Name null = the account was deleted.
type Author struct {
	Name     *string `json:"name"`
	Verified bool    `json:"verified"`
}

type IssueCard struct {
	ID              uuid.UUID `json:"id"`
	Kind            string    `json:"kind"`
	Category        string    `json:"category"`
	Private         bool      `json:"private"`
	Title           string    `json:"title"`
	Preview         string    `json:"preview"`
	PreviewCut      bool      `json:"previewCut"`
	Status          string    `json:"status"`
	Visibility      string    `json:"visibility"`
	MeTooCount      int       `json:"meTooCount"`
	CommentCount    int       `json:"commentCount"`
	ImageCount      int       `json:"imageCount"`
	Thumbnail       *string   `json:"thumbnail"`
	Images          []Image   `json:"images"`
	Voted           bool      `json:"voted"`
	Following       bool      `json:"following"`
	Mine            bool      `json:"mine"`
	Author          *Author   `json:"author"`
	LocationLabel   string    `json:"locationLabel"`
	CreatedAt       time.Time `json:"createdAt"`
	StatusChangedAt time.Time `json:"statusChangedAt"`
	// Reactions: count per reaction, zero ones left out (issues: me_too).
	Reactions  map[string]int `json:"reactions"`
	MyReaction *string        `json:"myReaction"`
	Poll       *Poll          `json:"poll"`
}

// Poll: option votes are nil (hidden) until the caller has voted, unless it
// is the caller's own poll or it is closed. Counts only, never who.
type Poll struct {
	Options    []PollOption `json:"options"`
	TotalVotes int          `json:"totalVotes"`
	MyVote     *uuid.UUID   `json:"myVote"`
	ClosesAt   time.Time    `json:"closesAt"`
	Closed     bool         `json:"closed"`
}

type PollOption struct {
	ID    uuid.UUID `json:"id"`
	Label string    `json:"label"`
	Votes *int      `json:"votes"`
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
	Timeline      []TimelineEntry `json:"timeline"`
	HoldReason    string          `json:"holdReason"`
	RemovedReason string          `json:"removedReason"`
	ReportCount   int             `json:"reportCount"`
	Can           Can             `json:"can"`
}

type Comment struct {
	ID            uuid.UUID  `json:"id"`
	Kind          string     `json:"kind"`
	Handle        string     `json:"handle"`
	IsIssueAuthor bool       `json:"isIssueAuthor"`
	Mine          bool       `json:"mine"`
	Author        *Author    `json:"author"`
	OfficialTitle string     `json:"officialTitle"`
	Body          string     `json:"body"`
	Visibility    string     `json:"visibility"`
	RemovedReason string     `json:"removedReason"`
	CreatedAt     time.Time  `json:"createdAt"`
	ParentID      *uuid.UUID `json:"parentId"`
	LikeCount     int        `json:"likeCount"`
	Liked         bool       `json:"liked"`
}

const (
	EditWindow   = 60 * time.Minute
	ReopenWindow = 30 * 24 * time.Hour

	previewIssue = 160 // card preview length, issues
	previewPost  = 500 // card preview length, the other kinds
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

// preview: the first n characters, "…" appended when cut.
func preview(body string, n int) (string, bool) {
	if utf8.RuneCountInString(body) <= n {
		return body, false
	}
	return string([]rune(body)[:n-1]) + "…", true
}

type pollOptionRow struct {
	ID    uuid.UUID `json:"id"`
	Label string    `json:"label"`
	Votes int       `json:"votes"`
}

// cardView: the card as this viewer may see it.
func cardView(v viewer, r store.GetIssueRow, now time.Time) IssueCard {
	n := previewIssue
	if r.Kind != "issue" {
		n = previewPost
	}
	pv, cut := preview(r.Body, n)
	c := IssueCard{
		ID: r.ID, Kind: r.Kind, Category: r.Category, Private: r.Private, Title: r.Title, Preview: pv, PreviewCut: cut,
		Status: r.Status, Visibility: "visible", MeTooCount: int(r.MeTooCount), CommentCount: int(r.CommentCount),
		ImageCount: int(r.ImageCount), Voted: r.Voted, Following: r.Following, Mine: r.Mine,
		Author:        namedAuthor(r.Named, r.AuthorExists, r.AuthorName, r.AuthorVerified),
		LocationLabel: r.LocationLabel, CreatedAt: r.CreatedAt.UTC(), StatusChangedAt: r.StatusChangedAt.UTC(),
		Reactions: map[string]int{}, Images: []Image{},
	}
	_ = json.Unmarshal(r.Reactions, &c.Reactions)
	_ = json.Unmarshal(r.Images, &c.Images)
	if c.Reactions == nil {
		c.Reactions = map[string]int{}
	}
	if c.Images == nil {
		c.Images = []Image{}
	}
	if r.MyReaction != "" {
		m := r.MyReaction
		c.MyReaction = &m
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
	if r.Kind == "poll" && r.PollClosesAt != nil {
		c.Poll = pollView(v, r, now)
	}
	return c
}

func pollView(v viewer, r store.GetIssueRow, now time.Time) *Poll {
	var rows []pollOptionRow
	_ = json.Unmarshal(r.PollOptions, &rows)
	closes := r.PollClosesAt.UTC()
	p := &Poll{Options: make([]PollOption, 0, len(rows)), ClosesAt: closes, Closed: !now.Before(closes)}
	if id, err := uuid.Parse(r.PollMyVote); err == nil {
		p.MyVote = &id
	}
	show := p.MyVote != nil || r.Mine || p.Closed || v.isMod()
	for _, o := range rows {
		p.TotalVotes += o.Votes
		opt := PollOption{ID: o.ID, Label: o.Label}
		if show {
			n := o.Votes
			opt.Votes = &n
		}
		p.Options = append(p.Options, opt)
	}
	return p
}

// issueView: the full issue; the timeline is loaded by the caller.
func (s *Service) issueView(v viewer, r store.GetIssueRow, timeline []TimelineEntry) Issue {
	now := s.now()
	out := Issue{IssueCard: cardView(v, r, now), Body: r.Body, Timeline: timeline}
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
	isIssue := r.Kind == "issue"
	out.Can = Can{
		Edit:   r.Mine && !removed && now.Sub(r.CreatedAt) < EditWindow,
		Delete: r.Mine && !removed,
		Reopen: isIssue && r.Mine && r.Status == "solved" && r.SolvedAt != nil && now.Sub(*r.SolvedAt) < ReopenWindow,
		ChangeStatus: isIssue && v.authorityOf(r.UniversityID) && r.Visibility == "visible" &&
			(r.Status == "open" || r.Status == "acknowledged" || r.Status == "in_progress"),
		OfficialReply: isIssue && v.authorityOf(r.UniversityID) && r.Visibility == "visible",
		Moderate:      v.modOf(r.UniversityID) && v.isMod(),
	}
	return out
}

func commentView(v viewer, c store.GetCommentRow) Comment {
	out := Comment{
		ID: c.ID, Kind: c.Kind, Handle: c.Handle, IsIssueAuthor: c.IsIssueAuthor, Mine: c.Mine,
		OfficialTitle: c.OfficialTitle, Body: c.Body, Visibility: "visible", CreatedAt: c.CreatedAt.UTC(),
		ParentID: c.ParentID, LikeCount: int(c.LikeCount), Liked: c.Liked,
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
