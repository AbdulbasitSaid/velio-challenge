// S8 admin page (V: T9; FR-014, AC-008) and the analytics helpers (FR-007).
import { fireEvent, render, screen, waitFor, within } from '@testing-library/react';
import type { AdminActivityList, AdminGoal, AdminMetrics } from '@velio/contracts';
import { AdminConsole } from '@/components/admin/admin-console';
import { ADMIN_TOKEN_KEY, formatTarget, formatValue, goalStatus } from '@/lib/admin';
import { vitalEvent, vitalPage } from '@/lib/analytics';

const ID = '0190a6f2-1f2b-7c3d-8e4f-5a6b7c8d9e0f';
const TOKEN = 'admin-token-for-tests-0123456789abcdef';
const r = (numerator: number, denominator: number) => ({
  numerator,
  denominator,
  value: denominator ? numerator / denominator : null,
});

const goal = (over: Partial<AdminGoal> = {}): AdminGoal => ({
  id: 'booking_success',
  label: 'Bookings succeed when spots exist',
  unit: 'ratio',
  value: 0.996,
  target: 0.995,
  trigger: 'Below 99.5% over any 1 h window',
  triggered: false,
  sample: 250,
  ...over,
});

const metrics = (): AdminMetrics => ({
  generatedAt: '2026-11-05T12:00:00.000Z',
  days: 7,
  goals: [
    goal({ id: 'no_oversell', label: 'Never oversell', unit: 'count', value: 0, target: 0, sample: 0 }),
    goal(),
    goal({
      id: 'availability_live',
      label: 'Availability feels live',
      unit: 'seconds',
      value: 2.4,
      target: 2,
      triggered: true,
      sample: 40,
    }),
    goal({
      id: 'invites_convert_public',
      label: 'Public links turn into guests',
      value: 0.12,
      target: null,
      sample: 50,
    }),
  ],
  funnel: [
    { rail: 'vouch', invites: 4, opens: 8, claims: 2, openToClaim: r(2, 8) },
    { rail: 'public', invites: 2, opens: 50, claims: 6, openToClaim: r(6, 50) },
  ],
  blendedOpenToClaim: r(8, 58),
  inviteRate: [
    { rail: 'any', rate: r(3, 10) },
    { rail: 'vouch', rate: r(2, 10) },
    { rail: 'public', rate: r(1, 10) },
  ],
  kFactor: [
    { rail: 'vouch', newUsers: 2, inviters: 2, value: 1 },
    { rail: 'public', newUsers: 3, inviters: 1, value: 3 },
  ],
  plansHappened: r(1, 2),
  guardrail: { invited: r(1, 4), organic: r(1, 8), ratio: 2, triggered: true },
  holdout: [
    { arm: 'exposed', users: 9, bookers: 9, newUsersPerBooker: r(5, 9), plansHappened: r(1, 2) },
    { arm: 'holdout', users: 1, bookers: 1, newUsersPerBooker: r(0, 1), plansHappened: r(0, 0) },
  ],
  audit: { ranAt: null, failures: null },
});

const activities: AdminActivityList = {
  activities: [
    {
      id: ID,
      title: 'Sunset Kayaking',
      communityName: 'Explore Kenya',
      startsAt: '2026-12-14T14:30:00.000Z',
      timezone: 'Africa/Nairobi',
      capacity: 14,
      spotsLeft: 6,
      bookingsPaused: false,
    },
  ],
};

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { 'content-type': 'application/json' } });

function stubFetch(handler: (url: string, init?: RequestInit) => Response) {
  const fetch = vi.fn(async (url: string, init?: RequestInit) => handler(String(url), init));
  vi.stubGlobal('fetch', fetch);
  return fetch;
}

beforeEach(() => sessionStorage.clear());
afterEach(() => vi.unstubAllGlobals());

describe('admin helpers', () => {
  test('values, targets and status', () => {
    expect(formatValue(0.996, 'ratio')).toBe('99.6%');
    expect(formatValue(0.3, 'ratio')).toBe('30%');
    expect(formatValue(1.234, 'seconds')).toBe('1.23 s');
    expect(formatValue(null, 'ratio')).toBe('—');
    expect(formatTarget(goal())).toBe('Target: ≥ 99.5%');
    expect(formatTarget(goal({ target: null }))).toBe('Target set after the week-1 baseline');
    expect(goalStatus(goal())).toBe('ok');
    expect(goalStatus(goal({ triggered: true }))).toBe('triggered');
    expect(goalStatus(goal({ value: null, sample: 0 }))).toBe('no-data');
    expect(goalStatus(goal({ target: null }))).toBe('baseline');
  });
});

