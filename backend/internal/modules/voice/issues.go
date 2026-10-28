package voice

import (
	"context"
	"slices"
	"strings"
	"time"
	"unicode/utf8"

	"github.com/google/uuid"

	"github.com/zamansheikh/campussaga/backend/internal/modules/voice/store"
	"github.com/zamansheikh/campussaga/backend/internal/platform/apperr"
	"github.com/zamansheikh/campussaga/backend/internal/platform/db"
	"github.com/zamansheikh/campussaga/backend/internal/platform/httpx"
)

var categories = []string{"academic", "hostel", "transport", "facilities", "safety", "administration", "food", "it", "other"}

const (
	feedPageSize    = 20
	trendingPages   = 10
	trendingDays    = 30
	similarDays     = 180
	maxImages       = 4
	commentPageSize = 30
)

// ---- feed ---------------------------------------------------------------------------

type feedReq struct {
	Sort         string `json:"-" query:"sort" validate:"omitempty,oneof=trending new solved"`
	Category     string `json:"-" query:"category" validate:"omitempty,oneof=academic hostel transport facilities safety administration food it other"`
	Q            string `json:"-" query:"q" validate:"max=100"`
	Cursor       string `json:"-" query:"cursor" validate:"max=200"`
	Private      string `json:"-" query:"private" validate:"omitempty,oneof=true false"`
	UniversityID string `json:"-" query:"universityId" validate:"omitempty,uuid"`
}

func (s *Service) handleFeed(ctx context.Context, in *feedReq) (*Page[IssueCard], error) {
	q := store.New(s.d.Q(ctx))
	v, err := s.begin(ctx, q)
	if err != nil {
		return nil, err
	}
	uni := v.uni
	if in.UniversityID != "" && v.isMod() {
		uni = uuid.MustParse(in.UniversityID)
	}
	if uni == uuid.Nil {
		return nil, ErrUniversityRequired
	}
	if v.role == RoleModerator && !v.modOf(uni) {
		return nil, ErrForbidden
	}
	// Private (safety) issues: the university's authorities and moderators.
	private := in.Private == "true" && (v.authorityOf(uni) || v.isMod())
	search := strings.TrimSpace(in.Q)
	out := &Page[IssueCard]{Items: []IssueCard{}}
	now := s.now()
	var rows []store.GetIssueRow
	switch in.Sort {
	case "new":
		at, id, err := parseKeyCursor(in.Cursor)
		if err != nil {
			return nil, err
		}
		rs, err := q.FeedNew(ctx, store.FeedNewParams{Viewer: v.id, UniversityID: uni, Private: private,
			Category: in.Category, Q: search, QLike: like(search), BeforeAt: at, BeforeID: id, Lim: feedPageSize})
		if err != nil {
			return nil, err
		}
		for _, r := range rs {
			rows = append(rows, store.GetIssueRow(r))
		}
		if len(rows) == feedPageSize {
			last := rows[len(rows)-1]
			c := keyCursor(last.CreatedAt, last.ID)
			out.NextCursor = &c
		}
	case "solved":
		at, id, err := parseKeyCursor(in.Cursor)
		if err != nil {
			return nil, err
		}
		rs, err := q.FeedSolved(ctx, store.FeedSolvedParams{Viewer: v.id, UniversityID: uni, Private: private,
			Category: in.Category, Q: search, QLike: like(search), BeforeAt: at, BeforeID: id, Lim: feedPageSize})
		if err != nil {
			return nil, err
		}
		for _, r := range rs {
			rows = append(rows, store.GetIssueRow(r))
		}
		if len(rows) == feedPageSize && rows[len(rows)-1].SolvedAt != nil {
			last := rows[len(rows)-1]
			c := keyCursor(*last.SolvedAt, last.ID)
			out.NextCursor = &c
		}
	default: // trending
		off, err := parseOffsetCursor(in.Cursor)
		if err != nil {
			return nil, err
		}
		if off >= feedPageSize*trendingPages {
			return out, nil
		}
		rs, err := q.FeedTrending(ctx, store.FeedTrendingParams{Viewer: v.id,
			NowEpoch: float64(now.UnixNano()) / 1e9, UniversityID: uni, Private: private,
			Since: now.Add(-trendingDays * 24 * time.Hour), Category: in.Category, Q: search, QLike: like(search),
			Off: int32(off), Lim: feedPageSize})
		if err != nil {
			return nil, err
		}
		for _, r := range rs {
			rows = append(rows, store.GetIssueRow(r))
		}
		if len(rows) == feedPageSize && off+feedPageSize < feedPageSize*trendingPages {
			c := offsetCursor(off + feedPageSize)
			out.NextCursor = &c
		}
	}
	for _, r := range rows {
		out.Items = append(out.Items, cardView(v, r))
	}
	return out, nil
}

