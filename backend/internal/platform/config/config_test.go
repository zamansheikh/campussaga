package config

import "testing"

func TestReviewConfig(t *testing.T) {
	cases := []struct {
		name, email, code string
		ok                bool
	}{
		{"off", "", "", true},
		{"on", " Play-Review@Review.Example.com ", "123456", true},
		{"only email", "a@b.com", "", false},
		{"only code", "", "123456", false},
		{"short code", "a@b.com", "12345", false},
		{"letters", "a@b.com", "12345a", false},
		{"long code", "a@b.com", "1234567", false},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			t.Setenv("REVIEW_EMAIL", tc.email)
			t.Setenv("REVIEW_CODE", tc.code)
			c, err := Load()
			if (err == nil) != tc.ok {
				t.Fatalf("Load() error = %v, want ok=%v", err, tc.ok)
			}
			if tc.name == "on" && c.ReviewEmail != "play-review@review.example.com" {
				t.Fatalf("email not normalised: %q", c.ReviewEmail)
			}
		})
	}
}
