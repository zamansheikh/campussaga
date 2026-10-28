// Package classgroups is "My Class": a section's weekly routine, run by its
// CR (class representative), joined by classmates with a 6-letter code.
//
//   - GET    /groups                    my groups, each with its routine
//   - POST   /groups                    create a group; the caller is its CR
//   - GET    /groups/preview?code=      what a code leads to, before joining
//   - POST   /groups/join               join with a code
//   - PUT    /groups/{id}               edit details (CR)
//   - DELETE /groups/{id}               delete for everyone (CR)
//   - POST   /groups/{id}/leave         leave
//   - POST   /groups/{id}/slots         add a class (CR)
//   - PUT    /groups/{id}/slots/{slot}  edit a class (CR)
//   - DELETE /groups/{id}/slots/{slot}  remove a class (CR)
//   - POST   /groups/{id}/changes       cancel / move a class, or add an
//     extra class, on one date (CR)
//   - DELETE /groups/{id}/changes/{c}   undo a change (CR)
//   - POST   /groups/{id}/announcements post a message (CR)
//   - PATCH  /groups/{id}/announcements/{a}  pin / unpin (CR)
//   - DELETE /groups/{id}/announcements/{a}  delete (CR)
//   - GET    /groups/{id}/members       names and roles (CR)
//   - PUT    /groups/{id}/members/{u}   {role}: make CR / member (CR)
//   - DELETE /groups/{id}/members/{u}   remove a student (CR)
//   - PUT    /groups/{id}/hidden        {courses}: courses I don't take
//   - POST   /groups/{id}/new-semester  {semester}: clear the routine (CR)
//   - GET/POST /me/classes, PUT/DELETE /me/classes/{id}: personal classes
//
// Security notes:
//   - A group is visible only to its members. Codes only work for students
//     of the same university; anything else answers GROUP_NOT_FOUND, so a
//     code can't be used to probe other universities.
//   - Join attempts are rate limited per student and per IP (24^6 codes).
//   - Member lists are never returned; only a count.
package classgroups

import (
	"context"
	"crypto/rand"
	"fmt"
	"math/big"
	"strconv"
	"strings"
	"time"

	"github.com/google/uuid"

	"github.com/zamansheikh/campussaga/backend/internal/modules/classgroups/store"
	"github.com/zamansheikh/campussaga/backend/internal/platform/apperr"
	"github.com/zamansheikh/campussaga/backend/internal/platform/auth"
	"github.com/zamansheikh/campussaga/backend/internal/platform/db"
)

// Limits keep one group or one student from growing without bound.
const (
	MaxGroupsPerStudent = 10
	MaxMembers          = 300
	MaxSlots            = 100

	codeAlphabet = "ABCDEFGHJKLMNPQRSTUVWXYZ" // no I or O
	codeLength   = 6
)

const (
	RoleCR     = "cr"
	RoleMember = "member"
)

// Service is the class groups module.
type Service struct {
	d      *db.DB
	now    func() time.Time
	notify Notifier // nil = no notifications
}

func NewService(d *db.DB, now func() time.Time) *Service { return &Service{d: d, now: now} }

// Group is one class group as its member sees it.
type Group struct {
	ID          uuid.UUID `json:"id"`
	Department  string    `json:"department"`
	Batch       string    `json:"batch"`
	Section     string    `json:"section"`
	Semester    string    `json:"semester"`
	JoinCode    string    `json:"joinCode"`
	Role        string    `json:"role"`
	MemberCount int64     `json:"memberCount"`
	Slots       []Slot    `json:"slots"`
	// Changes from yesterday on (Bangladesh dates), earliest first.
	Changes []Change `json:"changes"`
	// The pinned one first, then the last 30 days' newest first.
	Announcements []Announcement `json:"announcements"`
	// Tests and deadlines from yesterday on, earliest first.
	Assessments []Assessment `json:"assessments"`
	// Course keys the caller doesn't take here (hidden from their routine).
	HiddenCourses []string  `json:"hiddenCourses"`
	UpdatedAt     time.Time `json:"updatedAt"`
}

