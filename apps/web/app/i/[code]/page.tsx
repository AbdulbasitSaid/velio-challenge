// /i/<code> (S6 §4.1): server-rendered invite page. Canonical code in the path; status 200 for any
// invite state, 404 for an unknown code. Link previews read the metadata; bots never send the beacon.
import type { Metadata } from 'next';
import { notFound, permanentRedirect } from 'next/navigation';
import { ClaimedOther, ClaimedOwn, Expired, InviteHeader, Paused } from '@/components/invite/outcomes';
import { InviteLive } from '@/components/invite/invite-live';
import { CodeEntry } from '@/components/invite/code-entry';
import { firstName, formatWhen, spotsLabel, zoneLabel } from '@/lib/format';
import { loadInvite, loadNextSteps, loadPlan } from '@/lib/invite';
import { selectScreen } from '@/lib/invite-screen';
import { getViewer } from '@/lib/session';
import { normaliseCode } from '@/lib/format';

export const dynamic = 'force-dynamic';

const base = () => (process.env.PUBLIC_BASE_URL ?? 'http://localhost:3000').replace(/\/+$/, '');

export async function generateMetadata({ params }: { params: Promise<{ code: string }> }): Promise<Metadata> {
  const robots = { index: false, follow: false };
  const code = normaliseCode((await params).code);
  const load = code ? await loadInvite(code) : null;
  if (!code || load?.kind !== 'ok') return { title: 'Invite', robots };
  const { view } = load;
  const a = view.activity;
  const title =
    view.rail === 'vouch'
      ? `${firstName(view.inviter.shortName)} wants you on ${a.title}`
      : `Join the group going to ${a.title}`;
  const description = `${formatWhen(a.startsAt, a.timezone)} ${zoneLabel(a.timezone)} · ${a.location.venueName} · ${spotsLabel(a.spotsLeft)}`;
  const url = `${base()}/i/${code}`;
  const images = a.photoUrl ? [{ url: new URL(a.photoUrl, base()).toString(), alt: a.title }] : undefined;
  return {
    title,
    description,
    robots,
    alternates: { canonical: url },
    openGraph: { title, description, url, type: 'website', siteName: 'Velio', images },
    twitter: { card: images ? 'summary_large_image' : 'summary', title, description },
  };
}

export default async function InvitePage({ params }: { params: Promise<{ code: string }> }) {
  const raw = (await params).code;
  const code = normaliseCode(raw);
  if (!code) notFound();
  if (code !== raw) permanentRedirect(`/i/${code}`);

  const load = await loadInvite(code);
  if (load.kind === 'invalid') notFound();
  if (load.kind === 'rate-limited')
    return (
      <>
        <InviteHeader />
        <CodeEntry code={code} limited />
      </>
    );

  const { view } = load;
  const screen = selectScreen(view);
  switch (screen.kind) {
    case 'claimed-own': {
      const viewer = await getViewer();
      const planId = view.activity.viewer?.booking?.planId;
      const plan = planId ? await loadPlan(planId) : null;
      return (
        <>
          <InviteHeader
            end={
              <a href="/me/plans" className="text-[14px] font-bold">
                My plans
              </a>
            }
          />
          <ClaimedOwn view={view} plan={plan} viewer={viewer ?? { id: '', displayName: 'there' }} />
        </>
      );
    }
    case 'claimed-other':
      return (
        <>
          <InviteHeader />
          <ClaimedOther view={view} />
        </>
      );
    case 'expired':
      return (
        <>
          <InviteHeader />
          <Expired view={view} nextSteps={await loadNextSteps(view.activity.id)} />
        </>
      );
    case 'paused':
      return (
        <>
          <InviteHeader />
          <Paused view={view} nextSteps={await loadNextSteps(view.activity.id)} />
        </>
      );
    default:
      return (
        <InviteLive
          view={view}
          initialNextSteps={screen.kind === 'sold-out' ? await loadNextSteps(view.activity.id) : null}
        />
      );
  }
}
