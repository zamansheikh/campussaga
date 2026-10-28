package admin

import (
	"context"
	"net/http"
	"strings"
	"time"
	"unicode/utf8"

	"github.com/google/uuid"

	"github.com/zamansheikh/campussaga/backend/internal/modules/admin/store"
	"github.com/zamansheikh/campussaga/backend/internal/platform/apperr"
	"github.com/zamansheikh/campussaga/backend/internal/platform/auth"
	"github.com/zamansheikh/campussaga/backend/internal/platform/db"
	"github.com/zamansheikh/campussaga/backend/internal/platform/httpx"
)

// ErrRoleConflict: admins can't also be Campus Voice staff.
var ErrRoleConflict = apperr.New(http.StatusConflict, "ROLE_CONFLICT", "Admins can't be made authorities or moderators")

// Staff is a Campus Voice authority (a university official) or moderator.
type Staff struct {
	User struct {
		ID          uuid.UUID `json:"id"`
		Email       string    `json:"email"`
		DisplayName *string   `json:"displayName"`
	} `json:"user"`
	Kind       string         `json:"kind"`
	University *UniversityRef `json:"university"`
	Title      string         `json:"title"`
	CreatedAt  time.Time      `json:"createdAt"`
}

func staffView(r store.GetStaffRow) Staff {
	var out Staff
	out.User.ID, out.User.Email, out.User.DisplayName = r.UserID, r.Email, r.DisplayName
	out.Kind, out.Title, out.CreatedAt = r.Kind, r.Title, r.CreatedAt
	if r.UniversityID != nil && r.UniversitySlug != nil && r.UniversityName != nil {
		out.University = &UniversityRef{ID: *r.UniversityID, Slug: *r.UniversitySlug, Name: *r.UniversityName}
	}
	return out
}

type staffList struct {
	Items []Staff `json:"items"`
}

func (s *Service) handleListStaff(ctx context.Context, _ *httpx.Empty) (*staffList, error) {
	rows, err := store.New(s.d.Q(ctx)).ListStaff(ctx)
	if err != nil {
		return nil, err
	}
	out := &staffList{Items: make([]Staff, 0, len(rows))}
	for _, r := range rows {
		out.Items = append(out.Items, staffView(store.GetStaffRow(r)))
	}
	return out, nil
}

type addStaffReq struct {
	UserID       string `json:"userId" validate:"required,uuid"`
	Kind         string `json:"kind" validate:"required,oneof=authority moderator"`
	UniversityID string `json:"universityId" validate:"omitempty,uuid"`
	Title        string `json:"title"`
}

// handleAddStaff makes a user an authority or moderator (users.role and
// the staff row change together).
func (s *Service) handleAddStaff(ctx context.Context, in *addStaffReq) (*Staff, error) {
	id := uuid.MustParse(in.UserID)
	if auth.MustUser(ctx).UserID == id {
		return nil, ErrCannotChangeSelf
	}
	title := strings.TrimSpace(in.Title)
	uni := optUUID(in.UniversityID)
	bad := map[string]string{}
	if utf8.RuneCountInString(title) > 80 {
		bad["title"] = "must be at most 80 characters"
	}
	if in.Kind == "authority" {
		if uni == nil {
			bad["universityId"] = "is required for an authority"
		}
		if utf8.RuneCountInString(title) < 2 {
			bad["title"] = "is required for an authority (e.g. Proctor Office)"
		}
	}
	if len(bad) > 0 {
		return nil, apperr.Validation(bad)
	}
	var out *Staff
	err := s.d.InTx(ctx, func(ctx context.Context) error {
		q := store.New(s.d.Q(ctx))
		cur, err := q.LockUser(ctx, id)
		if db.IsNoRows(err) {
			return ErrUserNotFound
		}
		if err != nil {
			return err
		}
		if cur.Role == store.UserRoleAdmin {
			return ErrRoleConflict
		}
		err = q.UpsertStaff(ctx, store.UpsertStaffParams{UserID: id, Kind: in.Kind, UniversityID: uni, Title: title})
		if pe, ok := pgError(err); ok && pe.Code == "23503" {
			return ErrUniversityNotFound
		}
		if err != nil {
			return err
		}
		if err := q.SetUserRole(ctx, store.SetUserRoleParams{ID: id, Role: store.UserRole(in.Kind)}); err != nil {
			return err
		}
		meta := map[string]any{"kind": in.Kind, "title": title}
		if uni != nil {
			meta["universityId"] = uni.String()
		}
		if err := s.audit(ctx, q, "staff.add", "user", id.String(), meta); err != nil {
			return err
		}
		row, err := q.GetStaff(ctx, id)
		if err != nil {
			return err
		}
		v := staffView(row)
		out = &v
		return nil
	})
	return out, err
}

func (s *Service) handleRemoveStaff(ctx context.Context, in *userReq) (*httpx.Empty, error) {
	id := uuid.MustParse(in.ID)
	if auth.MustUser(ctx).UserID == id {
		return nil, ErrCannotChangeSelf
	}
	return nil, s.d.InTx(ctx, func(ctx context.Context) error {
		q := store.New(s.d.Q(ctx))
		cur, err := q.LockUser(ctx, id)
		if db.IsNoRows(err) {
			return ErrUserNotFound
		}
		if err != nil {
			return err
		}
		n, err := q.DeleteStaff(ctx, id)
		if err != nil {
			return err
		}
		if n == 0 {
			return ErrUserNotFound
		}
		if cur.Role == store.UserRoleAuthority || cur.Role == store.UserRoleModerator {
			if err := q.SetUserRole(ctx, store.SetUserRoleParams{ID: id, Role: store.UserRoleStudent}); err != nil {
				return err
			}
		}
		return s.audit(ctx, q, "staff.remove", "user", id.String(), map[string]string{"kind": string(cur.Role)})
	})
}
