package classgroups

import (
	"context"
	"fmt"
	"strings"
	"time"
	"unicode/utf8"

	"github.com/google/uuid"

	"github.com/zamansheikh/campussaga/backend/internal/modules/classgroups/store"
	"github.com/zamansheikh/campussaga/backend/internal/platform/db"
)

// NoticeText is a notification in one language.
type NoticeText struct{ Title, Body string }

// Notice tells classmates about a change; Texts are keyed by language.
type Notice struct {
	Texts map[string]NoticeText
	Data  map[string]string
}

// Notifier sends a Notice to students' phones (wired to the push module).
type Notifier func(userIDs []uuid.UUID, n Notice)

// SetNotifier turns on notifications to classmates.
func (s *Service) SetNotifier(n Notifier) { s.notify = n }

// tellClassmates sends n to every member but the actor, after commit.
func (s *Service) tellClassmates(ctx context.Context, q *store.Queries, groupID, actor uuid.UUID, n Notice) error {
	if s.notify == nil {
		return nil
	}
	ids, err := q.ListMemberIDs(ctx, groupID)
	if err != nil {
		return err
	}
	others := make([]uuid.UUID, 0, len(ids))
	for _, id := range ids {
		if id != actor {
			others = append(others, id)
		}
	}
	if len(others) > 0 {
		db.AfterCommit(ctx, func(context.Context) { s.notify(others, n) })
	}
	return nil
}

func groupTitle(g store.ClassGroup) string {
	t := g.Department + " " + g.Batch
	if g.Section != "" {
		t += " · " + g.Section
	}
	return t
}

// changeNotice describes a new change (undo = the change was removed).
func (s *Service) changeNotice(g store.ClassGroup, ch store.RoutineChange, slot *store.RoutineSlot, undo bool) Notice {
	course, room := ch.CourseCode, ch.Room
	if slot != nil {
		course = slot.CourseCode
		if room == "" {
			room = slot.Room
		}
	}
	gt := groupTitle(g)
	texts := map[string]NoticeText{}
	for _, lang := range []string{"en", "bn"} {
		when := s.whenText(lang, ch.Date)
		var time string
		if ch.StartsMin != nil && ch.EndsMin != nil {
			time = clockText(lang, *ch.StartsMin) + " – " + clockText(lang, *ch.EndsMin)
		}
		roomText := ""
		if room != "" {
			roomText = map[string]string{"en": "Room ", "bn": "রুম "}[lang] + room
		}
		body := join(" · ", time, roomText, ch.Note)
		var title string
		switch {
		case undo && ch.Kind == ChangeCancelled:
			title = pick(lang, fmt.Sprintf("%s %s is on again", course, when), fmt.Sprintf("%s %s আবার হবে", when, course))
			body = gt
		case undo && ch.Kind == ChangeMoved:
			title = pick(lang, fmt.Sprintf("%s %s: back to the usual time and room", course, when), fmt.Sprintf("%s %s আগের সময় ও রুমে হবে", when, course))
			body = gt
		case undo:
			title = pick(lang, fmt.Sprintf("Extra class %s removed: %s", when, course), fmt.Sprintf("%s অতিরিক্ত ক্লাস বাতিল: %s", when, course))
			body = gt
		case ch.Kind == ChangeCancelled:
			title = pick(lang, fmt.Sprintf("%s cancelled %s", course, when), fmt.Sprintf("%s %s বাতিল", when, course))
			body = join(" · ", ch.Note, gt)
		case ch.Kind == ChangeMoved:
			title = pick(lang, fmt.Sprintf("%s changed %s", course, when), fmt.Sprintf("%s %s পরিবর্তিত", when, course))
		default:
			title = pick(lang, fmt.Sprintf("Extra class %s: %s", when, course), fmt.Sprintf("%s অতিরিক্ত ক্লাস: %s", when, course))
		}
		texts[lang] = NoticeText{Title: title, Body: body}
	}
	return Notice{Texts: texts, Data: map[string]string{"type": "change", "groupId": g.ID.String()}}
}

func announcementNotice(g store.ClassGroup, body string) Notice {
	gt := groupTitle(g)
	short := body
	if utf8.RuneCountInString(short) > 180 {
		short = string([]rune(short)[:179]) + "…"
	}
	return Notice{
		Texts: map[string]NoticeText{
			"en": {Title: gt + ": New announcement", Body: short},
			"bn": {Title: gt + ": নতুন ঘোষণা", Body: short},
		},
		Data: map[string]string{"type": "announcement", "groupId": g.ID.String()},
	}
}

// whenText: "today", "tomorrow" or "Wed 28 Oct" (Bangla: "আজ", "আগামীকাল",
// "বুধ, ২৮ অক্টোবর").
func (s *Service) whenText(lang string, d time.Time) string {
	today := s.today()
	switch {
	case d.Equal(today):
		return pick(lang, "today", "আজ")
	case d.Equal(today.AddDate(0, 0, 1)):
		return pick(lang, "tomorrow", "আগামীকাল")
	case lang == "bn":
		days := []string{"রবি", "সোম", "মঙ্গল", "বুধ", "বৃহস্পতি", "শুক্র", "শনি"}
		months := []string{"জানুয়ারি", "ফেব্রুয়ারি", "মার্চ", "এপ্রিল", "মে", "জুন", "জুলাই", "আগস্ট", "সেপ্টেম্বর", "অক্টোবর", "নভেম্বর", "ডিসেম্বর"}
		return fmt.Sprintf("%s, %s %s", days[d.Weekday()], bnDigits(fmt.Sprint(d.Day())), months[d.Month()-1])
	default:
		return "on " + d.Format("Mon 2 Jan")
	}
}

// clockText: "10:30 AM" (Bangla digits in Bangla).
func clockText(lang string, min int16) string {
	h, m := int(min)/60%24, int(min)%60
	ampm := "AM"
	if h >= 12 {
		ampm = "PM"
	}
	h12 := h % 12
	if h12 == 0 {
		h12 = 12
	}
	t := fmt.Sprintf("%d:%02d %s", h12, m, ampm)
	if lang == "bn" {
		return bnDigits(t)
	}
	return t
}

func bnDigits(s string) string {
	return strings.Map(func(r rune) rune {
		if r >= '0' && r <= '9' {
			return '০' + (r - '0')
		}
		return r
	}, s)
}

func pick(lang, en, bn string) string {
	if lang == "bn" {
		return bn
	}
	return en
}

func join(sep string, parts ...string) string {
	out := parts[:0:0]
	for _, p := range parts {
		if p != "" {
			out = append(out, p)
		}
	}
	return strings.Join(out, sep)
}
