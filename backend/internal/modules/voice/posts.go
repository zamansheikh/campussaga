package voice

import (
	"context"
	"slices"
	"strings"
	"time"
	"unicode/utf8"

	"github.com/google/uuid"

	"github.com/zamansheikh/varsitykotha/backend/internal/modules/voice/store"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/apperr"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/db"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/httpx"
)

// Posts of every kind (docs/CAMPUS_SOCIAL.md §1): create, edit, react, poll.

func cleanText(s string) string { return strings.TrimSpace(s) }

type IssueInput struct {
	Kind          string   `json:"kind" validate:"omitempty,oneof=issue post question poll"`
	Category      string   `json:"category" validate:"omitempty,oneof=academic hostel transport facilities safety administration food it other general event lost_found buy_sell fun"`
	Title         string   `json:"title"`
	Body          string   `json:"body"`
	LocationLabel string   `json:"locationLabel"`
	Anonymous     *bool    `json:"anonymous"`
	ImageIDs      []string `json:"imageIds" validate:"max=4,dive,uuid"`
	PollOptions   []string `json:"pollOptions"`
	PollDays      int      `json:"pollDays"`
	// CampusOnly keeps a post, question or poll inside the university (ignored for issues).
	CampusOnly bool `json:"campusOnly"`
}

// checkLengths applies the rules of the post's kind. images is the number
// of photos (a post may have no text when it has a photo).
func checkLengths(kind, title, body, place string, images int) error {
	bad := map[string]string{}
	bodyLen := utf8.RuneCountInString(body)
	if kind == "issue" {
		if n := utf8.RuneCountInString(title); n < 8 || n > 120 {
			bad["title"] = "must be 8 to 120 characters"
		}
		if bodyLen < 20 || bodyLen > 3000 {
			bad["body"] = "must be 20 to 3000 characters"
		}
	} else {
		if title != "" {
			bad["title"] = "must be empty"
		}
		switch kind {
		case "post":
			if bodyLen > 3000 {
				bad["body"] = "must be at most 3000 characters"
			} else if bodyLen == 0 && images == 0 {
				bad["body"] = "write something or add a photo"
			}
		case "question":
			if bodyLen < 8 || bodyLen > 3000 {
				bad["body"] = "must be 8 to 3000 characters"
			}
		case "poll":
			if bodyLen < 4 || bodyLen > 300 {
				bad["body"] = "must be 4 to 300 characters"
			}
		}
	}
	if utf8.RuneCountInString(place) > 80 {
		bad["locationLabel"] = "must be at most 80 characters"
	}
	if len(bad) > 0 {
		return apperr.Validation(bad)
	}
	return nil
}

// checkPollOptions: 2 to 4 options of 1 to 80 characters, unique ignoring case.
func checkPollOptions(raw []string) ([]string, error) {
	opts := make([]string, 0, len(raw))
	for _, o := range raw {
		opts = append(opts, cleanText(o))
	}
	if len(opts) < 2 || len(opts) > 4 {
		return nil, apperr.Validation(map[string]string{"pollOptions": "must have 2 to 4 options"})
	}
	seen := map[string]bool{}
	for _, o := range opts {
		if n := utf8.RuneCountInString(o); n < 1 || n > 80 {
			return nil, apperr.Validation(map[string]string{"pollOptions": "each option must be 1 to 80 characters"})
		}
		k := strings.ToLower(o)
		if seen[k] {
			return nil, apperr.Validation(map[string]string{"pollOptions": "options must be different"})
		}
		seen[k] = true
	}
	return opts, nil
}

