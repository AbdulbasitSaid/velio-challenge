// X4: not found and server error, phone-first, centred column of at most 480px (UI design FR-014).
import type { ReactNode } from 'react';
import { Button } from './primitives';

export function ErrorScreen({
  code,
  headline,
  body,
  action,
  requestId,
}: {
  code: '404' | '500';
  headline: string;
  body: string;
  action?: ReactNode;
  requestId?: string;
}) {
  return (
    <main className="mx-auto flex min-h-[70dvh] w-full max-w-[480px] flex-col justify-center gap-4 px-5 pt-6 pb-16">
      <span
        className="font-display text-[64px] leading-none font-bold tracking-[-2px] text-forest"
        aria-hidden
      >
        {code}
      </span>
      <h1 className="m-0 text-title">{headline}</h1>
      <p className="m-0 text-muted">{body}</p>
      {action}
      <Button variant="secondary" block href="/">
        Go to communities
      </Button>
      <Button variant="quiet" href="/me/plans" className="self-center">
        My plans
      </Button>
      {requestId ? <span className="text-center text-[12px] text-muted">Reference {requestId}</span> : null}
    </main>
  );
}
