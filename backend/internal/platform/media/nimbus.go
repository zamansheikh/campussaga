package media

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"mime/multipart"
	"net/http"
	"net/url"
	"strings"
	"sync"
	"time"
)

// Nimbus is a Store on Nimbus (cloud-explorer, capi.tecsior.com): the files
// live in the R2 bucket the API key is bound to, off this server. Photos
// stay private: the bucket needs no public URL, and the API streams them to
// students after its own visibility checks, so no Nimbus link ever reaches
// the app.
//
// Objects are named Prefix + key ("varsitykotha/voice/<uuid>-full.jpg"),
// uploaded byte for byte (optimize=false: they are already re-encoded).
type Nimbus struct {
	BaseURL string // e.g. https://capi.tecsior.com/api/v1
	APIKey  string
	Prefix  string // e.g. "varsitykotha/voice/"
	Client  *http.Client

	ids sync.Map // object key → Nimbus asset id (saves a lookup per view)
}

func NewNimbus(baseURL, apiKey, prefix string) *Nimbus {
	return &Nimbus{
		BaseURL: strings.TrimRight(baseURL, "/"),
		APIKey:  apiKey,
		Prefix:  prefix,
		Client:  &http.Client{Timeout: 45 * time.Second},
	}
}

func (n *Nimbus) object(key string) (string, error) {
	if !keyRe.MatchString(key) {
		return "", fmt.Errorf("media: bad key")
	}
	return n.Prefix + key, nil
}

func (n *Nimbus) do(req *http.Request) (*http.Response, error) {
	req.Header.Set("Authorization", "Bearer "+n.APIKey)
	return n.Client.Do(req)
}

// Put uploads the photo under its exact object key.
func (n *Nimbus) Put(key string, data []byte) error {
	obj, err := n.object(key)
	if err != nil {
		return err
	}
	var body bytes.Buffer
	w := multipart.NewWriter(&body)
	for k, v := range map[string]string{
		"key": obj, "optimize": "false", "contentType": "image/jpeg",
		"cacheControl": "private, no-store", "tags": "varsitykotha,voice",
	} {
		if err := w.WriteField(k, v); err != nil {
			return err
		}
	}
	part, err := w.CreateFormFile("file", key)
	if err != nil {
		return err
	}
	if _, err := part.Write(data); err != nil {
		return err
	}
	if err := w.Close(); err != nil {
		return err
	}
	ctx, cancel := context.WithTimeout(context.Background(), 60*time.Second)
	defer cancel()
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, n.BaseURL+"/assets/upload", &body)
	if err != nil {
		return err
	}
	req.Header.Set("Content-Type", w.FormDataContentType())
	res, err := n.do(req)
	if err != nil {
		return fmt.Errorf("media: nimbus upload: %w", err)
	}
	defer res.Body.Close()
	if res.StatusCode/100 != 2 {
		return fmt.Errorf("media: nimbus upload: %s", status(res))
	}
	var out struct {
		Uploaded []struct {
			ID string `json:"_id"`
		} `json:"uploaded"`
	}
	if err := json.NewDecoder(res.Body).Decode(&out); err == nil && len(out.Uploaded) == 1 && out.Uploaded[0].ID != "" {
		n.ids.Store(obj, out.Uploaded[0].ID)
	}
	return nil
}

// id finds the asset id of an object key.
func (n *Nimbus) id(ctx context.Context, obj string) (string, error) {
	if v, ok := n.ids.Load(obj); ok {
		return v.(string), nil
	}
	req, err := http.NewRequestWithContext(ctx, http.MethodGet,
		n.BaseURL+"/assets/by-url?url="+url.QueryEscape(obj), nil)
	if err != nil {
		return "", err
	}
	res, err := n.do(req)
	if err != nil {
		return "", fmt.Errorf("media: nimbus lookup: %w", err)
	}
	defer res.Body.Close()
	if res.StatusCode == http.StatusNotFound {
		return "", ErrNotFound
	}
	if res.StatusCode/100 != 2 {
		return "", fmt.Errorf("media: nimbus lookup: %s", status(res))
	}
	var a struct {
		ID  string `json:"_id"`
		Key string `json:"key"`
	}
	if err := json.NewDecoder(res.Body).Decode(&a); err != nil || a.ID == "" {
		return "", fmt.Errorf("media: nimbus lookup: bad answer")
	}
	if a.Key != "" && a.Key != obj {
		return "", ErrNotFound // matched something else: never serve it
	}
	n.ids.Store(obj, a.ID)
	return a.ID, nil
}

// Open downloads the photo (small: a few hundred KB at most).
func (n *Nimbus) Open(key string) (io.ReadSeekCloser, error) {
	obj, err := n.object(key)
	if err != nil {
		return nil, ErrNotFound
	}
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	id, err := n.id(ctx, obj)
	if err != nil {
		return nil, err
	}
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, n.BaseURL+"/assets/"+url.PathEscape(id)+"/raw", nil)
	if err != nil {
		return nil, err
	}
	res, err := n.do(req)
	if err != nil {
		return nil, fmt.Errorf("media: nimbus download: %w", err)
	}
	defer res.Body.Close()
	if res.StatusCode == http.StatusNotFound {
		n.ids.Delete(obj)
		return nil, ErrNotFound
	}
	if res.StatusCode/100 != 2 {
		return nil, fmt.Errorf("media: nimbus download: %s", status(res))
	}
	data, err := io.ReadAll(io.LimitReader(res.Body, 20<<20))
	if err != nil {
		return nil, err
	}
	return nopCloser{bytes.NewReader(data)}, nil
}

// Delete removes the photo; a missing one is fine.
func (n *Nimbus) Delete(key string) error {
	obj, err := n.object(key)
	if err != nil {
		return nil
	}
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	req, err := http.NewRequestWithContext(ctx, http.MethodDelete,
		n.BaseURL+"/assets/by-url?url="+url.QueryEscape(obj), nil)
	if err != nil {
		return err
	}
	res, err := n.do(req)
	if err != nil {
		return fmt.Errorf("media: nimbus delete: %w", err)
	}
	defer res.Body.Close()
	n.ids.Delete(obj)
	if res.StatusCode == http.StatusNotFound || res.StatusCode/100 == 2 {
		return nil
	}
	return fmt.Errorf("media: nimbus delete: %s", status(res))
}

type nopCloser struct{ *bytes.Reader }

func (nopCloser) Close() error { return nil }

// status describes a failed answer without echoing much of its body.
func status(res *http.Response) string {
	b, _ := io.ReadAll(io.LimitReader(res.Body, 200))
	return fmt.Sprintf("%d %s", res.StatusCode, strings.TrimSpace(string(b)))
}
