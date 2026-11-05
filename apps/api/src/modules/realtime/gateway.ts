import { createRoute, OpenAPIHono, z } from '@hono/zod-openapi';
import type { MeterProvider } from '@opentelemetry/api';
import {
  ClientMessage,
  RealtimePlatform,
  ServerMessage,
  type RealtimePlatform as Platform,
  type ServerMessage as ServerMessageType,
} from '@velio/contracts';
import type { Server, ServerWebSocket, WebSocketHandler } from 'bun';
import type { AppEnv } from '../../app';
import type { Db } from '../../db/client';
import { ApiError } from '../../errors';
import { errorResponse, SECURITY } from '../../openapi';
import { createRollingWindow } from '../../telemetry/rolling';
import type { Logger } from '../../telemetry/logger';
import { createAckWindow } from './acks';
import { createListener, type SpotsPayload } from './listener';
import { createRealtimeMetrics, type EventType } from './metrics';
import { activityTopic, authorizeTopic, hostTopic, parseTopic, planTopic } from './topics';

// Bun's WebSocket APIs stay in this module and index.ts (MVP plan §8, S3 NFR-005).

/** Engineering limits (S3 PLANNING §4.3, FR-014), not product rules. */
export const LIMITS = {
  maxMessageBytes: 4 * 1024,
  maxTopics: 20,
  maxMalformed: 20,
  /** Bun's hard frame cap; frames above it close with 1009 before the app sees them. */
  maxFrameBytes: 64 * 1024,
  backpressureBytes: 1024 * 1024,
  ackedPerSocket: 1_000,
};

/** Server ping interval (parent NFR-009). */
export const PING_INTERVAL_MS = 30_000;

interface SocketData {
  userId: string | null;
  platform: Platform;
  topics: Set<string>;
  /** `activityId:version` already acknowledged by this socket. */
  acked: Set<string>;
  malformed: number;
  closed: boolean;
  /** Messages are handled one at a time per socket, so subscribe/unsubscribe keep their order. */
  queue: Promise<void>;
}

type Socket = ServerWebSocket<SocketData>;

const wsRoute = createRoute({
  method: 'get',
  path: '/ws',
  summary: 'Realtime WebSocket (upgrade)',
  description:
    'Upgrades to a WebSocket. The session cookie or bearer token identifies the user; without one the socket is anonymous and may subscribe to `activity:` topics only. Messages: `RealtimeClientMessage` and `RealtimeServerMessage`. Client rules are documented with those schemas.',
  security: [...SECURITY, {}],
  request: {
    query: z.object({ platform: RealtimePlatform, resume: z.enum(['1']).optional() }),
  },
  responses: {
    101: { description: 'Switching protocols' },
    200: {
      description: 'Message schemas, for reference (never returned)',
      content: { 'application/json': { schema: ServerMessage } },
    },
    400: errorResponse('`validation_failed`: missing `platform` or not a WebSocket upgrade'),
  },
});

export interface RealtimeDeps {
  db: Db;
  logger: Logger;
  /** Direct (unpooled) connection for LISTEN. */
  listenUrl: string;
  meterProvider?: MeterProvider;
  /** Tests shorten it. */
  pingIntervalMs?: number;
}

