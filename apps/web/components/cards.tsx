// Cards and list rows from the approved design system.
import type { ReactNode } from 'react';
import {
  Avatar,
  AvatarStack,
  Button,
  Chip,
  cx,
  Icon,
  Photo,
  PhotoArt,
  SpotsBadge,
  type ChipTone,
  type IconName,
  type Scene,
  type SpotsState,
  type StackPerson,
} from './primitives';

export interface DetailRow {
  icon?: IconName;
  label?: string;
  value: ReactNode;
  sub?: string;
}

export function DetailRows({ rows }: { rows: DetailRow[] }) {
  return (
    <ul className="vl-details">
      {rows.map((r, i) => (
        <li key={i}>
          <Icon name={r.icon ?? 'info'} />
          <span>
            {r.label ? <span className="vl-details-label">{r.label}</span> : null}
            <span className="vl-details-value">{r.value}</span>
            {r.sub ? <span className="vl-details-label">{r.sub}</span> : null}
          </span>
        </li>
      ))}
    </ul>
  );
}

export interface ActivityCardProps {
  title: string;
  photoUrl?: string | null;
  scene?: Scene;
  spots?: number;
  spotsState?: SpotsState;
  date?: string;
  zone?: string;
  place?: string;
  address?: string;
  price?: string;
  host?: string;
  going?: StackPerson[];
  goingTotal?: number;
  community?: string;
  lead?: string;
  compact?: boolean;
  /** Wraps the title in a link to the activity. */
  href?: string;
  children?: ReactNode;
}

export function ActivityCard(p: ActivityCardProps) {
  const rows: DetailRow[] = [
    { icon: 'calendar' as const, value: p.date, sub: p.zone },
    { icon: 'pin' as const, value: p.place, sub: p.address },
    { icon: 'price' as const, value: p.price ? `${p.price} · pay the host on the day` : null },
    { icon: 'host' as const, value: p.host ? `Hosted by ${p.host}` : null },
  ].filter((r) => r.value);
  return (
    <article className={cx('vl-activity', p.compact && 'vl-activity-compact')}>
      <div className="vl-activity-photo">
        <Photo src={p.photoUrl} scene={p.scene} alt={p.title} />
        {p.community ? <Chip tone="outline">{p.community}</Chip> : null}
        {p.spots != null ? <SpotsBadge spots={p.spots} state={p.spotsState} /> : null}
      </div>
      <div className="vl-activity-body">
        {p.lead ? <span style={{ color: 'var(--forest)', fontWeight: 700 }}>{p.lead}</span> : null}
        <h3 className="vl-activity-title">{p.href ? <a href={p.href}>{p.title}</a> : p.title}</h3>
        {p.compact ? (
          <span style={{ color: 'var(--muted)', fontSize: 14 }}>
            {[p.date, p.place].filter(Boolean).join(' · ')}
          </span>
        ) : (
          <DetailRows rows={rows} />
        )}
        {p.going ? <AvatarStack people={p.going} total={p.goingTotal} /> : null}
        {p.children}
      </div>
    </article>
  );
}

export function BookingRef({ code, label = 'Booking ref' }: { code: string; label?: string }) {
  return (
    <div className="vl-ref">
      <span className="vl-ref-label">{label}</span>
      <span className="vl-ref-code">{code}</span>
    </div>
  );
}

export type Source = 'direct' | 'vouch' | 'public';
export type InviteStatus = 'created' | 'opened' | 'claimed' | 'expired';

const SOURCE_TONE: Record<Source, ChipTone> = { direct: 'neutral', vouch: 'lime', public: 'sky' };
const SOURCE_LABEL: Record<Source, string> = { direct: 'Direct', vouch: 'Vouch', public: 'Public link' };
const STATUS_TONE: Record<InviteStatus, ChipTone> = {
  created: 'neutral',
  opened: 'sky',
  claimed: 'lime',
  expired: 'neutral',
};

export function MemberRow(p: {
  name: string;
  seed?: string;
  meta?: string;
  source?: Source;
  sourceLabel?: string;
  status?: InviteStatus;
  you?: boolean;
  removed?: boolean;
  pending?: boolean;
}) {
  return (
    <div className={cx('vl-listrow', p.removed && 'is-removed')}>
      {p.pending ? (
        <span
          className="vl-avatar"
          style={{ width: 40, height: 40, background: 'var(--line)', color: 'var(--muted)' }}
        >
          <Icon name="ticket" />
        </span>
      ) : (
        <Avatar name={p.name} seed={p.seed} decorative />
      )}
      <div className="vl-listrow-main">
        <span className="vl-listrow-name">
          {p.name}
          {p.you ? ' (you)' : ''}
        </span>
        <span className="vl-listrow-meta">{p.removed ? 'The host removed this booking' : p.meta}</span>
      </div>
      <div className="vl-listrow-end">
        {p.status ? (
          <Chip tone={STATUS_TONE[p.status]}>{p.status.charAt(0).toUpperCase() + p.status.slice(1)}</Chip>
        ) : null}
        {p.source ? (
          <Chip tone={SOURCE_TONE[p.source]}>{p.sourceLabel ?? SOURCE_LABEL[p.source]}</Chip>
        ) : null}
      </div>
    </div>
  );
}

