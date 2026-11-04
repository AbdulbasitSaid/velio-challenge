// Design-system primitives, ported from the approved prototype bundle (props per each component README).
// Hook-free, so they render on the server and inside client components alike.
import { avatarColor, initials } from '@velio/design-tokens';
import type { CSSProperties, ReactNode } from 'react';

export function cx(...parts: (string | false | null | undefined)[]): string {
  return parts.filter(Boolean).join(' ');
}

// Line icons, 24px grid, 1.75 stroke. Drawn for Velio.
const PATHS = {
  calendar: 'M4 6.5h16v13H4zM4 10h16M8 4v4M16 4v4',
  pin: 'M12 21s-6.5-5.6-6.5-11a6.5 6.5 0 0 1 13 0C18.5 15.4 12 21 12 21zM12 12.5a2.5 2.5 0 1 0 0-5 2.5 2.5 0 0 0 0 5z',
  price: 'M4 12.5V5h7.5l8.5 8.5-7.5 7.5zM8.5 9h.01',
  host: 'M12 12a4 4 0 1 0 0-8 4 4 0 0 0 0 8zM4.5 20.5c1.2-3.6 4-5.5 7.5-5.5s6.3 1.9 7.5 5.5',
  people:
    'M9 11a3.5 3.5 0 1 0 0-7 3.5 3.5 0 0 0 0 7zM2.5 20c.9-3.2 3.3-5 6.5-5s5.6 1.8 6.5 5M16 4.5a3.2 3.2 0 0 1 0 6.2M18 15.3c1.7.6 2.9 2.2 3.5 4.7',
  directions: 'M12 2.8l9.2 9.2-9.2 9.2L2.8 12zM9 14.5V12a1.5 1.5 0 0 1 1.5-1.5H15M13 8.5l2 2-2 2',
  check: 'M5 12.5l4.5 4.5L19 7.5',
  close: 'M6 6l12 12M18 6L6 18',
  search: 'M10.5 17.5a7 7 0 1 0 0-14 7 7 0 0 0 0 14zM15.5 15.5L20.5 20.5',
  share: 'M12 15V3.5M7.5 8L12 3.5 16.5 8M5 12.5V20h14v-7.5',
  copy: 'M8.5 8.5h11v11h-11zM15.5 8.5v-4h-11v11h4',
  chevron: 'M9.5 5.5L16 12l-6.5 6.5',
  back: 'M14.5 5.5L8 12l6.5 6.5',
  plus: 'M12 5v14M5 12h14',
  minus: 'M5 12h14',
  offline:
    'M3 3l18 18M8.5 16.5a5 5 0 0 1 7 0M5 13a10 10 0 0 1 4.5-2.4M19 13a10 10 0 0 0-2.3-1.6M2 9.5A14 14 0 0 1 7 6.6M22 9.5A14 14 0 0 0 11 6M12 20h.01',
  alert: 'M12 3.5l9.5 16.5h-19zM12 10v4.5M12 17.5h.01',
  info: 'M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18zM12 11v5.5M12 7.5h.01',
  lock: 'M6 10.5h12v10H6zM8.5 10.5V7.5a3.5 3.5 0 0 1 7 0v3',
  map: 'M3.5 6.5L9 4l6 2.5L20.5 4v13.5L15 20l-6-2.5L3.5 20zM9 4v13.5M15 6.5V20',
  list: 'M8.5 6.5h12M8.5 12h12M8.5 17.5h12M4 6.5h.01M4 12h.01M4 17.5h.01',
  flag: 'M5 21V4M5 4.5h12l-2.5 4 2.5 4H5',
  clock: 'M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18zM12 7.5V12l3 2',
  ticket: 'M3.5 7.5h17v3a2 2 0 0 0 0 4v3h-17v-3a2 2 0 0 0 0-4zM14.5 7.5v10',
  refresh: 'M20 11.5A8 8 0 0 0 5.5 7M4 12.5A8 8 0 0 0 18.5 17M5 3.5V7h3.5M19 20.5V17h-3.5',
  menu: 'M4 7h16M4 12h16M4 17h16',
  target:
    'M12 19.5a7.5 7.5 0 1 0 0-15 7.5 7.5 0 0 0 0 15zM12 2v3M12 19v3M2 12h3M19 12h3M12 13.5a1.5 1.5 0 1 0 0-3 1.5 1.5 0 0 0 0 3z',
  phone: 'M7 2.5h10v19H7zM11 18.5h2',
  sparkle: 'M12 3l1.8 5.2L19 10l-5.2 1.8L12 17l-1.8-5.2L5 10l5.2-1.8z',
  arrow: 'M4.5 12h15M13.5 6l6 6-6 6',
} as const;

