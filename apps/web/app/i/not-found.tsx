import type { Metadata } from 'next';
import { CodeEntry } from '@/components/invite/code-entry';
import { InviteHeader } from '@/components/invite/outcomes';

export const metadata: Metadata = { title: 'Invite not found', robots: { index: false, follow: false } };

// G9 for unknown codes, with status 404 (S6 FR-018).
export default function InviteNotFound() {
  return (
    <>
      <InviteHeader />
      <CodeEntry />
    </>
  );
}
