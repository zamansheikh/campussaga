package blood

import (
	"context"
	"encoding/json"
	"strconv"
	"strings"
	"time"

	"github.com/google/uuid"

	"github.com/zamansheikh/varsitykotha/backend/internal/modules/blood/store"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/apperr"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/auth"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/db"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/httpx"
)

// Admin panel (docs/ADMIN.md, "Blood requests"): every university's requests,
// and closing one.

// ErrNotOpen: the request is already fulfilled or closed.
var ErrNotOpen = apperr.New(409, "BLOOD_REQUEST_NOT_OPEN", "This blood request is not open")

func (s *Service) adminRoutes(r *httpx.Router) {
	a := r.Admin()
	a.Get("/admin/blood/requests", httpx.Handle(s.handleAdminList))
	a.Post("/admin/blood/requests/{id}/close", httpx.Handle(s.handleAdminClose))
}

// AdminRequest is a blood request as the admin panel sees it.
type AdminRequest struct {
	ID           uuid.UUID  `json:"id"`
	University   adminRef   `json:"university"`
	BloodGroup   string     `json:"bloodGroup"`
	Units        int        `json:"units"`
	Hospital     string     `json:"hospital"`
	Area         string     `json:"area"`
	NeededBy     time.Time  `json:"neededBy"`
	Urgent       bool       `json:"urgent"`
	ContactName  string     `json:"contactName"`
	ContactPhone string     `json:"contactPhone"`
	Note         string     `json:"note"`
	Status       string     `json:"status"`
	Notified     int        `json:"notified"`
	Responses    int        `json:"responses"`
	Requester    *adminWho  `json:"requester"`
	CreatedAt    time.Time  `json:"createdAt"`
	ClosedAt     *time.Time `json:"closedAt"`
}

type adminRef struct {
	ID   uuid.UUID `json:"id"`
	Name string    `json:"name"`
}

type adminWho struct {
	ID    uuid.UUID `json:"id"`
	Name  string    `json:"name"`
	Email string    `json:"email"`
}

func adminView(r store.BloodRequest, uniName string, name *string, email *string, responses int32) AdminRequest {
	v := AdminRequest{
		ID: r.ID, University: adminRef{ID: r.UniversityID, Name: uniName}, BloodGroup: r.BloodGroup,
		Units: int(r.Units), Hospital: r.Hospital, Area: r.Area, NeededBy: r.NeededBy, Urgent: r.Urgent,
		ContactName: r.ContactName, ContactPhone: r.ContactPhone, Note: r.Note, Status: r.Status,
		Notified: int(r.Notified), Responses: int(responses), CreatedAt: r.CreatedAt, ClosedAt: r.ClosedAt,
	}
	if r.RequesterID != nil {
		w := &adminWho{ID: *r.RequesterID}
		if email != nil {
			w.Email = *email
		}
		if name != nil {
			w.Name = *name
		}
		v.Requester = w
	}
	return v
}

// AdminPage is a page of the admin list.
type AdminPage struct {
	Items    []AdminRequest `json:"items"`
	Total    int            `json:"total"`
	Page     int            `json:"page"`
	PageSize int            `json:"pageSize"`
}

type adminListReq struct {
	Page         string `json:"-" query:"page" validate:"omitempty,number,min=1,max=6"`
	PageSize     string `json:"-" query:"pageSize" validate:"omitempty,number"`
	Status       string `json:"-" query:"status" validate:"omitempty,oneof=open fulfilled closed all"`
	UniversityID string `json:"-" query:"universityId" validate:"omitempty,uuid"`
	Q            string `json:"-" query:"q" validate:"max=100"`
}

