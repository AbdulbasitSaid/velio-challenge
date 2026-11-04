// Runs before every page request (Next.js 16 "proxy", formerly middleware).
// 1. Production origin lockdown: only CloudFront, which adds X-Origin-Verify, may reach the web origin.
// 2. Device cookie: minted on first visit and made visible to this same request's server render.
import { timingSafeEqual } from 'node:crypto';
import { NextResponse, type NextRequest } from 'next/server';
import { DEVICE_COOKIE, DEVICE_ID, DEVICE_MAX_AGE } from './lib/device';

function originAllowed(req: NextRequest): boolean {
  const secret = process.env.ORIGIN_VERIFY_SECRET;
  if (process.env.NODE_ENV !== 'production' || !secret) return true;
  if (req.nextUrl.pathname === '/healthz') return true;
  const got = Buffer.from(req.headers.get('x-origin-verify') ?? '');
  const expected = Buffer.from(secret);
  return got.length === expected.length && timingSafeEqual(got, expected);
}

export function proxy(req: NextRequest) {
  if (!originAllowed(req)) return new NextResponse('Forbidden', { status: 403 });

  const existing = req.cookies.get(DEVICE_COOKIE)?.value;
  if (existing && DEVICE_ID.test(existing)) return NextResponse.next();

  const id = crypto.randomUUID();
  req.cookies.set(DEVICE_COOKIE, id);
  const res = NextResponse.next({ request: { headers: req.headers } });
  res.cookies.set(DEVICE_COOKIE, id, {
    maxAge: DEVICE_MAX_AGE,
    sameSite: 'lax',
    secure: process.env.NODE_ENV === 'production',
    httpOnly: false,
    path: '/',
  });
  return res;
}

export const config = {
  // Pages only: static assets and the API (proxied locally, routed by CloudFront in production) skip it.
  matcher: ['/((?!api/|_next/static|_next/image|favicon.ico|robots.txt).*)'],
};
