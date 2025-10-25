// docs/milk-v0/emit-milk-trace.js
// Gate #011 Job M2 - Synthetic OTLP trace for Milk v0 viewer (simple HTTP POST)
const https = require('http');

const OTEL_ENDPOINT = process.env.OTEL_EXPORTER_OTLP_ENDPOINT || 'http://localhost:4318';
const traceID = '0123456789abcdef0123456789abcdef';
const spanID = '0123456789abcdef';

// Simple OTLP trace payload
const tracePayload = JSON.stringify({
  resourceSpans: [{
    resource: {
      attributes: [
        { key: 'service.name', value: { stringValue: 'milk-viewer' } },
        { key: 'deployment.environment', value: { stringValue: 'staging' } },
        { key: 'release.gate', value: { stringValue: '011' } }
      ]
    },
    scopeSpans: [{
      spans: [{
        traceId: traceID,
        spanId: spanID,
        name: 'milk.viewer.test',
        kind: 'SPAN_KIND_INTERNAL',
        startTimeUnixNano: Date.now() * 1000000,
        endTimeUnixNano: (Date.now() + 100) * 1000000,
        attributes: [
          { key: 'test.duration', value: { intValue: '30' } },
          { key: 'test.frames', value: { intValue: '20' } },
          { key: 'test.status', value: { stringValue: 'PASS' } }
        ]
      }]
    }]
  }]
});

// Send to OTLP endpoint
const url = new URL(`${OTEL_ENDPOINT}/v1/traces`);
const options = {
  hostname: url.hostname,
  port: url.port || 4318,
  path: url.pathname,
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Content-Length': Buffer.byteLength(tracePayload)
  }
};

console.log(`[trace] Sending milk.viewer.test span to ${OTEL_ENDPOINT}/v1/traces`);

const req = https.request(options, (res) => {
  console.log(`[trace] Response status: ${res.statusCode}`);
  if (res.statusCode === 200) {
    console.log('[trace] ✅ Trace sent successfully');
    process.exit(0);
  } else {
    console.error(`[trace] ❌ Failed: HTTP ${res.statusCode}`);
    process.exit(1);
  }
});

req.on('error', (err) => {
  console.error('[trace] ❌ Error:', err.message);
  process.exit(1);
});

req.write(tracePayload);
req.end();

