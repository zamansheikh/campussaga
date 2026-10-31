// Package feedback is in-app feedback (docs/FEEDBACK.md): students send a
// bug report, an idea or other feedback, optionally with screenshots; the
// team sets a status and replies from the admin panel; the student gets a
// push and can answer back. Each piece of feedback is a short conversation.
//
// Screenshots use the Campus upload pipeline: the app POSTs /uploads (re-
// encoding, nudity check, thumbnail) and sends the upload ids here.
// Image URLs are paths relative to the API prefix.
package feedback

import (
	"context"
	"encoding/json"
	"net/http"
	"strings"
	"time"
	"unicode/utf8"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"

	"github.com/zamansheikh/varsitykotha/backend/internal/platform/apperr"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/auth"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/db"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/httpx"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/media"
)

const (
	// PerDay: feedback a student can send in 24 hours.
	PerDay    = 10
	MaxImages = 3
)

var (
	ErrNotFound  = apperr.New(http.StatusNotFound, "FEEDBACK_NOT_FOUND", "This feedback was not found")
	ErrLimit     = apperr.New(http.StatusTooManyRequests, "FEEDBACK_LIMIT", "You have sent the most feedback allowed today. Try again tomorrow")
	ErrUpload    = apperr.New(http.StatusNotFound, "UPLOAD_NOT_FOUND", "This photo was not found. Upload it again")
	ErrImageGone = apperr.New(http.StatusNotFound, "IMAGE_NOT_FOUND", "This photo was not found")
)

// NoticeText is a push in one language.
type NoticeText struct{ Title, Body string }

// Notice is a push; Texts are keyed by language ("en", "bn").
type Notice struct {
	Texts map[string]NoticeText
	Data  map[string]string
}

// Notifier sends a Notice to a student's phones (wired to the push module).
type Notifier func(userIDs []uuid.UUID, n Notice)

type Service struct {
	d      *db.DB
	media  media.Store
	now    func() time.Time
	notify Notifier
}

func NewService(d *db.DB, store media.Store, now func() time.Time) *Service {
	return &Service{d: d, media: store, now: now}
}

// SetNotifier turns pushes on.
func (s *Service) SetNotifier(n Notifier) { s.notify = n }

func (s *Service) Routes(r *httpx.Router) {
	st := r.Student()
	st.Post("/feedback", httpx.Handle(s.handleCreate, httpx.Status(http.StatusCreated)))
	st.Get("/me/feedback", httpx.Handle(s.handleMine))
	st.Get("/feedback/{id}", httpx.Handle(s.handleThread))
	st.With(r.LimitUser("feedback-message", 60, time.Hour)).Post("/feedback/{id}/messages", httpx.Handle(s.handleReply, httpx.Status(http.StatusCreated)))
	st.Get("/feedback/{id}/images/{imageId}", s.handleImage(false))

	a := r.Admin()
	a.Get("/admin/feedback", httpx.Handle(s.handleAdminList))
	a.Get("/admin/feedback/{id}", httpx.Handle(s.handleAdminGet))
	a.Post("/admin/feedback/{id}/messages", httpx.Handle(s.handleAdminReply, httpx.Status(http.StatusCreated)))
	a.Patch("/admin/feedback/{id}", httpx.Handle(s.handleAdminStatus))
	a.Get("/admin/feedback/{id}/images/{imageId}", s.handleImage(true))
}

// ---- views --------------------------------------------------------------------------

type ImageRef struct {
	URL      string `json:"url"`
	ThumbURL string `json:"thumbUrl"`
}

// Feedback is one piece of feedback as its sender sees it.
type Feedback struct {
	ID            uuid.UUID  `json:"id"`
	Kind          string     `json:"kind"`
	Message       string     `json:"message"`
	Status        string     `json:"status"`
	Images        []ImageRef `json:"images"`
	CreatedAt     time.Time  `json:"createdAt"`
	LastMessageAt time.Time  `json:"lastMessageAt"`
	Unread        int        `json:"unread"`
}

