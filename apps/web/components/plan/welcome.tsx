'use client';

// B2 "You're going" with the invite step first (S5 FR-026; PRD Flows, Booker 3–4, R6). Shown once per
// booking: B1 lands here with `?welcome=1`, which is dropped from the address at once, so a reload or a
// return to the page shows the Plan instead.
import type { PlanView, PublicActivity } from '@velio/contracts';
import { useEffect } from 'react';
import { Icon, SpotsBadge, type IconName } from '../primitives';
import { apiJson } from '@/lib/api/client';
import { formatWhen, zoneLabel } from '@/lib/format';
import { useOnline } from '@/lib/online';
import { useLiveSpots } from '@/lib/realtime/react';

function promptLine(spotsLeft: number): string {
  const n = spotsLeft === 1 ? '1 spot' : `${spotsLeft} spots`;
  return `Only ${n} left. Invites don’t hold a spot, so tell friends now.`;
}

function Choice({
  href,
  icon,
  tone,
  title,
  body,
  primary,
}: {
  href: string;
  icon: IconName;
  tone: 'lime' | 'sky';
  title: string;
  body: string;
  primary?: boolean;
}) {
  return (
    <a
      href={href}
      className={`flex items-start gap-3.5 rounded-card bg-surface p-[18px] text-ink no-underline ${primary ? 'shadow-[inset_0_0_0_2px_var(--color-forest)]' : ''}`}
    >
      <span
        className={`inline-flex size-11 flex-none items-center justify-center rounded-full text-forest ${tone === 'lime' ? 'bg-lime' : 'bg-sky'}`}
      >
        <Icon name={icon} />
      </span>
      <span className="flex flex-1 flex-col gap-1">
        <strong className="text-[17px]">{title}</strong>
        <span className="text-[14px] leading-5 text-muted">{body}</span>
      </span>
      <span className="self-center text-forest">
        <Icon name="chevron" />
      </span>
    </a>
  );
}

export function Welcome({
  plan,
  spots: initial,
}: {
  plan: PlanView;
  spots: { spotsLeft: number; version: number };
}) {
  const a = plan.activity;
  const online = useOnline();
  const { spots, status } = useLiveSpots({ [a.id]: initial }, async () => {
    const fresh = await apiJson<PublicActivity>(`/activities/${a.id}`);
    return { [a.id]: { spotsLeft: fresh.spotsLeft, version: fresh.version } };
  });
  const live = spots[a.id]!;

  useEffect(() => {
    window.history.replaceState(window.history.state, '', `/plans/${plan.id}`);
  }, [plan.id]);

  const canInvite = plan.viewer.canInvite && live.spotsLeft > 0;
  return (
    <main className="mx-auto flex w-full max-w-[480px] flex-col gap-5 px-5 pt-1 pb-8 md:pt-6">
      <section className="flex items-center gap-3.5 rounded-hero bg-lime p-4 text-forest">
        <span className="inline-flex size-11 flex-none items-center justify-center rounded-full bg-forest text-lime">
          <Icon name="check" />
        </span>
        <div className="flex min-w-0 flex-col">
          <span className="text-[14px]">You’re going to</span>
          <strong className="font-display text-[20px] leading-[26px]">{a.title}</strong>
          <span className="text-caption">
            {formatWhen(a.startsAt, a.timezone)} {zoneLabel(a.timezone)} · {plan.viewer.booking.ref}
          </span>
        </div>
      </section>

      {canInvite ? (
        <>
          <section className="flex flex-col gap-3">
            <h1 className="m-0 text-title">Who’s coming with you?</h1>
            <p className="m-0 text-muted">{promptLine(live.spotsLeft)}</p>
            <span>
              <SpotsBadge
                spots={live.spotsLeft}
                state={!online || status === 'reconnecting' ? 'stale' : live.changed ? 'changed' : 'live'}
              />
            </span>
          </section>
          <Choice
            primary
            href={`/plans/${plan.id}?invite=vouch`}
            icon="host"
            tone="lime"
            title="Vouch for a friend"
            body="One invite, one person. It shows your name, so they know it’s from you."
          />
          <Choice
            href={`/plans/${plan.id}?invite=public`}
            icon="share"
            tone="sky"
            title="Share a link"
            body="For a group chat or a community thread. Anyone with it can claim a spot while spots last."
          />
        </>
      ) : null}

      <a className="vl-btn vl-btn-quiet self-center" href={`/plans/${plan.id}`}>
        Go to my plan
      </a>
    </main>
  );
}
