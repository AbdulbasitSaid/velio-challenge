// Building blocks shared by the invite screens (G1–G7). Hook-free: rendered on the server, and inside the
// live island.
import type { ActivityCard, InviteView, NextSteps as NextStepsData, PublicActivity } from '@velio/contracts';
import type { ReactNode } from 'react';
import { DetailRows, NextSteps, type NextStep } from '../cards';
import { Avatar, Photo, SpotsBadge, type SpotsState } from '../primitives';
import {
  firstName,
  formatDay,
  formatMoney,
  formatTime,
  formatWhen,
  spotsLabel,
  zoneLabel,
} from '@/lib/format';

export function InviteMain({ children, className = '' }: { children: ReactNode; className?: string }) {
  return (
    <main className={`mx-auto flex w-full max-w-[480px] flex-col gap-5 px-5 pt-1 pb-8 ${className}`}>
      {children}
    </main>
  );
}

export function Hero({
  activity,
  spotsLeft,
  spotsState,
}: {
  activity: PublicActivity;
  spotsLeft: number;
  spotsState: SpotsState;
}) {
  return (
    <div className="relative aspect-[16/10] overflow-hidden rounded-hero bg-forest [&>img]:absolute [&>img]:inset-0 [&>img]:size-full [&>img]:object-cover [&>svg]:absolute [&>svg]:inset-0 [&>svg]:size-full">
      <Photo src={activity.photoUrl} alt={activity.title} priority />
      <div className="absolute bottom-3 left-3">
        <SpotsBadge spots={spotsLeft} state={spotsState} />
      </div>
    </div>
  );
}

export function activityRows(activity: PublicActivity) {
  return [
    {
      icon: 'calendar' as const,
      value: formatWhen(activity.startsAt, activity.timezone),
      sub: zoneLabel(activity.timezone),
    },
    { icon: 'pin' as const, value: activity.location.venueName, sub: activity.location.addressText },
    {
      icon: 'price' as const,
      value:
        activity.priceMinor === 0
          ? 'Free'
          : `${formatMoney(activity.priceMinor, activity.currency)} · pay the host on the day`,
    },
  ];
}

export function Details({ activity }: { activity: PublicActivity }) {
  return <DetailRows rows={activityRows(activity)} />;
}

export function About({ activity }: { activity: PublicActivity }) {
  if (!activity.description) return null;
  return (
    <section className="flex flex-col gap-2">
      <h2 className="m-0 text-heading">About</h2>
      <p className="m-0 whitespace-pre-line">{activity.description}</p>
    </section>
  );
}

export function HostCard({ activity }: { activity: PublicActivity }) {
  return (
    <section className="flex items-center gap-3 rounded-card bg-surface px-4 py-3.5">
      <Avatar name={activity.host.shortName} seed={activity.host.avatarSeed} size={44} />
      <div className="flex min-w-0 flex-1 flex-col">
        <strong>Hosted by {activity.host.shortName}</strong>
        <span className="text-caption text-muted">{activity.community.name}</span>
      </div>
      <a href={`/users/${activity.host.id}`} className="text-[14px] font-bold text-forest">
        Profile
      </a>
    </section>
  );
}

/** The inviter's lead line: G1 (vouch) or G2 (public). */
export function InviterLead({ view }: { view: InviteView }) {
  if (view.rail === 'public') {
    return (
      <div className="flex flex-col items-start gap-2.5">
        <span className="vl-chip vl-chip-outline">{view.activity.community.name}</span>
        <p className="m-0 text-[17px] leading-6 text-forest">Join the group going to</p>
      </div>
    );
  }
  return (
    <>
      <div className="flex items-center gap-2.5">
        <Avatar name={view.inviter.shortName} seed={view.inviter.avatarSeed} size={36} />
        <p className="m-0 text-[17px] leading-6 text-forest">
          <strong>{firstName(view.inviter.shortName)}</strong> wants you on
        </p>
      </div>
      {view.note ? (
        <blockquote className="m-0 rounded-card bg-surface px-4 py-3.5">
          “{view.note}”
          <span className="mt-1.5 block text-caption text-muted">
            Note from {firstName(view.inviter.shortName)}
          </span>
        </blockquote>
      ) : null}
    </>
  );
}

function cardStep(
  card: ActivityCard,
  title: (c: ActivityCard) => string,
  meta: (c: ActivityCard) => string,
): NextStep {
  return {
    href: `/activities/${card.id}`,
    photoUrl: card.photoUrl,
    scene: 'lake',
    title: title(card),
    meta: meta(card),
  };
}

/** "{Host}'s other dates" and "More in {Community}"; empty blocks are hidden (UX FR-007). */
export function MoreToDo({
  activity,
  nextSteps,
  headingLevel = 'h3',
}: {
  activity: PublicActivity;
  nextSteps: NextStepsData | null;
  headingLevel?: 'h2' | 'h3';
}) {
  if (!nextSteps) return null;
  const H = headingLevel;
  const host = firstName(activity.host.shortName);
  return (
    <>
      {nextSteps.hostOtherDates.length ? (
        <>
          <H className="m-0 text-subheading">{host}’s other dates</H>
          <NextSteps
            items={nextSteps.hostOtherDates.map((c) =>
              cardStep(
                c,
                (x) => `${x.title} · ${formatDay(x.startsAt, x.timezone)}`,
                (x) =>
                  `${formatTime(x.startsAt, x.timezone)} ${zoneLabel(x.timezone)} · ${spotsLabel(x.spotsLeft)}`,
              ),
            )}
          />
        </>
      ) : null}
      {nextSteps.moreInCommunity.length ? (
        <>
          <H className="m-0 text-subheading">More in {activity.community.name}</H>
          <NextSteps
            items={nextSteps.moreInCommunity.map((c) =>
              cardStep(
                c,
                (x) => x.title,
                (x) => `${formatDay(x.startsAt, x.timezone)} · ${spotsLabel(x.spotsLeft)}`,
              ),
            )}
          />
        </>
      ) : null}
    </>
  );
}

/** The prefilled reply behind "Tell {Inviter}" (S6 §12 Q3, approved). */
export function tellInviterMessage(activity: PublicActivity): string {
  return `${activity.title} on ${formatDay(activity.startsAt, activity.timezone)} filled up before I could claim. Let's find another date?`;
}

export function whatsappHref(text: string): string {
  return `https://wa.me/?text=${encodeURIComponent(text)}`;
}
