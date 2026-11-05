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
    /** Static Maps (S6 §4.6): server key and URL-signing secret. Either unset → `staticMapUrl` is null (PRD A7). */
    GOOGLE_MAPS_SERVER_KEY: z.string().min(1).optional(),
    GOOGLE_MAPS_SIGNING_SECRET: z.string().min(1).optional(),
    /** Activity photos (S5 §4.9). Required in production; locally the MinIO bucket from Compose. */
    PHOTOS_BUCKET: z.string().min(1).optional(),
    S3_REGION: z.string().min(1).default('eu-west-2'),
    /** MinIO locally (path-style). Unset in production: the AWS endpoint and the instance role. */
    S3_ENDPOINT: z.url().optional(),
    S3_ACCESS_KEY_ID: z.string().min(1).optional(),
    S3_SECRET_ACCESS_KEY: z.string().min(1).optional(),
    /** PRD Holdout design (S8 FR-001): share of users, 0–100, who never get invite tools. */
    HOLDOUT_PERCENT: z.coerce.number().int().min(0).max(100).default(10),
    /** Bearer token for `/api/admin/*` (S8 FR-010). Unset → the admin routes answer 404. */
    ADMIN_TOKEN: z.string().min(32).optional(),
  })
  .refine((c) => c.NODE_ENV !== 'production' || c.ORIGIN_VERIFY_SECRET !== undefined, {
    path: ['ORIGIN_VERIFY_SECRET'],
    message: 'required when NODE_ENV=production',
  })
  .refine((c) => c.NODE_ENV !== 'production' || c.PUBLIC_BASE_URL !== undefined, {
    path: ['PUBLIC_BASE_URL'],
    message: 'required when NODE_ENV=production',
  })
  .refine((c) => c.NODE_ENV !== 'production' || c.PHOTOS_BUCKET !== undefined, {
    path: ['PHOTOS_BUCKET'],
    message: 'required when NODE_ENV=production',
  })
  .transform((c) => {
    // Outside production, default to the MinIO service in infra/docker-compose.yml.
    const local = c.NODE_ENV !== 'production';
    return {
      ...c,
      PUBLIC_BASE_URL: (c.PUBLIC_BASE_URL ?? 'http://localhost:3000').replace(/\/+$/, ''),
      PHOTOS_BUCKET: c.PHOTOS_BUCKET ?? 'velio-photos',
      S3_ENDPOINT: c.S3_ENDPOINT ?? (local ? 'http://localhost:9000' : undefined),
      S3_ACCESS_KEY_ID: c.S3_ACCESS_KEY_ID ?? (local ? 'velio-local' : undefined),
      S3_SECRET_ACCESS_KEY: c.S3_SECRET_ACCESS_KEY ?? (local ? 'velio-local-only' : undefined),
    };
  });

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
