package admin

import (
	"context"
	"encoding/json"
	"strings"
	"time"
	"unicode"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"

	"github.com/zamansheikh/varsitykotha/backend/internal/modules/admin/store"
	"github.com/zamansheikh/varsitykotha/backend/internal/modules/blood"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/db"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/httpx"
)

// ---- dashboard ----------------------------------------------------------------

type Stats struct {
	Users struct {
		Total        int `json:"total"`
		Verified     int `json:"verified"`
		NotVerified  int `json:"notVerified"`
		Admins       int `json:"admins"`
		Blocked      int `json:"blocked"`
		NewLast7Days int `json:"newLast7Days"`
	} `json:"users"`
	Groups struct {
		Total         int `json:"total"`
		Memberships   int `json:"memberships"`
		Slots         int `json:"slots"`
		Announcements int `json:"announcements"`
	} `json:"groups"`
	Devices struct {
		Android int `json:"android"`
		IOS     int `json:"ios"`
	} `json:"devices"`
	Universities struct {
		Active int `json:"active"`
		Total  int `json:"total"`
	} `json:"universities"`
	// Campus Voice: counts only.
	Voice struct {
		Open            int `json:"open"`
		Solved          int `json:"solved"`
		Held            int `json:"held"`
		Reported        int `json:"reported"`
		IssuesLast7Days int `json:"issuesLast7Days"`
	} `json:"voice"`
	// Campus social, blood donation and live buses: counts only.
	Campus struct {
		PostsLast7Days     map[string]int `json:"postsLast7Days"`
		CommentsLast7Days  int            `json:"commentsLast7Days"`
		ReactionsLast7Days int            `json:"reactionsLast7Days"`
	} `json:"campus"`
	Blood struct {
		Donors             int `json:"donors"`
		Available          int `json:"available"`
		OpenRequests       int `json:"openRequests"`
		RequestsLast7Days  int `json:"requestsLast7Days"`
		ResponsesLast7Days int `json:"responsesLast7Days"`
	} `json:"blood"`
	Bus struct {
		LiveNow           int `json:"liveNow"`
		SharesLast7Days   int `json:"sharesLast7Days"`
		TripsShared       int `json:"tripsShared"`
		RatingsLast30Days int `json:"ratingsLast30Days"`
	} `json:"bus"`
	// Feedback: new = not opened yet, open = not done or declined.
	Feedback struct {
		New       int `json:"new"`
		Open      int `json:"open"`
		Last7Days int `json:"last7Days"`
	} `json:"feedback"`
	// Growth: invites and campaigns (docs/GROWTH.md), counts only.
	Growth struct {
		InvitesLast7Days   int `json:"invitesLast7Days"`
		QualifiedLast7Days int `json:"qualifiedLast7Days"`
		LiveCampaigns      int `json:"liveCampaigns"`
	} `json:"growth"`
	SignupsByDay    []DayCount      `json:"signupsByDay"`
	TopUniversities []UniversityUse `json:"topUniversities"`
}

type DayCount struct {
	Date  string `json:"date"`
	Count int    `json:"count"`
}

type UniversityUse struct {
	ID    uuid.UUID `json:"id"`
	Name  string    `json:"name"`
	Users int       `json:"users"`
}

