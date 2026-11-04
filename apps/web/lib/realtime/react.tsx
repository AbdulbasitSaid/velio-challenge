'use client';

// React bindings for the realtime client: one client per tab, live spots with the version gate and
// `rendered` acks, and the single polite live region that announces spots changes at most every 5 s.
import type { Topic } from '@velio/contracts';
import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useLayoutEffect,
  useMemo,
  useRef,
  useState,
  useSyncExternalStore,
  type ReactNode,
} from 'react';
import { RealtimeClient, type RealtimeStatus } from './client';

const RealtimeContext = createContext<RealtimeClient | null>(null);
const AnnounceContext = createContext<(message: string) => void>(() => undefined);

export const ANNOUNCE_INTERVAL_MS = 5_000;

function realtimeUrl(): string {
  const configured = process.env.NEXT_PUBLIC_REALTIME_ORIGIN;
  if (configured) return `${configured}/api/ws`;
  const { protocol, hostname, host } = window.location;
  // Next's dev rewrites don't carry WebSockets; locally connect to the API directly (same host, so the
  // session cookie still goes with it). In production CloudFront routes /api/ws on the same origin.
  if (process.env.NODE_ENV === 'development') return `ws://${hostname}:3001/api/ws`;
  return `${protocol === 'https:' ? 'wss' : 'ws'}://${host}/api/ws`;
}

export function RealtimeProvider({ children, client }: { children: ReactNode; client?: RealtimeClient }) {
  const [rt] = useState(() => client ?? new RealtimeClient({ url: realtimeUrl }));
  useEffect(() => {
    const onVisibility = () => rt.setVisible(document.visibilityState === 'visible');
    document.addEventListener('visibilitychange', onVisibility);
    return () => document.removeEventListener('visibilitychange', onVisibility);
  }, [rt]);
  return (
    <RealtimeContext.Provider value={rt}>
      <LiveAnnouncer>{children}</LiveAnnouncer>
    </RealtimeContext.Provider>
  );
}

function useClient(): RealtimeClient {
  const rt = useContext(RealtimeContext);
  if (!rt) throw new Error('RealtimeProvider missing');
  return rt;
}

export function useRealtimeStatus(): RealtimeStatus {
  const rt = useClient();
  return useSyncExternalStore(
    useCallback((cb) => rt.onStatus(cb), [rt]),
    () => rt.status,
    () => 'connecting',
  );
}

/** One polite region per page; extra messages within 5 s collapse into the latest (UX NFR-003). */
function LiveAnnouncer({ children }: { children: ReactNode }) {
  const [text, setText] = useState('');
  const last = useRef(0);
  const pending = useRef<string | null>(null);
  const timer = useRef<ReturnType<typeof setTimeout> | null>(null);

  const announce = useCallback((message: string) => {
    const now = Date.now();
    const wait = last.current + ANNOUNCE_INTERVAL_MS - now;
    if (wait <= 0 && !timer.current) {
      last.current = now;
      setText(message);
      return;
    }
    pending.current = message;
    timer.current ??= setTimeout(
      () => {
        timer.current = null;
        last.current = Date.now();
        setText(pending.current ?? '');
        pending.current = null;
      },
      Math.max(wait, 0),
    );
  }, []);

  useEffect(() => () => void (timer.current && clearTimeout(timer.current)), []);

  return (
    <AnnounceContext.Provider value={announce}>
      {children}
      <div className="vl-sr" role="status" aria-live="polite" aria-atomic="true">
        {text}
      </div>
    </AnnounceContext.Provider>
  );
}

export function useAnnounce(): (message: string) => void {
  return useContext(AnnounceContext);
}

export interface Spots {
  spotsLeft: number;
  version: number;
}

export type LiveSpots = Record<string, Spots & { changed: boolean }>;

export function spotsMessage(spotsLeft: number): string {
  if (spotsLeft <= 0) return 'Sold out';
  if (spotsLeft === 1) return 'Last spot';
  return `${spotsLeft} spots left`;
}

/**
 * Live spots for one or more activities. `initial` is the server-rendered snapshot; `refresh` fetches
 * fresh snapshots (rules 1, 3, 4). Events and snapshots both pass the version gate (rule 2), and each
 * painted event version is acknowledged (rule 6).
 */
export function useLiveSpots(
  initial: Record<string, Spots>,
  refresh: () => Promise<Record<string, Spots>>,
  options: {
    extraTopics?: Topic[];
    onPlan?: (planId: string) => void;
    onAttendance?: (activityId: string) => void;
    /** Announce changes for these activity IDs (the screen's main activity). */
    announce?: string[];
  } = {},
): { spots: LiveSpots; status: RealtimeStatus } {
  const rt = useClient();
  const status = useRealtimeStatus();
  const announce = useAnnounce();
  const [spots, setSpots] = useState<LiveSpots>(() =>
    Object.fromEntries(Object.entries(initial).map(([id, s]) => [id, { ...s, changed: false }])),
  );
  const shown = useRef(spots);
  const toAck = useRef<{ activityId: string; version: number }[]>([]);
  const latest = useRef({ refresh, options });
  useLayoutEffect(() => {
    latest.current = { refresh, options };
  });

  const ids = Object.keys(initial).sort().join(',');
  const extra = (options.extraTopics ?? []).join(',');

  useEffect(() => {
    // The version gate reads `shown` rather than running inside a state updater, so the announcement
    // (another component's state) isn't set while React renders this one.
    const merge = (id: string, next: Spots, fromEvent: boolean) => {
      const cur = shown.current[id];
      if (cur && next.version <= cur.version) return;
      const changed = fromEvent && !!cur && cur.spotsLeft !== next.spotsLeft;
      shown.current = { ...shown.current, [id]: { ...next, changed } };
      setSpots(shown.current);
      if (changed && latest.current.options.announce?.includes(id)) announce(spotsMessage(next.spotsLeft));
    };

    const activityIds = ids ? ids.split(',') : [];
    const topics = [
      ...activityIds.map((id) => `activity:${id}` as Topic),
      ...(extra ? (extra.split(',') as Topic[]) : []),
    ];
    if (!topics.length) return;
    return rt.watch({
      topics,
      refresh: async () => {
        const fresh = await latest.current.refresh();
        for (const [id, s] of Object.entries(fresh)) merge(id, s, false);
      },
      onSpots: (e) => {
        toAck.current.push({ activityId: e.activityId, version: e.version });
        merge(e.activityId, { spotsLeft: e.spotsLeft, version: e.version }, true);
      },
      onPlan: (planId) => latest.current.options.onPlan?.(planId),
      onAttendance: (activityId) => latest.current.options.onAttendance?.(activityId),
    });
  }, [rt, ids, extra, announce]);

  // Rule 6: acknowledge after the browser has painted the new state.
  useEffect(() => {
    if (!toAck.current.length) return;
    const frame = requestAnimationFrame(() => {
      for (const a of toAck.current.splice(0)) {
        const shown = spots[a.activityId];
        if (shown && shown.version === a.version) rt.rendered(a.activityId, a.version);
      }
    });
    return () => cancelAnimationFrame(frame);
  }, [spots, rt]);

  return useMemo(() => ({ spots, status }), [spots, status]);
}