export type IconName = keyof typeof PATHS;

export function Icon({ name, label, className }: { name: IconName; label?: string; className?: string }) {
  return (
    <svg
      className={cx('vl-icon', className)}
      viewBox="0 0 24 24"
      aria-hidden={label ? undefined : true}
      role={label ? 'img' : undefined}
      aria-label={label}
    >
      <path d={PATHS[name]} />
    </svg>
  );
}

export interface ButtonProps {
  variant?: 'primary' | 'secondary' | 'quiet' | 'destructive' | 'danger';
  loading?: boolean;
  disabled?: boolean;
  block?: boolean;
  small?: boolean;
  icon?: IconName;
  href?: string;
  type?: 'button' | 'submit';
  id?: string;
  className?: string;
  onClick?: () => void;
  children?: ReactNode;
  /** For links that leave the site (directions, WhatsApp). */
  external?: boolean;
}

export function Button({
  variant = 'primary',
  loading,
  disabled,
  block,
  small,
  icon,
  href,
  ...p
}: ButtonProps) {
  const className = cx(
    'vl-btn',
    `vl-btn-${variant}`,
    block && 'vl-btn-block',
    small && 'vl-btn-sm',
    loading && 'is-loading',
    p.className,
  );
  const content = (
    <>
      {loading ? <span className="vl-spinner" aria-hidden /> : icon ? <Icon name={icon} /> : null}
      {p.children}
    </>
  );
  if (href) {
    return (
      <a
        className={className}
        href={href}
        id={p.id}
        onClick={p.onClick}
        {...(p.external ? { target: '_blank', rel: 'noopener noreferrer' } : {})}
      >
        {content}
      </a>
    );
  }
  return (
    <button
      className={className}
      type={p.type ?? 'button'}
      id={p.id}
      disabled={disabled || loading}
      aria-busy={loading || undefined}
      onClick={p.onClick}
    >
      {content}
    </button>
  );
}

export type SpotsState = 'live' | 'changed' | 'stale';

/** Five states (UX FR-003). Not a live region itself: screens announce changes through one throttled region. */
export function SpotsBadge({
  spots,
  state = 'live',
  label,
  className,
}: {
  spots: number;
  state?: SpotsState;
  label?: string;
  className?: string;
}) {
  let cls = 'vl-spots';
  let text: string;
  let dot = true;
  if (state === 'stale') {
    cls += ' vl-spots-stale';
    text = label ?? 'Reconnecting…';
    dot = false;
  } else if (spots <= 0) {
    cls += ' vl-spots-soldout';
    text = 'Sold out';
    dot = false;
  } else if (spots <= 2) {
    cls += ' vl-spots-last';
    text = spots === 1 ? 'Last spot' : 'Last 2 spots';
    dot = false;
  } else {
    text = `${spots} spots left`;
    if (state === 'changed') cls += ' vl-spots-changed';
  }
  return (
    <span className={cx(cls, className)} data-state={state}>
      {dot ? <span className="vl-dot" aria-hidden /> : null}
      {text}
    </span>
  );
}

export function LivePill({
  status,
  minutes,
}: {
  status: 'live' | 'reconnecting' | 'offline';
  minutes?: number;
}) {
  const text =
    status === 'live'
      ? 'Live'
      : status === 'reconnecting'
        ? 'Reconnecting…'
        : `Offline${minutes != null ? ` · updated ${minutes} min ago` : ''}`;
  return (
    <span className={cx('vl-pill', status !== 'live' && `vl-pill-${status}`)} role="status">
      {status === 'live' ? (
        <span className="vl-dot vl-dot-pulse" aria-hidden />
      ) : status === 'offline' ? (
        <Icon name="offline" />
      ) : (
        <span className="vl-spinner" aria-hidden style={{ width: 10, height: 10 }} />
      )}
      {text}
    </span>
  );
}

export interface AvatarProps {
  name: string;
  /** The person's avatarSeed; colour is the shared hash over the five avatar tokens (MVP FR-032). */
  seed?: string;
  size?: number;
  plus?: number;
  decorative?: boolean;
}

export function Avatar({ name, seed, size = 40, plus, decorative }: AvatarProps) {
  const background = plus ? 'var(--surface)' : `var(--${avatarColor(seed ?? name)})`;
  return (
    <span
      className="vl-avatar"
      style={{ width: size, height: size, background, fontSize: Math.round(size * 0.36) }}
      aria-hidden={decorative || undefined}
      title={decorative ? undefined : name}
    >
      {plus ? `+${plus}` : initials(name)}
    </span>
  );
}