type similarReq struct {
	Q string `json:"-" query:"q" validate:"required,min=8,max=120"`
}

type cardsRes struct {
	Items []IssueCard `json:"items"`
}

func (s *Service) handleSimilar(ctx context.Context, in *similarReq) (*cardsRes, error) {
	q := store.New(s.d.Q(ctx))
	v, err := s.begin(ctx, q)
	if err != nil {
		return nil, err
	}
	if v.uni == uuid.Nil {
		return nil, ErrUniversityRequired
	}
	rs, err := q.SimilarIssues(ctx, store.SimilarIssuesParams{Viewer: v.id, UniversityID: v.uni,
		Since: s.now().Add(-similarDays * 24 * time.Hour), Q: strings.TrimSpace(in.Q)})
	if err != nil {
		return nil, err
	}
	out := &cardsRes{Items: []IssueCard{}}
	for _, r := range rs {
		out.Items = append(out.Items, cardView(v, store.GetIssueRow(r)))
	}
	return out, nil
}

type myIssuesReq struct {
	Cursor string `json:"-" query:"cursor" validate:"max=200"`
}

func (s *Service) handleMyIssues(ctx context.Context, in *myIssuesReq) (*Page[IssueCard], error) {
	q := store.New(s.d.Q(ctx))
	v, err := s.begin(ctx, q)
	if err != nil {
		return nil, err
	}
	at, id, err := parseKeyCursor(in.Cursor)
	if err != nil {
		return nil, err
	}
	rs, err := q.MyIssues(ctx, store.MyIssuesParams{Viewer: v.id, BeforeAt: at, BeforeID: id, Lim: feedPageSize})
	if err != nil {
		return nil, err
	}
	out := &Page[IssueCard]{Items: []IssueCard{}}
	for _, r := range rs {
		out.Items = append(out.Items, cardView(v, store.GetIssueRow(r)))
	}
	if len(rs) == feedPageSize {
		last := rs[len(rs)-1]
		c := keyCursor(last.CreatedAt, last.ID)
		out.NextCursor = &c
	}
	return out, nil
}

// ---- one issue ------------------------------------------------------------------------

type issueReq struct {
	ID string `json:"-" path:"id" validate:"required,uuid"`
}

func (s *Service) handleGet(ctx context.Context, in *issueReq) (*Issue, error) {
	q := store.New(s.d.Q(ctx))
	v, err := s.begin(ctx, q)
	if err != nil {
		return nil, err
	}
	r, err := s.getIssue(ctx, q, v, uuid.MustParse(in.ID))
	if err != nil {
		return nil, err
	}
	return s.detail(ctx, q, v, r)
}

// detail loads images and the timeline for an issue the viewer may see.
func (s *Service) detail(ctx context.Context, q *store.Queries, v viewer, r store.GetIssueRow) (*Issue, error) {
	imgs, err := q.IssueImages(ctx, r.ID)
	if err != nil {
		return nil, err
	}
	images := make([]Image, 0, len(imgs))
	for _, im := range imgs {
		images = append(images, Image{ID: im.ID, Width: int(im.Width), Height: int(im.Height)})
	}
	tl, err := q.Timeline(ctx, r.ID)
	if err != nil {
		return nil, err
	}
	timeline := make([]TimelineEntry, 0, len(tl))
	for _, t := range tl {
		timeline = append(timeline, TimelineEntry{From: t.FromStatus, To: t.ToStatus, ActorKind: t.ActorKind,
			ActorTitle: t.ActorTitle, Note: t.Note, CreatedAt: t.CreatedAt.UTC()})
	}
	out := s.issueView(v, r, images, timeline)
	return &out, nil
}

