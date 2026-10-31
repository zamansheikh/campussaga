package voice

import (
	"strings"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestParseKinds(t *testing.T) {
	got, err := parseKinds("")
	require.NoError(t, err)
	assert.Equal(t, []string{"issue"}, got, "absent = issues only")
	got, _ = parseKinds("all")
	assert.Equal(t, allKinds, got)
	got, err = parseKinds("poll, post,poll")
	require.NoError(t, err)
	assert.Equal(t, []string{"poll", "post"}, got)
	_, err = parseKinds("poll,video")
	assert.Error(t, err)
}

func TestCheckPollOptions(t *testing.T) {
	got, err := checkPollOptions([]string{" Yes ", "No"})
	require.NoError(t, err)
	assert.Equal(t, []string{"Yes", "No"}, got)
	for _, bad := range [][]string{{"one"}, {"a", "A"}, {"a", ""}, {"a", "b", "c", "d", "e"}, {"a", strings.Repeat("x", 81)}} {
		_, err = checkPollOptions(bad)
		assert.Error(t, err, "%v", bad)
	}
}

func TestCheckLengths(t *testing.T) {
	assert.NoError(t, checkLengths("post", "", "", "", 1), "a photo alone is a post")
	assert.Error(t, checkLengths("post", "", "", "", 0))
	assert.Error(t, checkLengths("post", "title", "hello", "", 0))
	assert.NoError(t, checkLengths("question", "", "Where is it?", "", 0))
	assert.Error(t, checkLengths("question", "", "Why?", "", 0))
	assert.Error(t, checkLengths("poll", "", strings.Repeat("q", 301), "", 0))
	assert.NoError(t, checkLengths("issue", "A broken pump", strings.Repeat("b", 20), "", 0))
	assert.Error(t, checkLengths("issue", "", strings.Repeat("b", 20), "", 0))
}

func TestPreview(t *testing.T) {
	p, cut := preview("short", previewIssue)
	assert.Equal(t, "short", p)
	assert.False(t, cut)
	p, cut = preview(strings.Repeat("a", 600), previewPost)
	assert.True(t, cut)
	assert.Equal(t, 500, len([]rune(p)))
}
