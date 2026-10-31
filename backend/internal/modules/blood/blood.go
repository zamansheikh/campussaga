// Package blood is blood donation (docs/BLOOD_DONATION.md): students post
// blood requests, same-university donors of the same group get a push and
// answer "I can donate".
//
//   - GET/PUT/DELETE /blood/me       the caller's donor profile
//   - POST /blood/me/donated         record a donation
//   - GET/POST /blood/requests       open / mine lists, post a request
//   - GET /blood/requests/{id}       one request
//   - POST/DELETE /blood/requests/{id}/respond   "I can donate" / withdraw
//   - POST /blood/requests/{id}/close            fulfilled / cancelled
//
// Privacy: a donor's blood group is health data. It is shown to its owner
// and, when the donor responds, to that request's requester. A donor's
// phone goes only to the requester. Nobody can list donors; the only
// aggregate is a count on a request. Responses are returned to the
// requester only; everyone else always gets an empty list.
package blood

import (
	"context"
	"time"

	"github.com/google/uuid"

	"github.com/zamansheikh/varsitykotha/backend/internal/modules/blood/store"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/apperr"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/auth"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/db"
)

// Rules of docs/BLOOD_DONATION.md §1.
const (
	// DonorRestDays: days between donations before a donor is eligible.
	DonorRestDays = 120
	// MaxDonorsPerRequest: pushes sent for one request.
	MaxDonorsPerRequest = 300
	// MaxPushesPerDonorPerDay: request pushes a donor gets in 24 hours.
	MaxPushesPerDonorPerDay = 3

	MaxRequestsPerDay = 3
	MaxOpenRequests   = 3
	pageSize          = 20
	expireAfter       = 24 * time.Hour
)

// Groups are the wire blood groups.
var Groups = []string{"A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"}

var dhaka = mustZone("Asia/Dhaka")

func mustZone(name string) *time.Location {
	l, err := time.LoadLocation(name)
	if err != nil {
		return time.FixedZone(name, 6*3600)
	}
	return l
}

// Service is the blood donation module.
type Service struct {
	d      *db.DB
	now    func() time.Time
	notify Notifier // nil = no pushes
	// maxDonors caps pushes per request (a field so tests can lower it).
	maxDonors int
}

func NewService(d *db.DB, now func() time.Time) *Service {
	return &Service{d: d, now: now, maxDonors: MaxDonorsPerRequest}
}

// SetMaxDonorsPerRequest lowers the per-request push cap (tests).
func (s *Service) SetMaxDonorsPerRequest(n int) { s.maxDonors = n }

// today is the current Bangladesh calendar date at 00:00 UTC.
func (s *Service) today() time.Time {
	t := s.now().In(dhaka)
	return time.Date(t.Year(), t.Month(), t.Day(), 0, 0, 0, 0, time.UTC)
}

// caller returns the signed-in student; they need a university.
func caller(ctx context.Context) (*auth.Claims, error) {
	c := auth.MustUser(ctx)
	if c.UniversityID == uuid.Nil {
		return c, ErrUniversityRequired
	}
	return c, nil
}

// ---- the donor profile ---------------------------------------------------------

// Donor is the caller's own donor profile.
type Donor struct {
	BloodGroup    string  `json:"bloodGroup"`
	Available     bool    `json:"available"`
	Phone         string  `json:"phone"`
	LastDonated   *string `json:"lastDonated"`
	Donations     int     `json:"donations"`
	CanDonateFrom *string `json:"canDonateFrom"`
	Eligible      bool    `json:"eligible"`
}

const dateLayout = "2006-01-02"

// canDonateFrom is the first day a donor who gave blood on last may give
// again.
func canDonateFrom(last time.Time) time.Time { return last.AddDate(0, 0, DonorRestDays) }

// eligible: available, and no donation within the last 120 days.
func eligible(available bool, last *time.Time, today time.Time) bool {
	if !available {
		return false
	}
	return last == nil || !today.Before(canDonateFrom(*last))
}

