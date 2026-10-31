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

type commentsReq struct {
	ID     string `json:"-" path:"id" validate:"required,uuid"`
	Cursor string `json:"-" query:"cursor" validate:"max=200"`
}

func (s *Service) handleComments(ctx context.Context, in *commentsReq) (*Page[Comment], error) {
	q := store.New(s.d.Q(ctx))
	v, err := s.begin(ctx, q)
	if err != nil {
		return nil, err
	}
	r, err := s.getIssue(ctx, q, v, uuid.MustParse(in.ID))
	if err != nil {
		return nil, err
	}
	return s.comments(ctx, q, v, r, in.Cursor, v.modOf(r.UniversityID) && v.isMod())
}

// comments: oldest first; showAll (moderators) includes every state, others
// see visible ones plus their own.
func (s *Service) comments(ctx context.Context, q *store.Queries, v viewer, r store.GetIssueRow, cursor string, showAll bool) (*Page[Comment], error) {
	at, id, err := parseKeyCursor(cursor)
	if err != nil {
		return nil, err
	}
	rs, err := q.ListComments(ctx, store.ListCommentsParams{Viewer: v.id, IssueID: r.ID, ShowAll: showAll,
		AfterAt: at, AfterID: id, Lim: commentPageSize})
	if err != nil {
		return nil, err
	}
	out := &Page[Comment]{Items: []Comment{}}
	for _, c := range rs {
		out.Items = append(out.Items, commentView(v, store.GetCommentRow(c)))
	}
	if len(rs) == commentPageSize {
		last := rs[len(rs)-1]
		c := keyCursor(last.CreatedAt, last.ID)
		out.NextCursor = &c
	}
	return out, nil
}

type commentInput struct {
	ID        string `json:"-" path:"id" validate:"required,uuid"`
	Body      string `json:"body" validate:"required"`
	Anonymous *bool  `json:"anonymous"`
	ParentID  string `json:"parentId" validate:"omitempty,uuid"`
}

func (s *Service) handleComment(ctx context.Context, in *commentInput) (*Comment, error) {
	body := cleanText(in.Body)
	if n := utf8.RuneCountInString(body); n < 1 || n > 1000 {
		return nil, apperr.Validation(map[string]string{"body": "must be 1 to 1000 characters"})
	}
	anonymous := in.Anonymous == nil || *in.Anonymous
	var (
		out    *Comment
		notice *pending
		reply  *pending
	)
	err := s.d.InTx(ctx, func(ctx context.Context) error {
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
		if r.Visibility == "removed" {
			return ErrIssueClosed
		}
		if err := s.requireNoBan(ctx, q, v); err != nil {
			return err
		}
		// A reply: the comment replied to must be a visible one of this
		// issue; replying to a reply attaches to that reply's parent (one level).
		var parentID *uuid.UUID
		var replyTo *store.GetCommentRow
		if in.ParentID != "" {
			pc, err := q.GetComment(ctx, store.GetCommentParams{ID: uuid.MustParse(in.ParentID), Viewer: v.id})
			if db.IsNoRows(err) || (err == nil && (pc.IssueID != issueID || pc.Visibility != "visible")) {
				return ErrCommentNotFound
			}
			if err != nil {
				return err
			}
			replyTo = &pc
			top := pc.ID
			if pc.ParentID != nil {
				top = *pc.ParentID
			}
			parentID = &top
		}
		visibility, hold := "visible", checkText(body)
		if hold == "" && !v.verified && !v.isStaff() {
			hold = HoldUnverified
		}
		if hold != "" {
			visibility = "held"
		}
		params := store.CreateCommentParams{IssueID: issueID, Kind: "student", Body: body, ParentID: parentID,
			Visibility: visibility, HoldReason: hold, Named: !anonymous, Now: s.now()}
		if anonymous {
			params.Handle = handle(s.secret, issueID, v.id)
		} else {
			params.NamedAuthorID = &v.id
		}
		cid, err := q.CreateComment(ctx, params)
		if err != nil {
			return err
		}
		if err := q.InsertCommentAuthor(ctx, store.InsertCommentAuthorParams{CommentID: cid, UserID: v.id}); err != nil {
			return err
		}
		if err := q.Follow(ctx, store.FollowParams{IssueID: issueID, UserID: v.id}); err != nil {
			return err
		}
		if visibility == "visible" {
			if _, err := q.AdjustIssueCounts(ctx, store.AdjustIssueCountsParams{ID: issueID, Comments: 1}); err != nil {
				return err
			}
			is, err := q.LockIssue(ctx, issueID)
			if err != nil {
				return err
			}
			except := uuid.Nil
			if replyTo != nil {
				if reply, err = s.replyNotice(ctx, q, is, *replyTo, body, v.id); err != nil {
					return err
				}
				if reply != nil {
					except = reply.to[0] // one push is enough for them
				}
			}
			if notice, err = s.commentNotice(ctx, q, is, v.id, except); err != nil {
				return err
			}
		}
		c, err := q.GetComment(ctx, store.GetCommentParams{ID: cid, Viewer: v.id})
		if err != nil {
			return err
		}
		view := commentView(v, c)
		out = &view
		return nil
	})
	if err == nil {
		s.send(reply)
		s.send(notice)
	}
	return out, err
}

