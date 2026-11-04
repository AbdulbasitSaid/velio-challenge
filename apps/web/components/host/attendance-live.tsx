'use client';

// H1 live attendance (S5 FR-035–FR-038; PRD H1, H2, D3, D5). The page listens to `activity:<id>` for
// spots and `host:<id>` for bookings; an `attendance` event carries only the ID, so the list is fetched
// again (S3 rule 5). Before the start each row offers Remove (always confirmed first); after it,
// attended or no-show, where the latest mark wins. The host sees names, refs and sources, never contacts.
import type { Attendance, Attendee, PublicActivity } from '@velio/contracts';
import { useEffect, useMemo, useRef, useState } from 'react';
import { AttendanceRow, type Mark } from '../cards';
import { Banner, BottomSheet, ConfirmDialog, EmptyState } from '../feedback';
import { useFlash } from '../plan/flash';
import { Button, SpotsBadge, TextField, type SpotsState } from '../primitives';
import { ApiRequestError, apiJson } from '@/lib/api/client';
import {
  attendanceStats,
  attendeeSource,
  groupsSummary,
  matchesGuest,
  orderAttendees,
} from '@/lib/attendance';
import { firstName, formatDay, formatTime, formatWhen, zoneLabel } from '@/lib/format';
import { useOnline } from '@/lib/online';
import { useLiveSpots } from '@/lib/realtime/react';

const PRIVACY =
  'You see names and how people found you. Phone numbers, emails and invite notes stay private.';
/** setTimeout's ceiling; a start further out than ~24 days is caught by the next load instead. */
const MAX_TIMER_MS = 2 ** 31 - 1;

/** True from the start time on, flipping while the page is open (marking opens at the start, PRD H2). */
function useStarted(startsAt: string, initial: boolean): boolean {
  const [started, setStarted] = useState(initial);
  useEffect(() => {
    if (started) return;
    const wait = Date.parse(startsAt) - Date.now();
    if (wait > MAX_TIMER_MS) return;
    const t = setTimeout(() => setStarted(true), Math.max(wait, 0));
    return () => clearTimeout(t);
  }, [startsAt, started]);
  return started;
}

/** Text for a failed mark; exported for tests. */
export function markFailure(err: unknown, name: string): string {
  const code = err instanceof ApiRequestError ? err.code : null;
  if (code === 'booking_removed') return `${firstName(name)} was removed, so they can’t be marked.`;
  if (code === 'activity_not_started') return 'You can mark attendance once the activity starts.';
  if (code === 'network') return 'You’re offline. Reconnect to mark attendance.';
  return 'We couldn’t save that mark. Try again.';
}

