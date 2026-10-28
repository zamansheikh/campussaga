package classgroups

import (
	"context"
	"net/http"
	"time"

	"github.com/google/uuid"

	"github.com/zamansheikh/varsitykotha/backend/internal/platform/httpx"
)

// Routes mounts the module's endpoints. Looking up codes (preview + join)
// is limited per student and per IP, so codes can't be guessed.
func (s *Service) Routes(r *httpx.Router) {
	codes := []func(http.Handler) http.Handler{
		r.LimitUser("group-code-user", 30, time.Hour),
		r.Limit("group-code-ip", 120, time.Hour),
	}
	r.Student().Get("/groups", httpx.Handle(s.handleList))
	// Find your class: search, look before joining, join some courses.
	find := r.LimitUser("group-find", 600, time.Hour)
	r.Student().With(find).Get("/groups/search", httpx.Handle(s.handleSearch))
	r.Student().With(find).Get("/groups/similar", httpx.Handle(s.handleSimilar))
	r.Student().With(find).Get("/groups/{id}/routine-preview", httpx.Handle(s.handleRoutinePreview))
	r.Student().With(r.LimitUser("group-join-courses", 60, time.Hour)).
		Post("/groups/{id}/join-courses", httpx.Handle(s.handleJoinCourses))
	r.Student().With(r.LimitUser("group-create", 10, 24*time.Hour)).
		Post("/groups", httpx.Handle(s.handleCreate, httpx.Status(http.StatusCreated)))
	r.Student().With(codes...).Get("/groups/preview", httpx.Handle(s.handlePreview))
	r.Student().With(codes...).Post("/groups/join", httpx.Handle(s.handleJoin))
	r.Student().Put("/groups/{id}", httpx.Handle(s.handleUpdate))
	r.Student().Delete("/groups/{id}", httpx.Handle(s.handleDelete, httpx.NoContent()))
	r.Student().Post("/groups/{id}/leave", httpx.Handle(s.handleLeave, httpx.NoContent()))
	r.Student().Post("/groups/{id}/slots", httpx.Handle(s.handleAddSlot, httpx.Status(http.StatusCreated)))
	r.Student().Put("/groups/{id}/slots/{slot}", httpx.Handle(s.handleUpdateSlot))
	r.Student().Delete("/groups/{id}/slots/{slot}", httpx.Handle(s.handleDeleteSlot, httpx.NoContent()))
	r.Student().Post("/groups/{id}/changes", httpx.Handle(s.handleAddChange, httpx.Status(http.StatusCreated)))
	r.Student().Delete("/groups/{id}/changes/{change}", httpx.Handle(s.handleDeleteChange, httpx.NoContent()))
	r.Student().With(r.LimitUser("announce", 30, 24*time.Hour)).
		Post("/groups/{id}/announcements", httpx.Handle(s.handlePost, httpx.Status(http.StatusCreated)))
	r.Student().Patch("/groups/{id}/announcements/{a}", httpx.Handle(s.handlePin))
	r.Student().Delete("/groups/{id}/announcements/{a}", httpx.Handle(s.handleDeleteAnnouncement, httpx.NoContent()))
	r.Student().With(r.LimitUser("assessment-add", 30, 24*time.Hour)).
		Post("/groups/{id}/assessments", httpx.Handle(s.handleAddAssessment, httpx.Status(http.StatusCreated)))
	r.Student().Put("/groups/{id}/assessments/{a}", httpx.Handle(s.handleUpdateAssessment))
	r.Student().Delete("/groups/{id}/assessments/{a}", httpx.Handle(s.handleDeleteAssessment, httpx.NoContent()))
	r.Student().Get("/groups/{id}/members", httpx.Handle(s.handleMembers))
	r.Student().Put("/groups/{id}/members/{user}", httpx.Handle(s.handleSetRole, httpx.NoContent()))
	r.Student().Delete("/groups/{id}/members/{user}", httpx.Handle(s.handleRemoveMember, httpx.NoContent()))
	r.Student().Put("/groups/{id}/hidden", httpx.Handle(s.handleHidden))
	r.Student().Post("/groups/{id}/new-semester", httpx.Handle(s.handleNewSemester))
	r.Student().Get("/me/classes", httpx.Handle(s.handleMyPersonal))
	r.Student().Post("/me/classes", httpx.Handle(s.handleAddPersonal, httpx.Status(http.StatusCreated)))
	r.Student().Put("/me/classes/{id}", httpx.Handle(s.handleUpdatePersonal))
	r.Student().Delete("/me/classes/{id}", httpx.Handle(s.handleDeletePersonal, httpx.NoContent()))
}

