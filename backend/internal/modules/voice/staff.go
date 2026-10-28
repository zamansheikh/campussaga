package voice

import (
	"context"
	"time"
	"unicode/utf8"

	"github.com/google/uuid"

	"github.com/zamansheikh/varsitykotha/backend/internal/modules/voice/store"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/apperr"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/db"
)

// audit records a staff action. meta never names an author (§2.3).
func (s *Service) audit(ctx context.Context, q *store.Queries, v viewer, action, targetType string, target uuid.UUID, meta any) error {
	tt, tid := targetType, target.String()
	return q.InsertAudit(ctx, store.InsertAuditParams{ActorID: &v.id, Action: action, TargetType: &tt, TargetID: &tid, Meta: mustJSON(meta)})
}

// ---- authorities -----------------------------------------------------------------

var nextStatuses = map[string][]string{
	"open":         {"acknowledged", "in_progress", "solved", "rejected"},
	"acknowledged": {"in_progress", "solved", "rejected"},
	"in_progress":  {"solved", "rejected"},
}

type statusInput struct {
	ID   string `json:"-" path:"id" validate:"required,uuid"`
	To   string `json:"to" validate:"required,oneof=acknowledged in_progress solved rejected"`
	Note string `json:"note"`
}

func (s *Service) handleStatus(ctx context.Context, in *statusInput) (*Issue, error) {
	note := cleanText(in.Note)
	if utf8.RuneCountInString(note) > 500 {
		return nil, apperr.Validation(map[string]string{"note": "must be at most 500 characters"})
	}
	if in.To == "rejected" && note == "" {
		return nil, ErrNoteRequired
	}
	var (
		out    *Issue
		notice *pending
	)
	err := s.d.InTx(ctx, func(ctx context.Context) error {
		q := store.New(s.d.Q(ctx))
		v, err := s.begin(ctx, q)
		if err != nil {
			return err
		}
		id := uuid.MustParse(in.ID)
		r, err := s.getIssue(ctx, q, v, id)
		if err != nil {
			return err
		}
		if !v.authorityOf(r.UniversityID) {
			return ErrIssueNotFound
		}
		is, err := q.LockIssue(ctx, id)
		if err != nil {
			return err
		}
		allowed := false
		for _, to := range nextStatuses[is.Status] {
			allowed = allowed || to == in.To
		}
		if !allowed || is.Visibility != "visible" {
			return ErrStatusChange
		}
		now := s.now()
		var solvedAt *time.Time
		if in.To == "solved" {
			solvedAt = &now
		}
		if err := q.SetIssueStatus(ctx, store.SetIssueStatusParams{ID: id, Status: in.To, Now: now, SolvedAt: solvedAt}); err != nil {
			return err
		}
		if err := q.InsertStatusUpdate(ctx, store.InsertStatusUpdateParams{IssueID: id, ActorKind: "authority",
			ActorTitle: v.staffTitle, FromStatus: is.Status, ToStatus: in.To, Note: note, Now: now}); err != nil {
			return err
		}
		if err := s.audit(ctx, q, v, "issue.status", "issue", id, map[string]string{"from": is.Status, "to": in.To}); err != nil {
			return err
		}
		if notice, err = s.statusNotice(ctx, q, is, in.To, v.id); err != nil {
			return err
		}
		out, err = s.reload(ctx, q, v, id)
		return err
	})
	if err == nil {
		s.send(notice)
	}
	return out, err
}

type officialInput struct {
	ID   string `json:"-" path:"id" validate:"required,uuid"`
	Body string `json:"body" validate:"required"`
}

