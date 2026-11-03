import { trace } from '@opentelemetry/api';
import pino, { type DestinationStream, type Logger } from 'pino';

export type { Logger };

/** Keys whose values never reach a log line (SEC-003). */
const SECRET_KEYS = ['contact', 'token', 'authorization', 'cookie', 'note', 'code'];

/** Invite codes in paths: /i/:code and /invites/:code. */
const CODE_IN_PATH = /\/(i|invites)\/[^/?#]+/g;

/** Replaces invite codes in a URL path with `:code` and drops the query string. */
export function redactPath(path: string): string {
  return path.split(/[?#]/, 1)[0]!.replace(CODE_IN_PATH, '/$1/:code');
}

export function createLogger(level: string, destination?: DestinationStream): Logger {
  return pino(
    {
      level,
      base: { service: 'velio-api' },
      messageKey: 'msg',
      timestamp: pino.stdTimeFunctions.isoTime,
      formatters: { level: (label) => ({ level: label }) },
      redact: {
        // pino matches fixed depths; three levels covers request, error and nested payload objects.
        paths: SECRET_KEYS.flatMap((k) => [k, `*.${k}`, `*.*.${k}`]),
        censor: '[REDACTED]',
      },
      // Correlate every line with the active trace.
      mixin() {
        const ctx = trace.getActiveSpan()?.spanContext();
        return ctx ? { trace_id: ctx.traceId, span_id: ctx.spanId } : {};
      },
    },
    destination,
  );
}
