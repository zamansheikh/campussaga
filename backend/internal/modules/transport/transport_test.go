package transport

import (
	"encoding/json"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/zamansheikh/varsitykotha/backend/internal/modules/transport/store"
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

func f(v float64) *float64 { return &v }

func TestStopLocation(t *testing.T) {
	var in struct {
		Stops []StopInput `json:"stops"`
	}
	require.NoError(t, json.Unmarshal([]byte(`{"stops":[
		{"name":"A","location":{"lat":23.81,"lng":90.41}},
		{"name":"B","location":null},
		{"name":"C"}]}`), &in))
	assert.True(t, in.Stops[0].Location.Set)
	assert.Equal(t, &LatLng{Lat: 23.81, Lng: 90.41}, in.Stops[0].Location.Value)
	assert.True(t, in.Stops[1].Location.Set)
	assert.Nil(t, in.Stops[1].Location.Value)
	assert.False(t, in.Stops[2].Location.Set)
	require.NoError(t, checkStops(in.Stops))

	bad := []StopInput{{Name: "A", Location: OptLocation{Set: true, Value: &LatLng{Lat: 91, Lng: 0}}}}
	assert.Error(t, checkStops(bad))
}

func TestKeptLocations(t *testing.T) {
	old := []store.BusStop{
		{Name: "A", Lat: f(1), Lng: f(2)},
		{Name: "B", Lat: f(3), Lng: f(4)},
		{Name: "B", Lat: f(5), Lng: f(6)},
	}
	got := keptLocations(old, []StopInput{
		{Name: "B"}, // an older app: keeps B's first location
		{Name: "B"}, // and the second B gets the second one
		{Name: "A", Location: OptLocation{Set: true}}, // removed on purpose
		{Name: "New"},
		{Name: "B", Location: OptLocation{Set: true, Value: &LatLng{Lat: 7, Lng: 8}}},
	})
	assert.Equal(t, []*LatLng{{Lat: 3, Lng: 4}, {Lat: 5, Lng: 6}, nil, nil, {Lat: 7, Lng: 8}}, got)
}

func TestCleanPhone(t *testing.T) {
	for in, want := range map[string]string{
		"01989155614":       "01989155614",
		"০১৯৮৯১৫৫৬১৪":       "01989155614",
		"+880 1989-155614":  "+8801989155614",
		" (017) 1234.5678 ": "01712345678",
		"":                  "",
	} {
		got, ok := cleanPhone(in)
		assert.True(t, ok, in)
		assert.Equal(t, want, got, in)
	}
	for _, bad := range []string{"call me", "12345", "+", "0171234567890123456"} {
		_, ok := cleanPhone(bad)
		assert.False(t, ok, bad)
	}
}
