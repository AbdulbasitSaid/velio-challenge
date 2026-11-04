'use client';

// B4 Plan (S5 FR-029; PRD L1, Host removal). Members see each other's full names (PRD Q12). The page
// listens to `activity:<id>` for spots and `plan:<id>` for joins and invite changes; a `plan` event
// carries only the ID, so the Plan is fetched again (S3 rule 5).
import type { NextSteps as NextStepsData, PlanView, PublicActivity } from '@velio/contracts';
import { useState } from 'react';
import { BookingRef, MemberRow } from '../cards';
import { Banner, EmptyState } from '../feedback';
import { MoreToDo } from '../invite/parts';
import { LocationBlock } from '../maps';
import { ExploreMap } from '../maps-live';
import { Button, SpotsBadge, type SpotsState } from '../primitives';
import { useFlash } from './flash';
import { promptLine } from './welcome';
import { apiJson } from '@/lib/api/client';
import { firstName, formatDay, formatMoney, formatWhen, zoneLabel } from '@/lib/format';
import { useOnline } from '@/lib/online';
import { useLiveSpots } from '@/lib/realtime/react';
import { copyText } from '@/lib/share';

type Member = PlanView['members'][number];
type PlanInvite = PlanView['invites'][number];

function sourceLabel(m: Member): string | undefined {
  if (m.source === 'vouch' && m.invitedBy) return `Via ${firstName(m.invitedBy.displayName)}`;
  return undefined;
}

function inviteRow(i: PlanInvite, viewerId: string, timezone: string) {
  const from = i.createdBy.id === viewerId ? 'you' : firstName(i.createdBy.displayName);
  if (i.rail === 'public') {
    const claims = i.claims === 1 ? '1 claim' : `${i.claims} claims`;
    return {
      name: 'Public link',
      meta: [`From ${from}`, claims, i.paused ? 'Paused' : null].filter(Boolean).join(' · '),
    };
  }
  return {
    name: `Invite for ${firstName(i.inviteeName ?? 'a friend')}`,
    meta: `Vouch from ${from} · ${formatDay(i.createdAt, timezone)}`,
  };
}

