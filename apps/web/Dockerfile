# varsitykotha.com: Next.js standalone server (public pages + /admin).
# Build: docker build -t campussaga-web apps/web
# Needs internet at build time (npm ci, Google Fonts are self-hosted by next/font).

FROM node:24-alpine AS deps
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --no-audit --no-fund

FROM node:24-alpine AS build
WORKDIR /app
ENV NEXT_TELEMETRY_DISABLED=1
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN npm run build

FROM node:24-alpine AS run
WORKDIR /app
ENV NODE_ENV=production \
    NEXT_TELEMETRY_DISABLED=1 \
    PORT=7031 \
    HOSTNAME=0.0.0.0
# Only the self-contained server and its static files; no source, no dev deps.
COPY --from=build --chown=node:node /app/.next/standalone ./
COPY --from=build --chown=node:node /app/.next/static ./.next/static
USER node
EXPOSE 7031
HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD wget -q -O /dev/null http://127.0.0.1:7031/robots.txt || exit 1
CMD ["node", "server.js"]
