// Package ratelimit is a fixed-window limiter kept in process memory. The
// API runs as one process, so a shared store (Redis) would add a network hop
// to every limited request and buy nothing. Move to Redis only when running
// more than one API instance.
package ratelimit

import (
	"sync"
	"time"
)

// Limiter counts hits per key per window.
type Limiter struct {
	mu      sync.Mutex
	windows map[string]*window
	now     func() time.Time
	sweepAt time.Time
}

type window struct {
	start time.Time
	size  time.Duration
	count int
}

// New makes a limiter; now may be nil.
func New(now func() time.Time) *Limiter {
	if now == nil {
		now = time.Now
	}
	return &Limiter{windows: map[string]*window{}, now: now}
}

// Allow counts one hit on key and reports whether it is within limit per
// size window, and if not, how long until the window resets.
func (l *Limiter) Allow(key string, limit int, size time.Duration) (bool, time.Duration) {
	now := l.now()
	l.mu.Lock()
	defer l.mu.Unlock()
	if now.After(l.sweepAt) {
		l.sweep(now)
		l.sweepAt = now.Add(time.Minute)
	}
	w := l.windows[key]
	if w == nil || now.Sub(w.start) >= w.size {
		w = &window{start: now, size: size}
		l.windows[key] = w
	}
	w.count++
	if w.count > limit {
		return false, w.start.Add(w.size).Sub(now)
	}
	return true, 0
}

func (l *Limiter) sweep(now time.Time) {
	for k, w := range l.windows {
		if now.Sub(w.start) >= w.size {
			delete(l.windows, k)
		}
	}
}