// reload re-reads an issue after a change (inside the same transaction).
func (s *Service) reload(ctx context.Context, q *store.Queries, v viewer, id uuid.UUID) (*Issue, error) {
	r, err := q.GetIssue(ctx, store.GetIssueParams{ID: id, Viewer: v.id})
	if err != nil {
		return nil, err
	}
	return s.detail(ctx, q, v, r)
}

// ---- post / edit / delete ------------------------------------------------------------------

type IssueInput struct {
	Category      string   `json:"category" validate:"required,oneof=academic hostel transport facilities safety administration food it other"`
	Title         string   `json:"title" validate:"required"`
	Body          string   `json:"body" validate:"required"`
	LocationLabel string   `json:"locationLabel"`
	Anonymous     *bool    `json:"anonymous"`
	ImageIDs      []string `json:"imageIds" validate:"max=4,dive,uuid"`
}

func cleanText(s string) string { return strings.TrimSpace(s) }

func checkLengths(title, body, place string) error {
	bad := map[string]string{}
	if n := utf8.RuneCountInString(title); n < 8 || n > 120 {
		bad["title"] = "must be 8 to 120 characters"
	}
	if n := utf8.RuneCountInString(body); n < 20 || n > 3000 {
		bad["body"] = "must be 20 to 3000 characters"
	}
	if utf8.RuneCountInString(place) > 80 {
		bad["locationLabel"] = "must be at most 80 characters"
	}
	if len(bad) > 0 {
		return apperr.Validation(bad)
	}
	return nil
}

func (s *Service) handleCreate(ctx context.Context, in *IssueInput) (*Issue, error) {
	in.Title, in.Body, in.LocationLabel = cleanText(in.Title), cleanText(in.Body), cleanText(in.LocationLabel)
	if err := checkLengths(in.Title, in.Body, in.LocationLabel); err != nil {
		return nil, err
	}
	ids := make([]uuid.UUID, 0, len(in.ImageIDs))
	for _, raw := range in.ImageIDs {
		id := uuid.MustParse(raw)
		if slices.Contains(ids, id) {
			return nil, apperr.Validation(map[string]string{"imageIds": "has the same photo twice"})
		}
		ids = append(ids, id)
	}
	anonymous := in.Anonymous == nil || *in.Anonymous
	var out *Issue
	err := s.d.InTx(ctx, func(ctx context.Context) error {
		q := store.New(s.d.Q(ctx))
		v, err := s.begin(ctx, q)
		if err != nil {
			return err
		}
		if v.uni == uuid.Nil {
			return ErrUniversityRequired
		}
		if err := s.requireNoBan(ctx, q, v); err != nil {
			return err
		}
		visibility, hold := "visible", checkText(in.Title, in.Body, in.LocationLabel)
		if hold == "" && !v.verified && !v.isStaff() {
			hold = HoldUnverified
		}
		// A flagged photo (or one the checker couldn't see) holds the issue
		// for a moderator; the photo reason wins over "unverified".
		for _, upID := range ids {
			up, err := q.GetUpload(ctx, store.GetUploadParams{ID: upID, UserID: v.id})
			if db.IsNoRows(err) {
				return ErrUploadNotFound.WithDetails(map[string]string{"imageId": upID.String()})
			}
			if err != nil {
				return err
			}
			if up.Flagged && (hold == "" || hold == HoldUnverified || hold == HoldPhotoCheckUnavailable) {
				hold = HoldPhotoCheck
				if up.NsfwScore == nil {
					hold = HoldPhotoCheckUnavailable
				}
			}
		}
		if hold != "" {
			visibility = "held"
		}
		params := store.CreateIssueParams{
			UniversityID: v.uni, Category: in.Category, Private: in.Category == "safety", Title: in.Title,
			Body: in.Body, LocationLabel: in.LocationLabel, Visibility: visibility, HoldReason: hold, Named: !anonymous,
			Now: s.now(),
		}
		if !anonymous {
			params.NamedAuthorID = &v.id
		}
		id, err := q.CreateIssue(ctx, params)
		if err != nil {
			return err
		}
		if err := q.InsertIssueAuthor(ctx, store.InsertIssueAuthorParams{IssueID: id, UserID: v.id}); err != nil {
			return err
		}
		if err := q.Follow(ctx, store.FollowParams{IssueID: id, UserID: v.id}); err != nil {
			return err
		}
		for pos, upID := range ids {
			up, err := q.TakeUpload(ctx, store.TakeUploadParams{ID: upID, UserID: v.id})
			if db.IsNoRows(err) {
				return ErrUploadNotFound.WithDetails(map[string]string{"imageId": upID.String()})
			}
			if err != nil {
				return err
			}
			if err := q.InsertIssueImage(ctx, store.InsertIssueImageParams{ID: up.ID, IssueID: id, Position: int16(pos),
				FullKey: up.FullKey, ThumbKey: up.ThumbKey, Width: up.Width, Height: up.Height,
				NsfwScore: up.NsfwScore, Flagged: up.Flagged}); err != nil {
				return err
			}
			if err := q.DeleteUpload(ctx, up.ID); err != nil {
				return err
			}
		}
		out, err = s.reload(ctx, q, v, id)
		return err
	})
	return out, err
}