// Slot is one weekly class. Weekday is ISO (1 = Monday ... 7 = Sunday);
// start and end are "HH:MM" local time.
type Slot struct {
	ID          uuid.UUID `json:"id"`
	CourseCode  string    `json:"courseCode"`
	CourseTitle string    `json:"courseTitle"`
	Teacher     string    `json:"teacher"`
	Room        string    `json:"room"`
	Weekday     int       `json:"weekday"`
	Start       string    `json:"start"`
	End         string    `json:"end"`
	Kind        string    `json:"kind"`
}

// GroupInput creates or edits a group.
type GroupInput struct {
	Department string `json:"department" validate:"required,max=80"`
	Batch      string `json:"batch" validate:"required,max=20"`
	Section    string `json:"section" validate:"max=20"`
	Semester   string `json:"semester" validate:"required,max=30"`
}

func (in *GroupInput) clean() error {
	in.Department, in.Batch = clean(in.Department), clean(in.Batch)
	in.Section, in.Semester = clean(in.Section), clean(in.Semester)
	return required(map[string]string{
		"department": in.Department, "batch": in.Batch, "semester": in.Semester,
	})
}

// SlotInput creates or edits a class.
type SlotInput struct {
	CourseCode  string `json:"courseCode" validate:"required,max=20"`
	CourseTitle string `json:"courseTitle" validate:"max=100"`
	Teacher     string `json:"teacher" validate:"max=60"`
	Room        string `json:"room" validate:"max=30"`
	Weekday     int    `json:"weekday" validate:"min=1,max=7"`
	Start       string `json:"start" validate:"required"`
	End         string `json:"end" validate:"required"`
	Kind        string `json:"kind" validate:"required,oneof=theory lab"`

	startMin, endMin int16
}

func (in *SlotInput) clean() error {
	in.CourseCode, in.CourseTitle = clean(in.CourseCode), clean(in.CourseTitle)
	in.Teacher, in.Room = clean(in.Teacher), clean(in.Room)
	if err := required(map[string]string{"courseCode": in.CourseCode}); err != nil {
		return err
	}
	start, ok1 := parseClock(in.Start)
	end, ok2 := parseClock(in.End)
	switch {
	case !ok1:
		return apperr.Validation(map[string]string{"start": "must be a time like 09:30"})
	case !ok2:
		return apperr.Validation(map[string]string{"end": "must be a time like 10:45"})
	case end <= start:
		return apperr.Validation(map[string]string{"end": "must be after start"})
	}
	in.startMin, in.endMin = start, end
	return nil
}

// ---- groups -----------------------------------------------------------------

