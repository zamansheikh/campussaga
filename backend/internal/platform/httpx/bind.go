package httpx

import (
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"reflect"
	"strings"

	"github.com/go-chi/chi/v5"
	"github.com/go-playground/validator/v10"

	"github.com/zamansheikh/varsitykotha/backend/internal/platform/apperr"
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
		if name := f.Tag.Get("query"); name != "" {
			return name
		}
		if name := f.Tag.Get("path"); name != "" {
			return name
		}
		return f.Name
	})
	return v
}

// Validator exposes the shared validator (for module-specific tags).
func Validator() *validator.Validate { return validate }

// Bind fills dst from the URL path (string fields tagged `path:"name"`,
// matching a {name} route parameter), the query string (`query:"name"`)
// and the JSON body (if any), then validates it.
func Bind(r *http.Request, dst any) error {
	bindStrings(dst, "query", func(name string) (string, bool) {
		q := r.URL.Query()
		return q.Get(name), q.Has(name)
	})
	if rc := chi.RouteContext(r.Context()); rc != nil {
		bindStrings(dst, "path", func(name string) (string, bool) {
			v := rc.URLParam(name)
			return v, v != ""
		})
	}
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

// bindStrings copies values into string fields tagged `<tag>:"name"`,
// including fields of embedded structs. The body is decoded afterwards with
// DisallowUnknownFields, and query and path fields carry `json:"-"`, so a
// body can never set them.
func bindStrings(dst any, tag string, get func(name string) (string, bool)) {
	v := reflect.ValueOf(dst)
	if v.Kind() != reflect.Pointer || v.Elem().Kind() != reflect.Struct {
		return
	}
	bindStruct(v.Elem(), tag, get)
}

func bindStruct(v reflect.Value, tag string, get func(name string) (string, bool)) {
	t := v.Type()
	for i := 0; i < t.NumField(); i++ {
		f := t.Field(i)
		if f.Anonymous && f.Type.Kind() == reflect.Struct {
			bindStruct(v.Field(i), tag, get)
			continue
		}
		name := f.Tag.Get(tag)
		if name == "" || f.Type.Kind() != reflect.String || !f.IsExported() {
			continue
		}
		if val, ok := get(name); ok {
			v.Field(i).SetString(val)
		}
	}
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
