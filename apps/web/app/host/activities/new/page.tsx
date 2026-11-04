// /host/activities/new (S5 §4.8 H2, create).
import { CommunityList } from '@velio/contracts';
import type { Metadata } from 'next';
import { SiteHeader } from '../../../site-header';
import { ActivityForm } from '@/components/host/activity-form';
import { serverFetch } from '@/lib/api/server';
import type { HostForm } from '@/lib/host-form';
import { shortName } from '@/lib/host-form';
import { requireViewer } from '@/lib/session';

export const dynamic = 'force-dynamic';
export const metadata: Metadata = { title: 'Create an activity', robots: { index: false } };

export default async function NewActivityPage() {
  const viewer = await requireViewer('/host/activities/new');
  const { communities } = await serverFetch('/communities', { schema: CommunityList });
  const initial: HostForm = {
    communitySlug: communities[0]?.slug ?? '',
    title: '',
    description: '',
    date: '',
    time: '',
    // Filled with the browser's zone after hydration.
    timezone: '',
    location: null,
    meetingPoint: '',
    price: '',
    capacity: 10,
    photoKey: null,
  };
  return (
    <>
      <SiteHeader current="Create activity" />
      <ActivityForm
        communities={communities.map((c) => ({ slug: c.slug, name: c.name }))}
        host={shortName(viewer.displayName)}
        initial={initial}
      />
    </>
  );
}
