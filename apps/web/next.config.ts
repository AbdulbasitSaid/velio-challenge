import path from 'node:path';
import type { NextConfig } from 'next';

// Locally the browser talks to Next on :3000 and Next proxies /api/* to the API. In production CloudFront
// routes /api/* to the API directly, so the rewrite never runs there.
const apiUrl = process.env.API_INTERNAL_URL ?? 'http://localhost:3001';
// Photos are `/photos/<key>` (CloudFront → bucket in production); locally Next serves them from MinIO.
const photosUrl = 'http://localhost:9000/velio-photos/photos';

// S5 §4.11 and Maps §6. Photos and the API are same-origin (CloudFront). Google Maps needs its script,
// tile and API hosts. Inline scripts are Next's hydration payload ('unsafe-inline' until nonces are worth
// a dynamic-only render); dev adds 'unsafe-eval' for React's tooling and the API socket on :3001.
const google =
  'https://maps.googleapis.com https://maps.gstatic.com https://*.googleapis.com https://*.gstatic.com';
const dev = process.env.NODE_ENV !== 'production';
const csp = [
  "default-src 'self'",
  `script-src 'self' 'unsafe-inline'${dev ? " 'unsafe-eval'" : ''} ${google}`,
  `style-src 'self' 'unsafe-inline' https://fonts.googleapis.com`,
  `img-src 'self' data: blob: ${google}`,
  "font-src 'self' https://fonts.gstatic.com",
  // Photo uploads POST straight to the bucket (presigned, S5 §4.9).
  `connect-src 'self' ${dev ? 'ws://localhost:3001 http://localhost:9000 ' : ''}https://*.s3.eu-west-2.amazonaws.com ${google}`,
  "worker-src 'self' blob:",
  "frame-ancestors 'none'",
  "base-uri 'self'",
  "form-action 'self'",
  "object-src 'none'",
].join('; ');

const securityHeaders = [
  { key: 'Content-Security-Policy', value: csp },
  { key: 'Referrer-Policy', value: 'strict-origin-when-cross-origin' },
  { key: 'X-Content-Type-Options', value: 'nosniff' },
  { key: 'Permissions-Policy', value: 'camera=(), microphone=(), geolocation=(self), payment=()' },
];

const config: NextConfig = {
  output: 'standalone',
  outputFileTracingRoot: path.join(import.meta.dirname, '../..'),
  // Workspace packages ship TypeScript source.
  transpilePackages: ['@velio/contracts', '@velio/design-tokens'],
  poweredByHeader: false,
  async rewrites() {
    return [
      { source: '/api/:path*', destination: `${apiUrl}/api/:path*` },
      ...(dev ? [{ source: '/photos/:path*', destination: `${photosUrl}/:path*` }] : []),
    ];
  },
  async headers() {
    return [{ source: '/:path*', headers: securityHeaders }];
  },
};

export default config;
