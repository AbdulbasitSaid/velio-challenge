// Writes packages/contracts/openapi.json from the mounted routes. CI fails if the committed file differs.
import { resolve } from 'node:path';
import { createApp } from '../src/app';
import type { Db } from '../src/db/client';
import { loadConfig } from '../src/config';
import { createLogger } from '../src/telemetry/logger';

const app = createApp({
  // Route definitions only; nothing is served or queried.
  config: loadConfig({
    DATABASE_URL: 'postgres://unused/unused',
    DATABASE_LISTEN_URL: 'postgres://unused/unused',
    CONTACT_PEPPER: 'x'.repeat(32),
  }),
  db: {} as Db,
  logger: createLogger('silent'),
  clock: () => new Date(),
});

const doc = app.getOpenAPI31Document({
  openapi: '3.1.0',
  info: { title: 'Velio API', version: '0.1.0' },
});

const out = resolve(import.meta.dir, '../../../packages/contracts/openapi.json');
await Bun.write(out, `${JSON.stringify(doc, null, 2)}\n`);
console.log(`Wrote ${out}`);