describe('/admin', () => {
  test('asks for the token, then shows the goals with status in words, and sends the token as a header', async () => {
    const fetch = stubFetch((url) => (url.includes('/admin/metrics') ? json(metrics()) : json(activities)));
    render(<AdminConsole />);
    fireEvent.change(screen.getByLabelText('Admin token'), { target: { value: TOKEN } });
    fireEvent.click(screen.getByRole('button', { name: 'Continue' }));

    const tile = (await screen.findByText('Availability feels live')).closest('li')!;
    expect(within(tile).getByText('2.40 s')).toBeInTheDocument();
    expect(within(tile).getByText('Triggered')).toBeInTheDocument();
    expect(
      within(screen.getByText('Bookings succeed when spots exist').closest('li')!).getByText('On track'),
    ).toBeInTheDocument();
    expect(
      within(screen.getByText('Public links turn into guests').closest('li')!).getByText('Baseline'),
    ).toBeInTheDocument();
    expect(screen.getByText('Blended (context only)')).toBeInTheDocument();
    expect(screen.getByText('2.00×')).toBeInTheDocument();

    const [url, init] = fetch.mock.calls[0]!;
    expect(url).toBe('/api/admin/metrics?days=7');
    expect((init!.headers as Record<string, string>).authorization).toBe(`Bearer ${TOKEN}`);
    expect(sessionStorage.getItem(ADMIN_TOKEN_KEY)).toBe(TOKEN);
  });

  test('a rejected token returns to the form with a message and forgets it', async () => {
    sessionStorage.setItem(ADMIN_TOKEN_KEY, 'wrong');
    stubFetch(() => json({ error: { code: 'unauthenticated', message: 'x', requestId: 'r' } }, 401));
    render(<AdminConsole />);
    expect(await screen.findByText('That token didn’t work.')).toBeInTheDocument();
    expect(screen.getByLabelText('Admin token')).toBeInTheDocument();
    expect(sessionStorage.getItem(ADMIN_TOKEN_KEY)).toBeNull();
  });

  test('Pause asks first, then calls the kill switch', async () => {
    sessionStorage.setItem(ADMIN_TOKEN_KEY, TOKEN);
    const fetch = stubFetch((url, init) => {
      if (init?.method === 'POST') return new Response(null, { status: 204 });
      return url.includes('/admin/metrics') ? json(metrics()) : json(activities);
    });
    render(<AdminConsole />);
    fireEvent.click(await screen.findByRole('button', { name: 'Pause' }));
    const dialog = screen.getByRole('dialog');
    expect(within(dialog).getByText('Pause bookings for Sunset Kayaking?')).toBeInTheDocument();
    expect(fetch.mock.calls.some(([, i]) => i?.method === 'POST')).toBe(false);
    fireEvent.click(within(dialog).getByRole('button', { name: 'Pause bookings' }));
    await waitFor(() =>
      expect(
        fetch.mock.calls.some(([u, i]) => u === `/api/admin/activities/${ID}/pause` && i?.method === 'POST'),
      ).toBe(true),
    );
  });
});

describe('web vitals', () => {
  test('page templates and events', () => {
    expect(vitalPage(`/activities/${ID}`)).toBe('activity');
    expect(vitalPage('/i/K7PQ2N/claim')).toBe('invite');
    expect(vitalPage('/')).toBe('community');
    expect(vitalPage('/admin')).toBe('other');
    expect(vitalEvent({ name: 'LCP', value: 1400 }, '/i/K7PQ2N', '3g')).toEqual({
      name: 'web_vital',
      metric: 'LCP',
      value: 1400,
      page: 'invite',
      connection: '3g',
    });
    expect(vitalEvent({ name: 'FID', value: 10 }, '/')).toBeNull();
    expect(vitalEvent({ name: 'CLS', value: 0.02 }, '/', 'wifi')).toMatchObject({ connection: undefined });
  });
});
