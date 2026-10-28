package classgroups

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"

	"github.com/zamansheikh/campussaga/backend/internal/modules/classgroups/store"
	"github.com/zamansheikh/campussaga/backend/internal/platform/apperr"
	"github.com/zamansheikh/campussaga/backend/internal/platform/auth"
	"github.com/zamansheikh/campussaga/backend/internal/platform/db"
)

// MaxUpcomingAssessments caps the tests and deadlines ahead in one group.
const MaxUpcomingAssessments = 100

// Assessment is a test or deadline of a class group: a class test, quiz,
// assignment, lab report, presentation, mid or final exam.
type Assessment struct {
	ID          uuid.UUID `json:"id"`
	Kind        string    `json:"kind"`
	CourseCode  string    `json:"courseCode"`
	CourseTitle string    `json:"courseTitle"`
	Date        string    `json:"date"`
	// Start/End: "HH:MM" or null (no time). For an assignment, start is
	// the due time.
	Start     *string   `json:"start"`
	End       *string   `json:"end"`
	Room      string    `json:"room"`
	Topics    string    `json:"topics"`
	CreatedBy *Author   `json:"createdBy"`
	CanEdit   bool      `json:"canEdit"`
	UpdatedAt time.Time `json:"updatedAt"`
}

type Author struct {
	ID   uuid.UUID `json:"id"`
	Name *string   `json:"name"`
}

// AssessmentInput adds or changes a test or deadline.
type AssessmentInput struct {
	Kind        string `json:"kind" validate:"required,oneof=class_test quiz assignment lab_report presentation midterm final other"`
	CourseCode  string `json:"courseCode" validate:"required,max=20"`
	CourseTitle string `json:"courseTitle" validate:"max=100"`
	Date        string `json:"date" validate:"required"`
	Start       string `json:"start"`
	End         string `json:"end"`
	Room        string `json:"room" validate:"max=30"`
	Topics      string `json:"topics" validate:"max=500"`

	date             time.Time
	startMin, endMin *int16
}

var (
	ErrAssessmentNotFound = apperr.New(404, "ASSESSMENT_NOT_FOUND", "This test or deadline was not found")
	ErrNotAssessmentOwner = apperr.New(403, "NOT_ASSESSMENT_OWNER",
		"Only the student who added it or a CR can change it")
	ErrAssessmentLimit = apperr.New(409, "ASSESSMENT_LIMIT_REACHED",
		"This group already has the most upcoming tests and deadlines allowed")
)

func (in *AssessmentInput) clean(today time.Time) error {
	in.CourseCode, in.CourseTitle = clean(in.CourseCode), clean(in.CourseTitle)
	in.Room, in.Topics = clean(in.Room), clean(in.Topics)
	if err := required(map[string]string{"courseCode": in.CourseCode}); err != nil {
		return err
	}
	d, err := time.Parse("2006-01-02", in.Date)
	switch {
	case err != nil:
		return apperr.Validation(map[string]string{"date": "must be a date like 2026-10-28"})
	case d.Before(today):
		return apperr.Validation(map[string]string{"date": "must be today or later"})
	case d.After(today.AddDate(0, 0, MaxChangeDays)):
		return apperr.Validation(map[string]string{"date": "is too far ahead"})
	}
	in.date = d
	in.startMin, in.endMin = nil, nil
	if in.Start != "" {
		start, ok := parseClock(in.Start)
		if !ok {
			return apperr.Validation(map[string]string{"start": "must be a time like 09:30"})
		}
		in.startMin = &start
	}
	if in.End != "" {
		end, ok := parseClock(in.End)
		switch {
		case !ok:
			return apperr.Validation(map[string]string{"end": "must be a time like 10:45"})
		case in.startMin == nil:
			return apperr.Validation(map[string]string{"end": "needs a start time"})
		case end <= *in.startMin:
			return apperr.Validation(map[string]string{"end": "must be after start"})
		}
		in.endMin = &end
	}
	return nil
}

// AddAssessment adds a test or deadline (any member).
func (s *Service) AddAssessment(ctx context.Context, groupID uuid.UUID, in *AssessmentInput) (*Assessment, error) {
	c := auth.MustUser(ctx)
	today := s.today()
	if err := in.clean(today); err != nil {
		return nil, err
	}
	var out *Assessment
	err := s.d.InTx(ctx, func(ctx context.Context) error {
		q := store.New(s.d.Q(ctx))
		role, err := s.role(ctx, q, groupID, c.UserID)
		if err != nil {
			return err
		}
		n, err := q.CountUpcomingAssessments(ctx, store.CountUpcomingAssessmentsParams{GroupID: groupID, FromDate: today})
		if err != nil {
			return err
		}
		if n >= MaxUpcomingAssessments {
			return ErrAssessmentLimit
		}
		a, err := q.CreateAssessment(ctx, store.CreateAssessmentParams{
			GroupID: groupID, Kind: in.Kind, CourseCode: in.CourseCode, CourseTitle: in.CourseTitle,
			Date: in.date, StartsMin: in.startMin, EndsMin: in.endMin, Room: in.Room, Topics: in.Topics,
			CreatedBy: &c.UserID,
		})
		if err != nil {
			return err
		}
		name, err := q.UserName(ctx, c.UserID)
		if err != nil {
			return err
		}
		v := assessmentView(a, name, c.UserID, role)
		out = &v
		if err := q.TouchGroup(ctx, groupID); err != nil {
			return err
		}
		g, err := q.GetGroup(ctx, groupID)
		if err != nil {
			return err
		}
		return s.tellClassmates(ctx, q, groupID, c.UserID, s.assessmentNotice(g, a, nil, false))
	})
	return out, err
}

