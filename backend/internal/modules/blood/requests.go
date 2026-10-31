package blood

import (
	"context"
	"encoding/base64"
	"strconv"
	"strings"
	"time"
	"unicode/utf8"

	"github.com/google/uuid"

	"github.com/zamansheikh/varsitykotha/backend/internal/modules/blood/store"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/apperr"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/db"
)

// Request is a blood request as the caller sees it.
type Request struct {
	ID             uuid.UUID  `json:"id"`
	BloodGroup     string     `json:"bloodGroup"`
	Units          int        `json:"units"`
	Hospital       string     `json:"hospital"`
	Area           string     `json:"area"`
	NeededBy       time.Time  `json:"neededBy"`
	Urgent         bool       `json:"urgent"`
	ContactName    string     `json:"contactName"`
	ContactPhone   string     `json:"contactPhone"`
	Note           string     `json:"note"`
	Status         string     `json:"status"`
	CreatedAt      time.Time  `json:"createdAt"`
	ResponseCount  int        `json:"responseCount"`
	Notified       int        `json:"notified"`
	MatchingDonors int        `json:"matchingDonors"`
	Mine           bool       `json:"mine"`
	Responded      bool       `json:"responded"`
	Responses      []Response `json:"responses"`
}

// Response is one donor's "I can donate", visible to the requester only.
type Response struct {
	Name       string    `json:"name"`
	BloodGroup string    `json:"bloodGroup"`
	Phone      string    `json:"phone"`
	CreatedAt  time.Time `json:"createdAt"`
}

// Page is a page of a list.
type Page struct {
	Items      []Request `json:"items"`
	NextCursor *string   `json:"nextCursor"`
}

// row is a request with the counts every read carries.
type row struct {
	r         store.BloodRequest
	responses int64
	matching  int64
	responded bool
}

func (s *Service) status(r store.BloodRequest) string {
	if r.Status == "open" && r.NeededBy.Before(s.now().Add(-expireAfter)) {
		return "expired"
	}
	return r.Status
}

// views builds the caller's view of rows. Only the requester gets responses.
func (s *Service) views(ctx context.Context, q *store.Queries, viewer uuid.UUID, rows []row) ([]Request, error) {
	var mine []uuid.UUID
	for _, x := range rows {
		if x.r.RequesterID != nil && *x.r.RequesterID == viewer {
			mine = append(mine, x.r.ID)
		}
	}
	byRequest := map[uuid.UUID][]Response{}
	if len(mine) > 0 {
		rs, err := q.ListResponses(ctx, mine)
		if err != nil {
			return nil, err
		}
		for _, x := range rs {
			byRequest[x.RequestID] = append(byRequest[x.RequestID], Response{
				Name: x.Name, BloodGroup: x.BloodGroup, Phone: x.Phone, CreatedAt: x.CreatedAt,
			})
		}
	}
	out := make([]Request, 0, len(rows))
	for _, x := range rows {
		r := x.r
		isMine := r.RequesterID != nil && *r.RequesterID == viewer
		v := Request{
			ID: r.ID, BloodGroup: r.BloodGroup, Units: int(r.Units), Hospital: r.Hospital, Area: r.Area,
			NeededBy: r.NeededBy, Urgent: r.Urgent, ContactName: r.ContactName, ContactPhone: r.ContactPhone,
			Note: r.Note, Status: s.status(r), CreatedAt: r.CreatedAt, ResponseCount: int(x.responses),
			Notified: int(r.Notified), MatchingDonors: int(x.matching), Mine: isMine, Responded: x.responded,
			Responses: []Response{},
		}
		if isMine && byRequest[r.ID] != nil {
			v.Responses = byRequest[r.ID]
		}
		out = append(out, v)
	}
	return out, nil
}

// one loads a request the caller may see: their university's only.
func (s *Service) one(ctx context.Context, q *store.Queries, viewer, uni, id uuid.UUID) (*Request, error) {
	g, err := q.GetRequest(ctx, store.GetRequestParams{ViewerID: viewer, ID: id})
	if db.IsNoRows(err) || (err == nil && g.BloodRequest.UniversityID != uni) {
		return nil, ErrRequestNotFound
	}
	if err != nil {
		return nil, err
	}
	vs, err := s.views(ctx, q, viewer, []row{{g.BloodRequest, g.ResponseCount, g.MatchingDonors, g.Responded}})
	if err != nil {
		return nil, err
	}
	return &vs[0], nil
}

// Get is GET /blood/requests/{id}.
func (s *Service) Get(ctx context.Context, id uuid.UUID) (*Request, error) {
	c, err := caller(ctx)
	if err != nil {
		return nil, err
	}
	return s.one(ctx, store.New(s.d.Q(ctx)), c.UserID, c.UniversityID, id)
}