func (s *Service) handleCreate(ctx context.Context, in *IssueInput) (*Issue, error) {
	in.Title, in.Body, in.LocationLabel = cleanText(in.Title), cleanText(in.Body), cleanText(in.LocationLabel)
	kind := in.Kind
	if kind == "" {
		kind = "issue"
	}
	category := in.Category
	switch {
	case kind == "issue" && category == "":
		return nil, apperr.Validation(map[string]string{"category": "is required"})
	case kind == "issue" && !slices.Contains(issueCategories, category):
		return nil, apperr.Validation(map[string]string{"category": "is not an issue category"})
	case kind != "issue" && category == "":
		category = "general"
	case kind != "issue" && !slices.Contains(socialCategories, category):
		return nil, apperr.Validation(map[string]string{"category": "is not available for this kind"})
	}
	ids := make([]uuid.UUID, 0, len(in.ImageIDs))
	for _, raw := range in.ImageIDs {
		id := uuid.MustParse(raw)
		if slices.Contains(ids, id) {
			return nil, apperr.Validation(map[string]string{"imageIds": "has the same photo twice"})
		}
		ids = append(ids, id)
	}
	if err := checkLengths(kind, in.Title, in.Body, in.LocationLabel, len(ids)); err != nil {
		return nil, err
	}
	var (
		options []string
		days    = in.PollDays
	)
	if kind == "poll" {
		var err error
		if options, err = checkPollOptions(in.PollOptions); err != nil {
			return nil, err
		}
		if days == 0 {
			days = 3
		}
		if days != 1 && days != 3 && days != 7 {
			return nil, apperr.Validation(map[string]string{"pollDays": "must be 1, 3 or 7"})
		}
	} else if len(in.PollOptions) > 0 || in.PollDays != 0 {
		return nil, apperr.Validation(map[string]string{"pollOptions": "only polls have options"})
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
		now := s.now()
		if kind == "issue" {
			// The route limit covers every kind; issues have their own, lower one.
			n, err := q.CountMyIssuesSince(ctx, store.CountMyIssuesSinceParams{Viewer: v.id, Since: now.Add(-24 * time.Hour)})
			if err != nil {
				return err
			}
			if n >= issuesPerDay {
				return httpx.ErrTooManyRequests
			}
		}
		parts := append([]string{in.Title, in.Body, in.LocationLabel}, options...)
		visibility, hold := "visible", checkText(parts...)
		if hold == "" && !v.verified && !v.isStaff() {
			hold = HoldUnverified
		}
		// A flagged photo (or one the checker couldn't see) holds the post
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
			UniversityID: v.uni, Kind: kind, Category: category, Private: category == "safety", Title: in.Title,
			Body: in.Body, LocationLabel: in.LocationLabel, Visibility: visibility, HoldReason: hold, Named: !anonymous,
			CampusOnly: in.CampusOnly && kind != "issue", Now: now,
		}
		if !anonymous {
			params.NamedAuthorID = &v.id
		}
		if kind == "poll" {
			closes := now.Add(time.Duration(days) * 24 * time.Hour)
			params.PollClosesAt = &closes
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
		for pos, label := range options {
			if err := q.InsertPollOption(ctx, store.InsertPollOptionParams{IssueID: id, Position: int16(pos), Label: label}); err != nil {
				return err
			}
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
			if cur.Kind != "issue" && title == "" {
				title = cur.Title // "" stays ""
			}
		}
		if in.Body != nil {
			body = cleanText(*in.Body)
		}
		if in.LocationLabel != nil {
			place = cleanText(*in.LocationLabel)
		}
		imgs, err := q.IssueImages(ctx, id)
		if err != nil {
			return err
		}
		if err := checkLengths(cur.Kind, title, body, place, len(imgs)); err != nil {
			return err
		}
		parts := []string{title, body, place}
		if cur.Kind == "poll" {
			labels, err := q.PollLabels(ctx, id)
			if err != nil {
				return err
			}
			parts = append(parts, labels...)
		}
		visibility, hold := cur.Visibility, cur.HoldReason
		if h := checkText(parts...); h != "" && cur.Visibility == "visible" {
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

// ---- reactions (me too) -------------------------------------------------------------------

type voteReq struct {
	ID       string `json:"-" path:"id" validate:"required,uuid"`
	Reaction string `json:"reaction" validate:"omitempty,oneof=me_too like haha wow sad clap"`
}

type voteRes struct {
	MeTooCount int            `json:"meTooCount"`
	Voted      bool           `json:"voted"`
	Reactions  map[string]int `json:"reactions"`
	MyReaction *string        `json:"myReaction"`
}

func (s *Service) handleVote(ctx context.Context, in *voteReq) (*voteRes, error) {
	return s.vote(ctx, in, true)
}

func (s *Service) handleUnvote(ctx context.Context, in *voteReq) (*voteRes, error) {
	return s.vote(ctx, in, false)
}

func (s *Service) vote(ctx context.Context, in *voteReq, on bool) (*voteRes, error) {
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
		if r.Mine && r.Kind == "issue" {
			return ErrCannotVoteOwn
		}
		if r.Visibility != "visible" {
			return ErrIssueClosed
		}
		// Issues have "me too" only (any reaction sent is ignored); the
		// other kinds default to a like.
		reaction := "me_too"
		if r.Kind != "issue" {
			if reaction = in.Reaction; reaction == "" || reaction == "me_too" {
				reaction = "like"
			}
		}
		var delta int32
		if on {
			n, err := q.Vote(ctx, store.VoteParams{IssueID: id, UserID: v.id, Reaction: reaction})
			if err != nil {
				return err
			}
			if n == 0 { // already reacted: change it
				if err := q.SetReaction(ctx, store.SetReactionParams{IssueID: id, UserID: v.id, Reaction: reaction}); err != nil {
					return err
				}
			}
			delta = int32(n)
			if !isVisitor(v, r) { // visitors follow nothing (no pushes)
				if err := q.Follow(ctx, store.FollowParams{IssueID: id, UserID: v.id}); err != nil {
					return err
				}
			}
		} else {
			n, err := q.Unvote(ctx, store.UnvoteParams{IssueID: id, UserID: v.id})
			if err != nil {
				return err
			}
			delta = -int32(n)
		}
		counts, err := q.AdjustIssueCounts(ctx, store.AdjustIssueCountsParams{ID: id, MeToo: delta})
		if err != nil {
			return err
		}
		rows, err := q.ReactionCounts(ctx, id)
		if err != nil {
			return err
		}
		out = &voteRes{MeTooCount: int(counts.MeTooCount), Voted: on, Reactions: map[string]int{}}
		for _, rc := range rows {
			out.Reactions[rc.Reaction] = int(rc.N)
		}
		if on {
			out.MyReaction = &reaction
		}
		return nil
	})
	return out, err
}

// ---- poll votes ---------------------------------------------------------------------------------

type pollVoteReq struct {
	ID       string `json:"-" path:"id" validate:"required,uuid"`
	OptionID string `json:"optionId" validate:"required,uuid"`
}

// handlePollVote: one vote per person, it can't be changed. Counts only.
func (s *Service) handlePollVote(ctx context.Context, in *pollVoteReq) (*Poll, error) {
	var out *Poll
	err := s.d.InTx(ctx, func(ctx context.Context) error {
		q := store.New(s.d.Q(ctx))
		v, err := s.begin(ctx, q)
		if err != nil {
			return err
		}
		id := uuid.MustParse(in.ID)
		r, err := s.getIssueWrite(ctx, q, v, id)
		if err != nil {
			return err
		}
		if err := s.requireNoBan(ctx, q, v); err != nil {
			return err
		}
		if r.Kind != "poll" || r.PollClosesAt == nil || !s.now().Before(*r.PollClosesAt) {
			return ErrPollClosed
		}
		if r.Visibility != "visible" {
			return ErrIssueClosed
		}
		if _, err := q.LockIssue(ctx, id); err != nil { // one vote at a time per poll
			return err
		}
		if _, err := q.MyPollVote(ctx, store.MyPollVoteParams{IssueID: id, Viewer: v.id}); err == nil {
			return ErrAlreadyVoted
		} else if !db.IsNoRows(err) {
			return err
		}
		opt := uuid.MustParse(in.OptionID)
		if _, err := q.PollOptionOf(ctx, store.PollOptionOfParams{ID: opt, IssueID: id}); db.IsNoRows(err) {
			return apperr.Validation(map[string]string{"optionId": "is not an option of this poll"})
		} else if err != nil {
			return err
		}
		if err := q.InsertPollVote(ctx, store.InsertPollVoteParams{IssueID: id, UserID: v.id, OptionID: opt}); err != nil {
			return err
		}
		if err := q.BumpPollOption(ctx, opt); err != nil {
			return err
		}
		row, err := q.GetIssue(ctx, store.GetIssueParams{ID: id, Viewer: v.id})
		if err != nil {
			return err
		}
		out = pollView(v, row, s.now())
		return nil
	})
	return out, err
}
