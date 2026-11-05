'use client';

// /admin (S8 FR-014): the PRD goals as stat tiles, the funnel, K-factor, guardrail and holdout as
// tables, the attribution audit and the per-activity kill switch. The token lives in sessionStorage
// and goes in the Authorization header only.
import type { AdminActivity, AdminActivityList, AdminAudit, AdminGoal, AdminMetrics } from '@velio/contracts';
import {
  useCallback,
  useEffect,
  useState,
  useSyncExternalStore,
  type FormEvent,
  type ReactNode,
} from 'react';
import { Banner, ConfirmDialog } from '../feedback';
import { Button, Chip, Segmented, TextField } from '../primitives';
import { ADMIN_TOKEN_KEY, formatRatio, formatTarget, formatValue, goalStatus } from '@/lib/admin';
import { apiJson, ApiRequestError } from '@/lib/api/client';
import { formatWhen } from '@/lib/format';

function readToken(): string | null {
  try {
    return sessionStorage.getItem(ADMIN_TOKEN_KEY) ?? memoryToken;
  } catch {
    return memoryToken;
  }
}

const TOKEN_EVENT = 'velio-admin-token';
/** Fallback when sessionStorage is unavailable (private mode): the token lasts as long as the page. */
let memoryToken: string | null = null;

function writeToken(token: string | null) {
  memoryToken = token;
  try {
    if (token) sessionStorage.setItem(ADMIN_TOKEN_KEY, token);
    else sessionStorage.removeItem(ADMIN_TOKEN_KEY);
  } catch {
    // memoryToken holds it.
  }
  window.dispatchEvent(new Event(TOKEN_EVENT));
}

function subscribeToken(onChange: () => void) {
  window.addEventListener(TOKEN_EVENT, onChange);
  return () => window.removeEventListener(TOKEN_EVENT, onChange);
}

export function AdminConsole() {
  const token = useSyncExternalStore(subscribeToken, readToken, () => null);
  /** Why the token form came back (a rejected token, a lockout). */
  const [message, setMessage] = useState<string | null>(null);

  if (!token) {
    return (
      <TokenForm
        message={message}
        onToken={(t) => {
          setMessage(null);
          writeToken(t);
        }}
      />
    );
  }
  return (
    <Dashboard
      token={token}
      onSignOut={(reason) => {
        setMessage(reason ?? null);
        writeToken(null);
      }}
    />
  );
}

function TokenForm({ message, onToken }: { message: string | null; onToken: (token: string) => void }) {
  const [value, setValue] = useState('');
  const submit = (e: FormEvent) => {
    e.preventDefault();
    if (value.trim()) onToken(value.trim());
  };
  return (
    <main className="mx-auto flex w-full max-w-[480px] flex-col gap-5 px-5 pt-6 pb-10">
      <h1 className="m-0 text-title">Admin</h1>
      <p className="m-0 text-muted">Enter the admin token to see the PRD goals and the kill switch.</p>
      {message ? <Banner tone="error">{message}</Banner> : null}
      <form className="flex flex-col gap-4" onSubmit={submit}>
        <TextField label="Admin token" type="password" autoComplete="off" value={value} onChange={setValue} />
        <Button type="submit" block>
          Continue
        </Button>
      </form>
    </main>
  );
}

const DAYS = [
  { value: '1', label: '24 h' },
  { value: '7', label: '7 days' },
  { value: '28', label: '28 days' },
];

