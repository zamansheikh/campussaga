package sponsors

import (
	"testing"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func ad(priority int16) servable {
	return servable{promo: promo{ID: uuid.New(), Priority: priority}}
}

func TestWeightedOrderIsStable(t *testing.T) {
	ads := []servable{ad(5), ad(5), ad(5), ad(5)}
	user := uuid.New()
	first := weightedOrder(ads, user, "2026-11-01", "today")
	for range 5 {
		again := weightedOrder([]servable{ads[3], ads[1], ads[0], ads[2]}, user, "2026-11-01", "today")
		require.Equal(t, ids(first), ids(again), "the same order all day, whatever the input order")
	}
	// Another day or place reorders for some students.
	changed := 0
	for range 200 {
		u := uuid.New()
		if ids(weightedOrder(ads, u, "2026-11-01", "today"))[0] != ids(weightedOrder(ads, u, "2026-11-02", "today"))[0] {
			changed++
		}
	}
	assert.Greater(t, changed, 100, "a new day is a new pick")
}

func TestWeightedOrderFollowsPriority(t *testing.T) {
	high, low := ad(8), ad(2)
	ads := []servable{high, low}
	const n = 20000
	wins := 0
	for range n {
		if weightedOrder(ads, uuid.New(), "2026-11-01", "today")[0].ID == high.ID {
			wins++
		}
	}
	share := float64(wins) / n
	assert.InDelta(t, 0.8, share, 0.02, "priority 8 against 2 is chosen about 80%% of the time, got %.3f", share)

	// Three ads: 5, 3, 2 → about 50%, 30%, 20% first.
	a, b, c := ad(5), ad(3), ad(2)
	counts := map[uuid.UUID]int{}
	for range n {
		counts[weightedOrder([]servable{a, b, c}, uuid.New(), "2026-11-01", "campus")[0].ID]++
	}
	assert.InDelta(t, 0.5, float64(counts[a.ID])/n, 0.02)
	assert.InDelta(t, 0.3, float64(counts[b.ID])/n, 0.02)
	assert.InDelta(t, 0.2, float64(counts[c.ID])/n, 0.02)
}

func ids(ads []servable) []uuid.UUID {
	out := make([]uuid.UUID, len(ads))
	for i, a := range ads {
		out[i] = a.ID
	}
	return out
}

func TestLinksAndRoutes(t *testing.T) {
	for _, ok := range []string{"/explore", "/deals", "/bus", "/blood", "/groups", "/find-class", "/cgpa", "/campus",
		"/campaigns/" + uuid.NewString()} {
		assert.True(t, allowedAppRoute(ok), ok)
	}
	for _, bad := range []string{"", "/profile", "/campaigns/x", "/bus/123", "https://x.com", "/explore/"} {
		assert.False(t, allowedAppRoute(bad), bad)
	}
	for _, ok := range []string{"https://shop.example.com", "https://example.com/offer?x=1"} {
		assert.True(t, validWebLink(ok), ok)
	}
	for _, bad := range []string{"http://example.com", "https://", "https://exa mple.com", "javascript:alert(1)", "ftp://x.com"} {
		assert.False(t, validWebLink(bad), bad)
	}
	assert.Equal(t, []string{"Dhaka", "Sylhet"}, normCities([]string{" Dhaka ", "dhaka", "", "Sylhet"}))
}
