// Package config reads the process configuration from the environment once,
// at start-up. Every setting has a development default except the secrets,
// which must be set (and strong) in production.
package config

import (
	"errors"
	"fmt"
	"os"
	"strconv"
	"strings"
	"time"
)

// Config is the whole process configuration.
type Config struct {
	Env       string // development | production
	Addr      string // listen address, e.g. ":8090"
	APIPrefix string // "/api/v1"

	DatabaseURL string
	DBMaxConns  int32

	// JWTSecret signs access tokens. CodeSecret keys the HMAC that stores
	// email codes. Different secrets, so one leaking does not expose the other.
	JWTSecret  []byte
	CodeSecret []byte

	AccessTTL  time.Duration
	RefreshTTL time.Duration

	// Email sign-in codes.
	CodeTTL         time.Duration
	CodeResendAfter time.Duration
	CodeMaxPerHour  int
	CodeMaxAttempts int

	// SMTP. Development defaults point at Mailpit from docker-compose.
	SMTPHost     string
	SMTPPort     int
	SMTPUsername string
	SMTPPassword string
	MailFrom     string

	// FirebaseProjectID enables Google sign-in (POST /auth/google): ID tokens
	// must be issued for this Firebase project. Empty = Google sign-in off.
	FirebaseProjectID string

	// FCMCredentialsFile is a Firebase service-account key (JSON) used to
	// send push notifications. Empty = pushes are only logged (development).
	// Never commit the file; keep it outside the repo or in a git-ignored path.
	FCMCredentialsFile string

	ShutdownTimeout time.Duration
}

func (c *Config) IsProduction() bool { return c.Env == "production" }

const devSecret = "dev-only-secret-change-me-dev-only-secret"

// Load reads the environment.
func Load() (*Config, error) {
	env := get("APP_ENV", "development")
	c := &Config{
		Env:                env,
		Addr:               get("ADDR", ":8090"),
		APIPrefix:          get("API_PREFIX", "/api/v1"),
		DatabaseURL:        get("DATABASE_URL", "postgres://campus:campus@localhost:55632/campus?sslmode=disable"),
		DBMaxConns:         int32(getInt("DB_MAX_CONNS", 10)),
		JWTSecret:          []byte(get("JWT_SECRET", devSecret)),
		CodeSecret:         []byte(get("CODE_HMAC_SECRET", devSecret+"-codes")),
		AccessTTL:          getDuration("ACCESS_TTL", 15*time.Minute),
		RefreshTTL:         getDuration("REFRESH_TTL", 60*24*time.Hour),
		CodeTTL:            getDuration("CODE_TTL", 10*time.Minute),
		CodeResendAfter:    getDuration("CODE_RESEND_AFTER", 60*time.Second),
		CodeMaxPerHour:     getInt("CODE_MAX_PER_HOUR", 5),
		CodeMaxAttempts:    getInt("CODE_MAX_ATTEMPTS", 5),
		SMTPHost:           get("SMTP_HOST", "localhost"),
		SMTPPort:           getInt("SMTP_PORT", 55625),
		SMTPUsername:       get("SMTP_USERNAME", ""),
		SMTPPassword:       get("SMTP_PASSWORD", ""),
		MailFrom:           get("MAIL_FROM", "Campus Saga <no-reply@campussaga.local>"),
		FirebaseProjectID:  get("FIREBASE_PROJECT_ID", ""),
		FCMCredentialsFile: get("FCM_CREDENTIALS_FILE", ""),
		ShutdownTimeout:    getDuration("SHUTDOWN_TIMEOUT", 15*time.Second),
	}
	return c, c.validate()
}

func (c *Config) validate() error {
	var errs []error
	if c.Env != "development" && c.Env != "production" {
		errs = append(errs, fmt.Errorf("APP_ENV must be development or production, got %q", c.Env))
	}
	if !strings.HasPrefix(c.APIPrefix, "/") {
		errs = append(errs, errors.New("API_PREFIX must start with /"))
	}
	if c.IsProduction() {
		for name, s := range map[string][]byte{"JWT_SECRET": c.JWTSecret, "CODE_HMAC_SECRET": c.CodeSecret} {
			if len(s) < 32 || strings.HasPrefix(string(s), "dev-only") {
				errs = append(errs, fmt.Errorf("%s must be set to at least 32 random characters in production", name))
			}
		}
		if string(c.JWTSecret) == string(c.CodeSecret) {
			errs = append(errs, errors.New("JWT_SECRET and CODE_HMAC_SECRET must differ"))
		}
		if os.Getenv("SMTP_HOST") == "" || os.Getenv("MAIL_FROM") == "" {
			errs = append(errs, errors.New("SMTP_HOST and MAIL_FROM must be set in production"))
		}
		if os.Getenv("DATABASE_URL") == "" {
			errs = append(errs, errors.New("DATABASE_URL must be set in production"))
		}
	}
	if c.CodeMaxAttempts < 1 || c.CodeMaxPerHour < 1 {
		errs = append(errs, errors.New("CODE_MAX_ATTEMPTS and CODE_MAX_PER_HOUR must be at least 1"))
	}
	return errors.Join(errs...)
}

func get(key, def string) string {
	if v, ok := os.LookupEnv(key); ok && v != "" {
		return v
	}
	return def
}

func getInt(key string, def int) int {
	if v := os.Getenv(key); v != "" {
		if n, err := strconv.Atoi(v); err == nil {
			return n
		}
	}
	return def
}

func getDuration(key string, def time.Duration) time.Duration {
	if v := os.Getenv(key); v != "" {
		if d, err := time.ParseDuration(v); err == nil {
			return d
		}
	}
	return def
}
