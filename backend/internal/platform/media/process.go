package media

import (
	"bytes"
	"encoding/binary"
	"errors"
	"image"
	"image/jpeg"
	_ "image/png" // decoders
	"math"

	"golang.org/x/image/draw"
	_ "golang.org/x/image/webp"
)

const (
	MaxBytes     = 8 << 20 // per photo
	maxPixelSide = 8000
	// Sized for phone screens and cheap storage: a detailed 4K photo comes
	// out near 110 KB full and 12 KB thumb (1600 px q82 was 218 KB + 25 KB).
	FullSide     = 1280
	ThumbSide    = 400
	fullQuality  = 70
	thumbQuality = 65
)

var (
	// ErrInvalid: not a JPEG, PNG or WebP image (or a broken one).
	ErrInvalid = errors.New("media: not a supported image")
	// ErrTooLarge: over MaxBytes or over 8000 px on a side.
	ErrTooLarge = errors.New("media: image too large")
)

// Processed is a photo ready to store: re-encoded JPEGs, so no metadata
// (EXIF location, device, time) survives. The original bytes are never kept.
type Processed struct {
	Full, Thumb   []byte
	Width, Height int // of Full
}

// Process checks, orients, scales and re-encodes a photo.
func Process(data []byte) (*Processed, error) {
	if len(data) > MaxBytes {
		return nil, ErrTooLarge
	}
	cfg, format, err := image.DecodeConfig(bytes.NewReader(data))
	if err != nil {
		return nil, ErrInvalid
	}
	if format != "jpeg" && format != "png" && format != "webp" {
		return nil, ErrInvalid
	}
	if cfg.Width < 1 || cfg.Height < 1 || cfg.Width > maxPixelSide || cfg.Height > maxPixelSide {
		return nil, ErrTooLarge
	}
	img, _, err := image.Decode(bytes.NewReader(data))
	if err != nil {
		return nil, ErrInvalid
	}
	if format == "jpeg" {
		img = orient(img, jpegOrientation(data))
	}
	full := scale(img, FullSide)
	thumb := scale(img, ThumbSide)
	fb, err := encode(full, fullQuality)
	if err != nil {
		return nil, err
	}
	tb, err := encode(thumb, thumbQuality)
	if err != nil {
		return nil, err
	}
	b := full.Bounds()
	return &Processed{Full: fb, Thumb: tb, Width: b.Dx(), Height: b.Dy()}, nil
}

// BannerWidth: campaign banners are at most this wide (2:1 recommended).
const BannerWidth = 1600

// ProcessBanner checks a banner photo and re-encodes it as a JPEG at most
// BannerWidth wide (and at most BannerWidth tall), keeping its shape.
func ProcessBanner(data []byte) ([]byte, error) {
	if len(data) > MaxBytes {
		return nil, ErrTooLarge
	}
	cfg, format, err := image.DecodeConfig(bytes.NewReader(data))
	if err != nil || (format != "jpeg" && format != "png" && format != "webp") {
		return nil, ErrInvalid
	}
	if cfg.Width < 1 || cfg.Height < 1 || cfg.Width > maxPixelSide || cfg.Height > maxPixelSide {
		return nil, ErrTooLarge
	}
	img, _, err := image.Decode(bytes.NewReader(data))
	if err != nil {
		return nil, ErrInvalid
	}
	if format == "jpeg" {
		img = orient(img, jpegOrientation(data))
	}
	return encode(scale(img, BannerWidth), 80)
}

// Ad images (docs/SPONSORS.md) fit within PromoWidth × PromoHeight (2:1);
// sponsor logos within LogoSide × LogoSide.
const (
	PromoWidth   = 1600
	PromoHeight  = 800
	LogoSide     = 512
	LogoMaxBytes = 4 << 20
	promoQuality = 80
	logoQuality  = 88
)

// ProcessPromo checks an ad image and re-encodes it as a JPEG that fits
// within PromoWidth × PromoHeight, keeping its shape (never enlarged).
func ProcessPromo(data []byte) ([]byte, error) {
	img, err := decodeChecked(data, MaxBytes)
	if err != nil {
		return nil, err
	}
	return encode(fit(img, PromoWidth, PromoHeight), promoQuality)
}

// ProcessLogo checks a sponsor logo (at most LogoMaxBytes) and re-encodes it
// as a JPEG within LogoSide × LogoSide on white (transparency becomes white).
func ProcessLogo(data []byte) ([]byte, error) {
	img, err := decodeChecked(data, LogoMaxBytes)
	if err != nil {
		return nil, err
	}
	return encode(fit(img, LogoSide, LogoSide), logoQuality)
}

