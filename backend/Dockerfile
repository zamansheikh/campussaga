# syntax=docker/dockerfile:1
FROM golang:1.26-alpine AS build
WORKDIR /src
COPY go.mod go.sum ./
RUN --mount=type=cache,target=/go/pkg/mod go mod download
COPY . .
RUN --mount=type=cache,target=/go/pkg/mod --mount=type=cache,target=/root/.cache/go-build \
    CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /out/campusapi ./cmd/campusapi

FROM gcr.io/distroless/static-debian12:nonroot
COPY --from=build /out/campusapi /campusapi
ENV APP_ENV=production TZ=UTC ADDR=:8090
EXPOSE 8090
USER nonroot
# serve | migrate
ENTRYPOINT ["/campusapi"]
CMD ["serve"]