// Message: team messages show no staff name to students.
type Message struct {
	ID        uuid.UUID `json:"id"`
	FromTeam  bool      `json:"fromTeam"`
	Body      string    `json:"body"`
	CreatedAt time.Time `json:"createdAt"`
}

type Thread struct {
	Feedback Feedback  `json:"feedback"`
	Messages []Message `json:"messages"`
}

type row struct {
	Feedback
	userID     *uuid.UUID
	uniID      *uuid.UUID
	appVersion string
	build      int
	platform   string
	device     string
	os         string
	locale     string
	teamUnread int
}

const cols = `f.id, f.kind, f.message, f.status, f.created_at, f.last_message_at, f.user_unread, f.user_id, f.university_id,
	f.app_version, f.build, f.platform, f.device, f.os, f.locale, f.team_unread`

type scanner interface{ Scan(dest ...any) error }

func scanRow(r scanner) (row, error) {
	var x row
	err := r.Scan(&x.ID, &x.Kind, &x.Message, &x.Status, &x.CreatedAt, &x.LastMessageAt, &x.Unread, &x.userID, &x.uniID,
		&x.appVersion, &x.build, &x.platform, &x.device, &x.os, &x.locale, &x.teamUnread)
	x.Images = []ImageRef{}
	return x, err
}

func imageRef(feedback, image uuid.UUID) ImageRef {
	u := "/feedback/" + feedback.String() + "/images/" + image.String()
	return ImageRef{URL: u, ThumbURL: u + "?size=thumb"}
}

// fillImages adds each row's screenshots.
func (s *Service) fillImages(ctx context.Context, rows []row) error {
	if len(rows) == 0 {
		return nil
	}
	ids := make([]string, len(rows))
	at := map[uuid.UUID]int{}
	for i, r := range rows {
		ids[i], at[r.ID] = r.ID.String(), i
	}
	rs, err := s.d.Q(ctx).Query(ctx, `SELECT feedback_id, id FROM feedback_images WHERE feedback_id = ANY($1::uuid[]) ORDER BY position`, ids)
	if err != nil {
		return err
	}
	defer rs.Close()
	for rs.Next() {
		var f, im uuid.UUID
		if err := rs.Scan(&f, &im); err != nil {
			return err
		}
		rows[at[f]].Images = append(rows[at[f]].Images, imageRef(f, im))
	}
	return rs.Err()
}

func (s *Service) one(ctx context.Context, id uuid.UUID, owner *uuid.UUID, forUpdate bool) (row, error) {
	sql := `SELECT ` + cols + ` FROM feedback f WHERE f.id = $1 AND ($2::uuid IS NULL OR f.user_id = $2)`
	if forUpdate {
		sql += ` FOR UPDATE`
	}
	x, err := scanRow(s.d.Q(ctx).QueryRow(ctx, sql, id, owner))
	if db.IsNoRows(err) {
		return x, ErrNotFound
	}
	if err != nil {
		return x, err
	}
	list := []row{x}
	if err := s.fillImages(ctx, list); err != nil {
		return x, err
	}
	return list[0], nil
}

// ---- students -----------------------------------------------------------------------

type createReq struct {
	Kind       string   `json:"kind" validate:"required,oneof=bug idea other"`
	Message    string   `json:"message" validate:"required,max=2000"`
	Images     []string `json:"images" validate:"max=3,dive,uuid"`
	AppVersion string   `json:"appVersion" validate:"max=20"`
	Build      int      `json:"build" validate:"min=0,max=100000000"`
	Platform   string   `json:"platform" validate:"max=20"`
	Device     string   `json:"device" validate:"max=80"`
	OS         string   `json:"os" validate:"max=40"`
	Locale     string   `json:"locale" validate:"max=10"`
}

func clean(s string) string { return strings.TrimSpace(s) }

