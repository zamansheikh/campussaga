package admin

import (
	"context"
	"strings"
	"time"

	"github.com/google/uuid"

	"github.com/zamansheikh/campussaga/backend/internal/modules/admin/store"
	"github.com/zamansheikh/campussaga/backend/internal/platform/apperr"
	"github.com/zamansheikh/campussaga/backend/internal/platform/auth"
	"github.com/zamansheikh/campussaga/backend/internal/platform/db"
	"github.com/zamansheikh/campussaga/backend/internal/platform/httpx"
)

// UniversityRef is a university as shown next to a user or group.
type UniversityRef struct {
	ID   uuid.UUID `json:"id"`
	Slug string    `json:"slug"`
	Name string    `json:"name"`
}

// User is a user as the panel sees it.
type User struct {
	ID              uuid.UUID      `json:"id"`
	Email           string         `json:"email"`
	DisplayName     *string        `json:"displayName"`
	Department      *string        `json:"department"`
	Batch           *string        `json:"batch"`
	Role            string         `json:"role"`
	Verified        bool           `json:"verified"`
	VerifiedAt      *time.Time     `json:"verifiedAt"`
	UniversityEmail *string        `json:"universityEmail"`
	University      *UniversityRef `json:"university"`
	BlockedAt       *time.Time     `json:"blockedAt"`
	CreatedAt       time.Time      `json:"createdAt"`
	LastActiveAt    *time.Time     `json:"lastActiveAt"`
	Groups          int            `json:"groups"`
}

// UserDetail adds where the user is and what they use.
type UserDetail struct {
	User
	Memberships    []Membership `json:"memberships"`
	Devices        []Device     `json:"devices"`
	ActiveSessions int          `json:"activeSessions"`
}

type Membership struct {
	GroupID uuid.UUID `json:"groupId"`
	Title   string    `json:"title"`
	Role    string    `json:"role"`
}

type Device struct {
	Platform  string    `json:"platform"`
	CreatedAt time.Time `json:"createdAt"`
}

func userView(r store.GetUserRow) User {
	u := User{
		ID: r.ID, Email: r.Email, DisplayName: r.DisplayName, Department: r.Department, Batch: r.Batch,
		Role: string(r.Role), Verified: r.VerifiedAt != nil, VerifiedAt: r.VerifiedAt,
		UniversityEmail: r.UniversityEmail, BlockedAt: r.BlockedAt, CreatedAt: r.CreatedAt,
		Groups: int(r.Groups),
	}
	if r.UniversityID != nil && r.UniversitySlug != nil && r.UniversityName != nil {
		u.University = &UniversityRef{ID: *r.UniversityID, Slug: *r.UniversitySlug, Name: *r.UniversityName}
	}
	if r.LastActiveAt.Unix() > 0 { // epoch = never
		t := r.LastActiveAt
		u.LastActiveAt = &t
	}
	return u
}

func groupTitle(department, batch, section string) string {
	t := department + " " + batch
	if section != "" {
		t += " · " + section
	}
	return t
}

// ---- list / get ----------------------------------------------------------------

type listUsersReq struct {
	Page
	Q            string `json:"-" query:"q" validate:"max=100"`
	UniversityID string `json:"-" query:"universityId" validate:"omitempty,uuid"`
	Status       string `json:"-" query:"status" validate:"omitempty,oneof=verified notVerified blocked admin"`
}

func optUUID(s string) *uuid.UUID {
	if s == "" {
		return nil
	}
	id, err := uuid.Parse(s)
	if err != nil {
		return nil
	}
	return &id
}

func (s *Service) handleListUsers(ctx context.Context, in *listUsersReq) (*Paged[User], error) {
	page, size, lim, off := in.limits()
	q := store.New(s.d.Q(ctx))
	search := strings.TrimSpace(in.Q)
	rows, err := q.ListUsers(ctx, store.ListUsersParams{
		Q: search, QLike: like(search), UniversityID: optUUID(in.UniversityID), Status: in.Status, Lim: lim, Off: off,
	})
	if err != nil {
		return nil, err
	}
	total, err := q.CountUsers(ctx, store.CountUsersParams{
		Q: search, QLike: like(search), UniversityID: optUUID(in.UniversityID), Status: in.Status,
	})
	if err != nil {
		return nil, err
	}
	items := make([]User, 0, len(rows))
	for _, r := range rows {
		items = append(items, userView(store.GetUserRow(r)))
	}
	return &Paged[User]{Items: items, Total: int(total), Page: page, PageSize: size}, nil
}

type userReq struct {
	ID string `json:"-" path:"id" validate:"required,uuid"`
}

func (s *Service) handleGetUser(ctx context.Context, in *userReq) (*UserDetail, error) {
	return s.userDetail(ctx, uuid.MustParse(in.ID))
}

func (s *Service) userDetail(ctx context.Context, id uuid.UUID) (*UserDetail, error) {
	q := store.New(s.d.Q(ctx))
	r, err := q.GetUser(ctx, id)
	if db.IsNoRows(err) {
		return nil, ErrUserNotFound
	}
	if err != nil {
		return nil, err
	}
	out := &UserDetail{User: userView(r), Memberships: []Membership{}, Devices: []Device{}}
	ms, err := q.UserMemberships(ctx, id)
	if err != nil {
		return nil, err
	}
	for _, m := range ms {
		out.Memberships = append(out.Memberships, Membership{GroupID: m.ID, Title: groupTitle(m.Department, m.Batch, m.Section), Role: m.Role})
	}
	ds, err := q.UserDevices(ctx, id)
	if err != nil {
		return nil, err
	}
	for _, d := range ds {
		out.Devices = append(out.Devices, Device{Platform: d.Platform, CreatedAt: d.CreatedAt})
	}
	n, err := q.ActiveSessions(ctx, store.ActiveSessionsParams{UserID: id, Now: s.now()})
	if err != nil {
		return nil, err
	}
	out.ActiveSessions = int(n)
	return out, nil
}

