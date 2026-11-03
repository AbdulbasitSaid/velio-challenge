import { afterAll, beforeAll, describe, expect, test } from 'bun:test';
import { context, metrics, trace } from '@opentelemetry/api';
import { AsyncLocalStorageContextManager } from '@opentelemetry/context-async-hooks';
import {
  AggregationTemporality,
  MeterProvider,
  MetricReader,
  type ResourceMetrics,
} from '@opentelemetry/sdk-metrics';
import { InMemorySpanExporter, SimpleSpanProcessor, TracerProvider } from '@opentelemetry/sdk-trace';
import { Writable } from 'node:stream';
import { createApp } from '../../src/app';
import { loadConfig } from '../../src/config';
import { createLogger, redactPath } from '../../src/telemetry/logger';
import { TEST_PEPPER, json } from '../helpers/app';
import { createTestDatabase, type TestDatabase } from '../helpers/db';

class TestReader extends MetricReader {
  protected async onForceFlush() {}
  protected async onShutdown() {}
}

const spans = new InMemorySpanExporter();
const reader = new TestReader({ aggregationTemporalitySelector: () => AggregationTemporality.CUMULATIVE });
const lines: Record<string, unknown>[] = [];

/** Attributes of every data point of one metric. */
function pointAttributes(rm: ResourceMetrics, name: string) {
  return rm.scopeMetrics
    .flatMap((sm) => sm.metrics)
    .filter((m) => m.descriptor.name === name)
    .flatMap((m) => (m.dataPoints as { attributes: Record<string, unknown> }[]).map((p) => p.attributes));
}
const rawLog: string[] = [];

let t: TestDatabase;
let app: ReturnType<typeof createApp>;

beforeAll(async () => {
  // The OTel API globals can be set once per process; this file owns them.
  context.setGlobalContextManager(new AsyncLocalStorageContextManager().enable());
  trace.setGlobalTracerProvider(
    new TracerProvider({ spanProcessors: [new SimpleSpanProcessor({ exporter: spans })] }),
  );
  metrics.setGlobalMeterProvider(new MeterProvider({ readers: [reader] }));

  t = await createTestDatabase();
  const sink = new Writable({
    write(chunk, _enc, done) {
      const text = chunk.toString();
      rawLog.push(text);
      for (const line of text.split('\n').filter(Boolean)) lines.push(JSON.parse(line));
      done();
    },
  });
  const config = loadConfig({
    NODE_ENV: 'test',
    DATABASE_URL: t.url,
    DATABASE_LISTEN_URL: t.url,
    CONTACT_PEPPER: TEST_PEPPER,
  });
  // createDb is called after the meter provider is global, so db_pool_in_use is recorded here too.
  const { createDb } = await import('../../src/db/client');
  const db = createDb(t.url, { max: 2 });
  app = createApp({ config, db, logger: createLogger('info', sink), clock: () => new Date() });
});

afterAll(async () => {
  await t.drop();
});

// V-OBS-1 (NFR-002, NFR-003, AC-004), in process
describe('request telemetry', () => {
  test('a request yields a server span, DB child spans, a metric point and a log line sharing trace_id', async () => {
    spans.reset();
    lines.length = 0;
    const res = await app.request('/api/me', { headers: { authorization: `Bearer ${'x'.repeat(43)}` } });
    expect(res.status).toBe(401);

    const finished = spans.getFinishedSpans();
    const server = finished.find((s) => s.name === 'GET /api/me');
    expect(server).toBeDefined();
    const traceId = server!.spanContext().traceId;

    // The session lookup ran as a child DB span, named by operation only.
    const dbSpans = finished.filter((s) => s.name.startsWith('db.'));
    expect(dbSpans.map((s) => s.name)).toContain('db.select');
    for (const s of dbSpans) {
      expect(s.spanContext().traceId).toBe(traceId);
      expect(Object.keys(s.attributes).sort()).toEqual(['db.operation.name', 'db.system.name']);
    }

    const log = lines.find((l) => l.msg === 'request' && l.route === '/api/me');
    expect(log).toBeDefined();
    expect(log!.trace_id).toBe(traceId);
    expect(log!.request_id).toBe(res.headers.get('x-request-id')!);

    const { resourceMetrics } = await reader.collect();
    const point = pointAttributes(resourceMetrics, 'http_server_duration_seconds').find(
      (a) => a.route === '/api/me',
    );
    expect(point).toEqual({ route: '/api/me', method: 'GET', status_class: '4xx' });

    const names = resourceMetrics.scopeMetrics.flatMap((sm) => sm.metrics.map((m) => m.descriptor.name));
    expect(names).toContain('db_pool_in_use');
  });

  test('unmatched paths share one route label', async () => {
    await app.request('/api/does-not-exist/123');
    const { resourceMetrics } = await reader.collect();
    const routes = pointAttributes(resourceMetrics, 'http_server_duration_seconds').map((a) => a.route);
    expect(routes).toContain('unmatched');
    expect(routes.some((r) => String(r).includes('123'))).toBe(false);
  });
});

// V-OBS-2 (SEC-003), in process
describe('redaction', () => {
  test('contact, token and cookie values never reach spans or logs', async () => {
    spans.reset();
    rawLog.length = 0;
    const contact = 'redaction-check@example.com';
    const res = await app.request(
      '/api/sessions?contact=redaction-check@example.com',
      json({ displayName: 'Redaction Check', contact }, { 'x-client': 'mobile' }),
    );
    const { token } = (await res.json()) as { token: string };
    await app.request('/api/me', {
      headers: { authorization: `Bearer ${token}`, cookie: `velio_session=${token}` },
    });

    const spanText = JSON.stringify(
      spans.getFinishedSpans().map((s) => ({ name: s.name, attributes: s.attributes, events: s.events })),
    );
    const logText = rawLog.join('');
    for (const secret of [contact, token, encodeURIComponent(contact)]) {
      expect(spanText).not.toContain(secret);
      expect(logText).not.toContain(secret);
    }
  });

  test('invite codes in paths are redacted in spans and logs', async () => {
    spans.reset();
    rawLog.length = 0;
    await app.request('/api/invites/K7M2QX');
    await app.request('/api/i/K7M2QX?ref=abc');
    const spanText = JSON.stringify(spans.getFinishedSpans().map((s) => s.attributes));
    expect(spanText).not.toContain('K7M2QX');
    expect(rawLog.join('')).not.toContain('K7M2QX');
    expect(spanText).toContain('/api/invites/:code');
  });

  test('redactPath', () => {
    expect(redactPath('/api/invites/ABC234/claims')).toBe('/api/invites/:code/claims');
    expect(redactPath('/i/ABC234')).toBe('/i/:code');
    expect(redactPath('/api/me?token=x')).toBe('/api/me');
  });

  test('the logger censors secret keys at any of the first three levels', () => {
    const out: string[] = [];
    const sink = new Writable({
      write(chunk, _enc, done) {
        out.push(chunk.toString());
        done();
      },
    });
    const logger = createLogger('info', sink);
    logger.info(
      {
        contact: 'a@b.co',
        token: 't0k',
        req: { authorization: 'Bearer z', cookie: 'c', body: { note: 'n', code: 'K7M2QX' } },
      },
      'x',
    );
    const text = out.join('');
    for (const secret of ['a@b.co', 't0k', 'Bearer z', '"c"', '"n"', 'K7M2QX'])
      expect(text).not.toContain(secret);
    expect(text).toContain('[REDACTED]');
  });
});
