// App header (web) and app bar (phone-width screens) from the approved design system.
import Link from 'next/link';
import type { ReactNode } from 'react';
import { Avatar, Button, Icon, Segmented } from './primitives';

export type Role = 'booker' | 'host';

const LINKS: Record<Role, { label: string; href: string }[]> = {
  booker: [
    { label: 'Communities', href: '/' },
    { label: 'My plans', href: '/me/plans' },
  ],
  host: [
    { label: 'My activities', href: '/host/activities' },
    { label: 'Create activity', href: '/host/activities/new' },
  ],
};

export function AppHeader({
  role = 'booker',
  current,
  user,
  compact,
  signInHref = '/signin',
  onRoleChange,
}: {
  role?: Role;
  current?: string;
  /** Signed-in user; absent when signed out. */
  user?: { name: string; seed: string } | null;
  compact?: boolean;
  signInHref?: string;
  onRoleChange?: (role: Role) => void;
}) {
  return (
    <header className="vl-header">
      <Link className="vl-wordmark" href="/">
        velio
      </Link>
      {compact ? null : (
        <nav className="vl-header-nav" aria-label="Main">
          {LINKS[role].map((l) => (
            <Link key={l.href} href={l.href} aria-current={l.label === current ? 'page' : undefined}>
              {l.label}
            </Link>
          ))}
        </nav>
      )}
      <div className="vl-header-end">
        {user ? (
          <>
            <Segmented
              label="Role"
              value={role === 'host' ? 'Host' : 'Booker'}
              options={['Booker', 'Host']}
              onChange={onRoleChange ? (v) => onRoleChange(v === 'Host' ? 'host' : 'booker') : undefined}
            />
            <Avatar name={user.name} seed={user.seed} size={36} />
          </>
        ) : (
          <Button variant="secondary" small href={signInHref}>
            Continue
          </Button>
        )}
      </div>
    </header>
  );
}

export function AppBar({
  title,
  backHref,
  onBack,
  end,
}: {
  title: string;
  backHref?: string;
  onBack?: () => void;
  end?: ReactNode;
}) {
  const spacer = <span style={{ width: 44 }} />;
  return (
    <div className="vl-appbar">
      {backHref ? (
        <Link className="vl-iconbtn" href={backHref} aria-label="Back">
          <Icon name="back" />
        </Link>
      ) : onBack ? (
        <button className="vl-iconbtn" type="button" aria-label="Back" onClick={onBack}>
          <Icon name="back" />
        </button>
      ) : (
        spacer
      )}
      <span className="vl-appbar-title">{title}</span>
      {end ?? spacer}
    </div>
  );
}
