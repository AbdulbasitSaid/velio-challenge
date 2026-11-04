import { afterAll, beforeAll, describe, expect, test } from 'bun:test';
import { createDb } from '../../src/db/client';
import { testApp } from '../helpers/app';
import { createTestDatabase, type TestDatabase } from '../helpers/db';

let t: TestDatabase;
/** Nothing listens on port 1, so every query fails to connect. */
const downDb = createDb('postgres://velio_api@127.0.0.1:1/none', { max: 1 });

beforeAll(async () => {
  t = await createTestDatabase();
});

afterAll(async () => {
  await downDb.destroy();
  await t.drop();
});

// V-API-1 (FR-006)
describe('health', () => {
  test('healthz is 200 with the database down', async () => {
    const res = await testApp(downDb).request('/api/healthz');
    expect(res.status).toBe(200);
    expect(await res.json()).toEqual({ status: 'ok' });
  });

  test('readyz is 200 with the database up', async () => {
    const res = await testApp(t.db).request('/api/readyz');
    expect(res.status).toBe(200);
    expect(await res.json()).toEqual({ status: 'ok' });
  });

  test('readyz is 503 with the database down', async () => {
    const res = await testApp(downDb).request('/api/readyz');
    expect(res.status).toBe(503);
    expect(await res.json()).toEqual({ status: 'unavailable' });
  });
});

// V-API-2 (FR-010)
describe('error envelope', () => {
  test('an unknown error becomes internal with a requestId and no stack', async () => {
    const app = testApp(t.db);
    app.get('/boom', () => {
      throw new Error('secret internals at /srv/app.ts:42');
    });
    const res = await app.request('/api/boom');
    expect(res.status).toBe(500);
    const text = await res.text();
    const body = JSON.parse(text) as { error: { code: string; message: string; requestId: string } };
    expect(body.error.code).toBe('internal');
    expect(body.error.requestId).toMatch(/.+/);
    expect(text).not.toContain('secret internals');
    expect(text).not.toContain('.ts:');
  });

  test('the requestId matches the X-Request-Id response header', async () => {
    const res = await testApp(t.db).request('/api/me');
    const body = (await res.json()) as { error: { requestId: string } };
    expect(body.error.requestId).toBe(res.headers.get('x-request-id')!);
  });

  test('an unknown route is not_found', async () => {
    const res = await testApp(t.db).request('/api/nope');
    expect(res.status).toBe(404);
    expect(((await res.json()) as { error: { code: string } }).error.code).toBe('not_found');
  });

  test('the location_locked trigger maps to its error code', async () => {
    const app = testApp(t.db);
    app.get('/locked', () => {
      throw Object.assign(new Error('location_locked'), { code: 'VL001' });
    });
    const res = await app.request('/api/locked');
    expect(res.status).toBe(409);
    expect(((await res.json()) as { error: { code: string } }).error.code).toBe('location_locked');
  });
});

describe('origin lockdown', () => {
  const secret = 'origin-secret-0123456789abcdef0123456789';
  const prod = () =>
    testApp(t.db, undefined, {
      NODE_ENV: 'production',
      ORIGIN_VERIFY_SECRET: secret,
      PUBLIC_BASE_URL: 'https://example.cloudfront.net',
    });

  test('in production, requests without X-Origin-Verify are forbidden', async () => {
    const res = await prod().request('/api/readyz');
    expect(res.status).toBe(403);
    expect(((await res.json()) as { error: { code: string } }).error.code).toBe('forbidden');
  });

  test('in production, requests with the secret pass', async () => {
    const res = await prod().request('/api/readyz', { headers: { 'x-origin-verify': secret } });
    expect(res.status).toBe(200);
  });

  test('liveness is exempt', async () => {
    expect((await prod().request('/api/healthz')).status).toBe(200);
  });

  test('outside production, no header is needed', async () => {
    expect((await testApp(t.db).request('/api/readyz')).status).toBe(200);
  });
});
