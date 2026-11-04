import { describe, expect, test } from 'bun:test';
import { resolve } from 'node:path';
import { ConfigError, loadConfig } from '../../src/config';

const valid = {
  DATABASE_URL: 'postgres://velio_api@localhost:5432/velio',
  DATABASE_LISTEN_URL: 'postgres://velio_api@localhost:5432/velio',
  CONTACT_PEPPER: 'x'.repeat(32),
};

// V-API-3 (FR-012)
describe('configuration', () => {
  test('the API exits non-zero, naming the variable, when CONTACT_PEPPER is unset', async () => {
    const proc = Bun.spawn([process.execPath, resolve(import.meta.dir, '../../src/index.ts')], {
      // A bare environment, so a local .env can't fill the gap.
      env: {
        PATH: process.env.PATH ?? '',
        DATABASE_URL: valid.DATABASE_URL,
        DATABASE_LISTEN_URL: valid.DATABASE_LISTEN_URL,
      },
      cwd: '/',
      stdout: 'pipe',
      stderr: 'pipe',
    });
    const code = await proc.exited;
    const stderr = await new Response(proc.stderr).text();
    expect(code).not.toBe(0);
    expect(stderr).toContain('CONTACT_PEPPER');
  });

  test('defaults apply to a valid environment', () => {
    const config = loadConfig(valid);
    expect(config.SESSION_IDLE_DAYS).toBe(30);
    expect(config.SESSION_ABSOLUTE_DAYS).toBe(90);
    expect(config.NODE_ENV).toBe('development');
  });

  test('an empty value counts as unset', () => {
    expect(() => loadConfig({ ...valid, CONTACT_PEPPER: '' })).toThrow(ConfigError);
  });

  test('production requires ORIGIN_VERIFY_SECRET', () => {
    expect(() => loadConfig({ ...valid, NODE_ENV: 'production' })).toThrow(/ORIGIN_VERIFY_SECRET/);
    expect(
      loadConfig({
        ...valid,
        NODE_ENV: 'production',
        ORIGIN_VERIFY_SECRET: 'y'.repeat(32),
        PUBLIC_BASE_URL: 'https://example.cloudfront.net',
        PHOTOS_BUCKET: 'velio-photos-test',
      }).NODE_ENV,
    ).toBe('production');
  });

  // S4: invite links need the public origin in production.
  test('production requires PUBLIC_BASE_URL; elsewhere it defaults, without a trailing slash', () => {
    expect(() =>
      loadConfig({
        ...valid,
        NODE_ENV: 'production',
        ORIGIN_VERIFY_SECRET: 'y'.repeat(32),
        PHOTOS_BUCKET: 'velio-photos-test',
      }),
    ).toThrow(/PUBLIC_BASE_URL/);
    expect(loadConfig(valid).PUBLIC_BASE_URL).toBe('http://localhost:3000');
    expect(loadConfig({ ...valid, PUBLIC_BASE_URL: 'https://d1.cloudfront.net/' }).PUBLIC_BASE_URL).toBe(
      'https://d1.cloudfront.net',
    );
  });

  // S5 §4.9: photos go to the stack's bucket with the instance role in production, MinIO elsewhere.
  test('production requires PHOTOS_BUCKET and no MinIO defaults; elsewhere MinIO is the default', () => {
    const prod = {
      ...valid,
      NODE_ENV: 'production',
      ORIGIN_VERIFY_SECRET: 'y'.repeat(32),
      PUBLIC_BASE_URL: 'https://example.cloudfront.net',
    };
    expect(() => loadConfig(prod)).toThrow(/PHOTOS_BUCKET/);
    expect(loadConfig({ ...prod, PHOTOS_BUCKET: 'b' + 'x'.repeat(5) })).toMatchObject({
      PHOTOS_BUCKET: 'bxxxxx',
      S3_REGION: 'eu-west-2',
      S3_ENDPOINT: undefined,
      S3_ACCESS_KEY_ID: undefined,
      S3_SECRET_ACCESS_KEY: undefined,
    });
    expect(loadConfig(valid)).toMatchObject({
      PHOTOS_BUCKET: 'velio-photos',
      S3_ENDPOINT: 'http://localhost:9000',
      S3_ACCESS_KEY_ID: 'velio-local',
    });
  });
});
