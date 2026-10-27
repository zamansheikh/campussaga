package accounts

import (
	"context"

	"github.com/google/uuid"

	"github.com/zamansheikh/campussaga/backend/internal/modules/accounts/store"
	"github.com/zamansheikh/campussaga/backend/internal/platform/auth"
	"github.com/zamansheikh/campussaga/backend/internal/platform/db"
)

// SetUniversity: a not-verified student (signed in with Gmail) picks their
// university. A verified student's university comes from their email and
// can't be changed here.
func (s *Service) SetUniversity(ctx context.Context, universityID uuid.UUID) (*Me, error) {
	c := auth.MustUser(ctx)
	uni, err := s.unis.Get(ctx, universityID)
	if db.IsNoRows(err) || (err == nil && uni == nil) {
		return nil, ErrUniversityNotFound
	}
	if err != nil {
		return nil, err
	}
	u, err := store.New(s.d.Q(ctx)).SetUniversity(ctx, store.SetUniversityParams{ID: c.UserID, UniversityID: &uni.ID})
	if db.IsNoRows(err) {
		return nil, ErrAlreadyVerified
	}
	if err != nil {
		return nil, err
	}
	return s.meView(ctx, u)
}

// RequestVerifyCode sends a code to a university email the student wants
// to verify with (not-verified students only).
func (s *Service) RequestVerifyCode(ctx context.Context, rawEmail string) (*CodeSent, error) {
	c := auth.MustUser(ctx)
	if c.Verified {
		return nil, ErrAlreadyVerified
	}
	email, err := normalizeEmail(rawEmail)
	if err != nil {
		return nil, err
	}
	uni, err := s.unis.ForEmail(ctx, email)
	if err != nil {
		return nil, err
	}
	if uni == nil {
		return nil, ErrUniversityEmailRequired
	}
	used, err := store.New(s.d.Q(ctx)).EmailInUse(ctx, store.EmailInUseParams{Email: email, ID: c.UserID})
	if err != nil {
		return nil, err
	}
	if used {
		return nil, ErrEmailInUse
	}
	if err := s.sendCode(ctx, email, uni); err != nil {
		return nil, err
	}
	return &CodeSent{
		Email: email, University: uni,
		ExpiresInSeconds:   int(s.cfg.CodeTTL.Seconds()),
		ResendAfterSeconds: int(s.cfg.ResendAfter.Seconds()),
	}, nil
}

// VerifyUniversityEmail checks the code: the student becomes verified at
// that email's university (replacing any university they picked).
func (s *Service) VerifyUniversityEmail(ctx context.Context, rawEmail, code string) (*Me, error) {
	c := auth.MustUser(ctx)
	if c.Verified {
		return nil, ErrAlreadyVerified
	}
	email, err := normalizeEmail(rawEmail)
	if err != nil {
		return nil, err
	}
	now := s.now()
	var (
		out     *Me
		failure error
	)
	err = s.d.InTx(ctx, func(ctx context.Context) error {
		failure, out = nil, nil
		q := store.New(s.d.Q(ctx))
		if err := q.LockEmail(ctx, email); err != nil {
			return err
		}
		row, bad, err := s.consumeCode(ctx, q, email, code, now)
		if err != nil {
			return err
		}
		if bad != nil {
			failure = bad
			return nil // commit the attempt count
		}
		used, err := q.EmailInUse(ctx, store.EmailInUseParams{Email: email, ID: c.UserID})
		if err != nil {
			return err
		}
		if used {
			return ErrEmailInUse
		}
		u, err := q.VerifyUser(ctx, store.VerifyUserParams{
			ID: c.UserID, UniversityEmail: &email, UniversityID: &row.UniversityID, VerifiedAt: &now,
		})
		if err != nil {
			return err
		}
		out, err = s.meView(ctx, u)
		return err
	})
	if err != nil {
		return nil, err
	}
	if failure != nil {
		return nil, failure
	}
	return out, nil
}
