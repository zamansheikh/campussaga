package voice

import (
	"context"
	"slices"
	"strings"
	"time"

	"github.com/google/uuid"

	"github.com/zamansheikh/varsitykotha/backend/internal/modules/voice/store"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/apperr"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/httpx"
)

// Issue categories; posts, questions and polls use every one but "safety"
// plus the social ones.
var issueCategories = []string{"academic", "hostel", "transport", "facilities", "safety", "administration", "food", "it", "other"}

var socialCategories = []string{"academic", "hostel", "transport", "facilities", "administration", "food", "it", "other",
	"general", "event", "lost_found", "buy_sell", "fun"}

var allKinds = []string{"issue", "post", "question", "poll"}

// issuesPerDay: issues (kind = issue) one person may post in 24 hours,
// inside the route limit for all kinds together.
const issuesPerDay = 5

// parseKinds: absent = issues only (apps before campus social), "all" = every kind.
func parseKinds(raw string) ([]string, error) {
	raw = strings.TrimSpace(raw)
	if raw == "" {
		return []string{"issue"}, nil
	}
	if raw == "all" {
		return allKinds, nil
	}
	var out []string
	for _, k := range strings.Split(raw, ",") {
		k = strings.TrimSpace(k)
		if !slices.Contains(allKinds, k) {
			return nil, apperr.Validation(map[string]string{"kinds": "must be issue, post, question, poll or all"})
		}
		if !slices.Contains(out, k) {
			out = append(out, k)
		}
	}
	return out, nil
}

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
	Category     string `json:"-" query:"category" validate:"omitempty,oneof=academic hostel transport facilities safety administration food it other general event lost_found buy_sell fun"`
	Kinds        string `json:"-" query:"kinds" validate:"max=60"`
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
	visitor := false
	if in.UniversityID != "" {
		target := uuid.MustParse(in.UniversityID)
		switch {
		case v.isMod():
			uni = target
		case !v.isStaff() && target != v.uni:
			// A student looking at another university (docs/CAMPUS_VISITS.md §3.2).
			if !v.visitOn {
				return nil, ErrFeatureDisabled
			}
			uni, visitor = target, true
		}
	}
	if uni == uuid.Nil {
		return nil, ErrUniversityRequired
	}
	if v.role == RoleModerator && !v.modOf(uni) {
		return nil, ErrForbidden
	}
	// Private (safety) issues: the university's authorities and moderators.
	private := in.Private == "true" && (v.authorityOf(uni) || v.isMod())
	kinds, err := parseKinds(in.Kinds)
	if err != nil {
		return nil, err
	}
	search := strings.TrimSpace(in.Q)
	out := &Page[IssueCard]{Items: []IssueCard{}}
	now := s.now()
	if visitor {
		// Issues never leave their university; the rest is public posts only.
		kinds = slices.DeleteFunc(slices.Clone(kinds), func(k string) bool { return k == "issue" })
		if len(kinds) == 0 || in.Sort == "solved" || in.Private == "true" {
			return out, nil
		}
	}
	var rows []store.GetIssueRow
	switch in.Sort {
	case "new":
		at, id, err := parseKeyCursor(in.Cursor)
		if err != nil {
			return nil, err
		}
		rs, err := q.FeedNew(ctx, store.FeedNewParams{Viewer: v.id, UniversityID: uni, Private: private,
			Kinds: kinds, Visitor: visitor, Category: in.Category, Q: search, QLike: like(search), BeforeAt: at, BeforeID: id, Lim: feedPageSize})
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
			Since: now.Add(-trendingDays * 24 * time.Hour), Kinds: kinds, Visitor: visitor, Category: in.Category, Q: search, QLike: like(search),
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
		out.Items = append(out.Items, cardView(v, r, now))
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
		out.Items = append(out.Items, cardView(v, store.GetIssueRow(r), s.now()))
	}
	return out, nil
}

type myIssuesReq struct {
	Cursor string `json:"-" query:"cursor" validate:"max=200"`
	Kinds  string `json:"-" query:"kinds" validate:"max=60"`
}

func (s *Service) handleMyIssues(ctx context.Context, in *myIssuesReq) (*Page[IssueCard], error) {
	q := store.New(s.d.Q(ctx))
	v, err := s.begin(ctx, q)
	if err != nil {
		return nil, err
	}
	kinds, err := parseKinds(in.Kinds)
	if err != nil {
		return nil, err
	}
	at, id, err := parseKeyCursor(in.Cursor)
	if err != nil {
		return nil, err
	}
	rs, err := q.MyIssues(ctx, store.MyIssuesParams{Viewer: v.id, Kinds: kinds, BeforeAt: at, BeforeID: id, Lim: feedPageSize})
	if err != nil {
		return nil, err
	}
	out := &Page[IssueCard]{Items: []IssueCard{}}
	for _, r := range rs {
		out.Items = append(out.Items, cardView(v, store.GetIssueRow(r), s.now()))
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

// detail loads the timeline for an issue the viewer may see.
func (s *Service) detail(ctx context.Context, q *store.Queries, v viewer, r store.GetIssueRow) (*Issue, error) {
	tl, err := q.Timeline(ctx, r.ID)
	if err != nil {
		return nil, err
	}
	timeline := make([]TimelineEntry, 0, len(tl))
	for _, t := range tl {
		timeline = append(timeline, TimelineEntry{From: t.FromStatus, To: t.ToStatus, ActorKind: t.ActorKind,
			ActorTitle: t.ActorTitle, Note: t.Note, CreatedAt: t.CreatedAt.UTC()})
	}
	out := s.issueView(v, r, timeline)
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

// ownIssue locks an issue the caller wrote (ISSUE_NOT_FOUND otherwise).
func (s *Service) ownIssue(ctx context.Context, q *store.Queries, v viewer, id uuid.UUID) (store.Issue, error) {
	mine, err := q.IsIssueAuthor(ctx, store.IsIssueAuthorParams{IssueID: id, Viewer: v.id})
	if err != nil {
		return store.Issue{}, err
	}
	if !mine {
		// A visitor who can read the post is told it is read-only.
		if _, err := s.getIssueWrite(ctx, q, v, id); err != nil {
			return store.Issue{}, err
		}
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
	if _, err := s.getIssueWrite(ctx, q, v, id); err != nil {
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
		if cur.Kind != "issue" {
			return ErrNotAnIssue
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
