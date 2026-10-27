package ratelimit

import (
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
)

func TestAllowWindow(t *testing.T) {
	now := time.Date(2026, 10, 27, 10, 0, 0, 0, time.UTC)
	l := New(func() time.Time { return now })

	for i := 0; i < 3; i++ {
		ok, _ := l.Allow("k", 3, time.Minute)
		assert.True(t, ok, "hit %d", i+1)
	}
	ok, retry := l.Allow("k", 3, time.Minute)
	assert.False(t, ok)
	assert.Equal(t, time.Minute, retry)

	ok, _ = l.Allow("other", 3, time.Minute)
	assert.True(t, ok, "keys are independent")

	now = now.Add(time.Minute)
	ok, _ = l.Allow("k", 3, time.Minute)
	assert.True(t, ok, "a new window starts")
}