export function createRealtime(deps: RealtimeDeps) {
  const { db, logger } = deps;
  const sockets = new Set<Socket>();
  /** Subscriber count per topic on this instance, for resync. */
  const topicCounts = new Map<string, number>();
  const acks = createAckWindow();
  /** The last hour of commit-to-ack latencies, for the admin page's p95 (S8 FR-009). */
  const latency = createRollingWindow();
  const m = createRealtimeMetrics(() => {
    const counts = new Map<Platform, number>();
    for (const ws of sockets) counts.set(ws.data.platform, (counts.get(ws.data.platform) ?? 0) + 1);
    return counts;
  }, deps.meterProvider);
  let server: Server<SocketData> | undefined;
  let pinger: ReturnType<typeof setInterval> | undefined;

  function send(ws: Socket, msg: ServerMessageType) {
    if (!ws.data.closed) ws.send(JSON.stringify(msg));
  }

  function publish(topic: string, msg: ServerMessageType, type: EventType) {
    if (!server) return;
    server.publish(topic, JSON.stringify(msg));
    m.published.add(1, { type });
  }

  function track(ws: Socket, topic: string, delta: 1 | -1) {
    if (delta === 1) {
      ws.data.topics.add(topic);
    } else {
      ws.data.topics.delete(topic);
    }
    const next = (topicCounts.get(topic) ?? 0) + delta;
    if (next > 0) topicCounts.set(topic, next);
    else topicCounts.delete(topic);
  }

  function malformed(ws: Socket) {
    ws.data.malformed++;
    send(ws, { type: 'error', code: 'validation_failed' });
    if (ws.data.malformed >= LIMITS.maxMalformed) ws.close(1008, 'too many invalid messages');
  }

  async function subscribe(ws: Socket, topics: string[]) {
    const accepted: string[] = [];
    for (const raw of topics) {
      const parsed = parseTopic(raw);
      if (!parsed) {
        send(ws, { type: 'error', code: 'validation_failed', topic: raw });
        continue;
      }
      if (ws.data.topics.has(raw)) {
        accepted.push(raw);
        continue;
      }
      if (ws.data.topics.size >= LIMITS.maxTopics) {
        send(ws, { type: 'error', code: 'validation_failed', topic: raw });
        continue;
      }
      const verdict = await authorizeTopic(db, parsed, ws.data.userId);
      if (ws.data.closed) return;
      if (verdict !== 'ok') {
        send(ws, { type: 'error', code: verdict, topic: raw });
        continue;
      }
      ws.subscribe(raw);
      track(ws, raw, 1);
      accepted.push(raw);
    }
    if (accepted.length > 0) send(ws, { type: 'subscribed', topics: accepted });
  }

  function unsubscribe(ws: Socket, topics: string[]) {
    for (const topic of topics) {
      if (!ws.data.topics.has(topic)) continue;
      ws.unsubscribe(topic);
      track(ws, topic, -1);
    }
  }

  /** S3 FR-013: one sample per socket per version this instance published within the window. */
  function rendered(ws: Socket, activityId: string, version: number) {
    const key = `${activityId}:${version}`;
    const subscribed =
      ws.data.topics.has(activityTopic(activityId)) || ws.data.topics.has(hostTopic(activityId));
    const committedAt = acks.committedAt(activityId, version);
    if (!subscribed || committedAt === undefined || ws.data.acked.has(key)) {
      m.acksIgnored.add(1);
      return;
    }
    ws.data.acked.add(key);
    if (ws.data.acked.size > LIMITS.ackedPerSocket) {
      ws.data.acked.delete(ws.data.acked.values().next().value!);
    }
    const seconds = Math.max(0, Date.now() - committedAt) / 1000;
    m.commitToAck.record(seconds, { platform: ws.data.platform });
    latency.record(seconds);
  }

  async function handle(ws: Socket, raw: string | Buffer) {
    if (typeof raw !== 'string' || Buffer.byteLength(raw) > LIMITS.maxMessageBytes) return malformed(ws);
    let value: unknown;
    try {
      value = JSON.parse(raw);
    } catch {
      return malformed(ws);
    }
    const parsed = ClientMessage.safeParse(value);
    if (!parsed.success) return malformed(ws);
    const msg = parsed.data;
    if (msg.type === 'subscribe') return subscribe(ws, msg.topics);
    if (msg.type === 'unsubscribe') return unsubscribe(ws, msg.topics);
    return rendered(ws, msg.activityId, msg.version);
  }

  const websocket: WebSocketHandler<SocketData> = {
    maxPayloadLength: LIMITS.maxFrameBytes,
    backpressureLimit: LIMITS.backpressureBytes,
    // A client too slow to keep up is closed, reconnects and refetches, rather than missing events.
    closeOnBackpressureLimit: true,
    idleTimeout: 120,
    open(ws) {
      sockets.add(ws);
    },
    message(ws, message) {
      ws.data.queue = ws.data.queue
        .then(() => handle(ws, message))
        .catch((err: unknown) => {
          logger.error({ err }, 'realtime message handling failed');
        });
    },
    close(ws) {
      ws.data.closed = true;
      sockets.delete(ws);
      for (const topic of [...ws.data.topics]) track(ws, topic, -1);
    },
  };

  const listener = createListener(deps.listenUrl, logger, {
    spots(p: SpotsPayload, receivedAt) {
      const committedAt = Date.parse(p.committedAt);
      m.notifyLag.record(Math.max(0, receivedAt - committedAt) / 1000);
      acks.record(p.activityId, p.version, committedAt);
      const msg: ServerMessageType = { type: 'spots', ...p };
      publish(activityTopic(p.activityId), msg, 'spots');
      publish(hostTopic(p.activityId), msg, 'spots');
      publish(hostTopic(p.activityId), { type: 'attendance', activityId: p.activityId }, 'attendance');
    },
    plan(planId) {
      publish(planTopic(planId), { type: 'plan', planId }, 'plan');
    },
    attendance(activityId) {
      publish(hostTopic(activityId), { type: 'attendance', activityId }, 'attendance');
    },
    reconnected() {
      m.listenerReconnects.add(1);
      for (const topic of topicCounts.keys()) publish(topic, { type: 'resync' }, 'resync');
    },
  });

  const routes = new OpenAPIHono<AppEnv>();
  routes.openapi(wsRoute, (c) => {
    const { platform, resume } = c.req.valid('query');
    const data: SocketData = {
      userId: c.var.user?.id ?? null,
      platform,
      topics: new Set(),
      acked: new Set(),
      malformed: 0,
      closed: false,
      queue: Promise.resolve(),
    };
    if (!server?.upgrade(c.req.raw, { data })) {
      throw new ApiError('validation_failed', 'Expected a WebSocket upgrade.');
    }
    if (resume) m.reconnects.add(1, { platform });
    // Bun has taken over the connection; this response is never sent.
    return new Response(null) as never;
  });

  return {
    routes,
    websocket,
    /** Call right after Bun.serve, before traffic: upgrades and publishing need the server. */
    attach(s: Server<SocketData>) {
      server = s;
      clearInterval(pinger);
      pinger = setInterval(() => {
        for (const ws of sockets) ws.ping();
      }, deps.pingIntervalMs ?? PING_INTERVAL_MS);
    },
    latency,
    start: () => listener.start(),
    listening: () => listener.listening(),
    /** On shutdown: close every socket with 1012 (service restart) so clients reconnect at once. */
    closeSockets() {
      clearInterval(pinger);
      for (const ws of sockets) ws.close(1012, 'service restart');
    },
    stop: () => listener.stop(),
  };
}

export type Realtime = ReturnType<typeof createRealtime>;
