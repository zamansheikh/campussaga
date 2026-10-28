package classgroups

import (
	"context"
	"regexp"
	"strconv"
	"strings"

	"github.com/google/uuid"

	"github.com/zamansheikh/campussaga/backend/internal/modules/classgroups/store"
	"github.com/zamansheikh/campussaga/backend/internal/platform/apperr"
	"github.com/zamansheikh/campussaga/backend/internal/platform/auth"
	"github.com/zamansheikh/campussaga/backend/internal/platform/db"
)

// "Find your class": students search their university's class groups, look
// at a routine before joining, and join a whole section or only some of
// its courses. Groups of other universities never show; a CR can make a
// group "code only" (hidden from search, still joinable with its code).

const (
	searchPageSize  = 20
	maxSearchTokens = 6
)

// FoundGroup is a class group as search shows it (no member list).
type FoundGroup struct {
	ID          uuid.UUID `json:"id"`
	Title       string    `json:"title"`
	Department  string    `json:"department"`
	Batch       string    `json:"batch"`
	Section     string    `json:"section"`
	Semester    string    `json:"semester"`
	MemberCount int64     `json:"memberCount"`
	CRName      *string   `json:"crName"`
	Courses     []Course  `json:"courses"`
	IsMember    bool      `json:"isMember"`
}

// Course is one course of a group's routine; Key is CourseKey(Code).
type Course struct {
	Key     string `json:"key"`
	Code    string `json:"code"`
	Title   string `json:"title"`
	Teacher string `json:"teacher"`
}

// SearchResult is one page of search results.
type SearchResult struct {
	Items []FoundGroup `json:"items"`
	More  bool         `json:"more"`
}

// RoutinePreview is a group's weekly routine before joining.
type RoutinePreview struct {
	FoundGroup
	Slots []Slot `json:"slots"`
	// HiddenCourses: the courses a member doesn't take (keys).
	HiddenCourses []string `json:"hiddenCourses"`
}

var joinCodeRe = regexp.MustCompile(`^[A-HJ-NP-Z]{6}$`)

func titleOf(department, batch, section string) string {
	t := department + " " + batch
	if section != "" {
		t += " · " + section
	}
	return t
}