func (s *Service) handleCreate(ctx context.Context, in *createReq) (*Feedback, error) {
	msg := clean(in.Message)
	if n := utf8.RuneCountInString(msg); n < 10 || n > 2000 {
		return nil, apperr.Validation(map[string]string{"message": "must be 10 to 2000 characters"})
	}
	me := auth.MustUser(ctx).UserID
	now := s.now()
	var id uuid.UUID
	err := s.d.InTx(ctx, func(ctx context.Context) error {
		q := s.d.Q(ctx)
		// Serialise a student's sends so the daily limit holds.
		if _, err := q.Exec(ctx, `SELECT 1 FROM users WHERE id = $1 FOR UPDATE`, me); err != nil {
			return err
		}
		var n int
		if err := q.QueryRow(ctx, `SELECT count(*)::int FROM feedback WHERE user_id = $1 AND created_at > $2`,
			me, now.Add(-24*time.Hour)).Scan(&n); err != nil {
			return err
		}
		if n >= PerDay {
			return ErrLimit
		}
		if err := q.QueryRow(ctx, `
			INSERT INTO feedback (user_id, university_id, kind, message, app_version, build, platform, device, os, locale,
			                      created_at, updated_at, last_message_at)
			VALUES ($1, (SELECT university_id FROM users WHERE id = $1), $2, $3, $4, $5, $6, $7, $8, $9, $10, $10, $10)
			RETURNING id`, me, in.Kind, msg, clean(in.AppVersion), in.Build, clean(in.Platform), clean(in.Device),
			clean(in.OS), clean(in.Locale), now).Scan(&id); err != nil {
			return err
		}
		seen := map[string]bool{}
		for pos, raw := range in.Images {
			if seen[raw] {
				continue
			}
			seen[raw] = true
			var full, thumb string
			var w, h int
			err := q.QueryRow(ctx, `SELECT full_key, thumb_key, width, height FROM uploads WHERE id = $1 AND user_id = $2 FOR UPDATE`,
				uuid.MustParse(raw), me).Scan(&full, &thumb, &w, &h)
			if db.IsNoRows(err) {
				return ErrUpload
			}
			if err != nil {
				return err
			}
			if _, err := q.Exec(ctx, `INSERT INTO feedback_images (id, feedback_id, position, full_key, thumb_key, width, height)
				VALUES ($1, $2, $3, $4, $5, $6, $7)`, uuid.MustParse(raw), id, pos, full, thumb, w, h); err != nil {
				return err
			}
			// The files now belong to the feedback; only the pending row goes.
			if _, err := q.Exec(ctx, `DELETE FROM uploads WHERE id = $1`, uuid.MustParse(raw)); err != nil {
				return err
			}
		}
		return nil
	})
	if err != nil {
		return nil, err
	}
	x, err := s.one(ctx, id, &me, false)
	return &x.Feedback, err
}

type listRes struct {
	Items []Feedback `json:"items"`
}

func (s *Service) handleMine(ctx context.Context, _ *httpx.Empty) (*listRes, error) {
	me := auth.MustUser(ctx).UserID
	rs, err := s.d.Q(ctx).Query(ctx, `SELECT `+cols+` FROM feedback f WHERE f.user_id = $1 ORDER BY f.last_message_at DESC, f.id LIMIT 200`, me)
	if err != nil {
		return nil, err
	}
	var rows []row
	for rs.Next() {
		x, err := scanRow(rs)
		if err != nil {
			rs.Close()
			return nil, err
		}
		rows = append(rows, x)
	}
	rs.Close()
	if err := rs.Err(); err != nil {
		return nil, err
	}
	if err := s.fillImages(ctx, rows); err != nil {
		return nil, err
	}
	out := &listRes{Items: make([]Feedback, 0, len(rows))}
	for _, r := range rows {
		out.Items = append(out.Items, r.Feedback)
	}
	return out, nil
}

type idReq struct {
	ID string `json:"-" path:"id" validate:"required,uuid"`
}

type adminMessage struct {
	Message
	Author *authorRef `json:"author"`
}