// ---- change ---------------------------------------------------------------------

type patchUserReq struct {
	ID string `json:"-" path:"id" validate:"required,uuid"`
	// Role: student or admin.
	Role *string `json:"role" validate:"omitempty,oneof=student admin"`
	// UniversityID: a university id, or "" to clear it.
	UniversityID *string `json:"universityId" validate:"omitempty,max=36"`
	Verified     *bool   `json:"verified"`
	Blocked      *bool   `json:"blocked"`
	DisplayName  *string `json:"displayName" validate:"omitempty,max=60"`
}

func (s *Service) handlePatchUser(ctx context.Context, in *patchUserReq) (*UserDetail, error) {
	id := uuid.MustParse(in.ID)
	self := auth.MustUser(ctx).UserID == id
	if self && ((in.Role != nil && *in.Role != "admin") || (in.Blocked != nil && *in.Blocked)) {
		return nil, ErrCannotChangeSelf
	}
	var uniID *uuid.UUID
	if in.UniversityID != nil && *in.UniversityID != "" {
		u, err := uuid.Parse(*in.UniversityID)
		if err != nil {
			return nil, apperr.Validation(map[string]string{"universityId": "must be a valid UUID"})
		}
		uniID = &u
	}
	now := s.now()
	err := s.d.InTx(ctx, func(ctx context.Context) error {
		q := store.New(s.d.Q(ctx))
		cur, err := q.LockUser(ctx, id)
		if db.IsNoRows(err) {
			return ErrUserNotFound
		}
		if err != nil {
			return err
		}
		changed := map[string]any{}
		if in.UniversityID != nil && !sameUUID(cur.UniversityID, uniID) {
			if err := q.MoveUserUniversity(ctx, store.MoveUserUniversityParams{ID: id, UniversityID: uniID}); err != nil {
				if pe, ok := pgError(err); ok && pe.Code == "23503" {
					return ErrUniversityNotFound
				}
				return err
			}
			cur.UniversityID, cur.VerifiedAt = uniID, nil
			changed["universityId"] = uniID
		}
		if in.Verified != nil && *in.Verified != (cur.VerifiedAt != nil) {
			if *in.Verified {
				if cur.UniversityID == nil {
					return ErrUniversityRequired
				}
				err = q.VerifyUserByHand(ctx, store.VerifyUserByHandParams{ID: id, Now: &now})
			} else {
				err = q.UnverifyUser(ctx, id)
			}
			if err != nil {
				return err
			}
			changed["verified"] = *in.Verified
		}
		if in.Blocked != nil && *in.Blocked != (cur.BlockedAt != nil) {
			var at *time.Time
			if *in.Blocked {
				at = &now
			}
			if err := q.SetUserBlocked(ctx, store.SetUserBlockedParams{ID: id, BlockedAt: at}); err != nil {
				return err
			}
			if *in.Blocked {
				// Signed out everywhere, and no more pushes.
				if err := q.RevokeUserSessions(ctx, store.RevokeUserSessionsParams{UserID: id, Now: &now}); err != nil {
					return err
				}
				if err := q.DeleteUserDevices(ctx, id); err != nil {
					return err
				}
			}
			changed["blocked"] = *in.Blocked
		}
		if in.Role != nil && *in.Role != string(cur.Role) {
			if err := q.SetUserRole(ctx, store.SetUserRoleParams{ID: id, Role: store.UserRole(*in.Role)}); err != nil {
				return err
			}
			changed["role"] = *in.Role
		}
		if in.DisplayName != nil {
			name := strings.TrimSpace(*in.DisplayName)
			if err := q.SetUserName(ctx, store.SetUserNameParams{ID: id, DisplayName: name}); err != nil {
				return err
			}
			changed["displayName"] = name
		}
		if len(changed) == 0 {
			return nil
		}
		return s.audit(ctx, q, "user.update", "user", id.String(), changed)
	})
	if err != nil {
		return nil, err
	}
	return s.userDetail(ctx, id)
}

func sameUUID(a, b *uuid.UUID) bool {
	if a == nil || b == nil {
		return a == b
	}
	return *a == *b
}

func (s *Service) handleDeleteUser(ctx context.Context, in *userReq) (*httpx.Empty, error) {
	id := uuid.MustParse(in.ID)
	if auth.MustUser(ctx).UserID == id {
		return nil, ErrCannotChangeSelf
	}
	err := s.d.InTx(ctx, func(ctx context.Context) error {
		q := store.New(s.d.Q(ctx))
		u, err := q.GetUser(ctx, id)
		if db.IsNoRows(err) {
			return ErrUserNotFound
		}
		if err != nil {
			return err
		}
		if _, err := q.DeleteUser(ctx, id); err != nil {
			return err
		}
		return s.audit(ctx, q, "user.delete", "user", id.String(), map[string]string{"email": u.Email})
	})
	return nil, err
}
