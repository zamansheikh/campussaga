package classgroups

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestClock(t *testing.T) {
	for in, want := range map[string]int16{"00:00": 0, "08:30": 510, "23:59": 1439, "24:00": 1440, " 09:05 ": 545} {
		got, ok := parseClock(in)
		assert.True(t, ok, in)
		assert.Equal(t, want, got, in)
	}
	for _, bad := range []string{"", "9:30", "09:60", "24:01", "ab:cd", "09-30", "-1:00", "09:3"} {
		_, ok := parseClock(bad)
		assert.False(t, ok, bad)
	}
	assert.Equal(t, "08:05", formatClock(485))
}

func TestCodes(t *testing.T) {
	seen := map[string]bool{}
	for range 200 {
		c, err := newCode()
		assert.NoError(t, err)
		assert.Regexp(t, `^[A-HJ-NP-Z]{6}$`, c)
		seen[c] = true
	}
	assert.Greater(t, len(seen), 195, "random, not repeating")
}
