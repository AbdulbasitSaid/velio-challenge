import { describe, expect, test } from 'bun:test';
import { ERROR_CODES, MemberPerson, PublicPerson } from '../src';

describe('contracts', () => {
  // V-CON-2 (SEC-005): public responses can never carry a full name.
  test('PublicPerson has no displayName', () => {
    expect(Object.keys(PublicPerson.shape)).not.toContain('displayName');
  });

  test('PublicPerson strips a displayName passed to it', () => {
    const parsed = PublicPerson.parse({
      id: '0190a6f2-1f2b-7c3d-8e4f-5a6b7c8d9e0f',
      shortName: 'Tunde A.',
      avatarSeed: 'seed',
      displayName: 'Tunde Adeyemi',
    });
    expect(parsed).not.toHaveProperty('displayName');
  });

  test('MemberPerson adds displayName', () => {
    expect(Object.keys(MemberPerson.shape)).toContain('displayName');
  });

  test('error codes include location_locked and internal', () => {
    expect(ERROR_CODES).toContain('location_locked');
    expect(ERROR_CODES).toContain('internal');
  });
});
