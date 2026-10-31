package blood

import (
	"net/http"

	"github.com/zamansheikh/varsitykotha/backend/internal/platform/apperr"
)

// Error codes are the wire contract with the app; never rename a shipped one.
var (
	ErrUniversityRequired = apperr.New(http.StatusConflict, "UNIVERSITY_REQUIRED",
		"Choose your university first")
	ErrVerifyRequired = apperr.New(http.StatusForbidden, "VERIFY_REQUIRED",
		"Verify your university email to ask for blood")
	ErrTooManyOpen = apperr.New(http.StatusConflict, "TOO_MANY_OPEN_REQUESTS",
		"You already have the most open blood requests allowed")
	ErrRequestNotFound = apperr.New(http.StatusNotFound, "BLOOD_REQUEST_NOT_FOUND",
		"This blood request was not found")
	ErrRequestClosed = apperr.New(http.StatusConflict, "REQUEST_CLOSED",
		"This request is closed")
	ErrCannotRespondOwn = apperr.New(http.StatusConflict, "CANNOT_RESPOND_OWN",
		"You can't respond to your own request")
	ErrDonorRequired = apperr.New(http.StatusConflict, "DONOR_REQUIRED",
		"Become a donor first")
	ErrBadCursor = apperr.New(http.StatusBadRequest, "BAD_CURSOR", "This page link is no longer valid")
)
