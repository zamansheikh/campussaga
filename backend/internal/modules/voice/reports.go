package voice

import (
	"context"
	"unicode/utf8"

	"github.com/google/uuid"

	"github.com/zamansheikh/varsitykotha/backend/internal/modules/voice/store"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/apperr"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/db"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/httpx"
)

// AutoHideReports: this many open reports (one per person) hide an item
// until a moderator looks at it.
const AutoHideReports = 5

type reportInput struct {
	ID      string `json:"-" path:"id" validate:"required,uuid"`
	Comment string `json:"-" path:"c" validate:"omitempty,uuid"`
	Reason  string `json:"reason" validate:"required,oneof=spam abuse personal_info false_info inappropriate other"`
	Details string `json:"details"`
}

func (s *Service) handleReport(ctx context.Context, in *reportInput) (*httpx.Empty, error) {
	details := cleanText(in.Details)
	if utf8.RuneCountInString(details) > 300 {
		return nil, apperr.Validation(map[string]string{"details": "must be at most 300 characters"})
	}
	return nil, s.d.InTx(ctx, func(ctx context.Context) error {
		q := store.New(s.d.Q(ctx))
		v, err := s.begin(ctx, q)
		if err != nil {
			return err
		}
		issueID := uuid.MustParse(in.ID)
		r, err := s.getIssue(ctx, q, v, issueID)
		if err != nil {
			return err
		}
		if err := s.requireNoBan(ctx, q, v); err != nil {
			return err
		}
		targetType, target := "issue", issueID
		if in.Comment != "" {
			c, err := s.commentOf(ctx, q, v, issueID, uuid.MustParse(in.Comment))
			if err != nil {
				return err
			}
			targetType, target = "comment", c.ID
		} else if r.Visibility == "removed" {
			return ErrIssueClosed
		}
		id, err := q.InsertReport(ctx, store.InsertReportParams{TargetType: targetType, TargetID: target,
			IssueID: issueID, Reason: in.Reason, Details: details, Now: s.now()})
		if err != nil {
			return err
		}
		err = q.InsertReportAuthor(ctx, store.InsertReportAuthorParams{ReportID: id, UserID: v.id, TargetID: target})
		if db.IsUniqueViolation(err) {
			return ErrAlreadyReported
		}
		if err != nil {
			return err
		}
		if targetType == "issue" {
			counts, err := q.AdjustIssueCounts(ctx, store.AdjustIssueCountsParams{ID: issueID, Reports: 1})
			if err != nil {
				return err
			}
			if counts.ReportCount >= AutoHideReports && r.Visibility == "visible" {
				is, err := q.LockIssue(ctx, issueID)
				if err != nil {
					return err
				}
				return q.SetIssueVisibility(ctx, store.SetIssueVisibilityParams{ID: issueID, Visibility: "hidden",
					HoldReason: HoldReports, RemovedReason: is.RemovedReason})
			}
			return nil
		}
		n, err := q.AdjustCommentReports(ctx, store.AdjustCommentReportsParams{ID: target, Delta: 1})
		if err != nil {
			return err
		}
		if n >= AutoHideReports {
			c, err := q.LockComment(ctx, target)
			if err != nil {
				return err
			}
			if c.Visibility == "visible" {
				return s.setCommentVisibility(ctx, q, c, "hidden", HoldReports, c.RemovedReason, false)
			}
		}
		return nil
	})
}
