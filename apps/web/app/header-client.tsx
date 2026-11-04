'use client';

import { usePathname, useRouter } from 'next/navigation';
import { AppHeader, LivePill } from '@/components';
import { useOnline } from '@/lib/online';
import { useRealtimeStatus } from '@/lib/realtime/react';

function LiveStatus() {
  const online = useOnline();
  const status = useRealtimeStatus();
  return <LivePill status={!online ? 'offline' : status === 'reconnecting' ? 'reconnecting' : 'live'} />;
}

export function HeaderClient({
  current,
  user,
  live,
}: {
  current?: string;
  user: { name: string; seed: string } | null;
  live?: boolean;
}) {
  const pathname = usePathname();
  const router = useRouter();
  const role = pathname.startsWith('/host') ? 'host' : 'booker';
  return (
    <AppHeader
      role={role}
      current={current}
      user={user}
      status={live ? <LiveStatus /> : undefined}
      signInHref={`/signin?next=${encodeURIComponent(pathname)}`}
      onRoleChange={(next) => router.push(next === 'host' ? '/host/activities' : '/')}
    />
  );
}
