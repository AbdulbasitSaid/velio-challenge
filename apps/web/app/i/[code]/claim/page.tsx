// G3 claim step (S6 §4.4): its own route so Back returns to the invite and the page stays light.
import type { Metadata } from 'next';
import { notFound, redirect } from 'next/navigation';
import { ClaimForm } from '@/components/invite/claim-form';
import { Icon, Photo, SpotsBadge } from '@/components/primitives';
import { firstName, formatWhen, normaliseCode, zoneLabel } from '@/lib/format';
import { loadInvite } from '@/lib/invite';
import { selectScreen } from '@/lib/invite-screen';
import { getViewer } from '@/lib/session';

export const dynamic = 'force-dynamic';
export const metadata: Metadata = { title: 'Claim your spot', robots: { index: false, follow: false } };

export default async function ClaimPage({ params }: { params: Promise<{ code: string }> }) {
  const code = normaliseCode((await params).code);
  if (!code) notFound();
  const load = await loadInvite(code);
  if (load.kind === 'invalid') notFound();
  const screen = load.kind === 'ok' ? selectScreen(load.view) : null;
  // Anything but a claimable invite shows its state on the invite page.
  if (load.kind !== 'ok' || screen?.kind !== 'open' || screen.block) redirect(`/i/${code}`);

  const { view } = load;
  const a = view.activity;
  const viewer = await getViewer();
  const inviter = firstName(view.inviter.shortName);
  const host = firstName(a.host.shortName);
  return (
    <div className="min-h-dvh">
      <header className="mx-auto flex w-full max-w-[480px] items-center gap-2 px-3 py-2">
        <a href={`/i/${code}`} className="vl-iconbtn" aria-label="Back to the invite">
          <Icon name="back" />
        </a>
        <span className="flex-1 font-bold">
          {view.rail === 'vouch' ? `Invite from ${inviter}` : a.community.name}
        </span>
        <span className="vl-chip tracking-[1px] tabular-nums">Code {code}</span>
      </header>
      <main className="mx-auto flex w-full max-w-[480px] flex-col gap-5 px-5 pt-2 pb-8">
        <div className="flex items-center gap-3 rounded-card bg-surface p-3">
          <div className="size-16 flex-none overflow-hidden rounded-small [&>img]:size-full [&>img]:object-cover [&>svg]:size-full">
            <Photo src={a.photoUrl} alt="" />
          </div>
          <div className="flex min-w-0 flex-1 flex-col gap-1">
            <strong className="text-[16px]">{a.title}</strong>
            <span className="text-caption text-muted">
              {formatWhen(a.startsAt, a.timezone)} {zoneLabel(a.timezone)}
            </span>
            <span>
              <SpotsBadge spots={a.spotsLeft} />
            </span>
          </div>
        </div>
        <ClaimForm
          code={code}
          viewer={viewer ? { name: viewer.displayName } : null}
          disclosure={
            view.rail === 'vouch'
              ? `${host} (the host) will see your name and that ${inviter} invited you. Your phone or email stays private.`
              : `${host} (the host) will see your name and that you joined from a public link. Your phone or email stays private.`
          }
        />
      </main>
    </div>
  );
}