// like turns a search into an ILIKE pattern, matching % and _ literally.
func like(q string) string {
	return "%" + strings.NewReplacer(`\`, `\\`, `%`, `\%`, `_`, `\_`).Replace(q) + "%"
}

func (s *Service) handleAdminList(ctx context.Context, in *adminListReq) (*AdminPage, error) {
	page, _ := strconv.Atoi(in.Page)
	size, _ := strconv.Atoi(in.PageSize)
	page = max(page, 1)
	if size < 1 {
		size = 25
	}
	size = min(size, 100)
	status := in.Status
	if status == "" {
		status = "open"
	}
	var uni *uuid.UUID
	if in.UniversityID != "" {
		id := uuid.MustParse(in.UniversityID)
		uni = &id
	}
	search := strings.TrimSpace(in.Q)
	q := store.New(s.d.Q(ctx))
	rows, err := q.AdminListRequests(ctx, store.AdminListRequestsParams{
		Status: status, UniversityID: uni, Q: search, QLike: like(search),
		Lim: int32(size), Off: int32((page - 1) * size),
	})
	if err != nil {
		return nil, err
	}
	total, err := q.AdminCountRequests(ctx, store.AdminCountRequestsParams{
		Status: status, UniversityID: uni, Q: search, QLike: like(search),
	})
	if err != nil {
		return nil, err
	}
	out := &AdminPage{Items: make([]AdminRequest, 0, len(rows)), Total: int(total), Page: page, PageSize: size}
	for _, x := range rows {
		out.Items = append(out.Items, adminView(x.BloodRequest, x.UniversityName, x.RequesterName, x.RequesterEmail, x.ResponseCount))
	}
	return out, nil
}

type adminCloseReq struct {
	idPath
	Reason string `json:"reason" validate:"max=300"`
}

// handleAdminClose closes an open request and writes the audit row in the
// same transaction.
func (s *Service) handleAdminClose(ctx context.Context, in *adminCloseReq) (*AdminRequest, error) {
	return s.closeRequest(ctx, uuid.MustParse(in.ID), in.Reason, nil, "blood.close")
}

// CampusOpen lists a university's open requests (a campus admin's view).
func (s *Service) CampusOpen(ctx context.Context, uni uuid.UUID) ([]AdminRequest, error) {
	rows, err := store.New(s.d.Q(ctx)).AdminListRequests(ctx, store.AdminListRequestsParams{
		Status: "open", UniversityID: &uni, QLike: like(""), Lim: 100,
	})
	if err != nil {
		return nil, err
	}
	out := make([]AdminRequest, 0, len(rows))
	for _, x := range rows {
		out = append(out, adminView(x.BloodRequest, x.UniversityName, x.RequesterName, nil, x.ResponseCount))
	}
	return out, nil
}

// noEmail: a campus admin never sees a student's email.
func noEmail(r AdminRequest) AdminRequest {
	if r.Requester != nil {
		r.Requester.Email = ""
	}
	return r
}

// CampusClose closes one of the university's open requests (audit
// campus.blood_close); another university's request is not found.
func (s *Service) CampusClose(ctx context.Context, uni, id uuid.UUID, reason string) (*AdminRequest, error) {
	r, err := s.closeRequest(ctx, id, reason, &uni, "campus.blood_close")
	if err != nil {
		return nil, err
	}
	v := noEmail(*r)
	return &v, nil
}

func (s *Service) closeRequest(ctx context.Context, id uuid.UUID, reason string, scope *uuid.UUID, action string) (*AdminRequest, error) {
	actor := auth.MustUser(ctx).UserID
	var out *AdminRequest
	err := s.d.InTx(ctx, func(ctx context.Context) error {
		q := store.New(s.d.Q(ctx))
		r, err := q.GetRequestForUpdate(ctx, id)
		if db.IsNoRows(err) {
			return ErrRequestNotFound
		}
		if err != nil {
			return err
		}
		if scope != nil && r.UniversityID != *scope {
			return ErrRequestNotFound
		}
		if r.Status != "open" {
			return ErrNotOpen
		}
		if err := q.CloseRequest(ctx, store.CloseRequestParams{ID: id, Status: "closed", ClosedAt: ptr(s.now())}); err != nil {
			return err
		}
		meta, _ := json.Marshal(map[string]string{"reason": reason})
		target := id.String()
		if err := q.InsertAudit(ctx, store.InsertAuditParams{
			ActorID: &actor, Action: action, TargetType: ptr("blood_request"), TargetID: &target, Meta: meta,
		}); err != nil {
			return err
		}
		g, err := q.AdminGetRequest(ctx, id)
		if err != nil {
			return err
		}
		v := adminView(g.BloodRequest, g.UniversityName, g.RequesterName, g.RequesterEmail, g.ResponseCount)
		out = &v
		return nil
	})
	return out, err
}