export function AttendanceLive({
  attendance: initial,
  activity,
}: {
  attendance: Attendance;
  activity: PublicActivity;
}) {
  const online = useOnline();
  const [flash, showFlash] = useFlash();
  const [data, setData] = useState(initial);
  const [query, setQuery] = useState('');
  const [confirm, setConfirm] = useState<Attendee | null>(null);
  const [removing, setRemoving] = useState(false);
  const [arrived, setArrived] = useState<ReadonlySet<string>>(() => new Set());
  const seen = useRef(new Set(initial.attendees.map((a) => a.bookingId)));
  const started = useStarted(initial.activity.startsAt, initial.activity.started);

  const id = activity.id;
  const tz = activity.timezone;
  const apply = (fresh: Attendance) => {
    const fresher = fresh.attendees.filter((a) => !seen.current.has(a.bookingId)).map((a) => a.bookingId);
    for (const b of fresher) seen.current.add(b);
    if (fresher.length) setArrived((prev) => new Set([...prev, ...fresher]));
    setData(fresh);
    return fresh;
  };
  const refetch = async () => {
    const fresh = await apiJson<Attendance>(`/host/activities/${id}/attendance`).catch(() => null);
    return fresh ? apply(fresh) : null;
  };

  const { spots, status } = useLiveSpots(
    { [id]: { spotsLeft: initial.activity.spotsLeft, version: initial.activity.version } },
    async () => {
      const fresh = apply(await apiJson<Attendance>(`/host/activities/${id}/attendance`));
      return { [id]: { spotsLeft: fresh.activity.spotsLeft, version: fresh.activity.version } };
    },
    { extraTopics: [`host:${id}`], onAttendance: () => void refetch(), announce: [id] },
  );
  const live = spots[id]!;
  const spotsState: SpotsState =
    !online || status === 'reconnecting' ? 'stale' : live.changed ? 'changed' : 'live';

  // Marking opens at the start: fetch once then, so marks made elsewhere show.
  const wasStarted = useRef(started);
  useEffect(() => {
    if (started && !wasStarted.current) void refetch();
    wasStarted.current = started;
  });

  const stats = attendanceStats(data);
  const { groups, alone } = useMemo(() => groupsSummary(data.attendees), [data.attendees]);
  const rows = orderAttendees(data.attendees, started).filter((a) => matchesGuest(a, query));
  const empty = data.attendees.length === 0;
  const when = `${formatWhen(activity.startsAt, tz)} ${zoneLabel(tz)}`;

  const mark = async (a: Attendee, next: Mark) => {
    if (a.mark === next) return;
    const put = (m: Attendee) =>
      setData((d) => ({ ...d, attendees: d.attendees.map((x) => (x.bookingId === m.bookingId ? m : x)) }));
    put({ ...a, mark: next });
    try {
      put(
        await apiJson<Attendee>(`/host/bookings/${a.bookingId}/attendance`, {
          method: 'POST',
          body: { mark: next },
        }),
      );
    } catch (err) {
      put(a);
      showFlash(markFailure(err, a.person.displayName));
      if (err instanceof ApiRequestError && err.code === 'booking_removed') void refetch();
    }
  };

  const remove = async () => {
    if (!confirm) return;
    setRemoving(true);
    try {
      await apiJson(`/host/bookings/${confirm.bookingId}/removal`, { method: 'POST' });
      await refetch();
      showFlash(`${firstName(confirm.person.displayName)} removed. Their spot is open again.`);
    } catch (err) {
      showFlash(
        err instanceof ApiRequestError && err.code === 'network'
          ? 'You’re offline. Reconnect to remove a guest.'
          : `We couldn’t remove ${firstName(confirm.person.displayName)}. Try again.`,
      );
    } finally {
      setRemoving(false);
      setConfirm(null);
    }
  };

  const statCards: [string, string][] = started
    ? [
        ['Booked', `${stats.booked} of ${stats.capacity}`],
        ['Attended', String(stats.attended)],
        ['No-shows', String(stats.noShows)],
      ]
    : [
        ['Booked', `${stats.booked} of ${stats.capacity}`],
        ['Through invites', String(stats.throughInvites)],
        ['Spots left', String(Math.max(live.spotsLeft, 0))],
      ];

  return (
    <main className="mx-auto flex w-full max-w-content flex-col gap-4 px-5 pt-1 pb-8 md:gap-6 md:px-10 md:pt-6 md:pb-16">
      <div className="flex flex-wrap items-end justify-between gap-4">
        <div className="flex flex-col gap-1 md:gap-1.5">
          <a href="/host/activities" className="text-[14px] font-bold">
            My activities
          </a>
          <h1 className="m-0 text-title md:text-[36px] md:leading-[42px]">{activity.title}</h1>
          <span className="text-[14px] text-muted md:text-[15px]">
            {when}
            <span className="hidden md:inline"> · {activity.location.venueName}</span>
          </span>
        </div>
        <div className="hidden items-center gap-3 md:flex">
          <SpotsBadge spots={live.spotsLeft} state={spotsState} />
        </div>
      </div>

      {/* Phone: one stat beside the spots badge. */}
      <div className="flex items-center justify-between gap-3 rounded-hero bg-surface px-4 py-3.5 md:hidden">
        <div className="flex flex-col">
          <span className="text-caption text-muted">{started ? 'Marked' : 'Booked'}</span>
          <strong className="font-display text-[24px] leading-[30px] font-bold tabular-nums">
            {started ? `${stats.marked} of ${stats.booked}` : `${stats.booked} of ${stats.capacity}`}
          </strong>
        </div>
        <SpotsBadge spots={live.spotsLeft} state={spotsState} />
      </div>

      <div className="hidden grid-cols-[repeat(auto-fit,minmax(min(180px,100%),1fr))] gap-4 md:grid">
        {statCards.map(([label, value]) => (
          <div key={label} className="flex flex-col gap-1 rounded-hero bg-surface px-5 py-4">
            <span className="text-caption text-muted">{label}</span>
            <strong className="font-display text-[28px] leading-[34px] font-bold tabular-nums">
              {value}
            </strong>
          </div>
        ))}
      </div>

      <div className="flex flex-wrap items-start gap-4 md:gap-8">
        <section className="flex min-w-0 flex-[999_1_560px] flex-col gap-3" aria-labelledby="att-h">
          {started && !empty ? (
            <Banner title="The activity has started.">
              Mark who came. It’s how Velio counts the plans that actually happen.
            </Banner>
          ) : null}

          {empty ? null : (
            <div className="md:hidden">
              <TextField
                id="att-search"
                label="Find a guest"
                search
                type="search"
                inputMode="search"
                placeholder="Name or booking ref"
                value={query}
                onChange={setQuery}
              />
            </div>
          )}

          <div className="flex items-baseline justify-between gap-3">
            <h2 id="att-h" className="m-0 text-heading">
              {started ? 'Who came?' : 'Going'}
            </h2>
            {empty ? null : (
              <span className="text-caption text-muted">
                {!started ? (
                  'Newest first'
                ) : (
                  <>
                    <span className="md:hidden">Tap to mark</span>
                    <span className="hidden md:inline">
                      {stats.marked} of {stats.booked} marked
                    </span>
                  </>
                )}
              </span>
            )}
          </div>

          {empty ? (
            <EmptyState
              icon="people"
              title="No bookings yet"
              body={
                started
                  ? 'Nobody booked this activity.'
                  : `This page updates by itself the moment someone books. Bookings close at ${formatTime(activity.startsAt, tz)} ${zoneLabel(tz)} on ${formatDay(activity.startsAt, tz)}.`
              }
            />
          ) : rows.length ? (
            <div className="vl-list">
              {rows.map((a) => {
                const isNew = arrived.has(a.bookingId) && a.status === 'confirmed';
                return (
                  <AttendanceRow
                    key={a.bookingId}
                    name={a.person.displayName}
                    seed={a.person.avatarSeed}
                    bookingRef={a.ref}
                    time={
                      a.status === 'removed'
                        ? 'Removed'
                        : isNew
                          ? 'Booked just now'
                          : `Booked ${formatDay(a.bookedAt, tz)}`
                    }
                    source={a.source}
                    sourceLabel={attendeeSource(a)}
                    mode={started ? 'after' : 'before'}
                    mark={a.mark}
                    isNew={isNew}
                    removed={a.status === 'removed'}
                    onRemove={() => setConfirm(a)}
                    onMark={(m) => void mark(a, m)}
                  />
                );
              })}
            </div>
          ) : (
            <p className="m-0 text-muted">No guest matches “{query.trim()}”.</p>
          )}
          {empty ? null : <p className="m-0 text-caption text-muted md:hidden">{PRIVACY}</p>}
        </section>

        <aside className="flex min-w-0 flex-[1_1_320px] flex-col gap-4">
          {stats.booked ? (
            <section
              className="hidden flex-col gap-3 rounded-hero bg-surface p-5 md:flex"
              aria-labelledby="groups-h"
            >
              <h2 id="groups-h" className="m-0 text-[17px] font-bold">
                Groups
              </h2>
              {groups.map((g) => (
                <div key={g.planId} className="flex justify-between">
                  <span>{g.label}</span>
                  <strong>{g.count}</strong>
                </div>
              ))}
              {alone ? (
                <div className="flex justify-between">
                  <span>Booked alone</span>
                  <strong>{alone}</strong>
                </div>
              ) : null}
              <span className="text-caption text-muted">
                People who came in through each other’s invites. Useful for seating and boats.
              </span>
            </section>
          ) : null}
          <div className="hidden md:block">
            <Banner icon="lock" title="What you see">
              {PRIVACY}
            </Banner>
          </div>
          {started ? null : (
            <Button variant="secondary" block href={`/host/activities/${id}/edit`}>
              Edit activity
            </Button>
          )}
        </aside>
      </div>

      {confirm ? (
        <RemoveConfirm
          name={confirm.person.displayName}
          busy={removing}
          onConfirm={() => void remove()}
          onCancel={() => setConfirm(null)}
        />
      ) : null}
      {flash}
    </main>
  );
}

