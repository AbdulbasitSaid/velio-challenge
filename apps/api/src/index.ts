import { websocket } from 'hono/bun';
import { ConfigError, loadConfig, type Config } from './config';
import { createDb } from './db/client';
import { createLogger } from './telemetry/logger';
import { startTelemetry } from './telemetry/otel';
import { createApp } from './app';

let config: Config;
try {
  config = loadConfig();
} catch (err) {
  if (err instanceof ConfigError) {
    console.error(err.message);
    process.exit(1);
  }
  throw err;
}

// Telemetry first: metric instruments bind to the provider that is global when they are created.
const telemetry = startTelemetry(config.OTEL_EXPORTER_OTLP_ENDPOINT);
const logger = createLogger(config.LOG_LEVEL);
const db = createDb(config.DATABASE_URL);
const app = createApp({ config, db, logger, clock: () => new Date() });

// The WebSocket handler is wired now so S3 only adds routes.
const server = Bun.serve({ port: config.PORT, fetch: app.fetch, websocket });
logger.info({ port: server.port }, 'listening');

async function shutdown(signal: string) {
  logger.info({ signal }, 'shutting down');
  await server.stop();
  await db.destroy();
  await telemetry.shutdown();
  process.exit(0);
}
process.on('SIGTERM', () => void shutdown('SIGTERM'));
process.on('SIGINT', () => void shutdown('SIGINT'));