type commentReq struct {
	ID      string `json:"-" path:"id" validate:"required,uuid"`
	Comment string `json:"-" path:"c" validate:"required,uuid"`
}

// handleDeleteComment: the comment's author removes it (soft).
func (s *Service) handleDeleteComment(ctx context.Context, in *commentReq) (*httpx.Empty, error) {
	return nil, s.d.InTx(ctx, func(ctx context.Context) error {
		q := store.New(s.d.Q(ctx))
		v, err := s.begin(ctx, q)
		if err != nil {
			return err
		}
		cid := uuid.MustParse(in.Comment)
		mine, err := q.IsCommentAuthor(ctx, store.IsCommentAuthorParams{CommentID: cid, Viewer: v.id})
		if err != nil {
			return err
		}
		if !mine {
			return ErrCommentNotFound
		}
		c, err := q.LockComment(ctx, cid)
		if err != nil {
			return err
		}
		if c.IssueID != uuid.MustParse(in.ID) {
			return ErrCommentNotFound
		}
		return s.setCommentVisibility(ctx, q, c, "removed", c.HoldReason, c.RemovedReason, true)
	})
}

// setCommentVisibility keeps the issue's visible-comment count right.
func (s *Service) setCommentVisibility(ctx context.Context, q *store.Queries, c store.Comment, visibility, hold, reason string, byAuthor bool) error {
	if err := q.SetCommentVisibility(ctx, store.SetCommentVisibilityParams{ID: c.ID, Visibility: visibility,
		HoldReason: hold, RemovedReason: reason, DeletedByAuthor: byAuthor}); err != nil {
		return err
	}
	var delta int32
	switch {
	case c.Visibility == "visible" && visibility != "visible":
		delta = -1
	case c.Visibility != "visible" && visibility == "visible":
		delta = 1
	}
	if delta != 0 {
		if _, err := q.AdjustIssueCounts(ctx, store.AdjustIssueCountsParams{ID: c.IssueID, Comments: delta}); err != nil {
			return err
		}
	}
	return nil
}

// commentOf loads a comment of an issue the viewer may see.
func (s *Service) commentOf(ctx context.Context, q *store.Queries, v viewer, issueID, commentID uuid.UUID) (store.GetCommentRow, error) {
	c, err := q.GetComment(ctx, store.GetCommentParams{ID: commentID, Viewer: v.id})
	if db.IsNoRows(err) || (err == nil && c.IssueID != issueID) {
		return c, ErrCommentNotFound
	}
	if err != nil {
		return c, err
	}
	if c.Visibility != "visible" && !c.Mine && !v.isMod() {
		return c, ErrCommentNotFound
	}
	return c, nil
}

// ---- comment likes ----------------------------------------------------------------------------------

type likeRes struct {
	LikeCount int  `json:"likeCount"`
	Liked     bool `json:"liked"`
}

func (s *Service) handleLikeComment(ctx context.Context, in *commentReq) (*likeRes, error) {
	return s.likeComment(ctx, in, true)
}

func (s *Service) handleUnlikeComment(ctx context.Context, in *commentReq) (*likeRes, error) {
	return s.likeComment(ctx, in, false)
}

// likeComment: visible comments only; liking your own is fine. Who liked is never returned.
func (s *Service) likeComment(ctx context.Context, in *commentReq, on bool) (*likeRes, error) {
	var out *likeRes
	err := s.d.InTx(ctx, func(ctx context.Context) error {
		q := store.New(s.d.Q(ctx))
		v, err := s.begin(ctx, q)
		if err != nil {
			return err
		}
		r, err := s.getIssue(ctx, q, v, uuid.MustParse(in.ID))
		if err != nil {
			return err
		}
		if err := s.requireNoBan(ctx, q, v); err != nil {
			return err
		}
		c, err := s.commentOf(ctx, q, v, r.ID, uuid.MustParse(in.Comment))
		if err != nil {
			return err
		}
		if c.Visibility != "visible" {
			return ErrCommentNotFound
		}
		if r.Visibility == "removed" {
			return ErrIssueClosed
		}
		var delta int32
		if on {
			n, err := q.LikeComment(ctx, store.LikeCommentParams{CommentID: c.ID, UserID: v.id})
			if err != nil {
				return err
			}
			delta = int32(n)
		} else {
			n, err := q.UnlikeComment(ctx, store.UnlikeCommentParams{CommentID: c.ID, UserID: v.id})
			if err != nil {
				return err
			}
			delta = -int32(n)
		}
		n, err := q.AdjustCommentLikes(ctx, store.AdjustCommentLikesParams{ID: c.ID, Delta: delta})
		if err != nil {
			return err
		}
		out = &likeRes{LikeCount: int(n), Liked: on}
		return nil
	})
	return out, err
}
