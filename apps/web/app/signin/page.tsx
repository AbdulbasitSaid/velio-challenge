import type { Metadata } from 'next';
import { redirect } from 'next/navigation';
import { AppHeader } from '@/components';
import { getViewer, safeNext } from '@/lib/session';
import { SignInForm } from './sign-in-form';

export const metadata: Metadata = { title: 'Continue', robots: { index: false } };

export default async function SignInPage({
  searchParams,
}: {
  searchParams: Promise<{ next?: string | string[] }>;
}) {
  const next = safeNext((await searchParams).next);
  if (await getViewer()) redirect(next);
  return (
    <div className="min-h-dvh">
      <AppHeader compact />
      <main className="mx-auto flex max-w-content flex-wrap items-center gap-12 px-5 pt-6 pb-8 md:px-10 md:py-16">
        <div className="hidden min-w-0 flex-[1_1_380px] flex-col gap-4 md:flex">
          <h1 className="m-0 text-display md:text-[48px] md:leading-[52px]">Book together. Go together.</h1>
          <p className="m-0 max-w-[46ch] text-[17px] leading-[26px] text-muted">
            Hosts list activities with fixed spots. You book one, invite friends into your plan, and watch the
            spots fill live.
          </p>
        </div>
        <SignInForm next={next} />
      </main>
    </div>
  );
}