// ---- lists ---------------------------------------------------------------------

// ListInput is GET /blood/requests.
type ListInput struct {
	View   string `json:"-" query:"view" validate:"omitempty,oneof=open mine"`
	Group  string `json:"-" query:"group" validate:"omitempty,oneof=A+ A- B+ B- AB+ AB- O+ O-"`
	Cursor string `json:"-" query:"cursor" validate:"max=200"`
}

// List is the open view (urgent first, then soonest) or the caller's own.
func (s *Service) List(ctx context.Context, in *ListInput) (*Page, error) {
	c, err := caller(ctx)
	if err != nil {
		return nil, err
	}
	q := store.New(s.d.Q(ctx))
	var rows []row
	var next func(last store.BloodRequest) string
	if in.View == "mine" {
		cur, err := parseKeyCursor(in.Cursor, "m")
		if err != nil {
			return nil, err
		}
		p := store.ListMyRequestsParams{ViewerID: c.UserID, Lim: pageSize + 1}
		if cur != nil {
			p.HasCursor, p.CCreated, p.CID = true, cur.at, cur.id
		}
		rs, err := q.ListMyRequests(ctx, p)
		if err != nil {
			return nil, err
		}
		for _, x := range rs {
			rows = append(rows, row{x.BloodRequest, x.ResponseCount, x.MatchingDonors, x.Responded})
		}
		next = func(l store.BloodRequest) string { return keyCursor("m", false, l.CreatedAt, l.ID) }
	} else {
		cur, err := parseKeyCursor(in.Cursor, "o")
		if err != nil {
			return nil, err
		}
		p := store.ListOpenRequestsParams{
			ViewerID: c.UserID, UniversityID: c.UniversityID, NotBefore: s.now().Add(-expireAfter),
			BloodGroup: in.Group, Lim: pageSize + 1,
		}
		if cur != nil {
			p.HasCursor, p.CUrgent, p.CNeeded, p.CID = true, cur.urgent, cur.at, cur.id
		}
		rs, err := q.ListOpenRequests(ctx, p)
		if err != nil {
			return nil, err
		}
		for _, x := range rs {
			rows = append(rows, row{x.BloodRequest, x.ResponseCount, x.MatchingDonors, x.Responded})
		}
		next = func(l store.BloodRequest) string { return keyCursor("o", l.Urgent, l.NeededBy, l.ID) }
	}
	var nextCursor *string
	if len(rows) > pageSize {
		rows = rows[:pageSize]
		n := next(rows[pageSize-1].r)
		nextCursor = &n
	}
	items, err := s.views(ctx, q, c.UserID, rows)
	if err != nil {
		return nil, err
	}
	return &Page{Items: items, NextCursor: nextCursor}, nil
}

// Cursors are opaque to clients: "<kind>|<urgent 0/1>|<unixnano>|<uuid>".
type cursor struct {
	urgent bool
	at     time.Time
	id     uuid.UUID
}

func keyCursor(kind string, urgent bool, t time.Time, id uuid.UUID) string {
	u := "0"
	if urgent {
		u = "1"
	}
	raw := kind + "|" + u + "|" + strconv.FormatInt(t.UnixNano(), 10) + "|" + id.String()
	return base64.RawURLEncoding.EncodeToString([]byte(raw))
}

func parseKeyCursor(c, kind string) (*cursor, error) {
	if c == "" {
		return nil, nil
	}
	raw, err := base64.RawURLEncoding.DecodeString(c)
	parts := strings.Split(string(raw), "|")
	if err != nil || len(parts) != 4 || parts[0] != kind || (parts[1] != "0" && parts[1] != "1") {
		return nil, ErrBadCursor
	}
	n, err := strconv.ParseInt(parts[2], 10, 64)
	if err != nil {
		return nil, ErrBadCursor
	}
	id, err := uuid.Parse(parts[3])
	if err != nil {
		return nil, ErrBadCursor
	}
	return &cursor{urgent: parts[1] == "1", at: time.Unix(0, n).UTC(), id: id}, nil
}

// ---- posting ---------------------------------------------------------------------

// RequestInput is POST /blood/requests.
type RequestInput struct {
	BloodGroup   string    `json:"bloodGroup" validate:"required,oneof=A+ A- B+ B- AB+ AB- O+ O-"`
	Units        int       `json:"units" validate:"required,min=1,max=10"`
	Hospital     string    `json:"hospital" validate:"required,max=200"`
	Area         string    `json:"area" validate:"max=200"`
	NeededBy     time.Time `json:"neededBy"`
	Urgent       bool      `json:"urgent"`
	ContactName  string    `json:"contactName" validate:"required,max=200"`
	ContactPhone string    `json:"contactPhone" validate:"required,max=40"`
	Note         string    `json:"note" validate:"max=1000"`
}