// likePatterns turns a search into lower-case '%word%' patterns, matching
// % and _ literally.
func likePatterns(q string) []string {
	esc := strings.NewReplacer(`\`, `\\`, `%`, `\%`, `_`, `\_`)
	words := strings.Fields(strings.ToLower(q))
	if len(words) > maxSearchTokens {
		words = words[:maxSearchTokens]
	}
	out := make([]string, 0, len(words))
	for _, w := range words {
		out = append(out, "%"+esc.Replace(w)+"%")
	}
	return out
}

// Search finds groups of the caller's university. q matches department,
// batch, section, semester, course codes ("CSE311" or "CSE 311"), titles
// and teachers (every word must match); an exact join code also finds a
// code-only group.
func (s *Service) Search(ctx context.Context, query, department, batch string, page int) (*SearchResult, error) {
	c := auth.MustUser(ctx)
	if c.UniversityID == uuid.Nil {
		return nil, ErrUniversityRequired
	}
	page = max(page, 1)
	q := store.New(s.d.Q(ctx))
	rows, err := q.SearchGroups(ctx, store.SearchGroupsParams{
		UniversityID: c.UniversityID, Patterns: likePatterns(query),
		Department: clean(department), Batch: clean(batch),
		Lim: searchPageSize + 1, Off: int32((page - 1) * searchPageSize),
	})
	if err != nil {
		return nil, err
	}
	more := len(rows) > searchPageSize
	if more {
		rows = rows[:searchPageSize]
	}
	found := make([]FoundGroup, 0, len(rows)+1)
	seen := map[uuid.UUID]bool{}
	// An exact join code first (also for a code-only group).
	if code := strings.ToUpper(strings.TrimSpace(query)); page == 1 && joinCodeRe.MatchString(code) {
		g, err := q.GetGroupByCode(ctx, code)
		switch {
		case err == nil && g.UniversityID == c.UniversityID:
			n, err := q.CountMembers(ctx, g.ID)
			if err != nil {
				return nil, err
			}
			found = append(found, FoundGroup{
				ID: g.ID, Title: titleOf(g.Department, g.Batch, g.Section), Department: g.Department,
				Batch: g.Batch, Section: g.Section, Semester: g.Semester, MemberCount: n,
			})
			seen[g.ID] = true
		case err != nil && !db.IsNoRows(err):
			return nil, err
		}
	}
	for _, r := range rows {
		if seen[r.ID] {
			continue
		}
		found = append(found, FoundGroup{
			ID: r.ID, Title: titleOf(r.Department, r.Batch, r.Section), Department: r.Department,
			Batch: r.Batch, Section: r.Section, Semester: r.Semester, MemberCount: r.MemberCount,
		})
	}
	if err := s.decorate(ctx, q, c.UserID, found); err != nil {
		return nil, err
	}
	return &SearchResult{Items: found, More: more}, nil
}

// Similar lists groups that may already be the one a CR is about to create
// (same university, department and batch; the same or no section).
func (s *Service) Similar(ctx context.Context, department, batch, section string) ([]FoundGroup, error) {
	c := auth.MustUser(ctx)
	if c.UniversityID == uuid.Nil {
		return nil, ErrUniversityRequired
	}
	department, batch, section = clean(department), clean(batch), clean(section)
	if department == "" || batch == "" {
		return []FoundGroup{}, nil
	}
	q := store.New(s.d.Q(ctx))
	rows, err := q.SimilarGroups(ctx, store.SimilarGroupsParams{
		UniversityID: c.UniversityID, Department: department, Batch: batch, Section: section,
	})
	if err != nil {
		return nil, err
	}
	found := make([]FoundGroup, 0, len(rows))
	for _, r := range rows {
		found = append(found, FoundGroup{
			ID: r.ID, Title: titleOf(r.Department, r.Batch, r.Section), Department: r.Department,
			Batch: r.Batch, Section: r.Section, Semester: r.Semester, MemberCount: r.MemberCount,
		})
	}
	if err := s.decorate(ctx, q, c.UserID, found); err != nil {
		return nil, err
	}
	return found, nil
}

// decorate adds courses, the CR's name and the caller's membership.
func (s *Service) decorate(ctx context.Context, q *store.Queries, me uuid.UUID, groups []FoundGroup) error {
	if len(groups) == 0 {
		return nil
	}
	ids := make([]uuid.UUID, len(groups))
	at := make(map[uuid.UUID]int, len(groups))
	for i := range groups {
		ids[i], at[groups[i].ID] = groups[i].ID, i
		groups[i].Courses = []Course{}
	}
	courses, err := q.GroupCourses(ctx, ids)
	if err != nil {
		return err
	}
	for _, r := range courses {
		g := &groups[at[r.GroupID]]
		g.Courses = append(g.Courses, Course{Key: CourseKey(r.CourseCode), Code: r.CourseCode, Title: r.CourseTitle, Teacher: r.Teacher})
	}
	crs, err := q.GroupCRNames(ctx, ids)
	if err != nil {
		return err
	}
	for _, r := range crs {
		groups[at[r.GroupID]].CRName = r.DisplayName
	}
	mine, err := q.MyMemberships(ctx, store.MyMembershipsParams{UserID: me, GroupIds: ids})
	if err != nil {
		return err
	}
	for _, id := range mine {
		groups[at[id]].IsMember = true
	}
	return nil
}

// visibleGroup loads a group the caller may look at: their university, and
// findable, or they are a member, or they have its code.
func (s *Service) visibleGroup(ctx context.Context, q *store.Queries, c *auth.Claims, id uuid.UUID, code string, forUpdate bool) (store.ClassGroup, bool, error) {
	if c.UniversityID == uuid.Nil {
		return store.ClassGroup{}, false, ErrUniversityRequired
	}
	var (
		g   store.ClassGroup
		err error
	)
	if forUpdate {
		g, err = q.GetGroupForUpdate(ctx, id)
	} else {
		g, err = q.GetGroup(ctx, id)
	}
	if db.IsNoRows(err) || (err == nil && g.UniversityID != c.UniversityID) {
		return g, false, ErrGroupNotFound
	}
	if err != nil {
		return g, false, err
	}
	_, err = q.GetRole(ctx, store.GetRoleParams{GroupID: id, UserID: c.UserID})
	member := err == nil
	if err != nil && !db.IsNoRows(err) {
		return g, false, err
	}
	withCode := code != "" && strings.ToUpper(strings.TrimSpace(code)) == g.JoinCode
	if !g.Discoverable && !member && !withCode {
		return g, false, ErrGroupNotFound
	}
	return g, member, nil
}

// RoutinePreview shows a group's weekly routine and courses (no members,
// announcements or changes).
func (s *Service) RoutinePreview(ctx context.Context, id uuid.UUID, code string) (*RoutinePreview, error) {
	c := auth.MustUser(ctx)
	q := store.New(s.d.Q(ctx))
	g, member, err := s.visibleGroup(ctx, q, c, id, code, false)
	if err != nil {
		return nil, err
	}
	n, err := q.CountMembers(ctx, id)
	if err != nil {
		return nil, err
	}
	found := []FoundGroup{{
		ID: g.ID, Title: titleOf(g.Department, g.Batch, g.Section), Department: g.Department,
		Batch: g.Batch, Section: g.Section, Semester: g.Semester, MemberCount: n,
	}}
	if err := s.decorate(ctx, q, c.UserID, found); err != nil {
		return nil, err
	}
	slots, err := q.ListSlots(ctx, id)
	if err != nil {
		return nil, err
	}
	out := &RoutinePreview{FoundGroup: found[0], Slots: make([]Slot, 0, len(slots)), HiddenCourses: []string{}}
	for _, sl := range slots {
		out.Slots = append(out.Slots, slotView(sl))
	}
	if member {
		hidden, err := q.ListHiddenForUser(ctx, c.UserID)
		if err != nil {
			return nil, err
		}
		for _, h := range hidden {
			if h.GroupID == id {
				out.HiddenCourses = append(out.HiddenCourses, h.CourseKey)
			}
		}
	}
	return out, nil
}

// JoinCourses joins the group for some of its courses only: every other
// course is hidden for the caller, and courses the CR adds later stay
// hidden too. Picking every course is the same as joining the whole
// section. A member can call it again to change their courses.
func (s *Service) JoinCourses(ctx context.Context, id uuid.UUID, courses []string, code string) (*Group, error) {
	c := auth.MustUser(ctx)
	picked := map[string]bool{}
	for _, cc := range courses {
		if k := CourseKey(cc); k != "" {
			picked[k] = true
		}
	}
	err := s.d.InTx(ctx, func(ctx context.Context) error {
		q := store.New(s.d.Q(ctx))
		g, member, err := s.visibleGroup(ctx, q, c, id, code, true) // locked: serialises joins
		if err != nil {
			return err
		}
		slots, err := q.ListSlots(ctx, g.ID)
		if err != nil {
			return err
		}
		all := map[string]bool{}
		for _, sl := range slots {
			all[CourseKey(sl.CourseCode)] = true
		}
		// No courses picked: fine only while the routine is still empty
		// (joining the whole section before the CR adds classes).
		if len(picked) == 0 && len(all) > 0 {
			return apperr.Validation(map[string]string{"courses": "pick at least one course"})
		}
		for k := range picked {
			if !all[k] {
				return apperr.Validation(map[string]string{"courses": k + " is not in this routine"})
			}
		}
		if !member {
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
			if err := q.AddMember(ctx, store.AddMemberParams{GroupID: g.ID, UserID: c.UserID, Role: RoleMember}); err != nil {
				return err
			}
		}
		if err := q.ClearHidden(ctx, store.ClearHiddenParams{GroupID: g.ID, UserID: c.UserID}); err != nil {
			return err
		}
		for k := range all {
			if picked[k] {
				continue
			}
			if err := q.AddHidden(ctx, store.AddHiddenParams{GroupID: g.ID, UserID: c.UserID, CourseKey: k}); err != nil {
				return err
			}
		}
		return q.SetCoursesOnly(ctx, store.SetCoursesOnlyParams{
			GroupID: g.ID, UserID: c.UserID, CoursesOnly: len(picked) < len(all),
		})
	})
	if err != nil {
		return nil, err
	}
	return s.myGroup(ctx, id)
}

// hideNewCourse keeps a course new to the group hidden for members who
// joined for some courses only.
func hideNewCourse(ctx context.Context, q *store.Queries, groupID uuid.UUID, sl store.RoutineSlot) error {
	return q.HideNewCourseForSelective(ctx, store.HideNewCourseForSelectiveParams{
		GroupID: groupID, SlotID: sl.ID, CourseKey: CourseKey(sl.CourseCode),
	})
}

func atoiOr(s string, def int) int {
	if n, err := strconv.Atoi(s); err == nil {
		return n
	}
	return def
}