type patchReq struct {
	ID            string  `json:"-" path:"id" validate:"required,uuid"`
	Title         *string `json:"title"`
	Body          *string `json:"body"`
	LocationLabel *string `json:"locationLabel"`
}

func (s *Service) handlePatch(ctx context.Context, in *patchReq) (*Issue, error) {
	var out *Issue
	err := s.d.InTx(ctx, func(ctx context.Context) error {
		q := store.New(s.d.Q(ctx))
		v, err := s.begin(ctx, q)
		if err != nil {
			return err
		}
		id := uuid.MustParse(in.ID)
		cur, err := s.ownIssue(ctx, q, v, id)
		if err != nil {
			return err
		}
		if cur.Visibility == "removed" || s.now().Sub(cur.CreatedAt) >= EditWindow {
			return ErrEditWindowClosed
		}
		if err := s.requireNoBan(ctx, q, v); err != nil {
			return err
		}
		title, body, place := cur.Title, cur.Body, cur.LocationLabel
		if in.Title != nil {
			title = cleanText(*in.Title)
		}
		if in.Body != nil {
			body = cleanText(*in.Body)
		}
		if in.LocationLabel != nil {
			place = cleanText(*in.LocationLabel)
		}
		if err := checkLengths(title, body, place); err != nil {
			return err
		}
		visibility, hold := cur.Visibility, cur.HoldReason
		if h := checkText(title, body, place); h != "" && cur.Visibility == "visible" {
			visibility, hold = "held", h
		}
		if err := q.UpdateIssueText(ctx, store.UpdateIssueTextParams{ID: id, Title: title, Body: body,
			LocationLabel: place, Now: s.now(), Visibility: visibility, HoldReason: hold}); err != nil {
			return err
		}
		out, err = s.reload(ctx, q, v, id)
		return err
	})
	return out, err
}

// ownIssue locks an issue the caller wrote (ISSUE_NOT_FOUND otherwise).
func (s *Service) ownIssue(ctx context.Context, q *store.Queries, v viewer, id uuid.UUID) (store.Issue, error) {
	mine, err := q.IsIssueAuthor(ctx, store.IsIssueAuthorParams{IssueID: id, Viewer: v.id})
	if err != nil {
		return store.Issue{}, err
	}
	if !mine {
		return store.Issue{}, ErrIssueNotFound
	}
	return q.LockIssue(ctx, id)
}

func (s *Service) handleDelete(ctx context.Context, in *issueReq) (*httpx.Empty, error) {
	return nil, s.d.InTx(ctx, func(ctx context.Context) error {
		q := store.New(s.d.Q(ctx))
		v, err := s.begin(ctx, q)
		if err != nil {
			return err
		}
		cur, err := s.ownIssue(ctx, q, v, uuid.MustParse(in.ID))
		if err != nil {
			return err
		}
		if cur.Visibility == "removed" {
			return nil
		}
		return q.SetIssueVisibility(ctx, store.SetIssueVisibilityParams{ID: cur.ID, Visibility: "removed",
			HoldReason: cur.HoldReason, RemovedReason: cur.RemovedReason, DeletedByAuthor: true})
	})
}

