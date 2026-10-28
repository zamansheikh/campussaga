package app

import (
	"bytes"
	"context"
	"encoding/json"
	"io"
	"mime/multipart"
	"net/http"
	"time"

	"github.com/stretchr/testify/require"
)

// Campus Voice test helpers.

func (h *harness) voiceOn(on bool) {
	h.t.Helper()
	v := "false"
	if on {
		v = "true"
	}
	_, err := h.app.DB.Pool.Exec(context.Background(),
		`UPDATE app_config SET value = jsonb_set(value, '{campusVoice}', $1::jsonb) WHERE key = 'features'`, v)
	require.NoError(h.t, err)
}

// addStaff makes userID an authority (of test-uni, with title) or a moderator.
func (h *harness) addStaff(admin, userID, kind, title string) {
	h.t.Helper()
	body := map[string]any{"userId": userID, "kind": kind, "title": title}
	if kind == "authority" {
		body["universityId"] = h.universityID("test-uni")
	}
	r := h.do("POST", "/admin/staff", admin, body)
	require.Equal(h.t, http.StatusCreated, r.Status, r.Raw)
}

type voiceAuthorJSON struct {
	Name     *string `json:"name"`
	Verified bool    `json:"verified"`
}

type issueJSON struct {
	ID            string           `json:"id"`
	Category      string           `json:"category"`
	Private       bool             `json:"private"`
	Title         string           `json:"title"`
	Status        string           `json:"status"`
	Visibility    string           `json:"visibility"`
	MeTooCount    int              `json:"meTooCount"`
	CommentCount  int              `json:"commentCount"`
	ImageCount    int              `json:"imageCount"`
	Voted         bool             `json:"voted"`
	Following     bool             `json:"following"`
	Mine          bool             `json:"mine"`
	Author        *voiceAuthorJSON `json:"author"`
	CreatedAt     time.Time        `json:"createdAt"`
	HoldReason    string           `json:"holdReason"`
	RemovedReason string           `json:"removedReason"`
	ReportCount   int              `json:"reportCount"`
	Images        []struct {
		ID string `json:"id"`
	} `json:"images"`
	Timeline []struct {
		From, To, ActorKind, ActorTitle, Note string
	} `json:"timeline"`
	Can map[string]bool `json:"can"`
}

type voiceCommentJSON struct {
	ID            string           `json:"id"`
	Kind          string           `json:"kind"`
	Handle        string           `json:"handle"`
	IsIssueAuthor bool             `json:"isIssueAuthor"`
	Mine          bool             `json:"mine"`
	Author        *voiceAuthorJSON `json:"author"`
	OfficialTitle string           `json:"officialTitle"`
	Visibility    string           `json:"visibility"`
	CreatedAt     time.Time        `json:"createdAt"`
}

type voicePage[T any] struct {
	Items      []T     `json:"items"`
	NextCursor *string `json:"nextCursor"`
}

func issueBody(title string, extra ...map[string]any) map[string]any {
	b := map[string]any{"category": "hostel", "title": title,
		"body": "The water pump on the third floor has been broken for a week."}
	for _, e := range extra {
		for k, v := range e {
			b[k] = v
		}
	}
	return b
}

func (h *harness) postIssue(tok string, body map[string]any) issueJSON {
	h.t.Helper()
	r := h.do("POST", "/issues", tok, body)
	require.Equal(h.t, http.StatusCreated, r.Status, r.Raw)
	var is issueJSON
	r.into(h.t, &is)
	return is
}

func (h *harness) getIssue(tok, id string) issueJSON {
	h.t.Helper()
	r := h.do("GET", "/issues/"+id, tok, nil)
	require.Equal(h.t, http.StatusOK, r.Status, r.Raw)
	var is issueJSON
	r.into(h.t, &is)
	return is
}

func (h *harness) comment(tok, issueID string, body map[string]any) voiceCommentJSON {
	h.t.Helper()
	r := h.do("POST", "/issues/"+issueID+"/comments", tok, body)
	require.Equal(h.t, http.StatusCreated, r.Status, r.Raw)
	var c voiceCommentJSON
	r.into(h.t, &c)
	return c
}

func (h *harness) comments(tok, issueID string) []voiceCommentJSON {
	h.t.Helper()
	r := h.do("GET", "/issues/"+issueID+"/comments", tok, nil)
	require.Equal(h.t, http.StatusOK, r.Status, r.Raw)
	var p voicePage[voiceCommentJSON]
	r.into(h.t, &p)
	return p.Items
}

func (h *harness) feed(tok, query string) []issueJSON {
	h.t.Helper()
	r := h.do("GET", "/issues"+query, tok, nil)
	require.Equal(h.t, http.StatusOK, r.Status, r.Raw)
	var p voicePage[issueJSON]
	r.into(h.t, &p)
	return p.Items
}

// upload sends a photo as multipart/form-data and returns the response.
func (h *harness) upload(tok string, data []byte) *response {
	h.t.Helper()
	var body bytes.Buffer
	mw := multipart.NewWriter(&body)
	fw, err := mw.CreateFormFile("image", "IMG_20261027_my_name.jpg")
	require.NoError(h.t, err)
	_, _ = fw.Write(data)
	require.NoError(h.t, mw.Close())
	req, err := http.NewRequest("POST", h.srv.URL+"/api/v1/uploads", &body)
	require.NoError(h.t, err)
	req.Header.Set("Content-Type", mw.FormDataContentType())
	req.Header.Set("Authorization", "Bearer "+tok)
	res, err := http.DefaultClient.Do(req)
	require.NoError(h.t, err)
	defer res.Body.Close()
	raw, _ := io.ReadAll(res.Body)
	out := &response{Status: res.StatusCode, Header: res.Header, Raw: string(raw)}
	if len(raw) > 0 {
		require.NoError(h.t, json.Unmarshal(raw, out), string(raw))
	}
	return out
}

// raw fetches a path (any content type) and returns status and body.
func (h *harness) raw(tok, path string) (int, []byte) {
	h.t.Helper()
	req, err := http.NewRequest("GET", h.srv.URL+"/api/v1"+path, nil)
	require.NoError(h.t, err)
	if tok != "" {
		req.Header.Set("Authorization", "Bearer "+tok)
	}
	res, err := http.DefaultClient.Do(req)
	require.NoError(h.t, err)
	defer res.Body.Close()
	b, _ := io.ReadAll(res.Body)
	return res.StatusCode, b
}
