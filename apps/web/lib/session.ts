// The signed-in viewer for server components (S5 §4.6). One GET /me per request, memoised by React.
import { MemberPerson } from '@velio/contracts';
import { redirect } from 'next/navigation';
import { cache } from 'react';
import { ApiRequestError } from './api/client';
import { serverFetch } from './api/server';

export const getViewer = cache(async (): Promise<MemberPerson | null> => {
  try {
    return await serverFetch('/me', { schema: MemberPerson });
  } catch (err) {
    if (err instanceof ApiRequestError && err.status === 401) return null;
    throw err;
  }
});

/** Only relative paths on this site, so `next` can't send people elsewhere. */
export function safeNext(next: string | string[] | undefined, fallback = '/me/plans'): string {
  const value = Array.isArray(next) ? next[0] : next;
  return value && value.startsWith('/') && !value.startsWith('//') && !value.startsWith('/\\')
    ? value
    : fallback;
}

/** Pages that need a session send signed-out visitors to X1 and back afterwards. */
export async function requireViewer(path: string): Promise<MemberPerson> {
  const viewer = await getViewer();
  if (!viewer) redirect(`/signin?next=${encodeURIComponent(path)}`);
  return viewer;
}
