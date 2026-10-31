package blood

import (
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
)

// NoticeText is a push in one language.
type NoticeText struct{ Title, Body string }

// Notice is a push; Texts are keyed by language ("en", "bn").
type Notice struct {
	Texts map[string]NoticeText
	Data  map[string]string
}

// Notifier sends a Notice to students' phones (wired to the push module).
type Notifier func(userIDs []uuid.UUID, n Notice)

// SetNotifier turns pushes on.
func (s *Service) SetNotifier(n Notifier) { s.notify = n }

// requestNotice is the push to donors of a request's group.
func requestNotice(group, hospital, area string, urgent bool, neededBy, now time.Time, id uuid.UUID) Notice {
	texts := map[string]NoticeText{}
	for _, lang := range []string{"en", "bn"} {
		title := group + " blood needed"
		if lang == "bn" {
			title = group + " রক্ত প্রয়োজন"
		}
		if urgent {
			title += pick(lang, ", urgent", ", জরুরি")
		}
		place := hospital
		if area != "" {
			place += ", " + area
		}
		texts[lang] = NoticeText{Title: title, Body: place + " · " + whenText(lang, neededBy, now)}
	}
	return Notice{Texts: texts, Data: map[string]string{"type": "blood_request", "requestId": id.String()}}
}

// responseNotice tells the requester that name can donate.
func responseNotice(name, group string, id uuid.UUID) Notice {
	return Notice{
		Texts: map[string]NoticeText{
			"en": {Title: fmt.Sprintf("%s can donate %s", name, group), Body: "Tap to call"},
			"bn": {Title: name + " রক্ত দিতে পারবেন", Body: "কল করতে চাপো"},
		},
		Data: map[string]string{"type": "blood_response", "requestId": id.String()},
	}
}

// whenText formats the needed-by time in Bangladesh time: "today 3:00 PM",
// "tomorrow 10:00 AM" or "Nov 4, 10:00 AM" (Bangla digits and month names in
// Bangla).
func whenText(lang string, t, now time.Time) string {
	t, now = t.In(dhaka), now.In(dhaka)
	clock := clockText(lang, t)
	day := time.Date(t.Year(), t.Month(), t.Day(), 0, 0, 0, 0, time.UTC)
	today := time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, time.UTC)
	switch {
	case day.Equal(today):
		return pick(lang, "today ", "আজ ") + clock
	case day.Equal(today.AddDate(0, 0, 1)):
		return pick(lang, "tomorrow ", "আগামীকাল ") + clock
	case lang == "bn":
		months := []string{"জানুয়ারি", "ফেব্রুয়ারি", "মার্চ", "এপ্রিল", "মে", "জুন", "জুলাই", "আগস্ট", "সেপ্টেম্বর", "অক্টোবর", "নভেম্বর", "ডিসেম্বর"}
		return fmt.Sprintf("%s %s, %s", bnDigits(fmt.Sprint(t.Day())), months[t.Month()-1], clock)
	default:
		return t.Format("Jan 2, ") + clock
	}
}

// clockText: "3:00 PM" (Bangla digits in Bangla).
func clockText(lang string, t time.Time) string {
	h, m := t.Hour(), t.Minute()
	ampm := "AM"
	if h >= 12 {
		ampm = "PM"
	}
	h12 := h % 12
	if h12 == 0 {
		h12 = 12
	}
	s := fmt.Sprintf("%d:%02d %s", h12, m, ampm)
	if lang == "bn" {
		return bnDigits(s)
	}
	return s
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
