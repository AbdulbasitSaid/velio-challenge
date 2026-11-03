import { afterAll, beforeAll, describe, expect, test } from 'bun:test';
import { createHash } from 'node:crypto';
import { deleteExpiredSessions } from '../../src/modules/identity/sessions';
import { json, sessionCookie, testApp, testClock } from '../helpers/app';
import { createTestDatabase, type TestDatabase } from '../helpers/db';

let t: TestDatabase;

beforeAll(async () => {
  t = await createTestDatabase();
});

afterAll(async () => {
  await t.drop();
});

const signIn = (app: ReturnType<typeof testApp>, contact: string, headers: Record<string, string> = {}) =>
  app.request('/api/sessions', json({ displayName: 'Zainab Bello', contact }, headers));

const bearer = (token: string) => ({ headers: { authorization: `Bearer ${token}` } });
const cookie = (token: string) => ({ headers: { cookie: `velio_session=${token}` } });

describe('POST /api/sessions', () => {
  // V-ID-2 (AC-003)
  test('the same email in different formats maps to one user', async () => {
    const app = testApp(t.db);
    const first = await signIn(app, 'Zainab@Example.com ');
    const second = await signIn(app, 'zainab@example.com');
    expect(first.status).toBe(201);
    expect(second.status).toBe(201);
    const a = (await first.json()) as { user: { id: string } };
    const b = (await second.json()) as { user: { id: string } };
    expect(a.user.id).toBe(b.user.id);
  });

  test('a phone with and without its country code maps to one user', async () => {
    const app = testApp(t.db);
    const a = await (await signIn(app, '+254 712 345 678')).json();
    const b = await (
      await app.request('/api/sessions', json({ displayName: 'Z', contact: '0712345678', country: 'KE' }))
    ).json();
    expect((a as { user: { id: string } }).user.id).toBe((b as { user: { id: string } }).user.id);
  });

  test('a new user starts at generation 0', async () => {
    const app = testApp(t.db);
    const res = await signIn(app, 'new-person@example.com');
    const { user } = (await res.json()) as { user: { id: string } };
    const [row] = await t.admin`SELECT invite_generation FROM users WHERE id = ${user.id}`;
    expect(row!.invite_generation).toBe(0);
  });

  test('an invalid contact returns invalid_contact', async () => {
    const res = await signIn(testApp(t.db), 'not a contact');
    expect(res.status).toBe(400);
    const body = (await res.json()) as { error: { code: string; requestId: string } };
    expect(body.error.code).toBe('invalid_contact');
    expect(body.error.requestId).toBeString();
  });

  test('a missing field returns validation_failed without echoing values', async () => {
    const res = await testApp(t.db).request('/api/sessions', json({ contact: 'secret@example.com' }));
    expect(res.status).toBe(400);
    const text = await res.text();
    expect(JSON.parse(text).error.code).toBe('validation_failed');
    expect(text).not.toContain('secret@example.com');
  });

  test('malformed JSON returns validation_failed', async () => {
    const res = await testApp(t.db).request('/api/sessions', {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: '{not json',
    });
    expect(res.status).toBe(400);
    expect(((await res.json()) as { error: { code: string } }).error.code).toBe('validation_failed');
  });
});

// V-ID-3 (FR-007, FR-008, SEC-002)
describe('web cookie and mobile bearer flows', () => {
  test('web gets an httpOnly cookie and no token in the body', async () => {
    const app = testApp(t.db);
    const res = await signIn(app, 'web@example.com');
    const setCookie = res.headers.get('set-cookie') ?? '';
    expect(setCookie).toContain('HttpOnly');
    expect(setCookie).toContain('Secure');
    expect(setCookie).toContain('SameSite=Lax');
    expect(setCookie).toContain('Path=/');
    expect(setCookie).toContain(`Max-Age=${30 * 86_400}`);
    const body = (await res.json()) as { token?: string };
    expect(body.token).toBeUndefined();

    const me = await app.request('/api/me', cookie(sessionCookie(res)!));
    expect(me.status).toBe(200);
    expect(await me.json()).toEqual({
      id: expect.any(String),
      shortName: 'Zainab B.',
      avatarSeed: expect.any(String),
      displayName: 'Zainab Bello',
    });
  });

  test('mobile gets a bearer token and no cookie', async () => {
    const app = testApp(t.db);
    const res = await signIn(app, 'mobile@example.com', { 'x-client': 'mobile' });
    expect(res.headers.get('set-cookie')).toBeNull();
    const { token, user } = (await res.json()) as { token: string; user: unknown };
    expect(token).toMatch(/^[A-Za-z0-9_-]{43}$/);

    const me = await app.request('/api/me', bearer(token));
    expect(me.status).toBe(200);
    expect(await me.json()).toEqual(user);
  });
});