type groupsRes struct {
	Groups []Group `json:"groups"`
}

func (s *Service) handleList(ctx context.Context, _ *httpx.Empty) (*groupsRes, error) {
	g, err := s.MyGroups(ctx)
	if err != nil {
		return nil, err
	}
	return &groupsRes{Groups: g}, nil
}

func (s *Service) handleCreate(ctx context.Context, in *GroupInput) (*Group, error) {
	return s.Create(ctx, in)
}

type previewReq struct {
	Code string `json:"-" query:"code" validate:"required,len=6,alpha"`
}

func (s *Service) handlePreview(ctx context.Context, in *previewReq) (*Preview, error) {
	return s.Preview(ctx, in.Code)
}

type joinReq struct {
	Code string `json:"code" validate:"required,len=6,alpha"`
}

func (s *Service) handleJoin(ctx context.Context, in *joinReq) (*Group, error) {
	return s.Join(ctx, in.Code)
}

type groupPath struct {
	ID string `json:"-" path:"id" validate:"required,uuid"`
}

type updateGroupReq struct {
	groupPath
	GroupInput
}

func (s *Service) handleUpdate(ctx context.Context, in *updateGroupReq) (*Group, error) {
	return s.Update(ctx, uuid.MustParse(in.ID), &in.GroupInput)
}

func (s *Service) handleDelete(ctx context.Context, in *groupPath) (*httpx.Empty, error) {
	return nil, s.Delete(ctx, uuid.MustParse(in.ID))
}

func (s *Service) handleLeave(ctx context.Context, in *groupPath) (*httpx.Empty, error) {
	return nil, s.Leave(ctx, uuid.MustParse(in.ID))
}

type addSlotReq struct {
	groupPath
	SlotInput
}

func (s *Service) handleAddSlot(ctx context.Context, in *addSlotReq) (*Slot, error) {
	return s.AddSlot(ctx, uuid.MustParse(in.ID), &in.SlotInput)
}

type slotPath struct {
	ID   string `json:"-" path:"id" validate:"required,uuid"`
	Slot string `json:"-" path:"slot" validate:"required,uuid"`
}

type updateSlotReq struct {
	slotPath
	SlotInput
}

func (s *Service) handleUpdateSlot(ctx context.Context, in *updateSlotReq) (*Slot, error) {
	return s.UpdateSlot(ctx, uuid.MustParse(in.ID), uuid.MustParse(in.Slot), &in.SlotInput)
}

func (s *Service) handleDeleteSlot(ctx context.Context, in *slotPath) (*httpx.Empty, error) {
	return nil, s.DeleteSlot(ctx, uuid.MustParse(in.ID), uuid.MustParse(in.Slot))
}

type addChangeReq struct {
	groupPath
	ChangeInput
}

func (s *Service) handleAddChange(ctx context.Context, in *addChangeReq) (*Change, error) {
	return s.AddChange(ctx, uuid.MustParse(in.ID), &in.ChangeInput)
}

type changePath struct {
	ID     string `json:"-" path:"id" validate:"required,uuid"`
	Change string `json:"-" path:"change" validate:"required,uuid"`
}

func (s *Service) handleDeleteChange(ctx context.Context, in *changePath) (*httpx.Empty, error) {
	return nil, s.DeleteChange(ctx, uuid.MustParse(in.ID), uuid.MustParse(in.Change))
}

type postReq struct {
	groupPath
	AnnouncementInput
}

func (s *Service) handlePost(ctx context.Context, in *postReq) (*Announcement, error) {
	return s.Post(ctx, uuid.MustParse(in.ID), &in.AnnouncementInput)
}

type announcementPath struct {
	ID string `json:"-" path:"id" validate:"required,uuid"`
	A  string `json:"-" path:"a" validate:"required,uuid"`
}

type pinReq struct {
	announcementPath
	Pinned *bool `json:"pinned" validate:"required"`
}

