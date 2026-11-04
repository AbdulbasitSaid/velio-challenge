'use client';

// B3 vouch (S5 FR-027; PRD I1, I3). One named friend per invite. The contact is optional, goes only in
// the request body, and the API keeps only its keyed hash (SEC-002); the send links carry the message
// alone, so the booker picks the recipient in WhatsApp or Messages.
import type { Invite, PlanView, PublicActivity } from '@velio/contracts';
import { useEffect, useRef, useState, type FormEvent } from 'react';
import { Banner } from '../feedback';
import { whatsappHref } from '../invite/parts';
import { Button, TextField } from '../primitives';
import { useBrowserValue, useCanShare, useFlash } from './flash';
import { PlanSubHeader } from './sub-header';
import { ApiRequestError, apiJson } from '@/lib/api/client';
import { firstName } from '@/lib/format';
import { useOnline } from '@/lib/online';
import { useLiveSpots } from '@/lib/realtime/react';
import { copyText, displayLink, nativeShare, smsHref, vouchMessage } from '@/lib/share';

const NAME_ERROR = 'Add their name, so the invite is addressed to them.';
const CONTACT_ERROR = 'Enter a full phone number with country code, or an email address.';
const NOTE_MAX = 280;

/** Copy deck `vouch.noHold`. */
export function noHoldLine(spotsLeft: number): string {
  if (spotsLeft <= 0) return 'Invites don’t hold a spot. It’s sold out right now.';
  const n = spotsLeft === 1 ? '1 spot' : `${spotsLeft} spots`;
  return `Invites don’t hold a spot. ${n} left right now.`;
}

type Failure = { title: string; body: string } | null;

/** Maps a create error to a field or a banner. Exported for tests. */
export function vouchFailure(err: unknown): { field: 'name' | 'contact' } | { banner: NonNullable<Failure> } {
  if (err instanceof ApiRequestError) {
    if (err.code === 'invalid_contact') return { field: 'contact' };
    if (err.code === 'validation_failed') return { field: 'name' };
    if (err.code === 'activity_started')
      return { banner: { title: 'This activity has started.', body: 'Invites close at the start time.' } };
    if (err.code === 'forbidden')
      return { banner: { title: 'You can’t invite to this plan.', body: 'Only people going can invite.' } };
  }
  return {
    banner: { title: 'We couldn’t create the invite.', body: 'Check your connection and try again.' },
  };
}

interface ContactsManager {
  select(
    props: string[],
    options?: { multiple?: boolean },
  ): Promise<{ name?: string[]; tel?: string[]; email?: string[] }[]>;
}

/** The Contact Picker API (Chrome on Android); the button is hidden elsewhere. */
function contactPicker(): ContactsManager | null {
  const c = (navigator as Navigator & { contacts?: ContactsManager }).contacts;
  return c && typeof c.select === 'function' ? c : null;
}

