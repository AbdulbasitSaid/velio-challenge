'use client';

import { usePathname, useRouter } from 'next/navigation';
import { AppHeader } from '@/components';

export function HeaderClient({
  current,
  user,
}: {
  current?: string;
  user: { name: string; seed: string } | null;
}) {
  const pathname = usePathname();
  const router = useRouter();
  const role = pathname.startsWith('/host') ? 'host' : 'booker';
  return (
    <AppHeader
      role={role}
      current={current}
      user={user}
      signInHref={`/signin?next=${encodeURIComponent(pathname)}`}
      onRoleChange={(next) => router.push(next === 'host' ? '/host/activities' : '/')}
    />
  );
}
