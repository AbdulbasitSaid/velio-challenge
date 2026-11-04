import { CommunityList } from '@velio/contracts';
import { redirect } from 'next/navigation';
import { ErrorScreen } from '@/components/error-screen';
import { serverFetch } from '@/lib/api/server';
import { SiteHeader } from './site-header';

export const dynamic = 'force-dynamic';

// The design has no landing page: home opens the first community (S5 §4.2).
export default async function Home() {
  const { communities } = await serverFetch('/communities', { schema: CommunityList });
  const first = communities[0];
  if (first) redirect(`/communities/${first.slug}`);
  return (
    <>
      <SiteHeader current="Communities" />
      <ErrorScreen code="404" headline="No communities yet." body="Check back soon." />
    </>
  );
}
