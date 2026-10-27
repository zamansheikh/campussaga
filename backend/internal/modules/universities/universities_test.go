package universities

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestDomainCandidates(t *testing.T) {
	assert.Equal(t, []string{"cse.du.ac.bd", "du.ac.bd", "ac.bd"}, DomainCandidates("a@cse.du.ac.bd"))
	assert.Equal(t, []string{"test.ac.bd", "ac.bd"}, DomainCandidates("A@Test.AC.BD"))
	assert.Equal(t, []string{"nottest.ac.bd", "ac.bd"}, DomainCandidates("x@nottest.ac.bd"),
		"whole labels only: never matches test.ac.bd")
	assert.Nil(t, DomainCandidates("no-at-sign"))
	assert.Nil(t, DomainCandidates("a@"))
	assert.Nil(t, DomainCandidates("a@localhost"))
	assert.Nil(t, DomainCandidates("a@bad..domain.bd"))
}
