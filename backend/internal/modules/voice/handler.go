package voice

import (
	"net/http"
	"time"

	"github.com/zamansheikh/varsitykotha/backend/internal/platform/httpx"
)

// Routes mounts Campus Voice. Every route drops the user id from its log
// lines (httpx.Unlogged): who wrote what never reaches the logs.
func (s *Service) Routes(r *httpx.Router) {
	st := r.Student().With(httpx.Unlogged)
	st.Get("/issues", httpx.Handle(s.handleFeed))
	st.Get("/issues/similar", httpx.Handle(s.handleSimilar))
	st.With(r.LimitUser("voice-issue", 5, 24*time.Hour)).
		Post("/issues", httpx.Handle(s.handleCreate, httpx.Status(http.StatusCreated)))
	st.Get("/issues/{id}", httpx.Handle(s.handleGet))
	st.Patch("/issues/{id}", httpx.Handle(s.handlePatch))
	st.Delete("/issues/{id}", httpx.Handle(s.handleDelete, httpx.NoContent()))
	votes := st.With(r.LimitUser("voice-vote", 300, time.Hour))
	votes.Put("/issues/{id}/vote", httpx.Handle(s.handleVote))
	votes.Delete("/issues/{id}/vote", httpx.Handle(s.handleUnvote))
	st.Put("/issues/{id}/follow", httpx.Handle(s.handleFollow))
	st.Delete("/issues/{id}/follow", httpx.Handle(s.handleUnfollow))
	st.Post("/issues/{id}/reopen", httpx.Handle(s.handleReopen))
	st.Get("/issues/{id}/comments", httpx.Handle(s.handleComments))
	st.With(r.LimitUser("voice-comment", 60, 24*time.Hour)).
		Post("/issues/{id}/comments", httpx.Handle(s.handleComment, httpx.Status(http.StatusCreated)))
	st.Delete("/issues/{id}/comments/{c}", httpx.Handle(s.handleDeleteComment, httpx.NoContent()))
	reports := st.With(r.LimitUser("voice-report", 20, 24*time.Hour))
	reports.Post("/issues/{id}/report", httpx.Handle(s.handleReport, httpx.NoContent()))
	reports.Post("/issues/{id}/comments/{c}/report", httpx.Handle(s.handleReport, httpx.NoContent()))
	st.Get("/me/issues", httpx.Handle(s.handleMyIssues))
	st.With(r.LimitUser("voice-upload", 20, 24*time.Hour)).Post("/uploads", s.handleUpload)
	st.Get("/uploads/{id}", s.handleUploadImage)
	st.Get("/issues/images/{imageId}", s.handleImage)

	auth := r.Roles(RoleAuthority).With(httpx.Unlogged)
	auth.Post("/issues/{id}/status", httpx.Handle(s.handleStatus))
	auth.Post("/issues/{id}/official-replies", httpx.Handle(s.handleOfficialReply, httpx.Status(http.StatusCreated)))

	mod := r.Roles(RoleModerator, RoleAdmin).With(httpx.Unlogged)
	mod.Get("/moderation/queue", httpx.Handle(s.handleQueue))
	mod.Get("/moderation/issues/{id}", httpx.Handle(s.handleModerationIssue))
	mod.Post("/moderation/issues/{id}", httpx.Handle(s.handleModerateIssue))
	mod.Post("/moderation/comments/{id}", httpx.Handle(s.handleModerateComment))
	mod.Post("/moderation/issues/{id}/ban-author", httpx.Handle(s.handleBanIssueAuthor))
	mod.Post("/moderation/comments/{id}/ban-author", httpx.Handle(s.handleBanCommentAuthor))
	mod.Post("/moderation/reports/dismiss", httpx.Handle(s.handleDismiss, httpx.NoContent()))
}