type authorRef struct {
	ID   uuid.UUID `json:"id"`
	Name string    `json:"name"`
}

// messages returns the thread; team=true adds the team authors' names.
func (s *Service) messages(ctx context.Context, id uuid.UUID) ([]adminMessage, error) {
	rs, err := s.d.Q(ctx).Query(ctx, `
		SELECT m.id, m.from_team, m.body, m.created_at, u.id, coalesce(u.display_name, '')
		FROM feedback_messages m LEFT JOIN users u ON u.id = m.author_id
		WHERE m.feedback_id = $1 ORDER BY m.created_at, m.seq`, id)
	if err != nil {
		return nil, err
	}
	defer rs.Close()
	out := []adminMessage{}
	for rs.Next() {
		var m adminMessage
		var aid *uuid.UUID
		var name string
		if err := rs.Scan(&m.ID, &m.FromTeam, &m.Body, &m.CreatedAt, &aid, &name); err != nil {
			return nil, err
		}
		if m.FromTeam && aid != nil {
			m.Author = &authorRef{ID: *aid, Name: name}
		}
		out = append(out, m)
	}
	return out, rs.Err()
}

func (s *Service) handleThread(ctx context.Context, in *idReq) (*Thread, error) {
	me := auth.MustUser(ctx).UserID
	id := uuid.MustParse(in.ID)
	var x row
	err := s.d.InTx(ctx, func(ctx context.Context) error {
		var err error
		if x, err = s.one(ctx, id, &me, true); err != nil {
			return err
		}
		if x.Unread > 0 {
			if _, err := s.d.Q(ctx).Exec(ctx, `UPDATE feedback SET user_unread = 0 WHERE id = $1`, id); err != nil {
				return err
			}
			x.Unread = 0
		}
		return nil
	})
	if err != nil {
		return nil, err
	}
	ms, err := s.messages(ctx, id)
	if err != nil {
		return nil, err
	}
	out := &Thread{Feedback: x.Feedback, Messages: make([]Message, 0, len(ms))}
	for _, m := range ms {
		out.Messages = append(out.Messages, m.Message)
	}
	return out, nil
}

type bodyReq struct {
	ID   string `json:"-" path:"id" validate:"required,uuid"`
	Body string `json:"body" validate:"required,max=2000"`
}

func cleanBody(b string) (string, error) {
	b = strings.TrimSpace(b)
	if n := utf8.RuneCountInString(b); n < 1 || n > 2000 {
		return "", apperr.Validation(map[string]string{"body": "must be 1 to 2000 characters"})
	}
	return b, nil
}

func (s *Service) handleReply(ctx context.Context, in *bodyReq) (*Message, error) {
	body, err := cleanBody(in.Body)
	if err != nil {
		return nil, err
	}
	me := auth.MustUser(ctx).UserID
	id := uuid.MustParse(in.ID)
	var out *Message
	err = s.d.InTx(ctx, func(ctx context.Context) error {
		if _, err := s.one(ctx, id, &me, true); err != nil {
			return err
		}
		m, err := s.addMessage(ctx, id, &me, false, body)
		out = m
		return err
	})
	return out, err
}

// addMessage stores a message and moves the counters: a student's raises
// the team's unread count, the team's raises the student's.
func (s *Service) addMessage(ctx context.Context, id uuid.UUID, author *uuid.UUID, fromTeam bool, body string) (*Message, error) {
	now := s.now()
	m := &Message{FromTeam: fromTeam, Body: body, CreatedAt: now}
	q := s.d.Q(ctx)
	if err := q.QueryRow(ctx, `INSERT INTO feedback_messages (feedback_id, author_id, from_team, body, created_at)
		VALUES ($1, $2, $3, $4, $5) RETURNING id`, id, author, fromTeam, body, now).Scan(&m.ID); err != nil {
		return nil, err
	}
	_, err := q.Exec(ctx, `UPDATE feedback SET last_message_at = $2, updated_at = $2,
		user_unread = user_unread + CASE WHEN $3 THEN 1 ELSE 0 END,
		team_unread = team_unread + CASE WHEN $3 THEN 0 ELSE 1 END WHERE id = $1`, id, now, fromTeam)
	return m, err
}

