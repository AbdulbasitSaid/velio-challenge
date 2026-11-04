import { getViewer } from '@/lib/session';
import { HeaderClient } from './header-client';

/** X3 app shell header: the signed-in viewer comes from the server; the role toggle is client-side. */
export async function SiteHeader({ current }: { current?: string }) {
  const viewer = await getViewer();
  return (
    <HeaderClient
      current={current}
      user={viewer ? { name: viewer.displayName, seed: viewer.avatarSeed } : null}
    />
  );
}