export interface StackPerson {
  name: string;
  seed?: string;
}

function defaultGoing(shown: StackPerson[], extra: number): string {
  if (!shown.length) return 'Be the first to book';
  if (shown.length === 1 && extra <= 0) return `${shown[0]!.name} is going`;
  const names = shown
    .slice(0, 2)
    .map((p) => p.name)
    .join(', ');
  const rest = extra + Math.max(0, shown.length - 2);
  return rest > 0
    ? `${names} and ${rest} other${rest === 1 ? '' : 's'} are going`
    : `${shown.map((p) => p.name).join(' and ')} are going`;
}

export function AvatarStack({
  people,
  total,
  max = 3,
  size = 34,
  label,
}: {
  people: StackPerson[];
  total?: number;
  max?: number;
  size?: number;
  label?: string | false;
}) {
  const shown = people.slice(0, max);
  const extra = (total ?? people.length) - shown.length;
  return (
    <div className="vl-stack">
      <div className="vl-stack-faces" aria-hidden>
        {shown.map((p, i) => (
          <Avatar key={i} name={p.name} seed={p.seed} size={size} decorative />
        ))}
        {extra > 0 ? <Avatar name="" plus={extra} size={size} decorative /> : null}
      </div>
      {label === false ? null : <span className="vl-stack-label">{label ?? defaultGoing(shown, extra)}</span>}
    </div>
  );
}

export type ChipTone = 'neutral' | 'lime' | 'sky' | 'forest' | 'outline' | 'danger';

export function Chip({
  tone = 'neutral',
  icon,
  className,
  children,
}: {
  tone?: ChipTone;
  icon?: IconName;
  className?: string;
  children?: ReactNode;
}) {
  return (
    <span className={cx('vl-chip', tone !== 'neutral' && `vl-chip-${tone}`, className)}>
      {icon ? <Icon name={icon} /> : null}
      {children}
    </span>
  );
}

export interface TextFieldProps {
  label?: string;
  id?: string;
  name?: string;
  value?: string;
  defaultValue?: string;
  placeholder?: string;
  help?: string;
  error?: string | null;
  code?: boolean;
  search?: boolean;
  multiline?: boolean;
  maxLength?: number;
  /** Shows "count / maxLength" under the field. */
  count?: number;
  type?: string;
  inputMode?: 'text' | 'email' | 'tel' | 'numeric' | 'decimal' | 'search' | 'url' | 'none';
  autoComplete?: string;
  /** A `<datalist>` id with suggestions. */
  list?: string;
  min?: string;
  readOnly?: boolean;
  disabled?: boolean;
  required?: boolean;
  className?: string;
  onChange?: (value: string) => void;
}

export function TextField(p: TextFieldProps) {
  const id = p.id ?? `f-${(p.label ?? 'field').toLowerCase().replace(/[^a-z0-9]+/g, '-')}`;
  const describedBy = p.error ? `${id}-err` : p.help || p.count != null ? `${id}-help` : undefined;
  const common = {
    id,
    name: p.name,
    value: p.value,
    defaultValue: p.defaultValue,
    placeholder: p.placeholder,
    'aria-invalid': p.error ? true : undefined,
    'aria-describedby': describedBy,
    maxLength: p.maxLength,
    autoComplete: p.autoComplete,
    readOnly: p.readOnly,
    disabled: p.disabled,
    required: p.required,
    onChange: p.onChange
      ? (e: { currentTarget: { value: string } }) => p.onChange!(e.currentTarget.value)
      : undefined,
  };
  const control = p.multiline ? (
    <textarea {...common} />
  ) : (
    <input {...common} type={p.type ?? 'text'} inputMode={p.inputMode} list={p.list} min={p.min} />
  );
  return (
    <div
      className={cx(
        'vl-field',
        p.code && 'vl-field-code',
        p.search && 'vl-field-search',
        p.error && 'has-error',
        p.className,
      )}
    >
      {p.label ? <label htmlFor={id}>{p.label}</label> : null}
      {p.search ? (
        <div style={{ position: 'relative' }}>
          <Icon name="search" />
          {control}
        </div>
      ) : (
        control
      )}
      {p.error ? (
        <span className="vl-field-error" id={`${id}-err`}>
          <Icon name="alert" />
          {p.error}
        </span>
      ) : p.help || p.count != null ? (
        <span className="vl-field-help" id={`${id}-help`}>
          <span>{p.help ?? ''}</span>
          {p.count != null ? (
            <span>
              {p.count} / {p.maxLength}
            </span>
          ) : null}
        </span>
      ) : null}
    </div>
  );
}

