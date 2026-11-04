'use client';

import Link from 'next/link';
import { Button } from '@/components';
import { ErrorScreen } from '@/components/error-screen';
import { ApiRequestError } from '@/lib/api/client';

export default function ErrorPage({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  // The API's request ID when the failure came from it; otherwise Next's digest, which matches server logs.
  const requestId = error instanceof ApiRequestError ? error.requestId : error.digest;
  return (
    <>
      <header className="flex items-center px-5 py-3.5">
        <Link className="vl-wordmark" href="/">
          velio
        </Link>
      </header>
      <ErrorScreen
        code="500"
        headline="Something went wrong on our side."
        body="It's not you. Try again in a moment."
        requestId={requestId}
        action={
          <Button block onClick={reset}>
            Try again
          </Button>
        }
      />
    </>
  );
}