// ---- images ----------------------------------------------------------------------------

func (s *Service) handleImage(admin bool) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		ctx := r.Context()
		fid, err1 := uuid.Parse(chi.URLParam(r, "id"))
		iid, err2 := uuid.Parse(chi.URLParam(r, "imageId"))
		if err1 != nil || err2 != nil {
			httpx.WriteError(w, r, ErrImageGone)
			return
		}
		var owner *uuid.UUID
		if !admin {
			me := auth.MustUser(ctx).UserID
			owner = &me
		}
		var full, thumb string
		err := s.d.Q(ctx).QueryRow(ctx, `SELECT i.full_key, i.thumb_key FROM feedback_images i JOIN feedback f ON f.id = i.feedback_id
			WHERE i.id = $1 AND f.id = $2 AND ($3::uuid IS NULL OR f.user_id = $3)`, iid, fid, owner).Scan(&full, &thumb)
		if err != nil {
			httpx.WriteError(w, r, ErrImageGone)
			return
		}
		key := full
		if r.URL.Query().Get("size") == "thumb" {
			key = thumb
		}
		f, err := s.media.Open(key)
		if err != nil {
			httpx.WriteError(w, r, ErrImageGone)
			return
		}
		defer f.Close()
		w.Header().Set("Content-Type", "image/jpeg")
		w.Header().Set("Cache-Control", "private, max-age=86400")
		http.ServeContent(w, r, "", time.Time{}, f)
	}
}

// ---- admin ------------------------------------------------------------------------------

type userRef struct {
	ID         uuid.UUID  `json:"id"`
	Name       string     `json:"name"`
	Email      string     `json:"email"`
	University *authorRef `json:"university"`
}

// AdminItem is feedback as the panel sees it.
type AdminItem struct {
	Feedback
	User       *userRef `json:"user"`
	TeamUnread int      `json:"teamUnread"`
	Device     string   `json:"device"`
	OS         string   `json:"os"`
	AppVersion string   `json:"appVersion"`
	Build      int      `json:"build"`
	Platform   string   `json:"platform"`
	Locale     string   `json:"locale"`
}

type AdminDetail struct {
	AdminItem
	Messages []adminMessage `json:"messages"`
}

func (s *Service) adminItem(ctx context.Context, x row) (AdminItem, error) {
	it := AdminItem{Feedback: x.Feedback, TeamUnread: x.teamUnread, Device: x.device, OS: x.os,
		AppVersion: x.appVersion, Build: x.build, Platform: x.platform, Locale: x.locale}
	if x.userID != nil {
		u := &userRef{ID: *x.userID}
		var uid *uuid.UUID
		var uname *string
		err := s.d.Q(ctx).QueryRow(ctx, `SELECT coalesce(u.display_name, ''), u.email, un.id, un.name
			FROM users u LEFT JOIN universities un ON un.id = u.university_id WHERE u.id = $1`, *x.userID).
			Scan(&u.Name, &u.Email, &uid, &uname)
		if err != nil && !db.IsNoRows(err) {
			return it, err
		}
		if uid != nil && uname != nil {
			u.University = &authorRef{ID: *uid, Name: *uname}
		}
		it.User = u
	}
	return it, nil
}

type adminListReq struct {
	Page     string `json:"-" query:"page" validate:"omitempty,number,min=1,max=6"`
	PageSize string `json:"-" query:"pageSize" validate:"omitempty,number"`
	Status   string `json:"-" query:"status" validate:"omitempty,oneof=open closed all new seen planned in_progress done wont_do"`
	Kind     string `json:"-" query:"kind" validate:"omitempty,oneof=bug idea other"`
	Q        string `json:"-" query:"q" validate:"max=100"`
}

