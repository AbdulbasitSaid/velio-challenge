import { context, propagation, trace } from '@opentelemetry/api';
import { AsyncLocalStorageContextManager } from '@opentelemetry/context-async-hooks';
import { W3CTraceContextPropagator, type ExportResult } from '@opentelemetry/core';
import { OTLPTraceExporter } from '@opentelemetry/exporter-trace-otlp-http';
import { resourceFromAttributes } from '@opentelemetry/resources';
import {
  BatchSpanProcessor,
  TracerProvider,
  type ReadableSpan,
  type SpanExporter,
} from '@opentelemetry/sdk-trace';
import { ATTR_SERVICE_NAME } from '@opentelemetry/semantic-conventions';
import { redactAttributes, redactText } from './redact';

/** Wraps an exporter so spans leave the process with templated names and URLs only. */
export class RedactingExporter implements SpanExporter {
  constructor(private readonly inner: SpanExporter) {}

  export(spans: ReadableSpan[], done: (result: ExportResult) => void): void {
    const clean = spans.map(
      (span) =>
        Object.assign(Object.create(Object.getPrototypeOf(span) as object), span, {
          name: redactText(span.name),
          attributes: redactAttributes(span.attributes),
          events: span.events.map((e) => ({
            ...e,
            attributes: e.attributes && redactAttributes(e.attributes),
          })),
        }) as ReadableSpan,
    );
    this.inner.export(clean, done);
  }

  shutdown(): Promise<void> {
    return this.inner.shutdown();
  }

  forceFlush(): Promise<void> {
    return this.inner.forceFlush?.() ?? Promise.resolve();
  }
}

export function startTelemetry(endpoint: string, serviceName = 'velio-web'): void {
  context.setGlobalContextManager(new AsyncLocalStorageContextManager().enable());
  propagation.setGlobalPropagator(new W3CTraceContextPropagator());
  const exporter = new OTLPTraceExporter({ url: `${endpoint.replace(/\/$/, '')}/v1/traces` });
  trace.setGlobalTracerProvider(
    new TracerProvider({
      resource: resourceFromAttributes({ [ATTR_SERVICE_NAME]: serviceName }),
      spanProcessors: [new BatchSpanProcessor({ exporter: new RedactingExporter(exporter) })],
    }),
  );
}
