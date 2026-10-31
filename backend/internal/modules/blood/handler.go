package blood

import (
	"context"
	"net/http"
	"time"

	"github.com/google/uuid"

	"github.com/zamansheikh/varsitykotha/backend/internal/platform/httpx"
)

// Routes mounts the module's endpoints. Posting is limited to 3 requests a
// day in the service (failed attempts don't count); responding to 30 a day.
func (s *Service) Routes(r *httpx.Router) {
	r.Student().Get("/blood/me", httpx.Handle(s.handleMe))
	r.Student().Put("/blood/me", httpx.Handle(s.handleSave))
	r.Student().Delete("/blood/me", httpx.Handle(s.handleStop, httpx.NoContent()))
	r.Student().Post("/blood/me/donated", httpx.Handle(s.handleDonated))
	r.Student().Get("/blood/requests", httpx.Handle(s.List))
	r.Student().With(r.LimitUser("blood-request-post", 30, 24*time.Hour)).
		Post("/blood/requests", httpx.Handle(s.Create, httpx.Status(http.StatusCreated)))
	r.Student().Get("/blood/requests/{id}", httpx.Handle(s.handleGet))
	r.Student().With(r.LimitUser("blood-respond", 30, 24*time.Hour)).
		Post("/blood/requests/{id}/respond", httpx.Handle(s.handleRespond))
	r.Student().Delete("/blood/requests/{id}/respond", httpx.Handle(s.handleWithdraw))
	r.Student().Post("/blood/requests/{id}/close", httpx.Handle(s.handleClose))
}

func (s *Service) handleMe(ctx context.Context, _ *httpx.Empty) (*donorRes, error) {
	return s.MyDonor(ctx)
}

func (s *Service) handleSave(ctx context.Context, in *DonorInput) (*Donor, error) {
	return s.SaveDonor(ctx, in)
}

func (s *Service) handleStop(ctx context.Context, _ *httpx.Empty) (*httpx.Empty, error) {
	return nil, s.StopDonating(ctx)
}

func (s *Service) handleDonated(ctx context.Context, in *DonatedInput) (*Donor, error) {
	return s.Donated(ctx, in)
}

type idPath struct {
	ID string `json:"-" path:"id" validate:"required,uuid"`
}

func (s *Service) handleGet(ctx context.Context, in *idPath) (*Request, error) {
	return s.Get(ctx, uuid.MustParse(in.ID))
}

type respondReq struct {
	idPath
	RespondInput
}

func (s *Service) handleRespond(ctx context.Context, in *respondReq) (*Request, error) {
	return s.Respond(ctx, uuid.MustParse(in.ID), &in.RespondInput)
}

func (s *Service) handleWithdraw(ctx context.Context, in *idPath) (*Request, error) {
	return s.Withdraw(ctx, uuid.MustParse(in.ID))
}

type closeReq struct {
	idPath
	CloseInput
}

func (s *Service) handleClose(ctx context.Context, in *closeReq) (*Request, error) {
	return s.Close(ctx, uuid.MustParse(in.ID), &in.CloseInput)
}
