import { timingSafeEqual } from 'node:crypto';
import { OpenAPIHono, type Hook } from '@hono/zod-openapi';
import type { Env } from 'hono';
import { createMiddleware } from 'hono/factory';
import { HTTPException } from 'hono/http-exception';
import { requestId, type RequestIdVariables } from 'hono/request-id';
import type { Config } from './config';
import type { Db } from './db/client';
import { ApiError, envelope, fromPostgresError } from './errors';
import { healthRoutes } from './modules/health/routes';
import { identityRoutes } from './modules/identity/routes';
import type { User } from './modules/identity/sessions';
import { sessionMiddleware } from './modules/identity/middleware';
import { accessMiddleware, tracingMiddleware } from './telemetry/http';
import type { Logger } from './telemetry/logger';

export interface AppDeps {
  config: Config;
  db: Db;
  logger: Logger;
  /** Injected so tests can move time (session expiry). */
  clock: () => Date;
}

export interface AppEnv extends Env {
  Variables: RequestIdVariables & {
    logger: Logger;
    /** The signed-in user, or null. Set on every request by the session middleware. */
    user: User | null;
  };
}

/** Request validation failures become `validation_failed`, naming the fields but never their values. */
const validationHook: Hook<unknown, AppEnv, string, unknown> = (result) => {
  if (result.success) return;
  const fields = [...new Set(result.error.issues.map((i) => i.path.join('.') || '(body)'))];
  throw new ApiError('validation_failed', `Invalid request: ${fields.join(', ')}.`);
};

function fromHttpException(err: HTTPException): ApiError {
  if (err.status === 400) return new ApiError('validation_failed', 'Invalid request.');
  if (err.status === 401) return new ApiError('unauthenticated');
  if (err.status === 403) return new ApiError('forbidden');
  if (err.status === 404) return new ApiError('not_found');
  return new ApiError('internal');
}

/** In production only, requests must carry CloudFront's secret header (MVP plan §4.11). */
function originVerify(secret: string) {
  const expected = Buffer.from(secret);
  return createMiddleware<AppEnv>(async (c, next) => {
    // Liveness carries no data and is probed from inside the host.
    if (c.req.path !== '/api/healthz') {
      const got = Buffer.from(c.req.header('x-origin-verify') ?? '');
      if (got.length !== expected.length || !timingSafeEqual(got, expected)) throw new ApiError('forbidden');
    }
    await next();
  });
}

export function createApp(deps: AppDeps) {
  const app = new OpenAPIHono<AppEnv>({ defaultHook: validationHook }).basePath('/api');

  app.use(tracingMiddleware());
  app.use(requestId());
  app.use(async (c, next) => {
    c.set('logger', deps.logger.child({ request_id: c.var.requestId }));
    await next();
  });
  app.use(accessMiddleware());
  if (deps.config.NODE_ENV === 'production' && deps.config.ORIGIN_VERIFY_SECRET) {
    app.use(originVerify(deps.config.ORIGIN_VERIFY_SECRET));
  }
  app.use(sessionMiddleware(deps));

  app.route('/', healthRoutes(deps));
  app.route('/', identityRoutes(deps));

  app.openAPIRegistry.registerComponent('securitySchemes', 'cookieAuth', {
    type: 'apiKey',
    in: 'cookie',
    name: 'velio_session',
  });
  app.openAPIRegistry.registerComponent('securitySchemes', 'bearerAuth', {
    type: 'http',
    scheme: 'bearer',
  });

  app.notFound((c) => c.json(envelope(new ApiError('not_found'), c.var.requestId ?? ''), 404));

  // The single place errors become the envelope. Unknown errors never expose details.
  app.onError((err, c) => {
    const known =
      err instanceof ApiError
        ? err
        : (fromPostgresError(err) ?? (err instanceof HTTPException ? fromHttpException(err) : undefined));
    const apiError = known ?? new ApiError('internal');
    if (!known) (c.var.logger ?? deps.logger).error({ err }, 'unhandled error');
    return c.json(envelope(apiError, c.var.requestId ?? ''), apiError.status);
  });

  return app;
}

export type App = ReturnType<typeof createApp>;
