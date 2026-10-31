package voice

import (
	"context"
	"errors"

	"github.com/google/uuid"

	"github.com/zamansheikh/varsitykotha/backend/internal/modules/voice/store"
)

// ProfilePostsMax is how many posts a student's profile page shows.
const ProfilePostsMax = 20

// ProfilePosts are the latest named posts of author as the caller may see
// them (docs/GROWTH.md §4): only content the author put their name on
// (anonymous posts have no named_author_id, so they can never match), never
// private (safety) ones; the caller's own university sees everything else,
// other universities only public posts that are not campus-only (and only
// while campus visits are on).
func (s *Service) ProfilePosts(ctx context.Context, author uuid.UUID) ([]IssueCard, error) {
	q := store.New(s.d.Q(ctx))
	v, err := s.begin(ctx, q)
	if errors.Is(err, ErrFeatureDisabled) {
		return []IssueCard{}, nil
	}
	if err != nil {
		return nil, err
	}
	rows, err := q.ProfilePosts(ctx, store.ProfilePostsParams{
		Viewer: v.id, Author: &author, AllCampuses: v.isMod(), UniversityID: v.uni, VisitOn: v.visitOn, Lim: ProfilePostsMax,
	})
	if err != nil {
		return nil, err
	}
	now := s.now()
	out := make([]IssueCard, 0, len(rows))
	for _, r := range rows {
		out = append(out, cardView(v, store.GetIssueRow(r), now))
	}
	return out, nil
}
