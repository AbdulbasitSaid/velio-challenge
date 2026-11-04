// Server-side invite loading for /i/[code] (S6 §4.1): one API call per request, shared by the page and
// its metadata. The viewer's cookie, device ID and IP are forwarded (rate limits key on them).
import { NextSteps, InviteView, PlanView } from '@velio/contracts';
import { cache } from 'react';
import { ApiRequestError } from './api/client';
import { serverFetch } from './api/server';

export type InviteLoad = { kind: 'ok'; view: InviteView } | { kind: 'invalid' } | { kind: 'rate-limited' };

export const loadInvite = cache(async (code: string): Promise<InviteLoad> => {
  try {
    return { kind: 'ok', view: await serverFetch(`/invites/${code}`, { schema: InviteView }) };
  } catch (err) {
    if (err instanceof ApiRequestError) {
      if (err.code === 'invalid_code' || err.code === 'not_found') return { kind: 'invalid' };
      if (err.code === 'rate_limited') return { kind: 'rate-limited' };
    }
    throw err;
  }
});

export const loadNextSteps = cache(async (activityId: string): Promise<NextSteps> => {
  try {
    return await serverFetch(`/activities/${activityId}/next-steps`, { schema: NextSteps });
  } catch {
    // Next steps are extras: an outcome screen still renders without them (UX FR-007).
    return { hostOtherDates: [], moreInCommunity: [] };
  }
});

export const loadPlan = cache(async (planId: string): Promise<PlanView | null> => {
  try {
    return await serverFetch(`/plans/${planId}`, { schema: PlanView });
  } catch (err) {
    if (err instanceof ApiRequestError && (err.status === 401 || err.status === 403 || err.status === 404))
      return null;
    throw err;
  }
});
