// Server-rendered invite outcomes: G6 expired, G7 already claimed (own / other), paused link (S6 §12 Q2,
// copy approved). Each ends with a next step (PRD Q9).
import type { InviteView, NextSteps as NextStepsData, PlanView } from '@velio/contracts';
import Link from 'next/link';
import type { ReactNode } from 'react';
import { NextSteps, PlanCard } from '../cards';
import { Button, Icon, type IconName } from '../primitives';
import { InviteMain, MoreToDo } from './parts';
import { firstName, formatDay, formatWhen, zoneLabel } from '@/lib/format';

export function InviteHeader({ end }: { end?: ReactNode }) {
  return (
    <header className="flex items-center justify-between px-5 py-3.5">
      <Link className="vl-wordmark" href="/">
        velio
      </Link>
      {end}
    </header>
  );
}

function Mark({ icon }: { icon: IconName }) {
  return (
    <span className="inline-flex size-12 items-center justify-center rounded-full bg-surface text-forest">
      <Icon name={icon} />
    </span>
  );
}

function Lead({ view }: { view: InviteView }) {
  const a = view.activity;
  return (
    <span className="text-caption text-muted">
      {a.title} · {formatWhen(a.startsAt, a.timezone)} {zoneLabel(a.timezone)}
    </span>
  );
}

export function Expired({ view, nextSteps }: { view: InviteView; nextSteps: NextStepsData }) {
  const inviter = view.inviter;
  return (
    <InviteMain className="pt-6">
      <Mark icon="clock" />
      <div className="flex flex-col gap-2">
        <Lead view={view} />
        <h1 className="m-0 text-title">This invite expired when the activity started.</h1>
        <p className="m-0 text-muted">
          Bookings close at the start time. Here are a few ways to still get out together.
        </p>
      </div>
      <section className="flex flex-col gap-3">
        <NextSteps
          items={[
            {
              icon: 'host',
              title: `See ${firstName(inviter.shortName)}’s profile`,
              meta: inviter.shortName,
              href: `/users/${inviter.id}`,
            },
          ]}
        />
        <MoreToDo activity={view.activity} nextSteps={nextSteps} headingLevel="h2" />
      </section>
    </InviteMain>
  );
}

export function Paused({ view, nextSteps }: { view: InviteView; nextSteps: NextStepsData }) {
  return (
    <InviteMain className="pt-6">
      <Mark icon="lock" />
      <div className="flex flex-col gap-2">
        <Lead view={view} />
        <h1 className="m-0 text-title">This link is paused.</h1>
        <p className="m-0 text-muted">
          {firstName(view.inviter.shortName)} can send you a new invite, or pick another date below.
        </p>
      </div>
      <section className="flex flex-col gap-3">
        <MoreToDo activity={view.activity} nextSteps={nextSteps} headingLevel="h2" />
      </section>
    </InviteMain>
  );
}

export function ClaimedOther({ view }: { view: InviteView }) {
  const inviter = firstName(view.inviter.shortName);
  const a = view.activity;
  return (
    <InviteMain className="pt-6">
      <Mark icon="ticket" />
      <h1 className="m-0 text-title">This invite has already been claimed.</h1>
      <p className="m-0 text-muted">
        A vouch invite is for one person. If it was meant for you, ask {inviter} for a new one. If you claimed
        it on another phone, continue with the same phone number or email to see your booking.
      </p>
      <NextSteps
        items={[
          {
            icon: 'phone',
            title: 'Continue with your phone or email',
            meta: 'See bookings from another device',
            href: `/signin?next=/me/plans`,
          },
          {
            photoUrl: a.photoUrl,
            scene: 'lake',
            title: a.title,
            meta: `${formatDay(a.startsAt, a.timezone)} · see the activity`,
            href: `/activities/${a.id}`,
          },
        ]}
      />
    </InviteMain>
  );
}

export function ClaimedOwn({
  view,
  plan,
  viewer,
}: {
  view: InviteView;
  plan: PlanView | null;
  viewer: { id: string; displayName: string };
}) {
  const a = view.activity;
  const planId = a.viewer?.booking?.planId;
  const joined = plan?.members.find((m) => m.person.id === viewer.id)?.joinedAt;
  return (
    <InviteMain className="pt-6">
      <h1 className="m-0 text-title">You’re already going, {firstName(viewer.displayName)}.</h1>
      <p className="m-0 text-muted">
        You claimed this invite{joined ? ` on ${formatDay(joined, a.timezone)}` : ''}. Here’s your booking.
      </p>
      {planId ? (
        <>
          <PlanCard
            title={a.title}
            href={`/plans/${planId}`}
            photoUrl={a.photoUrl}
            date={formatWhen(a.startsAt, a.timezone)}
            place={a.location.venueName}
            members={plan?.members.map((m) => ({ name: m.person.displayName, seed: m.person.avatarSeed }))}
            memberTotal={plan?.members.length}
            code={plan?.viewer.booking.ref}
          />
          <Button block href={`/plans/${planId}`}>
            Open the plan
          </Button>
        </>
      ) : null}
    </InviteMain>
  );
}