func (s *Service) handleOfficialReply(ctx context.Context, in *officialInput) (*Comment, error) {
	body := cleanText(in.Body)
	if n := utf8.RuneCountInString(body); n < 1 || n > 2000 {
		return nil, apperr.Validation(map[string]string{"body": "must be 1 to 2000 characters"})
	}
	var (
		out    *Comment
		notice *pending
	)
	err := s.d.InTx(ctx, func(ctx context.Context) error {
		q := store.New(s.d.Q(ctx))
		v, err := s.begin(ctx, q)
		if err != nil {
			return err
		}
		id := uuid.MustParse(in.ID)
		r, err := s.getIssue(ctx, q, v, id)
		if err != nil {
			return err
		}
		if !v.authorityOf(r.UniversityID) || r.Visibility != "visible" {
			return ErrIssueNotFound
		}
		cid, err := q.CreateComment(ctx, store.CreateCommentParams{IssueID: id, Kind: "official",
			OfficialTitle: v.staffTitle, Named: true, NamedAuthorID: &v.id, Body: body, Visibility: "visible", Now: s.now()})
		if err != nil {
			return err
		}
		if err := q.InsertCommentAuthor(ctx, store.InsertCommentAuthorParams{CommentID: cid, UserID: v.id}); err != nil {
			return err
		}
		if _, err := q.AdjustIssueCounts(ctx, store.AdjustIssueCountsParams{ID: id, Comments: 1}); err != nil {
			return err
		}
		if err := s.audit(ctx, q, v, "issue.official_reply", "issue", id, map[string]string{"commentId": cid.String()}); err != nil {
			return err
		}
		is, err := q.LockIssue(ctx, id)
		if err != nil {
			return err
		}
		if notice, err = s.officialNotice(ctx, q, is, v.staffTitle, v.id); err != nil {
			return err
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
		s.send(notice)
	}
	return out, err
}

// ---- moderation --------------------------------------------------------------------

type QueueItem struct {
	TargetType string         `json:"targetType"`
	Issue      IssueCard      `json:"issue"`
	Comment    *Comment       `json:"comment"`
	University UniversityRef  `json:"university"`
	Reasons    map[string]int `json:"reasons"`
	HoldReason string         `json:"holdReason"`
	CreatedAt  time.Time      `json:"createdAt"`
}

type UniversityRef struct {
	ID   uuid.UUID `json:"id"`
	Slug string    `json:"slug"`
	Name string    `json:"name"`
}

type queueReq struct {
	Kind         string `json:"-" query:"kind" validate:"required,oneof=held reported hidden private"`
	UniversityID string `json:"-" query:"universityId" validate:"omitempty,uuid"`
	Cursor       string `json:"-" query:"cursor" validate:"max=200"`
}

const queuePageSize = 20

func (s *Service) handleQueue(ctx context.Context, in *queueReq) (*Page[QueueItem], error) {
	q := store.New(s.d.Q(ctx))
	v, err := s.begin(ctx, q)
	if err != nil {
		return nil, err
	}
	off, err := parseOffsetCursor(in.Cursor)
	if err != nil {
		return nil, err
	}
	var uni *uuid.UUID
	if in.UniversityID != "" {
		u := uuid.MustParse(in.UniversityID)
		uni = &u
	}
	if v.role == RoleModerator && v.staffUni != nil {
		uni = v.staffUni // scoped moderators see their university only
	}
	rows, err := q.Queue(ctx, store.QueueParams{Kind: in.Kind, UniversityID: uni, Lim: queuePageSize, Off: int32(off)})
	if err != nil {
		return nil, err
	}
	out := &Page[QueueItem]{Items: []QueueItem{}}
	unis := map[uuid.UUID]UniversityRef{}
	for _, row := range rows {
		r, err := q.GetIssue(ctx, store.GetIssueParams{ID: row.IssueID, Viewer: v.id})
		if err != nil {
			return nil, err
		}
		item := QueueItem{TargetType: row.TargetType, Issue: cardView(v, r), HoldReason: row.HoldReason,
			CreatedAt: roughTime(row.CreatedAt), Reasons: map[string]int{}}
		target := row.IssueID
		if row.TargetType == "comment" && row.CommentID != nil {
			c, err := q.GetComment(ctx, store.GetCommentParams{ID: *row.CommentID, Viewer: v.id})
			if err != nil {
				return nil, err
			}
			cv := commentView(v, c)
			item.Comment, target = &cv, c.ID
		}
		reasons, err := q.OpenReasons(ctx, target)
		if err != nil {
			return nil, err
		}
		for _, rr := range reasons {
			item.Reasons[rr.Reason] = int(rr.N)
		}
		ref, ok := unis[row.UniversityID]
		if !ok {
			u, err := q.UniversityRef(ctx, row.UniversityID)
			if err != nil {
				return nil, err
			}
			ref = UniversityRef{ID: u.ID, Slug: u.Slug, Name: u.Name}
			unis[row.UniversityID] = ref
		}
		item.University = ref
		out.Items = append(out.Items, item)
	}
	if len(rows) == queuePageSize {
		c := offsetCursor(off + queuePageSize)
		out.NextCursor = &c
	}
	return out, nil
}

type ModerationIssue struct {
	Issue
	Reports  []ReportView `json:"reports"`
	Comments []Comment    `json:"comments"`
	// PhotoChecks: the photo check's result per image (moderators only).
	PhotoChecks []PhotoCheckView `json:"photoChecks"`
}

// PhotoCheckView: score nil = not checked (checker down, or development).
type PhotoCheckView struct {
	ImageID uuid.UUID `json:"imageId"`
	Score   *float32  `json:"score"`
	Flagged bool      `json:"flagged"`
}

type ReportView struct {
	TargetType string    `json:"targetType"`
	TargetID   uuid.UUID `json:"targetId"`
	Reason     string    `json:"reason"`
	Details    string    `json:"details"`
	State      string    `json:"state"`
	CreatedAt  time.Time `json:"createdAt"`
}

// handleModerationIssue: the issue, its reports (no reporters) and every comment.
func (s *Service) handleModerationIssue(ctx context.Context, in *issueReq) (*ModerationIssue, error) {
	q := store.New(s.d.Q(ctx))
	v, err := s.begin(ctx, q)
	if err != nil {
		return nil, err
	}
	r, err := s.getIssue(ctx, q, v, uuid.MustParse(in.ID))
	if err != nil {
		return nil, err
	}
	is, err := s.detail(ctx, q, v, r)
	if err != nil {
		return nil, err
	}
	out := &ModerationIssue{Issue: *is, Reports: []ReportView{}, Comments: []Comment{}, PhotoChecks: []PhotoCheckView{}}
	checks, err := q.ImageChecks(ctx, r.ID)
	if err != nil {
		return nil, err
	}
	for _, c := range checks {
		out.PhotoChecks = append(out.PhotoChecks, PhotoCheckView{ImageID: c.ID, Score: c.NsfwScore, Flagged: c.Flagged})
	}
	reps, err := q.IssueReports(ctx, r.ID)
	if err != nil {
		return nil, err
	}
	for _, rp := range reps {
		out.Reports = append(out.Reports, ReportView{TargetType: rp.TargetType, TargetID: rp.TargetID, Reason: rp.Reason,
			Details: rp.Details, State: rp.State, CreatedAt: roughTime(rp.CreatedAt)})
	}
	cursor := ""
	for range 20 { // up to 600 comments
		page, err := s.comments(ctx, q, v, r, cursor, true)
		if err != nil {
			return nil, err
		}
		out.Comments = append(out.Comments, page.Items...)
		if page.NextCursor == nil {
			break
		}
		cursor = *page.NextCursor
	}
	return out, nil
}

type moderateInput struct {
	ID     string `json:"-" path:"id" validate:"required,uuid"`
	Action string `json:"action" validate:"required,oneof=approve hide remove restore"`
	Reason string `json:"reason"`
}

func (in *moderateInput) check() error {
	in.Reason = cleanText(in.Reason)
	if utf8.RuneCountInString(in.Reason) > 300 {
		return apperr.Validation(map[string]string{"reason": "must be at most 300 characters"})
	}
	if in.Action == "remove" && in.Reason == "" {
		return apperr.Validation(map[string]string{"reason": "is required to remove (the author sees it)"})
	}
	return nil
}

func (s *Service) handleModerateIssue(ctx context.Context, in *moderateInput) (*Issue, error) {
	if err := in.check(); err != nil {
		return nil, err
	}
	var (
		out    *Issue
		notice *pending
	)
	err := s.d.InTx(ctx, func(ctx context.Context) error {
		q := store.New(s.d.Q(ctx))
		v, err := s.begin(ctx, q)
		if err != nil {
			return err
		}
		id := uuid.MustParse(in.ID)
		if _, err := s.getIssue(ctx, q, v, id); err != nil {
			return err
		}
		is, err := q.LockIssue(ctx, id)
		if err != nil {
			return err
		}
		visibility, hold, reason := "visible", "", ""
		switch in.Action {
		case "hide":
			visibility, hold = "hidden", HoldModerator
		case "remove":
			visibility, reason = "removed", in.Reason
		}
		if err := q.SetIssueVisibility(ctx, store.SetIssueVisibilityParams{ID: id, Visibility: visibility,
			HoldReason: hold, RemovedReason: reason}); err != nil {
			return err
		}
		if _, err := q.ResolveReports(ctx, store.ResolveReportsParams{TargetID: id, State: "resolved", Now: s.now()}); err != nil {
			return err
		}
		if err := q.ClearIssueReports(ctx, id); err != nil {
			return err
		}
		meta := map[string]string{"from": is.Visibility}
		if in.Reason != "" {
			meta["reason"] = in.Reason
		}
		if err := s.audit(ctx, q, v, "moderation."+in.Action, "issue", id, meta); err != nil {
			return err
		}
		switch {
		case in.Action == "approve" && is.Visibility == "held":
			notice, err = s.moderatedNotice(ctx, q, is, true, "")
		case in.Action == "remove" && is.Visibility != "removed" && !is.DeletedByAuthor:
			notice, err = s.moderatedNotice(ctx, q, is, false, in.Reason)
		}
		if err != nil {
			return err
		}
		out, err = s.reload(ctx, q, v, id)
		return err
	})
	if err == nil {
		s.send(notice)
	}
	return out, err
}

type moderateCommentInput struct {
	ID     string `json:"-" path:"id" validate:"required,uuid"`
	Action string `json:"action" validate:"required,oneof=approve hide remove restore"`
	Reason string `json:"reason"`
}

func (s *Service) handleModerateComment(ctx context.Context, in *moderateCommentInput) (*Comment, error) {
	m := moderateInput{ID: in.ID, Action: in.Action, Reason: in.Reason}
	if err := m.check(); err != nil {
		return nil, err
	}
	var out *Comment
	err := s.d.InTx(ctx, func(ctx context.Context) error {
		q := store.New(s.d.Q(ctx))
		v, err := s.begin(ctx, q)
		if err != nil {
			return err
		}
		cid := uuid.MustParse(in.ID)
		c, err := q.LockComment(ctx, cid)
		if db.IsNoRows(err) {
			return ErrCommentNotFound
		}
		if err != nil {
			return err
		}
		if _, err := s.getIssue(ctx, q, v, c.IssueID); err != nil {
			return ErrCommentNotFound
		}
		visibility, hold, reason := "visible", "", ""
		switch m.Action {
		case "hide":
			visibility, hold = "hidden", HoldModerator
		case "remove":
			visibility, reason = "removed", m.Reason
		}
		if err := s.setCommentVisibility(ctx, q, c, visibility, hold, reason, false); err != nil {
			return err
		}
		if _, err := q.ResolveReports(ctx, store.ResolveReportsParams{TargetID: cid, State: "resolved", Now: s.now()}); err != nil {
			return err
		}
		if err := q.ClearCommentReports(ctx, cid); err != nil {
			return err
		}
		meta := map[string]string{"from": c.Visibility, "issueId": c.IssueID.String()}
		if m.Reason != "" {
			meta["reason"] = m.Reason
		}
		if err := s.audit(ctx, q, v, "moderation."+m.Action, "comment", cid, meta); err != nil {
			return err
		}
		row, err := q.GetComment(ctx, store.GetCommentParams{ID: cid, Viewer: v.id})
		if err != nil {
			return err
		}
		view := commentView(v, row)
		out = &view
		return nil
	})
	return out, err
}

type banInput struct {
	ID     string `json:"-" path:"id" validate:"required,uuid"`
	Days   *int   `json:"days" validate:"omitempty,oneof=7 30"`
	Reason string `json:"reason" validate:"required"`
}

type banRes struct {
	BannedUntil *time.Time `json:"bannedUntil"`
}

func (s *Service) handleBanIssueAuthor(ctx context.Context, in *banInput) (*banRes, error) {
	return s.ban(ctx, in, false)
}

func (s *Service) handleBanCommentAuthor(ctx context.Context, in *banInput) (*banRes, error) {
	return s.ban(ctx, in, true)
}

// ban blocks the author of an issue or comment from writing, resolving who
// they are inside this transaction. Nothing about them is returned, logged
// or audited: the audit row names the content, not the person.
func (s *Service) ban(ctx context.Context, in *banInput, comment bool) (*banRes, error) {
	reason := cleanText(in.Reason)
	if reason == "" || utf8.RuneCountInString(reason) > 300 {
		return nil, apperr.Validation(map[string]string{"reason": "must be 1 to 300 characters"})
	}
	var out *banRes
	err := s.d.InTx(ctx, func(ctx context.Context) error {
		q := store.New(s.d.Q(ctx))
		v, err := s.begin(ctx, q)
		if err != nil {
			return err
		}
		id := uuid.MustParse(in.ID)
		var author uuid.UUID
		target := "issue"
		if comment {
			target = "comment"
			c, err := q.LockComment(ctx, id)
			if db.IsNoRows(err) {
				return ErrCommentNotFound
			}
			if err != nil {
				return err
			}
			if _, err := s.getIssue(ctx, q, v, c.IssueID); err != nil {
				return ErrCommentNotFound
			}
			if c.Kind == "official" {
				return ErrCannotBanOfficial
			}
			author, err = q.CommentAuthorID(ctx, id)
			if db.IsNoRows(err) {
				return ErrCommentNotFound // the account was deleted
			}
			if err != nil {
				return err
			}
		} else {
			if _, err := s.getIssue(ctx, q, v, id); err != nil {
				return err
			}
			author, err = q.IssueAuthorID(ctx, id)
			if db.IsNoRows(err) {
				return ErrIssueNotFound
			}
			if err != nil {
				return err
			}
		}
		var until *time.Time
		if in.Days != nil {
			t := s.now().Add(time.Duration(*in.Days) * 24 * time.Hour)
			until = &t
		}
		if err := q.UpsertBan(ctx, store.UpsertBanParams{UserID: author, Until: until, Reason: reason}); err != nil {
			return err
		}
		if err := s.audit(ctx, q, v, "moderation.ban", target, id, map[string]any{"days": in.Days, "reason": reason}); err != nil {
			return err
		}
		out = &banRes{BannedUntil: until}
		return nil
	})
	return out, err
}

type dismissInput struct {
	TargetType string `json:"targetType" validate:"required,oneof=issue comment"`
	TargetID   string `json:"targetId" validate:"required,uuid"`
}

// handleDismiss: the reports were wrong; an item hidden by reports comes back.
func (s *Service) handleDismiss(ctx context.Context, in *dismissInput) (*struct{}, error) {
	return nil, s.d.InTx(ctx, func(ctx context.Context) error {
		q := store.New(s.d.Q(ctx))
		v, err := s.begin(ctx, q)
		if err != nil {
			return err
		}
		id := uuid.MustParse(in.TargetID)
		if in.TargetType == "issue" {
			if _, err := s.getIssue(ctx, q, v, id); err != nil {
				return err
			}
			is, err := q.LockIssue(ctx, id)
			if err != nil {
				return err
			}
			if is.Visibility == "hidden" && is.HoldReason == HoldReports {
				if err := q.SetIssueVisibility(ctx, store.SetIssueVisibilityParams{ID: id, Visibility: "visible"}); err != nil {
					return err
				}
			}
			if err := q.ClearIssueReports(ctx, id); err != nil {
				return err
			}
		} else {
			c, err := q.LockComment(ctx, id)
			if db.IsNoRows(err) {
				return ErrCommentNotFound
			}
			if err != nil {
				return err
			}
			if _, err := s.getIssue(ctx, q, v, c.IssueID); err != nil {
				return ErrCommentNotFound
			}
			if c.Visibility == "hidden" && c.HoldReason == HoldReports {
				if err := s.setCommentVisibility(ctx, q, c, "visible", "", "", false); err != nil {
					return err
				}
			}
			if err := q.ClearCommentReports(ctx, id); err != nil {
				return err
			}
		}
		if _, err := q.ResolveReports(ctx, store.ResolveReportsParams{TargetID: id, State: "dismissed", Now: s.now()}); err != nil {
			return err
		}
		return s.audit(ctx, q, v, "moderation.dismiss", in.TargetType, id, map[string]string{})
	})
}
