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
      loadConfig({ ...valid, NODE_ENV: 'production', ORIGIN_VERIFY_SECRET: 'y'.repeat(32) }).NODE_ENV,
    ).toBe('production');
  });
});
