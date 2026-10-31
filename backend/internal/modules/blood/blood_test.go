package blood

import (
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
)

func TestCleanPhone(t *testing.T) {
	for in, want := range map[string]string{
		"01712345678":     "01712345678",
		" 017-1234 5678 ": "01712345678",
		"+8801712345678":  "01712345678",
		"8801712345678":   "01712345678",
		"০১৭১২৩৪৫৬৭৮":     "01712345678",
		"(+৮৮) ০১৯১১.২২৩৩৪৪": "01911223344",
	} {
		got, ok := cleanPhone(in)
		assert.True(t, ok, in)
		assert.Equal(t, want, got, in)
	}
	for _, in := range []string{"", "0171234567", "017123456789", "01212345678", "029876543", "+8801212345678", "abc", "0171234567a"} {
		_, ok := cleanPhone(in)
		assert.False(t, ok, in)
	}
}

func TestCompatibleTable(t *testing.T) {
	assert.Equal(t, []string{"O-"}, CompatibleDonors("O-"))
	assert.Equal(t, []string{"A+", "A-", "O+", "O-"}, CompatibleDonors("A+"))
	assert.Equal(t, []string{"AB-", "A-", "B-", "O-"}, CompatibleDonors("AB-"))
	assert.Len(t, CompatibleDonors("AB+"), 8)
	assert.Len(t, compatible, len(Groups))
	for _, g := range Groups {
		assert.Contains(t, CompatibleDonors(g), g, "everyone can receive their own group")
		assert.Contains(t, CompatibleDonors(g), "O-", "O- is the universal donor")
	}
}

func TestEligible(t *testing.T) {
	today := time.Date(2026, 10, 27, 0, 0, 0, 0, time.UTC)
	day := func(s string) *time.Time {
		d, _ := time.Parse(dateLayout, s)
		return &d
	}
	assert.True(t, eligible(true, nil, today))
	assert.False(t, eligible(false, nil, today))
	assert.True(t, eligible(true, day("2026-06-29"), today), "exactly 120 days")
	assert.False(t, eligible(true, day("2026-06-30"), today), "119 days")
	assert.False(t, eligible(false, day("2025-01-01"), today))
	assert.Equal(t, "2026-10-29", canDonateFrom(*day("2026-07-01")).Format(dateLayout))
}

func TestWhenText(t *testing.T) {
	bdt := time.FixedZone("BDT", 6*3600)
	now := time.Date(2026, 10, 27, 15, 0, 0, 0, bdt)
	at := func(m time.Month, d, h, min int) time.Time { return time.Date(2026, m, d, h, min, 0, 0, bdt) }
	for _, c := range []struct {
		t      time.Time
		en, bn string
	}{
		{at(10, 27, 15, 0), "today 3:00 PM", "আজ ৩:০০ PM"},
		{at(10, 27, 0, 5), "today 12:05 AM", "আজ ১২:০৫ AM"},
		{at(10, 28, 10, 0), "tomorrow 10:00 AM", "আগামীকাল ১০:০০ AM"},
		{at(11, 4, 10, 30), "Nov 4, 10:30 AM", "৪ নভেম্বর, ১০:৩০ AM"},
		{at(10, 26, 23, 30), "Oct 26, 11:30 PM", "২৬ অক্টোবর, ১১:৩০ PM"},
		{at(12, 1, 12, 0), "Dec 1, 12:00 PM", "১ ডিসেম্বর, ১২:০০ PM"},
	} {
		assert.Equal(t, c.en, whenText("en", c.t, now))
		assert.Equal(t, c.bn, whenText("bn", c.t, now))
	}
	// Given in UTC, shown in Bangladesh time: 18:30 UTC on the 27th is
	// 00:30 on the 28th in Dhaka.
	assert.Equal(t, "tomorrow 12:30 AM", whenText("en", time.Date(2026, 10, 27, 18, 30, 0, 0, time.UTC), now))
	// The day is Dhaka's: 20:00 UTC on the 27th "now" is already the 28th there.
	assert.Equal(t, "today 3:00 PM", whenText("en", time.Date(2026, 10, 28, 9, 0, 0, 0, time.UTC), time.Date(2026, 10, 27, 20, 0, 0, 0, time.UTC)))
}

func TestNotices(t *testing.T) {
	bdt := time.FixedZone("BDT", 6*3600)
	now := time.Date(2026, 10, 27, 15, 0, 0, 0, bdt)
	id := uuid.New()
	n := requestNotice("A+", "Enam Medical", "", false, now.Add(24*time.Hour), now, id)
	assert.Equal(t, "A+ blood needed", n.Texts["en"].Title)
	assert.Equal(t, "Enam Medical · tomorrow 3:00 PM", n.Texts["en"].Body)
	assert.Equal(t, "A+ রক্ত প্রয়োজন", n.Texts["bn"].Title)
	assert.Equal(t, map[string]string{"type": "blood_request", "requestId": id.String()}, n.Data)
	n = requestNotice("O-", "Enam Medical", "Savar", true, now, now, id)
	assert.Equal(t, "O- blood needed, urgent", n.Texts["en"].Title)
	assert.Equal(t, "Enam Medical, Savar · today 3:00 PM", n.Texts["en"].Body)
	r := responseNotice("Nusrat", "B+", id)
	assert.Equal(t, "Nusrat can donate B+", r.Texts["en"].Title)
	assert.Equal(t, "Tap to call", r.Texts["en"].Body)
	assert.Equal(t, "blood_response", r.Data["type"])
}

func TestCursor(t *testing.T) {
	id := uuid.New()
	at := time.Date(2026, 10, 27, 9, 0, 0, 123000, time.UTC)
	c := keyCursor("o", true, at, id)
	got, err := parseKeyCursor(c, "o")
	assert.NoError(t, err)
	assert.True(t, got.urgent)
	assert.True(t, got.at.Equal(at))
	assert.Equal(t, id, got.id)
	_, err = parseKeyCursor(c, "m")
	assert.ErrorIs(t, err, ErrBadCursor)
	_, err = parseKeyCursor("!!", "o")
	assert.ErrorIs(t, err, ErrBadCursor)
	got, err = parseKeyCursor("", "o")
	assert.NoError(t, err)
	assert.Nil(t, got)
}
