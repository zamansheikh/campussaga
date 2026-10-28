package admin

import (
	"net/http"

	"github.com/zamansheikh/varsitykotha/backend/internal/platform/apperr"
)

// Error codes are the wire contract with the admin panel.
var (
	ErrUserNotFound     = apperr.New(http.StatusNotFound, "USER_NOT_FOUND", "No such user")
	ErrCannotChangeSelf = apperr.New(http.StatusConflict, "CANNOT_CHANGE_SELF",
		"You can't block, demote or delete your own account")
	ErrUniversityRequired = apperr.New(http.StatusConflict, "UNIVERSITY_REQUIRED",
		"Give the student a university first")
	ErrUniversityNotFound = apperr.New(http.StatusNotFound, "UNIVERSITY_NOT_FOUND", "No such university")
	ErrSlugTaken          = apperr.New(http.StatusConflict, "SLUG_TAKEN", "Another university already uses this slug")
	ErrDomainTaken        = apperr.New(http.StatusConflict, "DOMAIN_TAKEN", "This email domain already belongs to a university")
	ErrDomainNotAllowed   = apperr.New(http.StatusUnprocessableEntity, "DOMAIN_NOT_ALLOWED",
		"Free email providers and shared suffixes (like ac.bd) can't be university domains")
	ErrGroupNotFound  = apperr.New(http.StatusNotFound, "GROUP_NOT_FOUND", "No such class group")
	ErrMemberNotFound = apperr.New(http.StatusNotFound, "MEMBER_NOT_FOUND", "This student is not in the group")
	ErrLastCR         = apperr.New(http.StatusConflict, "LAST_CR", "A group always keeps one CR. Make someone else CR first")
	ErrCRLimit        = apperr.New(http.StatusConflict, "CR_LIMIT_REACHED", "A group can have at most 3 CRs")
	ErrConfigKey      = apperr.New(http.StatusNotFound, "CONFIG_KEY_UNKNOWN", "No such setting")
	ErrConfigValue    = apperr.New(http.StatusUnprocessableEntity, "CONFIG_VALUE_INVALID", "This value doesn't fit the setting")
)
