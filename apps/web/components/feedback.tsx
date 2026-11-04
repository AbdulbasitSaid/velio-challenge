// Banners, toasts, dialogs and empty states from the approved design system.
import type { ReactNode } from 'react';
import { Button, cx, Icon, type IconName } from './primitives';

export function Banner({
  tone = 'info',
  title,
  icon,
  action,
  children,
}: {
  tone?: 'info' | 'offline' | 'error';
  title?: string;
  icon?: IconName;
  action?: ReactNode;
  children?: ReactNode;
}) {
  const name = icon ?? (tone === 'offline' ? 'offline' : tone === 'error' ? 'alert' : 'info');
  return (
    <div
      className={cx('vl-banner', tone !== 'info' && `vl-banner-${tone}`)}
      role={tone === 'error' ? 'alert' : 'status'}
    >
      <Icon name={name} />
      <div className="vl-banner-body">
        {title ? <strong>{title}</strong> : null}
        {children}
      </div>
      {action ?? null}
    </div>
  );
}

export function Toast({ icon = 'check', children }: { icon?: IconName; children?: ReactNode }) {
  return (
    <div className="vl-toast" role="status">
      <Icon name={icon} />
      {children}
    </div>
  );
}

export function ConfirmDialog({
  title,
  body,
  confirm = 'Confirm',
  cancel = 'Cancel',
  destructive,
  busy,
  onConfirm,
  onCancel,
}: {
  title: string;
  body: ReactNode;
  confirm?: string;
  cancel?: string;
  destructive?: boolean;
  busy?: boolean;
  onConfirm?: () => void;
  onCancel?: () => void;
}) {
  return (
    <div className="vl-dialog-scrim">
      <div className="vl-dialog" role="dialog" aria-modal="true" aria-labelledby="dlg-title">
        <h2 id="dlg-title">{title}</h2>
        <p>{body}</p>
        <div className="vl-dialog-actions">
          <Button variant="quiet" onClick={onCancel} disabled={busy}>
            {cancel}
          </Button>
          <Button variant={destructive ? 'danger' : 'primary'} onClick={onConfirm} loading={busy}>
            {confirm}
          </Button>
        </div>
      </div>
    </div>
  );
}

export function BottomSheet({ label, children }: { label: string; children?: ReactNode }) {
  return (
    <div className="vl-sheet" role="dialog" aria-label={label}>
      <span className="vl-sheet-grip" aria-hidden />
      {children}
    </div>
  );
}

export function EmptyState({
  title,
  body,
  icon = 'sparkle',
  action,
}: {
  title: string;
  body?: ReactNode;
  icon?: IconName;
  action?: ReactNode;
}) {
  return (
    <div className="vl-empty">
      <span className="vl-empty-mark">
        <Icon name={icon} />
      </span>
      <h3>{title}</h3>
      {body ? <p>{body}</p> : null}
      {action ?? null}
    </div>
  );
}
