'use client';

// G3 form (S6 §4.4). One Idempotency-Key per attempt, kept in sessionStorage for the code so a retry or a
// reload during a slow claim never books twice (PRD Edge cases: server error). Rejections map per the
// API's order (S4 FR-010); outcomes the invite page already shows send the guest back to it.
import { useRouter } from 'next/navigation';
import { useEffect, useRef, useState, type FormEvent, type ReactNode } from 'react';
import { Banner } from '../feedback';
import { Button, TextField } from '../primitives';
import { useOnline } from './invite-live';
import { ApiRequestError, apiFetch } from '@/lib/api/client';

const keyName = (code: string) => `velio_claim_${code}`;

export function claimKey(code: string): string {
  try {
    const existing = sessionStorage.getItem(keyName(code));
    if (existing) return existing;
    const key = crypto.randomUUID();
    sessionStorage.setItem(keyName(code), key);
    return key;
  } catch {
    return crypto.randomUUID();
  }
}

export function clearClaimKey(code: string): void {
  try {
    sessionStorage.removeItem(keyName(code));
  } catch {
    // Storage blocked: nothing to clear.
  }
}

export type ClaimOutcome =
  | { kind: 'done' }
  | { kind: 'back' } // the invite page shows the state (expired, paused, claimed by someone else, host)
  | { kind: 'field'; field: 'name' | 'contact' }
  | { kind: 'banner'; title: string; body: ReactNode; retry: boolean; final: boolean };

/** Maps a claim error to what the guest sees. Exported for tests (V-CLM-3). */
export function claimOutcome(err: unknown, code: string): ClaimOutcome {
  if (!(err instanceof ApiRequestError)) return serverError();
  switch (err.code) {
    case 'invalid_contact':
      return { kind: 'field', field: 'contact' };
    case 'validation_failed':
      return { kind: 'field', field: 'name' };
    case 'sold_out':
      return {
        kind: 'banner',
        title: 'Someone just took the last spot.',
        body: (
          <>
            We didn’t book you. <a href={`/i/${code}`}>See other dates and activities</a>
          </>
        ),
        retry: false,
        final: true,
      };
    case 'rate_limited':
      return {
        kind: 'banner',
        title: 'Too many attempts from this device.',
        body: 'Try again in an hour. Your invite still works.',
        retry: false,
        final: true,
      };
    case 'bookings_paused':
      return {
        kind: 'banner',
        title: 'Bookings are paused for this activity.',
        body: 'Nothing has changed for people already going. Check back soon.',
        retry: false,
        final: true,
      };
    case 'booking_removed':
      return {
        kind: 'banner',
        title: 'The host removed your booking for this activity.',
        body: (
          <>
            Your spot was released. You can still book another date.{' '}
            <a href={`/i/${code}`}>See other dates</a>
          </>
        ),
        retry: false,
        final: true,
      };
    case 'already_booked':
      return { kind: 'done' };
    case 'invite_expired':
    case 'invite_paused':
    case 'already_claimed':
    case 'activity_started':
    case 'forbidden':
    case 'invalid_code':
    case 'not_found':
      return { kind: 'back' };
    default:
      return serverError();
  }
}

function serverError(): ClaimOutcome {
  return {
    kind: 'banner',
    title: 'We couldn’t confirm your spot. Nothing was booked.',
    body: 'Try again. You won’t be booked twice.',
    retry: true,
    final: false,
  };
}

const CONTACT_ERROR = 'Enter a full phone number with country code, or an email address.';

export function ClaimForm({
  code,
  viewer,
  disclosure,
}: {
  code: string;
  viewer: { name: string } | null;
  disclosure: string;
}) {
  const router = useRouter();
  const online = useOnline();
  const [signedIn, setSignedIn] = useState(viewer);
  const [name, setName] = useState('');
  const [contact, setContact] = useState('');
  const [nameError, setNameError] = useState<string | null>(null);
  const [contactError, setContactError] = useState<string | null>(null);
  const [banner, setBanner] = useState<Extract<ClaimOutcome, { kind: 'banner' }> | null>(null);
  const [submitting, setSubmitting] = useState(false);
  const bannerRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (banner) bannerRef.current?.focus();
  }, [banner]);

  async function notYou() {
    await apiFetch('/sessions/current', { method: 'DELETE' }).catch(() => undefined);
    setSignedIn(null);
    router.refresh();
  }

  async function submit(e: FormEvent) {
    e.preventDefault();
    if (!online || submitting) return;
    let body: Record<string, string> = { platform: 'web' };
    if (!signedIn) {
      const displayName = name.trim();
      const value = contact.trim();
      setNameError(displayName ? null : 'Enter your name.');
      setContactError(value ? null : CONTACT_ERROR);
      if (!displayName || !value) return;
      body = { ...body, displayName, contact: value };
    }
    setSubmitting(true);
    setBanner(null);
    try {
      await apiFetch(`/invites/${code}/claims`, { method: 'POST', body, idempotencyKey: claimKey(code) });
      clearClaimKey(code);
      router.replace(`/i/${code}/in`);
      return;
    } catch (err) {
      const outcome = claimOutcome(err, code);
      if (outcome.kind === 'done') {
        clearClaimKey(code);
        router.replace(`/i/${code}/in`);
        return;
      }
      setSubmitting(false);
      if (outcome.kind === 'back') {
        clearClaimKey(code);
        router.replace(`/i/${code}`);
        router.refresh();
      } else if (outcome.kind === 'field') {
        if (outcome.field === 'contact') setContactError(CONTACT_ERROR);
        else setNameError('Enter your name.');
      } else {
        if (outcome.final) clearClaimKey(code);
        setBanner(outcome);
      }
    }
  }

  const blocked = banner?.final ?? false;
  return (
    <>
      <h1 className="m-0 text-title">Claim your spot</h1>
      {banner ? (
        <div ref={bannerRef} tabIndex={-1} className="outline-none">
          <Banner tone="error" title={banner.title}>
            {banner.body}
          </Banner>
        </div>
      ) : null}
      {!online ? (
        <Banner tone="offline" title="You're offline">
          Reconnect to claim. Nothing is booked until you do.
        </Banner>
      ) : null}
      <form onSubmit={submit} noValidate className="flex flex-col gap-4">
        {signedIn ? (
          <div className="flex items-center justify-between gap-3 rounded-card bg-surface px-4 py-3.5">
            <span>
              Claiming as <strong>{signedIn.name}</strong>
            </span>
            <button type="button" className="vl-btn vl-btn-quiet vl-btn-sm" onClick={notYou}>
              Not you?
            </button>
          </div>
        ) : (
          <>
            <TextField
              id="claim-name"
              label="Your name"
              value={name}
              onChange={setName}
              placeholder="First and last name"
              autoComplete="name"
              maxLength={80}
              error={nameError}
              help="The host and the people in your group see this."
            />
            <TextField
              id="claim-contact"
              label="Phone or email"
              value={contact}
              onChange={setContact}
              placeholder="+254 7… or you@example.com"
              autoComplete="tel"
              maxLength={200}
              error={contactError}
              help="So you can find this booking again. We don't message you."
            />
          </>
        )}
        <Banner title="What the host sees">{disclosure}</Banner>
        <Button type="submit" block loading={submitting} disabled={!online || blocked}>
          {submitting
            ? 'Confirming…'
            : !online
              ? 'Reconnect to claim'
              : banner?.retry
                ? 'Try again'
                : 'Confirm my spot'}
        </Button>
        <p className="m-0 text-center text-caption text-muted">Spots aren’t held. Claim while they last.</p>
      </form>
    </>
  );
}