func (s *Service) handleStats(ctx context.Context, _ *httpx.Empty) (*Stats, error) {
	q := store.New(s.d.Q(ctx))
	now := s.now()
	out := &Stats{SignupsByDay: []DayCount{}, TopUniversities: []UniversityUse{}}

	u, err := q.UserCounts(ctx, now.Add(-7*24*time.Hour))
	if err != nil {
		return nil, err
	}
	out.Users.Total, out.Users.Verified, out.Users.NotVerified = int(u.Total), int(u.Verified), int(u.NotVerified)
	out.Users.Admins, out.Users.Blocked, out.Users.NewLast7Days = int(u.Admins), int(u.Blocked), int(u.NewSince)

	o, err := q.OtherCounts(ctx)
	if err != nil {
		return nil, err
	}
	out.Groups.Total, out.Groups.Memberships = int(o.Groups), int(o.Memberships)
	out.Groups.Slots, out.Groups.Announcements = int(o.Slots), int(o.Announcements)
	out.Devices.Android, out.Devices.IOS = int(o.Android), int(o.Ios)
	out.Universities.Active, out.Universities.Total = int(o.UniversitiesActive), int(o.UniversitiesTotal)

	vc, err := q.VoiceCounts(ctx, now.Add(-7*24*time.Hour))
	if err != nil {
		return nil, err
	}
	out.Voice.Open, out.Voice.Solved, out.Voice.Held = int(vc.Open), int(vc.Solved), int(vc.Held)
	out.Voice.Reported, out.Voice.IssuesLast7Days = int(vc.Reported), int(vc.IssuesLast7Days)

	week := now.Add(-7 * 24 * time.Hour)
	cc, err := q.CampusCounts(ctx, week)
	if err != nil {
		return nil, err
	}
	out.Campus.PostsLast7Days = map[string]int{
		"issue": int(cc.Issues), "post": int(cc.Posts), "question": int(cc.Questions), "poll": int(cc.Polls),
	}
	out.Campus.CommentsLast7Days, out.Campus.ReactionsLast7Days = int(cc.Comments), int(cc.Reactions)

	bc, err := q.BloodCounts(ctx, store.BloodCountsParams{
		EligibleOn: pgtype.Date{Time: blood.EligibleOn(now), Valid: true}, OpenAfter: now.Add(-24 * time.Hour), Since: week,
	})
	if err != nil {
		return nil, err
	}
	out.Blood.Donors, out.Blood.Available, out.Blood.OpenRequests = int(bc.Donors), int(bc.Available), int(bc.OpenRequests)
	out.Blood.RequestsLast7Days, out.Blood.ResponsesLast7Days = int(bc.Requests), int(bc.Responses)

	bu, err := q.BusCounts(ctx, store.BusCountsParams{
		FreshSince: now.Add(-2 * time.Minute), Since: week, RatingsSince: now.Add(-30 * 24 * time.Hour),
	})
	if err != nil {
		return nil, err
	}
	out.Bus.LiveNow, out.Bus.SharesLast7Days = int(bu.LiveNow), int(bu.Shares)
	out.Bus.TripsShared, out.Bus.RatingsLast30Days = int(bu.TripsShared), int(bu.Ratings)

	if err := s.d.Q(ctx).QueryRow(ctx, `
		SELECT count(*) FILTER (WHERE status = 'new')::int,
		       count(*) FILTER (WHERE status IN ('new', 'seen', 'planned', 'in_progress'))::int,
		       count(*) FILTER (WHERE created_at >= $1)::int
		FROM feedback`, week).Scan(&out.Feedback.New, &out.Feedback.Open, &out.Feedback.Last7Days); err != nil {
		return nil, err
	}

	if err := s.d.Q(ctx).QueryRow(ctx, `
		SELECT (SELECT count(*) FROM referrals WHERE created_at >= $1)::int,
		       (SELECT count(*) FROM referrals WHERE qualified_at >= $1)::int,
		       (SELECT count(*) FROM campaigns WHERE status IN ('live', 'ended') AND starts_at <= $2 AND ends_at >= $2)::int`,
		week, now).Scan(&out.Growth.InvitesLast7Days, &out.Growth.QualifiedLast7Days, &out.Growth.LiveCampaigns); err != nil {
		return nil, err
	}

	today := bdToday(now)
	days, err := q.SignupsByDay(ctx, store.SignupsByDayParams{
		FirstDay: today.AddDate(0, 0, -29).Format(time.DateOnly), LastDay: today.Format(time.DateOnly),
	})
	if err != nil {
		return nil, err
	}
	for _, d := range days {
		out.SignupsByDay = append(out.SignupsByDay, DayCount{Date: d.Day, Count: int(d.Count)})
	}
	top, err := q.TopUniversities(ctx)
	if err != nil {
		return nil, err
	}
	for _, t := range top {
		out.TopUniversities = append(out.TopUniversities, UniversityUse{ID: t.ID, Name: t.Name, Users: int(t.Users)})
	}
	return out, nil
}

// ---- app settings ---------------------------------------------------------------

type ConfigItem struct {
	Key       string          `json:"key"`
	Value     json.RawMessage `json:"value"`
	UpdatedAt time.Time       `json:"updatedAt"`
}

type configRes struct {
	Items []ConfigItem `json:"items"`
}

func (s *Service) handleListConfig(ctx context.Context, _ *httpx.Empty) (*configRes, error) {
	rows, err := store.New(s.d.Q(ctx)).ListConfig(ctx)
	if err != nil {
		return nil, err
	}
	out := &configRes{Items: make([]ConfigItem, 0, len(rows))}
	for _, r := range rows {
		out.Items = append(out.Items, ConfigItem{Key: camel(r.Key), Value: r.Value, UpdatedAt: r.UpdatedAt})
	}
	return out, nil
}

type updateConfigReq struct {
	Key   string          `json:"-" path:"key" validate:"required,max=60"`
	Value json.RawMessage `json:"value" validate:"required"`
}

func (s *Service) handleUpdateConfig(ctx context.Context, in *updateConfigReq) (*ConfigItem, error) {
	if err := checkConfig(in.Key, in.Value); err != nil {
		return nil, err
	}
	var out *ConfigItem
	err := s.d.InTx(ctx, func(ctx context.Context) error {
		q := store.New(s.d.Q(ctx))
		r, err := q.UpdateConfig(ctx, store.UpdateConfigParams{Key: snake(in.Key), Value: in.Value})
		if db.IsNoRows(err) {
			return ErrConfigKey
		}
		if err != nil {
			return err
		}
		out = &ConfigItem{Key: camel(r.Key), Value: r.Value, UpdatedAt: r.UpdatedAt}
		return s.audit(ctx, q, "config.update", "config", out.Key, map[string]json.RawMessage{"value": in.Value})
	})
	return out, err
}

