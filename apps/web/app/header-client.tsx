'use client';

import { usePathname, useRouter } from 'next/navigation';
import { AppHeader, LivePill, type Role } from '@/components';
import { useOnline } from '@/lib/online';
import { useRealtimeStatus } from '@/lib/realtime/react';
import { roleFor, saveRole } from '@/lib/role';

function LiveStatus() {
  const online = useOnline();
  const status = useRealtimeStatus();
  return <LivePill status={!online ? 'offline' : status === 'reconnecting' ? 'reconnecting' : 'live'} />;
}

export function HeaderClient({
  current,
  user,
  live,
  savedRole,
}: {
  current?: string;
  savedRole: Role;
  user: { name: string; seed: string } | null;
  live?: boolean;
}) {
  const pathname = usePathname();
  const router = useRouter();
  const role = roleFor(pathname, savedRole);
  return (
    <AppHeader
      role={role}
      current={current}
      user={user}
      status={live ? <LiveStatus /> : undefined}
      signInHref={`/signin?next=${encodeURIComponent(pathname)}`}
      onRoleChange={(next) => {
        saveRole(next);
        router.push(next === 'host' ? '/host/activities' : '/');
        router.refresh();
      }}
    />
  );
}
