package app

import (
	"context"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/zamansheikh/varsitykotha/backend/internal/modules/universities"
	"github.com/zamansheikh/varsitykotha/backend/internal/testkit"
)

// Real student addresses must reach the right university (seeded by the
// migrations from backend/data/universities_bd.json).
func TestBangladeshiUniversityEmailsMatch(t *testing.T) {
	svc := universities.NewService(testkit.NewDB(t))
	ctx := context.Background()

	cases := map[string]string{
		"rafi@diu.edu.bd":              "diu",        // Daffodil student domain
		"staff@daffodilvarsity.edu.bd": "diu",        // Daffodil website domain
		"x@diu.ac":                     "diu-ac",     // Dhaka International University (look-alike)
		"x@g.bracu.ac.bd":              "bracu",      // BRAC student subdomain
		"x@bscse.uiu.ac.bd":            "uiu",        // UIU per-programme subdomain
		"x@iub.edu.bd":                 "iub",        // IUB students on a different domain than the website
		"x@student.presidency.edu.bd":  "pu",         // Presidency, different domain
		"x@uttarauniversity.edu.bd":    "uttara",     // Uttara, different domain
		"x@std.cu.ac.bd":               "cu",         // University of Chittagong
		"x@cse.du.ac.bd":               "du",         // University of Dhaka department
		"x@student.aiub.edu":           "aiub",       // .edu ending
		"x@northsouth.edu":             "northsouth", // NSU
		"x@nu.edu.bd":                  "nu",         // National University, old domain alias
		"x@bsmmu.edu.bd":               "bmu-ac",     // renamed: BSMMU -> Bangladesh Medical University
		"x@sau.ac.bd":                  "sau-ac",     // Sylhet Agricultural (look-alike of sau.edu.bd)
		"x@sau.edu.bd":                 "sau",        // Sher-e-Bangla Agricultural
	}
	for email, slug := range cases {
		u, err := svc.ForEmail(ctx, email)
		require.NoError(t, err, email)
		if assert.NotNil(t, u, email) {
			assert.Equal(t, slug, u.Slug, email)
		}
	}

	for _, email := range []string{"x@student.green.ac.bd", "x@gmail.com", "x@ac.bd", "x@notdu.ac.bd"} {
		u, err := svc.ForEmail(ctx, email)
		require.NoError(t, err)
		assert.Nil(t, u, "%s must not match (held, free mail, suffix or look-alike)", email)
	}
}