// checkConfig knows the shape of the settings the app reads.
func checkConfig(key string, v json.RawMessage) error {
	switch key {
	case "features":
		var flags map[string]bool
		if json.Unmarshal(v, &flags) != nil {
			return ErrConfigValue.WithMessage("Feature flags must be on/off switches")
		}
	case "minSupportedBuild":
		var n int
		if json.Unmarshal(v, &n) != nil || n < 1 {
			return ErrConfigValue.WithMessage("The minimum build must be a whole number of 1 or more")
		}
	default:
		if !json.Valid(v) {
			return ErrConfigValue
		}
	}
	return nil
}

func camel(s string) string {
	parts := strings.Split(s, "_")
	for i := 1; i < len(parts); i++ {
		if parts[i] != "" {
			parts[i] = strings.ToUpper(parts[i][:1]) + parts[i][1:]
		}
	}
	return strings.Join(parts, "")
}

func snake(s string) string {
	var b strings.Builder
	for _, r := range s {
		if unicode.IsUpper(r) {
			b.WriteByte('_')
			r = unicode.ToLower(r)
		}
		b.WriteRune(r)
	}
	return b.String()
}

// ---- push ------------------------------------------------------------------------

type pushReq struct {
	Target  string `json:"target" validate:"required,oneof=user all"`
	UserID  string `json:"userId" validate:"required_if=Target user,omitempty,uuid"`
	Title   string `json:"title" validate:"required,max=100"`
	Body    string `json:"body" validate:"required,max=500"`
	TitleBn string `json:"titleBn" validate:"max=100"`
	BodyBn  string `json:"bodyBn" validate:"max=500"`
}

type pushRes struct {
	Users   int `json:"users"`
	Devices int `json:"devices"`
}

func (s *Service) handlePush(ctx context.Context, in *pushReq) (*pushRes, error) {
	var (
		userID *uuid.UUID
		users  []uuid.UUID
	)
	q := store.New(s.d.Q(ctx))
	if in.Target == "user" {
		id := uuid.MustParse(in.UserID)
		if _, err := q.GetUser(ctx, id); db.IsNoRows(err) {
			return nil, ErrUserNotFound
		} else if err != nil {
			return nil, err
		}
		userID, users = &id, []uuid.UUID{id}
	} else {
		var err error
		if users, err = q.PushUsers(ctx); err != nil {
			return nil, err
		}
	}
	aud, err := q.PushAudience(ctx, userID)
	if err != nil {
		return nil, err
	}
	t := PushText{
		Title: strings.TrimSpace(in.Title), Body: strings.TrimSpace(in.Body),
		TitleBn: strings.TrimSpace(in.TitleBn), BodyBn: strings.TrimSpace(in.BodyBn),
	}
	if err := s.audit(ctx, q, "push.send", "push", in.Target, map[string]any{
		"userId": userID, "title": t.Title, "body": t.Body, "users": aud.Users, "devices": aud.Devices,
	}); err != nil {
		return nil, err
	}
	if aud.Devices > 0 {
		s.push(users, t)
	}
	return &pushRes{Users: int(aud.Users), Devices: int(aud.Devices)}, nil
}

// ---- audit log -------------------------------------------------------------------

type AuditEntry struct {
	ID         int64           `json:"id"`
	Actor      *Person         `json:"actor"`
	Action     string          `json:"action"`
	TargetType *string         `json:"targetType"`
	TargetID   *string         `json:"targetId"`
	Meta       json.RawMessage `json:"meta"`
	CreatedAt  time.Time       `json:"createdAt"`
}

type auditReq struct {
	Page
}

func (s *Service) handleAudit(ctx context.Context, in *auditReq) (*Paged[AuditEntry], error) {
	page, size, lim, off := in.limits()
	q := store.New(s.d.Q(ctx))
	rows, err := q.ListAudit(ctx, store.ListAuditParams{Lim: lim, Off: off})
	if err != nil {
		return nil, err
	}
	total, err := q.CountAudit(ctx)
	if err != nil {
		return nil, err
	}
	items := make([]AuditEntry, 0, len(rows))
	for _, r := range rows {
		e := AuditEntry{ID: r.ID, Action: r.Action, TargetType: r.TargetType, TargetID: r.TargetID, Meta: r.Meta, CreatedAt: r.CreatedAt}
		if r.ActorID != nil {
			e.Actor = &Person{ID: *r.ActorID, Name: r.ActorName}
			if r.ActorEmail != nil {
				e.Actor.Email = *r.ActorEmail
			}
		}
		items = append(items, e)
	}
	return &Paged[AuditEntry]{Items: items, Total: int(total), Page: page, PageSize: size}, nil
}
