# syntax=docker/dockerfile:1
FROM golang:1.26-alpine AS build
WORKDIR /src
COPY go.mod go.sum ./
RUN --mount=type=cache,target=/go/pkg/mod go mod download
COPY . .
RUN --mount=type=cache,target=/go/pkg/mod --mount=type=cache,target=/root/.cache/go-build \
    CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /out/campusapi ./cmd/campusapi
# Campus Voice photos: an empty directory the media volume starts from, owned
# by the nonroot user (65532) so the API can write to it.
RUN mkdir -p /out/media

FROM gcr.io/distroless/static-debian12:nonroot
COPY --from=build /out/campusapi /campusapi
COPY --from=build --chown=65532:65532 /out/media /data/media
ENV APP_ENV=production TZ=UTC ADDR=:8090
EXPOSE 8090
USER nonroot
# serve | migrate
ENTRYPOINT ["/campusapi"]
CMD ["serve"]
