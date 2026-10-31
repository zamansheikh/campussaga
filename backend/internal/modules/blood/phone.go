package blood

import (
	"regexp"
	"strings"
)

const phoneProblem = "must be a mobile number like 01712345678"

// A Bangladeshi mobile number: 01[3-9] and 8 more digits, optional +88/88.
var phoneRe = regexp.MustCompile(`^(?:\+?88)?(01[3-9][0-9]{8})$`)

// cleanPhone follows the transport module's rule (Bangla digits to ASCII;
// spaces, dashes, dots and brackets dropped) and keeps only Bangladeshi
// mobile numbers, stored as 01XXXXXXXXX.
func cleanPhone(s string) (string, bool) {
	var b strings.Builder
	for _, r := range strings.TrimSpace(s) {
		switch {
		case r >= '০' && r <= '৯':
			b.WriteRune('0' + (r - '০'))
		case r == ' ' || r == '-' || r == '.' || r == '(' || r == ')':
		default:
			b.WriteRune(r)
		}
	}
	m := phoneRe.FindStringSubmatch(b.String())
	if m == nil {
		return "", false
	}
	return m[1], true
}
