'use client';

// B1 activity page (S5 FR-023–FR-025). Server-rendered first; after hydration the spots follow the six
// realtime rules, and Book runs one attempt per Idempotency-Key: "Booking…" at once, success only when
// the API confirms, then B2 (`/plans/<id>?welcome=1`).
import type { BookingResponse, NextSteps as NextStepsData, PublicActivity } from '@velio/contracts';
import { useRouter } from 'next/navigation';
import { useEffect, useRef, useState, type ReactNode } from 'react';
import { DetailRows } from '../cards';
import { Banner } from '../feedback';
import { activityRows, HostCard, MoreToDo } from '../invite/parts';
import { LocationBlock } from '../maps';
import { ExploreMap } from '../maps-live';
import { AvatarStack, Button, Icon, Photo, SpotsBadge, type SpotsState } from '../primitives';
import { apiJson } from '@/lib/api/client';
import { attemptKey, clearAttemptKey } from '@/lib/attempt-key';
import { bookingOutcome, bookingScope } from '@/lib/booking';
import { formatMoney, formatTime, zoneLabel } from '@/lib/format';
import { useOnline } from '@/lib/online';
import { useLiveSpots } from '@/lib/realtime/react';

type Attempt = 'idle' | 'booking' | 'sold-out' | 'error' | 'started' | 'paused';

