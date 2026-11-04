import { afterAll, beforeAll, describe, expect, test } from 'bun:test';
import type { PhotoUploadResponse, PresignedPost } from '@velio/contracts';
import { json, testApp } from '../helpers/app';
import {
  activityBody,
  bookOk,
  createActivity,
  errorCode,
  inProcess,
  patchActivity,
  signIn,
  type Caller,
  type Requester,
} from '../helpers/api';
import { createTestDatabase, type TestDatabase } from '../helpers/db';

// Runs against the MinIO bucket from infra/docker-compose.yml (`velio-photos`).

let t: TestDatabase;
let request: Requester;
let amara: Caller;
let tunde: Caller;

beforeAll(async () => {
  t = await createTestDatabase();
  request = inProcess(testApp(t.db));
  amara = await signIn(request, 'Amara Okafor');
  tunde = await signIn(request, 'Tunde Adeyemi');
});

afterAll(async () => {
  await t.drop();
});

async function presign(caller: Caller, contentType = 'image/webp'): Promise<PhotoUploadResponse> {
  const res = await request('/api/uploads/photos', json({ contentType }, caller.headers));
  expect(res.status).toBe(201);
  return (await res.json()) as PhotoUploadResponse;
}

/** Posts like a browser form: the policy fields first, then the file. */
function upload(target: PresignedPost, bytes: number, type = 'image/webp') {
  const form = new FormData();
  for (const [k, v] of Object.entries(target.fields)) form.append(k, v);
  form.set('Content-Type', target.fields['Content-Type'] ?? type);
  form.append('file', new Blob([new Uint8Array(bytes)], { type }));
  return fetch(target.url, { method: 'POST', body: form });
}

async function uploaded(caller: Caller): Promise<string> {
  const { key, uploads } = await presign(caller);
  expect((await upload(uploads.large, 50_000)).status).toBe(204);
  expect((await upload(uploads.small, 20_000)).status).toBe(204);
  return key;
}

describe('POST /api/uploads/photos', () => {
  // V-PH-1 (FR-013, SEC-006)
  test('needs a session', async () => {
    const res = await request('/api/uploads/photos', json({ contentType: 'image/webp' }));
    expect(res.status).toBe(401);
  });

  test('rejects a type other than WebP, JPEG or AVIF', async () => {
    const res = await request('/api/uploads/photos', json({ contentType: 'image/gif' }, amara.headers));
    expect(res.status).toBe(400);
    expect(await errorCode(res)).toBe('validation_failed');
  });

  test('returns two targets under the caller, valid for 10 minutes', async () => {
    const before = Date.now();
    const body = await presign(amara, 'image/jpeg');
    expect(body.key).toMatch(new RegExp(`^${amara.id}/[0-9a-f-]{36}\\.jpg$`));
    expect(body.uploads.large.fields.key).toBe(`photos/${body.key}`);
    expect(body.uploads.small.fields.key).toBe(`photos/${body.key.replace('.jpg', '-640.jpg')}`);
    expect(body.uploads.large.fields['Content-Type']).toBe('image/jpeg');
    const ttl = new Date(body.expiresAt).getTime() - before;
    expect(ttl).toBeGreaterThan(9.9 * 60_000);
    expect(ttl).toBeLessThanOrEqual(10 * 60_000 + 1_000);
  });

  test('S3 accepts a 1 MB photo of the signed type', async () => {
    const { key, uploads } = await presign(amara);
    expect((await upload(uploads.large, 1024 * 1024)).status).toBe(204);
    // Readable without signing, as CloudFront serves it.
    const read = await fetch(`${uploads.large.url}/photos/${key}`);
    expect(read.status).toBe(200);
    expect(read.headers.get('content-type')).toBe('image/webp');
  });

  test('S3 refuses 3 MB, an empty file, another type and another key', async () => {
    const { uploads } = await presign(amara);
    expect((await upload(uploads.large, 3 * 1024 * 1024)).status).toBe(400);
    expect((await upload(uploads.large, 0)).status).toBe(400);

    const gif = { ...uploads.large, fields: { ...uploads.large.fields, 'Content-Type': 'image/gif' } };
    expect((await upload(gif, 1000, 'image/gif')).status).toBe(403);

    const elsewhere = {
      ...uploads.large,
      fields: { ...uploads.large.fields, key: `photos/${tunde.id}/x.webp` },
    };
    expect((await upload(elsewhere, 1000)).status).toBe(403);
  });
});

describe('photoKey on activities', () => {
  // V-PH-1 (FR-014, FR-015, SEC-006)
  test('create with an uploaded photo: the snapshot and cards return its URL', async () => {
    const key = await uploaded(amara);
    const activity = await createActivity(request, amara, { photoKey: key });
    expect((activity as unknown as { photoKey: string }).photoKey).toBe(key);

    const snapshot = (await (await request(`/api/activities/${activity.id}`)).json()) as { photoUrl: string };
    expect(snapshot.photoUrl).toBe(`/photos/${key}`);

    await bookOk(request, tunde, activity.id);
    const plans = (await (await request('/api/me/plans', { headers: tunde.headers })).json()) as {
      upcoming: { activity: { photoUrl: string } }[];
    };
    expect(plans.upcoming[0]!.activity.photoUrl).toBe(`/photos/${key}`);
  });

  test("rejects another person's photo and a key that was never uploaded", async () => {
    const tundes = await uploaded(tunde);
    let res = await request('/api/activities', json(activityBody({ photoKey: tundes }), amara.headers));
    expect(res.status).toBe(400);
    expect(await errorCode(res)).toBe('validation_failed');

    const { key: never } = await presign(amara);
    res = await request('/api/activities', json(activityBody({ photoKey: never }), amara.headers));
    expect(res.status).toBe(400);

    res = await request('/api/activities', json(activityBody({ photoKey: '../etc/passwd' }), amara.headers));
    expect(res.status).toBe(400);
  });

  test('the photo stays editable after a booking, and null removes it', async () => {
    const activity = await createActivity(request, amara);
    await bookOk(request, tunde, activity.id);

    const key = await uploaded(amara);
    let res = await patchActivity(request, amara, activity.id, { photoKey: key });
    expect(res.status).toBe(200);
    expect(((await res.json()) as { photoKey: string }).photoKey).toBe(key);

    res = await patchActivity(request, tunde, activity.id, { photoKey: await uploaded(tunde) });
    expect(res.status).toBe(403);

    res = await patchActivity(request, amara, activity.id, { photoKey: null });
    expect(res.status).toBe(200);
    const snapshot = (await (await request(`/api/activities/${activity.id}`)).json()) as { photoUrl: null };
    expect(snapshot.photoUrl).toBeNull();
  });
});
