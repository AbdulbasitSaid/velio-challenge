import { getViewer } from '@/lib/session';
import { HeaderClient } from './header-client';

/** X3 app shell header: the signed-in viewer comes from the server; the role toggle is client-side. */
export async function SiteHeader({ current, live }: { current?: string; live?: boolean }) {
  const viewer = await getViewer();
  return (
    <HeaderClient
      current={current}
      live={live}
      user={viewer ? { name: viewer.displayName, seed: viewer.avatarSeed } : null}
    />
  );
}
