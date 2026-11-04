// Next.js server telemetry (S5 §4.11): Next's built-in spans exported over OTLP/HTTP to the collector,
// on the same SDK and versions as the API. Unset OTEL_EXPORTER_OTLP_ENDPOINT keeps the OTel API a no-op.
export async function register() {
  if (process.env.NEXT_RUNTIME !== 'nodejs' || !process.env.OTEL_EXPORTER_OTLP_ENDPOINT) return;
  const { startTelemetry } = await import('./lib/telemetry/otel');
  startTelemetry(process.env.OTEL_EXPORTER_OTLP_ENDPOINT);
}
