// Realtime client (S5 §4.7): one socket per tab implementing the six client rules in
// packages/contracts/src/realtime.ts. Framework-free so it can be tested with a fake socket and timers.
import type { ClientMessage, ServerMessage, SpotsEvent, Topic } from '@velio/contracts';

export type RealtimeStatus = 'connecting' | 'live' | 'reconnecting';

export interface Watch {
  topics: Topic[];
  /** Fetch every snapshot this screen shows. Called after `subscribe` on each (re)connect (rule 1), on
   * `resync` (rule 4) and every 10 s while disconnected (rule 3). */
  refresh: () => Promise<unknown> | void;
  onSpots?: (event: SpotsEvent) => void;
  /** Rule 5: the Plan changed; fetch it again. */
  onPlan?: (planId: string) => void;
  /** Rule 5: the attendance list changed; fetch it again. */
  onAttendance?: (activityId: string) => void;
}

export interface SocketLike {
  readyState: number;
  onopen: (() => void) | null;
  onmessage: ((event: { data: unknown }) => void) | null;
  onclose: (() => void) | null;
  onerror: (() => void) | null;
  send(data: string): void;
  close(): void;
}

export interface RealtimeOptions {
  /** Full ws(s) URL without query; a function is resolved at connect time (browser only). */
  url: string | (() => string);
  createSocket?: (url: string) => SocketLike;
  random?: () => number;
  /** Rule 3 polling interval. */
  pollMs?: number;
  /** Hidden this long, the socket closes; it resumes when the tab is visible again (S5 §4.7 step 6). */
  hiddenCloseMs?: number;
}

const OPEN = 1;
const BACKOFF_MIN = 1_000;
const BACKOFF_MAX = 30_000;

export class RealtimeClient {
  private socket: SocketLike | null = null;
  private watches = new Set<Watch>();
  private statusListeners = new Set<(s: RealtimeStatus) => void>();
  private _status: RealtimeStatus = 'connecting';
  private attempt = 0;
  private everConnected = false;
  private reconnectTimer: ReturnType<typeof setTimeout> | null = null;
  private pollTimer: ReturnType<typeof setInterval> | null = null;
  private hiddenTimer: ReturnType<typeof setTimeout> | null = null;
  private paused = false;
  private readonly createSocket: (url: string) => SocketLike;
  private readonly random: () => number;
  private readonly pollMs: number;
  private readonly hiddenCloseMs: number;

  constructor(private readonly opts: RealtimeOptions) {
    this.createSocket = opts.createSocket ?? ((url) => new WebSocket(url) as unknown as SocketLike);
    this.random = opts.random ?? Math.random;
    this.pollMs = opts.pollMs ?? 10_000;
    this.hiddenCloseMs = opts.hiddenCloseMs ?? 60_000;
  }

  get status(): RealtimeStatus {
    return this._status;
  }

  onStatus(listener: (s: RealtimeStatus) => void): () => void {
    this.statusListeners.add(listener);
    return () => this.statusListeners.delete(listener);
  }

  /** Starts following the topics. The returned function stops. */
  watch(watch: Watch): () => void {
    this.watches.add(watch);
    if (!this.socket && !this.reconnectTimer && !this.paused) this.connect();
    else if (this.socket?.readyState === OPEN) {
      this.send({ type: 'subscribe', topics: watch.topics });
      void watch.refresh();
    } else if (this._status === 'reconnecting') void watch.refresh();
    return () => {
      this.watches.delete(watch);
      if (this.socket?.readyState === OPEN) {
        const still = new Set([...this.watches].flatMap((w) => w.topics));
        const gone = watch.topics.filter((t) => !still.has(t));
        if (gone.length) this.send({ type: 'unsubscribe', topics: gone });
      }
      if (this.watches.size === 0) this.stop();
    };
  }

  /** Rule 6: after a `spots` version is painted. */
  rendered(activityId: string, version: number): void {
    if (this.socket?.readyState === OPEN) this.send({ type: 'rendered', activityId, version });
  }

