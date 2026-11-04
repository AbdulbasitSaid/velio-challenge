'use client';

// G9: unknown code (404) and rate-limited device. The field opens /i/<code>; typed codes are forgiving.
import { usePathname, useRouter } from 'next/navigation';
import { useState, type FormEvent } from 'react';
import { Button, TextField } from '../primitives';
import { normaliseCode } from '@/lib/format';

export function CodeEntry({ code: initial, limited = false }: { code?: string; limited?: boolean }) {
  const router = useRouter();
  const pathname = usePathname();
  // On the not-found page the attempted code is only in the path.
  const [code, setCode] = useState(initial ?? decodeURIComponent(pathname.split('/')[2] ?? '').slice(0, 12));
  const [error, setError] = useState<string | null>(
    limited ? null : 'That code doesn’t match an invite. Check the letters.',
  );

  function submit(e: FormEvent) {
    e.preventDefault();
    const normalised = normaliseCode(code);
    if (!normalised) {
      setError('Invite codes are 6 letters and numbers.');
      return;
    }
    router.push(`/i/${normalised}`);
  }

  return (
    <main className="mx-auto flex w-full max-w-[480px] flex-col gap-4 px-5 pt-6 pb-16">
      <h1 className="m-0 text-title">
        {limited ? 'Too many attempts from this device.' : 'We can’t find that invite.'}
      </h1>
      <p className="m-0 text-muted">
        {limited
          ? 'To protect invites from guessing, codes are paused here for an hour. Your real invite still works when you try again.'
          : 'The link may be cut short or mistyped. Check the code in the message you got and type it below.'}
      </p>
      <form onSubmit={submit} noValidate className="flex flex-col gap-4">
        <TextField
          id="code"
          label="Invite code"
          code
          value={code}
          onChange={(v) => {
            setCode(v);
            setError(null);
          }}
          autoComplete="off"
          maxLength={12}
          error={error}
          help="6 letters and numbers, from the link or message you got."
          disabled={limited}
        />
        {limited ? (
          <Button block disabled>
            Try again in an hour
          </Button>
        ) : (
          <Button block type="submit">
            Open invite
          </Button>
        )}
      </form>
      <Button variant="quiet" href="/" className="self-center">
        Browse communities
      </Button>
    </main>
  );
}
