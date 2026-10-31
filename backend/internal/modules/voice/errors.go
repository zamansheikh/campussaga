package voice

import (
	"net/http"

	"github.com/zamansheikh/varsitykotha/backend/internal/platform/apperr"
)

// Error codes are the wire contract with the app and the admin panel.
var (
	ErrFeatureDisabled    = apperr.New(http.StatusForbidden, "FEATURE_DISABLED", "Campus Voice isn't open yet")
	ErrBanned             = apperr.New(http.StatusForbidden, "VOICE_BANNED", "You can't post, comment, vote or report right now")
	ErrIssueNotFound      = apperr.New(http.StatusNotFound, "ISSUE_NOT_FOUND", "This issue was not found")
	ErrCommentNotFound    = apperr.New(http.StatusNotFound, "COMMENT_NOT_FOUND", "This comment was not found")
	ErrUploadNotFound     = apperr.New(http.StatusNotFound, "UPLOAD_NOT_FOUND", "This photo was not found. Add it again")
	ErrImageInvalid       = apperr.New(http.StatusUnprocessableEntity, "IMAGE_INVALID", "Use a JPEG, PNG or WebP photo")
	ErrImageTooLarge      = apperr.New(http.StatusRequestEntityTooLarge, "IMAGE_TOO_LARGE", "This photo is too large (8 MB at most)")
	ErrEditWindowClosed   = apperr.New(http.StatusConflict, "EDIT_WINDOW_CLOSED", "An issue can only be edited in the first hour")
	ErrReopenNotAllowed   = apperr.New(http.StatusConflict, "REOPEN_NOT_ALLOWED", "Only a solved issue can be reopened, within 30 days")
	ErrIssueClosed        = apperr.New(http.StatusConflict, "ISSUE_CLOSED", "This issue was removed")
	ErrCannotVoteOwn      = apperr.New(http.StatusConflict, "CANNOT_VOTE_OWN", "You raised this issue")
	ErrAlreadyReported    = apperr.New(http.StatusConflict, "ALREADY_REPORTED", "You already reported this")
	ErrStatusChange       = apperr.New(http.StatusConflict, "STATUS_CHANGE_INVALID", "This status change isn't possible")
	ErrNoteRequired       = apperr.New(http.StatusUnprocessableEntity, "NOTE_REQUIRED", "Say why the issue is rejected")
	ErrCannotBanOfficial  = apperr.New(http.StatusConflict, "CANNOT_BAN_OFFICIAL", "Official replies come from staff accounts")
	ErrUniversityRequired = apperr.New(http.StatusConflict, "UNIVERSITY_REQUIRED", "Choose your university first")
	ErrPollClosed         = apperr.New(http.StatusConflict, "POLL_CLOSED", "This poll is closed")
	ErrAlreadyVoted       = apperr.New(http.StatusConflict, "ALREADY_VOTED", "You already voted in this poll")
	ErrNotAnIssue         = apperr.New(http.StatusConflict, "NOT_AN_ISSUE", "This is not an issue")
	ErrBadCursor          = apperr.New(http.StatusBadRequest, "BAD_CURSOR", "This page link is no longer valid")
	ErrForbidden          = apperr.New(http.StatusForbidden, "FORBIDDEN", "You can't do this")
)
