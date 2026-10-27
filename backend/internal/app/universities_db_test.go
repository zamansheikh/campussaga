package app

import (
	"context"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/zamansheikh/campussaga/backend/internal/platform/db"
	"github.com/zamansheikh/campussaga/backend/internal/testkit"
)

func TestSharedDomainsAreRefusedByTheDatabase(t *testing.T) {
	d := testkit.NewDB(t)
	ctx := context.Background()
	var uni string
	require.NoError(t, d.Pool.QueryRow(ctx,
		`INSERT INTO universities (slug, name) VALUES ('x-uni', 'X University') RETURNING id`).Scan(&uni))

	for _, domain := range []string{"ac.bd", "edu.bd", "gmail.com", "yahoo.co.uk", "edu", "outlook.com"} {
		_, err := d.Pool.Exec(ctx, `INSERT INTO university_domains (domain, university_id) VALUES ($1, $2)`, domain, uni)
		assert.Error(t, err, domain)
		if err != nil && domain != "edu" {
			assert.Equal(t, "23514", db.PgCode(err), "%s: check constraint", domain)
		}
	}
	_, err := d.Pool.Exec(ctx, `INSERT INTO university_domains (domain, university_id) VALUES ('x.ac.bd', $1)`, uni)
	assert.NoError(t, err, "a real university domain is fine")
}
