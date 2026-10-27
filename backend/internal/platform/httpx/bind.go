package httpx

import (
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"reflect"
	"strings"

	"github.com/go-playground/validator/v10"

	"github.com/zamansheikh/campussaga/backend/internal/platform/apperr"
)

// Request DTOs are plain structs filled from the JSON body:
//
//	type UpdateMeReq struct {
//	    DisplayName *string `json:"displayName" validate:"omitnil,min=1,max=60"`
//	}
//
// Unknown JSON fields are rejected (400 BAD_REQUEST), so a client can never
// smuggle a field such as "role" into an update. Validation uses
// go-playground/validator tags; errors come back per JSON field name.

var validate = newValidator()

func newValidator() *validator.Validate {
	v := validator.New(validator.WithRequiredStructEnabled())
	v.RegisterTagNameFunc(func(f reflect.StructField) string {
		if name := strings.Split(f.Tag.Get("json"), ",")[0]; name != "" && name != "-" {
			return name
		}
		return f.Name
	})
	return v
}

// Validator exposes the shared validator (for module-specific tags).
func Validator() *validator.Validate { return validate }

// Bind decodes the JSON body (if any) into dst and validates it.
func Bind(r *http.Request, dst any) error {
	if r.Body != nil && r.ContentLength != 0 && r.Method != http.MethodGet {
		dec := json.NewDecoder(r.Body)
		dec.DisallowUnknownFields()
		if err := dec.Decode(dst); err != nil && !errors.Is(err, io.EOF) {
			var tooBig *http.MaxBytesError
			if errors.As(err, &tooBig) {
				return apperr.New(http.StatusRequestEntityTooLarge, "PAYLOAD_TOO_LARGE", "Request body is too large")
			}
			msg := "Invalid JSON body"
			if strings.HasPrefix(err.Error(), "json: unknown field") {
				msg = "Unknown field " + strings.TrimPrefix(err.Error(), "json: unknown field ")
			}
			return apperr.BadRequest(msg)
		}
	}
	return Validate(dst)
}

// Validate runs the struct's validate tags.
func Validate(v any) error {
	err := validate.Struct(v)
	if err == nil {
		return nil
	}
	var verrs validator.ValidationErrors
	if !errors.As(err, &verrs) {
		return apperr.BadRequest("Invalid request")
	}
	fields := map[string]string{}
	for _, fe := range verrs {
		fields[fe.Field()] = describe(fe)
	}
	return apperr.Validation(fields)
}

func describe(fe validator.FieldError) string {
	switch fe.Tag() {
	case "required":
		return "is required"
	case "email":
		return "must be a valid email address"
	case "min":
		return "is too short"
	case "max":
		return "is too long"
	case "len":
		return "has the wrong length"
	case "numeric":
		return "must contain digits only"
	default:
		return "is invalid"
	}
}
