'use client';

// G1 (vouch), G2 (public) and G5 (sold out), switching live as spots change (S6 §4.3, §4.5). Server-
// rendered first; after hydration it follows the six realtime rules, sends the open beacon once after
// paint, and disables claiming while offline (claims are never queued).
import type { InviteView, NextSteps as NextStepsData, PublicActivity } from '@velio/contracts';
import Link from 'next/link';
import { useEffect, useState, useSyncExternalStore } from 'react';
import { NextSteps } from '../cards';
import { Banner } from '../feedback';
import { LocationBlock } from '../maps';
import { AvatarStack, Button, LivePill } from '../primitives';
import {
  About,
  Details,
  Hero,
  HostCard,
  InviteMain,
  InviterLead,
  MoreToDo,
  tellInviterMessage,
  whatsappHref,
} from './parts';
import { apiFetch } from '@/lib/api/client';
import { firstName, formatDay } from '@/lib/format';
import { selectScreen } from '@/lib/invite-screen';
import { useLiveSpots } from '@/lib/realtime/react';

function subscribeOnline(cb: () => void) {
  window.addEventListener('online', cb);
  window.addEventListener('offline', cb);
  return () => {
    window.removeEventListener('online', cb);
    window.removeEventListener('offline', cb);
  };
}

export function useOnline(): boolean {
  return useSyncExternalStore(
    subscribeOnline,
    () => navigator.onLine,
    () => true,
  );
}

/** PRD Scope challenge 2: an open counts only when a real browser paints the page; bots never run this. */
function useOpenBeacon(code: string) {
  useEffect(() => {
    let frame = requestAnimationFrame(() => {
      frame = requestAnimationFrame(() => {
        void apiFetch(`/invites/${code}/opens`, { method: 'POST', body: { platform: 'web' } }).catch(
          () => undefined,
        );
      });
    });
    return () => cancelAnimationFrame(frame);
  }, [code]);
}

export function InviteLive({
  view,
  initialNextSteps,
}: {
  view: InviteView;
  initialNextSteps: NextStepsData | null;
}) {
  const activity = view.activity;
  const online = useOnline();
  const { spots, status } = useLiveSpots(
    { [activity.id]: { spotsLeft: activity.spotsLeft, version: activity.version } },
    async () => {
      const fresh = (await apiFetch(`/activities/${activity.id}`)) as unknown as PublicActivity;
      return { [activity.id]: { spotsLeft: fresh.spotsLeft, version: fresh.version } };
    },
    { announce: [activity.id] },
  );
  useOpenBeacon(view.code);

  const live = spots[activity.id]!;
  const screen = selectScreen(view, live.spotsLeft);
  const spotsState = !online || status === 'reconnecting' ? 'stale' : live.changed ? 'changed' : 'live';

  // G5 reached live: fetch next steps then (the server only fetched them for an initial sold-out).
  const [nextSteps, setNextSteps] = useState(initialNextSteps);
  const soldOut = screen.kind === 'sold-out';
  useEffect(() => {
    if (!soldOut || nextSteps) return;
    let stale = false;
    apiFetch(`/activities/${activity.id}/next-steps`)
      .then((n) => !stale && setNextSteps(n as unknown as NextStepsData))
      .catch(() => undefined);
    return () => {
      stale = true;
    };
  }, [soldOut, nextSteps, activity.id]);

  return (
    <>
      <header className="flex items-center justify-between px-5 py-3.5">
        <Link className="vl-wordmark" href="/">
          velio
        </Link>
        <LivePill status={!online ? 'offline' : status === 'reconnecting' ? 'reconnecting' : 'live'} />
      </header>
      {soldOut ? (
        <SoldOut view={view} spotsState={spotsState} nextSteps={nextSteps} />
      ) : (
        <Open
          view={view}
          screen={screen}
          online={online}
          spotsLeft={live.spotsLeft}
          spotsState={spotsState}
        />
      )}
    </>
  );
}

