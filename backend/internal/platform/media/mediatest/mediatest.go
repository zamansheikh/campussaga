// Package mediatest makes test photos for the media package and the API tests.
package mediatest

import (
	"bytes"
	"encoding/binary"
	"image"
	"image/color"
	"image/jpeg"
	"testing"

	"github.com/stretchr/testify/require"
)

// JPEGWithExif makes a w×h JPEG carrying an EXIF block with an orientation
// and a fake GPS marker, like a phone photo.
func JPEGWithExif(t testing.TB, w, h, orientation int) []byte {
	t.Helper()
	img := image.NewRGBA(image.Rect(0, 0, w, h))
	for x := 0; x < w/2; x++ { // left half red: shows rotation
		for y := 0; y < h; y++ {
			img.Set(x, y, color.RGBA{R: 255, A: 255})
		}
	}
	var enc bytes.Buffer
	require.NoError(t, jpeg.Encode(&enc, img, nil))
	raw := enc.Bytes()

	var tiff bytes.Buffer
	tiff.WriteString("II")
	_ = binary.Write(&tiff, binary.LittleEndian, uint16(42))
	_ = binary.Write(&tiff, binary.LittleEndian, uint32(8))
	_ = binary.Write(&tiff, binary.LittleEndian, uint16(1)) // one entry
	_ = binary.Write(&tiff, binary.LittleEndian, uint16(0x0112))
	_ = binary.Write(&tiff, binary.LittleEndian, uint16(3))
	_ = binary.Write(&tiff, binary.LittleEndian, uint32(1))
	_ = binary.Write(&tiff, binary.LittleEndian, uint16(orientation))
	_ = binary.Write(&tiff, binary.LittleEndian, uint16(0))
	_ = binary.Write(&tiff, binary.LittleEndian, uint32(0))
	tiff.WriteString("GPSLatitude 23.81 N; GPSLongitude 90.41 E; Pixel 6")
	seg := append([]byte("Exif\x00\x00"), tiff.Bytes()...)

	var out bytes.Buffer
	out.Write(raw[:2]) // SOI
	out.Write([]byte{0xFF, 0xE1})
	_ = binary.Write(&out, binary.BigEndian, uint16(len(seg)+2))
	out.Write(seg)
	out.Write(raw[2:])
	return out.Bytes()
}
