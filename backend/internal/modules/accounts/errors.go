package accounts

import (
	"net/http"

	"github.com/zamansheikh/campussaga/backend/internal/platform/apperr"
	"github.com/zamansheikh/campussaga/backend/internal/platform/auth"
)

// Error codes are the wire contract with the app; never rename a shipped one.
var (
	ErrAccountBlocked = apperr.New(http.StatusForbidden, "ACCOUNT_BLOCKED",
		"This account is blocked. Contact hello@silifton.com")
	ErrNotAdmin = auth.ErrNotAdmin

	ErrUniversityEmailRequired = apperr.New(http.StatusForbidden, "UNIVERSITY_EMAIL_REQUIRED",
		"Please use your university email address")
	ErrCodeResendTooSoon = apperr.New(http.StatusTooManyRequests, "CODE_RESEND_TOO_SOON",
		"Please wait a moment before asking for a new code")
	ErrCodeLimitReached = apperr.New(http.StatusTooManyRequests, "CODE_LIMIT_REACHED",
		"Too many codes requested. Please try again later")
	ErrEmailSendFailed = apperr.New(http.StatusBadGateway, "EMAIL_SEND_FAILED",
		"We could not send the email. Please try again shortly")

	ErrCodeInvalid = apperr.New(http.StatusBadRequest, "CODE_INVALID",
		"The code is not correct")
	ErrCodeExpired = apperr.New(http.StatusBadRequest, "CODE_EXPIRED",
		"The code has expired. Please ask for a new one")
	ErrCodeTooManyAttempts = apperr.New(http.StatusTooManyRequests, "CODE_TOO_MANY_ATTEMPTS",
		"Too many wrong codes. Please ask for a new one")

	ErrGoogleUnavailable = apperr.New(http.StatusServiceUnavailable, "GOOGLE_SIGN_IN_UNAVAILABLE",
		"Google sign-in is not available right now. Please use your university email")
	ErrGoogleTokenInvalid = apperr.New(http.StatusUnauthorized, "GOOGLE_TOKEN_INVALID",
		"Google sign-in failed. Please try again")

	ErrAlreadyVerified = apperr.New(http.StatusConflict, "ALREADY_VERIFIED",
		"You are already a verified student")
	ErrEmailInUse = apperr.New(http.StatusConflict, "EMAIL_IN_USE",
		"This email already belongs to another account. Sign in with it instead")
	ErrUniversityNotFound = apperr.New(http.StatusNotFound, "UNIVERSITY_NOT_FOUND",
		"This university was not found")

	// ErrRefreshInvalid tells the app to sign the student out.
	ErrRefreshInvalid = apperr.New(http.StatusUnauthorized, "REFRESH_INVALID",
		"Please sign in again")
	// ErrSessionEnded: signed out, account deleted, or session revoked.
	ErrSessionEnded = apperr.New(http.StatusUnauthorized, "SESSION_ENDED",
		"Please sign in again")
)