// UpdateAssessment changes one (the member who added it, or a CR).
func (s *Service) UpdateAssessment(ctx context.Context, groupID, id uuid.UUID, in *AssessmentInput) (*Assessment, error) {
	c := auth.MustUser(ctx)
	if err := in.clean(s.today()); err != nil {
		return nil, err
	}
	var out *Assessment
	err := s.d.InTx(ctx, func(ctx context.Context) error {
		q := store.New(s.d.Q(ctx))
		before, role, err := s.ownAssessment(ctx, q, groupID, id, c.UserID)
		if err != nil {
			return err
		}
		a, err := q.UpdateAssessment(ctx, store.UpdateAssessmentParams{
			ID: id, GroupID: groupID, Kind: in.Kind, CourseCode: in.CourseCode, CourseTitle: in.CourseTitle,
			Date: in.date, StartsMin: in.startMin, EndsMin: in.endMin, Room: in.Room, Topics: in.Topics,
		})
		if err != nil {
			return err
		}
		var name *string
		if a.CreatedBy != nil {
			if name, err = q.UserName(ctx, *a.CreatedBy); err != nil && !db.IsNoRows(err) {
				return err
			}
		}
		v := assessmentView(a, name, c.UserID, role)
		out = &v
		if err := q.TouchGroup(ctx, groupID); err != nil {
			return err
		}
		// Only a new day or time is worth a push.
		if before.Date.Equal(a.Date) && eqMin(before.StartsMin, a.StartsMin) {
			return nil
		}
		g, err := q.GetGroup(ctx, groupID)
		if err != nil {
			return err
		}
		return s.tellClassmates(ctx, q, groupID, c.UserID, s.assessmentNotice(g, a, &before, false))
	})
	return out, err
}

// DeleteAssessment removes one (the member who added it, or a CR).
func (s *Service) DeleteAssessment(ctx context.Context, groupID, id uuid.UUID) error {
	c := auth.MustUser(ctx)
	return s.d.InTx(ctx, func(ctx context.Context) error {
		q := store.New(s.d.Q(ctx))
		a, _, err := s.ownAssessment(ctx, q, groupID, id, c.UserID)
		if err != nil {
			return err
		}
		if _, err := q.DeleteAssessment(ctx, store.DeleteAssessmentParams{ID: id, GroupID: groupID}); err != nil {
			return err
		}
		if err := q.TouchGroup(ctx, groupID); err != nil {
			return err
		}
		if a.Date.Before(s.today()) {
			return nil // already past: nothing to tell
		}
		g, err := q.GetGroup(ctx, groupID)
		if err != nil {
			return err
		}
		return s.tellClassmates(ctx, q, groupID, c.UserID, s.assessmentNotice(g, a, nil, true))
	})
}

// role is the caller's role in the group (ErrGroupNotFound if not a member).
func (s *Service) role(ctx context.Context, q *store.Queries, groupID, userID uuid.UUID) (string, error) {
	role, err := q.GetRole(ctx, store.GetRoleParams{GroupID: groupID, UserID: userID})
	if db.IsNoRows(err) {
		return "", ErrGroupNotFound
	}
	return role, err
}

// ownAssessment locks an assessment the caller may change.
func (s *Service) ownAssessment(ctx context.Context, q *store.Queries, groupID, id, userID uuid.UUID) (store.Assessment, string, error) {
	role, err := s.role(ctx, q, groupID, userID)
	if err != nil {
		return store.Assessment{}, "", err
	}
	a, err := q.GetAssessment(ctx, store.GetAssessmentParams{ID: id, GroupID: groupID})
	if db.IsNoRows(err) {
		return a, role, ErrAssessmentNotFound
	}
	if err != nil {
		return a, role, err
	}
	if !canEditAssessment(a.CreatedBy, userID, role) {
		return a, role, ErrNotAssessmentOwner
	}
	return a, role, nil
}

func canEditAssessment(author *uuid.UUID, userID uuid.UUID, role string) bool {
	return role == RoleCR || (author != nil && *author == userID)
}

