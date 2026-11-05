import { httpInstrumentationMiddleware } from '@hono/otel';
import { createNoopMeter, metrics, type MeterProvider } from '@opentelemetry/api';
import type { MiddlewareHandler } from 'hono';
import { createMiddleware } from 'hono/factory';
import { routePath } from 'hono/route';
import type { AppEnv } from '../app';
import { LATENCY_BUCKETS_S } from './buckets';
import { redactPath } from './logger';

/** Hono reports unmatched requests under the catch-all pattern; label them as one series. */
function routeTemplate(c: Parameters<MiddlewareHandler>[0]): string {
  const route = routePath(c);
  return route.endsWith('*') ? 'unmatched' : route;
}

// @hono/otel would record its own http.server.request.duration with full status codes; we record
// http_server_duration_seconds below instead, so its meter is a no-op.
const noopMeterProvider: MeterProvider = { getMeter: () => createNoopMeter() };

/**
 * One server span per request (via @hono/otel). `url.full` is reduced to the redacted path so query
 * strings and invite codes never reach a span (SEC-003).
 */
export function tracingMiddleware(): MiddlewareHandler {
  return httpInstrumentationMiddleware({
    serviceName: 'velio-api',
    meterProvider: noopMeterProvider,
    spanNameFactory: (c) => `${c.req.method} ${routeTemplate(c)}`,
    getRoute: routeTemplate,
    getUrlFull: (c) => redactPath(new URL(c.req.url).pathname),
  });
}

/**
 * Records `http_server_duration_seconds` labelled by route template, method and status class only
 * (NFR-002), and writes one access log line per request. Call after telemetry has started: the
 * OTel metrics API binds to whichever provider is global when the instrument is created.
 */
export function accessMiddleware() {
  const histogram = metrics.getMeter('velio-http').createHistogram('http_server_duration_seconds', {
    description: 'HTTP server request duration',
    unit: 's',
    advice: { explicitBucketBoundaries: LATENCY_BUCKETS_S },
  });
  return createMiddleware<AppEnv>(async (c, next) => {
    const start = performance.now();
    try {
      await next();
    } finally {
      const seconds = (performance.now() - start) / 1000;
      const route = routeTemplate(c);
      const status = c.res.status;
      histogram.record(seconds, {
        route,
        method: c.req.method,
        status_class: `${Math.floor(status / 100)}xx`,
      });
      c.var.logger.info(
        {
          method: c.req.method,
          route,
          path: redactPath(new URL(c.req.url).pathname),
          status,
          duration_ms: Math.round(seconds * 1000),
        },
        'request',
      );
    }
  });
}
