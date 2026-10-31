package voice

import (
	"context"
	"time"

	"github.com/google/uuid"

	"github.com/zamansheikh/varsitykotha/backend/internal/platform/apperr"
)

// A campus admin (docs/CAMPUS_ADMINS.md) moderates their own university's
// public Campus posts and comments with the same rules as a moderator
// scoped to that university: the moderation handlers run unchanged, with
// a viewer built from the scope in ctx.

type campusScopeKey struct{}

// campusScope returns the university a campus admin acts for, if ctx has one.
func campusScope(ctx context.Context) (uuid.UUID, bool) {
	u, ok := ctx.Value(campusScopeKey{}).(uuid.UUID)
	return u, ok
}

// CampusReport is a reported post or comment in the campus admin's list.
type CampusReport struct {
	Kind      string         `json:"kind"` // issue | comment
	ID        uuid.UUID      `json:"id"`
	IssueID   uuid.UUID      `json:"issueId"`
	Excerpt   string         `json:"excerpt"`
	Reports   int            `json:"reports"`
	Reasons   map[string]int `json:"reasons"`
	CreatedAt time.Time      `json:"createdAt"`
	Hidden    bool           `json:"hidden"`
}

// CampusReports lists the university's reported public posts and comments
// (private safety issues stay with authorities and moderators), newest first.
func (s *Service) CampusReports(ctx context.Context, uni uuid.UUID) ([]CampusReport, error) {
	rows, err := s.d.Q(ctx).Query(ctx, `
		SELECT 'issue', i.id, i.id, i.title || ' ' || i.body, i.report_count, i.created_at, i.visibility = 'hidden'
		FROM issues i
		WHERE i.university_id = $1 AND NOT i.private AND i.report_count > 0 AND i.visibility <> 'removed'
		UNION ALL
		SELECT 'comment', c.id, c.issue_id, c.body, c.report_count, c.created_at, c.visibility = 'hidden'
		FROM comments c JOIN issues i ON i.id = c.issue_id
		WHERE i.university_id = $1 AND NOT i.private AND c.report_count > 0 AND c.visibility <> 'removed'
		ORDER BY 6 DESC
		LIMIT 100`, uni)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []CampusReport{}
	for rows.Next() {
		var r CampusReport
		if err := rows.Scan(&r.Kind, &r.ID, &r.IssueID, &r.Excerpt, &r.Reports, &r.CreatedAt, &r.Hidden); err != nil {
			return nil, err
		}
		r.Excerpt, _ = preview(r.Excerpt, 140)
		r.Reasons = map[string]int{}
		out = append(out, r)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	for i := range out {
		rr, err := s.d.Q(ctx).Query(ctx, `SELECT reason, count(*)::int FROM reports WHERE target_id = $1 AND state = 'open' GROUP BY reason`, out[i].ID)
		if err != nil {
			return nil, err
		}
		for rr.Next() {
			var reason string
			var n int
			if err := rr.Scan(&reason, &n); err != nil {
				rr.Close()
				return nil, err
			}
			out[i].Reasons[reason] = n
		}
		rr.Close()
		if err := rr.Err(); err != nil {
			return nil, err
		}
	}
	return out, nil
}

// CampusReportsWaiting counts the university's reported items.
func (s *Service) CampusReportsWaiting(ctx context.Context, uni uuid.UUID) (int, error) {
	var n int
	err := s.d.Q(ctx).QueryRow(ctx, `
		SELECT (SELECT count(*) FROM issues i WHERE i.university_id = $1 AND NOT i.private AND i.report_count > 0 AND i.visibility <> 'removed')
		     + (SELECT count(*) FROM comments c JOIN issues i ON i.id = c.issue_id
		        WHERE i.university_id = $1 AND NOT i.private AND c.report_count > 0 AND c.visibility <> 'removed')`, uni).Scan(&n)
	return n, err
}

// CampusModerate applies hide, restore or dismiss to a reported post or
// comment of the university. Anything else (another university, a private
// issue, a missing item) is not found.
func (s *Service) CampusModerate(ctx context.Context, uni uuid.UUID, kind string, id uuid.UUID, action string) error {
	var found bool
	var notFound *apperr.Error
	switch kind {
	case "issue":
		notFound = ErrIssueNotFound
		err := s.d.Q(ctx).QueryRow(ctx,
			`SELECT EXISTS (SELECT 1 FROM issues WHERE id = $1 AND university_id = $2 AND NOT private)`, id, uni).Scan(&found)
		if err != nil {
			return err
		}
	case "comment":
		notFound = ErrCommentNotFound
		err := s.d.Q(ctx).QueryRow(ctx, `SELECT EXISTS (SELECT 1 FROM comments c JOIN issues i ON i.id = c.issue_id
			WHERE c.id = $1 AND i.university_id = $2 AND NOT i.private)`, id, uni).Scan(&found)
		if err != nil {
			return err
		}
	default:
		return apperr.Validation(map[string]string{"kind": "must be issue or comment"})
	}
	if !found {
		return notFound
	}
	ctx = context.WithValue(ctx, campusScopeKey{}, uni)
	switch {
	case action == "dismiss":
		_, err := s.handleDismiss(ctx, &dismissInput{TargetType: kind, TargetID: id.String()})
		return err
	case kind == "issue":
		_, err := s.handleModerateIssue(ctx, &moderateInput{ID: id.String(), Action: action})
		return err
	default:
		_, err := s.handleModerateComment(ctx, &moderateCommentInput{ID: id.String(), Action: action})
		return err
	}
}