// ---- me too / follow ----------------------------------------------------------------------

type voteRes struct {
	MeTooCount int  `json:"meTooCount"`
	Voted      bool `json:"voted"`
}

func (s *Service) handleVote(ctx context.Context, in *issueReq) (*voteRes, error) {
	return s.vote(ctx, in, true)
}

func (s *Service) handleUnvote(ctx context.Context, in *issueReq) (*voteRes, error) {
	return s.vote(ctx, in, false)
}

func (s *Service) vote(ctx context.Context, in *issueReq, on bool) (*voteRes, error) {
	var out *voteRes
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
		if err := s.requireNoBan(ctx, q, v); err != nil {
			return err
		}
		if r.Mine {
			return ErrCannotVoteOwn
		}
		if r.Visibility != "visible" {
			return ErrIssueClosed
		}
		var n int64
		delta := int32(0)
		if on {
			if n, err = q.Vote(ctx, store.VoteParams{IssueID: id, UserID: v.id}); err != nil {
				return err
			}
			delta = int32(n)
			if err := q.Follow(ctx, store.FollowParams{IssueID: id, UserID: v.id}); err != nil {
				return err
			}
		} else {
			if n, err = q.Unvote(ctx, store.UnvoteParams{IssueID: id, UserID: v.id}); err != nil {
				return err
			}
			delta = -int32(n)
		}
		counts, err := q.AdjustIssueCounts(ctx, store.AdjustIssueCountsParams{ID: id, MeToo: delta})
		if err != nil {
			return err
		}
		out = &voteRes{MeTooCount: int(counts.MeTooCount), Voted: on}
		return nil
	})
	return out, err
}

type followRes struct {
	Following bool `json:"following"`
}

func (s *Service) handleFollow(ctx context.Context, in *issueReq) (*followRes, error) {
	return s.follow(ctx, in, true)
}

func (s *Service) handleUnfollow(ctx context.Context, in *issueReq) (*followRes, error) {
	return s.follow(ctx, in, false)
}

func (s *Service) follow(ctx context.Context, in *issueReq, on bool) (*followRes, error) {
	q := store.New(s.d.Q(ctx))
	v, err := s.begin(ctx, q)
	if err != nil {
		return nil, err
	}
	id := uuid.MustParse(in.ID)
	if _, err := s.getIssue(ctx, q, v, id); err != nil {
		return nil, err
	}
	if on {
		err = q.Follow(ctx, store.FollowParams{IssueID: id, UserID: v.id})
	} else {
		err = q.Unfollow(ctx, store.UnfollowParams{IssueID: id, UserID: v.id})
	}
	if err != nil {
		return nil, err
	}
	return &followRes{Following: on}, nil
}

// ---- reopen ------------------------------------------------------------------------------------

type noteReq struct {
	ID   string `json:"-" path:"id" validate:"required,uuid"`
	Note string `json:"note" validate:"required,max=500"`
}

func (s *Service) handleReopen(ctx context.Context, in *noteReq) (*Issue, error) {
	note := cleanText(in.Note)
	if note == "" {
		return nil, apperr.Validation(map[string]string{"note": "is required"})
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
		cur, err := s.ownIssue(ctx, q, v, uuid.MustParse(in.ID))
		if err != nil {
			return err
		}
		now := s.now()
		if cur.Status != "solved" || cur.SolvedAt == nil || now.Sub(*cur.SolvedAt) >= ReopenWindow || cur.Visibility == "removed" {
			return ErrReopenNotAllowed
		}
		if err := q.SetIssueStatus(ctx, store.SetIssueStatusParams{ID: cur.ID, Status: "open", Now: now}); err != nil {
			return err
		}
		if err := q.InsertStatusUpdate(ctx, store.InsertStatusUpdateParams{IssueID: cur.ID, ActorKind: "author",
			FromStatus: "solved", ToStatus: "open", Note: note, Now: now}); err != nil {
			return err
		}
		notice, err = s.statusNotice(ctx, q, cur, "open", v.id)
		if err != nil {
			return err
		}
		out, err = s.reload(ctx, q, v, cur.ID)
		return err
	})
	if err == nil {
		s.send(notice)
	}
	return out, err
}
