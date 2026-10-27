// Package apperr is the single error type every layer returns when the
// failure is meant for the client. The HTTP layer renders it into the
// {success:false,error:{code,message,details}} envelope the app parses.
//
// Rules:
//   - Modules declare their errors as package-level vars built with New and
//     return them directly (or .WithDetails / .WithMessage copies).
//   - Anything that is NOT an *Error reaching the HTTP layer is a bug: it is
//     logged and rendered as 500 INTERNAL_ERROR with a generic message, so
//     internal details never leak to clients.
//   - Codes are part of the wire contract: the app branches on them
//     (e.g. REFRESH_INVALID signs the student out). Never rename a shipped code.
package apperr

import (
	"errors"
	"fmt"
	"net/http"
)

// Error is a client-facing failure.
type Error struct {
	Status  int    // HTTP status
	Code    string // stable machine-readable code, e.g. "CODE_INVALID"
	Message string // human-readable fallback; the app shows its own translated text per code
	Details any    // optional structured payload (field errors, retry time, ...)
	cause   error  // optional internal cause (logged, never rendered)
}

// New declares an error. Use it for package-level sentinels.
func New(status int, code, message string) *Error {
	return &Error{Status: status, Code: code, Message: message}
}

func (e *Error) Error() string {
	if e.cause != nil {
		return fmt.Sprintf("%s: %s: %v", e.Code, e.Message, e.cause)
	}
	return e.Code + ": " + e.Message
}

func (e *Error) Unwrap() error { return e.cause }

// Is makes errors.Is(err, ErrX) match on Code, so copies made by
// WithDetails/WithMessage still compare equal to their sentinel.
func (e *Error) Is(target error) bool {
	var t *Error
	if !errors.As(target, &t) {
		return false
	}
	return t.Code == e.Code && t.Status == e.Status
}

// WithDetails returns a copy carrying structured details.
func (e *Error) WithDetails(details any) *Error {
	c := *e
	c.Details = details
	return &c
}

// WithMessage returns a copy with a different message (same code).
func (e *Error) WithMessage(format string, args ...any) *Error {
	c := *e
	c.Message = fmt.Sprintf(format, args...)
	return &c
}

// Wrap returns a copy that records an internal cause for logging.
func (e *Error) Wrap(cause error) *Error {
	c := *e
	c.cause = cause
	return &c
}

// As extracts an *Error from any error chain.
func As(err error) (*Error, bool) {
	var e *Error
	if errors.As(err, &e) {
		return e, true
	}
	return nil, false
}

func BadRequest(message string) *Error {
	return New(http.StatusBadRequest, "BAD_REQUEST", message)
}

// Validation is a 400 with per-field reasons in details.
func Validation(details map[string]string) *Error {
	return New(http.StatusBadRequest, "VALIDATION_FAILED", "Some fields are invalid").WithDetails(map[string]any{"fields": details})
}

func Unauthorized(message string) *Error {
	return New(http.StatusUnauthorized, "UNAUTHORIZED", message)
}

func Forbidden(message string) *Error {
	return New(http.StatusForbidden, "FORBIDDEN", message)
}

func NotFound(message string) *Error {
	return New(http.StatusNotFound, "NOT_FOUND", message)
}

func TooManyRequests(message string) *Error {
	return New(http.StatusTooManyRequests, "TOO_MANY_REQUESTS", message)
}

// Internal is what every non-*Error renders as. Never put internals in it.
var Internal = New(http.StatusInternalServerError, "INTERNAL_ERROR", "An unexpected error occurred")
