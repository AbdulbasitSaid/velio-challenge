import { cookies } from 'next/headers';
import { parseRole, ROLE_COOKIE } from '@/lib/role';
import { getViewer } from '@/lib/session';
import { HeaderClient } from './header-client';

/** X3 app shell header: the signed-in viewer comes from the server; the role toggle is client-side. */
export async function SiteHeader({ current, live }: { current?: string; live?: boolean }) {
  const [viewer, jar] = await Promise.all([getViewer(), cookies()]);
  return (
    <HeaderClient
      current={current}
      live={live}
      savedRole={parseRole(jar.get(ROLE_COOKIE)?.value)}
      user={viewer ? { name: viewer.displayName, seed: viewer.avatarSeed } : null}
    />
  );
}
