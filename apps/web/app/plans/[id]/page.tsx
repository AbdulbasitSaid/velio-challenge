// /plans/<id> (S5 §4.8): B4, B2 with `?welcome=1` straight after booking, and B3 / B3b with
// `?invite=vouch|public` (full screens, as the approved canvas draws them, so a reload keeps the step).
// Members only: the API answers 403 or 404 to anyone else, and both show X4's not-found.
import { PublicActivity } from '@velio/contracts';
import type { Metadata } from 'next';
import { notFound } from 'next/navigation';
import { SiteHeader } from '../../site-header';
import { PlanLive } from '@/components/plan/plan-live';
import { ShareLink } from '@/components/plan/share-link';
import { Vouch } from '@/components/plan/vouch';
import { Welcome } from '@/components/plan/welcome';
import { serverFetch } from '@/lib/api/server';
import { loadNextSteps, loadPlan } from '@/lib/invite';
import { requireViewer } from '@/lib/session';

export const dynamic = 'force-dynamic';
export const metadata: Metadata = { title: 'Your plan', robots: { index: false } };

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export default async function PlanPage({
  params,
  searchParams,
}: {
  params: Promise<{ id: string }>;
  searchParams: Promise<{ welcome?: string; invite?: string }>;
}) {
  const [{ id }, { welcome, invite }] = await Promise.all([params, searchParams]);
  const step = invite === 'vouch' || invite === 'public' ? invite : null;
  const viewer = await requireViewer(`/plans/${id}${step ? `?invite=${step}` : ''}`);
  const plan = UUID.test(id) ? await loadPlan(id) : null;
  if (!plan) notFound();
  const activity = await serverFetch(`/activities/${plan.activity.id}`, { schema: PublicActivity });

  if (welcome === '1' && plan.viewer.booking.status === 'confirmed') {
    return (
      <>
        <SiteHeader current="My plans" />
        <Welcome plan={plan} spots={{ spotsLeft: activity.spotsLeft, version: activity.version }} />
      </>
    );
  }
  if (step && plan.viewer.canInvite) {
    return step === 'vouch' ? (
      <Vouch plan={plan} activity={activity} />
    ) : (
      <ShareLink plan={plan} activity={activity} />
    );
  }

  const removed = plan.viewer.booking.status === 'removed';
  return (
    <>
      <SiteHeader current="My plans" live />
      <PlanLive
        plan={plan}
        activity={activity}
        viewerId={viewer.id}
        nextSteps={removed ? await loadNextSteps(activity.id) : null}
      />
    </>
  );
}