func (in *RequestInput) clean(now time.Time) error {
	bad := map[string]string{}
	in.Hospital, in.Area = strings.TrimSpace(in.Hospital), strings.TrimSpace(in.Area)
	in.ContactName, in.Note = strings.TrimSpace(in.ContactName), strings.TrimSpace(in.Note)
	if n := utf8.RuneCountInString(in.Hospital); n < 2 || n > 120 {
		bad["hospital"] = "must be 2 to 120 characters"
	}
	if utf8.RuneCountInString(in.Area) > 80 {
		bad["area"] = "is too long"
	}
	if n := utf8.RuneCountInString(in.ContactName); n < 1 || n > 80 {
		bad["contactName"] = "must be 1 to 80 characters"
	}
	if utf8.RuneCountInString(in.Note) > 500 {
		bad["note"] = "is too long"
	}
	if p, ok := cleanPhone(in.ContactPhone); ok {
		in.ContactPhone = p
	} else {
		bad["contactPhone"] = phoneProblem
	}
	if in.NeededBy.IsZero() {
		bad["neededBy"] = "is required"
	} else if in.NeededBy.Before(now.Add(-time.Hour)) || in.NeededBy.After(now.AddDate(0, 0, 30)) {
		bad["neededBy"] = "must be between an hour ago and 30 days from now"
	}
	if len(bad) > 0 {
		return apperr.Validation(bad)
	}
	in.NeededBy = in.NeededBy.UTC()
	return nil
}

// Create posts a request and pushes matching donors after commit.
func (s *Service) Create(ctx context.Context, in *RequestInput) (*Request, error) {
	c, err := caller(ctx)
	if err != nil {
		return nil, err
	}
	if !c.Verified {
		return nil, ErrVerifyRequired
	}
	now := s.now()
	if err := in.clean(now); err != nil {
		return nil, err
	}
	var out *Request
	err = s.d.InTx(ctx, func(ctx context.Context) error {
		q := store.New(s.d.Q(ctx))
		if _, err := q.LockUser(ctx, c.UserID); err != nil {
			return err
		}
		open, err := q.CountOpenRequests(ctx, store.CountOpenRequestsParams{RequesterID: &c.UserID, NotBefore: now.Add(-expireAfter)})
		if err != nil {
			return err
		}
		if open >= MaxOpenRequests {
			return ErrTooManyOpen
		}
		recent, err := q.CountRecentRequests(ctx, store.CountRecentRequestsParams{RequesterID: &c.UserID, Since: now.Add(-24 * time.Hour)})
		if err != nil {
			return err
		}
		if recent >= MaxRequestsPerDay {
			return apperr.TooManyRequests("You can post 3 blood requests a day")
		}
		r, err := q.CreateRequest(ctx, store.CreateRequestParams{
			UniversityID: c.UniversityID, RequesterID: &c.UserID, BloodGroup: in.BloodGroup,
			Units: int16(in.Units), Hospital: in.Hospital, Area: in.Area, NeededBy: in.NeededBy,
			Urgent: in.Urgent, ContactName: in.ContactName, ContactPhone: in.ContactPhone, Note: in.Note,
			CreatedAt: now,
		})
		if err != nil {
			return err
		}
		donors, err := q.PickDonorsToNotify(ctx, store.PickDonorsToNotifyParams{
			UniversityID: &c.UniversityID, BloodGroup: r.BloodGroup, EligibleOn: s.today().AddDate(0, 0, -DonorRestDays),
			RequesterID: c.UserID, RequestID: r.ID, Since: now.Add(-24 * time.Hour),
			MaxDaily: MaxPushesPerDonorPerDay, Lim: int32(s.maxDonors),
		})
		if err != nil {
			return err
		}
		if len(donors) > 0 {
			if err := q.InsertNotices(ctx, store.InsertNoticesParams{RequestID: r.ID, UserIds: donors, SentAt: now}); err != nil {
				return err
			}
			if err := q.SetNotified(ctx, store.SetNotifiedParams{ID: r.ID, Notified: int32(len(donors))}); err != nil {
				return err
			}
			if s.notify != nil {
				n := requestNotice(r.BloodGroup, r.Hospital, r.Area, r.Urgent, r.NeededBy, now, r.ID)
				db.AfterCommit(ctx, func(context.Context) { s.notify(donors, n) })
			}
		}
		out, err = s.one(ctx, q, c.UserID, c.UniversityID, r.ID)
		return err
	})
	if err != nil {
		return nil, err
	}
	return out, nil
}

