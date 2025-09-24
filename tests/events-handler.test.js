const { createEventsHandler } = require('../src/api/events/handler');

describe('/api/events handler', () => {
  function makeHandler(overrides = {}) {
    return createEventsHandler({
      maxRequests: overrides.maxRequests ?? 2,
      windowMs: overrides.windowMs ?? 1000,
      ringSize: overrides.ringSize ?? 10,
      maxEventsPerRequest: overrides.maxEventsPerRequest ?? 5,
      nowProvider: overrides.nowProvider ?? (() => Date.now())
    });
  }

  function buildRequest(events, headers = {}) {
    return {
      method: 'POST',
      headers,
      body: { events }
    };
  }

  test('accepts analytics payload, clamps props, and writes to ring buffer', () => {
    const handler = makeHandler();
    const response = handler.handle(
      buildRequest(
        [
          {
            event: 'warmup_start',
            session_id: ' user-123 ',
            ts: 1,
            props: {
              flow: 'daily',
              step: 'warmup',
              grantRatePct: 150,
              activationRatePct: -5,
              latencyMs: 5000,
              durationMs: 30_000,
              status: ' ok '
            }
          }
        ],
        { 'x-session-id': 'abc' }
      )
    );

    expect(response.status).toBe(200);
    expect(response.headers['Cache-Control']).toContain('no-store');
    expect(response.body).toEqual({ status: 'ok', accepted: 1 });

    const ring = handler.exportRingBuffer();
    expect(ring).toHaveLength(1);
    expect(ring[0].props.grantRatePct).toBe(100);
    expect(ring[0].props.activationRatePct).toBe(0);
    expect(ring[0].props.latencyMs).toBe(5000);
    expect(ring[0].props.durationMs).toBe(30000);
    expect(ring[0].props.status).toBe('ok');
    expect(ring[0].session_id).toBe('user-123');
  });

  test('rejects payloads that include banned audio or PII hints', () => {
    const handler = makeHandler();
    const response = handler.handle(
      buildRequest([
        {
          event: 'invalid',
          props: {
            audioBlob: 'danger',
            flow: 'daily'
          }
        }
      ])
    );

    expect(response.status).toBe(400);
    expect(response.body.error).toBe('invalid_event');
  });

  test('enforces ring buffer export/delete data controls', () => {
    const handler = makeHandler();
    handler.handle(
      buildRequest([
        { event: 'first', props: { flow: 'daily', step: 'warmup' } }
      ])
    );
    expect(handler.exportRingBuffer()).toHaveLength(1);
    handler.clearRingBuffer();
    expect(handler.exportRingBuffer()).toHaveLength(0);
  });

  test('rate limits repeated requests from the same client', () => {
    let now = 0;
    const handler = makeHandler({
      maxRequests: 2,
      windowMs: 1000,
      nowProvider: () => now
    });

    const headers = { 'x-session-id': 'limittest' };
    const events = [{ event: 'tick', props: { flow: 'daily', step: 'warmup' } }];

    const first = handler.handle(buildRequest(events, headers));
    expect(first.status).toBe(200);

    const second = handler.handle(buildRequest(events, headers));
    expect(second.status).toBe(200);

    const third = handler.handle(buildRequest(events, headers));
    expect(third.status).toBe(429);
    expect(third.body.retryAfterMs).toBe(1000);

    now = 1500;
    const fourth = handler.handle(buildRequest(events, headers));
    expect(fourth.status).toBe(200);
  });

  test('rejects requests that exceed per-request event caps', () => {
    const handler = makeHandler({ maxEventsPerRequest: 1 });
    const response = handler.handle(
      buildRequest([
        { event: 'ok', props: { flow: 'daily', step: 'warmup' } },
        { event: 'extra', props: { flow: 'daily', step: 'warmup' } }
      ])
    );
    expect(response.status).toBe(400);
    expect(response.body.error).toBe('too_many_events');
  });

  test('rejects unsupported HTTP verbs', () => {
    const handler = makeHandler();
    const response = handler.handle({ method: 'GET', headers: {}, body: {} });
    expect(response.status).toBe(405);
  });
});
