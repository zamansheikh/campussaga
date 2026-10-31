package transport

import (
	"fmt"
	"strings"

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

// busNearNotice tells a student the bus is about mins minutes from their stop.
func busNearNotice(route, stop string, mins, riders int, routeID, stopID uuid.UUID) Notice {
	return Notice{
		Texts: map[string]NoticeText{
			"en": {
				Title: "Bus coming: " + route,
				Body:  fmt.Sprintf("About %d min from %s · %d sharing live", mins, stop, riders),
			},
			"bn": {
				Title: "বাস আসছে: " + route,
				Body:  fmt.Sprintf("%s থেকে প্রায় %s মিনিট দূরে · %s জন লাইভ শেয়ার করছে", stop, bnDigits(fmt.Sprint(mins)), bnDigits(fmt.Sprint(riders))),
			},
		},
		Data: map[string]string{"type": "bus_near", "routeId": routeID.String(), "stopId": stopID.String()},
	}
}

func bnDigits(s string) string {
	return strings.Map(func(r rune) rune {
		if r >= '0' && r <= '9' {
			return '০' + (r - '0')
		}
		return r
	}, s)
}
