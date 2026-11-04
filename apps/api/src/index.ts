import { ConfigError, loadConfig, type Config } from './config';
import { createDb } from './db/client';
import { createRealtime } from './modules/realtime/gateway';
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
const realtime = createRealtime({ db, logger, listenUrl: config.DATABASE_LISTEN_URL });
const app = createApp({ config, db, logger, clock: () => new Date(), realtime });

const server = Bun.serve({ port: config.PORT, fetch: app.fetch, websocket: realtime.websocket });
realtime.attach(server);
// Readiness reports 503 until the first LISTEN succeeds; the listener retries in the background.
void realtime.start();
logger.info({ port: server.port }, 'listening');

async function shutdown(signal: string) {
  logger.info({ signal }, 'shutting down');
  realtime.closeSockets();
  await server.stop();
  await realtime.stop();
  await db.destroy();
  await telemetry.shutdown();
  process.exit(0);
}
process.on('SIGTERM', () => void shutdown('SIGTERM'));
process.on('SIGINT', () => void shutdown('SIGINT'));
