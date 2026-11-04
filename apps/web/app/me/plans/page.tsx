// /me/plans (S5 §4.8 B6). Signed-in only; signed-out visitors go to X1 and come back here.
import { MyPlans as MyPlansData } from '@velio/contracts';
import type { Metadata } from 'next';
import { SiteHeader } from '../../site-header';
import { MyPlans } from '@/components/plan/my-plans';
import { serverFetch } from '@/lib/api/server';
import { requireViewer } from '@/lib/session';

export const dynamic = 'force-dynamic';
export const metadata: Metadata = { title: 'My plans', robots: { index: false } };

export default async function MyPlansPage() {
  const viewer = await requireViewer('/me/plans');
  const data = await serverFetch('/me/plans', { schema: MyPlansData });
  return (
    <>
      <SiteHeader current="My plans" />
      <MyPlans data={data} viewerName={viewer.displayName} />
    </>
  );
}