export type SegmentedOption = string | { value: string; label: string; icon?: IconName };

export function Segmented({
  label,
  value,
  options,
  onChange,
}: {
  label: string;
  value: string;
  options: SegmentedOption[];
  onChange?: (value: string) => void;
}) {
  return (
    <div className="vl-seg" role="group" aria-label={label}>
      {options.map((o) => {
        const val = typeof o === 'string' ? o : o.value;
        return (
          <button
            key={val}
            type="button"
            aria-pressed={value === val}
            onClick={onChange ? () => onChange(val) : undefined}
          >
            {typeof o !== 'string' && o.icon ? <Icon name={o.icon} /> : null}
            {typeof o === 'string' ? o : o.label}
          </button>
        );
      })}
    </div>
  );
}

export type Scene = 'lake' | 'savanna' | 'city' | 'coast';

const SCENES: Record<Scene, { sky: string; far: string; near: string; water: string }> = {
  lake: { sky: 'var(--sun)', far: 'var(--peach)', near: 'var(--forest)', water: 'var(--sky)' },
  savanna: { sky: 'var(--peach)', far: 'var(--sun)', near: 'var(--forest)', water: 'var(--lime)' },
  city: { sky: 'var(--lilac)', far: 'var(--sky)', near: 'var(--forest)', water: 'var(--lime)' },
  coast: { sky: 'var(--sky)', far: 'var(--lime)', near: 'var(--forest)', water: 'var(--info)' },
};

/** Duotone landscape: the placeholder when an activity has no photo yet. */
export function PhotoArt({ scene = 'lake', alt }: { scene?: Scene; alt?: string }) {
  const s = SCENES[scene];
  return (
    <svg
      viewBox="0 0 320 200"
      preserveAspectRatio="xMidYMid slice"
      role={alt ? 'img' : undefined}
      aria-label={alt || undefined}
      aria-hidden={alt ? undefined : true}
    >
      <rect width={320} height={200} style={{ fill: s.sky }} />
      <circle cx={232} cy={78} r={30} style={{ fill: 'var(--surface)', opacity: 0.85 }} />
      <path d="M0 120 L60 84 L110 108 L170 70 L240 112 L320 92 L320 200 L0 200Z" style={{ fill: s.far }} />
      <path d="M0 140 L320 132 L320 200 L0 200Z" style={{ fill: s.water }} />
      <path
        d="M0 150 C60 140 90 160 150 152 C210 144 260 162 320 150 L320 200 L0 200Z"
        style={{ fill: s.near }}
      />
      <path d="M150 132 l14 -6 l14 6z" style={{ fill: s.near }} />
    </svg>
  );
}

/** A real activity photo, or the scene art when there is none. `priority` for the hero (S6 §4.8). */
export function Photo({
  src,
  alt,
  scene,
  priority,
}: {
  src?: string | null;
  alt: string;
  scene?: Scene;
  priority?: boolean;
}) {
  if (!src) return <PhotoArt scene={scene} alt={alt} />;
  return (
    // eslint-disable-next-line @next/next/no-img-element -- photos come from our CDN at fixed sizes
    <img
      src={src}
      alt={alt}
      loading={priority ? 'eager' : 'lazy'}
      fetchPriority={priority ? 'high' : undefined}
      decoding="async"
    />
  );
}

export function Skeleton({ variant = 'card', width }: { variant?: 'card' | 'row' | 'text'; width?: string }) {
  const bar = (style: CSSProperties) => <div className="vl-skel" style={style} />;
  if (variant === 'text') return bar({ height: 14, width: width ?? '70%' });
  if (variant === 'row')
    return (
      <div className="vl-listrow" aria-hidden>
        {bar({ width: 40, height: 40, borderRadius: '50%' })}
        <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: 8 }}>
          {bar({ height: 14, width: '55%' })}
          {bar({ height: 12, width: '35%' })}
        </div>
      </div>
    );
  return (
    <div className="vl-activity" aria-busy aria-label="Loading">
      {bar({ aspectRatio: '16 / 10', borderRadius: 0 })}
      <div className="vl-activity-body">
        {bar({ height: 26, width: '75%' })}
        {bar({ height: 14, width: '60%' })}
        {bar({ height: 14, width: '45%' })}
        {bar({ height: 52, borderRadius: 999, marginTop: 8 })}
      </div>
    </div>
  );
}
