package classgroups

import (
	"context"

	"github.com/google/uuid"
)

type searchReq struct {
	Q          string `json:"-" query:"q" validate:"max=100"`
	Department string `json:"-" query:"department" validate:"max=80"`
	Batch      string `json:"-" query:"batch" validate:"max=20"`
	Page       string `json:"-" query:"page" validate:"omitempty,number,max=4"`
}

func (s *Service) handleSearch(ctx context.Context, in *searchReq) (*SearchResult, error) {
	return s.Search(ctx, in.Q, in.Department, in.Batch, atoiOr(in.Page, 1))
}

type similarReq struct {
	Department string `json:"-" query:"department" validate:"max=80"`
	Batch      string `json:"-" query:"batch" validate:"max=20"`
	Section    string `json:"-" query:"section" validate:"max=20"`
}

type similarRes struct {
	Items []FoundGroup `json:"items"`
}

func (s *Service) handleSimilar(ctx context.Context, in *similarReq) (*similarRes, error) {
	items, err := s.Similar(ctx, in.Department, in.Batch, in.Section)
	if err != nil {
		return nil, err
	}
	return &similarRes{Items: items}, nil
}

type routinePreviewReq struct {
	ID   string `json:"-" path:"id" validate:"required,uuid"`
	Code string `json:"-" query:"code" validate:"max=6"`
}

func (s *Service) handleRoutinePreview(ctx context.Context, in *routinePreviewReq) (*RoutinePreview, error) {
	return s.RoutinePreview(ctx, uuid.MustParse(in.ID), in.Code)
}

type joinCoursesReq struct {
	ID string `json:"-" path:"id" validate:"required,uuid"`
	// Courses to take (codes or keys); every other course is hidden.
	Courses []string `json:"courses" validate:"max=50,dive,max=20"`
	// Code: the join code, for a group that isn't findable.
	Code string `json:"code" validate:"max=6"`
}

func (s *Service) handleJoinCourses(ctx context.Context, in *joinCoursesReq) (*Group, error) {
	return s.JoinCourses(ctx, uuid.MustParse(in.ID), in.Courses, in.Code)
}