export function Vouch({ plan, activity }: { plan: PlanView; activity: PublicActivity }) {
  const online = useOnline();
  const canShare = useCanShare();
  const picker = useBrowserValue(() => !!contactPicker());
  const [flash, showFlash] = useFlash();
  const { spots } = useLiveSpots(
    { [activity.id]: { spotsLeft: activity.spotsLeft, version: activity.version } },
    async () => {
      const fresh = await apiJson<PublicActivity>(`/activities/${activity.id}`);
      return { [activity.id]: { spotsLeft: fresh.spotsLeft, version: fresh.version } };
    },
  );
  const spotsLeft = spots[activity.id]!.spotsLeft;

  const [name, setName] = useState('');
  const [contact, setContact] = useState('');
  const [note, setNote] = useState('');
  const [nameError, setNameError] = useState<string | null>(null);
  const [contactError, setContactError] = useState<string | null>(null);
  const [failure, setFailure] = useState<Failure>(null);
  const [creating, setCreating] = useState(false);
  const [invite, setInvite] = useState<Invite | null>(null);
  const bannerRef = useRef<HTMLDivElement>(null);
  const titleRef = useRef<HTMLHeadingElement>(null);

  useEffect(() => {
    if (failure) bannerRef.current?.focus();
  }, [failure]);
  useEffect(() => {
    if (invite) titleRef.current?.focus();
  }, [invite]);

  async function pickContact() {
    const [picked] =
      (await contactPicker()
        ?.select(['name', 'tel', 'email'])
        .catch(() => [])) ?? [];
    if (!picked) return;
    if (picked.name?.[0] && !name) setName(picked.name[0]);
    const value = picked.tel?.[0] ?? picked.email?.[0];
    if (value) setContact(value);
  }

  async function submit(e: FormEvent) {
    e.preventDefault();
    if (creating || !online) return;
    const inviteeName = name.trim();
    setNameError(inviteeName ? null : NAME_ERROR);
    setContactError(null);
    if (!inviteeName) return;
    setCreating(true);
    setFailure(null);
    try {
      const body: Record<string, string> = { rail: 'vouch', inviteeName };
      if (contact.trim()) body.contact = contact.trim();
      if (note.trim()) body.note = note.trim();
      setInvite(
        await apiJson<Invite>(`/plans/${plan.id}/invites`, {
          method: 'POST',
          body,
          headers: { 'x-client': 'web' },
        }),
      );
    } catch (err) {
      const f = vouchFailure(err);
      if ('field' in f) {
        if (f.field === 'contact') setContactError(CONTACT_ERROR);
        else setNameError(NAME_ERROR);
      } else {
        setFailure(f.banner);
      }
    } finally {
      setCreating(false);
    }
  }

  const host = firstName(activity.host.shortName);

  if (invite) {
    const who = firstName(invite.inviteeName ?? name);
    const message = vouchMessage(invite.inviteeName ?? name, activity, invite.link);
    return (
      <>
        <PlanSubHeader plan={plan} />
        <main className="mx-auto flex w-full max-w-[480px] flex-col gap-5 px-5 pt-2 pb-8">
          <div className="flex flex-col gap-2">
            <h1 ref={titleRef} tabIndex={-1} className="m-0 text-title outline-none">
              Send it to {who}
            </h1>
            <p className="m-0 text-muted">Your invite is ready. Send it however you usually talk.</p>
          </div>

          <section className="flex flex-col gap-3 rounded-card bg-surface p-4">
            <span className="text-[12px] font-bold tracking-[.06em] text-muted uppercase">
              Message preview
            </span>
            <p className="m-0 break-words">{message.replace(invite.link, displayLink(invite.link))}</p>
            <div className="flex flex-wrap items-center gap-2">
              <span className="vl-chip tracking-[1px]">Code {invite.code}</span>
              <span className="text-caption text-muted">Works once, until the activity starts</span>
            </div>
          </section>

          <div className="flex flex-col gap-2.5">
            <Button block href={whatsappHref(message)} external>
              Send on WhatsApp
            </Button>
            <Button block variant="secondary" href={smsHref(message)}>
              Send by text message
            </Button>
            {canShare ? (
              <Button
                block
                variant="secondary"
                icon="share"
                onClick={() => void nativeShare({ text: message })}
              >
                Share
              </Button>
            ) : null}
            <Button
              block
              variant="quiet"
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
          </div>

          <Banner title="What happens next">
            You’ll see “Opened” in your plan when {who} opens it, and “Claimed” once the spot is taken.
            “Created” means the link exists; we can’t see whether it was sent.
          </Banner>
          <a className="vl-btn vl-btn-quiet self-center" href={`/plans/${plan.id}`}>
            Done
          </a>
        </main>
        {flash}
      </>
    );
  }

  return (
    <>
      <PlanSubHeader plan={plan} />
      <main className="mx-auto flex w-full max-w-[480px] flex-col gap-5 px-5 pt-2 pb-8">
        <div className="flex flex-col gap-2">
          <h1 className="m-0 text-title">Vouch for a friend</h1>
          <p className="m-0 text-muted">
            One invite, one person. It shows your name, so they know it’s from you.
          </p>
        </div>

        {failure ? (
          <div ref={bannerRef} tabIndex={-1} className="outline-none">
            <Banner tone="error" title={failure.title}>
              {failure.body}
            </Banner>
          </div>
        ) : null}
        {!online ? (
          <Banner tone="offline" title="You’re offline">
            Reconnect to create an invite.
          </Banner>
        ) : null}

        <form className="flex flex-col gap-4" onSubmit={submit} noValidate>
          <TextField
            id="v-name"
            label="Friend’s name"
            value={name}
            onChange={setName}
            placeholder="Who is it for?"
            error={nameError}
            maxLength={80}
            autoComplete="off"
            required
          />
          <div className="flex flex-col gap-2">
            <TextField
              id="v-contact"
              label="Their phone or email"
              value={contact}
              onChange={setContact}
              placeholder="+254 7… or name@example.com"
              help={`Used only to send and match this invite. ${host} never sees it.`}
              error={contactError}
              maxLength={200}
              autoComplete="off"
            />
            {picker ? (
              <span>
                <Button variant="quiet" small icon="people" onClick={() => void pickContact()}>
                  Choose from contacts
                </Button>
              </span>
            ) : null}
          </div>
          <TextField
            id="v-note"
            label="Note (optional)"
            multiline
            value={note}
            onChange={setNote}
            placeholder="A line from you, shown on their invite"
            maxLength={NOTE_MAX}
            count={note.length}
          />
          <Button block type="submit" loading={creating} disabled={!online}>
            {creating ? 'Creating…' : failure ? 'Try again' : 'Create invite'}
          </Button>
          <p className="m-0 text-center text-caption text-muted">{noHoldLine(spotsLeft)}</p>
        </form>
      </main>
    </>
  );
}
