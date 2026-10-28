package media

import (
	"bytes"
	"image"
	"image/jpeg"
	"image/png"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/zamansheikh/campussaga/backend/internal/platform/media/mediatest"
)

func TestProcessStripsMetadataAndOrients(t *testing.T) {
	src := mediatest.JPEGWithExif(t, 400, 200, 6) // rotate 90° clockwise
	require.True(t, bytes.Contains(src, []byte("Exif")))
	assert.Equal(t, 6, jpegOrientation(src))

	p, err := Process(src)
	require.NoError(t, err)
	for _, b := range [][]byte{p.Full, p.Thumb} {
		assert.False(t, bytes.Contains(b, []byte("Exif")), "metadata dropped")
		assert.False(t, bytes.Contains(b, []byte("GPS")))
	}
	assert.Equal(t, 200, p.Width, "portrait after orientation")
	assert.Equal(t, 400, p.Height)
	full, err := jpeg.Decode(bytes.NewReader(p.Full))
	require.NoError(t, err)
	r, _, _, _ := full.At(100, 10).RGBA() // red half is now on top
	assert.Greater(t, r>>8, uint32(200))
}

func TestProcessScalesAndRefuses(t *testing.T) {
	big := image.NewRGBA(image.Rect(0, 0, 3200, 1600))
	var b bytes.Buffer
	require.NoError(t, png.Encode(&b, big))
	p, err := Process(b.Bytes())
	require.NoError(t, err)
	assert.Equal(t, FullSide, p.Width)
	assert.Equal(t, 800, p.Height)
	th, err := jpeg.Decode(bytes.NewReader(p.Thumb))
	require.NoError(t, err)
	assert.Equal(t, ThumbSide, th.Bounds().Dx())

	_, err = Process([]byte("not an image at all"))
	assert.ErrorIs(t, err, ErrInvalid)
	_, err = Process(make([]byte, MaxBytes+1))
	assert.ErrorIs(t, err, ErrTooLarge)
	huge := image.NewGray(image.Rect(0, 0, 8001, 1))
	b.Reset()
	require.NoError(t, png.Encode(&b, huge))
	_, err = Process(b.Bytes())
	assert.ErrorIs(t, err, ErrTooLarge)
}
