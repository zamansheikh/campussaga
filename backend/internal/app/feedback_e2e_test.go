package app

import (
	"context"
	"fmt"
	"net/http"
	"strings"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/zamansheikh/varsitykotha/backend/internal/platform/media/mediatest"
)

type fbJSON struct {
	ID            string `json:"id"`
	Kind          string `json:"kind"`
	Message       string `json:"message"`
	Status        string `json:"status"`
	CreatedAt     string `json:"createdAt"`
	LastMessageAt string `json:"lastMessageAt"`
	Unread        int    `json:"unread"`
	Images        []struct {
		URL      string `json:"url"`
		ThumbURL string `json:"thumbUrl"`
	} `json:"images"`
	// Admin only.
	TeamUnread int    `json:"teamUnread"`
	Device     string `json:"device"`
	OS         string `json:"os"`
	AppVersion string `json:"appVersion"`
	Build      int    `json:"build"`
	Platform   string `json:"platform"`
	User       *struct {
		ID         string `json:"id"`
		Name       string `json:"name"`
		Email      string `json:"email"`
		University *struct {
			Name string `json:"name"`
		} `json:"university"`
	} `json:"user"`
	Messages []fbMsgJSON `json:"messages"`
}

type fbMsgJSON struct {
	ID        string `json:"id"`
	FromTeam  bool   `json:"fromTeam"`
	Body      string `json:"body"`
	CreatedAt string `json:"createdAt"`
	Author    *struct {
		ID   string `json:"id"`
		Name string `json:"name"`
	} `json:"author"`
}

func fbBody(kind, msg string) map[string]any {
	return map[string]any{"kind": kind, "message": msg, "appVersion": "1.0.2", "build": 8, "platform": "android",
		"device": "Pixel 7", "os": "Android 15", "locale": "en"}
}

func (h *harness) fbSend(tok string, body map[string]any) fbJSON {
	h.t.Helper()
	r := h.do("POST", "/feedback", tok, body)
	require.Equal(h.t, http.StatusCreated, r.Status, r.Raw)
	var f fbJSON
	r.into(h.t, &f)
	return f
}

func (h *harness) fbMine(tok string) []fbJSON {
	h.t.Helper()
	r := h.do("GET", "/me/feedback", tok, nil)
	require.Equal(h.t, http.StatusOK, r.Status, r.Raw)
	var out struct {
		Items []fbJSON `json:"items"`
	}
	r.into(h.t, &out)
	return out.Items
}

func (h *harness) fbAdminList(tok, query string) (items []fbJSON, total int) {
	h.t.Helper()
	r := h.do("GET", "/admin/feedback"+query, tok, nil)
	require.Equal(h.t, http.StatusOK, r.Status, r.Raw)
	var out struct {
		Items []fbJSON `json:"items"`
		Total int      `json:"total"`
	}
	r.into(h.t, &out)
	return out.Items, out.Total
}

func TestFeedbackCreateLimitAndImages(t *testing.T) {
	h := newHarness(t)
	h.voiceOn(true)
	s := h.caVerified("fay@test.ac.bd", "Fay")

	assert.Equal(t, "VALIDATION_FAILED", h.do("POST", "/feedback", s.Tok, fbBody("bug", "short")).code())
	assert.Equal(t, "VALIDATION_FAILED", h.do("POST", "/feedback", s.Tok, fbBody("rant", "A long enough message here")).code())
	assert.Equal(t, "VALIDATION_FAILED", h.do("POST", "/feedback", s.Tok, fbBody("bug", strings.Repeat("x", 2001))).code())
	body := fbBody("bug", "The routine page crashes when I open it")
	body["images"] = []string{"00000000-0000-0000-0000-0000000000aa"}
	assert.Equal(t, "UPLOAD_NOT_FOUND", h.do("POST", "/feedback", s.Tok, body).code())
	body["images"] = []string{"a", "b", "c", "d"}
	assert.Equal(t, "VALIDATION_FAILED", h.do("POST", "/feedback", s.Tok, body).code())
	assert.Empty(t, h.fbMine(s.Tok), "failed sends leave nothing")

	// Screenshots go through POST /uploads first.
	var ids []string
	for range 2 {
		r := h.upload(s.Tok, mediatest.JPEGWithExif(t, 800, 600, 1))
		require.Equal(t, http.StatusCreated, r.Status, r.Raw)
		var im struct {
			ID string `json:"id"`
		}
		r.into(t, &im)
		ids = append(ids, im.ID)
	}
	body = fbBody("bug", "The routine page crashes when I open it")
	body["images"] = ids
	f := h.fbSend(s.Tok, body)
	assert.Equal(t, "new", f.Status)
	assert.Equal(t, "bug", f.Kind)
	assert.Equal(t, 0, f.Unread)
	require.Len(t, f.Images, 2)
	assert.Equal(t, "/feedback/"+f.ID+"/images/"+ids[0], f.Images[0].URL)
	assert.Equal(t, f.Images[0].URL+"?size=thumb", f.Images[0].ThumbURL)
	code, data := h.raw(s.Tok, f.Images[0].ThumbURL)
	assert.Equal(t, http.StatusOK, code)
	assert.Equal(t, []byte{0xFF, 0xD8}, data[:2])
	code, _ = h.raw(s.Tok, f.Images[1].URL)
	assert.Equal(t, http.StatusOK, code)
	// An upload is used once.
	body["images"] = []string{ids[0]}
	assert.Equal(t, "UPLOAD_NOT_FOUND", h.do("POST", "/feedback", s.Tok, body).code())

	// Ten a day.
	for i := range 8 {
		h.fbSend(s.Tok, fbBody("idea", fmt.Sprintf("Please add dark mode number %d", i)))
	}
	assert.Len(t, h.fbMine(s.Tok), 9)
	h.fbSend(s.Tok, fbBody("other", "The tenth feedback of the day"))
	lr := h.do("POST", "/feedback", s.Tok, fbBody("other", "The eleventh feedback of the day"))
	assert.Equal(t, "FEEDBACK_LIMIT", lr.code())
	assert.Equal(t, http.StatusTooManyRequests, lr.Status)
	assert.Equal(t, http.StatusUnauthorized, h.do("POST", "/feedback", "", fbBody("bug", "Not signed in at all here")).Status)
}

