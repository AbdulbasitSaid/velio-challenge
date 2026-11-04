// /communities/<slug> (S5 §4.8 C1): server-rendered list, live spots and the map after hydration.
import { CommunityPage } from '@velio/contracts';
import type { Metadata } from 'next';
import { notFound } from 'next/navigation';
import { cache } from 'react';
import { SiteHeader } from '../../site-header';
import { CommunityLive } from '@/components/community/community-live';
import { ApiRequestError } from '@/lib/api/client';
import { serverFetch } from '@/lib/api/server';

export const dynamic = 'force-dynamic';

const loadCommunity = cache(async (slug: string): Promise<CommunityPage | null> => {
  try {
    return await serverFetch(`/communities/${encodeURIComponent(slug)}`, { schema: CommunityPage });
  } catch (err) {
    if (err instanceof ApiRequestError && (err.status === 404 || err.status === 400)) return null;
    throw err;
  }
});

export async function generateMetadata({ params }: { params: Promise<{ slug: string }> }): Promise<Metadata> {
  const page = await loadCommunity((await params).slug);
  return page ? { title: page.community.name, description: page.community.blurb } : { title: 'Community' };
}

export default async function CommunityRoute({ params }: { params: Promise<{ slug: string }> }) {
  const page = await loadCommunity((await params).slug);
  if (!page) notFound();
  return (
    <>
      <SiteHeader current="Communities" />
      <CommunityLive page={page} />
    </>
  );
}
