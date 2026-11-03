# Migrate image (production): dbmate plus the migrations. Build from the repository root:
#   docker build -f apps/api/migrate.Dockerfile .
FROM amacneil/dbmate:2.37.0

LABEL org.opencontainers.image.source=https://github.com/AbdulbasitSaid/velio-challenge

COPY apps/api/migrations /db/migrations
COPY apps/api/scripts/migrate-prod.sh /usr/local/bin/migrate-prod

ENV DBMATE_MIGRATIONS_DIR=/db/migrations \
    DBMATE_NO_DUMP_SCHEMA=true \
    DBMATE_WAIT=true

ENTRYPOINT ["/usr/local/bin/migrate-prod"]
