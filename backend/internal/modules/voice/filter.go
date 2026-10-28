package voice

import (
	_ "embed"
	"net/url"
	"regexp"
	"strings"
)

// Hold reasons (shown to the author and to moderators).
const (
	HoldPersonalInfo = "personal_info"
	HoldLanguage     = "language"
	HoldUnverified   = "unverified"
	HoldReports      = "reports"   // auto-hidden after reports
	HoldModerator    = "moderator" // hidden by a moderator
)

//go:embed filter_words.txt
var wordList string

var (
	lang = loadWords(wordList)

	// Bangladeshi mobile numbers, with or without +88, spaces or dashes.
	phoneRe = regexp.MustCompile(`(?:\+?88[\s-]?)?0[\s-]?1[3-9](?:[\s-]?\d){8}`)
	emailRe = regexp.MustCompile(`(?i)[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}`)
	urlRe   = regexp.MustCompile(`(?i)\b(?:https?://|www\.)[^\s]+|\b[a-z0-9-]+(?:\.[a-z0-9-]+)*\.(?:com|net|org|io|me|info|xyz|link|ly|co|app)\b[^\s]*`)
	// Roll / ID numbers: 8 or more digits, possibly split by dashes or spaces.
	idRe = regexp.MustCompile(`\d(?:[\s-]?\d){7,}`)
)

// allowedHost: links to universities and the government are fine.
func allowedHost(link string) bool {
	if !strings.Contains(link, "://") {
		link = "https://" + link
	}
	u, err := url.Parse(link)
	if err != nil {
		return false
	}
	h := strings.ToLower(u.Hostname())
	for _, suffix := range []string{".edu.bd", ".ac.bd", ".gov.bd", ".edu"} {
		if strings.HasSuffix(h, suffix) {
			return true
		}
	}
	return false
}

// latinDigits turns Bangla digits into 0–9 so the number rules see them.
func latinDigits(s string) string {
	return strings.Map(func(r rune) rune {
		if r >= '০' && r <= '৯' {
			return '0' + (r - '০')
		}
		return r
	}, s)
}

// checkText returns a hold reason, or "" when the text may go public.
func checkText(parts ...string) string {
	text := latinDigits(strings.Join(parts, "\n"))
	if phoneRe.MatchString(text) || emailRe.MatchString(text) || idRe.MatchString(text) {
		return HoldPersonalInfo
	}
	for _, link := range urlRe.FindAllString(text, -1) {
		if !allowedHost(link) {
			return HoldPersonalInfo
		}
	}
	if lang.matches(text) {
		return HoldLanguage
	}
	return ""
}
