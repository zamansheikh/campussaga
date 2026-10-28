package push

import (
	"context"
	"net/http"
	"time"

	"github.com/zamansheikh/varsitykotha/backend/internal/platform/httpx"
)

func (s *Service) Routes(r *httpx.Router) {
	r.Student().With(r.LimitUser("devices", 60, time.Hour)).
		Post("/me/devices", httpx.Handle(s.handleRegister, httpx.Status(http.StatusNoContent)))
}

func (s *Service) handleRegister(ctx context.Context, in *DeviceInput) (*httpx.Empty, error) {
	return nil, s.Register(ctx, in)
}
