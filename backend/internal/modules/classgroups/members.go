package classgroups

import (
	"context"
	"strings"
	"time"

	"github.com/google/uuid"

	"github.com/zamansheikh/varsitykotha/backend/internal/modules/classgroups/store"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/apperr"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/auth"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/db"
)

// MaxCRs per group: the CR and up to two co-CRs.
const MaxCRs = 3

// Member is one student in a group, as a CR sees them: a name, never an
// email or other details.
type Member struct {
	UserID   uuid.UUID `json:"userId"`
	Name     string    `json:"name"`
	Role     string    `json:"role"`
	JoinedAt time.Time `json:"joinedAt"`
	IsMe     bool      `json:"isMe"`
	// Verified: proved a university email (others signed in with Gmail).
	Verified bool `json:"verified"`
	// The member's photo: an uploaded one (GET /users/{id}/photo?v=…), else
	// their Google photo, else none (initials).
	PhotoVersion   *string `json:"photoVersion"`
	GooglePhotoURL *string `json:"googlePhotoUrl"`
}

// Members lists the group's students (CR only).
func (s *Service) Members(ctx context.Context, groupID uuid.UUID) ([]Member, error) {
	c := auth.MustUser(ctx)
	q := store.New(s.d.Q(ctx))
	if err := s.requireCR(ctx, q, groupID, c.UserID); err != nil {
		return nil, err
	}
	rows, err := q.ListMembers(ctx, groupID)
	if err != nil {
		return nil, err
	}
	out := make([]Member, 0, len(rows))
	for _, r := range rows {
		name := ""
		if r.DisplayName != nil {
			name = *r.DisplayName
		}
		out = append(out, Member{
			UserID: r.UserID, Name: name, Role: r.Role, JoinedAt: r.JoinedAt,
			IsMe: r.UserID == c.UserID, Verified: r.Verified,
			PhotoVersion: r.PhotoKey, GooglePhotoURL: r.GooglePhotoUrl,
		})
	}
	return out, nil
}

// SetMemberRole makes a member a CR (at most MaxCRs) or a CR a member
// again (never the last one). A CR can also step down this way.
func (s *Service) SetMemberRole(ctx context.Context, groupID, userID uuid.UUID, role string) error {
	c := auth.MustUser(ctx)
	return s.d.InTx(ctx, func(ctx context.Context) error {
		q := store.New(s.d.Q(ctx))
		if _, err := q.GetGroupForUpdate(ctx, groupID); db.IsNoRows(err) {
			return ErrGroupNotFound
		} else if err != nil {
			return err
		}
		if err := s.requireCR(ctx, q, groupID, c.UserID); err != nil {
			return err
		}
		current, err := q.GetRole(ctx, store.GetRoleParams{GroupID: groupID, UserID: userID})
		if db.IsNoRows(err) {
			return ErrMemberNotFound
		}
		if err != nil || current == role {
			return err
		}
		crs, err := q.CountCRs(ctx, groupID)
		if err != nil {
			return err
		}
		if role == RoleCR && crs >= MaxCRs {
			return ErrCRLimit
		}
		if role == RoleMember && crs <= 1 {
			return ErrLastCR
		}
		_, err = q.SetRole(ctx, store.SetRoleParams{GroupID: groupID, UserID: userID, Role: role})
		return err
	})
}

// RemoveMember takes a student out of the group (CR only), e.g. someone
// who got the code but isn't in the section. CRs step down first.
func (s *Service) RemoveMember(ctx context.Context, groupID, userID uuid.UUID) error {
	c := auth.MustUser(ctx)
	return s.d.InTx(ctx, func(ctx context.Context) error {
		q := store.New(s.d.Q(ctx))
		if err := s.requireCR(ctx, q, groupID, c.UserID); err != nil {
			return err
		}
		if userID == c.UserID {
			return apperr.BadRequest("Use leave to leave the group")
		}
		role, err := q.GetRole(ctx, store.GetRoleParams{GroupID: groupID, UserID: userID})
		if db.IsNoRows(err) {
			return ErrMemberNotFound
		}
		if err != nil {
			return err
		}
		if role == RoleCR {
			return ErrRemoveCR
		}
		return q.RemoveMember(ctx, store.RemoveMemberParams{GroupID: groupID, UserID: userID})
	})
}

// SetHidden replaces the courses the caller doesn't take in this group;
// they disappear from the caller's routine and reminders only.
func (s *Service) SetHidden(ctx context.Context, groupID uuid.UUID, courses []string) (*Group, error) {
	c := auth.MustUser(ctx)
	err := s.d.InTx(ctx, func(ctx context.Context) error {
		q := store.New(s.d.Q(ctx))
		if _, err := q.GetRole(ctx, store.GetRoleParams{GroupID: groupID, UserID: c.UserID}); db.IsNoRows(err) {
			return ErrGroupNotFound
		} else if err != nil {
			return err
		}
		if err := q.ClearHidden(ctx, store.ClearHiddenParams{GroupID: groupID, UserID: c.UserID}); err != nil {
			return err
		}
		for _, code := range courses {
			key := CourseKey(code)
			if key == "" || len([]rune(key)) > 20 {
				continue
			}
			if err := q.AddHidden(ctx, store.AddHiddenParams{GroupID: groupID, UserID: c.UserID, CourseKey: key}); err != nil {
				return err
			}
		}
		return nil
	})
	if err != nil {
		return nil, err
	}
	return s.myGroup(ctx, groupID)
}

// CourseKey: a course code in upper case without spaces ("cse 311" →
// "CSE311"), the same rule the app uses.
func CourseKey(code string) string {
	return strings.ToUpper(strings.Join(strings.Fields(code), ""))
}

// NewSemester clears the weekly routine (and its changes) and renames the
// semester; members, the code and announcements stay (CR only).
func (s *Service) NewSemester(ctx context.Context, groupID uuid.UUID, semester string) (*Group, error) {
	c := auth.MustUser(ctx)
	semester = clean(semester)
	if semester == "" {
		return nil, apperr.Validation(map[string]string{"semester": "is required"})
	}
	err := s.d.InTx(ctx, func(ctx context.Context) error {
		q := store.New(s.d.Q(ctx))
		if err := s.requireCR(ctx, q, groupID, c.UserID); err != nil {
			return err
		}
		if err := q.DeleteGroupSlots(ctx, groupID); err != nil {
			return err
		}
		if err := q.SetSemester(ctx, store.SetSemesterParams{ID: groupID, Semester: semester}); err != nil {
			return err
		}
		g, err := q.GetGroup(ctx, groupID)
		if err != nil {
			return err
		}
		return s.tellClassmates(ctx, q, groupID, c.UserID, semesterNotice(g))
	})
	if err != nil {
		return nil, err
	}
	return s.myGroup(ctx, groupID)
}
