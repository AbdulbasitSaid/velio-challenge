// /plans/<id> (S5 §4.8 B4; B2 with `?welcome=1` straight after booking). Members only: the API answers
// 403 or 404 to anyone else, and both show X4's not-found.
import { PublicActivity } from '@velio/contracts';
import type { Metadata } from 'next';
import { notFound } from 'next/navigation';
import { SiteHeader } from '../../site-header';
import { Welcome } from '@/components/plan/welcome';
import { serverFetch } from '@/lib/api/server';
import { loadPlan } from '@/lib/invite';
import { requireViewer } from '@/lib/session';

export const dynamic = 'force-dynamic';
export const metadata: Metadata = { title: 'Your plan', robots: { index: false } };

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export default async function PlanPage({
  params,
  searchParams,
}: {
  params: Promise<{ id: string }>;
  searchParams: Promise<{ welcome?: string }>;
}) {
  const [{ id }, { welcome }] = await Promise.all([params, searchParams]);
  await requireViewer(`/plans/${id}`);
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
  // B4 follows in T12.
  notFound();
}
