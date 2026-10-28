package admin

import (
	"context"
	"regexp"
	"strings"
	"time"

	"github.com/google/uuid"

	"github.com/zamansheikh/varsitykotha/backend/internal/modules/admin/store"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/apperr"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/db"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/httpx"
)

// maxCRs matches the app's rule (classgroups.MaxCRs).
const maxCRs = 3

// Group is a class group as the panel sees it.
type Group struct {
	ID         uuid.UUID     `json:"id"`
	Title      string        `json:"title"`
	Department string        `json:"department"`
	Batch      string        `json:"batch"`
	Section    string        `json:"section"`
	Semester   string        `json:"semester"`
	JoinCode   string        `json:"joinCode"`
	University UniversityRef `json:"university"`
	Members    int           `json:"members"`
	CRs        []Person      `json:"crs"`
	Slots      int           `json:"slots"`
	// KeepWhenEmpty: a published routine that stays when its last member leaves.
	KeepWhenEmpty bool      `json:"keepWhenEmpty"`
	CreatedAt     time.Time `json:"createdAt"`
}

type Person struct {
	ID    uuid.UUID `json:"id"`
	Name  *string   `json:"name"`
	Email string    `json:"email"`
}

type GroupDetail struct {
	Group
	MemberList []Member `json:"memberList"`
}

type Member struct {
	UserID   uuid.UUID `json:"userId"`
	Name     *string   `json:"name"`
	Email    string    `json:"email"`
	Role     string    `json:"role"`
	Verified bool      `json:"verified"`
	JoinedAt time.Time `json:"joinedAt"`
}

func groupView(r store.GetGroupRow) Group {
	return Group{
		ID: r.ID, Title: groupTitle(r.Department, r.Batch, r.Section), Department: r.Department,
		Batch: r.Batch, Section: r.Section, Semester: r.Semester, JoinCode: r.JoinCode,
		University: UniversityRef{ID: r.UniversityID, Slug: r.UniversitySlug, Name: r.UniversityName},
		Members:    int(r.Members), CRs: []Person{}, Slots: int(r.Slots), CreatedAt: r.CreatedAt,
		KeepWhenEmpty: r.KeepWhenEmpty,
	}
}

// withCRs fills in each group's CRs.
func withCRs(ctx context.Context, q *store.Queries, groups []Group) error {
	ids := make([]uuid.UUID, len(groups))
	at := make(map[uuid.UUID]int, len(groups))
	for i, g := range groups {
		ids[i], at[g.ID] = g.ID, i
	}
	crs, err := q.GroupCRs(ctx, ids)
	if err != nil {
		return err
	}
	for _, c := range crs {
		g := &groups[at[c.GroupID]]
		g.CRs = append(g.CRs, Person{ID: c.ID, Name: c.DisplayName, Email: c.Email})
	}
	return nil
}

type listGroupsReq struct {
	Page
	Q            string `json:"-" query:"q" validate:"max=100"`
	UniversityID string `json:"-" query:"universityId" validate:"omitempty,uuid"`
}

func (s *Service) handleListGroups(ctx context.Context, in *listGroupsReq) (*Paged[Group], error) {
	page, size, lim, off := in.limits()
	search := strings.TrimSpace(in.Q)
	q := store.New(s.d.Q(ctx))
	rows, err := q.ListGroups(ctx, store.ListGroupsParams{
		Q: search, QLike: like(search), UniversityID: optUUID(in.UniversityID), Lim: lim, Off: off,
	})
	if err != nil {
		return nil, err
	}
	total, err := q.CountGroups(ctx, store.CountGroupsParams{Q: search, QLike: like(search), UniversityID: optUUID(in.UniversityID)})
	if err != nil {
		return nil, err
	}
	items := make([]Group, 0, len(rows))
	for _, r := range rows {
		items = append(items, groupView(store.GetGroupRow(r)))
	}
	if err := withCRs(ctx, q, items); err != nil {
		return nil, err
	}
	return &Paged[Group]{Items: items, Total: int(total), Page: page, PageSize: size}, nil
}

type groupReq struct {
	ID string `json:"-" path:"id" validate:"required,uuid"`
}

func (s *Service) handleGetGroup(ctx context.Context, in *groupReq) (*GroupDetail, error) {
	id := uuid.MustParse(in.ID)
	q := store.New(s.d.Q(ctx))
	r, err := q.GetGroup(ctx, id)
	if db.IsNoRows(err) {
		return nil, ErrGroupNotFound
	}
	if err != nil {
		return nil, err
	}
	groups := []Group{groupView(r)}
	if err := withCRs(ctx, q, groups); err != nil {
		return nil, err
	}
	ms, err := q.GroupMembers(ctx, id)
	if err != nil {
		return nil, err
	}
	out := &GroupDetail{Group: groups[0], MemberList: make([]Member, 0, len(ms))}
	for _, m := range ms {
		out.MemberList = append(out.MemberList, Member{
			UserID: m.ID, Name: m.DisplayName, Email: m.Email, Role: m.Role, Verified: m.Verified, JoinedAt: m.JoinedAt,
		})
	}
	return out, nil
}

type memberRoleReq struct {
	ID   string `json:"-" path:"id" validate:"required,uuid"`
	User string `json:"-" path:"user" validate:"required,uuid"`
	Role string `json:"role" validate:"required,oneof=cr member"`
}