func (s *Service) handlePin(ctx context.Context, in *pinReq) (*Announcement, error) {
	return s.SetPinned(ctx, uuid.MustParse(in.ID), uuid.MustParse(in.A), *in.Pinned)
}

func (s *Service) handleDeleteAnnouncement(ctx context.Context, in *announcementPath) (*httpx.Empty, error) {
	return nil, s.DeleteAnnouncement(ctx, uuid.MustParse(in.ID), uuid.MustParse(in.A))
}

type membersRes struct {
	Members []Member `json:"members"`
}

func (s *Service) handleMembers(ctx context.Context, in *groupPath) (*membersRes, error) {
	m, err := s.Members(ctx, uuid.MustParse(in.ID))
	if err != nil {
		return nil, err
	}
	return &membersRes{Members: m}, nil
}

type memberPath struct {
	ID   string `json:"-" path:"id" validate:"required,uuid"`
	User string `json:"-" path:"user" validate:"required,uuid"`
}

type setRoleReq struct {
	memberPath
	Role string `json:"role" validate:"required,oneof=cr member"`
}

func (s *Service) handleSetRole(ctx context.Context, in *setRoleReq) (*httpx.Empty, error) {
	return nil, s.SetMemberRole(ctx, uuid.MustParse(in.ID), uuid.MustParse(in.User), in.Role)
}

func (s *Service) handleRemoveMember(ctx context.Context, in *memberPath) (*httpx.Empty, error) {
	return nil, s.RemoveMember(ctx, uuid.MustParse(in.ID), uuid.MustParse(in.User))
}

type hiddenReq struct {
	groupPath
	Courses []string `json:"courses" validate:"max=100,dive,max=40"`
}

func (s *Service) handleHidden(ctx context.Context, in *hiddenReq) (*Group, error) {
	return s.SetHidden(ctx, uuid.MustParse(in.ID), in.Courses)
}

type semesterReq struct {
	groupPath
	Semester string `json:"semester" validate:"required,max=30"`
}

func (s *Service) handleNewSemester(ctx context.Context, in *semesterReq) (*Group, error) {
	return s.NewSemester(ctx, uuid.MustParse(in.ID), in.Semester)
}

type personalRes struct {
	Classes []PersonalClass `json:"classes"`
}

func (s *Service) handleMyPersonal(ctx context.Context, _ *httpx.Empty) (*personalRes, error) {
	p, err := s.MyPersonal(ctx)
	if err != nil {
		return nil, err
	}
	return &personalRes{Classes: p}, nil
}

func (s *Service) handleAddPersonal(ctx context.Context, in *PersonalInput) (*PersonalClass, error) {
	return s.AddPersonal(ctx, in)
}

type personalPath struct {
	ID string `json:"-" path:"id" validate:"required,uuid"`
}

type updatePersonalReq struct {
	personalPath
	PersonalInput
}

func (s *Service) handleUpdatePersonal(ctx context.Context, in *updatePersonalReq) (*PersonalClass, error) {
	return s.UpdatePersonal(ctx, uuid.MustParse(in.ID), &in.PersonalInput)
}

func (s *Service) handleDeletePersonal(ctx context.Context, in *personalPath) (*httpx.Empty, error) {
	return nil, s.DeletePersonal(ctx, uuid.MustParse(in.ID))
}

type addAssessmentReq struct {
	groupPath
	AssessmentInput
}

func (s *Service) handleAddAssessment(ctx context.Context, in *addAssessmentReq) (*Assessment, error) {
	return s.AddAssessment(ctx, uuid.MustParse(in.ID), &in.AssessmentInput)
}

type assessmentPath struct {
	ID string `json:"-" path:"id" validate:"required,uuid"`
	A  string `json:"-" path:"a" validate:"required,uuid"`
}

type updateAssessmentReq struct {
	assessmentPath
	AssessmentInput
}

func (s *Service) handleUpdateAssessment(ctx context.Context, in *updateAssessmentReq) (*Assessment, error) {
	return s.UpdateAssessment(ctx, uuid.MustParse(in.ID), uuid.MustParse(in.A), &in.AssessmentInput)
}

func (s *Service) handleDeleteAssessment(ctx context.Context, in *assessmentPath) (*httpx.Empty, error) {
	return nil, s.DeleteAssessment(ctx, uuid.MustParse(in.ID), uuid.MustParse(in.A))
}
