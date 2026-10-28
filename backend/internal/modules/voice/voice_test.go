package voice

import (
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestCheckText(t *testing.T) {
	for _, c := range []struct {
		text, want string
	}{
		{"The hostel water pump is broken again", ""},
		{"Call me at 01712345678 please", HoldPersonalInfo},
		{"Call +880 1712-345 678", HoldPersonalInfo},
		{"নম্বর ০১৭১২৩৪৫৬৭৮ এ ফোন দিন", HoldPersonalInfo}, // Bangla digits
		{"Mail rafi.cse@gmail.com", HoldPersonalInfo},
		{"My roll is 221-15-4031 by the way", HoldPersonalInfo},
		{"See bit.ly/abc for the photo", HoldPersonalInfo},
		{"Notice is at https://www.diu.edu.bd/notice/12", ""},
		{"Room 402 in 2 weeks, 3 times", ""},
		{"The guard is a Bastard!", HoldLanguage},
		{"ও একটা হারামজাদা", HoldLanguage},
		{"Classic class assignment", ""}, // no partial word matches
	} {
		assert.Equal(t, c.want, checkText(c.text), c.text)
	}
}

func TestHandles(t *testing.T) {
	secret := []byte("secret")
	issue, other, user, user2 := uuid.New(), uuid.New(), uuid.New(), uuid.New()
	h := handle(secret, issue, user)
	assert.Len(t, h, 4)
	assert.Regexp(t, `^[A-HJ-NP-Z2-9]{4}$`, h)
	assert.Equal(t, h, handle(secret, issue, user), "stable for the same person and issue")
	diff := 0
	for range 20 { // different issues and people give unrelated handles
		if handle(secret, uuid.New(), user) != h {
			diff++
		}
	}
	assert.Greater(t, diff, 15)
	assert.NotEqual(t, handle(secret, issue, user2)+handle(secret, other, user), h+h)
}

func TestCursorsAndTimes(t *testing.T) {
	at := time.Date(2026, 10, 28, 9, 3, 4, 5, time.UTC)
	id := uuid.New()
	gotAt, gotID, err := parseKeyCursor(keyCursor(at, id))
	require.NoError(t, err)
	assert.True(t, gotAt.Equal(at))
	assert.Equal(t, id, *gotID)
	n, err := parseOffsetCursor(offsetCursor(40))
	require.NoError(t, err)
	assert.Equal(t, 40, n)
	_, _, err = parseKeyCursor("garbage")
	assert.ErrorIs(t, err, ErrBadCursor)
	_, err = parseOffsetCursor(keyCursor(at, id))
	assert.ErrorIs(t, err, ErrBadCursor)
	assert.Equal(t, time.Date(2026, 10, 28, 9, 0, 0, 0, time.UTC), roughTime(at))
}