// MyGroups returns the caller's groups, each with its full routine.
func (s *Service) MyGroups(ctx context.Context) ([]Group, error) {
	c := auth.MustUser(ctx)
	q := store.New(s.d.Q(ctx))
	rows, err := q.ListMyGroups(ctx, c.UserID)
	if err != nil {
		return nil, err
	}
	slots, err := q.ListSlotsForUser(ctx, c.UserID)
	if err != nil {
		return nil, err
	}
	byGroup := map[uuid.UUID][]Slot{}
	for _, sl := range slots {
		byGroup[sl.GroupID] = append(byGroup[sl.GroupID], slotView(sl))
	}
	changes, err := q.ListChangesForUser(ctx, store.ListChangesForUserParams{
		UserID: c.UserID, FromDate: s.today().AddDate(0, 0, -1),
	})
	if err != nil {
		return nil, err
	}
	changesByGroup := map[uuid.UUID][]Change{}
	for _, ch := range changes {
		changesByGroup[ch.GroupID] = append(changesByGroup[ch.GroupID], changeView(ch))
	}
	news, err := s.announcementsByGroup(ctx, q, c.UserID)
	if err != nil {
		return nil, err
	}
	roles := make(map[uuid.UUID]string, len(rows))
	for _, r := range rows {
		roles[r.ClassGroup.ID] = r.Role
	}
	tests, err := s.assessmentsByGroup(ctx, q, c.UserID, roles)
	if err != nil {
		return nil, err
	}
	hiddenRows, err := q.ListHiddenForUser(ctx, c.UserID)
	if err != nil {
		return nil, err
	}
	hidden := map[uuid.UUID][]string{}
	for _, h := range hiddenRows {
		hidden[h.GroupID] = append(hidden[h.GroupID], h.CourseKey)
	}
	out := make([]Group, 0, len(rows))
	for _, r := range rows {
		g := groupView(r.ClassGroup, r.Role, r.MemberCount, byGroup[r.ClassGroup.ID])
		if cs := changesByGroup[r.ClassGroup.ID]; cs != nil {
			g.Changes = cs
		}
		if as := news[r.ClassGroup.ID]; as != nil {
			g.Announcements = as
		}
		if ts := tests[r.ClassGroup.ID]; ts != nil {
			g.Assessments = ts
		}
		if hs := hidden[r.ClassGroup.ID]; hs != nil {
			g.HiddenCourses = hs
		}
		out = append(out, g)
	}
	return out, nil
}

// Create makes a new group with the caller as its CR.
func (s *Service) Create(ctx context.Context, in *GroupInput) (*Group, error) {
	if auth.MustUser(ctx).UniversityID == uuid.Nil {
		return nil, ErrUniversityRequired
	}
	if err := in.clean(); err != nil {
		return nil, err
	}
	// A random code that is already taken (rare: 191 million codes) fails
	// the unique index; try again with a fresh one.
	for attempt := 1; ; attempt++ {
		out, err := s.create(ctx, in)
		if attempt < 4 && db.IsUniqueViolation(err, "class_groups_join_code_key") {
			continue
		}
		return out, err
	}
}

func (s *Service) create(ctx context.Context, in *GroupInput) (*Group, error) {
	c := auth.MustUser(ctx)
	var out *Group
	err := s.d.InTx(ctx, func(ctx context.Context) error {
		q := store.New(s.d.Q(ctx))
		n, err := q.CountUserGroups(ctx, c.UserID)
		if err != nil {
			return err
		}
		if n >= MaxGroupsPerStudent {
			return ErrGroupLimit
		}
		code, err := newCode()
		if err != nil {
			return err
		}
		g, err := q.CreateGroup(ctx, store.CreateGroupParams{
			UniversityID: c.UniversityID, Department: in.Department, Batch: in.Batch,
			Section: in.Section, Semester: in.Semester, JoinCode: code, CreatedBy: &c.UserID,
		})
		if err != nil {
			return err
		}
		if err := q.AddMember(ctx, store.AddMemberParams{GroupID: g.ID, UserID: c.UserID, Role: RoleCR}); err != nil {
			return err
		}
		v := groupView(g, RoleCR, 1, nil)
		out = &v
		return nil
	})
	return out, err
}

// Preview tells a student what a code leads to, before joining.
type Preview struct {
	Department  string `json:"department"`
	Batch       string `json:"batch"`
	Section     string `json:"section"`
	Semester    string `json:"semester"`
	MemberCount int64  `json:"memberCount"`
	ClassCount  int64  `json:"classCount"`
	IsMember    bool   `json:"isMember"`
}

func (s *Service) Preview(ctx context.Context, code string) (*Preview, error) {
	c := auth.MustUser(ctx)
	q := store.New(s.d.Q(ctx))
	g, err := s.groupForCode(ctx, q, c, code)
	if err != nil {
		return nil, err
	}
	members, err := q.CountMembers(ctx, g.ID)
	if err != nil {
		return nil, err
	}
	classes, err := q.CountSlots(ctx, g.ID)
	if err != nil {
		return nil, err
	}
	_, err = q.GetRole(ctx, store.GetRoleParams{GroupID: g.ID, UserID: c.UserID})
	if err != nil && !db.IsNoRows(err) {
		return nil, err
	}
	return &Preview{
		Department: g.Department, Batch: g.Batch, Section: g.Section, Semester: g.Semester,
		MemberCount: members, ClassCount: classes, IsMember: err == nil,
	}, nil
}