function Dashboard({ token, onSignOut }: { token: string; onSignOut: (reason?: string) => void }) {
  const [days, setDays] = useState('7');
  const [metrics, setMetrics] = useState<AdminMetrics | null>(null);
  const [activities, setActivities] = useState<AdminActivity[] | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  /** Bumped by Refresh and after every change, to load again. */
  const [nonce, setNonce] = useState(0);
  const headers = { authorization: `Bearer ${token}` };

  const fail = useCallback(
    (err: unknown) => {
      if (err instanceof ApiRequestError && (err.status === 401 || err.status === 404)) {
        onSignOut(err.status === 404 ? 'Admin isn’t configured on this server.' : 'That token didn’t work.');
      } else if (err instanceof ApiRequestError && err.status === 429) {
        onSignOut('Too many attempts. Try again in a minute.');
      } else {
        setError('We couldn’t load the admin data.');
      }
    },
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [],
  );

  const reload = () => {
    setLoading(true);
    setError(null);
    setNonce((n) => n + 1);
  };

  useEffect(() => {
    let current = true;
    Promise.all([
      apiJson<AdminMetrics>(`/admin/metrics?days=${days}`, { headers }),
      apiJson<AdminActivityList>('/admin/activities', { headers }),
    ])
      .then(([m, a]) => {
        if (!current) return;
        setMetrics(m);
        setActivities(a.activities);
      })
      .catch((err: unknown) => current && fail(err))
      .finally(() => current && setLoading(false));
    return () => {
      current = false;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [days, token, nonce]);

  return (
    <main className="mx-auto flex w-full max-w-content flex-col gap-6 px-4 pt-4 pb-12 md:gap-8 md:px-10 md:pt-8">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <h1 className="m-0 text-title md:text-[36px] md:leading-[42px]">Admin</h1>
        <div className="flex flex-wrap items-center gap-3">
          <Segmented
            label="Window"
            value={days}
            options={DAYS}
            onChange={(d) => {
              setLoading(true);
              setDays(d);
            }}
          />
          <Button small variant="quiet" icon="refresh" onClick={reload} loading={loading}>
            Refresh
          </Button>
          <Button small variant="quiet" onClick={() => onSignOut()}>
            Forget token
          </Button>
        </div>
      </div>

      {error ? (
        <Banner
          tone="error"
          action={
            <Button small variant="quiet" onClick={reload}>
              Try again
            </Button>
          }
        >
          {error}
        </Banner>
      ) : null}

      {metrics ? (
        <>
          <Section
            title="Goals"
            note={`Last ${DAYS.find((d) => d.value === days)?.label ?? `${days} days`}.`}
          >
            <ul className="m-0 grid list-none grid-cols-1 gap-3 p-0 sm:grid-cols-2 lg:grid-cols-3">
              {metrics.goals.map((g) => (
                <GoalTile key={g.id} goal={g} />
              ))}
            </ul>
          </Section>
          <Funnel metrics={metrics} />
          <Outcomes metrics={metrics} />
          <Audit metrics={metrics} headers={headers} onDone={reload} onError={fail} />
        </>
      ) : loading ? (
        <p className="m-0 text-muted">Loading…</p>
      ) : null}

      {activities ? (
        <KillSwitch activities={activities} headers={headers} onChanged={reload} onError={fail} />
      ) : null}
    </main>
  );
}

function Section({ title, note, children }: { title: string; note?: ReactNode; children: ReactNode }) {
  return (
    <section className="flex flex-col gap-3" aria-labelledby={`h-${title}`}>
      <div className="flex flex-wrap items-baseline justify-between gap-2">
        <h2 id={`h-${title}`} className="m-0 text-heading">
          {title}
        </h2>
        {note ? <span className="text-[13px] text-muted">{note}</span> : null}
      </div>
      {children}
    </section>
  );
}

const STATUS = {
  triggered: { tone: 'danger', icon: 'alert', label: 'Triggered' },
  ok: { tone: 'lime', icon: 'check', label: 'On track' },
  'no-data': { tone: 'neutral', icon: 'info', label: 'No data yet' },
  baseline: { tone: 'sky', icon: 'flag', label: 'Baseline' },
} as const;

/** A stat tile: label, value, target and a status chip with icon and words, never colour alone. */
function GoalTile({ goal }: { goal: AdminGoal }) {
  const s = STATUS[goalStatus(goal)];
  return (
    <li className="flex flex-col gap-2 rounded-card bg-surface p-4">
      <div className="flex items-start justify-between gap-3">
        <span className="text-[14px] font-bold">{goal.label}</span>
        <Chip tone={s.tone} icon={s.icon}>
          {s.label}
        </Chip>
      </div>
      <span className="text-[32px] leading-[38px] font-bold">{formatValue(goal.value, goal.unit)}</span>
      <span className="text-[13px] text-muted">
        {formatTarget(goal)} · n = {goal.sample.toLocaleString('en-GB')}
      </span>
      <span className="text-[13px] text-muted">Trigger: {goal.trigger}</span>
    </li>
  );
}

function Table({ head, rows, caption }: { head: string[]; rows: ReactNode[][]; caption: string }) {
  return (
    <div className="overflow-x-auto rounded-card bg-surface">
      <table className="w-full border-collapse text-[15px]">
        <caption className="vl-sr">{caption}</caption>
        <thead>
          <tr className="text-left text-[13px] text-muted">
            {head.map((h, i) => (
              <th key={h} scope="col" className={`px-4 py-3 font-bold ${i > 0 ? 'text-right' : ''}`}>
                {h}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {rows.map((r, i) => (
            <tr key={i} className="border-t border-line">
              {r.map((cell, j) => (
                <td key={j} className={`px-4 py-3 ${j > 0 ? 'text-right tabular-nums' : ''}`}>
                  {cell}
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

const railName = (rail: string) =>
  rail === 'vouch' ? 'Vouch' : rail === 'public' ? 'Public link' : 'Any rail';

function Funnel({ metrics }: { metrics: AdminMetrics }) {
  return (
    <Section title="Invites by rail" note="Opens are unique human opens: one per invite and device.">
      <Table
        caption="Invite funnel per rail"
        head={['Rail', 'Invites', 'Opens', 'Claims', 'Open → claim', 'New users', 'K-factor']}
        rows={[
          ...metrics.funnel.map((f) => {
            const k = metrics.kFactor.find((x) => x.rail === f.rail)!;
            return [
              railName(f.rail),
              f.invites,
              f.opens,
              f.claims,
              formatRatio(f.openToClaim),
              k.newUsers,
              k.value === null ? '—' : k.value.toFixed(2),
            ];
          }),
          ['Blended (context only)', '', '', '', formatRatio(metrics.blendedOpenToClaim), '', ''],
        ]}
      />
      <Table
        caption="Bookers who invited within 24 hours, exposed arm"
        head={['Bookers who invited within 24 h', 'Rate', 'Bookers']}
        rows={metrics.inviteRate.map((r) => [railName(r.rail), formatRatio(r.rate), r.rate.denominator])}
      />
    </Section>
  );
}

function Outcomes({ metrics }: { metrics: AdminMetrics }) {
  const g = metrics.guardrail;
  return (
    <Section title="Plans and holdout" note="Holdout: 10% of users never see invite tools.">
      <Table
        caption="Plans that happened and the no-show guardrail"
        head={['Guardrail', 'Rate', 'Of']}
        rows={[
          [
            'Plans where everyone attended',
            formatRatio(metrics.plansHappened),
            metrics.plansHappened.denominator,
          ],
          ['No-show or removed: invited', formatRatio(g.invited), g.invited.denominator],
          ['No-show or removed: organic', formatRatio(g.organic), g.organic.denominator],
          [
            <span key="r" className="inline-flex items-center gap-2">
              Invited ÷ organic (trigger above 1.5×)
              {g.triggered ? (
                <Chip tone="danger" icon="alert">
                  Triggered
                </Chip>
              ) : null}
            </span>,
            g.ratio === null ? '—' : `${g.ratio.toFixed(2)}×`,
            '',
          ],
        ]}
      />
      <Table
        caption="Exposed and holdout arms"
        head={['Arm', 'Users', 'Bookers', 'New users per booker', 'Plans happened']}
        rows={metrics.holdout.map((h) => [
          h.arm === 'exposed' ? 'Exposed (90%)' : 'Holdout (10%)',
          h.users,
          h.bookers,
          h.newUsersPerBooker.value === null ? '—' : h.newUsersPerBooker.value.toFixed(2),
          formatRatio(h.plansHappened),
        ])}
      />
    </Section>
  );
}

function Audit({
  metrics,
  headers,
  onDone,
  onError,
}: {
  metrics: AdminMetrics;
  headers: Record<string, string>;
  onDone: () => void;
  onError: (err: unknown) => void;
}) {
  const [running, setRunning] = useState(false);
  const [result, setResult] = useState<AdminAudit | null>(null);
  const run = () => {
    setRunning(true);
    apiJson<AdminAudit>('/admin/audit', { method: 'POST', headers })
      .then((r) => {
        setResult(r);
        onDone();
      })
      .catch(onError)
      .finally(() => setRunning(false));
  };
  const failures = result ? result.failures.length : metrics.audit.failures;
  const ranAt = result?.ranAt ?? metrics.audit.ranAt;
  return (
    <Section title="Attribution audit" note="Runs nightly at 02:00 UTC.">
      <div className="flex flex-wrap items-center justify-between gap-3 rounded-card bg-surface p-4">
        <div className="flex flex-col gap-1">
          {ranAt === null ? (
            <span>Not run since the server started.</span>
          ) : failures === 0 ? (
            <Chip tone="lime" icon="check">
              Every hash chain verified
            </Chip>
          ) : (
            <Chip tone="danger" icon="alert">
              {failures} chain{failures === 1 ? '' : 's'} failed verification
            </Chip>
          )}
          {ranAt ? (
            <span className="text-[13px] text-muted">Last run {new Date(ranAt).toLocaleString('en-GB')}</span>
          ) : null}
        </div>
        <Button small variant="secondary" onClick={run} loading={running}>
          Run audit now
        </Button>
      </div>
    </Section>
  );
}

function KillSwitch({
  activities,
  headers,
  onChanged,
  onError,
}: {
  activities: AdminActivity[];
  headers: Record<string, string>;
  onChanged: () => void;
  onError: (err: unknown) => void;
}) {
  const [confirm, setConfirm] = useState<AdminActivity | null>(null);
  const [busy, setBusy] = useState(false);
  const act = (a: AdminActivity) => {
    setBusy(true);
    apiJson(`/admin/activities/${a.id}/${a.bookingsPaused ? 'resume' : 'pause'}`, { method: 'POST', headers })
      .then(() => {
        setConfirm(null);
        onChanged();
      })
      .catch(onError)
      .finally(() => setBusy(false));
  };
  return (
    <Section title="Kill switch" note="Pausing stops new bookings and claims at once.">
      {activities.length === 0 ? (
        <p className="m-0 text-muted">No upcoming activities.</p>
      ) : (
        <ul className="m-0 flex list-none flex-col gap-2 p-0">
          {activities.map((a) => (
            <li
              key={a.id}
              className="flex flex-wrap items-center justify-between gap-3 rounded-card bg-surface p-3.5"
            >
              <div className="flex min-w-0 flex-col">
                <strong className="truncate">{a.title}</strong>
                <span className="text-[13px] text-muted">
                  {a.communityName} · {formatWhen(a.startsAt, a.timezone)} · {a.spotsLeft} of {a.capacity}{' '}
                  left
                </span>
              </div>
              <div className="flex items-center gap-3">
                {a.bookingsPaused ? (
                  <Chip tone="danger" icon="lock">
                    Paused
                  </Chip>
                ) : null}
                <Button
                  small
                  variant={a.bookingsPaused ? 'secondary' : 'quiet'}
                  onClick={() => setConfirm(a)}
                >
                  {a.bookingsPaused ? 'Resume' : 'Pause'}
                </Button>
              </div>
            </li>
          ))}
        </ul>
      )}
      {confirm ? (
        <ConfirmDialog
          title={
            confirm.bookingsPaused
              ? `Resume bookings for ${confirm.title}?`
              : `Pause bookings for ${confirm.title}?`
          }
          body={
            confirm.bookingsPaused
              ? 'People can book and claim spots again straight away.'
              : 'New bookings and claims are refused until you resume. Existing bookings stay.'
          }
          confirm={confirm.bookingsPaused ? 'Resume' : 'Pause bookings'}
          destructive={!confirm.bookingsPaused}
          busy={busy}
          onConfirm={() => act(confirm)}
          onCancel={() => setConfirm(null)}
        />
      ) : null}
    </Section>
  );
}