  /** Page visibility (S5 §4.7 step 6). */
  setVisible(visible: boolean): void {
    if (visible) {
      if (this.hiddenTimer) clearTimeout(this.hiddenTimer);
      this.hiddenTimer = null;
      if (this.paused) {
        this.paused = false;
        if (this.watches.size) this.connect();
      }
    } else if (!this.hiddenTimer && !this.paused) {
      this.hiddenTimer = setTimeout(() => {
        this.hiddenTimer = null;
        this.paused = true;
        this.teardown();
      }, this.hiddenCloseMs);
    }
  }

  private connect(): void {
    this.reconnectTimer = null;
    const resume = this.everConnected ? '&resume=1' : '';
    let socket: SocketLike;
    try {
      const url = typeof this.opts.url === 'function' ? this.opts.url() : this.opts.url;
      socket = this.createSocket(`${url}?platform=web${resume}`);
    } catch {
      this.scheduleReconnect();
      return;
    }
    this.socket = socket;
    socket.onopen = () => {
      this.everConnected = true;
      this.attempt = 0;
      this.stopPolling();
      this.setStatus('live');
      const topics = [...new Set([...this.watches].flatMap((w) => w.topics))];
      if (topics.length) this.send({ type: 'subscribe', topics });
      this.refreshAll(); // rule 1: after subscribe
    };
    socket.onmessage = (event) => this.handle(event.data);
    socket.onclose = () => {
      if (this.socket !== socket) return;
      this.socket = null;
      if (this.watches.size && !this.paused) this.scheduleReconnect();
    };
    socket.onerror = () => socket.close();
  }

  private handle(data: unknown): void {
    // Shape-checked by hand: the Zod schema would add ~30 kB to every live page.
    let msg: ServerMessage;
    try {
      msg = JSON.parse(String(data)) as ServerMessage;
    } catch {
      return;
    }
    if (!msg || typeof msg !== 'object') return;
    if (msg.type === 'spots' && (typeof msg.spotsLeft !== 'number' || typeof msg.version !== 'number'))
      return;
    switch (msg.type) {
      case 'spots':
        for (const w of this.watches) if (w.topics.includes(`activity:${msg.activityId}`)) w.onSpots?.(msg);
        break;
      case 'plan':
        for (const w of this.watches) if (w.topics.includes(`plan:${msg.planId}`)) w.onPlan?.(msg.planId);
        break;
      case 'attendance':
        for (const w of this.watches)
          if (w.topics.includes(`host:${msg.activityId}`)) w.onAttendance?.(msg.activityId);
        break;
      case 'resync':
        this.refreshAll();
        break;
      default:
        break;
    }
  }

  private scheduleReconnect(): void {
    this.setStatus('reconnecting');
    this.startPolling();
    const ceiling = Math.min(BACKOFF_MAX, BACKOFF_MIN * 2 ** this.attempt);
    this.attempt++;
    // Full jitter keeps many tabs from reconnecting in step after a deploy.
    const delay = Math.max(BACKOFF_MIN / 2, Math.round(ceiling * this.random()));
    this.reconnectTimer = setTimeout(() => this.connect(), delay);
  }

  private startPolling(): void {
    if (this.pollTimer) return;
    this.refreshAll();
    this.pollTimer = setInterval(() => this.refreshAll(), this.pollMs);
  }

  private stopPolling(): void {
    if (this.pollTimer) clearInterval(this.pollTimer);
    this.pollTimer = null;
  }

  private refreshAll(): void {
    for (const w of this.watches) void Promise.resolve(w.refresh()).catch(() => undefined);
  }

  private send(message: ClientMessage): void {
    this.socket?.send(JSON.stringify(message));
  }

  private setStatus(status: RealtimeStatus): void {
    if (status === this._status) return;
    this._status = status;
    for (const l of this.statusListeners) l(status);
  }

  private teardown(): void {
    if (this.reconnectTimer) clearTimeout(this.reconnectTimer);
    this.reconnectTimer = null;
    this.stopPolling();
    const socket = this.socket;
    this.socket = null;
    socket?.close();
  }

  private stop(): void {
    this.teardown();
    if (this.hiddenTimer) clearTimeout(this.hiddenTimer);
    this.hiddenTimer = null;
    this.paused = false;
    this.attempt = 0;
    this.setStatus('connecting');
  }
}

/** Highest version wins (rule 2). Returns the state to show. */
export function applyVersion<T extends { version: number }>(current: T | null, next: T): T {
  return current && next.version <= current.version ? current : next;
}
