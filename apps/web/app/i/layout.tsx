import type { ReactNode } from 'react';

// Gives /i/* its own not-found boundary (G9 instead of the site-wide 404).
export default function InviteLayout({ children }: { children: ReactNode }) {
  return children;
}
