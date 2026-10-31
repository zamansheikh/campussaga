// Package growth is invites, badges, student profiles and prize campaigns
// (docs/GROWTH.md): every student has an invite link, an invite counts only
// when the friend is verified and active on 3 days, badges show roles and
// activity, other students can open a profile, and the team runs prize
// campaigns for the top inviters (by rank, never a draw).
//
// Anonymity: badges earned from anonymous activity (helper, campus_voice)
// are private, computed here as aggregate counts only and read only by their
// owner; nothing here links a person to an anonymous item.
//
// Queries are plain SQL because most of them join tables of several modules.
package growth

import (
	"context"
	"fmt"
	"log/slog"
	"net/http"
	"strings"
	"sync"
	"time"

	"github.com/google/uuid"

	"github.com/zamansheikh/varsitykotha/backend/internal/platform/apperr"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/db"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/httpx"
	"github.com/zamansheikh/varsitykotha/backend/internal/platform/media"
)

// Rules of docs/GROWTH.md.
const (
	ClaimWithinDays = 7  // a referral can be claimed within this many days of signing up
	WindowDays      = 14 // a friend must qualify within this many days of joining
	ActiveDaysNeed  = 3  // distinct active days needed
	KeepActiveDays  = 30
	KeepClaimsDays  = 90 // claims are deleted this long after delivery
	LinkBase        = "https://varsitykotha.com/r/"
	RulesBase       = "https://varsitykotha.com/campaigns/"
)