// Join adds the caller to the group with this code. Joining a group you
// are already in just returns it.
func (s *Service) Join(ctx context.Context, code string) (*Group, error) {
	c := auth.MustUser(ctx)
	var id uuid.UUID
	err := s.d.InTx(ctx, func(ctx context.Context) error {
		q := store.New(s.d.Q(ctx))
		g, err := s.groupForCode(ctx, q, c, code)
		if err != nil {
			return err
		}
		id = g.ID
		if _, err := q.GetGroupForUpdate(ctx, g.ID); err != nil { // serialise joins
			return err
		}
		_, err = q.GetRole(ctx, store.GetRoleParams{GroupID: g.ID, UserID: c.UserID})
		if err == nil {
			return nil // already a member
		}
		if !db.IsNoRows(err) {
			return err
		}
		mine, err := q.CountUserGroups(ctx, c.UserID)
		if err != nil {
			return err
		}
		if mine >= MaxGroupsPerStudent {
			return ErrGroupLimit
		}
		members, err := q.CountMembers(ctx, g.ID)
		if err != nil {
			return err
		}
		if members >= MaxMembers {
			return ErrGroupFull
		}
		return q.AddMember(ctx, store.AddMemberParams{GroupID: g.ID, UserID: c.UserID, Role: RoleMember})
	})
	if err != nil {
		return nil, err
	}
	return s.myGroup(ctx, id)
}

// Update edits the group's details (CR only).
func (s *Service) Update(ctx context.Context, id uuid.UUID, in *GroupInput) (*Group, error) {
	c := auth.MustUser(ctx)
	if err := in.clean(); err != nil {
		return nil, err
	}
	err := s.d.InTx(ctx, func(ctx context.Context) error {
		q := store.New(s.d.Q(ctx))
		if err := s.requireCR(ctx, q, id, c.UserID); err != nil {
			return err
		}
		_, err := q.UpdateGroup(ctx, store.UpdateGroupParams{
			ID: id, Department: in.Department, Batch: in.Batch, Section: in.Section, Semester: in.Semester,
		})
		return err
	})
	if err != nil {
		return nil, err
	}
	return s.myGroup(ctx, id)
}

// Delete removes the group and its routine for every member (CR only).
func (s *Service) Delete(ctx context.Context, id uuid.UUID) error {
	c := auth.MustUser(ctx)
	return s.d.InTx(ctx, func(ctx context.Context) error {
		q := store.New(s.d.Q(ctx))
		if err := s.requireCR(ctx, q, id, c.UserID); err != nil {
			return err
		}
		return q.DeleteGroup(ctx, id)
	})
}

// Leave removes the caller from the group. The last member leaving deletes
// it. The only CR can't leave while classmates remain (they would lose the
// person who keeps the routine up to date); they can delete the group.
func (s *Service) Leave(ctx context.Context, id uuid.UUID) error {
	c := auth.MustUser(ctx)
	return s.d.InTx(ctx, func(ctx context.Context) error {
		q := store.New(s.d.Q(ctx))
		if _, err := q.GetGroupForUpdate(ctx, id); db.IsNoRows(err) {
			return ErrGroupNotFound
		} else if err != nil {
			return err
		}
		role, err := q.GetRole(ctx, store.GetRoleParams{GroupID: id, UserID: c.UserID})
		if db.IsNoRows(err) {
			return ErrGroupNotFound
		}
		if err != nil {
			return err
		}
		members, err := q.CountMembers(ctx, id)
		if err != nil {
			return err
		}
		if members == 1 {
			return q.DeleteGroup(ctx, id)
		}
		if role == RoleCR {
			crs, err := q.CountCRs(ctx, id)
			if err != nil {
				return err
			}
			if crs == 1 {
				return ErrCRCannotLeave
			}
		}
		return q.RemoveMember(ctx, store.RemoveMemberParams{GroupID: id, UserID: c.UserID})
	})
}

