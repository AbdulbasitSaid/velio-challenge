import { context, metrics, propagation, trace } from '@opentelemetry/api';
import { AsyncLocalStorageContextManager } from '@opentelemetry/context-async-hooks';
import { W3CTraceContextPropagator } from '@opentelemetry/core';
import { OTLPMetricExporter } from '@opentelemetry/exporter-metrics-otlp-http';
import { OTLPTraceExporter } from '@opentelemetry/exporter-trace-otlp-http';
import { resourceFromAttributes } from '@opentelemetry/resources';
import { MeterProvider, PeriodicExportingMetricReader } from '@opentelemetry/sdk-metrics';
import { BatchSpanProcessor, TracerProvider } from '@opentelemetry/sdk-trace';
import { ATTR_SERVICE_NAME } from '@opentelemetry/semantic-conventions';

export interface Telemetry {
  shutdown(): Promise<void>;
}

/**
 * Registers global trace and metric providers that export over OTLP/HTTP to `endpoint`.
 * With no endpoint, the OTel API stays a no-op: no spans or metrics are recorded or sent.
 * No auto-instrumentation: it relies on Node module hooks that are unreliable on Bun (MVP plan §4.12).
 */
export function startTelemetry(
  endpoint: string | undefined,
  serviceName = 'velio-api',
  /** `deployment.environment`, so Grafana tells local from production (S8 F3). */
  environment = 'development',
): Telemetry {
  // The context manager is needed for trace_id in logs even when nothing is exported.
  context.setGlobalContextManager(new AsyncLocalStorageContextManager().enable());
  propagation.setGlobalPropagator(new W3CTraceContextPropagator());
  if (!endpoint) return { shutdown: async () => {} };

  const base = endpoint.replace(/\/$/, '');
  const resource = resourceFromAttributes({
    [ATTR_SERVICE_NAME]: serviceName,
    'deployment.environment': environment,
  });

  const tracerProvider = new TracerProvider({
    resource,
    spanProcessors: [
      new BatchSpanProcessor({ exporter: new OTLPTraceExporter({ url: `${base}/v1/traces` }) }),
    ],
  });
  trace.setGlobalTracerProvider(tracerProvider);

  const meterProvider = new MeterProvider({
    resource,
    readers: [
      new PeriodicExportingMetricReader({
        exporter: new OTLPMetricExporter({ url: `${base}/v1/metrics` }),
        exportIntervalMillis: 10_000,
      }),
    ],
  });
  metrics.setGlobalMeterProvider(meterProvider);

  return {
    async shutdown() {
      await Promise.allSettled([tracerProvider.shutdown(), meterProvider.shutdown()]);
    },
  };
}
