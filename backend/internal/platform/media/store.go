// Package media stores and prepares photos (Campus Voice issues).
package media

import (
	"errors"
	"io"
	"os"
	"path/filepath"
	"regexp"
)

// Store keeps files by key. Keys are random names like "<uuid>-full.jpg";
// they never include a user's file name.
type Store interface {
	Put(key string, data []byte) error
	Open(key string) (io.ReadSeekCloser, error)
	Delete(key string) error
}

// ErrNotFound: no file under that key.
var ErrNotFound = errors.New("media: not found")

var keyRe = regexp.MustCompile(`^[a-z0-9-]{8,80}\.jpg$`)

// Disk is a Store on a local directory (a Docker volume in production).
type Disk struct{ Dir string }

func NewDisk(dir string) (*Disk, error) {
	if err := os.MkdirAll(dir, 0o750); err != nil {
		return nil, err
	}
	return &Disk{Dir: dir}, nil
}

func (d *Disk) path(key string) (string, error) {
	if !keyRe.MatchString(key) {
		return "", errors.New("media: bad key")
	}
	return filepath.Join(d.Dir, key), nil
}

// Put writes atomically (temp file, then rename).
func (d *Disk) Put(key string, data []byte) error {
	p, err := d.path(key)
	if err != nil {
		return err
	}
	tmp, err := os.CreateTemp(d.Dir, ".upload-*")
	if err != nil {
		return err
	}
	if _, err := tmp.Write(data); err != nil {
		tmp.Close()
		os.Remove(tmp.Name())
		return err
	}
	if err := tmp.Close(); err != nil {
		os.Remove(tmp.Name())
		return err
	}
	return os.Rename(tmp.Name(), p)
}

func (d *Disk) Open(key string) (io.ReadSeekCloser, error) {
	p, err := d.path(key)
	if err != nil {
		return nil, ErrNotFound
	}
	f, err := os.Open(p)
	if errors.Is(err, os.ErrNotExist) {
		return nil, ErrNotFound
	}
	return f, err
}

func (d *Disk) Delete(key string) error {
	p, err := d.path(key)
	if err != nil {
		return nil
	}
	if err := os.Remove(p); err != nil && !errors.Is(err, os.ErrNotExist) {
		return err
	}
	return nil
}
