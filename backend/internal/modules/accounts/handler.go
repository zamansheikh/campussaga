package accounts

import (
	"context"
	"net/http"
	"time"

	"github.com/google/uuid"

	"github.com/zamansheikh/campussaga/backend/internal/platform/httpx"
)

// Routes mounts the module's endpoints. Sign-in endpoints are limited per
// client IP on top of the per-email limits in the service.
func (s *Service) Routes(r *httpx.Router) {
	r.Public().With(r.Limit("auth-code", 10, 10*time.Minute)).
		Post("/auth/code", httpx.Handle(s.handleRequestCode, httpx.Status(http.StatusAccepted)))
	r.Public().With(r.Limit("auth-verify", 30, 10*time.Minute)).
		Post("/auth/verify", httpx.Handle(s.handleVerify))
	r.Public().With(r.Limit("auth-google", 30, 10*time.Minute)).
		Post("/auth/google", httpx.Handle(s.handleGoogle))
	r.Public().With(r.Limit("auth-refresh", 60, 10*time.Minute)).
		Post("/auth/refresh", httpx.Handle(s.handleRefresh))

	r.Student().Post("/auth/logout", httpx.Handle(s.handleLogout, httpx.NoContent()))
	r.Student().Post("/auth/logout-all", httpx.Handle(s.handleLogoutAll, httpx.NoContent()))

	r.Student().Get("/me", httpx.Handle(s.handleGetMe))
	r.Student().Patch("/me", httpx.Handle(s.handleUpdateMe))
	r.Student().Get("/me/department-suggestions", httpx.Handle(s.handleDepartmentSuggestions))
	r.Student().Delete("/me", httpx.Handle(s.handleDeleteMe, httpx.NoContent()))
	r.Student().Put("/me/university", httpx.Handle(s.handleSetUniversity))
	r.Student().With(r.Limit("verify-code", 10, 10*time.Minute)).
		Post("/me/verify/code", httpx.Handle(s.handleVerifyCode, httpx.Status(http.StatusAccepted)))
	r.Student().With(r.Limit("verify", 30, 10*time.Minute)).
		Post("/me/verify", httpx.Handle(s.handleVerify2))
}

type requestCodeReq struct {
	Email string `json:"email" validate:"required,max=254"`
}

func (s *Service) handleRequestCode(ctx context.Context, in *requestCodeReq) (*CodeSent, error) {
	return s.RequestCode(ctx, in.Email)
}

type verifyReq struct {
	Email string `json:"email" validate:"required,max=254"`
	Code  string `json:"code" validate:"required,len=6,numeric"`
}

func (s *Service) handleVerify(ctx context.Context, in *verifyReq) (*SignedIn, error) {
	return s.VerifyCode(ctx, in.Email, in.Code)
}

type googleReq struct {
	IDToken string `json:"idToken" validate:"required,max=8192"`
}

func (s *Service) handleGoogle(ctx context.Context, in *googleReq) (*SignedIn, error) {
	return s.SignInWithGoogle(ctx, in.IDToken)
}

type refreshReq struct {
	RefreshToken string `json:"refreshToken" validate:"required,max=100"`
}

func (s *Service) handleRefresh(ctx context.Context, in *refreshReq) (*Tokens, error) {
	return s.Refresh(ctx, in.RefreshToken)
}

func (s *Service) handleLogout(ctx context.Context, _ *httpx.Empty) (*httpx.Empty, error) {
	return nil, s.Logout(ctx)
}

func (s *Service) handleLogoutAll(ctx context.Context, _ *httpx.Empty) (*httpx.Empty, error) {
	return nil, s.LogoutAll(ctx)
}

func (s *Service) handleGetMe(ctx context.Context, _ *httpx.Empty) (*Me, error) {
	return s.GetMe(ctx)
}

func (s *Service) handleUpdateMe(ctx context.Context, in *ProfilePatch) (*Me, error) {
	return s.UpdateMe(ctx, in)
}

type suggestionsReq struct {
	Q string `json:"-" query:"q" validate:"max=60"`
}

type suggestionsRes struct {
	Departments []string `json:"departments"`
}

func (s *Service) handleDepartmentSuggestions(ctx context.Context, in *suggestionsReq) (*suggestionsRes, error) {
	d, err := s.DepartmentSuggestions(ctx, in.Q)
	if err != nil {
		return nil, err
	}
	return &suggestionsRes{Departments: d}, nil
}

func (s *Service) handleDeleteMe(ctx context.Context, _ *httpx.Empty) (*httpx.Empty, error) {
	return nil, s.DeleteMe(ctx)
}

type universityReq struct {
	UniversityID string `json:"universityId" validate:"required,uuid"`
}

func (s *Service) handleSetUniversity(ctx context.Context, in *universityReq) (*Me, error) {
	return s.SetUniversity(ctx, uuid.MustParse(in.UniversityID))
}

func (s *Service) handleVerifyCode(ctx context.Context, in *requestCodeReq) (*CodeSent, error) {
	return s.RequestVerifyCode(ctx, in.Email)
}

func (s *Service) handleVerify2(ctx context.Context, in *verifyReq) (*Me, error) {
	return s.VerifyUniversityEmail(ctx, in.Email, in.Code)
}