func TestFeedbackConversation(t *testing.T) {
	h := newHarness(t)
	h.voiceOn(true)
	admin := h.makeAdmin("root@test.ac.bd")
	fay := h.caVerified("fay@test.ac.bd", "Fay")
	gus := h.caVerified("gus@test.ac.bd", "Gus")
	h.register(fay.Tok, "device-fay", "android", "en")
	h.register(gus.Tok, "device-gus", "android", "bn")

	f := h.fbSend(fay.Tok, fbBody("bug", "The routine page crashes when I open it"))
	g := h.fbSend(gus.Tok, fbBody("idea", "Please add a dark mode to the app"))
	assert.Empty(t, h.pushes(), "nothing is pushed when students send")

	// Own only.
	mine := h.fbMine(fay.Tok)
	require.Len(t, mine, 1)
	assert.Equal(t, f.ID, mine[0].ID)
	assert.Equal(t, "FEEDBACK_NOT_FOUND", h.do("GET", "/feedback/"+g.ID, fay.Tok, nil).code())
	assert.Equal(t, http.StatusNotFound, h.do("GET", "/feedback/"+g.ID, fay.Tok, nil).Status)
	assert.Equal(t, "FEEDBACK_NOT_FOUND", h.do("POST", "/feedback/"+g.ID+"/messages", fay.Tok, map[string]string{"body": "hello"}).code())
	code, _ := h.raw(fay.Tok, "/feedback/"+g.ID+"/images/00000000-0000-0000-0000-0000000000aa")
	assert.Equal(t, http.StatusNotFound, code)
	assert.Equal(t, http.StatusForbidden, h.do("GET", "/admin/feedback", fay.Tok, nil).Status)

	// A student message raises the team's counter; opening clears it, and
	// a new item becomes seen.
	r := h.do("POST", "/feedback/"+f.ID+"/messages", fay.Tok, map[string]string{"body": "It happens every time"})
	require.Equal(t, http.StatusCreated, r.Status, r.Raw)
	var m fbMsgJSON
	r.into(t, &m)
	assert.False(t, m.FromTeam)
	assert.Equal(t, "VALIDATION_FAILED", h.do("POST", "/feedback/"+f.ID+"/messages", fay.Tok, map[string]string{"body": "  "}).code())
	items, total := h.fbAdminList(admin, "")
	assert.Equal(t, 2, total)
	byID := map[string]fbJSON{}
	for _, it := range items {
		byID[it.ID] = it
	}
	assert.Equal(t, 1, byID[f.ID].TeamUnread)
	assert.Equal(t, 0, byID[g.ID].TeamUnread)
	assert.Equal(t, "Fay", byID[f.ID].User.Name)
	assert.Equal(t, "fay@test.ac.bd", byID[f.ID].User.Email)
	assert.Equal(t, "Test University", byID[f.ID].User.University.Name)
	assert.Equal(t, "Pixel 7", byID[f.ID].Device)
	assert.Equal(t, "Android 15", byID[f.ID].OS)
	assert.Equal(t, "1.0.2", byID[f.ID].AppVersion)
	assert.Equal(t, 8, byID[f.ID].Build)
	assert.Equal(t, "android", byID[f.ID].Platform)

	// The inbox and the dashboard count new or unread items.
	var inbox struct {
		FeedbackNew int `json:"feedbackNew"`
	}
	h.do("GET", "/admin/inbox", admin, nil).into(t, &inbox)
	assert.Equal(t, 2, inbox.FeedbackNew)
	var stats struct {
		Feedback struct{ New, Open, Last7Days int } `json:"feedback"`
	}
	h.do("GET", "/admin/stats", admin, nil).into(t, &stats)
	assert.Equal(t, 2, stats.Feedback.New)
	assert.Equal(t, 2, stats.Feedback.Open)
	assert.Equal(t, 2, stats.Feedback.Last7Days)

	// Opening: counter to 0, new -> seen. The team's names show only here.
	r = h.do("GET", "/admin/feedback/"+f.ID, admin, nil)
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	var d fbJSON
	r.into(t, &d)
	assert.Equal(t, "seen", d.Status)
	assert.Equal(t, 0, d.TeamUnread)
	require.Len(t, d.Messages, 1)
	assert.Equal(t, "It happens every time", d.Messages[0].Body)
	assert.Nil(t, d.Messages[0].Author, "student messages carry no author block")
	h.do("GET", "/admin/inbox", admin, nil).into(t, &inbox)
	assert.Equal(t, 1, inbox.FeedbackNew, "only Gus's stays new")

	// The team replies: unread for the student, a push in the device language.
	assert.Equal(t, "VALIDATION_FAILED", h.do("POST", "/admin/feedback/"+f.ID+"/messages", admin, map[string]string{"body": ""}).code())
	long := strings.Repeat("Thanks, ", 30)
	r = h.do("POST", "/admin/feedback/"+f.ID+"/messages", admin, map[string]string{"body": long})
	require.Equal(t, http.StatusCreated, r.Status, r.Raw)
	var tm fbMsgJSON
	r.into(t, &tm)
	assert.True(t, tm.FromTeam)
	require.NotNil(t, tm.Author)
	ns := h.pushes()
	require.Len(t, ns, 1)
	assert.Equal(t, "device-fay", ns[0].Token)
	assert.Equal(t, "VarsityKotha team replied", ns[0].Title)
	assert.Equal(t, strings.TrimSpace(long)[:120], ns[0].Body)
	assert.Equal(t, "feedback_reply", ns[0].Data["type"])
	assert.Equal(t, f.ID, ns[0].Data["feedbackId"])
	assert.Equal(t, 1, h.fbMine(fay.Tok)[0].Unread)

	// Opening the thread clears it. The team side has no names.
	r = h.do("GET", "/feedback/"+f.ID, fay.Tok, nil)
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	var th struct {
		Feedback fbJSON      `json:"feedback"`
		Messages []fbMsgJSON `json:"messages"`
	}
	r.into(t, &th)
	assert.Equal(t, f.ID, th.Feedback.ID)
	assert.Equal(t, 0, th.Feedback.Unread)
	require.Len(t, th.Messages, 2)
	assert.False(t, th.Messages[0].FromTeam)
	assert.True(t, th.Messages[1].FromTeam)
	assert.NotContains(t, r.Raw, "author")
	assert.NotContains(t, r.Raw, "root@test.ac.bd")
	assert.Equal(t, 0, h.fbMine(fay.Tok)[0].Unread)

	// A status change pushes (Bangla for Gus); the same status does not.
	r = h.do("PATCH", "/admin/feedback/"+g.ID, admin, map[string]string{"status": "planned"})
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	var upd fbJSON
	r.into(t, &upd)
	assert.Equal(t, "planned", upd.Status)
	ns = h.pushes()
	require.Len(t, ns, 1)
	assert.Equal(t, "device-gus", ns[0].Token)
	assert.Equal(t, "ভার্সিটি কথা টিম উত্তর দিয়েছে", ns[0].Title)
	assert.Equal(t, "অবস্থা: পরিকল্পনায় আছে", ns[0].Body)
	assert.Equal(t, g.ID, ns[0].Data["feedbackId"])
	require.Equal(t, http.StatusOK, h.do("PATCH", "/admin/feedback/"+g.ID, admin, map[string]string{"status": "planned"}).Status)
	assert.Empty(t, h.pushes())
	assert.Equal(t, "VALIDATION_FAILED", h.do("PATCH", "/admin/feedback/"+g.ID, admin, map[string]string{"status": "later"}).code())
	assert.Equal(t, "FEEDBACK_NOT_FOUND", h.do("PATCH", "/admin/feedback/00000000-0000-0000-0000-0000000000aa", admin, map[string]string{"status": "done"}).code())
	assert.Equal(t, "planned", h.fbMine(gus.Tok)[0].Status)

	// A closed item stays closed when the student writes; the team still sees it.
	require.Equal(t, http.StatusOK, h.do("PATCH", "/admin/feedback/"+f.ID, admin, map[string]string{"status": "done"}).Status)
	h.pushes()
	require.Equal(t, http.StatusCreated, h.do("POST", "/feedback/"+f.ID+"/messages", fay.Tok, map[string]string{"body": "Still broken for me"}).Status)
	items, _ = h.fbAdminList(admin, "?status=closed")
	require.Len(t, items, 1)
	assert.Equal(t, "done", items[0].Status)
	assert.Equal(t, 1, items[0].TeamUnread)
	h.do("GET", "/admin/inbox", admin, nil).into(t, &inbox)
	assert.Equal(t, 1, inbox.FeedbackNew, "Gus's is planned now; Fay's closed item has an unread message")

	// Audit rows.
	var replies, statuses int
	require.NoError(t, h.app.DB.Pool.QueryRow(context.Background(), `SELECT count(*) FROM audit_log WHERE action = 'feedback.reply'`).Scan(&replies))
	require.NoError(t, h.app.DB.Pool.QueryRow(context.Background(), `SELECT count(*) FROM audit_log WHERE action = 'feedback.status'`).Scan(&statuses))
	assert.Equal(t, 1, replies)
	assert.Equal(t, 2, statuses)
}

