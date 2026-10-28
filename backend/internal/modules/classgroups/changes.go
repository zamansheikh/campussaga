package classgroups

import (
	"context"
	"time"
	_ "time/tzdata" // the server image has no zoneinfo

	"github.com/google/uuid"

	"github.com/zamansheikh/campussaga/backend/internal/modules/classgroups/store"
	"github.com/zamansheikh/campussaga/backend/internal/platform/apperr"
	"github.com/zamansheikh/campussaga/backend/internal/platform/auth"
	"github.com/zamansheikh/campussaga/backend/internal/platform/db"
)

// Routine dates are Bangladesh dates (every supported university).
var dhaka = mustZone("Asia/Dhaka")

func mustZone(name string) *time.Location {
	l, err := time.LoadLocation(name)
	if err != nil {
		panic(err)
	}
	return l
}

const (
	ChangeCancelled = "cancelled"
	ChangeMoved     = "moved"
	ChangeExtra     = "extra"

	// How far ahead a change can be made, and how many may be pending.
	MaxChangeDays     = 180
	MaxPendingChanges = 200
)

// Change is a change to the routine on one date. Cancelled and moved
// changes point at a weekly class (SlotID); extra classes carry their own
// course. Start/End are set for moved and extra; Room "" on a moved class
// means the room is unchanged.
type Change struct {
	ID          uuid.UUID  `json:"id"`
	Kind        string     `json:"kind"`
	SlotID      *uuid.UUID `json:"slotId"`
	Date        string     `json:"date"`
	CourseCode  string     `json:"courseCode"`
	CourseTitle string     `json:"courseTitle"`
	Teacher     string     `json:"teacher"`
	ClassKind   string     `json:"classKind"`
	Room        string     `json:"room"`
	Start       *string    `json:"start"`
	End         *string    `json:"end"`
	Note        string     `json:"note"`
	// NewDate: a moved class happens on this day instead (null = same day).
	NewDate *string `json:"newDate"`
}

// ChangeInput creates a change (CR).
type ChangeInput struct {
	Kind        string `json:"kind" validate:"required,oneof=cancelled moved extra"`
	SlotID      string `json:"slotId" validate:"omitempty,uuid"`
	Date        string `json:"date" validate:"required"`
	Start       string `json:"start"`
	End         string `json:"end"`
	Room        string `json:"room" validate:"max=30"`
	CourseCode  string `json:"courseCode" validate:"max=20"`
	CourseTitle string `json:"courseTitle" validate:"max=100"`
	Teacher     string `json:"teacher" validate:"max=60"`
	ClassKind   string `json:"classKind" validate:"omitempty,oneof=theory lab"`
	Note        string `json:"note" validate:"max=200"`
	// NewDate moves the class to another day (moved only; "" = same day).
	NewDate string `json:"newDate"`

	date             time.Time
	newDate          *time.Time
	slot             *uuid.UUID
	startMin, endMin *int16
}

// today is the current Bangladesh date at midnight (as a UTC date value).
func (s *Service) today() time.Time {
	t := s.now().In(dhaka)
	return time.Date(t.Year(), t.Month(), t.Day(), 0, 0, 0, 0, time.UTC)
}