// ---- responding ------------------------------------------------------------------

// RespondInput is POST /blood/requests/{id}/respond.
type RespondInput struct {
	Phone string `json:"phone" validate:"required,max=40"`
}

// Respond is "I can donate": the donor's phone goes to the requester.
// Saying it again changes nothing.
func (s *Service) Respond(ctx context.Context, id uuid.UUID, in *RespondInput) (*Request, error) {
	c, err := caller(ctx)
	if err != nil {
		return nil, err
	}
	phone, ok := cleanPhone(in.Phone)
	if !ok {
		return nil, apperr.Validation(map[string]string{"phone": phoneProblem})
	}
	var out *Request
	err = s.d.InTx(ctx, func(ctx context.Context) error {
		q := store.New(s.d.Q(ctx))
		r, err := q.GetRequestForUpdate(ctx, id)
		if db.IsNoRows(err) || (err == nil && r.UniversityID != c.UniversityID) {
			return ErrRequestNotFound
		}
		if err != nil {
			return err
		}
		if r.RequesterID != nil && *r.RequesterID == c.UserID {
			return ErrCannotRespondOwn
		}
		if s.status(r) != "open" {
			return ErrRequestClosed
		}
		donor, err := q.GetDonor(ctx, c.UserID)
		if db.IsNoRows(err) {
			return ErrDonorRequired
		}
		if err != nil {
			return err
		}
		added, err := q.InsertResponse(ctx, store.InsertResponseParams{RequestID: r.ID, DonorID: c.UserID, Phone: phone, CreatedAt: s.now()})
		if err != nil {
			return err
		}
		if err := q.SetDonorPhoneIfEmpty(ctx, store.SetDonorPhoneIfEmptyParams{UserID: c.UserID, Phone: phone}); err != nil {
			return err
		}
		if added > 0 && s.notify != nil && r.RequesterID != nil {
			name, err := q.DisplayName(ctx, c.UserID)
			if err != nil {
				return err
			}
			n, to := responseNotice(name, donor.BloodGroup, r.ID), []uuid.UUID{*r.RequesterID}
			db.AfterCommit(ctx, func(context.Context) { s.notify(to, n) })
		}
		out, err = s.one(ctx, q, c.UserID, c.UniversityID, r.ID)
		return err
	})
	if err != nil {
		return nil, err
	}
	return out, nil
}

// Withdraw takes the caller's response back.
func (s *Service) Withdraw(ctx context.Context, id uuid.UUID) (*Request, error) {
	c, err := caller(ctx)
	if err != nil {
		return nil, err
	}
	var out *Request
	err = s.d.InTx(ctx, func(ctx context.Context) error {
		q := store.New(s.d.Q(ctx))
		if _, err := s.one(ctx, q, c.UserID, c.UniversityID, id); err != nil {
			return err
		}
		if err := q.DeleteResponse(ctx, store.DeleteResponseParams{RequestID: id, DonorID: c.UserID}); err != nil {
			return err
		}
		var err error
		out, err = s.one(ctx, q, c.UserID, c.UniversityID, id)
		return err
	})
	if err != nil {
		return nil, err
	}
	return out, nil
}

// CloseInput is POST /blood/requests/{id}/close.
type CloseInput struct {
	Fulfilled bool `json:"fulfilled"`
}

// Close ends an open request: fulfilled (got blood) or closed (cancelled).
func (s *Service) Close(ctx context.Context, id uuid.UUID, in *CloseInput) (*Request, error) {
	c, err := caller(ctx)
	if err != nil {
		return nil, err
	}
	var out *Request
	err = s.d.InTx(ctx, func(ctx context.Context) error {
		q := store.New(s.d.Q(ctx))
		r, err := q.GetRequestForUpdate(ctx, id)
		if db.IsNoRows(err) || (err == nil && (r.UniversityID != c.UniversityID || r.RequesterID == nil || *r.RequesterID != c.UserID)) {
			return ErrRequestNotFound
		}
		if err != nil {
			return err
		}
		if r.Status != "open" {
			return ErrRequestClosed
		}
		status := "closed"
		if in.Fulfilled {
			status = "fulfilled"
		}
		if err := q.CloseRequest(ctx, store.CloseRequestParams{ID: id, Status: status, ClosedAt: ptr(s.now())}); err != nil {
			return err
		}
		out, err = s.one(ctx, q, c.UserID, c.UniversityID, id)
		return err
	})
	if err != nil {
		return nil, err
	}
	return out, nil
}

func ptr[T any](v T) *T { return &v }
