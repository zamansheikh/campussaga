package voice

import (
	"context"
	"time"
	"unicode/utf8"

	"github.com/google/uuid"

	"github.com/zamansheikh/campussaga/backend/internal/modules/voice/store"
	"github.com/zamansheikh/campussaga/backend/internal/platform/db"
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

// commentNotice tells the issue's author about a new comment, at most once
// per issue every 15 minutes.
func (s *Service) commentNotice(ctx context.Context, q *store.Queries, is store.Issue, commenter uuid.UUID) (*pending, error) {
	author, err := q.IssueAuthorID(ctx, is.ID)
	if db.IsNoRows(err) {
		return nil, nil // the author deleted their account
	}
	if err != nil {
		return nil, err
	}
	if author == commenter {
		return nil, nil
	}
	s.mu.Lock()
	defer s.mu.Unlock()
	now := s.now()
	if last, ok := s.lastComment[is.ID]; ok && now.Sub(last) < 15*time.Minute {
		return nil, nil
	}
	s.lastComment[is.ID] = now
	return &pending{to: []uuid.UUID{author}, n: Notice{
		Texts: map[string]NoticeText{
			"en": {Title: "New comment on your issue", Body: short(is.Title, 120)},
			"bn": {Title: "তোমার ইস্যুতে নতুন মন্তব্য", Body: short(is.Title, 120)},
		},
		Data: data("issue_comment", is.ID),
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
	en, bn := NoticeText{Title: "Your issue is now public", Body: short(is.Title, 120)},
		NoticeText{Title: "তোমার ইস্যু এখন সবাই দেখছে", Body: short(is.Title, 120)}
	if !approved {
		en = NoticeText{Title: "Your issue was removed", Body: short(reason, 160)}
		bn = NoticeText{Title: "তোমার ইস্যু সরানো হয়েছে", Body: short(reason, 160)}
	}
	return &pending{to: []uuid.UUID{author}, n: Notice{
		Texts: map[string]NoticeText{"en": en, "bn": bn},
		Data:  data("issue_moderated", is.ID),
	}}, nil
}
