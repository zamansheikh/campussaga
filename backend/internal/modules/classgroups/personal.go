package classgroups

import (
	"context"

	"github.com/google/uuid"

	"github.com/zamansheikh/campussaga/backend/internal/modules/classgroups/store"
	"github.com/zamansheikh/campussaga/backend/internal/platform/apperr"
	"github.com/zamansheikh/campussaga/backend/internal/platform/auth"
	"github.com/zamansheikh/campussaga/backend/internal/platform/db"
)

// MaxPersonal entries per student.
const MaxPersonal = 50

// PersonalClass is a student's own weekly entry, seen only by them.
type PersonalClass struct {
	ID      uuid.UUID `json:"id"`
	Title   string    `json:"title"`
	Details string    `json:"details"`
	Place   string    `json:"place"`
	Weekday int       `json:"weekday"`
	Start   string    `json:"start"`
	End     string    `json:"end"`
}

type PersonalInput struct {
	Title   string `json:"title" validate:"required,max=40"`
	Details string `json:"details" validate:"max=100"`
	Place   string `json:"place" validate:"max=40"`
	Weekday int    `json:"weekday" validate:"min=1,max=7"`
	Start   string `json:"start" validate:"required"`
	End     string `json:"end" validate:"required"`

	startMin, endMin int16
}

func (in *PersonalInput) clean() error {
	in.Title, in.Details, in.Place = clean(in.Title), clean(in.Details), clean(in.Place)
	if err := required(map[string]string{"title": in.Title}); err != nil {
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

func (s *Service) MyPersonal(ctx context.Context) ([]PersonalClass, error) {
	c := auth.MustUser(ctx)
	rows, err := store.New(s.d.Q(ctx)).ListPersonal(ctx, c.UserID)
	if err != nil {
		return nil, err
	}
	out := make([]PersonalClass, 0, len(rows))
	for _, r := range rows {
		out = append(out, personalView(r))
	}
	return out, nil
}

func (s *Service) AddPersonal(ctx context.Context, in *PersonalInput) (*PersonalClass, error) {
	c := auth.MustUser(ctx)
	if err := in.clean(); err != nil {
		return nil, err
	}
	var out *PersonalClass
	err := s.d.InTx(ctx, func(ctx context.Context) error {
		q := store.New(s.d.Q(ctx))
		n, err := q.CountPersonal(ctx, c.UserID)
		if err != nil {
			return err
		}
		if n >= MaxPersonal {
			return ErrPersonalLimit
		}
		r, err := q.CreatePersonal(ctx, store.CreatePersonalParams{
			UserID: c.UserID, Title: in.Title, Details: in.Details, Place: in.Place,
			Weekday: int16(in.Weekday), StartsMin: in.startMin, EndsMin: in.endMin,
		})
		if err != nil {
			return err
		}
		v := personalView(r)
		out = &v
		return nil
	})
	return out, err
}

func (s *Service) UpdatePersonal(ctx context.Context, id uuid.UUID, in *PersonalInput) (*PersonalClass, error) {
	c := auth.MustUser(ctx)
	if err := in.clean(); err != nil {
		return nil, err
	}
	r, err := store.New(s.d.Q(ctx)).UpdatePersonal(ctx, store.UpdatePersonalParams{
		ID: id, UserID: c.UserID, Title: in.Title, Details: in.Details, Place: in.Place,
		Weekday: int16(in.Weekday), StartsMin: in.startMin, EndsMin: in.endMin,
	})
	if db.IsNoRows(err) {
		return nil, ErrSlotNotFound
	}
	if err != nil {
		return nil, err
	}
	v := personalView(r)
	return &v, nil
}

func (s *Service) DeletePersonal(ctx context.Context, id uuid.UUID) error {
	c := auth.MustUser(ctx)
	n, err := store.New(s.d.Q(ctx)).DeletePersonal(ctx, store.DeletePersonalParams{ID: id, UserID: c.UserID})
	if err != nil {
		return err
	}
	if n == 0 {
		return ErrSlotNotFound
	}
	return nil
}

func personalView(r store.PersonalSlot) PersonalClass {
	return PersonalClass{
		ID: r.ID, Title: r.Title, Details: r.Details, Place: r.Place, Weekday: int(r.Weekday),
		Start: formatClock(r.StartsMin), End: formatClock(r.EndsMin),
	}
}
