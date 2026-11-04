// G4 "You're in" (S6 §4.4). Server-rendered from the Plan, so a reload shows the same screen.
import type { Metadata } from 'next';
import Link from 'next/link';
import { notFound, redirect } from 'next/navigation';
import { MemberRow } from '@/components/cards';
import { LocationBlock } from '@/components/maps';
import { Button, Icon } from '@/components/primitives';
import { Vibrate } from '@/components/invite/vibrate';
import { firstName, formatDay, formatMoney, formatWhen, zoneLabel } from '@/lib/format';
import { loadInvite, loadPlan } from '@/lib/invite';
import { normaliseCode } from '@/lib/format';
import { getViewer } from '@/lib/session';

export const dynamic = 'force-dynamic';
export const metadata: Metadata = { title: 'You’re in', robots: { index: false, follow: false } };

export default async function YoureInPage({ params }: { params: Promise<{ code: string }> }) {
  const code = normaliseCode((await params).code);
  if (!code) notFound();
  const [load, viewer] = await Promise.all([loadInvite(code), getViewer()]);
  const booking = load.kind === 'ok' ? load.view.activity.viewer?.booking : null;
  if (load.kind !== 'ok' || !viewer || booking?.status !== 'confirmed') redirect(`/i/${code}`);
  const plan = await loadPlan(booking.planId);
  if (!plan) redirect(`/i/${code}`);

  const a = load.view.activity;
  const host = firstName(a.host.shortName);
  const owner = firstName(plan.owner.displayName);
  const price =
    a.priceMinor === 0
      ? 'Free'
      : `Price: ${formatMoney(a.priceMinor, a.currency)}, paid to the host on the day.`;
  return (
    <div className="min-h-dvh">
      <header className="flex items-center justify-between px-5 py-3.5">
        <Link className="vl-wordmark" href="/">
          velio
        </Link>
        <a href="/me/plans" className="text-[14px] font-bold">
          My plans
        </a>
      </header>
      <main className="mx-auto flex w-full max-w-[480px] flex-col gap-5 px-5 pt-1 pb-8">
        <Vibrate />
        <section className="flex flex-col gap-4 rounded-hero bg-lime px-5 py-6 text-forest">
          <span className="inline-flex size-12 items-center justify-center rounded-full bg-forest text-lime">
            <Icon name="check" className="size-[26px]" />
          </span>
          <h1 className="m-0 text-title text-forest" tabIndex={-1} autoFocus>
            You’re in, {firstName(viewer.displayName)}.
          </h1>
          <p className="m-0">
            {a.title} with {owner === firstName(viewer.displayName) ? 'your' : `${owner}’s`} group.{' '}
            {formatWhen(a.startsAt, a.timezone)} {zoneLabel(a.timezone)}.
          </p>
          <div className="flex flex-col gap-1 rounded-field bg-surface px-4 py-3">
            <span className="text-[12px] leading-4 font-bold tracking-[.06em] text-muted uppercase">
              Booking ref
            </span>
            <span className="text-code text-forest">{plan.viewer.booking.ref}</span>
            <span className="text-caption text-muted">
              Show this to {host} when you arrive. {price}
            </span>
          </div>
        </section>

        <section className="flex flex-col gap-3">
          <h2 className="m-0 text-heading">Your group</h2>
          <div className="vl-list">
            {plan.members.map((m) => (
              <MemberRow
                key={m.person.id}
                name={m.person.displayName}
                seed={m.person.avatarSeed}
                you={m.person.id === viewer.id}
                meta={`${m.source === 'direct' ? 'Booked' : 'Claimed'} ${formatDay(m.joinedAt, a.timezone)}`}
                source={m.source}
                sourceLabel={m.invitedBy ? `Via ${firstName(m.invitedBy.displayName)}` : undefined}
              />
            ))}
          </div>
          <Button variant="secondary" block href={`/plans/${plan.id}`}>
            See the plan
          </Button>
        </section>

        {plan.viewer.canInvite ? (
          <section className="flex flex-col gap-3">
            <h2 className="m-0 text-heading">Who’s coming with you?</h2>
            <p className="m-0 text-muted">Invites don’t hold a spot, so tell friends now.</p>
            <div className="flex flex-wrap gap-3">
              <Button icon="host" href={`/plans/${plan.id}?invite=vouch`}>
                Vouch for a friend
              </Button>
              <Button variant="secondary" icon="share" href={`/plans/${plan.id}?invite=public`}>
                Share link
              </Button>
            </div>
          </section>
        ) : null}

        <LocationBlock
          venue={a.location.venueName}
          address={a.location.addressText}
          meetingPoint={a.location.meetingPoint}
          directionsUrl={a.location.directionsUrl}
          staticMapUrl={a.location.staticMapUrl}
          map={!!a.location.staticMapUrl}
        />
      </main>
    </div>
  );
}
