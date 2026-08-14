#!/usr/bin/env tsx
/**
 * Example: Start a span and log with correlation
 * - Emits a short trace to OTLP HTTP (5321)
 * - Writes JSON logs enriched with trace_id/span_id to logs/app.log
 */

import { NodeTracerProvider } from '@opentelemetry/sdk-trace-node'
import { resourceFromAttributes } from '@opentelemetry/resources'
import { SemanticResourceAttributes as R } from '@opentelemetry/semantic-conventions'
import { OTLPTraceExporter } from '@opentelemetry/exporter-trace-otlp-http'
import { BatchSpanProcessor } from '@opentelemetry/sdk-trace-base'
import { context, trace } from '@opentelemetry/api'
import loggerInstance, { getLogger } from '../lib/logger'
import { ensureCorrelationId, getCorrelationHeaders, withCorrelationId } from '../lib/correlation'
import fs from 'fs'
import path from 'path'

const endpoint = process.env.OTEL_EXPORTER_OTLP_ENDPOINT ?? 'http://127.0.0.1:5321/v1/traces'
const serviceName = process.env.OTEL_SERVICE_NAME ?? 'bosscat-example'
const token = process.env.BOSSCAT_TOKEN ?? `T-${Date.now()}`
const correlationId = ensureCorrelationId()

// Ensure file logging path for collector ingestion
if (!process.env.BOSSCAT_LOG_PATH) {
  process.env.BOSSCAT_LOG_PATH = 'logs/app.log'
}
// Truncate log file so first line reflects correlation-enabled entry (acceptance requirement)
try {
  const logPath = process.env.BOSSCAT_LOG_PATH as string
  const dir = path.dirname(logPath)
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true })
  fs.writeFileSync(logPath, '')
} catch {}

const provider = new NodeTracerProvider({
  resource: resourceFromAttributes({
    [R.SERVICE_NAME]: serviceName,
    [R.SERVICE_NAMESPACE]: 'resonai',
    [R.DEPLOYMENT_ENVIRONMENT]: process.env.DEPLOYMENT_ENVIRONMENT ?? 'production',
  }),
  spanProcessors: [
    new BatchSpanProcessor(
      new OTLPTraceExporter({ url: endpoint, timeoutMillis: 5000, headers: { ...getCorrelationHeaders(correlationId) } }),
      { exportTimeoutMillis: 5000 }
    ),
  ],
})

provider.register()
const tracer = provider.getTracer('bosscat-example', '1.0.0')
const logger = () => getLogger()

async function main() {
  // Active correlation + span context
  await withCorrelationId(correlationId, async () => {
    await context.with(
      trace.setSpan(
        context.active(),
        tracer.startSpan('example.root', { attributes: { 'bosscat.token': token, correlation_id: correlationId } })
      ),
      async () => {
        logger().info({ event: 'log_start', 'bosscat.token': token, correlation_id: correlationId }, 'BossCat example — logging started')
        const child = tracer.startSpan('example.child', { attributes: { step: 1 } })
        await new Promise((r) => setTimeout(r, 25))
        child.end()
        logger().warn({ event: 'log_mid', step: 1, 'bosscat.token': token, correlation_id: correlationId }, 'BossCat example — mid log')
        logger().error({ event: 'log_end', ok: true, 'bosscat.token': token, correlation_id: correlationId }, 'BossCat example — logging complete')
        trace.getSpan(context.active())?.end()
      }
    )
  })

  await new Promise((r) => setTimeout(r, 250))
  await provider.shutdown()
  console.log('✅ Example complete')
  console.log(`   Logs: ${process.env.BOSSCAT_LOG_PATH}`)
  console.log(`   Token: ${token}`)
  console.log(`   Correlation ID: ${correlationId}`)
}

main().catch(async (e) => {
  console.error('❌ Example failed', e)
  await provider.shutdown()
  process.exit(1)
})