// decodeChecked: a JPEG, PNG or WebP of at most limit bytes and 8000 px a
// side, turned the way it was taken.
func decodeChecked(data []byte, limit int) (image.Image, error) {
	if len(data) > limit {
		return nil, ErrTooLarge
	}
	cfg, format, err := image.DecodeConfig(bytes.NewReader(data))
	if err != nil || (format != "jpeg" && format != "png" && format != "webp") {
		return nil, ErrInvalid
	}
	if cfg.Width < 1 || cfg.Height < 1 || cfg.Width > maxPixelSide || cfg.Height > maxPixelSide {
		return nil, ErrTooLarge
	}
	img, _, err := image.Decode(bytes.NewReader(data))
	if err != nil {
		return nil, ErrInvalid
	}
	if format == "jpeg" {
		img = orient(img, jpegOrientation(data))
	}
	return img, nil
}

// fit scales img to fit within w × h (never enlarges), on white.
func fit(img image.Image, w, h int) image.Image {
	b := img.Bounds()
	f := math.Min(1, math.Min(float64(w)/float64(b.Dx()), float64(h)/float64(b.Dy())))
	dw := max(1, int(math.Round(float64(b.Dx())*f)))
	dh := max(1, int(math.Round(float64(b.Dy())*f)))
	dst := image.NewRGBA(image.Rect(0, 0, dw, dh))
	draw.Draw(dst, dst.Bounds(), image.White, image.Point{}, draw.Src)
	draw.CatmullRom.Scale(dst, dst.Bounds(), img, b, draw.Over, nil)
	return dst
}

func encode(img image.Image, quality int) ([]byte, error) {
	var buf bytes.Buffer
	if err := jpeg.Encode(&buf, img, &jpeg.Options{Quality: quality}); err != nil {
		return nil, err
	}
	return buf.Bytes(), nil
}

// scale fits img within side × side (never enlarges), on an opaque white
// background (PNG/WebP transparency).
func scale(img image.Image, side int) image.Image {
	b := img.Bounds()
	w, h := b.Dx(), b.Dy()
	if m := max(w, h); m > side {
		f := float64(side) / float64(m)
		w = max(1, int(math.Round(float64(w)*f)))
		h = max(1, int(math.Round(float64(h)*f)))
	}
	dst := image.NewRGBA(image.Rect(0, 0, w, h))
	draw.Draw(dst, dst.Bounds(), image.White, image.Point{}, draw.Src)
	draw.CatmullRom.Scale(dst, dst.Bounds(), img, b, draw.Over, nil)
	return dst
}

// orient applies an EXIF orientation (1–8) so the photo stands the way it
// was taken once the metadata is gone.
func orient(img image.Image, o int) image.Image {
	if o < 2 || o > 8 {
		return img
	}
	b := img.Bounds()
	w, h := b.Dx(), b.Dy()
	swap := o >= 5
	dw, dh := w, h
	if swap {
		dw, dh = h, w
	}
	dst := image.NewRGBA(image.Rect(0, 0, dw, dh))
	for y := 0; y < h; y++ {
		for x := 0; x < w; x++ {
			var dx, dy int
			switch o {
			case 2:
				dx, dy = w-1-x, y
			case 3:
				dx, dy = w-1-x, h-1-y
			case 4:
				dx, dy = x, h-1-y
			case 5:
				dx, dy = y, x
			case 6:
				dx, dy = h-1-y, x
			case 7:
				dx, dy = h-1-y, w-1-x
			case 8:
				dx, dy = y, w-1-x
			}
			dst.Set(dx, dy, img.At(b.Min.X+x, b.Min.Y+y))
		}
	}
	return dst
}

// jpegOrientation reads the EXIF orientation tag (0x0112) of a JPEG, or 1.
func jpegOrientation(data []byte) int {
	if len(data) < 4 || data[0] != 0xFF || data[1] != 0xD8 {
		return 1
	}
	i := 2
	for i+4 <= len(data) {
		if data[i] != 0xFF {
			return 1
		}
		marker := data[i+1]
		if marker == 0xDA || marker == 0xD9 { // start of scan / end
			return 1
		}
		size := int(binary.BigEndian.Uint16(data[i+2 : i+4]))
		if size < 2 || i+2+size > len(data) {
			return 1
		}
		seg := data[i+4 : i+2+size]
		if marker == 0xE1 && len(seg) > 14 && string(seg[:6]) == "Exif\x00\x00" {
			return tiffOrientation(seg[6:])
		}
		i += 2 + size
	}
	return 1
}

func tiffOrientation(t []byte) int {
	if len(t) < 8 {
		return 1
	}
	var bo binary.ByteOrder
	switch string(t[:2]) {
	case "II":
		bo = binary.LittleEndian
	case "MM":
		bo = binary.BigEndian
	default:
		return 1
	}
	off := int(bo.Uint32(t[4:8]))
	if off+2 > len(t) {
		return 1
	}
	n := int(bo.Uint16(t[off : off+2]))
	for k := 0; k < n; k++ {
		e := off + 2 + k*12
		if e+12 > len(t) {
			return 1
		}
		if bo.Uint16(t[e:e+2]) == 0x0112 {
			v := int(bo.Uint16(t[e+8 : e+10]))
			if v >= 1 && v <= 8 {
				return v
			}
			return 1
		}
	}
	return 1
}
