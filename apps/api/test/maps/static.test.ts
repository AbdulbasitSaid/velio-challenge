import { describe, expect, test } from 'bun:test';
import { signUrl, staticMapUrl } from '../../src/modules/maps/static';

describe('signUrl', () => {
  // Google's published URL-signing sample (web services "url_signer" example).
  test('matches Google’s example signature', () => {
    const signed = signUrl(
      'http://maps.googleapis.com/maps/api/geocode/json?address=New+York&client=clientID',
      'vNIXE0xscrmjlyV-12Nj_BvUPaw=',
    );
    expect(signed.endsWith('&signature=chaRF2hTJKOScPr-RQCEhZbSzIE=')).toBe(true);
  });
});

describe('staticMapUrl', () => {
  test('null when either value is missing', () => {
    expect(staticMapUrl({})(1, 2)).toBeNull();
    expect(staticMapUrl({ GOOGLE_MAPS_SERVER_KEY: 'k' })(1, 2)).toBeNull();
    expect(staticMapUrl({ GOOGLE_MAPS_SIGNING_SECRET: 's' })(1, 2)).toBeNull();
  });

  test('signed, fixed-size URL for the pin', () => {
    const url = staticMapUrl({
      GOOGLE_MAPS_SERVER_KEY: 'key',
      GOOGLE_MAPS_SIGNING_SECRET: 'vNIXE0xscrmjlyV-12Nj_BvUPaw=',
    })(-0.7167, 36.4333)!;
    const parsed = new URL(url);
    expect(parsed.origin + parsed.pathname).toBe('https://maps.googleapis.com/maps/api/staticmap');
    expect(parsed.searchParams.get('center')).toBe('-0.7167,36.4333');
    expect(parsed.searchParams.get('size')).toBe('600x300');
    expect(parsed.searchParams.get('markers')).toBe('color:0x173600|-0.7167,36.4333');
    // The signature is the last parameter and covers everything before it.
    const unsigned = url.slice(0, url.lastIndexOf('&signature='));
    expect(signUrl(unsigned, 'vNIXE0xscrmjlyV-12Nj_BvUPaw=')).toBe(url);
  });
});
