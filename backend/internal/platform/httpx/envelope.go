// Package httpx is the HTTP edge: the response envelope, typed handlers,
// request binding + validation, route groups with the auth guards, and
// middleware.
//
// Wire contract (the Flutter app's campus_data package parses it):
//
//	success: {"success":true,"data":<T>,"error":null,"meta":{"timestamp":"…"}}
//	failure: {"success":false,"data":null,"error":{"code":"…","message":"…","details":…},
//	          "meta":{"path":"/api/v1/…","timestamp":"…"}}
//
// The trace id travels in the X-Trace-Id header.
package httpx

import (
	"context"
	"encoding/json"
	"errors"
	"log/slog"
	"net/http"
	"time"

	"github.com/zamansheikh/campussaga/backend/internal/platform/apperr"
)

type successEnvelope struct {
	Success bool        `json:"success"`
	Data    any         `json:"data"`
	Error   *struct{}   `json:"error"`
	Meta    successMeta `json:"meta"`
}

type successMeta struct {
	Timestamp string `json:"timestamp"`
}

type errorBody struct {
	Code    string `json:"code"`
	Message string `json:"message"`
	Details any    `json:"details,omitempty"`
}

type errorEnvelope struct {
	Success bool      `json:"success"`
	Data    *struct{} `json:"data"`
	Error   errorBody `json:"error"`
	Meta    errorMeta `json:"meta"`
}

type errorMeta struct {
	Path      string `json:"path"`
	Timestamp string `json:"timestamp"`
}

func timestamp() string { return time.Now().UTC().Format("2006-01-02T15:04:05.000Z") }

// WriteOK writes a success envelope.
func WriteOK(w http.ResponseWriter, _ *http.Request, status int, data any) {
	writeJSON(w, status, successEnvelope{
		Success: true,
		Data:    data,
		Meta:    successMeta{Timestamp: timestamp()},
	})
}

// WriteError renders err. Anything that is not an *apperr.Error is a bug: it
// is logged and answered with a generic 500.
func WriteError(w http.ResponseWriter, r *http.Request, err error) {
	ae, ok := apperr.As(err)
	if !ok {
		if errors.Is(err, context.Canceled) {
			ae = apperr.New(499, "CLIENT_CLOSED_REQUEST", "Client closed request")
		} else {
			Logger(r.Context()).Error("unhandled error", "err", err, "path", r.URL.Path, "method", r.Method)
			ae = apperr.Internal
		}
	} else if ae.Status >= 500 {
		Logger(r.Context()).Error("server error", "err", err, "path", r.URL.Path, "method", r.Method)
	}
	if retry, ok := ae.Details.(RetryAfter); ok {
		w.Header().Set("Retry-After", retry.Header())
	}
	writeJSON(w, ae.Status, errorEnvelope{
		Error: errorBody{Code: ae.Code, Message: ae.Message, Details: ae.Details},
		Meta:  errorMeta{Path: r.URL.Path, Timestamp: timestamp()},
	})
}

// RetryAfter as error details also sets the Retry-After header.
type RetryAfter struct {
	RetryAfterSeconds int `json:"retryAfterSeconds"`
}

func (r RetryAfter) Header() string { return itoa(r.RetryAfterSeconds) }

func writeJSON(w http.ResponseWriter, status int, v any) {
	buf, err := json.Marshal(v)
	if err != nil {
		slog.Error("httpx: marshal response", "err", err)
		w.Header().Set("Content-Type", "application/json; charset=utf-8")
		w.WriteHeader(http.StatusInternalServerError)
		_, _ = w.Write([]byte(`{"success":false,"data":null,"error":{"code":"INTERNAL_ERROR","message":"An unexpected error occurred"},"meta":{}}`))
		return
	}
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(status)
	_, _ = w.Write(buf)
}
