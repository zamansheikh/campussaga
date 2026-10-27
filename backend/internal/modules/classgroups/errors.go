package classgroups

import (
	"net/http"

	"github.com/zamansheikh/campussaga/backend/internal/platform/apperr"
)

// Error codes are the wire contract with the app; never rename a shipped one.
var (
	ErrGroupNotFound = apperr.New(http.StatusNotFound, "GROUP_NOT_FOUND",
		"No class group with this code at your university")
	ErrUniversityRequired = apperr.New(http.StatusConflict, "UNIVERSITY_REQUIRED",
		"Choose your university first")
	ErrNotCR = apperr.New(http.StatusForbidden, "NOT_GROUP_CR",
		"Only the CR can change this class group")
	ErrGroupLimit = apperr.New(http.StatusConflict, "GROUP_LIMIT_REACHED",
		"You are already in the most class groups allowed")
	ErrGroupFull = apperr.New(http.StatusConflict, "GROUP_FULL",
		"This class group is full")
	ErrCRCannotLeave = apperr.New(http.StatusConflict, "CR_CANNOT_LEAVE",
		"You are the only CR. Make someone else CR first, or delete the group")
	ErrSlotLimit = apperr.New(http.StatusConflict, "SLOT_LIMIT_REACHED",
		"This routine already has the most classes allowed")
	ErrSlotNotFound = apperr.New(http.StatusNotFound, "SLOT_NOT_FOUND",
		"This class was not found")
	ErrChangeNotFound = apperr.New(http.StatusNotFound, "CHANGE_NOT_FOUND",
		"This change was not found")
	ErrAnnouncementNotFound = apperr.New(http.StatusNotFound, "ANNOUNCEMENT_NOT_FOUND",
		"This announcement was not found")
	ErrMemberNotFound = apperr.New(http.StatusNotFound, "MEMBER_NOT_FOUND",
		"This student is not in the group")
	ErrCRLimit = apperr.New(http.StatusConflict, "CR_LIMIT_REACHED",
		"A group can have at most 3 CRs")
	ErrLastCR = apperr.New(http.StatusConflict, "LAST_CR",
		"Make someone else CR first")
	ErrRemoveCR = apperr.New(http.StatusConflict, "REMOVE_CR",
		"A CR can't be removed. Make them a member first")
	ErrPersonalLimit = apperr.New(http.StatusConflict, "PERSONAL_LIMIT_REACHED",
		"You already have the most personal classes allowed")
	ErrChangeLimit = apperr.New(http.StatusConflict, "CHANGE_LIMIT_REACHED",
		"This routine already has the most upcoming changes allowed")
)