export function ActivityLive({
  activity,
  signedIn,
  initialNextSteps,
}: {
  activity: PublicActivity;
  signedIn: boolean;
  initialNextSteps: NextStepsData | null;
}) {
  const router = useRouter();
  const online = useOnline();
  const { spots, status } = useLiveSpots(
    { [activity.id]: { spotsLeft: activity.spotsLeft, version: activity.version } },
    async () => {
      const fresh = await apiJson<PublicActivity>(`/activities/${activity.id}`);
      return { [activity.id]: { spotsLeft: fresh.spotsLeft, version: fresh.version } };
    },
    { announce: [activity.id] },
  );
  const live = spots[activity.id]!;
  const spotsState: SpotsState =
    !online || status === 'reconnecting' ? 'stale' : live.changed ? 'changed' : 'live';

  const [attempt, setAttempt] = useState<Attempt>('idle');
  const bannerRef = useRef<HTMLDivElement>(null);
  useEffect(() => {
    if (attempt === 'error' || attempt === 'sold-out') bannerRef.current?.focus();
  }, [attempt]);

  const booking = activity.viewer?.booking ?? null;
  const started = activity.status === 'started' || attempt === 'started';
  const paused = activity.bookingsPaused || attempt === 'paused';
  const soldOut = live.spotsLeft <= 0 || attempt === 'sold-out';
  const needsNextSteps = booking?.status === 'removed' || started || (soldOut && !booking);

  // Reached live (sold out while open, or a rejected attempt): fetch next steps then.
  const [nextSteps, setNextSteps] = useState(initialNextSteps);
  useEffect(() => {
    if (!needsNextSteps || nextSteps) return;
    let stale = false;
    apiJson<NextStepsData>(`/activities/${activity.id}/next-steps`)
      .then((n) => !stale && setNextSteps(n))
      .catch(() => undefined);
    return () => {
      stale = true;
    };
  }, [needsNextSteps, nextSteps, activity.id]);

  async function book() {
    if (attempt === 'booking' || !online) return;
    setAttempt('booking');
    const scope = bookingScope(activity.id);
    try {
      const res = await apiJson<BookingResponse>(`/activities/${activity.id}/bookings`, {
        method: 'POST',
        idempotencyKey: attemptKey(scope),
        headers: { 'x-client': 'web' },
      });
      clearAttemptKey(scope);
      router.push(`/plans/${res.booking.planId}?welcome=1`);
    } catch (err) {
      const outcome = bookingOutcome(err);
      if (outcome.kind !== 'error') clearAttemptKey(scope);
      switch (outcome.kind) {
        case 'signin':
          router.push(`/signin?next=${encodeURIComponent(`/activities/${activity.id}`)}`);
          return;
        case 'refresh':
          setAttempt('idle');
          router.refresh();
          return;
        default:
          setAttempt(outcome.kind);
      }
    }
  }

  const priceNote =
    activity.priceMinor === 0
      ? 'Free. Velio doesn’t take payment.'
      : `${formatMoney(activity.priceMinor, activity.currency)} · pay the host on the day. Velio doesn’t take payment.`;

  let action: ReactNode;
  if (activity.viewer?.isHost) {
    action = (
      <>
        <p className="m-0 text-center text-muted">You’re the host of this activity.</p>
        <Button block variant="secondary" href={`/host/activities/${activity.id}/attendance`}>
          Open live attendance
        </Button>
      </>
    );
  } else if (booking?.status === 'confirmed') {
    action = (
      <div className="flex items-center gap-3 rounded-card bg-lime px-4 py-3.5 text-forest">
        <Icon name="check" />
        <strong className="flex-1">You’re already going</strong>
        <a href={`/plans/${booking.planId}`} className="font-bold">
          Open plan
        </a>
      </div>
    );
  } else if (booking?.status === 'removed') {
    action = (
      <>
        <Banner title="The host removed your booking for this activity.">
          Your spot was released. You can still book another date.
        </Banner>
        <MoreToDo activity={activity} nextSteps={nextSteps} />
      </>
    );
  } else if (started) {
    action = (
      <>
        <Banner icon="clock" title="This activity has started.">
          Bookings closed at {formatTime(activity.startsAt, activity.timezone)} {zoneLabel(activity.timezone)}
          .
        </Banner>
        <MoreToDo activity={activity} nextSteps={nextSteps} />
        <Button block disabled>
          Bookings closed
        </Button>
      </>
    );
  } else if (paused) {
    action = (
      <>
        <Banner title="Bookings are paused for this activity.">
          Nothing has changed for people already going. Check back soon.
        </Banner>
        <Button block disabled>
          Bookings paused
        </Button>
      </>
    );
  } else if (attempt === 'sold-out') {
    action = (
      <>
        <div ref={bannerRef} tabIndex={-1} className="outline-none">
          <Banner tone="error" title="Someone just took the last spot.">
            We didn’t book or charge you.
          </Banner>
        </div>
        <MoreToDo activity={activity} nextSteps={nextSteps} />
      </>
    );
  } else if (soldOut) {
    action = (
      <>
        <Button block disabled>
          Sold out
        </Button>
        <MoreToDo activity={activity} nextSteps={nextSteps} />
      </>
    );
  } else {
    action = (
      <>
        {attempt === 'error' ? (
          <div ref={bannerRef} tabIndex={-1} className="outline-none">
            <Banner tone="error" title="We couldn’t confirm your spot. Nothing was booked.">
              Try again. You won’t be booked twice.
            </Banner>
          </div>
        ) : null}
        {!signedIn ? (
          <Button block href={`/signin?next=${encodeURIComponent(`/activities/${activity.id}`)}`}>
            Book a spot
          </Button>
        ) : !online ? (
          <Button block disabled>
            Reconnect to book
          </Button>
        ) : (
          <Button block loading={attempt === 'booking'} onClick={book}>
            {attempt === 'booking' ? 'Booking…' : attempt === 'error' ? 'Try again' : 'Book a spot'}
          </Button>
        )}
      </>
    );
  }

  const dimmed = soldOut || started;
  const people = activity.members.preview.map((p) => ({ name: p.shortName, seed: p.avatarSeed }));
  const loc = activity.location;

  return (
    <main className="mx-auto grid w-full max-w-content grid-cols-1 gap-5 px-5 pt-1 pb-8 md:grid-cols-[minmax(0,1fr)_minmax(320px,380px)] md:grid-rows-[auto_auto_auto_auto_auto_1fr] md:items-start md:gap-x-10 md:gap-y-6 md:px-10 md:pt-6 md:pb-16">
      <nav aria-label="Breadcrumb" className="text-[14px] md:col-span-2">
        <a
          href={`/communities/${activity.community.slug}`}
          className="inline-flex items-center gap-1 font-bold no-underline md:hidden"
        >
          <Icon name="back" />
          {activity.community.name}
        </a>
        <span className="hidden text-muted md:inline">
          <a href={`/communities/${activity.community.slug}`} className="font-bold">
            {activity.community.name}
          </a>{' '}
          / {activity.title}
        </span>
      </nav>

      <div
        className={`relative aspect-[16/10] overflow-hidden rounded-hero bg-forest md:col-start-1 md:aspect-video [&>img]:absolute [&>img]:inset-0 [&>img]:size-full [&>img]:object-cover [&>svg]:absolute [&>svg]:inset-0 [&>svg]:size-full ${dimmed ? '[&>img]:opacity-55 [&>svg]:opacity-55' : ''}`}
      >
        <Photo src={activity.photoUrl} alt={activity.title} priority />
        <div className="absolute bottom-3 left-3 md:hidden">
          <SpotsBadge spots={live.spotsLeft} state={spotsState} />
        </div>
      </div>

      <h1 className="m-0 text-display text-balance md:col-start-1 md:text-[48px] md:leading-[52px]">
        {activity.title}
      </h1>

      <aside className="flex flex-col gap-4 md:col-start-2 md:row-span-5 md:row-start-2 md:rounded-hero md:bg-surface md:p-6">
        <SpotsBadge spots={live.spotsLeft} state={spotsState} className="hidden self-start md:inline-flex" />
        <DetailRows
          rows={[...activityRows(activity), { icon: 'people', value: `${activity.capacity} spots in total` }]}
        />
        <AvatarStack people={people} total={activity.members.count} />
        <section className="flex flex-col gap-3" aria-label="Booking">
          {action}
          <p className="m-0 text-center text-caption text-muted">{priceNote}</p>
        </section>
        <div className="hidden md:block">
          <HostCard activity={activity} />
        </div>
      </aside>

      <hr className="my-1 border-0 border-t border-line md:hidden" />

      {activity.description ? (
        <section className="flex max-w-[640px] flex-col gap-2 md:col-start-1">
          <h2 className="m-0 text-heading">About</h2>
          <p className="m-0 whitespace-pre-line md:text-[16px] md:leading-6">{activity.description}</p>
        </section>
      ) : null}

      <div className="max-w-[640px] md:col-start-1">
        <LocationBlock
          venue={loc.venueName}
          address={loc.addressText}
          meetingPoint={loc.meetingPoint}
          directionsUrl={loc.directionsUrl}
          mapSlot={
            online ? (
              <ExploreMap lat={loc.lat} lng={loc.lng} venue={loc.venueName} staticMapUrl={loc.staticMapUrl} />
            ) : undefined
          }
          map={!!loc.staticMapUrl}
          mapState="offline"
        />
      </div>

      <div className="md:hidden">
        <HostCard activity={activity} />
      </div>
    </main>
  );
}
