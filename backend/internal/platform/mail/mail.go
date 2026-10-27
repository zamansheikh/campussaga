// Package mail sends transactional email (sign-in codes) over SMTP.
// Production uses a provider's SMTP relay (Resend); development uses Mailpit
// from docker-compose; tests use Memory.
package mail

import (
	"bytes"
	"context"
	"crypto/rand"
	"crypto/tls"
	"embed"
	"encoding/base64"
	"encoding/hex"
	"errors"
	"fmt"
	"html/template"
	"mime"
	"net"
	"net/mail"
	"net/smtp"
	"strconv"
	"strings"
	"sync"
	"time"
)

// Message is one email.
type Message struct {
	To      string
	Subject string
	Text    string
	HTML    string
}

// Sender delivers messages.
type Sender interface {
	Send(ctx context.Context, m Message) error
}

// SMTP sends through an SMTP server, upgrading with STARTTLS when offered.
// Credentials are only ever sent over TLS (net/smtp's PlainAuth refuses
// plain-text auth except to localhost).
type SMTP struct {
	Host     string
	Port     int
	Username string
	Password string
	From     string // "Name <address>"
}

func (s *SMTP) Send(ctx context.Context, m Message) error {
	from, err := mail.ParseAddress(s.From)
	if err != nil {
		return fmt.Errorf("mail: bad From %q: %w", s.From, err)
	}
	to, err := mail.ParseAddress(m.To)
	if err != nil {
		return fmt.Errorf("mail: bad To: %w", err)
	}
	body, err := build(from, to, m)
	if err != nil {
		return err
	}

	deadline, ok := ctx.Deadline()
	if !ok {
		deadline = time.Now().Add(15 * time.Second)
	}
	addr := net.JoinHostPort(s.Host, strconv.Itoa(s.Port))
	conn, err := (&net.Dialer{Deadline: deadline}).DialContext(ctx, "tcp", addr)
	if err != nil {
		return fmt.Errorf("mail: dial %s: %w", addr, err)
	}
	_ = conn.SetDeadline(deadline)
	c, err := smtp.NewClient(conn, s.Host)
	if err != nil {
		_ = conn.Close()
		return fmt.Errorf("mail: hello: %w", err)
	}
	defer c.Close()
	if ok, _ := c.Extension("STARTTLS"); ok {
		if err := c.StartTLS(&tls.Config{ServerName: s.Host, MinVersion: tls.VersionTLS12}); err != nil {
			return fmt.Errorf("mail: starttls: %w", err)
		}
	}
	if s.Username != "" {
		if err := c.Auth(smtp.PlainAuth("", s.Username, s.Password, s.Host)); err != nil {
			return fmt.Errorf("mail: auth: %w", err)
		}
	}
	if err := c.Mail(from.Address); err != nil {
		return fmt.Errorf("mail: MAIL FROM: %w", err)
	}
	if err := c.Rcpt(to.Address); err != nil {
		return fmt.Errorf("mail: RCPT TO: %w", err)
	}
	w, err := c.Data()
	if err != nil {
		return fmt.Errorf("mail: DATA: %w", err)
	}
	if _, err := w.Write(body); err != nil {
		return fmt.Errorf("mail: write: %w", err)
	}
	if err := w.Close(); err != nil {
		return fmt.Errorf("mail: send: %w", err)
	}
	return c.Quit()
}

// build renders a multipart/alternative message (text + HTML), every part
// base64 encoded so Bangla text survives any relay.
func build(from, to *mail.Address, m Message) ([]byte, error) {
	if strings.ContainsAny(m.Subject, "\r\n") {
		return nil, errors.New("mail: subject contains a line break")
	}
	var rnd [12]byte
	_, _ = rand.Read(rnd[:])
	boundary := "b_" + hex.EncodeToString(rnd[:])
	domain := from.Address[strings.LastIndex(from.Address, "@")+1:]

	var b bytes.Buffer
	h := func(k, v string) { fmt.Fprintf(&b, "%s: %s\r\n", k, v) }
	h("From", from.String())
	h("To", to.String())
	h("Subject", mime.QEncoding.Encode("utf-8", m.Subject))
	h("Date", time.Now().UTC().Format(time.RFC1123Z))
	h("Message-ID", "<"+hex.EncodeToString(rnd[:])+"@"+domain+">")
	h("MIME-Version", "1.0")
	h("Content-Type", `multipart/alternative; boundary="`+boundary+`"`)
	b.WriteString("\r\n")
	part := func(ctype, content string) {
		fmt.Fprintf(&b, "--%s\r\nContent-Type: %s; charset=utf-8\r\nContent-Transfer-Encoding: base64\r\n\r\n", boundary, ctype)
		enc := base64.StdEncoding.EncodeToString([]byte(content))
		for len(enc) > 76 {
			b.WriteString(enc[:76] + "\r\n")
			enc = enc[76:]
		}
		b.WriteString(enc + "\r\n")
	}
	part("text/plain", m.Text)
	if m.HTML != "" {
		part("text/html", m.HTML)
	}
	fmt.Fprintf(&b, "--%s--\r\n", boundary)
	return b.Bytes(), nil
}

// Memory keeps messages in memory (tests).
type Memory struct {
	mu   sync.Mutex
	sent []Message
	Fail error // when set, Send returns it
}

func (m *Memory) Send(_ context.Context, msg Message) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	if m.Fail != nil {
		return m.Fail
	}
	m.sent = append(m.sent, msg)
	return nil
}

// Sent returns a copy of every message sent so far.
func (m *Memory) Sent() []Message {
	m.mu.Lock()
	defer m.mu.Unlock()
	return append([]Message(nil), m.sent...)
}

// Last returns the last message sent to addr.
func (m *Memory) Last(addr string) (Message, bool) {
	m.mu.Lock()
	defer m.mu.Unlock()
	for i := len(m.sent) - 1; i >= 0; i-- {
		if strings.EqualFold(m.sent[i].To, addr) {
			return m.sent[i], true
		}
	}
	return Message{}, false
}

//go:embed templates/*.html
var templates embed.FS

var loginCodeHTML = template.Must(template.ParseFS(templates, "templates/login_code.html"))

// LoginCode is the bilingual sign-in code email.
func LoginCode(to, code string, ttl time.Duration) (Message, error) {
	minutes := int(ttl.Minutes())
	var html bytes.Buffer
	if err := loginCodeHTML.Execute(&html, map[string]any{"Code": code, "Minutes": minutes}); err != nil {
		return Message{}, err
	}
	text := fmt.Sprintf("Your sign-in code is %s\nIt expires in %d minutes. Never share this code with anyone.\n\n"+
		"তোমার সাইন-ইন কোড %s\nকোডটি %d মিনিট পর বাতিল হবে। কাউকে এই কোড দিও না।\n\n"+
		"If you didn't try to sign in, you can ignore this email.\n", code, minutes, code, minutes)
	return Message{To: to, Subject: "Your sign-in code: " + code, Text: text, HTML: html.String()}, nil
}
