import { z } from 'zod';

const Config = z
  .object({
    NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
    PORT: z.coerce.number().int().min(1).max(65535).default(3001),
    /** Runtime connection as velio_api. */
    DATABASE_URL: z.url(),
    /** Direct (unpooled) connection for LISTEN, used from S3. */
    DATABASE_LISTEN_URL: z.url(),
    /** Server secret keying the contact hash. */
    CONTACT_PEPPER: z.string().min(32),
    /** Shared secret CloudFront adds as X-Origin-Verify. Required and enforced in production only. */
    ORIGIN_VERIFY_SECRET: z.string().min(32).optional(),
    /** OTLP/HTTP base URL of the collector. Unset disables export. */
    OTEL_EXPORTER_OTLP_ENDPOINT: z.url().optional(),
    LOG_LEVEL: z.enum(['fatal', 'error', 'warn', 'info', 'debug', 'trace', 'silent']).default('info'),
    SESSION_IDLE_DAYS: z.coerce.number().int().positive().default(30),
    SESSION_ABSOLUTE_DAYS: z.coerce.number().int().positive().default(90),
    /** Origin of invite links (`<origin>/i/<code>`): the cloudfront.net hostname in production. */
    PUBLIC_BASE_URL: z.url().optional(),
    /** PRD R7: claim attempts allowed on one public link per minute (S4 §12, Q2). */
    LINK_CLAIMS_PER_MINUTE: z.coerce.number().int().positive().default(60),
    /** PRD R7: opens in the trailing hour before a link with < 2% claims auto-pauses (S4 §12, Q2). */
    AUTO_PAUSE_MIN_OPENS: z.coerce.number().int().positive().default(200),
  })
  .refine((c) => c.NODE_ENV !== 'production' || c.ORIGIN_VERIFY_SECRET !== undefined, {
    path: ['ORIGIN_VERIFY_SECRET'],
    message: 'required when NODE_ENV=production',
  })
  .refine((c) => c.NODE_ENV !== 'production' || c.PUBLIC_BASE_URL !== undefined, {
    path: ['PUBLIC_BASE_URL'],
    message: 'required when NODE_ENV=production',
  })
  .transform((c) => ({
    ...c,
    PUBLIC_BASE_URL: (c.PUBLIC_BASE_URL ?? 'http://localhost:3000').replace(/\/+$/, ''),
  }));

export type Config = z.infer<typeof Config>;

export class ConfigError extends Error {}

/** Treats empty strings as unset, so `FOO=` in a .env file means "not provided". */
export function loadConfig(env: Record<string, string | undefined> = process.env): Config {
  const cleaned = Object.fromEntries(Object.entries(env).filter(([, v]) => v !== ''));
  const result = Config.safeParse(cleaned);
  if (result.success) return result.data;
  const problems = result.error.issues.map((i) => `  ${i.path.join('.')}: ${i.message}`);
  throw new ConfigError(`Invalid configuration:\n${problems.join('\n')}`);
}
