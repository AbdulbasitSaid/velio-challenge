import { inviteView } from './fixtures';

const incoming = new Headers({
  cookie: 'velio_session=s; velio_device=dev-1',
  'x-forwarded-for': '203.0.113.9',
  traceparent: '00-abc-def-01',
  'user-agent': 'Mozilla/5.0',
});

vi.mock('next/headers', () => ({
  headers: async () => incoming,
  cookies: async () => ({ get: (n: string) => (n === 'velio_device' ? { value: 'dev-1' } : undefined) }),
}));

const serverFetch = vi.fn();
vi.mock('@/lib/api/server', async (orig) => ({
  ...(await orig<typeof import('@/lib/api/server')>()),
  serverFetch: (...args: unknown[]) => serverFetch(...args),
}));

afterEach(() => {
  serverFetch.mockReset();
  vi.unstubAllEnvs();
});

test('SSR forwards cookie, device ID, client IP and trace context, and adds the origin header (V-SSR-1)', async () => {
  vi.stubEnv('ORIGIN_VERIFY_SECRET', 'origin-secret');
  const { serverTransport } = await vi.importActual<typeof import('@/lib/api/server')>('@/lib/api/server');
  expect(await serverTransport.headers()).toEqual({
    cookie: 'velio_session=s; velio_device=dev-1',
    'x-device-id': 'dev-1',
    'x-forwarded-for': '203.0.113.9',
    traceparent: '00-abc-def-01',
    'user-agent': 'Mozilla/5.0',
    'x-origin-verify': 'origin-secret',
  });
});

describe('Open Graph metadata (V-OG-1)', () => {
  const params = (code: string) => ({ params: Promise.resolve({ code }) });

  test('vouch preview names the inviter; never indexed', async () => {
    vi.stubEnv('PUBLIC_BASE_URL', 'https://example.cloudfront.net');
    serverFetch.mockResolvedValue(inviteView({}, { photoUrl: '/photos/p/1280.webp' }));
    const { generateMetadata } = await import('@/app/i/[code]/page');
    const m = await generateMetadata(params('K7PQ2N'));
    expect(m.title).toBe('Tunde wants you on Sunset Kayaking');
    expect(m.robots).toEqual({ index: false, follow: false });
    expect(m.openGraph).toMatchObject({
      url: 'https://example.cloudfront.net/i/K7PQ2N',
      images: [{ url: 'https://example.cloudfront.net/photos/p/1280.webp', alt: 'Sunset Kayaking' }],
    });
    expect(m.twitter).toMatchObject({ card: 'summary_large_image' });
    expect(String(m.description)).toContain('Nairobi time');
  });

  test('public preview', async () => {
    serverFetch.mockResolvedValue(inviteView({ rail: 'public' }));
    const { generateMetadata } = await import('@/app/i/[code]/page');
    expect((await generateMetadata(params('K7PQ2N'))).title).toBe('Join the group going to Sunset Kayaking');
  });

  test('unknown code: neutral and noindex', async () => {
    const { ApiRequestError } = await import('@/lib/api/client');
    serverFetch.mockRejectedValue(new ApiRequestError(404, 'invalid_code', 'x'));
    const { generateMetadata } = await import('@/app/i/[code]/page');
    expect(await generateMetadata(params('ABCDEF'))).toEqual({
      title: 'Invite',
      robots: { index: false, follow: false },
    });
  });
});