// V-ID-4 (FR-008)
describe('GET /api/me without a valid session', () => {
  const unauthenticated = async (res: Response) => {
    expect(res.status).toBe(401);
    expect(((await res.json()) as { error: { code: string } }).error.code).toBe('unauthenticated');
  };

  test('no token', async () => {
    await unauthenticated(await testApp(t.db).request('/api/me'));
  });

  test('an unknown token', async () => {
    await unauthenticated(await testApp(t.db).request('/api/me', bearer('x'.repeat(43))));
  });

  test('a deleted session', async () => {
    const app = testApp(t.db);
    const { token } = (await (await signIn(app, 'deleted@example.com', { 'x-client': 'mobile' })).json()) as {
      token: string;
    };
    await t.admin`DELETE FROM sessions`;
    await unauthenticated(await app.request('/api/me', bearer(token)));
  });
});

// V-ID-5 (SEC-001, SEC-002)
describe('storage', () => {
  test('no raw contact or token is stored; hashes are 32 bytes', async () => {
    const app = testApp(t.db);
    const contact = 'stored-check@example.com';
    const { token, user } = (await (await signIn(app, contact, { 'x-client': 'mobile' })).json()) as {
      token: string;
      user: { id: string };
    };

    const [u] =
      await t.admin`SELECT row_to_json(users)::text AS j, octet_length(contact_hash) AS n FROM users WHERE id = ${user.id}`;
    expect(u!.n).toBe(32);
    expect(u!.j).not.toContain(contact);

    const sessions =
      await t.admin`SELECT token_hash, row_to_json(sessions)::text AS j FROM sessions WHERE user_id = ${user.id}`;
    expect(sessions).toHaveLength(1);
    expect(sessions[0]!.token_hash.length).toBe(32);
    expect(sessions[0]!.j).not.toContain(token);
    expect(Buffer.from(sessions[0]!.token_hash).equals(createHash('sha256').update(token).digest())).toBe(
      true,
    );
  });
});

