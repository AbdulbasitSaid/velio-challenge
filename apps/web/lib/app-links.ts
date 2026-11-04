// Deep-link association files (S6 §4.7). Values come from configuration so S7 fills them without a code
// change; with none set the routes return 404. iOS stays unset: no Apple Developer account (S7 §12 Q1).
const list = (v: string | undefined) =>
  (v ?? '')
    .split(',')
    .map((s) => s.trim())
    .filter(Boolean);

const HEADERS = { 'content-type': 'application/json', 'cache-control': 'public, max-age=3600' };

export function assetLinks(env: Record<string, string | undefined> = process.env): Response {
  const pkg = env.ANDROID_PACKAGE?.trim();
  const certs = list(env.ANDROID_CERT_SHA256);
  if (!pkg || !certs.length) return new Response('Not found', { status: 404 });
  return new Response(
    JSON.stringify([
      {
        relation: ['delegate_permission/common.handle_all_urls'],
        target: { namespace: 'android_app', package_name: pkg, sha256_cert_fingerprints: certs },
      },
    ]),
    { headers: HEADERS },
  );
}

export function appleAppSiteAssociation(env: Record<string, string | undefined> = process.env): Response {
  const appIDs = list(env.APPLE_APP_IDS);
  if (!appIDs.length) return new Response('Not found', { status: 404 });
  return new Response(
    JSON.stringify({ applinks: { details: [{ appIDs, components: [{ '/': '/i/*' }] }] } }),
    { headers: HEADERS },
  );
}
