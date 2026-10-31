package classgroups

import (
	"context"
	"net/url"
	"regexp"
	"strings"
	"unicode/utf8"

	"github.com/google/uuid"

	"github.com/zamansheikh/varsitykotha/backend/internal/modules/classgroups/store"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/apperr"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/auth"
)

// CourseInfo: optional extras of a course in a group, set by the CR. Every
// field may be empty.
type CourseInfo struct {
	CourseKey string `json:"courseKey"`
	// The class chat group (Messenger, WhatsApp, Telegram, Discord…).
	ChatLink string `json:"chatLink"`
	// The Google Classroom (or other class site) code.
	ClassroomCode string `json:"classroomCode"`
	// A folder or page with slides and notes.
	MaterialsLink string `json:"materialsLink"`
	TeacherEmail  string `json:"teacherEmail"`
	Notes         string `json:"notes"`
}

// CourseInfoInput is what the CR sends; all empty removes it.
type CourseInfoInput struct {
	ChatLink      string `json:"chatLink" validate:"max=300"`
	ClassroomCode string `json:"classroomCode" validate:"max=20"`
	MaterialsLink string `json:"materialsLink" validate:"max=300"`
	TeacherEmail  string `json:"teacherEmail" validate:"max=120"`
	Notes         string `json:"notes" validate:"max=500"`
}

var (
	classroomCodeRe = regexp.MustCompile(`^[A-Za-z0-9-]{3,20}$`)
	emailRe         = regexp.MustCompile(`^[^\s@]+@[^\s@]+\.[^\s@]{2,}$`)
)

// cleanLink: an http(s) address ("chat.whatsapp.com/x" gets https://), or
// "" with ok=false when it isn't one.
func cleanLink(s string) (string, bool) {
	s = strings.TrimSpace(s)
	if s == "" {
		return "", true
	}
	if !strings.Contains(s, "://") {
		s = "https://" + s
	}
	u, err := url.Parse(s)
	if err != nil || (u.Scheme != "http" && u.Scheme != "https") || !strings.Contains(u.Host, ".") ||
		strings.ContainsAny(s, " \t\n") || utf8.RuneCountInString(s) > 300 {
		return "", false
	}
	return u.String(), true
}

func (in *CourseInfoInput) clean() error {
	bad := map[string]string{}
	var ok bool
	if in.ChatLink, ok = cleanLink(in.ChatLink); !ok {
		bad["chatLink"] = "must be a web link"
	}
	if in.MaterialsLink, ok = cleanLink(in.MaterialsLink); !ok {
		bad["materialsLink"] = "must be a web link"
	}
	in.ClassroomCode = strings.TrimSpace(in.ClassroomCode)
	if in.ClassroomCode != "" && !classroomCodeRe.MatchString(in.ClassroomCode) {
		bad["classroomCode"] = "must be 3 to 20 letters or digits"
	}
	in.TeacherEmail = strings.ToLower(strings.TrimSpace(in.TeacherEmail))
	if in.TeacherEmail != "" && !emailRe.MatchString(in.TeacherEmail) {
		bad["teacherEmail"] = "must be an email address"
	}
	in.Notes = cleanBody(in.Notes)
	if utf8.RuneCountInString(in.Notes) > 500 {
		bad["notes"] = "must be at most 500 characters"
	}
	if len(bad) > 0 {
		return apperr.Validation(bad)
	}
	return nil
}

func (in *CourseInfoInput) empty() bool {
	return in.ChatLink == "" && in.ClassroomCode == "" && in.MaterialsLink == "" &&
		in.TeacherEmail == "" && in.Notes == ""
}

func courseInfoView(r store.GroupCourse) CourseInfo {
	return CourseInfo{CourseKey: r.CourseKey, ChatLink: r.ChatLink, ClassroomCode: r.ClassroomCode,
		MaterialsLink: r.MaterialsLink, TeacherEmail: r.TeacherEmail, Notes: r.Notes}
}

// SetCourseInfo saves (or, all empty, removes) a course's extras (CR). The
// course must be in the group's routine.
func (s *Service) SetCourseInfo(ctx context.Context, groupID uuid.UUID, course string, in *CourseInfoInput) (*Group, error) {
	c := auth.MustUser(ctx)
	key := CourseKey(course)
	if key == "" || utf8.RuneCountInString(key) > 20 {
		return nil, apperr.Validation(map[string]string{"course": "is not a course code"})
	}
	if err := in.clean(); err != nil {
		return nil, err
	}
	err := s.d.InTx(ctx, func(ctx context.Context) error {
		q := store.New(s.d.Q(ctx))
		if err := s.requireCR(ctx, q, groupID, c.UserID); err != nil {
			return err
		}
		slots, err := q.ListSlots(ctx, groupID)
		if err != nil {
			return err
		}
		found := false
		for _, sl := range slots {
			if CourseKey(sl.CourseCode) == key {
				found = true
				break
			}
		}
		if !found {
			return apperr.Validation(map[string]string{"course": "isn't in this routine"})
		}
		if in.empty() {
			err = q.DeleteCourseInfo(ctx, store.DeleteCourseInfoParams{GroupID: groupID, CourseKey: key})
		} else {
			_, err = q.UpsertCourseInfo(ctx, store.UpsertCourseInfoParams{GroupID: groupID, CourseKey: key,
				ChatLink: in.ChatLink, ClassroomCode: in.ClassroomCode, MaterialsLink: in.MaterialsLink,
				TeacherEmail: in.TeacherEmail, Notes: in.Notes, Now: s.now()})
		}
		if err != nil {
			return err
		}
		return q.TouchGroup(ctx, groupID)
	})
	if err != nil {
		return nil, err
	}
	return s.myGroup(ctx, groupID)
}
