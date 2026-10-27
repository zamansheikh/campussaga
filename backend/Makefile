SHELL := /bin/bash
GO    ?= go
BIN   := bin/campusapi
DEVDB := postgres://campus:campus@localhost:55632/campus?sslmode=disable

# Local overrides (git-ignored), e.g. SMTP settings.
-include .env
export

.PHONY: help deps-up deps-down run migrate seed build test test-short sqlc fmt vet lint check clean-testdbs

help: ## list targets
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN{FS=":.*?## "}{printf "  %-14s %s\n",$$1,$$2}'

deps-up: ## start local Postgres (:55632) and Mailpit (:58025)
	docker compose up -d --wait

deps-down: ## stop local deps (data kept)
	docker compose down

build: ## build the server binary
	CGO_ENABLED=0 $(GO) build -trimpath -ldflags="-s -w" -o $(BIN) ./cmd/campusapi

run: ## run on :8090 against local deps (applies migrations first)
	$(GO) run ./cmd/campusapi serve

migrate: ## apply migrations to DATABASE_URL (default: local dev db)
	$(GO) run ./cmd/campusapi migrate

seed: migrate ## load development universities (demo.ac.bd, sit.edu.bd)
	psql "$(DEVDB)" -v ON_ERROR_STOP=1 -q -f seed/dev.sql

sqlc: ## regenerate every module's store/ from its sqlc.yaml
	@for f in $$(find internal -name sqlc.yaml); do echo "sqlc $$f"; (cd $$(dirname $$f) && sqlc generate) || exit 1; done

fmt: ## format code
	gofmt -w cmd internal migrations

vet:
	$(GO) vet ./...

lint: ## golangci-lint (skipped with a notice if not installed)
	@if command -v golangci-lint >/dev/null; then golangci-lint run ./...; else echo "golangci-lint not installed, skipping"; fi

test: ## all tests (needs deps-up)
	$(GO) test -race -count=1 ./...

test-short: ## tests without -race
	$(GO) test -count=1 ./...

check: ## what CI runs
	@test -z "$$(gofmt -l cmd internal migrations)" || (gofmt -l cmd internal migrations; echo "gofmt needed"; exit 1)
	$(MAKE) vet lint test

clean-testdbs: ## drop leftover test databases/templates
	@psql "$(DEVDB)" -Atc "SELECT datname FROM pg_database WHERE datname ~ '^(t_|tmpl_)'" | while read d; do \
	    psql "$(DEVDB)" -qc "ALTER DATABASE $$d WITH IS_TEMPLATE false" 2>/dev/null; \
	    psql "$(DEVDB)" -qc "DROP DATABASE IF EXISTS $$d WITH (FORCE)"; done