var (
	ErrReferralTooLate    = apperr.New(http.StatusUnprocessableEntity, "REFERRAL_TOO_LATE", "An invite can only be added in your first week")
	ErrAlreadyReferred    = apperr.New(http.StatusConflict, "ALREADY_REFERRED", "You already used an invite")
	ErrReferralSelf       = apperr.New(http.StatusUnprocessableEntity, "REFERRAL_SELF", "This is your own invite code")
	ErrReferralNotFound   = apperr.New(http.StatusNotFound, "REFERRAL_NOT_FOUND", "This invite was not found")
	ErrBadgeNotHeld       = apperr.New(http.StatusUnprocessableEntity, "BADGE_NOT_HELD", "You don't have this badge")
	ErrBadgePrivate       = apperr.New(http.StatusUnprocessableEntity, "BADGE_PRIVATE", "This badge is only visible to you, so it can't be shown by your name")
	ErrUserNotFound       = apperr.New(http.StatusNotFound, "USER_NOT_FOUND", "This student was not found")
	ErrCampaignNotFound   = apperr.New(http.StatusNotFound, "CAMPAIGN_NOT_FOUND", "This campaign was not found")
	ErrNotAWinner         = apperr.New(http.StatusForbidden, "NOT_A_WINNER", "You are not a winner of this campaign")
	ErrAlreadyClaimed     = apperr.New(http.StatusConflict, "ALREADY_CLAIMED", "You already sent your details")
	ErrCampaignLocked     = apperr.New(http.StatusConflict, "CAMPAIGN_LOCKED", "This campaign can't be changed this way any more")
	ErrCampaignIncomplete = apperr.New(http.StatusUnprocessableEntity, "CAMPAIGN_INCOMPLETE", "A campaign needs a title, rules and prizes before it goes live")
	ErrCampaignDates      = apperr.New(http.StatusUnprocessableEntity, "CAMPAIGN_DATES", "The dates don't fit: start < end <= settle")
	ErrCampaignPrizes     = apperr.New(http.StatusUnprocessableEntity, "CAMPAIGN_PRIZES", "The prize ranks are not valid")
	ErrNotSettled         = apperr.New(http.StatusConflict, "CAMPAIGN_NOT_SETTLED", "Winners can be announced after the campaign settles")
	ErrNotAnnounceable    = apperr.New(http.StatusConflict, "CAMPAIGN_NOT_ANNOUNCEABLE", "Only a live campaign can be announced, once")
	ErrWinners            = apperr.New(http.StatusUnprocessableEntity, "CAMPAIGN_WINNERS", "The winners are not valid")
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

// Ports are what other modules provide (wired in app.go).
type Ports struct {
	// Posts: a student's named Campus posts as the caller may see them.
	Posts func(ctx context.Context, author uuid.UUID) (any, error)
}

type Service struct {
	d      *db.DB
	now    func() time.Time
	log    *slog.Logger
	notify Notifier
	ports  Ports
	media  media.Store // banner photos; nil until SetMedia

	mu      sync.Mutex
	seenDay string
	seen    map[uuid.UUID]struct{}

	// Badges recomputed when someone else opens a profile, at most once
	// per profileRecomputeEvery per student.
	recomputed map[uuid.UUID]time.Time
}

const profileRecomputeEvery = 10 * time.Minute

func NewService(d *db.DB, now func() time.Time, ports Ports, log *slog.Logger) *Service {
	if log == nil {
		log = slog.Default()
	}
	return &Service{d: d, now: now, log: log, ports: ports, seen: map[uuid.UUID]struct{}{}, recomputed: map[uuid.UUID]time.Time{}}
}

// SetNotifier turns pushes on.
func (s *Service) SetNotifier(n Notifier) { s.notify = n }

func (s *Service) Routes(r *httpx.Router) {
	st := r.Student()
	st.Get("/me/referrals", httpx.Handle(s.handleMyReferrals))
	st.With(r.LimitUser("referral-claim", 20, time.Hour)).Post("/me/referral", httpx.Handle(s.handleClaim, httpx.NoContent()))
	r.Public().With(r.Limit("referral-lookup", 60, time.Minute)).Get("/referral/{code}", httpx.Handle(s.handleLookup))
	st.Get("/me/badges", httpx.Handle(s.handleMyBadges))
	st.Put("/me/featured-badge", httpx.Handle(s.handleFeature))
	st.Get("/users/{id}/profile", httpx.Handle(s.handleProfile))

	loc := st.With(withLang)
	loc.Get("/campaigns", httpx.Handle(s.handleCampaigns))
	loc.Get("/campaigns/{id}", httpx.Handle(s.handleCampaign))
	loc.Get("/campaigns/{id}/leaderboard", httpx.Handle(s.handleLeaderboard))
	st.Post("/campaigns/{id}/claim", httpx.Handle(s.handlePrizeClaim, httpx.NoContent()))
	r.Public().With(r.Limit("campaign-public", 120, time.Minute)).Get("/campaigns/{id}/public", httpx.Handle(s.handlePublicCampaign))
	r.Public().With(r.Limit("campaign-banner", 240, time.Minute)).Get("/campaigns/{id}/banner", s.handleBanner)

	a := r.Admin()
	a.Get("/admin/campaigns", httpx.Handle(s.handleAdminCampaigns))
	a.Post("/admin/campaigns", httpx.Handle(s.handleAdminCreate, httpx.Status(http.StatusCreated)))
	a.Get("/admin/campaigns/{id}", httpx.Handle(s.handleAdminCampaign))
	a.Patch("/admin/campaigns/{id}", httpx.Handle(s.handleAdminPatch))
	a.Post("/admin/campaigns/{id}/banner", s.handleAdminBanner)
	a.Delete("/admin/campaigns/{id}/banner", httpx.Handle(s.handleAdminBannerDelete))
	a.Get("/admin/campaigns/{id}/standings", httpx.Handle(s.handleAdminStandings))
	a.Post("/admin/campaigns/{id}/participants/{userId}/disqualify", httpx.Handle(s.handleAdminDisqualifyUser, httpx.NoContent()))
	a.Delete("/admin/campaigns/{id}/participants/{userId}/disqualify", httpx.Handle(s.handleAdminRestoreUser, httpx.NoContent()))
	a.Post("/admin/campaigns/{id}/announce", httpx.Handle(s.handleAdminAnnounce))
	a.Get("/admin/campaigns/{id}/winners", httpx.Handle(s.handleAdminWinners))
	a.Post("/admin/campaigns/{id}/winners/{userId}/delivered", httpx.Handle(s.handleAdminDelivered, httpx.NoContent()))
	a.Post("/admin/referrals/{referredId}/disqualify", httpx.Handle(s.handleAdminDisqualifyReferral, httpx.NoContent()))
	a.Post("/admin/referrals/{referredId}/restore", httpx.Handle(s.handleAdminRestoreReferral, httpx.NoContent()))
	a.Get("/admin/referrals", httpx.Handle(s.handleAdminReferrals))
	a.Get("/admin/users/{id}/growth", httpx.Handle(s.handleAdminUserGrowth))
}

// ---- language -----------------------------------------------------------------------

type langKey struct{}

// withLang reads the student's language for campaign text: the `lang` query
// parameter, else the Accept-Language header, else English.
func withLang(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		next.ServeHTTP(w, r.WithContext(context.WithValue(r.Context(), langKey{}, langOf(r))))
	})
}

