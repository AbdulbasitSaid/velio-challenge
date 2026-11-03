import { randomBytes } from 'node:crypto';
import postgres from 'postgres';
import { createDb, type Db } from '../../src/db/client';

/** Postgres from infra/docker-compose.yml. `velio_test` is migrated by `bun run db:migrate`. */
const HOST = process.env.TEST_POSTGRES_HOST ?? 'localhost:5432';
const TEMPLATE = 'velio_test';

export interface TestDatabase {
  name: string;
  /** Connection as the runtime role, velio_api. */
  url: string;
  db: Db;
  /** Superuser connection to this database, for setup and role switching. */
  admin: postgres.Sql;
  drop(): Promise<void>;
}

/** A fresh database per test file, cloned from the migrated template. */
export async function createTestDatabase(): Promise<TestDatabase> {
  const name = `velio_t_${randomBytes(6).toString('hex')}`;
  const server = postgres(`postgres://postgres@${HOST}/postgres`, { max: 1, onnotice: () => {} });
  await server.unsafe(`CREATE DATABASE ${name} TEMPLATE ${TEMPLATE}`);

  const url = `postgres://velio_api@${HOST}/${name}`;
  const db = createDb(url, { max: 5 });
  const admin = postgres(`postgres://postgres@${HOST}/${name}`, { max: 1, onnotice: () => {} });

  return {
    name,
    url,
    db,
    admin,
    async drop() {
      await db.destroy();
      await admin.end();
      await server.unsafe(`DROP DATABASE IF EXISTS ${name} WITH (FORCE)`);
      await server.end();
    },
  };
}
