package transport

import (
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func m(v int16) *int16 { return &v }

func TestCheckStops(t *testing.T) {
	ok := []StopInput{
		{Name: " Mirpur  10 ", ToCampusMin: m(0), FromCampusMin: m(50)},
		{Name: "Skipped one way", ToCampusMin: nil, FromCampusMin: m(40)},
		{Name: "Campus", ToCampusMin: m(50), FromCampusMin: m(0)},
	}
	require.NoError(t, checkStops(ok))
	assert.Equal(t, "Mirpur 10", ok[0].Name)

	assert.Error(t, checkStops([]StopInput{{Name: "  "}}))
	assert.Error(t, checkStops([]StopInput{{Name: "A", ToCampusMin: m(20)}, {Name: "B", ToCampusMin: m(10)}}))
	assert.Error(t, checkStops([]StopInput{{Name: "A", FromCampusMin: m(10)}, {Name: "B", FromCampusMin: m(20)}}))
}

func TestCheckTrips(t *testing.T) {
	trips := []TripInput{{Direction: ToCampus, Departs: "07:05", Weekdays: []int{7, 6, 6, 1}}}
	require.NoError(t, checkTrips(trips))
	assert.Equal(t, int16(7*60+5), trips[0].departs)
	assert.Equal(t, []int16{1, 6, 7}, trips[0].weekdays)

	for _, bad := range []string{"7:05", "24:00", "07:60", "x"} {
		assert.Error(t, checkTrips([]TripInput{{Direction: ToCampus, Departs: bad, Weekdays: []int{1}}}), bad)
	}
}