func TestFeedbackAdminFilters(t *testing.T) {
	h := newHarness(t)
	admin := h.makeAdmin("root@test.ac.bd")
	fay := h.caVerified("fay@test.ac.bd", "Fay")
	gus := h.caVerified("gus@test.ac.bd", "Gus")
	bug := h.fbSend(fay.Tok, fbBody("bug", "The routine page crashes when I open it"))
	idea := h.fbSend(gus.Tok, fbBody("idea", "Please add a dark mode to the app"))
	other := h.fbSend(gus.Tok, fbBody("other", "Thanks for the app, really useful"))
	for id, st := range map[string]string{idea.ID: "in_progress", other.ID: "wont_do"} {
		require.Equal(t, http.StatusOK, h.do("PATCH", "/admin/feedback/"+id, admin, map[string]string{"status": st}).Status)
	}

	ids := func(query string) []string {
		items, _ := h.fbAdminList(admin, query)
		out := []string{}
		for _, it := range items {
			out = append(out, it.ID)
		}
		return out
	}
	assert.ElementsMatch(t, []string{bug.ID, idea.ID, other.ID}, ids(""))
	assert.ElementsMatch(t, []string{bug.ID, idea.ID}, ids("?status=open"))
	assert.ElementsMatch(t, []string{other.ID}, ids("?status=closed"))
	assert.ElementsMatch(t, []string{idea.ID}, ids("?status=in_progress"))
	assert.ElementsMatch(t, []string{bug.ID}, ids("?status=new"))
	assert.ElementsMatch(t, []string{bug.ID}, ids("?kind=bug"))
	assert.ElementsMatch(t, []string{idea.ID}, ids("?kind=idea&status=open"))
	assert.ElementsMatch(t, []string{idea.ID}, ids("?q=dark+mode"))
	assert.ElementsMatch(t, []string{idea.ID, other.ID}, ids("?q=gus@test"))
	assert.Empty(t, ids("?q=nothing-like-this"))
	assert.Equal(t, "VALIDATION_FAILED", h.do("GET", "/admin/feedback?status=weird", admin, nil).code())
	assert.Equal(t, "VALIDATION_FAILED", h.do("GET", "/admin/feedback?kind=weird", admin, nil).code())

	r := h.do("GET", "/admin/feedback?pageSize=2&page=2", admin, nil)
	var p struct {
		Items    []fbJSON `json:"items"`
		Total    int      `json:"total"`
		Page     int      `json:"page"`
		PageSize int      `json:"pageSize"`
	}
	r.into(t, &p)
	assert.Equal(t, 3, p.Total)
	assert.Equal(t, 2, p.Page)
	assert.Equal(t, 2, p.PageSize)
	assert.Len(t, p.Items, 1)

	// A deleted account leaves the feedback without a user.
	h.caExec(`DELETE FROM users WHERE id = $1`, fay.ID)
	r = h.do("GET", "/admin/feedback/"+bug.ID, admin, nil)
	require.Equal(t, http.StatusOK, r.Status, r.Raw)
	var d fbJSON
	r.into(t, &d)
	assert.Nil(t, d.User)
}