function Open({
  view,
  screen,
  online,
  spotsLeft,
  spotsState,
}: {
  view: InviteView;
  screen: ReturnType<typeof selectScreen>;
  online: boolean;
  spotsLeft: number;
  spotsState: 'live' | 'changed' | 'stale';
}) {
  const activity = view.activity;
  const block = screen.kind === 'open' ? screen.block : null;
  const people = activity.members.preview.map((p) => ({ name: p.shortName, seed: p.avatarSeed }));
  return (
    <InviteMain>
      {!online ? (
        <Banner tone="offline" title="You're offline">
          Reconnect to claim. The count may have changed.
        </Banner>
      ) : null}
      <InviterLead view={view} />
      <Hero activity={activity} spotsLeft={spotsLeft} spotsState={spotsState} />
      <h1 className="m-0 text-display text-balance text-ink">{activity.title}</h1>
      <section className="flex flex-col gap-3 rounded-card bg-surface p-4">
        <AvatarStack people={people} total={activity.members.count} />
        {view.rail === 'public' ? (
          <p className="m-0 text-caption text-muted">
            Shared by {view.inviter.shortName} in {activity.community.name}
          </p>
        ) : null}
      </section>
      <Details activity={activity} />
      <div className="flex flex-col gap-2.5">
        {block === 'host' ? (
          <>
            <p className="m-0 text-center text-muted">You’re the host of this activity.</p>
            <Button block variant="secondary" href={`/host/activities/${activity.id}/attendance`}>
              Open live attendance
            </Button>
          </>
        ) : block === 'already-going' ? (
          <>
            <Banner title="You're already going.">Your spot is booked. Invite friends from your plan.</Banner>
            <Button block href={`/plans/${activity.viewer!.booking!.planId}`}>
              Open the plan
            </Button>
          </>
        ) : block === 'bookings-paused' ? (
          <>
            <Banner title="Bookings are paused for this activity.">
              Nothing has changed for people already going. Check back soon.
            </Banner>
            <Button block disabled>
              Claim my spot
            </Button>
          </>
        ) : online ? (
          <>
            <Button block href={`/i/${view.code}/claim`}>
              Claim my spot
            </Button>
            <p className="m-0 text-center text-caption text-muted">
              Spots aren’t held. Claim while they last.
            </p>
          </>
        ) : (
          <Button block disabled>
            Reconnect to claim
          </Button>
        )}
      </div>
      <hr className="my-1 border-0 border-t border-line" />
      <About activity={activity} />
      <LocationBlock
        venue={activity.location.venueName}
        address={activity.location.addressText}
        meetingPoint={activity.location.meetingPoint}
        directionsUrl={activity.location.directionsUrl}
        staticMapUrl={activity.location.staticMapUrl}
        map={!!activity.location.staticMapUrl}
        mapState={online ? 'static' : 'offline'}
      />
      <HostCard activity={activity} />
    </InviteMain>
  );
}

function SoldOut({
  view,
  spotsState,
  nextSteps,
}: {
  view: InviteView;
  spotsState: 'live' | 'changed' | 'stale';
  nextSteps: NextStepsData | null;
}) {
  const activity = view.activity;
  const inviter = firstName(view.inviter.shortName);
  const message = tellInviterMessage(activity);
  return (
    <InviteMain>
      <Hero activity={activity} spotsLeft={0} spotsState={spotsState} />
      <div className="flex flex-col gap-1.5">
        <span className="text-caption text-muted">
          {activity.title} · {formatDay(activity.startsAt, activity.timezone)}
        </span>
        <h1 className="m-0 text-title">This one filled up before you got here.</h1>
      </div>
      <AvatarStack
        people={activity.members.preview.map((p) => ({ name: p.shortName, seed: p.avatarSeed }))}
        total={activity.members.count}
      />
      <section className="flex flex-col gap-3">
        <h2 className="m-0 text-heading">What you can do</h2>
        <TellInviter inviter={inviter} message={message} />
        <MoreToDo activity={activity} nextSteps={nextSteps} />
      </section>
    </InviteMain>
  );
}

/** "Tell {Inviter}": the share sheet where there is one, WhatsApp otherwise (S6 §4.3). */
export function TellInviter({ inviter, message }: { inviter: string; message: string }) {
  return (
    <div
      onClickCapture={(e) => {
        if (typeof navigator.share !== 'function') return;
        e.preventDefault();
        navigator.share({ text: message }).catch(() => undefined);
      }}
    >
      <NextSteps
        items={[
          {
            icon: 'share',
            title: `Tell ${inviter}`,
            meta: 'Let them know it filled up',
            href: whatsappHref(message),
          },
        ]}
      />
    </div>
  );
}
