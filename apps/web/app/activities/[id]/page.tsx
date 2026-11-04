// /activities/<id> (S5 §4.8 B1): server-rendered from the public snapshot, live after hydration. People
// show only as PublicPerson (SEC-001). Signed-out visitors see the page; Book sends them to X1 first.
import { PublicActivity } from '@velio/contracts';
import type { Metadata } from 'next';
import { notFound } from 'next/navigation';
import { cache } from 'react';
import { SiteHeader } from '../../site-header';
import { ActivityLive } from '@/components/activity/activity-live';
import { ApiRequestError } from '@/lib/api/client';
import { serverFetch } from '@/lib/api/server';
import { loadNextSteps } from '@/lib/invite';
import { getViewer } from '@/lib/session';

export const dynamic = 'force-dynamic';

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

const loadActivity = cache(async (id: string): Promise<PublicActivity | null> => {
  if (!UUID.test(id)) return null;
  try {
    return await serverFetch(`/activities/${id}`, { schema: PublicActivity });
  } catch (err) {
    if (err instanceof ApiRequestError && (err.status === 404 || err.status === 400)) return null;
    throw err;
  }
});

export async function generateMetadata({ params }: { params: Promise<{ id: string }> }): Promise<Metadata> {
  const activity = await loadActivity((await params).id);
  return { title: activity?.title ?? 'Activity' };
}

export default async function ActivityPage({ params }: { params: Promise<{ id: string }> }) {
  const [activity, viewer] = await Promise.all([loadActivity((await params).id), getViewer()]);
  if (!activity) notFound();
  const booking = activity.viewer?.booking;
  const needsNextSteps =
    booking?.status === 'removed' ||
    activity.status === 'started' ||
    (activity.status === 'sold_out' && !booking);
  return (
    <>
      <SiteHeader current="Communities" live />
      <ActivityLive
        activity={activity}
        signedIn={!!viewer}
        initialNextSteps={needsNextSteps ? await loadNextSteps(activity.id) : null}
      />
    </>
  );
}
