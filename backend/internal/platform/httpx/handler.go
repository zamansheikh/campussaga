package httpx

import (
	"context"
	"net/http"
	"strconv"
)

// Empty is the input/output type for handlers that take or return nothing.
type Empty struct{}

// HandlerOption tunes a typed handler.
type HandlerOption func(*handlerConfig)

type handlerConfig struct {
	status int
}

// Status overrides the success status (default 200).
func Status(code int) HandlerOption { return func(c *handlerConfig) { c.status = code } }

// NoContent marks a handler whose success is 204 with an empty body.
func NoContent() HandlerOption { return Status(http.StatusNoContent) }

// Handle adapts a typed function into an http.HandlerFunc: bind + validate
// In, call fn, render Out in the success envelope, or the error envelope.
//
//	r.Student().Patch("/me", httpx.Handle(h.updateMe))
//	func (h *handler) updateMe(ctx context.Context, in *UpdateMeReq) (*MeRes, error)
func Handle[In any, Out any](fn func(ctx context.Context, in *In) (Out, error), opts ...HandlerOption) http.HandlerFunc {
	var cfg handlerConfig
	for _, o := range opts {
		o(&cfg)
	}
	return func(w http.ResponseWriter, r *http.Request) {
		in := new(In)
		if err := Bind(r, in); err != nil {
			WriteError(w, r, err)
			return
		}
		out, err := fn(r.Context(), in)
		if err != nil {
			WriteError(w, r, err)
			return
		}
		status := cfg.status
		if status == 0 {
			status = http.StatusOK
		}
		if status == http.StatusNoContent {
			w.WriteHeader(http.StatusNoContent)
			return
		}
		WriteOK(w, r, status, out)
	}
}

func itoa(n int) string { return strconv.Itoa(n) }
