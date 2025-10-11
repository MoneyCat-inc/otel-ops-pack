import pino, { Logger, LoggerOptions } from 'pino'
import { context, trace } from '@opentelemetry/api'
import { getCorrelationId } from './correlation'

/**
 * BossCat Structured Logger (Phase 2 / Week 1)
 * - JSON logs enriched with OpenTelemetry context (trace_id, span_id)
 * - Writes to stdout by default; optional file destination via BOSSCAT_LOG_PATH
 * - Safe in environments without an active span
 */

export type BossCatLogger = Logger

  function buildMixin() {
    return () => {
      const span = trace.getSpan(context.active())
      const ctx = span?.spanContext()
    const corr = getCorrelationId()
    const base: Record<string, any> = {}
    if (ctx) {
      base.trace_id = ctx.traceId
      base.span_id = ctx.spanId
    }
    if (corr) base.correlation_id = corr
    return base
    }
  }

export function createLogger(options: LoggerOptions = {}): BossCatLogger {
  const mixin = buildMixin()
  const base: Record<string, any> = {
    service: process.env.OTEL_SERVICE_NAME || 'resonai-backend',
    env: process.env.DEPLOYMENT_ENVIRONMENT || 'production',
    'bosscat.lane': process.env.BOSSCAT_LANE || 'gate',
  }

  const destinationPath = process.env.BOSSCAT_LOG_PATH
  const pinoOpts: LoggerOptions = {
    level: process.env.LOG_LEVEL || 'info',
    base,
    mixin,
    timestamp: pino.stdTimeFunctions.isoTime,
    ...options,
  }

  if (destinationPath) {
    const dest = pino.destination({ dest: destinationPath, sync: true, mkdir: true })
    return pino(pinoOpts, dest)
  }
  return pino(pinoOpts)
}

// Default singleton logger
let _logger: BossCatLogger | undefined
export function getLogger(): BossCatLogger {
  if (!_logger) _logger = createLogger()
  return _logger
}

export default getLogger()