// ---- routine ----------------------------------------------------------------

// AddSlot adds a weekly class (CR only).
func (s *Service) AddSlot(ctx context.Context, groupID uuid.UUID, in *SlotInput) (*Slot, error) {
	c := auth.MustUser(ctx)
	if err := in.clean(); err != nil {
		return nil, err
	}
	var out *Slot
	err := s.d.InTx(ctx, func(ctx context.Context) error {
		q := store.New(s.d.Q(ctx))
		if err := s.requireCR(ctx, q, groupID, c.UserID); err != nil {
			return err
		}
		n, err := q.CountSlots(ctx, groupID)
		if err != nil {
			return err
		}
		if n >= MaxSlots {
			return ErrSlotLimit
		}
		sl, err := q.CreateSlot(ctx, store.CreateSlotParams{
			GroupID: groupID, CourseCode: in.CourseCode, CourseTitle: in.CourseTitle,
			Teacher: in.Teacher, Room: in.Room, Weekday: int16(in.Weekday),
			StartsMin: in.startMin, EndsMin: in.endMin, Kind: in.Kind,
		})
		if err != nil {
			return err
		}
		v := slotView(sl)
		out = &v
		return q.TouchGroup(ctx, groupID)
	})
	return out, err
}

// UpdateSlot replaces a class's details (CR only).
func (s *Service) UpdateSlot(ctx context.Context, groupID, slotID uuid.UUID, in *SlotInput) (*Slot, error) {
	c := auth.MustUser(ctx)
	if err := in.clean(); err != nil {
		return nil, err
	}
	var out *Slot
	err := s.d.InTx(ctx, func(ctx context.Context) error {
		q := store.New(s.d.Q(ctx))
		if err := s.requireCR(ctx, q, groupID, c.UserID); err != nil {
			return err
		}
		before, err := q.GetSlot(ctx, store.GetSlotParams{ID: slotID, GroupID: groupID})
		if db.IsNoRows(err) {
			return ErrSlotNotFound
		}
		if err != nil {
			return err
		}
		if int(before.Weekday) != in.Weekday { // old one-date changes no longer fit
			if err := q.DeleteSlotChanges(ctx, &slotID); err != nil {
				return err
			}
		}
		sl, err := q.UpdateSlot(ctx, store.UpdateSlotParams{
			ID: slotID, GroupID: groupID, CourseCode: in.CourseCode, CourseTitle: in.CourseTitle,
			Teacher: in.Teacher, Room: in.Room, Weekday: int16(in.Weekday),
			StartsMin: in.startMin, EndsMin: in.endMin, Kind: in.Kind,
		})
		if db.IsNoRows(err) {
			return ErrSlotNotFound
		}
		if err != nil {
			return err
		}
		v := slotView(sl)
		out = &v
		return q.TouchGroup(ctx, groupID)
	})
	return out, err
}

// DeleteSlot removes a class (CR only).
func (s *Service) DeleteSlot(ctx context.Context, groupID, slotID uuid.UUID) error {
	c := auth.MustUser(ctx)
	return s.d.InTx(ctx, func(ctx context.Context) error {
		q := store.New(s.d.Q(ctx))
		if err := s.requireCR(ctx, q, groupID, c.UserID); err != nil {
			return err
		}
		n, err := q.DeleteSlot(ctx, store.DeleteSlotParams{ID: slotID, GroupID: groupID})
		if err != nil {
			return err
		}
		if n == 0 {
			return ErrSlotNotFound
		}
		return q.TouchGroup(ctx, groupID)
	})
}

