'use client';

// B3b public link (S5 FR-028; PRD I2, R7). Each member has one public link per Plan: asking for it again
// returns the same one. A paused link shows why; its creator can resume a link they or the auto-pause
// paused, but not one the host paused.
import type { Invite, PlanView, PublicActivity } from '@velio/contracts';
import { useCallback, useEffect, useState } from 'react';
import { Banner } from '../feedback';
import { Button, Photo, Skeleton } from '../primitives';
import { useCanShare, useFlash } from './flash';
import { PlanSubHeader } from './sub-header';
import { apiJson } from '@/lib/api/client';
import { useOnline } from '@/lib/online';
import { copyText, displayLink, nativeShare } from '@/lib/share';

const PAUSED: Record<NonNullable<Invite['pausedReason']>, { title: string; body: string }> = {
  auto: {
    title: 'This link is paused.',
    body: 'We paused it while we check unusual activity. Bookings already made are safe. Vouch invites still work.',
  },
  owner: {
    title: 'You paused this link.',
    body: 'Nobody can claim from it until you resume it. Bookings already made are safe.',
  },
  host: {
    title: 'The host paused this link.',
    body: 'Bookings already made are safe. Vouch invites still work.',
  },
};

export function ShareLink({ plan, activity }: { plan: PlanView; activity: PublicActivity }) {
  const online = useOnline();
  const canShare = useCanShare();
  const [flash, showFlash] = useFlash();
  const [invite, setInvite] = useState<Invite | null>(null);
  const [failed, setFailed] = useState(false);
  const [resuming, setResuming] = useState(false);

  const fetchLink = useCallback(
    () =>
      apiJson<Invite>(`/plans/${plan.id}/invites`, {
        method: 'POST',
        body: { rail: 'public' },
        headers: { 'x-client': 'web' },
      }),
    [plan.id],
  );

  function load() {
    setFailed(false);
    return fetchLink().then(setInvite, () => setFailed(true));
  }

  useEffect(() => {
    let stale = false;
    fetchLink().then(
      (i) => !stale && setInvite(i),
      () => !stale && setFailed(true),
    );
    return () => {
      stale = true;
    };
  }, [fetchLink]);

  async function resume() {
    if (!invite || resuming) return;
    setResuming(true);
    try {
      await apiJson(`/invites/${invite.code}/pause`, { method: 'DELETE' });
      await load();
    } catch {
      showFlash('Couldn’t resume the link. Try again.');
    } finally {
      setResuming(false);
    }
  }

  const paused = invite?.paused ? PAUSED[invite.pausedReason ?? 'auto'] : null;
  const shareText = `Join the group going to ${activity.title}`;

  return (
    <>
      <PlanSubHeader plan={plan} />
      <main className="mx-auto flex w-full max-w-[480px] flex-col gap-5 px-5 pt-2 pb-8">
        <div className="flex flex-col gap-2">
          <h1 className="m-0 text-title">Share a link</h1>
          <p className="m-0 text-muted">
            Anyone with this link can claim a spot while spots last. Post it in a group chat or the{' '}
            {activity.community.name} thread.
          </p>
        </div>

        {paused ? (
          <Banner tone="error" title={paused.title}>
            {paused.body}
          </Banner>
        ) : null}
        {failed ? (
          <Banner
            tone="error"
            title="We couldn’t get your link."
            action={
              <Button small variant="secondary" onClick={() => void load()} disabled={!online}>
                Try again
              </Button>
            }
          >
            Check your connection and try again.
          </Banner>
        ) : null}

        {invite ? (
          <>
            <section className="flex flex-col gap-3.5 rounded-card bg-surface p-4">
              <div className="flex items-center gap-3">
                <span className="relative size-16 flex-none overflow-hidden rounded-[10px] bg-forest [&>img]:size-full [&>img]:object-cover [&>svg]:block [&>svg]:size-full">
                  <Photo src={activity.photoUrl} scene="lake" alt="" />
                </span>
                <span className="flex min-w-0 flex-col">
                  <strong>{shareText}</strong>
                  <span className="text-caption text-muted">
                    Preview people see in WhatsApp and other apps
                  </span>
                </span>
              </div>
              <div
                className={`flex items-center gap-2 overflow-hidden rounded-field bg-cream px-3.5 py-3 text-[15px] font-bold ${paused ? 'text-muted' : 'text-forest'}`}
              >
                <span className="truncate">{displayLink(invite.link)}</span>
              </div>
              <span className="text-caption text-muted">
                Code {invite.code} · works until the activity starts
              </span>
            </section>

            {paused ? (
              invite.pausedReason === 'host' ? (
                <Button block disabled>
                  Link paused
                </Button>
              ) : (
                <Button block loading={resuming} disabled={!online} onClick={() => void resume()}>
                  Resume link
                </Button>
              )
            ) : (
              <div className="flex flex-col gap-2.5">
                <Button
                  block
                  icon="copy"
                  onClick={async () =>
                    showFlash(
                      (await copyText(invite.link))
                        ? 'Link copied'
                        : 'Couldn’t copy. Press and hold the link to copy it.',
                    )
                  }
                >
                  Copy link
                </Button>
                {canShare ? (
                  <Button
                    block
                    variant="secondary"
                    icon="share"
                    onClick={() => void nativeShare({ title: shareText, url: invite.link })}
                  >
                    Share
                  </Button>
                ) : null}
              </div>
            )}
          </>
        ) : failed ? null : (
          <Skeleton variant="row" />
        )}

        <p className="m-0 text-caption text-muted">
          People who join from this link show as “Public link” in your plan. They see members as “First L.”
          until they’re in.
        </p>
        <a className="vl-btn vl-btn-quiet self-center" href={`/plans/${plan.id}`}>
          Done
        </a>
      </main>
      {flash}
    </>
  );
}