func (s *Service) donorView(d store.BloodDonor) *Donor {
	out := &Donor{
		BloodGroup: d.BloodGroup, Available: d.Available, Phone: d.Phone,
		Donations: int(d.Donations), Eligible: eligible(d.Available, d.LastDonated, s.today()),
	}
	if d.LastDonated != nil {
		l := d.LastDonated.Format(dateLayout)
		c := canDonateFrom(*d.LastDonated).Format(dateLayout)
		out.LastDonated, out.CanDonateFrom = &l, &c
	}
	return out
}

type donorRes struct {
	Donor *Donor `json:"donor"`
}

// MyDonor is GET /blood/me.
func (s *Service) MyDonor(ctx context.Context) (*donorRes, error) {
	c, err := caller(ctx)
	if err != nil {
		return nil, err
	}
	d, err := store.New(s.d.Q(ctx)).GetDonor(ctx, c.UserID)
	if db.IsNoRows(err) {
		return &donorRes{}, nil
	}
	if err != nil {
		return nil, err
	}
	return &donorRes{Donor: s.donorView(d)}, nil
}

// DonorInput is PUT /blood/me.
type DonorInput struct {
	BloodGroup  string  `json:"bloodGroup" validate:"required,oneof=A+ A- B+ B- AB+ AB- O+ O-"`
	Available   bool    `json:"available"`
	Phone       string  `json:"phone" validate:"max=40"`
	LastDonated *string `json:"lastDonated" validate:"omitnil,max=10"`
}

// SaveDonor creates or updates the caller's donor profile.
func (s *Service) SaveDonor(ctx context.Context, in *DonorInput) (*Donor, error) {
	c, err := caller(ctx)
	if err != nil {
		return nil, err
	}
	phone := ""
	if in.Phone != "" {
		p, ok := cleanPhone(in.Phone)
		if !ok {
			return nil, apperr.Validation(map[string]string{"phone": phoneProblem})
		}
		phone = p
	}
	var last *time.Time
	if in.LastDonated != nil {
		t, err := s.parseDate(*in.LastDonated)
		if err != nil {
			return nil, apperr.Validation(map[string]string{"lastDonated": err.Error()})
		}
		last = &t
	}
	d, err := store.New(s.d.Q(ctx)).UpsertDonor(ctx, store.UpsertDonorParams{
		UserID: c.UserID, BloodGroup: in.BloodGroup, Available: in.Available, Phone: phone, LastDonated: last,
	})
	if err != nil {
		return nil, err
	}
	return s.donorView(d), nil
}

// parseDate reads "YYYY-MM-DD"; a date after today (Bangladesh) is refused.
func (s *Service) parseDate(v string) (time.Time, error) {
	t, err := time.Parse(dateLayout, v)
	if err != nil {
		return t, errBadDate
	}
	if t.After(s.today()) {
		return t, errFutureDate
	}
	return t, nil
}

type dateError string

func (e dateError) Error() string { return string(e) }

const (
	errBadDate    dateError = "must be a date like 2026-07-01"
	errFutureDate dateError = "can't be in the future"
)

// StopDonating is DELETE /blood/me. Responses already given stay.
func (s *Service) StopDonating(ctx context.Context) error {
	c, err := caller(ctx)
	if err != nil {
		return err
	}
	return store.New(s.d.Q(ctx)).DeleteDonor(ctx, c.UserID)
}

// DonatedInput is POST /blood/me/donated.
type DonatedInput struct {
	Date *string `json:"date" validate:"omitnil,max=10"`
}

// Donated records a donation: last donated moves to date (if later) and the
// count goes up by one.
func (s *Service) Donated(ctx context.Context, in *DonatedInput) (*Donor, error) {
	c, err := caller(ctx)
	if err != nil {
		return nil, err
	}
	date := s.today()
	if in.Date != nil && *in.Date != "" {
		t, err := s.parseDate(*in.Date)
		if err != nil {
			return nil, apperr.Validation(map[string]string{"date": err.Error()})
		}
		date = t
	}
	d, err := store.New(s.d.Q(ctx)).MarkDonated(ctx, store.MarkDonatedParams{UserID: c.UserID, Date: date})
	if db.IsNoRows(err) {
		return nil, ErrDonorRequired
	}
	if err != nil {
		return nil, err
	}
	return s.donorView(d), nil
}
