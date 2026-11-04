# API image. Build from the repository root:
#   docker build -f apps/api/Dockerfile .
FROM oven/bun:1.4.4-slim

LABEL org.opencontainers.image.source=https://github.com/AbdulbasitSaid/velio-challenge

WORKDIR /app

# Every workspace manifest is needed for a frozen install; only production dependencies are kept.
COPY package.json bun.lock bunfig.toml tsconfig.base.json ./
COPY apps/api/package.json apps/api/
COPY apps/web/package.json apps/web/
COPY packages/contracts/package.json packages/contracts/
COPY packages/design-tokens/package.json packages/design-tokens/
COPY infra/aws/package.json infra/aws/
RUN bun install --frozen-lockfile --production

COPY packages/contracts packages/contracts
COPY apps/api/tsconfig.json apps/api/
COPY apps/api/src apps/api/src

ENV NODE_ENV=production
USER bun
EXPOSE 3001
CMD ["bun", "apps/api/src/index.ts"]