func eqMin(a, b *int16) bool {
	if a == nil || b == nil {
		return a == b
	}
	return *a == *b
}

func assessmentView(a store.Assessment, authorName *string, me uuid.UUID, role string) Assessment {
	clock := func(m *int16) *string {
		if m == nil {
			return nil
		}
		v := formatClock(*m)
		return &v
	}
	v := Assessment{
		ID: a.ID, Kind: a.Kind, CourseCode: a.CourseCode, CourseTitle: a.CourseTitle,
		Date: a.Date.Format("2006-01-02"), Start: clock(a.StartsMin), End: clock(a.EndsMin),
		Room: a.Room, Topics: a.Topics, CanEdit: canEditAssessment(a.CreatedBy, me, role), UpdatedAt: a.UpdatedAt,
	}
	if a.CreatedBy != nil {
		v.CreatedBy = &Author{ID: *a.CreatedBy, Name: authorName}
	}
	return v
}

// assessmentsByGroup: each group's tests and deadlines from yesterday on.
func (s *Service) assessmentsByGroup(ctx context.Context, q *store.Queries, me uuid.UUID, roles map[uuid.UUID]string) (map[uuid.UUID][]Assessment, error) {
	rows, err := q.ListAssessmentsForUser(ctx, store.ListAssessmentsForUserParams{UserID: me, FromDate: s.today().AddDate(0, 0, -1)})
	if err != nil {
		return nil, err
	}
	out := map[uuid.UUID][]Assessment{}
	for _, r := range rows {
		a := store.Assessment{
			ID: r.ID, GroupID: r.GroupID, Kind: r.Kind, CourseCode: r.CourseCode, CourseTitle: r.CourseTitle,
			Date: r.Date, StartsMin: r.StartsMin, EndsMin: r.EndsMin, Room: r.Room, Topics: r.Topics,
			CreatedBy: r.CreatedBy, CreatedAt: r.CreatedAt, UpdatedAt: r.UpdatedAt,
		}
		out[r.GroupID] = append(out[r.GroupID], assessmentView(a, r.AuthorName, me, roles[r.GroupID]))
	}
	return out, nil
}

// kindText names a kind in a push ("Class test" / "ক্লাস টেস্ট").
func kindText(lang, kind string) string {
	names := map[string][2]string{
		"class_test":   {"Class test", "ক্লাস টেস্ট"},
		"quiz":         {"Quiz", "কুইজ"},
		"assignment":   {"Assignment", "অ্যাসাইনমেন্ট"},
		"lab_report":   {"Lab report", "ল্যাব রিপোর্ট"},
		"presentation": {"Presentation", "প্রেজেন্টেশন"},
		"midterm":      {"Mid exam", "মিড পরীক্ষা"},
		"final":        {"Final exam", "ফাইনাল পরীক্ষা"},
		"other":        {"Test", "পরীক্ষা"},
	}
	n := names[kind]
	return pick(lang, n[0], n[1])
}

// assessmentNotice: added (before nil), moved (before set) or cancelled.
func (s *Service) assessmentNotice(g store.ClassGroup, a store.Assessment, before *store.Assessment, cancelled bool) Notice {
	texts := map[string]NoticeText{}
	for _, lang := range []string{"en", "bn"} {
		kind, day := kindText(lang, a.Kind), s.dayText(lang, a.Date)
		var when string
		if a.StartsMin != nil {
			when = clockText(lang, *a.StartsMin)
			if a.EndsMin != nil {
				when += " – " + clockText(lang, *a.EndsMin)
			}
		}
		roomText := ""
		if a.Room != "" {
			roomText = pick(lang, "Room ", "রুম ") + a.Room
		}
		topics := a.Topics
		if r := []rune(topics); len(r) > 120 {
			topics = string(r[:119]) + "…"
		}
		var title, body string
		switch {
		case cancelled:
			title = pick(lang, fmt.Sprintf("%s: %s cancelled", a.CourseCode, kind), fmt.Sprintf("%s: %s বাতিল", a.CourseCode, kind))
			body = join(" · ", pick(lang, "Was "+day, "ছিল "+day), groupTitle(g))
		case before != nil:
			title = pick(lang, fmt.Sprintf("%s: %s moved to %s", a.CourseCode, kind, day), fmt.Sprintf("%s: %s সরে %s", a.CourseCode, kind, day))
			body = join(" · ", when, roomText, topics)
		default:
			title = pick(lang, fmt.Sprintf("%s: %s %s", a.CourseCode, kind, s.whenText(lang, a.Date)), fmt.Sprintf("%s: %s %s", a.CourseCode, kind, day))
			body = join(" · ", when, roomText, topics)
		}
		if body == "" {
			body = groupTitle(g)
		}
		texts[lang] = NoticeText{Title: title, Body: body}
	}
	return Notice{Texts: texts, Data: map[string]string{"type": "assessment", "groupId": g.ID.String()}}
}