/** `host.remove.confirm`: a dialog from 768 px, a bottom sheet on phone, as the canvas draws them. */
function RemoveConfirm({
  name,
  busy,
  onConfirm,
  onCancel,
}: {
  name: string;
  busy: boolean;
  onConfirm: () => void;
  onCancel: () => void;
}) {
  const box = useRef<HTMLDivElement>(null);
  useEffect(() => {
    // Focus the safe choice in whichever variant is showing.
    const keeps = [...(box.current?.querySelectorAll<HTMLButtonElement>('button') ?? [])].filter(
      (b) => b.textContent === 'Keep',
    );
    (keeps.find((b) => b.offsetParent !== null) ?? keeps[0])?.focus();
  }, []);
  const title = `Remove ${name}?`;
  const body = 'Their spot opens to whoever books next, and they’ll see that you removed them.';
  const confirmLabel = `Remove ${firstName(name)}`;
  return (
    <div
      ref={box}
      className="fixed inset-0 z-40"
      onKeyDown={(e) => {
        if (e.key === 'Escape' && !busy) onCancel();
      }}
    >
      <div className="hidden h-full md:block [&>.vl-dialog-scrim]:h-full">
        <ConfirmDialog
          title={title}
          body={body}
          confirm={confirmLabel}
          cancel="Keep"
          destructive
          busy={busy}
          onConfirm={onConfirm}
          onCancel={onCancel}
        />
      </div>
      <div className="flex h-full flex-col justify-end bg-scrim md:hidden">
        <BottomSheet label={title}>
          <strong className="font-display text-[20px] leading-[26px] font-bold">{title}</strong>
          <span className="text-[15px] leading-[22px] text-muted">{body}</span>
          <Button variant="danger" block loading={busy} onClick={onConfirm}>
            {confirmLabel}
          </Button>
          <Button variant="quiet" block disabled={busy} onClick={onCancel}>
            Keep
          </Button>
        </BottomSheet>
      </div>
    </div>
  );
}
