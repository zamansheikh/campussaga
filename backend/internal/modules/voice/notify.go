package voice

import (
	"context"
	"time"
	"unicode/utf8"

	"github.com/google/uuid"

	"github.com/zamansheikh/varsitykotha/backend/internal/modules/voice/store"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/db"
)

// pending is a push to send once its transaction committed.
type pending struct {
	to []uuid.UUID
	n  Notice
}

func (s *Service) send(p *pending) {
	if p == nil || s.notify == nil || len(p.to) == 0 {
		return
	}
	s.notify(p.to, p.n)
}

var statusNames = map[string][2]string{
	"open":         {"Open", "খোলা"},
	"acknowledged": {"Acknowledged", "দেখা হয়েছে"},
	"in_progress":  {"In progress", "কাজ চলছে"},
	"solved":       {"Solved", "সমাধান হয়েছে"},
	"rejected":     {"Rejected", "বাতিল"},
}

func short(s string, n int) string {
	if utf8.RuneCountInString(s) <= n {
		return s
	}
	return string([]rune(s)[:n-1]) + "…"
}

func data(kind string, issue uuid.UUID) map[string]string {
	return map[string]string{"type": kind, "issueId": issue.String()}
}

// followers except the one who acted.
func (s *Service) followers(ctx context.Context, q *store.Queries, issue, except uuid.UUID) ([]uuid.UUID, error) {
	ids, err := q.Followers(ctx, issue)
	if err != nil {
		return nil, err
	}
	out := ids[:0]
	for _, id := range ids {
		if id != except {
			out = append(out, id)
		}
	}
	return out, nil
}

func (s *Service) statusNotice(ctx context.Context, q *store.Queries, is store.Issue, to string, actor uuid.UUID) (*pending, error) {
	ids, err := s.followers(ctx, q, is.ID, actor)
	if err != nil {
		return nil, err
	}
	name := statusNames[to]
	return &pending{to: ids, n: Notice{
		Texts: map[string]NoticeText{
			"en": {Title: "Issue update: " + name[0], Body: short(is.Title, 120)},
			"bn": {Title: "ইস্যু আপডেট: " + name[1], Body: short(is.Title, 120)},
		},
		Data: data("issue_status", is.ID),
	}}, nil
}

func (s *Service) officialNotice(ctx context.Context, q *store.Queries, is store.Issue, title string, actor uuid.UUID) (*pending, error) {
	ids, err := s.followers(ctx, q, is.ID, actor)
	if err != nil {
		return nil, err
	}
	return &pending{to: ids, n: Notice{
		Texts: map[string]NoticeText{
			"en": {Title: "Official reply from " + title, Body: short(is.Title, 120)},
			"bn": {Title: title + "-এর অফিসিয়াল উত্তর", Body: short(is.Title, 120)},
		},
		Data: data("issue_official", is.ID),
	}}, nil
}

// quote is what a push says about a post: the title of an issue, the
// first 80 characters of the text of any other kind.
func quote(is store.Issue) string {
	if is.Kind == "issue" {
		return short(is.Title, 120)
	}
	return short(is.Body, 80)
}

// commentNotice tells the post's author about a new comment, at most once
// per post every 15 minutes. except: someone who already got a push for this comment.
func (s *Service) commentNotice(ctx context.Context, q *store.Queries, is store.Issue, commenter, except uuid.UUID) (*pending, error) {
	author, err := q.IssueAuthorID(ctx, is.ID)
	if db.IsNoRows(err) {
		return nil, nil // the author deleted their account
	}
	if err != nil {
		return nil, err
	}
	if author == commenter || author == except {
		return nil, nil
	}
	s.mu.Lock()
	defer s.mu.Unlock()
	now := s.now()
	if last, ok := s.lastComment[is.ID]; ok && now.Sub(last) < 15*time.Minute {
		return nil, nil
	}
	s.lastComment[is.ID] = now
	en, bn := "New comment on your issue", "তোমার ইস্যুতে নতুন মন্তব্য"
	switch is.Kind {
	case "question":
		en, bn = "New answer to your question", "তোমার প্রশ্নের নতুন উত্তর"
	case "post", "poll":
		en, bn = "New comment on your post", "তোমার পোস্টে নতুন মন্তব্য"
	}
	return &pending{to: []uuid.UUID{author}, n: Notice{
		Texts: map[string]NoticeText{
			"en": {Title: en, Body: quote(is)},
			"bn": {Title: bn, Body: quote(is)},
		},
		Data: data("issue_comment", is.ID),
	}}, nil
}

// replyNotice tells the author of a comment about a reply to it: not to the
// replier, not for an official's comment, at most once per comment every 15 minutes.
func (s *Service) replyNotice(ctx context.Context, q *store.Queries, is store.Issue, to store.GetCommentRow, body string, replier uuid.UUID) (*pending, error) {
	if to.Kind == "official" {
		return nil, nil
	}
	author, err := q.CommentAuthorID(ctx, to.ID)
	if db.IsNoRows(err) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	if author == replier {
		return nil, nil
	}
	s.mu.Lock()
	defer s.mu.Unlock()
	now := s.now()
	if last, ok := s.lastReply[to.ID]; ok && now.Sub(last) < 15*time.Minute {
		return nil, nil
	}
	s.lastReply[to.ID] = now
	text := short(body, 80)
	return &pending{to: []uuid.UUID{author}, n: Notice{
		Texts: map[string]NoticeText{
			"en": {Title: "New reply to your comment", Body: text},
			"bn": {Title: "তোমার মন্তব্যে নতুন উত্তর", Body: text},
		},
		Data: data("issue_reply", is.ID),
	}}, nil
}

// moderatedNotice tells the author their issue went public or was removed.
func (s *Service) moderatedNotice(ctx context.Context, q *store.Queries, is store.Issue, approved bool, reason string) (*pending, error) {
	author, err := q.IssueAuthorID(ctx, is.ID)
	if db.IsNoRows(err) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	what, whatBN := "issue", "ইস্যু"
	if is.Kind != "issue" {
		what, whatBN = "post", "পোস্ট"
	}
	en, bn := NoticeText{Title: "Your " + what + " is now public", Body: quote(is)},
		NoticeText{Title: "তোমার " + whatBN + " এখন সবাই দেখছে", Body: quote(is)}
	if !approved {
		en = NoticeText{Title: "Your " + what + " was removed", Body: short(reason, 160)}
		bn = NoticeText{Title: "তোমার " + whatBN + " সরানো হয়েছে", Body: short(reason, 160)}
	}
	return &pending{to: []uuid.UUID{author}, n: Notice{
		Texts: map[string]NoticeText{"en": en, "bn": bn},
		Data:  data("issue_moderated", is.ID),
	}}, nil
}
