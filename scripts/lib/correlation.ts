import { context, createContextKey } from '@opentelemetry/api'

export const X_CORRELATION_ID_HEADER = 'x-correlation-id'
// Use createContextKey from @opentelemetry/api (not context.createKey)
const CORR_KEY = createContextKey('bosscat.correlation_id')

function generateId(): string {
  if (typeof crypto !== 'undefined' && 'randomUUID' in crypto) {
    // @ts-ignore - Node 19+ provides global crypto.randomUUID
    return crypto.randomUUID()
  }
  // Fallback simple UUIDv4-ish
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c) => {
    const r = (Math.random() * 16) | 0
    const v = c === 'x' ? r : (r & 0x3) | 0x8
    return v.toString(16)
  })
}

export function getCorrelationId(ctx = context.active()): string | undefined {
  return ctx.getValue(CORR_KEY) as string | undefined
}

export function withCorrelationId<T>(correlationId: string, fn: () => T): T {
  const newContext = context.active().setValue(CORR_KEY, correlationId)
  return context.with(newContext, fn)
}

export function ensureCorrelationId(): string {
  const existing = getCorrelationId()
  if (existing) return existing
  const id = generateId()
  // Note: This doesn't set it in active context, just returns a new ID
  // Call sites should use withCorrelationId to scope it precisely
  return id
}

export function newCorrelationId(): string {
  return generateId()
}

export function getCorrelationHeaders(id?: string): Record<string, string> {
  const cid = id ?? getCorrelationId() ?? generateId()
  return { [X_CORRELATION_ID_HEADER]: cid }
}
