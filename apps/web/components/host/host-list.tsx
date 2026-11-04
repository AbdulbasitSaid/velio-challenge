'use client';

// H3 (S5 FR-032; PRD W1): the host's activities, upcoming and past. A table from 1024 px, cards below (at 768 px the table would scroll its actions out of view).
// After the start, a row asks for attendance until someone is marked, then shows how many came.
import type { HostActivityItem, HostActivityList } from '@velio/contracts';
import { useState } from 'react';
import { EmptyState } from '../feedback';
import { Button, Chip, Photo, Segmented, type ChipTone } from '../primitives';
import { formatWhen, spotsLabel } from '@/lib/format';

type Tab = 'upcoming' | 'past';

export interface HostRow {
  id: string;
  status: string;
  tone: ChipTone;
  primary: { label: string; href: string };
  secondary: { label: string; href: string };
}

/** Status chip and actions, as the approved canvas draws them. Exported for tests. */
export function hostRow(a: HostActivityItem, tab: Tab): HostRow {
  const page = `/activities/${a.id}`;
  const attendance = `/host/activities/${a.id}/attendance`;
  if (tab === 'upcoming') {
    return {
      id: a.id,
      ...(a.bookedCount === 0
        ? { status: 'No bookings yet', tone: 'neutral' as const, primary: { label: 'View page', href: page } }
        : {
            status: spotsLabel(a.spotsLeft),
            tone: a.spotsLeft <= 0 ? ('forest' as const) : ('lime' as const),
            primary: { label: 'Attendance', href: attendance },
          }),
      secondary: { label: 'Edit', href: `/host/activities/${a.id}/edit` },
    };
  }
  return {
    id: a.id,
    ...(a.bookedCount === 0
      ? {
          status: 'No bookings',
          tone: 'neutral' as const,
          primary: { label: 'Attendance', href: attendance },
        }
      : a.markedCount === 0
        ? {
            status: 'Mark attendance',
            tone: 'danger' as const,
            primary: { label: 'Mark now', href: attendance },
          }
        : {
            status: `${a.attendedCount} attended`,
            tone: 'neutral' as const,
            primary: { label: 'Attendance', href: attendance },
          }),
    secondary: { label: 'View', href: page },
  };
}

export function HostList({ data }: { data: HostActivityList }) {
  const [tab, setTab] = useState<Tab>('upcoming');
  const items = data[tab];
  const empty = !data.upcoming.length && !data.past.length;

  const toggle = (
    <Segmented
      label="Show"
      value={tab}
      options={[
        { value: 'upcoming', label: 'Upcoming' },
        { value: 'past', label: 'Past' },
      ]}
      onChange={(v) => setTab(v as Tab)}
    />
  );

  return (
    <main className="mx-auto flex w-full max-w-content flex-col gap-5 px-5 pt-1 pb-8 md:gap-6 md:px-10 md:pt-8 md:pb-16">
      <div className="flex flex-wrap items-center justify-between gap-4">
        <h1 className="m-0 text-title md:text-[36px] md:leading-[42px]">My activities</h1>
        <div className="flex flex-wrap items-center gap-3">
          {empty ? null : <span className="hidden md:inline-flex">{toggle}</span>}
          <Button small href="/host/activities/new">
            <span className="md:hidden">Create</span>
            <span className="hidden md:inline">Create activity</span>
          </Button>
        </div>
      </div>
      {empty ? null : <span className="md:hidden">{toggle}</span>}

      {empty ? (
        <div className="mx-auto flex w-full max-w-[480px] flex-col gap-4 md:my-10">
          <EmptyState
            icon="calendar"
            title="No activities yet"
            body="Create your first activity. It gets a page in its community and links you can share."
          />
          <Button href="/host/activities/new" block className="md:!w-auto md:self-center">
            Create activity
          </Button>
        </div>
      ) : items.length === 0 ? (
        <p className="m-0 text-muted">
          {tab === 'upcoming' ? 'Nothing coming up.' : 'No past activities yet.'}
        </p>
      ) : (
        <>
          <ul className="m-0 flex list-none flex-col gap-3 p-0 md:grid md:grid-cols-2 lg:hidden">
            {items.map((a) => {
              const row = hostRow(a, tab);
              return (
                <li key={a.id}>
                  <a
                    href={`/host/activities/${a.id}/attendance`}
                    className="flex flex-col gap-2.5 rounded-card bg-surface p-3.5 text-ink no-underline"
                  >
                    <div className="flex items-center gap-3">
                      <Thumb a={a} size="size-14" />
                      <div className="flex min-w-0 flex-1 flex-col gap-0.5">
                        <strong>{a.title}</strong>
                        <span className="text-[13px] text-muted">{formatWhen(a.startsAt, a.timezone)}</span>
                      </div>
                    </div>
                    <div className="flex items-center justify-between gap-2">
                      <span className="text-[14px] tabular-nums">
                        <strong>{a.bookedCount}</strong> of {a.capacity} booked
                      </span>
                      <Chip tone={row.tone}>{row.status}</Chip>
                    </div>
                  </a>
                </li>
              );
            })}
          </ul>

          <div className="hidden overflow-x-auto rounded-card bg-surface lg:block">
            <table className="w-full min-w-[760px] border-collapse text-[15px]">
              <thead>
                <tr className="text-left text-[13px] text-muted">
                  <th scope="col" className="px-4 py-3.5 font-bold">
                    Activity
                  </th>
                  <th scope="col" className="px-4 py-3.5 font-bold">
                    When
                  </th>
                  <th scope="col" className="px-4 py-3.5 font-bold">
                    Booked
                  </th>
                  <th scope="col" className="px-4 py-3.5 font-bold">
                    Status
                  </th>
                  <th scope="col" className="px-4 py-3.5">
                    <span className="vl-sr">Actions</span>
                  </th>
                </tr>
              </thead>
              <tbody>
                {items.map((a) => {
                  const row = hostRow(a, tab);
                  return (
                    <tr key={a.id} className="border-t border-line">
                      <td className="px-4 py-3">
                        <div className="flex items-center gap-3">
                          <Thumb a={a} size="h-10 w-14" />
                          <div className="flex flex-col">
                            <strong>{a.title}</strong>
                            <span className="text-[13px] text-muted">{a.community.name}</span>
                          </div>
                        </div>
                      </td>
                      <td className="px-4 py-3 whitespace-nowrap">{formatWhen(a.startsAt, a.timezone)}</td>
                      <td className="px-4 py-3 whitespace-nowrap tabular-nums">
                        <strong>{a.bookedCount}</strong> <span className="text-muted">of {a.capacity}</span>
                      </td>
                      <td className="px-4 py-3">
                        <Chip tone={row.tone}>{row.status}</Chip>
                      </td>
                      <td className="px-4 py-3 text-right whitespace-nowrap">
                        <a
                          href={row.primary.href}
                          className="mr-4 font-bold"
                          aria-label={`${row.primary.label}: ${a.title}`}
                        >
                          {row.primary.label}
                        </a>
                        <a
                          href={row.secondary.href}
                          className="font-bold"
                          aria-label={`${row.secondary.label}: ${a.title}`}
                        >
                          {row.secondary.label}
                        </a>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </>
      )}
    </main>
  );
}

function Thumb({ a, size }: { a: HostActivityItem; size: string }) {
  return (
    <div
      className={`${size} flex-none overflow-hidden rounded-small bg-forest [&_img]:size-full [&_img]:object-cover [&_svg]:block [&_svg]:size-full`}
    >
      <Photo src={a.photoUrl} alt="" scene="lake" />
    </div>
  );
}
