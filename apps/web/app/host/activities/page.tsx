// /host/activities (S5 §4.8 H3). Signed-in only; everyone can host (PRD W1), so nobody is turned away.
import { HostActivityList } from '@velio/contracts';
import type { Metadata } from 'next';
import { SiteHeader } from '../../site-header';
import { HostList } from '@/components/host/host-list';
import { serverFetch } from '@/lib/api/server';
import { requireViewer } from '@/lib/session';

export const dynamic = 'force-dynamic';
export const metadata: Metadata = { title: 'My activities', robots: { index: false } };

export default async function HostActivitiesPage() {
  await requireViewer('/host/activities');
  const data = await serverFetch('/host/activities', { schema: HostActivityList });
  return (
    <>
      <SiteHeader current="My activities" />
      <HostList data={data} />
    </>
  );
}
