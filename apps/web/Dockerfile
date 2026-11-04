# Web image (S5 §4.11). Build from the repository root:
#   docker build -f apps/web/Dockerfile .
# Dependencies install with Bun (the workspace's package manager); Next.js builds and runs on Node LTS.
FROM node:26.13.0-slim@sha256:e4db4c914bf8ad241bd24804fc25d272d89bad97e68cdc8a1414862790a02c39 AS build
COPY --from=oven/bun:1.4.4-slim@sha256:1846adf22496bd711036aae8be147e57bdebbaea2e5264e3e0b5af1db187d9a4 /usr/local/bin/bun /usr/local/bin/bun

WORKDIR /app
COPY package.json bun.lock bunfig.toml tsconfig.base.json ./
COPY apps/api/package.json apps/api/
COPY apps/web/package.json apps/web/
COPY packages/contracts/package.json packages/contracts/
COPY packages/design-tokens/package.json packages/design-tokens/
COPY infra/aws/package.json infra/aws/
RUN bun install --frozen-lockfile

COPY packages/contracts packages/contracts
COPY packages/design-tokens packages/design-tokens
COPY apps/web apps/web
# Public values only: the browser Maps key is restricted by referrer (S5 SEC-005).
ARG NEXT_PUBLIC_GOOGLE_MAPS_BROWSER_KEY=""
ENV NEXT_TELEMETRY_DISABLED=1 NEXT_PUBLIC_GOOGLE_MAPS_BROWSER_KEY=$NEXT_PUBLIC_GOOGLE_MAPS_BROWSER_KEY
RUN cd apps/web && node node_modules/next/dist/bin/next build

FROM node:26.13.0-slim@sha256:e4db4c914bf8ad241bd24804fc25d272d89bad97e68cdc8a1414862790a02c39

LABEL org.opencontainers.image.source=https://github.com/AbdulbasitSaid/velio-challenge

WORKDIR /app
ENV NODE_ENV=production NEXT_TELEMETRY_DISABLED=1 PORT=3000 HOSTNAME=0.0.0.0
# Standalone output: a traced server and only the node_modules it needs.
COPY --from=build --chown=node:node /app/apps/web/.next/standalone ./
COPY --from=build --chown=node:node /app/apps/web/.next/static ./apps/web/.next/static
USER node
EXPOSE 3000
CMD ["node", "apps/web/server.js"]
