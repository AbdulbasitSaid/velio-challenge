import { ApiRequestError, apiFetch } from '@/lib/api/client';
import { safeNext } from '@/lib/session';
import { z } from 'zod';

function mockFetch(status: number, body: unknown) {
  const fn = vi.fn(async () => new Response(body === undefined ? null : JSON.stringify(body), { status }));
  vi.stubGlobal('fetch', fn);
  return fn;
}

afterEach(() => {
  vi.unstubAllGlobals();
  document.cookie = 'velio_device=; max-age=0';
});

describe('apiFetch', () => {
  test('sends the device ID, idempotency key and JSON body; parses the response', async () => {
    document.cookie = 'velio_device=dev-123';
    const fetch = mockFetch(201, { id: 'b1' });
    const out = await apiFetch('/activities/a/bookings', {
      method: 'POST',
      body: { x: 1 },
      idempotencyKey: 'key-1',
      schema: z.object({ id: z.string() }),
    });
    expect(out).toEqual({ id: 'b1' });
    const [url, init] = fetch.mock.calls[0] as unknown as [string, RequestInit];
    expect(url).toBe('/api/activities/a/bookings');
    const headers = init.headers as Record<string, string>;
    expect(headers['x-device-id']).toBe('dev-123');
    expect(headers['idempotency-key']).toBe('key-1');
    expect(headers['content-type']).toBe('application/json');
    expect(init.body).toBe('{"x":1}');
  });

  test('maps the error envelope to a typed code', async () => {
    mockFetch(409, { error: { code: 'sold_out', message: 'Sold out', requestId: 'req_1' } });
    const err = await apiFetch('/x').catch((e: unknown) => e);
    expect(err).toBeInstanceOf(ApiRequestError);
    expect(err).toMatchObject({ status: 409, code: 'sold_out', requestId: 'req_1' });
  });

  test('a non-envelope failure is internal', async () => {
    mockFetch(502, '<html>');
    await expect(apiFetch('/x')).rejects.toMatchObject({ status: 502, code: 'internal' });
  });

  test('a network failure is its own code', async () => {
    vi.stubGlobal(
      'fetch',
      vi.fn(async () => Promise.reject(new TypeError('Failed to fetch'))),
    );
    await expect(apiFetch('/x')).rejects.toMatchObject({ status: 0, code: 'network' });
  });

  test('a schema mismatch fails loudly outside production', async () => {
    mockFetch(200, { id: 1 });
    await expect(apiFetch('/x', { schema: z.object({ id: z.string() }) })).rejects.toThrow();
  });

  test('204 returns nothing', async () => {
    mockFetch(204, undefined);
    await expect(apiFetch('/sessions/current', { method: 'DELETE' })).resolves.toBeUndefined();
  });
});

describe('safeNext', () => {
  test.each([
    ['/plans/1', '/plans/1'],
    [undefined, '/me/plans'],
    ['https://evil.example', '/me/plans'],
    ['//evil.example', '/me/plans'],
    ['/\\evil.example', '/me/plans'],
    [['/a', '/b'], '/a'],
  ])('%o → %s', (input, expected) => {
    expect(safeNext(input)).toBe(expected);
  });
});
