import { createRoute, OpenAPIHono } from '@hono/zod-openapi';
import { Health } from '@velio/contracts';
import { sql } from 'kysely';
import type { AppDeps, AppEnv } from '../../app';

const READY_TIMEOUT_MS = 2_000;

const healthzRoute = createRoute({
  method: 'get',
  path: '/healthz',
  summary: 'Liveness. Never touches the database.',
  responses: {
    200: { description: 'The process is up', content: { 'application/json': { schema: Health } } },
  },
});

const readyzRoute = createRoute({
  method: 'get',
  path: '/readyz',
  summary: 'Readiness. 200 only when a database query succeeds and the realtime listener is listening.',
  responses: {
    200: { description: 'Ready', content: { 'application/json': { schema: Health } } },
    503: {
      description: 'The database is unreachable, or live updates are down',
      content: { 'application/json': { schema: Health } },
    },
  },
});

export function healthRoutes(deps: AppDeps) {
  const app = new OpenAPIHono<AppEnv>();

  app.openapi(healthzRoute, (c) => c.json({ status: 'ok' as const }, 200));

  app.openapi(readyzRoute, async (c) => {
    let timer: ReturnType<typeof setTimeout> | undefined;
    try {
      await Promise.race([
        sql`select 1`.execute(deps.db),
        new Promise((_, reject) => {
          timer = setTimeout(() => reject(new Error('readyz timeout')), READY_TIMEOUT_MS);
        }),
      ]);
      // Without the listener the API still books correctly, but nothing is live (S3 FR-017).
      if (deps.realtime && !deps.realtime.listening()) {
        c.var.logger.warn('readiness check failed: realtime listener not listening');
        return c.json({ status: 'unavailable' as const }, 503);
      }
      return c.json({ status: 'ok' as const }, 200);
    } catch (err) {
      c.var.logger.warn({ err }, 'readiness check failed');
      return c.json({ status: 'unavailable' as const }, 503);
    } finally {
      clearTimeout(timer);
    }
  });

  return app;
}