type adminPage struct {
	Items    []AdminItem `json:"items"`
	Total    int         `json:"total"`
	Page     int         `json:"page"`
	PageSize int         `json:"pageSize"`
}

func atoi(s string) int {
	n := 0
	for _, c := range s {
		n = n*10 + int(c-'0')
	}
	return n
}

func (s *Service) handleAdminList(ctx context.Context, in *adminListReq) (*adminPage, error) {
	page, size := max(atoi(in.Page), 1), atoi(in.PageSize)
	if size < 1 {
		size = 25
	}
	size = min(size, 100)
	status := in.Status
	if status == "" {
		status = "all"
	}
	search := strings.TrimSpace(in.Q)
	pat := "%" + strings.NewReplacer(`\`, `\\`, `%`, `\%`, `_`, `\_`).Replace(search) + "%"
	where := `($1 = 'all' OR ($1 = 'open' AND f.status IN ('new','seen','planned','in_progress'))
		OR ($1 = 'closed' AND f.status IN ('done','wont_do')) OR f.status = $1)
		AND ($2 = '' OR f.kind = $2)
		AND ($3 = '' OR f.message ILIKE $4 OR EXISTS (SELECT 1 FROM users u WHERE u.id = f.user_id AND u.email ILIKE $4))`
	q := s.d.Q(ctx)
	out := &adminPage{Items: []AdminItem{}, Page: page, PageSize: size}
	if err := q.QueryRow(ctx, `SELECT count(*)::int FROM feedback f WHERE `+where, status, in.Kind, search, pat).Scan(&out.Total); err != nil {
		return nil, err
	}
	rs, err := q.Query(ctx, `SELECT `+cols+` FROM feedback f WHERE `+where+` ORDER BY f.last_message_at DESC, f.id LIMIT $5 OFFSET $6`,
		status, in.Kind, search, pat, size, (page-1)*size)
	if err != nil {
		return nil, err
	}
	var rows []row
	for rs.Next() {
		x, err := scanRow(rs)
		if err != nil {
			rs.Close()
			return nil, err
		}
		rows = append(rows, x)
	}
	rs.Close()
	if err := rs.Err(); err != nil {
		return nil, err
	}
	if err := s.fillImages(ctx, rows); err != nil {
		return nil, err
	}
	for _, x := range rows {
		it, err := s.adminItem(ctx, x)
		if err != nil {
			return nil, err
		}
		out.Items = append(out.Items, it)
	}
	return out, nil
}

// handleAdminGet opens the conversation: the team's unread count clears and
// a new item becomes seen.
func (s *Service) handleAdminGet(ctx context.Context, in *idReq) (*AdminDetail, error) {
	id := uuid.MustParse(in.ID)
	var x row
	err := s.d.InTx(ctx, func(ctx context.Context) error {
		var err error
		if x, err = s.one(ctx, id, nil, true); err != nil {
			return err
		}
		if x.teamUnread > 0 || x.Status == "new" {
			if _, err := s.d.Q(ctx).Exec(ctx, `UPDATE feedback SET team_unread = 0,
				status = CASE WHEN status = 'new' THEN 'seen' ELSE status END WHERE id = $1`, id); err != nil {
				return err
			}
			x.teamUnread = 0
			if x.Status == "new" {
				x.Status = "seen"
			}
		}
		return nil
	})
	if err != nil {
		return nil, err
	}
	it, err := s.adminItem(ctx, x)
	if err != nil {
		return nil, err
	}
	ms, err := s.messages(ctx, id)
	if err != nil {
		return nil, err
	}
	return &AdminDetail{AdminItem: it, Messages: ms}, nil
}

func (s *Service) audit(ctx context.Context, action string, id uuid.UUID, meta any) error {
	b, err := json.Marshal(meta)
	if err != nil {
		b = []byte("{}")
	}
	_, err = s.d.Q(ctx).Exec(ctx, `INSERT INTO audit_log (actor_id, action, target_type, target_id, meta) VALUES ($1, $2, 'feedback', $3, $4)`,
		auth.MustUser(ctx).UserID, action, id.String(), b)
	return err
}

// tell pushes the student once the transaction commits.
func (s *Service) tell(ctx context.Context, user *uuid.UUID, id uuid.UUID, en, bn string) {
	if user == nil {
		return
	}
	u := *user
	db.AfterCommit(ctx, func(context.Context) {
		if s.notify == nil {
			return
		}
		s.notify([]uuid.UUID{u}, Notice{
			Texts: map[string]NoticeText{
				"en": {Title: "VarsityKotha team replied", Body: en},
				"bn": {Title: "ভার্সিটি কথা টিম উত্তর দিয়েছে", Body: bn},
			},
			Data: map[string]string{"type": "feedback_reply", "feedbackId": id.String()},
		})
	})
}

func first120(s string) string {
	if utf8.RuneCountInString(s) <= 120 {
		return s
	}
	return string([]rune(s)[:120])
}

func (s *Service) handleAdminReply(ctx context.Context, in *bodyReq) (*adminMessage, error) {
	body, err := cleanBody(in.Body)
	if err != nil {
		return nil, err
	}
	me := auth.MustUser(ctx).UserID
	id := uuid.MustParse(in.ID)
	var out *adminMessage
	err = s.d.InTx(ctx, func(ctx context.Context) error {
		x, err := s.one(ctx, id, nil, true)
		if err != nil {
			return err
		}
		m, err := s.addMessage(ctx, id, &me, true, body)
		if err != nil {
			return err
		}
		if _, err := s.d.Q(ctx).Exec(ctx, `UPDATE feedback SET team_unread = 0, status = CASE WHEN status = 'new' THEN 'seen' ELSE status END WHERE id = $1`, id); err != nil {
			return err
		}
		var name string
		_ = s.d.Q(ctx).QueryRow(ctx, `SELECT coalesce(display_name, '') FROM users WHERE id = $1`, me).Scan(&name)
		out = &adminMessage{Message: *m, Author: &authorRef{ID: me, Name: name}}
		if err := s.audit(ctx, "feedback.reply", id, map[string]any{"length": utf8.RuneCountInString(body)}); err != nil {
			return err
		}
		preview := first120(body)
		s.tell(ctx, x.userID, id, preview, preview)
		return nil
	})
	return out, err
}

var statusWords = map[string][2]string{
	"new":         {"New", "নতুন"},
	"seen":        {"Seen", "দেখা হয়েছে"},
	"planned":     {"Planned", "পরিকল্পনায় আছে"},
	"in_progress": {"In progress", "কাজ চলছে"},
	"done":        {"Done", "সম্পন্ন"},
	"wont_do":     {"Won't do", "করা হবে না"},
}

type statusReq struct {
	ID     string `json:"-" path:"id" validate:"required,uuid"`
	Status string `json:"status" validate:"required,oneof=new seen planned in_progress done wont_do"`
}

func (s *Service) handleAdminStatus(ctx context.Context, in *statusReq) (*AdminItem, error) {
	id := uuid.MustParse(in.ID)
	var out AdminItem
	err := s.d.InTx(ctx, func(ctx context.Context) error {
		x, err := s.one(ctx, id, nil, true)
		if err != nil {
			return err
		}
		if x.Status != in.Status {
			if _, err := s.d.Q(ctx).Exec(ctx, `UPDATE feedback SET status = $2, updated_at = $3 WHERE id = $1`, id, in.Status, s.now()); err != nil {
				return err
			}
			if err := s.audit(ctx, "feedback.status", id, map[string]any{"from": x.Status, "to": in.Status}); err != nil {
				return err
			}
			w := statusWords[in.Status]
			s.tell(ctx, x.userID, id, "Status: "+w[0], "অবস্থা: "+w[1])
			x.Status = in.Status
		}
		out, err = s.adminItem(ctx, x)
		return err
	})
	if err != nil {
		return nil, err
	}
	return &out, nil
}
