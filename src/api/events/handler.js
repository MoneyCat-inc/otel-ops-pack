const DEFAULT_MAX_EVENTS_PER_REQUEST = 25;
const DEFAULT_RING_SIZE = 256;
const DEFAULT_RATE_LIMIT = 6;
const DEFAULT_WINDOW_MS = 10_000;
const ALLOWED_PROP_KEYS = new Set([
  'flow',
  'step',
  'cohort',
  'durationMs',
  'latencyMs',
  'timeInTargetPct',
  'voicedTimePct',
  'smoothness',
  'expressiveness',
  'grantRatePct',
  'activationRatePct',
  'status',
  'variant',
  'attempt',
  'device',
  'appVersion'
]);
const BANNED_PROP_KEY_PATTERNS = [
  /audio/i,
  /blob/i,
  /pcm/i,
  /wav/i,
  /record/i,
  /base64/i,
  /user.?id/i,
  /email/i,
  /phone/i,
  /ssn/i,
  /pii/i,
  /transcript/i
];
const BANNED_STRING_VALUE_PATTERNS = [
  /data:audio/i,
  /audio\//i,
  /\b\d{3}-\d{2}-\d{4}\b/, // SSN pattern
  /@.+\./ // email-like
];

class SlidingWindowRateLimiter {
  constructor(maxRequests = DEFAULT_RATE_LIMIT, windowMs = DEFAULT_WINDOW_MS, nowProvider = () => Date.now()) {
    this.maxRequests = maxRequests;
    this.windowMs = windowMs;
    this.nowProvider = nowProvider;
    this.hits = new Map();
  }

  tryConsume(id) {
    const now = this.nowProvider();
    const timestamps = this.hits.get(id) ?? [];
    const fresh = timestamps.filter((ts) => now - ts < this.windowMs);
    if (fresh.length >= this.maxRequests) {
      this.hits.set(id, fresh);
      return false;
    }
    fresh.push(now);
    this.hits.set(id, fresh);
    return true;
  }

  snapshot() {
    const snapshot = {};
    for (const [id, values] of this.hits.entries()) {
      snapshot[id] = [...values];
    }
    return snapshot;
  }
}

function sanitizeString(value, maxLength = 120) {
  if (typeof value !== 'string') {
    return undefined;
  }
  const trimmed = value.trim();
  return trimmed.slice(0, maxLength);
}

function clampPercentage(value) {
  if (typeof value !== 'number' || Number.isNaN(value)) {
    return undefined;
  }
  const clamped = Math.max(0, Math.min(100, value));
  return Math.round(clamped * 100) / 100;
}

function clampDuration(value) {
  if (typeof value !== 'number' || Number.isNaN(value)) {
    return undefined;
  }
  const clamped = Math.max(0, Math.min(10 * 60 * 1000, value));
  return Math.round(clamped);
}

function sanitizeProps(rawProps = {}) {
  const sanitized = {};
  for (const [key, value] of Object.entries(rawProps)) {
    if (BANNED_PROP_KEY_PATTERNS.some((pattern) => pattern.test(key))) {
      throw new Error(`Disallowed analytics property: ${key}`);
    }

    if (typeof value === 'string' && BANNED_STRING_VALUE_PATTERNS.some((pattern) => pattern.test(value))) {
      throw new Error(`Disallowed analytics value detected for property ${key}`);
    }

    if (!ALLOWED_PROP_KEYS.has(key)) {
      continue;
    }

    if (key.endsWith('Pct')) {
      const pct = clampPercentage(Number(value));
      if (pct !== undefined) {
        sanitized[key] = pct;
      }
      continue;
    }

    if (key.endsWith('Ms')) {
      const duration = clampDuration(Number(value));
      if (duration !== undefined) {
        sanitized[key] = duration;
      }
      continue;
    }

    if (typeof value === 'string') {
      sanitized[key] = sanitizeString(value);
      continue;
    }

    if (typeof value === 'number' && Number.isFinite(value)) {
      sanitized[key] = value;
      continue;
    }
  }
  return sanitized;
}