func langOf(r *http.Request) string {
	if l := strings.ToLower(strings.TrimSpace(r.URL.Query().Get("lang"))); l == "bn" || l == "en" {
		return l
	}
	for _, part := range strings.Split(r.Header.Get("Accept-Language"), ",") {
		tag := strings.ToLower(strings.TrimSpace(strings.SplitN(part, ";", 2)[0]))
		switch {
		case tag == "bn" || strings.HasPrefix(tag, "bn-"):
			return "bn"
		case tag == "en" || strings.HasPrefix(tag, "en-"):
			return "en"
		}
	}
	return "en"
}

func lang(ctx context.Context) string {
	if l, ok := ctx.Value(langKey{}).(string); ok {
		return l
	}
	return "en"
}

// pick returns bn when the language is Bangla and bn is not empty.
func pick(l, en, bn string) string {
	if l == "bn" && bn != "" {
		return bn
	}
	return en
}

// ---- time ---------------------------------------------------------------------------

var dhaka = mustZone("Asia/Dhaka")

func mustZone(name string) *time.Location {
	l, err := time.LoadLocation(name)
	if err != nil {
		return time.FixedZone(name, 6*3600)
	}
	return l
}

// dhakaDay is the calendar day (Asia/Dhaka) of t as YYYY-MM-DD.
func dhakaDay(t time.Time) string { return t.In(dhaka).Format(time.DateOnly) }

func bnDigits(s string) string {
	return strings.Map(func(r rune) rune {
		if r >= '0' && r <= '9' {
			return '০' + (r - '0')
		}
		return r
	}, s)
}

func itoa(n int) string { return fmt.Sprint(n) }

// ---- active days --------------------------------------------------------------------

// Active records that the student used the app today (Asia/Dhaka). It is
// called on every signed-in request, so an in-memory set keeps it to one
// write per student and day per process. A friend's invite is re-checked when
// a new active day is written.
func (s *Service) Active(ctx context.Context, id uuid.UUID) {
	day := dhakaDay(s.now())
	s.mu.Lock()
	if s.seenDay != day {
		s.seenDay, s.seen = day, map[uuid.UUID]struct{}{}
	}
	if _, ok := s.seen[id]; ok {
		s.mu.Unlock()
		return
	}
	s.seen[id] = struct{}{}
	s.mu.Unlock()

	forget := func() {
		s.mu.Lock()
		if s.seenDay == day {
			delete(s.seen, id)
		}
		s.mu.Unlock()
	}
	if _, err := s.d.Q(ctx).Exec(ctx, `INSERT INTO user_active_days (user_id, day) VALUES ($1, $2) ON CONFLICT DO NOTHING`, id, day); err != nil {
		forget()
		s.log.Warn("growth: active day", "err", err)
		return
	}
	if err := s.Qualify(ctx, id); err != nil {
		s.log.Warn("growth: qualify", "err", err)
	}
}
