'use client';

// B6 My plans (S5 FR-030; PRD L2, Q14): upcoming soonest first with live spots, past most recent first.
// Plans follow the person, not the device, so the footer says how to see them elsewhere, and offers
// sign-out for a shared computer.
import type { MyPlans as MyPlansData } from '@velio/contracts';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { useState } from 'react';
import { PlanCard } from '../cards';
import { EmptyState } from '../feedback';
import { Button, Segmented, SpotsBadge } from '../primitives';
import { apiFetch, apiJson } from '@/lib/api/client';
import { formatDay, formatWhen } from '@/lib/format';
import { useOnline } from '@/lib/online';
import { useLiveSpots } from '@/lib/realtime/react';

type Tab = 'upcoming' | 'past';
type Plan = MyPlansData['upcoming'][number];

function spotsOf(plans: Plan[]) {
  return Object.fromEntries(
    plans.map((p) => [p.activity.id, { spotsLeft: p.activity.spotsLeft, version: p.activity.version }]),
  );
}

export function MyPlans({ data, viewerName }: { data: MyPlansData; viewerName: string }) {
  const router = useRouter();
  const online = useOnline();
  const [tab, setTab] = useState<Tab>('upcoming');
  const [signingOut, setSigningOut] = useState(false);
  // Removed bookings don't need live spots: there is nothing left to book from the card.
  const watched = data.upcoming.filter((p) => p.booking.status === 'confirmed');
  const { spots, status } = useLiveSpots(spotsOf(watched), async () =>
    spotsOf((await apiJson<MyPlansData>('/me/plans')).upcoming),
  );
  const stale = !online || status === 'reconnecting';

  async function signOut() {
    setSigningOut(true);
    await apiFetch('/sessions/current', { method: 'DELETE' }).catch(() => undefined);
    router.push('/');
    router.refresh();
  }

  const nothing = data.upcoming.length === 0 && data.past.length === 0;
  const list = tab === 'upcoming' ? data.upcoming : data.past;

  return (
    <main className="mx-auto flex w-full max-w-content flex-col gap-5 px-5 pt-1 pb-8 md:gap-6 md:px-10 md:pt-8 md:pb-16">
      <div className="flex flex-col gap-5 md:flex-row md:flex-wrap md:items-center md:justify-between md:gap-4">
        <h1 className="m-0 text-title md:text-[36px] md:leading-[42px]">My plans</h1>
        {nothing ? null : (
          <Segmented
            label="Show"
            value={tab}
            options={[
              { value: 'upcoming', label: 'Upcoming' },
              { value: 'past', label: 'Past' },
            ]}
            onChange={(v) => setTab(v as Tab)}
          />
        )}
      </div>

      {nothing ? (
        <div className="flex flex-col gap-4 md:mx-auto md:my-10 md:w-full md:max-w-[480px]">
          <EmptyState
            icon="ticket"
            title="No plans yet"
            body="When you book or claim a spot, your plan shows up here."
          />
          <Link className="vl-btn vl-btn-secondary w-full md:w-auto md:self-center" href="/">
            Browse communities
          </Link>
        </div>
      ) : list.length === 0 ? (
        <p className="m-0 text-muted">{tab === 'upcoming' ? 'Nothing coming up.' : 'No past plans yet.'}</p>
      ) : (
        <ul
          className="m-0 grid list-none grid-cols-1 gap-3 p-0 md:grid-cols-[repeat(auto-fill,minmax(min(320px,100%),1fr))] md:gap-4"
          aria-label={tab === 'upcoming' ? 'Upcoming plans' : 'Past plans'}
        >
          {list.map((p) => {
            const a = p.activity;
            const removed = p.booking.status === 'removed';
            const live = spots[a.id];
            return (
              <li key={p.planId} className="flex flex-col [&>a]:flex-1">
                <PlanCard
                  href={`/plans/${p.planId}`}
                  photoUrl={a.photoUrl}
                  scene="lake"
                  title={a.title}
                  date={
                    tab === 'past' ? formatDay(a.startsAt, a.timezone) : formatWhen(a.startsAt, a.timezone)
                  }
                  place={a.location.venueName}
                  members={p.members.preview.map((m) => ({ name: m.shortName, seed: m.avatarSeed }))}
                  memberTotal={p.members.count}
                  code={p.booking.ref}
                  removed={removed}
                  past={tab === 'past'}
                  end={
                    tab === 'upcoming' && !removed && live ? (
                      <SpotsBadge
                        spots={live.spotsLeft}
                        state={stale ? 'stale' : live.changed ? 'changed' : 'live'}
                        className="ml-auto"
                      />
                    ) : undefined
                  }
                />
              </li>
            );
          })}
        </ul>
      )}

      <div className="flex flex-col gap-2">
        <p className="m-0 text-caption text-muted">
          Plans for {viewerName}. On another phone, continue with the same number to see these.
        </p>
        <span>
          <Button variant="quiet" small loading={signingOut} onClick={() => void signOut()}>
            Sign out
          </Button>
        </span>
      </div>
    </main>
  );
}