export type Mark = 'attended' | 'no_show';

export function AttendanceRow(p: {
  name: string;
  seed?: string;
  bookingRef?: string;
  time?: string;
  source?: Source;
  sourceLabel?: string;
  mode?: 'before' | 'after';
  mark?: Mark | null;
  isNew?: boolean;
  removed?: boolean;
  onRemove?: () => void;
  onMark?: (mark: Mark) => void;
}) {
  const mode = p.mode ?? 'before';
  return (
    <div className={cx('vl-listrow', p.isNew && 'is-new', p.removed && 'is-removed')}>
      <Avatar name={p.name} seed={p.seed} decorative />
      <div className="vl-listrow-main">
        <span className="vl-listrow-name">{p.name}</span>
        <span className="vl-listrow-meta">{[p.bookingRef, p.time].filter(Boolean).join(' · ')}</span>
      </div>
      <div className="vl-listrow-end">
        <Chip tone={p.source ? SOURCE_TONE[p.source] : 'neutral'}>
          {p.sourceLabel ?? (p.source ? SOURCE_LABEL[p.source] : 'Direct')}
        </Chip>
        {p.removed ? null : mode === 'before' ? (
          <Button variant="destructive" small onClick={p.onRemove}>
            Remove
          </Button>
        ) : (
          <div className="vl-mark" role="group" aria-label={`Attendance for ${p.name}`}>
            <button
              type="button"
              className="is-attended"
              aria-pressed={p.mark === 'attended'}
              onClick={p.onMark ? () => p.onMark!('attended') : undefined}
            >
              Attended
            </button>
            <button
              type="button"
              className="is-noshow"
              aria-pressed={p.mark === 'no_show'}
              onClick={p.onMark ? () => p.onMark!('no_show') : undefined}
            >
              No-show
            </button>
          </div>
        )}
      </div>
    </div>
  );
}

export interface NextStep {
  title: string;
  meta?: string;
  href: string;
  photoUrl?: string | null;
  scene?: Scene;
  icon?: IconName;
}

export function NextSteps({ items }: { items: NextStep[] }) {
  return (
    <div className="vl-next">
      {items.map((it, i) => (
        <a key={i} href={it.href}>
          {it.photoUrl || it.scene ? (
            <span className="vl-next-thumb">
              <Photo src={it.photoUrl} scene={it.scene} alt="" />
            </span>
          ) : (
            <span className="vl-avatar" style={{ width: 44, height: 44, background: 'var(--lime)' }}>
              <Icon name={it.icon ?? 'share'} />
            </span>
          )}
          <span className="vl-next-text">
            <span className="vl-next-title">{it.title}</span>
            {it.meta ? <span className="vl-next-meta">{it.meta}</span> : null}
          </span>
          <Icon name="chevron" />
        </a>
      ))}
    </div>
  );
}

export function PlanCard(p: {
  title: string;
  href: string;
  photoUrl?: string | null;
  scene?: Scene;
  date?: string;
  place?: string;
  members?: StackPerson[];
  memberTotal?: number;
  code?: string;
  removed?: boolean;
  past?: boolean;
  attended?: boolean | null;
  /** Live spots for upcoming Plans (B6). */
  end?: ReactNode;
}) {
  return (
    <a className={cx('vl-plan', p.past && 'is-past')} href={p.href}>
      <span className="vl-plan-thumb">
        {p.photoUrl ? <Photo src={p.photoUrl} alt="" /> : <PhotoArt scene={p.scene} />}
      </span>
      <span className="vl-plan-main">
        <span className="vl-plan-title">{p.title}</span>
        <span className="vl-plan-meta">{[p.date, p.place].filter(Boolean).join(' · ')}</span>
        <span className="vl-plan-foot">
          <AvatarStack people={p.members ?? []} size={26} max={3} total={p.memberTotal} label={false} />
          {p.removed ? (
            <Chip tone="danger">Removed by host</Chip>
          ) : p.past ? (
            <Chip>{p.attended === false ? 'No-show' : 'Went'}</Chip>
          ) : (
            <span className="vl-ref-code" style={{ fontSize: 13, letterSpacing: 1 }}>
              {p.code}
            </span>
          )}
          {p.end}
        </span>
      </span>
    </a>
  );
}