func (in *ChangeInput) clean(today time.Time) error {
	in.Room, in.Note = clean(in.Room), clean(in.Note)
	in.CourseCode, in.CourseTitle, in.Teacher = clean(in.CourseCode), clean(in.CourseTitle), clean(in.Teacher)
	if in.ClassKind == "" {
		in.ClassKind = "theory"
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

	if in.NewDate != "" && in.NewDate != in.Date {
		if in.Kind != ChangeMoved {
			return apperr.Validation(map[string]string{"newDate": "only a moved class has a new day"})
		}
		nd, err := time.Parse("2006-01-02", in.NewDate)
		switch {
		case err != nil:
			return apperr.Validation(map[string]string{"newDate": "must be a date like 2026-10-28"})
		case nd.Before(today):
			return apperr.Validation(map[string]string{"newDate": "must be today or later"})
		case nd.After(today.AddDate(0, 0, MaxChangeDays)):
			return apperr.Validation(map[string]string{"newDate": "is too far ahead"})
		}
		in.newDate = &nd
	}

	if in.Kind == ChangeExtra {
		if in.SlotID != "" {
			return apperr.Validation(map[string]string{"slotId": "must be empty for an extra class"})
		}
		if err := required(map[string]string{"courseCode": in.CourseCode}); err != nil {
			return err
		}
	} else {
		if in.SlotID == "" {
			return apperr.Validation(map[string]string{"slotId": "is required"})
		}
		id := uuid.MustParse(in.SlotID)
		in.slot = &id
	}

	if in.Kind == ChangeCancelled {
		return nil
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
	in.startMin, in.endMin = &start, &end
	return nil
}

// AddChange records a change for one date (CR). A new change for a class
// on a date replaces the previous one.
func (s *Service) AddChange(ctx context.Context, groupID uuid.UUID, in *ChangeInput) (*Change, error) {
	c := auth.MustUser(ctx)
	today := s.today()
	if err := in.clean(today); err != nil {
		return nil, err
	}
	var out *Change
	err := s.d.InTx(ctx, func(ctx context.Context) error {
		q := store.New(s.d.Q(ctx))
		if err := s.requireCR(ctx, q, groupID, c.UserID); err != nil {
			return err
		}
		var slotRow *store.RoutineSlot
		if in.slot != nil {
			slot, err := q.GetSlot(ctx, store.GetSlotParams{ID: *in.slot, GroupID: groupID})
			if db.IsNoRows(err) {
				return ErrSlotNotFound
			}
			if err != nil {
				return err
			}
			if int(slot.Weekday) != isoWeekday(in.date) {
				return apperr.Validation(map[string]string{"date": "is not a day this class meets"})
			}
			if err := q.DeleteSlotChangeOn(ctx, store.DeleteSlotChangeOnParams{SlotID: in.slot, Date: in.date}); err != nil {
				return err
			}
			slotRow = &slot
		}
		n, err := q.CountUpcomingChanges(ctx, store.CountUpcomingChangesParams{GroupID: groupID, FromDate: today})
		if err != nil {
			return err
		}
		if n >= MaxPendingChanges {
			return ErrChangeLimit
		}
		ch, err := q.CreateChange(ctx, store.CreateChangeParams{
			GroupID: groupID, SlotID: in.slot, Date: in.date, Kind: in.Kind,
			CourseCode: in.CourseCode, CourseTitle: in.CourseTitle, Teacher: in.Teacher,
			ClassKind: in.ClassKind, Room: in.Room, StartsMin: in.startMin, EndsMin: in.endMin,
			Note: in.Note, CreatedBy: &c.UserID, NewDate: in.newDate,
		})
		if err != nil {
			return err
		}
		v := changeView(ch)
		out = &v
		if err := q.TouchGroup(ctx, groupID); err != nil {
			return err
		}
		g, err := q.GetGroup(ctx, groupID)
		if err != nil {
			return err
		}
		return s.tellClassmates(ctx, q, groupID, c.UserID, s.changeNotice(g, ch, slotRow, false))
	})
	return out, err
}

// DeleteChange undoes a change (CR).
func (s *Service) DeleteChange(ctx context.Context, groupID, changeID uuid.UUID) error {
	c := auth.MustUser(ctx)
	return s.d.InTx(ctx, func(ctx context.Context) error {
		q := store.New(s.d.Q(ctx))
		if err := s.requireCR(ctx, q, groupID, c.UserID); err != nil {
			return err
		}
		ch, err := q.GetChange(ctx, store.GetChangeParams{ID: changeID, GroupID: groupID})
		if db.IsNoRows(err) {
			return ErrChangeNotFound
		}
		if err != nil {
			return err
		}
		if _, err := q.DeleteChange(ctx, store.DeleteChangeParams{ID: changeID, GroupID: groupID}); err != nil {
			return err
		}
		if err := q.TouchGroup(ctx, groupID); err != nil {
			return err
		}
		last := ch.Date
		if ch.NewDate != nil && ch.NewDate.After(last) {
			last = *ch.NewDate
		}
		if last.Before(s.today()) {
			return nil // a past change: nothing to tell
		}
		var slot *store.RoutineSlot
		if ch.SlotID != nil {
			sl, err := q.GetSlot(ctx, store.GetSlotParams{ID: *ch.SlotID, GroupID: groupID})
			if err != nil {
				return err
			}
			slot = &sl
		}
		g, err := q.GetGroup(ctx, groupID)
		if err != nil {
			return err
		}
		return s.tellClassmates(ctx, q, groupID, c.UserID, s.changeNotice(g, ch, slot, true))
	})
}

func changeView(c store.RoutineChange) Change {
	clock := func(m *int16) *string {
		if m == nil {
			return nil
		}
		v := formatClock(*m)
		return &v
	}
	return Change{
		ID: c.ID, Kind: c.Kind, SlotID: c.SlotID, Date: c.Date.Format("2006-01-02"),
		CourseCode: c.CourseCode, CourseTitle: c.CourseTitle, Teacher: c.Teacher,
		ClassKind: c.ClassKind, Room: c.Room, Start: clock(c.StartsMin), End: clock(c.EndsMin),
		Note: c.Note, NewDate: dateText(c.NewDate),
	}
}

func dateText(d *time.Time) *string {
	if d == nil {
		return nil
	}
	v := d.Format("2006-01-02")
	return &v
}

// isoWeekday: 1 = Monday ... 7 = Sunday.
func isoWeekday(t time.Time) int { return (int(t.Weekday())+6)%7 + 1 }