// V-ID-6 (FR-013, AC-006)
describe('session lifetime', () => {
  const mobileSignIn = async (app: ReturnType<typeof testApp>, contact: string) =>
    ((await (await signIn(app, contact, { 'x-client': 'mobile' })).json()) as { token: string }).token;

  const expiry = async (token: string) => {
    const [row] = await t.admin`
      SELECT expires_at, last_renewed_at FROM sessions
      WHERE token_hash = ${createHash('sha256').update(token).digest()}`;
    return row as { expires_at: Date; last_renewed_at: Date };
  };

  test('used at day 29, the idle expiry slides forward', async () => {
    const clock = testClock();
    const app = testApp(t.db, clock.now);
    const token = await mobileSignIn(app, 'slide@example.com');
    clock.advanceDays(29);
    expect((await app.request('/api/me', bearer(token))).status).toBe(200);
    const { expires_at } = await expiry(token);
    expect(expires_at.getTime()).toBe(clock.now().getTime() + 30 * 86_400_000);
  });

  test('idle for 31 days, the session is rejected', async () => {
    const clock = testClock();
    const app = testApp(t.db, clock.now);
    const token = await mobileSignIn(app, 'idle@example.com');
    clock.advanceDays(31);
    expect((await app.request('/api/me', bearer(token))).status).toBe(401);
  });

  test('kept active, the session still ends at day 90', async () => {
    const clock = testClock();
    const app = testApp(t.db, clock.now);
    const token = await mobileSignIn(app, 'absolute@example.com');
    // Weekly use up to day 84, so the idle expiry (day 114) is never the reason.
    for (let day = 7; day <= 84; day += 7) {
      clock.advanceDays(7);
      expect((await app.request('/api/me', bearer(token))).status).toBe(200);
    }
    clock.advanceDays(7); // day 91
    expect((await app.request('/api/me', bearer(token))).status).toBe(401);
  });

  test('the idle expiry never extends past the absolute expiry', async () => {
    const clock = testClock();
    const app = testApp(t.db, clock.now);
    const token = await mobileSignIn(app, 'cap@example.com');
    for (let day = 0; day < 85; day += 5) {
      await app.request('/api/me', bearer(token));
      clock.advanceDays(5);
    }
    await app.request('/api/me', bearer(token));
    const { expires_at } = await expiry(token);
    expect(expires_at.getTime()).toBe(testClock().now().getTime() + 90 * 86_400_000);
  });

  test('two requests within 24 hours renew once', async () => {
    const clock = testClock();
    const app = testApp(t.db, clock.now);
    const token = await mobileSignIn(app, 'renew-once@example.com');
    clock.advanceDays(2);
    await app.request('/api/me', bearer(token));
    const first = await expiry(token);
    clock.advanceDays(0.5);
    await app.request('/api/me', bearer(token));
    const second = await expiry(token);
    expect(second.last_renewed_at.getTime()).toBe(first.last_renewed_at.getTime());
    expect(second.expires_at.getTime()).toBe(first.expires_at.getTime());
  });

  test('a renewed web session refreshes its cookie', async () => {
    const clock = testClock();
    const app = testApp(t.db, clock.now);
    const token = sessionCookie(await signIn(app, 'cookie-renew@example.com'))!;
    clock.advanceDays(2);
    const res = await app.request('/api/me', cookie(token));
    expect(sessionCookie(res)).toBe(token);
    expect(res.headers.get('set-cookie')).toContain(`Max-Age=${30 * 86_400}`);
    // Within the same day: no renewal, no cookie.
    expect((await app.request('/api/me', cookie(token))).headers.get('set-cookie')).toBeNull();
  });

  test('expired sessions are purged', async () => {
    const clock = testClock();
    const app = testApp(t.db, clock.now);
    await mobileSignIn(app, 'purge@example.com');
    clock.advanceDays(400);
    expect(await deleteExpiredSessions(t.db, clock.now())).toBeGreaterThan(0);
  });
});

// V-ID-7 (FR-014)
describe('rotation and sign-out', () => {
  test('signing in again revokes the session sent with the request', async () => {
    const app = testApp(t.db);
    const old = sessionCookie(await signIn(app, 'rotate@example.com'))!;
    const res = await signIn(app, 'rotate@example.com', { cookie: `velio_session=${old}` });
    const fresh = sessionCookie(res)!;
    expect(fresh).not.toBe(old);
    expect((await app.request('/api/me', cookie(old))).status).toBe(401);
    expect((await app.request('/api/me', cookie(fresh))).status).toBe(200);
  });

  test('sign-out revokes the token and clears the cookie', async () => {
    const app = testApp(t.db);
    const token = sessionCookie(await signIn(app, 'signout@example.com'))!;
    const res = await app.request('/api/sessions/current', { method: 'DELETE', ...cookie(token) });
    expect(res.status).toBe(204);
    expect(res.headers.get('set-cookie')).toMatch(/velio_session=;.*Max-Age=0/);
    expect((await app.request('/api/me', cookie(token))).status).toBe(401);
  });

  test('sign-out without a session is unauthenticated', async () => {
    const res = await testApp(t.db).request('/api/sessions/current', { method: 'DELETE' });
    expect(res.status).toBe(401);
  });
});
