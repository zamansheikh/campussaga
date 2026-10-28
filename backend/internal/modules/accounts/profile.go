package accounts

import (
	"context"
	"strings"
	"time"

	"github.com/google/uuid"

	"github.com/zamansheikh/varsitykotha/backend/internal/modules/accounts/store"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/auth"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/db"
)

// Me is the signed-in student's own profile. It is the only place an
// email address is ever returned, and only to its owner.
type Me struct {
	ID    uuid.UUID `json:"id"`
	Email string    `json:"email"`
	// University: null until a not-verified student picks one.
	University  *University `json:"university"`
	DisplayName *string     `json:"displayName"`
	Department  *string     `json:"department"`
	Batch       *string     `json:"batch"`
	Role        string      `json:"role"`
	// Verified: proved a university email (signing in with one, or later).
	Verified        bool       `json:"verified"`
	UniversityEmail *string    `json:"universityEmail"`
	VerifiedAt      *time.Time `json:"verifiedAt"`
	CreatedAt       time.Time  `json:"createdAt"`
}

func (s *Service) meView(ctx context.Context, u store.User) (*Me, error) {
	var uni *University
	if u.UniversityID != nil {
		var err error
		if uni, err = s.unis.Get(ctx, *u.UniversityID); err != nil {
			return nil, err
		}
	}
	return &Me{
		ID: u.ID, Email: u.Email, University: uni,
		DisplayName: u.DisplayName, Department: u.Department, Batch: u.Batch,
		Role: string(u.Role), Verified: u.VerifiedAt != nil, UniversityEmail: u.UniversityEmail,
		VerifiedAt: u.VerifiedAt, CreatedAt: u.CreatedAt,
	}, nil
}

// GetMe returns the caller's profile.
func (s *Service) GetMe(ctx context.Context) (*Me, error) {
	c := auth.MustUser(ctx)
	u, err := store.New(s.d.Q(ctx)).GetUser(ctx, c.UserID)
	if db.IsNoRows(err) {
		return nil, ErrSessionEnded
	}
	if err != nil {
		return nil, err
	}
	return s.meView(ctx, u)
}

// ProfilePatch: a nil field is left unchanged; an empty string clears it.
type ProfilePatch struct {
	DisplayName *string `json:"displayName" validate:"omitnil,max=60"`
	Department  *string `json:"department" validate:"omitnil,max=80"`
	Batch       *string `json:"batch" validate:"omitnil,max=20"`
}

// UpdateMe edits the caller's own profile. Only these three fields exist in
// the request type, so role, email and university can never be changed here.
func (s *Service) UpdateMe(ctx context.Context, p *ProfilePatch) (*Me, error) {
	c := auth.MustUser(ctx)
	var out *Me
	err := s.d.InTx(ctx, func(ctx context.Context) error {
		q := store.New(s.d.Q(ctx))
		u, err := q.GetUser(ctx, c.UserID)
		if db.IsNoRows(err) {
			return ErrSessionEnded
		}
		if err != nil {
			return err
		}
		u, err = q.UpdateProfile(ctx, store.UpdateProfileParams{
			ID:          u.ID,
			DisplayName: apply(u.DisplayName, p.DisplayName),
			Department:  apply(u.Department, p.Department),
			Batch:       apply(u.Batch, p.Batch),
		})
		if err != nil {
			return err
		}
		out, err = s.meView(ctx, u)
		return err
	})
	return out, err
}

func apply(current, patch *string) *string {
	if patch == nil {
		return current
	}
	v := strings.Join(strings.Fields(*patch), " ")
	if v == "" {
		return nil
	}
	return &v
}

// DepartmentSuggestions returns departments other students at the caller's
// university have entered that contain q (any case), most used first.
// Only department names are returned, never who entered them.
func (s *Service) DepartmentSuggestions(ctx context.Context, q string) ([]string, error) {
	c := auth.MustUser(ctx)
	if c.UniversityID == uuid.Nil {
		return []string{}, nil
	}
	q = strings.Join(strings.Fields(q), " ")
	out, err := store.New(s.d.Q(ctx)).DepartmentSuggestions(ctx, store.DepartmentSuggestionsParams{
		UniversityID: &c.UniversityID, Q: q, MaxResults: 10,
	})
	if err != nil {
		return nil, err
	}
	return out, nil
}

// DeleteMe deletes the caller's account and everything that belongs to it
// (sessions cascade). Required by the Play Store and our privacy promise.
func (s *Service) DeleteMe(ctx context.Context) error {
	c := auth.MustUser(ctx)
	_, err := store.New(s.d.Q(ctx)).DeleteUser(ctx, c.UserID)
	return err
}
