import { appleAppSiteAssociation, assetLinks } from '@/lib/app-links';

test('assetlinks.json from config (V-DL-1)', async () => {
  const res = assetLinks({
    ANDROID_PACKAGE: 'io.github.abdulbasitsaid.velio',
    ANDROID_CERT_SHA256: 'AA:BB, CC:DD',
  });
  expect(res.status).toBe(200);
  expect(res.headers.get('content-type')).toBe('application/json');
  expect(await res.json()).toEqual([
    {
      relation: ['delegate_permission/common.handle_all_urls'],
      target: {
        namespace: 'android_app',
        package_name: 'io.github.abdulbasitsaid.velio',
        sha256_cert_fingerprints: ['AA:BB', 'CC:DD'],
      },
    },
  ]);
});

test('apple-app-site-association covers /i/* only', async () => {
  const res = appleAppSiteAssociation({ APPLE_APP_IDS: 'TEAM.io.github.abdulbasitsaid.velio' });
  expect(await res.json()).toEqual({
    applinks: {
      details: [{ appIDs: ['TEAM.io.github.abdulbasitsaid.velio'], components: [{ '/': '/i/*' }] }],
    },
  });
});

test('404 when unconfigured', () => {
  expect(assetLinks({}).status).toBe(404);
  expect(assetLinks({ ANDROID_PACKAGE: 'x' }).status).toBe(404);
  expect(appleAppSiteAssociation({}).status).toBe(404);
});
