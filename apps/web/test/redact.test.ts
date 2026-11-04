import { redactAttributes, redactText } from '@/lib/telemetry/redact';

test.each([
  ['fetch GET http://api:3001/api/invites/K7PQ2N', 'fetch GET http://api:3001/api/invites/:code'],
  ['GET /i/K7PQ2N/claim', 'GET /i/:code/claim'],
  ['GET /plans/0190a6f2-1f2b-7c3d-8e4f-5a6b7c8d9e0f', 'GET /plans/:id'],
  ['GET /signin?next=%2Fplans%2Fx', 'GET /signin'],
  ['GET /i/[code]', 'GET /i/:code'],
  ['render route (app) /communities/[slug]', 'render route (app) /communities/[slug]'],
])('%s → %s', (input, expected) => {
  expect(redactText(input)).toBe(expected);
});

test('URL attributes are templated; query, headers and user agent are dropped', () => {
  expect(
    redactAttributes({
      'http.target': '/i/K7PQ2N?ref=wa',
      'url.full': 'http://api:3001/api/plans/0190a6f2-1f2b-7c3d-8e4f-5a6b7c8d9e0f',
      'url.query': 'next=/x',
      'http.request.header.cookie': 'velio_session=secret',
      'user_agent.original': 'WhatsApp/2',
      'http.method': 'GET',
      'http.status_code': 200,
    }),
  ).toEqual({
    'http.target': '/i/:code',
    'url.full': 'http://api:3001/api/plans/:id',
    'http.method': 'GET',
    'http.status_code': 200,
  });
});
