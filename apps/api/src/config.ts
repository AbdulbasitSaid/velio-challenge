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
  })
  .refine((c) => c.NODE_ENV !== 'production' || c.ORIGIN_VERIFY_SECRET !== undefined, {
    path: ['ORIGIN_VERIFY_SECRET'],
    message: 'required when NODE_ENV=production',
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