export function PlanLive({
  plan: initialPlan,
  activity,
  viewerId,
  nextSteps,
}: {
  plan: PlanView;
  activity: PublicActivity;
  viewerId: string;
  nextSteps: NextStepsData | null;
}) {
  const online = useOnline();
  const [flash, showFlash] = useFlash();
  const [plan, setPlan] = useState(initialPlan);
  const refetchPlan = async () => {
    const fresh = await apiJson<PlanView>(`/plans/${initialPlan.id}`).catch(() => null);
    if (fresh) setPlan(fresh);
  };
  const { spots, status } = useLiveSpots(
    { [activity.id]: { spotsLeft: activity.spotsLeft, version: activity.version } },
    async () => {
      const [fresh] = await Promise.all([
        apiJson<PublicActivity>(`/activities/${activity.id}`),
        refetchPlan(),
      ]);
      return { [activity.id]: { spotsLeft: fresh.spotsLeft, version: fresh.version } };
    },
    {
      extraTopics: [`plan:${initialPlan.id}`],
      onPlan: () => void refetchPlan(),
      announce: [activity.id],
    },
  );
  const live = spots[activity.id]!;
  const spotsState: SpotsState =
    !online || status === 'reconnecting' ? 'stale' : live.changed ? 'changed' : 'live';

  const a = activity;
  const removed = plan.viewer.booking.status === 'removed';
  const canInvite = plan.viewer.canInvite && !removed && live.spotsLeft > 0;
  const price =
    a.priceMinor === 0 ? 'Free' : `${formatMoney(a.priceMinor, a.currency)} · pay the host on the day`;
  const going = plan.members.length === 1 ? '1 person' : `${plan.members.length} people`;
  const loc = a.location;

  const inviteButtons = canInvite ? (
    <div className="flex flex-wrap gap-2">
      <Button small icon="host" href={`/plans/${plan.id}?invite=vouch`}>
        Vouch for a friend
      </Button>
      <Button small variant="secondary" icon="share" href={`/plans/${plan.id}?invite=public`}>
        Share link
      </Button>
    </div>
  ) : null;

  const location = (
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
      onCopy={async () =>
        showFlash(
          (await copyText(`${loc.venueName}, ${loc.addressText}`)) ? 'Address copied' : 'Couldn’t copy.',
        )
      }
    />
  );

  return (
    <main className="mx-auto flex w-full max-w-content flex-col gap-5 px-5 pt-1 pb-8 md:gap-6 md:px-10 md:pt-6 md:pb-16">
      {removed ? (
        <Banner tone="error" title="The host removed this booking.">
          Your spot was released. You can still book another date below.
        </Banner>
      ) : null}

      <div className="flex flex-col gap-3 md:flex-row md:flex-wrap md:items-end md:justify-between md:gap-4">
        <div className="flex flex-col gap-1.5">
          <span className="text-[15px] font-bold text-forest">
            {removed ? 'Your plan' : 'You’re going to'}
          </span>
          <h1 className="m-0 text-title md:text-[36px] md:leading-[42px]">
            <a href={`/activities/${a.id}`} className="text-inherit no-underline hover:underline">
              {a.title}
            </a>
          </h1>
          <span className="text-[15px] text-muted">
            {formatWhen(a.startsAt, a.timezone)} {zoneLabel(a.timezone)} · {price}
          </span>
        </div>
        <div className="flex flex-wrap items-center gap-3">
          <SpotsBadge spots={live.spotsLeft} state={spotsState} />
          {removed ? null : (
            <span className="md:hidden">
              <BookingRef code={plan.viewer.booking.ref} />
            </span>
          )}
        </div>
      </div>

      {removed ? (
        <div className="flex max-w-[640px] flex-col gap-3">
          <MoreToDo activity={a} nextSteps={nextSteps} headingLevel="h2" />
        </div>
      ) : (
        <div className="grid grid-cols-1 gap-5 md:grid-cols-[minmax(0,1fr)_minmax(320px,380px)] md:grid-rows-[auto_1fr] md:items-start md:gap-x-8 md:gap-y-5">
          <div className="flex min-w-0 flex-col gap-5 md:row-span-2 md:gap-7">
            <section className="flex flex-col gap-3" aria-labelledby="going-h">
              <div className="flex items-baseline justify-between">
                <h2 id="going-h" className="m-0 text-heading">
                  Going
                </h2>
                <span className="text-caption text-muted">{going}</span>
              </div>
              <div className="vl-list">
                {plan.members.map((m) => (
                  <MemberRow
                    key={m.person.id}
                    name={m.person.displayName}
                    seed={m.person.avatarSeed}
                    you={m.person.id === viewerId}
                    meta={`${m.source === 'direct' ? 'Booked' : 'Claimed'} ${formatDay(m.joinedAt, a.timezone)}`}
                    source={m.source}
                    sourceLabel={sourceLabel(m)}
                  />
                ))}
              </div>
            </section>

            {plan.invites.length || canInvite ? (
              <section className="flex flex-col gap-3" aria-labelledby="invites-h">
                <div className="flex flex-wrap items-center justify-between gap-3">
                  <h2 id="invites-h" className="m-0 text-heading">
                    Invites
                  </h2>
                  {plan.invites.length ? <span className="hidden md:block">{inviteButtons}</span> : null}
                </div>
                {plan.invites.length ? (
                  <>
                    <div className="vl-list">
                      {plan.invites.map((i) => {
                        const row = inviteRow(i, viewerId, a.timezone);
                        return (
                          <MemberRow key={i.id} pending name={row.name} meta={row.meta} status={i.status} />
                        );
                      })}
                    </div>
                    <p className="m-0 text-caption text-muted">
                      “Created” means the link exists; we can’t see whether it was sent.
                    </p>
                    <span className="md:hidden">{inviteButtons}</span>
                  </>
                ) : (
                  <>
                    <EmptyState
                      icon="people"
                      title="Who’s coming with you?"
                      body={promptLine(live.spotsLeft)}
                    />
                    {inviteButtons}
                  </>
                )}
              </section>
            ) : null}
          </div>

          <div className="hidden flex-col gap-3 rounded-hero bg-surface p-5 md:col-start-2 md:row-start-1 md:flex">
            <BookingRef code={plan.viewer.booking.ref} />
            <span className="text-caption text-muted">
              Show this to {firstName(a.host.shortName)} when you arrive.
            </span>
          </div>
          <div className="min-w-0 md:col-start-2 md:row-start-2 md:rounded-hero md:bg-surface md:p-5">
            {location}
          </div>
        </div>
      )}
      {flash}
    </main>
  );
}