func (s *Service) handleSetMemberRole(ctx context.Context, in *memberRoleReq) (*httpx.Empty, error) {
	groupID, userID := uuid.MustParse(in.ID), uuid.MustParse(in.User)
	err := s.d.InTx(ctx, func(ctx context.Context) error {
		q := store.New(s.d.Q(ctx))
		if _, err := q.GetGroup(ctx, groupID); db.IsNoRows(err) {
			return ErrGroupNotFound
		} else if err != nil {
			return err
		}
		members, err := q.LockGroupMembers(ctx, groupID)
		if err != nil {
			return err
		}
		crs, current := 0, ""
		for _, m := range members {
			if m.Role == "cr" {
				crs++
			}
			if m.UserID == userID {
				current = m.Role
			}
		}
		switch {
		case current == "":
			return ErrMemberNotFound
		case current == in.Role:
			return nil
		case in.Role == "member" && crs <= 1:
			return ErrLastCR
		case in.Role == "cr" && crs >= maxCRs:
			return ErrCRLimit
		}
		if err := q.SetMemberRole(ctx, store.SetMemberRoleParams{GroupID: groupID, UserID: userID, Role: in.Role}); err != nil {
			return err
		}
		return s.audit(ctx, q, "group.member.role", "group", groupID.String(),
			map[string]string{"userId": userID.String(), "role": in.Role})
	})
	return nil, err
}

type memberReq struct {
	ID   string `json:"-" path:"id" validate:"required,uuid"`
	User string `json:"-" path:"user" validate:"required,uuid"`
}

// handleRemoveMember removes a student from a group. If they were its last
// CR, the database passes the role to the longest-standing member.
func (s *Service) handleRemoveMember(ctx context.Context, in *memberReq) (*httpx.Empty, error) {
	groupID, userID := uuid.MustParse(in.ID), uuid.MustParse(in.User)
	err := s.d.InTx(ctx, func(ctx context.Context) error {
		q := store.New(s.d.Q(ctx))
		n, err := q.RemoveMember(ctx, store.RemoveMemberParams{GroupID: groupID, UserID: userID})
		if err != nil {
			return err
		}
		if n == 0 {
			return ErrMemberNotFound
		}
		return s.audit(ctx, q, "group.member.remove", "group", groupID.String(), map[string]string{"userId": userID.String()})
	})
	return nil, err
}

type patchGroupReq struct {
	groupReq
	// JoinCode: 6 letters, no I or O (any case); must be free.
	JoinCode      *string `json:"joinCode" validate:"omitempty"`
	KeepWhenEmpty *bool   `json:"keepWhenEmpty"`
}

var joinCodeRe = regexp.MustCompile(`^[A-HJ-NP-Z]{6}$`)

// handlePatchGroup sets a group's join code and whether it stays when empty.
func (s *Service) handlePatchGroup(ctx context.Context, in *patchGroupReq) (*GroupDetail, error) {
	id := uuid.MustParse(in.ID)
	var code string
	if in.JoinCode != nil {
		code = strings.ToUpper(strings.TrimSpace(*in.JoinCode))
		if !joinCodeRe.MatchString(code) {
			return nil, apperr.Validation(map[string]string{"joinCode": "must be 6 letters, without I or O"})
		}
	}
	err := s.d.InTx(ctx, func(ctx context.Context) error {
		q := store.New(s.d.Q(ctx))
		g, err := q.GetGroup(ctx, id)
		if db.IsNoRows(err) {
			return ErrGroupNotFound
		}
		if err != nil {
			return err
		}
		meta := map[string]any{"title": groupTitle(g.Department, g.Batch, g.Section)}
		if in.JoinCode != nil && code != g.JoinCode {
			taken, err := q.JoinCodeTaken(ctx, store.JoinCodeTakenParams{JoinCode: code, ID: id})
			if err != nil {
				return err
			}
			if taken {
				return ErrJoinCodeTaken
			}
			if err := q.SetGroupCode(ctx, store.SetGroupCodeParams{JoinCode: code, ID: id}); err != nil {
				return err
			}
			meta["joinCode"] = map[string]string{"from": g.JoinCode, "to": code}
		}
		if in.KeepWhenEmpty != nil && *in.KeepWhenEmpty != g.KeepWhenEmpty {
			if err := q.SetGroupKeep(ctx, store.SetGroupKeepParams{Keep: *in.KeepWhenEmpty, ID: id}); err != nil {
				return err
			}
			meta["keepWhenEmpty"] = *in.KeepWhenEmpty
		}
		return s.audit(ctx, q, "group.update", "group", id.String(), meta)
	})
	if err != nil {
		return nil, err
	}
	return s.handleGetGroup(ctx, &in.groupReq)
}

func (s *Service) handleDeleteGroup(ctx context.Context, in *groupReq) (*httpx.Empty, error) {
	id := uuid.MustParse(in.ID)
	err := s.d.InTx(ctx, func(ctx context.Context) error {
		q := store.New(s.d.Q(ctx))
		g, err := q.GetGroup(ctx, id)
		if db.IsNoRows(err) {
			return ErrGroupNotFound
		}
		if err != nil {
			return err
		}
		if _, err := q.DeleteGroup(ctx, id); err != nil {
			return err
		}
		return s.audit(ctx, q, "group.delete", "group", id.String(), map[string]any{
			"title": groupTitle(g.Department, g.Batch, g.Section), "university": g.UniversitySlug, "members": g.Members,
		})
	})
	return nil, err
}
