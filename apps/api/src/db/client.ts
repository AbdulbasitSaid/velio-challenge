import { context, metrics, SpanKind, SpanStatusCode, trace, type MeterProvider } from '@opentelemetry/api';
import { Kysely, type LogEvent } from 'kysely';
import { PostgresJSDialect } from 'kysely-postgres-js';
import postgres from 'postgres';
import type { DB } from './types';

export type Db = Kysely<DB>;

/** Connections currently reserved by Kysely, across every pool in this process. */
let poolInUse = 0;
let gaugeProvider: MeterProvider | undefined;

/** Registers once per global meter provider, so it follows telemetry started after a first createDb. */
function registerPoolGauge() {
  const provider = metrics.getMeterProvider();
  if (gaugeProvider === provider) return;
  gaugeProvider = provider;
  metrics
    .getMeter('velio-db')
    .createObservableGauge('db_pool_in_use', { description: 'Database connections in use' })
    .addCallback((result) => result.observe(poolInUse));
}

/** "SelectQueryNode" → "select". Never the SQL text or its parameters (SEC-003). */
function operationName(event: LogEvent): string {
  const kind = event.query.query.kind;
  return kind.replace(/QueryNode$|Node$/, '').toLowerCase();
}

/**
 * Kysely calls `log` after each query completes, in the caller's async context, so the span is a
 * child of the request span. Its start time is back-dated by the measured duration.
 */
function traceQuery(event: LogEvent) {
  const op = operationName(event);
  const end = performance.timeOrigin + performance.now();
  const span = trace.getTracer('velio-db').startSpan(
    `db.${op}`,
    {
      kind: SpanKind.CLIENT,
      startTime: end - event.queryDurationMillis,
      attributes: { 'db.system.name': 'postgresql', 'db.operation.name': op },
    },
    context.active(),
  );
  if (event.level === 'error') span.setStatus({ code: SpanStatusCode.ERROR });
  span.end(end);
}

/** Seconds destroy() waits for in-flight queries before closing connections. */
const END_TIMEOUT_S = 2;

export interface DbOptions {
  /** Pool size. */
  max?: number;
}

export function createDb(url: string, options: DbOptions = {}): Db {
  registerPoolGauge();
  const sql = postgres(url, {
    max: options.max ?? 10,
    connect_timeout: 5,
    onnotice: () => {},
  });

  // The dialect requires a real postgres.js instance (a function), so this proxies it: reserve()
  // and release() are counted for db_pool_in_use, and end() gets a timeout.
  const counted = new Proxy(sql, {
    get(target, prop, receiver) {
      // Bound shutdown: without a timeout, end() can wait forever on a reservation left queued
      // after a failed connection attempt.
      if (prop === 'end') return (o?: { timeout?: number }) => target.end({ timeout: END_TIMEOUT_S, ...o });
      if (prop !== 'reserve') return Reflect.get(target, prop, receiver);
      return async () => {
        const reserved = await target.reserve();
        poolInUse++;
        let released = false;
        return new Proxy(reserved, {
          get(conn, connProp, connReceiver) {
            if (connProp !== 'release') return Reflect.get(conn, connProp, connReceiver);
            return () => {
              if (!released) {
                released = true;
                poolInUse--;
              }
              conn.release();
            };
          },
        });
      };
    },
  });

  return new Kysely<DB>({
    dialect: new PostgresJSDialect({ postgres: counted }),
    log: traceQuery,
  });
}