function sanitizeEvent(rawEvent) {
  if (!rawEvent || typeof rawEvent !== 'object') {
    throw new Error('Event payload must be an object');
  }

  const eventName = sanitizeString(String(rawEvent.event ?? ''), 64);
  if (!eventName) {
    throw new Error('Event name required');
  }

  const sessionRaw = sanitizeString(String(rawEvent.session_id ?? rawEvent.sessionId ?? 'anonymous'), 64);
  const safeSession = sessionRaw?.replace(/[^a-zA-Z0-9-_]/g, '') || 'anonymous';
  const ts = Number.isFinite(Number(rawEvent.ts)) ? Number(rawEvent.ts) : Date.now();
  const props = sanitizeProps(rawEvent.props ?? {});

  const sanitized = {
    schema: 'v1',
    event: eventName,
    session_id: safeSession || 'anonymous',
    ts,
    props
  };

  const variant = sanitizeString(rawEvent.variant ?? rawEvent.props?.variant, 32);
  if (variant) {
    sanitized.variant = variant;
  }

  return sanitized;
}

function deriveClientId(headers = {}) {
  const lowerCaseHeaders = {};
  for (const [key, value] of Object.entries(headers)) {
    lowerCaseHeaders[key.toLowerCase()] = value;
  }
  return (
    lowerCaseHeaders['x-session-id'] ||
    lowerCaseHeaders['x-client-id'] ||
    lowerCaseHeaders['x-forwarded-for'] ||
    'anonymous'
  );
}

function createEventsHandler(options = {}) {
  const {
    maxEventsPerRequest = DEFAULT_MAX_EVENTS_PER_REQUEST,
    ringSize = DEFAULT_RING_SIZE,
    maxRequests = DEFAULT_RATE_LIMIT,
    windowMs = DEFAULT_WINDOW_MS,
    nowProvider = () => Date.now()
  } = options;

  if (maxEventsPerRequest <= 0) {
    throw new Error('maxEventsPerRequest must be positive');
  }

  const limiter = new SlidingWindowRateLimiter(maxRequests, windowMs, nowProvider);
  const ringBuffer = [];

  function appendToRing(events) {
    for (const event of events) {
      ringBuffer.push(event);
      if (ringBuffer.length > ringSize) {
        ringBuffer.shift();
      }
    }
  }

  function handle(request) {
    if (!request || typeof request !== 'object') {
      throw new Error('Request object required');
    }

    const headers = request.headers ?? {};
    const method = request.method ?? 'POST';
    const cacheHeaders = {
      'Cache-Control': 'no-store, max-age=0',
      Pragma: 'no-cache'
    };

    if (method !== 'POST') {
      return { status: 405, headers: cacheHeaders, body: { error: 'method_not_allowed' } };
    }

    const clientId = deriveClientId(headers);
    if (!limiter.tryConsume(clientId)) {
      return {
        status: 429,
        headers: cacheHeaders,
        body: { error: 'rate_limited', retryAfterMs: windowMs }
      };
    }

    let payload;
    try {
      payload = typeof request.body === 'string' ? JSON.parse(request.body) : request.body;
    } catch (err) {
      return { status: 400, headers: cacheHeaders, body: { error: 'invalid_json' } };
    }

    if (!payload || !Array.isArray(payload.events)) {
      return { status: 400, headers: cacheHeaders, body: { error: 'invalid_payload' } };
    }

    if (payload.events.length > maxEventsPerRequest) {
      return { status: 400, headers: cacheHeaders, body: { error: 'too_many_events' } };
    }

    try {
      const sanitizedEvents = payload.events.map(sanitizeEvent);
      appendToRing(sanitizedEvents);
      return {
        status: 200,
        headers: cacheHeaders,
        body: { status: 'ok', accepted: sanitizedEvents.length }
      };
    } catch (err) {
      return {
        status: 400,
        headers: cacheHeaders,
        body: { error: 'invalid_event', message: err.message }
      };
    }
  }

  return {
    handle,
    exportRingBuffer() {
      return ringBuffer.map((entry) => ({ ...entry, props: { ...entry.props } }));
    },
    clearRingBuffer() {
      ringBuffer.length = 0;
    },
    limiterSnapshot() {
      return limiter.snapshot();
    }
  };
}

module.exports = {
  createEventsHandler,
  SlidingWindowRateLimiter
};
