// /host/activities/<id>/edit (S5 §4.8 H2, edit; `?published=1` straight after publishing). The public
// snapshot has every field the form needs; anyone but the host gets X4's not-found (SEC-008).
import { CommunityList, PublicActivity } from '@velio/contracts';
import type { Metadata } from 'next';
import { notFound } from 'next/navigation';
import { SiteHeader } from '../../../../site-header';
import { ActivityForm } from '@/components/host/activity-form';
import { ApiRequestError } from '@/lib/api/client';
import { serverFetch } from '@/lib/api/server';
import { formFromActivity } from '@/lib/host-form';
import { requireViewer } from '@/lib/session';

export const dynamic = 'force-dynamic';
export const metadata: Metadata = { title: 'Edit activity', robots: { index: false } };

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

async function load(id: string): Promise<PublicActivity | null> {
  if (!UUID.test(id)) return null;
  try {
    return await serverFetch(`/activities/${id}`, { schema: PublicActivity });
  } catch (err) {
    if (err instanceof ApiRequestError && (err.status === 404 || err.status === 400)) return null;
    throw err;
  }
}

export default async function EditActivityPage({
  params,
  searchParams,
}: {
  params: Promise<{ id: string }>;
  searchParams: Promise<{ published?: string }>;
}) {
  const [{ id }, { published }] = await Promise.all([params, searchParams]);
  await requireViewer(`/host/activities/${id}/edit`);
  const [activity, { communities }] = await Promise.all([
    load(id),
    serverFetch('/communities', { schema: CommunityList }),
  ]);
  if (!activity?.viewer?.isHost) notFound();
  return (
    <>
      <SiteHeader current={published === '1' ? 'Create activity' : 'My activities'} />
      <ActivityForm
        communities={communities.map((c) => ({ slug: c.slug, name: c.name }))}
        host={activity.host.shortName}
        initial={formFromActivity(activity)}
        published={published === '1'}
        edit={{
          id: activity.id,
          booked: activity.members.count,
          photoUrl: activity.photoUrl,
          directionsUrl: activity.location.directionsUrl,
          staticMapUrl: activity.location.staticMapUrl,
          communityName: activity.community.name,
          currency: activity.currency,
        }}
      />
    </>
  );
}
