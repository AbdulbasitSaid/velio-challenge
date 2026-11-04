// /host/activities/<id>/attendance (S5 §4.8 H1). The host only: the API answers 403 or 404 to anyone
// else, and both show X4's not-found (SEC-008). The snapshot adds the title and venue the list lacks.
import { Attendance, PublicActivity } from '@velio/contracts';
import type { Metadata } from 'next';
import { notFound } from 'next/navigation';
import { SiteHeader } from '../../../../site-header';
import { AttendanceLive } from '@/components/host/attendance-live';
import { ApiRequestError } from '@/lib/api/client';
import { serverFetch } from '@/lib/api/server';
import { requireViewer } from '@/lib/session';

export const dynamic = 'force-dynamic';
export const metadata: Metadata = { title: 'Attendance', robots: { index: false } };

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

async function load(id: string) {
  if (!UUID.test(id)) return null;
  try {
    return await Promise.all([
      serverFetch(`/host/activities/${id}/attendance`, { schema: Attendance }),
      serverFetch(`/activities/${id}`, { schema: PublicActivity }),
    ]);
  } catch (err) {
    if (err instanceof ApiRequestError && [400, 403, 404].includes(err.status)) return null;
    throw err;
  }
}

export default async function AttendancePage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  await requireViewer(`/host/activities/${id}/attendance`);
  const loaded = await load(id);
  if (!loaded) notFound();
  const [attendance, activity] = loaded;
  return (
    <>
      <SiteHeader current="My activities" live />
      <AttendanceLive attendance={attendance} activity={activity} />
    </>
  );
}