// ---- helpers ----------------------------------------------------------------

// groupForCode finds a group of the caller's university by code.
func (s *Service) groupForCode(ctx context.Context, q *store.Queries, c *auth.Claims, code string) (store.ClassGroup, error) {
	if c.UniversityID == uuid.Nil {
		return store.ClassGroup{}, ErrUniversityRequired
	}
	code = strings.ToUpper(strings.TrimSpace(code))
	g, err := q.GetGroupByCode(ctx, code)
	if db.IsNoRows(err) || (err == nil && g.UniversityID != c.UniversityID) {
		return store.ClassGroup{}, ErrGroupNotFound
	}
	return g, err
}

// requireCR: not a member answers GROUP_NOT_FOUND (don't confirm the group
// exists); a member who isn't CR answers NOT_GROUP_CR.
func (s *Service) requireCR(ctx context.Context, q *store.Queries, groupID, userID uuid.UUID) error {
	role, err := q.GetRole(ctx, store.GetRoleParams{GroupID: groupID, UserID: userID})
	if db.IsNoRows(err) {
		return ErrGroupNotFound
	}
	if err != nil {
		return err
	}
	if role != RoleCR {
		return ErrNotCR
	}
	return nil
}

func (s *Service) myGroup(ctx context.Context, id uuid.UUID) (*Group, error) {
	all, err := s.MyGroups(ctx)
	if err != nil {
		return nil, err
	}
	for i := range all {
		if all[i].ID == id {
			return &all[i], nil
		}
	}
	return nil, ErrGroupNotFound
}

func groupView(g store.ClassGroup, role string, members int64, slots []Slot) Group {
	if slots == nil {
		slots = []Slot{}
	}
	return Group{
		ID: g.ID, Department: g.Department, Batch: g.Batch, Section: g.Section, Semester: g.Semester,
		JoinCode: g.JoinCode, Role: role, MemberCount: members, Slots: slots, Changes: []Change{},
		Announcements: []Announcement{}, Assessments: []Assessment{}, HiddenCourses: []string{}, UpdatedAt: g.UpdatedAt,
	}
}

func slotView(s store.RoutineSlot) Slot {
	return Slot{
		ID: s.ID, CourseCode: s.CourseCode, CourseTitle: s.CourseTitle, Teacher: s.Teacher,
		Room: s.Room, Weekday: int(s.Weekday), Start: formatClock(s.StartsMin),
		End: formatClock(s.EndsMin), Kind: s.Kind,
	}
}

func newCode() (string, error) {
	b := make([]byte, codeLength)
	max := big.NewInt(int64(len(codeAlphabet)))
	for i := range b {
		n, err := rand.Int(rand.Reader, max)
		if err != nil {
			return "", err
		}
		b[i] = codeAlphabet[n.Int64()]
	}
	return string(b), nil
}

// parseClock reads "HH:MM" (00:00-24:00) as minutes after midnight.
func parseClock(s string) (int16, bool) {
	h, m, ok := strings.Cut(strings.TrimSpace(s), ":")
	if !ok || len(h) != 2 || len(m) != 2 {
		return 0, false
	}
	hh, err1 := strconv.Atoi(h)
	mm, err2 := strconv.Atoi(m)
	if err1 != nil || err2 != nil || hh < 0 || mm < 0 || mm > 59 || hh*60+mm > 24*60 {
		return 0, false
	}
	return int16(hh*60 + mm), true
}

func formatClock(min int16) string { return fmt.Sprintf("%02d:%02d", min/60, min%60) }

func clean(s string) string { return strings.Join(strings.Fields(s), " ") }

// required reports fields that are empty after trimming.
func required(fields map[string]string) error {
	bad := map[string]string{}
	for name, v := range fields {
		if v == "" {
			bad[name] = "is required"
		}
	}
	if len(bad) > 0 {
		return apperr.Validation(bad)
	}
	return nil
}
