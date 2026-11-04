import postgres from 'postgres';
import { z } from 'zod';
import type { Logger } from '../../telemetry/logger';
import { CHANNELS } from './notify';

const SpotsPayload = z.object({
  activityId: z.uuid(),
  spotsLeft: z.number().int(),
  version: z.number().int(),
  committedAt: z.string(),
});
const PlanPayload = z.object({ planId: z.uuid() });
const AttendancePayload = z.object({ activityId: z.uuid() });

export type SpotsPayload = z.infer<typeof SpotsPayload>;

export interface ListenerHandlers {
  spots(payload: SpotsPayload, receivedAt: number): void;
  plan(planId: string): void;
  attendance(activityId: string): void;
  /** The connection came back after dropping: notifications may have been lost. */
  reconnected(): void;
}

const RETRY_MIN_MS = 250;
const RETRY_MAX_MS = 5_000;

/**
 * One direct connection per process running LISTEN on every channel (MVP plan §4.2, S3 NFR-004).
 * postgres.js re-listens only once after a drop and gives up if that fails, so this keeps its own
 * connection and retries until LISTEN succeeds again.
 */
export function createListener(url: string, logger: Logger, handlers: ListenerHandlers) {
  let listening = false;
  let everListened = false;
  let stopped = false;
  let retry: ReturnType<typeof setTimeout> | undefined;
  let delay = RETRY_MIN_MS;

  function dispatch(channel: string, raw: string) {
    const receivedAt = Date.now();
    let value: unknown;
    try {
      value = JSON.parse(raw);
    } catch {
      value = undefined;
    }
    // Invalid payloads never reach a client; the log names the channel only.
    if (channel === CHANNELS.spots) {
      const p = SpotsPayload.safeParse(value);
      if (p.success) return handlers.spots(p.data, receivedAt);
    } else if (channel === CHANNELS.plan) {
      const p = PlanPayload.safeParse(value);
      if (p.success) return handlers.plan(p.data.planId);
    } else if (channel === CHANNELS.attendance) {
      const p = AttendancePayload.safeParse(value);
      if (p.success) return handlers.attendance(p.data.activityId);
    }
    logger.warn({ channel }, 'invalid notification payload dropped');
  }

  // `onnotify` is the hook postgres.js's own listen() uses; it isn't in the published Options type.
  const options = {
    max: 1,
    idle_timeout: 0,
    max_lifetime: null,
    connect_timeout: 5,
    fetch_types: false,
    onnotice: () => {},
    onnotify: dispatch,
    onclose: () => {
      if (!listening) return;
      listening = false;
      if (!stopped) {
        logger.warn('realtime listener connection closed; reconnecting');
        schedule(RETRY_MIN_MS);
      }
    },
  };
  const sql = postgres(url, options as postgres.Options<Record<string, never>>);

  const listenSql = Object.values(CHANNELS)
    .map((c) => `LISTEN "${c}"`)
    .join('; ');

  async function attempt(): Promise<boolean> {
    try {
      await sql.unsafe(listenSql);
    } catch (err) {
      if (!stopped) logger.warn({ err }, 'realtime listener could not LISTEN; retrying');
      return false;
    }
    listening = true;
    delay = RETRY_MIN_MS;
    if (everListened) handlers.reconnected();
    everListened = true;
    return true;
  }

  function schedule(ms: number) {
    clearTimeout(retry);
    retry = setTimeout(async () => {
      if (stopped || listening) return;
      if (!(await attempt())) {
        delay = Math.min(delay * 2, RETRY_MAX_MS);
        schedule(delay);
      }
    }, ms);
  }

  return {
    /** Resolves once the first LISTEN succeeds; keeps retrying in the background until then. */
    start(): Promise<void> {
      return new Promise((resolve) => {
        const first = async () => {
          if (stopped) return resolve();
          if (await attempt()) return resolve();
          delay = Math.min(delay * 2, RETRY_MAX_MS);
          retry = setTimeout(first, delay);
        };
        void first();
      });
    },
    listening: () => listening,
    async stop() {
      stopped = true;
      clearTimeout(retry);
      listening = false;
      await sql.end({ timeout: 2 });
    },
  };
}

export type Listener = ReturnType<typeof createListener>;
