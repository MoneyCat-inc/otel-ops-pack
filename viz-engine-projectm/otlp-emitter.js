// Gate #020 - Minimal OTLP Span Emitter
// ECRR: BossCat OEM | Executor: Cursor{Implementer}
// Purpose: Emit OTLP spans for canary events to SigNoz

const http = require('http');

class OTLPEmitter {
  constructor(config = {}) {
    this.endpoint = config.endpoint || 'http://localhost:5318/v1/traces';
    this.serviceName = config.serviceName || 'pm-engine';
    this.environment = config.environment || 'staging';
  }
  
  // Generate trace/span IDs (8-byte hex for trace, 4-byte hex for span)
  generateTraceId() {
    return Array.from({ length: 32 }, () => Math.floor(Math.random() * 16).toString(16)).join('');
  }
  
  generateSpanId() {
    return Array.from({ length: 16 }, () => Math.floor(Math.random() * 16).toString(16)).join('');
  }
  
  // Emit a simple span
  emitSpan(name, attributes = {}, durationMs = 0) {
    const nowNanos = Date.now() * 1000000;
    const startTimeNanos = nowNanos - (durationMs * 1000000);
    
    const payload = {
      resourceSpans: [{
        resource: {
          attributes: [
            { key: 'service.name', value: { stringValue: this.serviceName } },
            { key: 'deployment.environment', value: { stringValue: this.environment } }
          ]
        },
        scopeSpans: [{
          scope: { name: 'canary-deployment', version: '1.0.0' },
          spans: [{
            traceId: this.generateTraceId(),
            spanId: this.generateSpanId(),
            name: name,
            kind: 1,  // SPAN_KIND_INTERNAL
            startTimeUnixNano: startTimeNanos.toString(),
            endTimeUnixNano: nowNanos.toString(),
            attributes: Object.entries(attributes).map(([key, value]) => ({
              key,
              value: this.convertValue(value)
            }))
          }]
        }]
      }]
    };
    
    return this.sendToOTLP(payload);
  }
  
  convertValue(value) {
    if (typeof value === 'string') return { stringValue: value };
    if (typeof value === 'number') {
      return Number.isInteger(value) 
        ? { intValue: value.toString() }
        : { doubleValue: value };
    }
    if (typeof value === 'boolean') return { boolValue: value };
    return { stringValue: String(value) };
  }
  
  sendToOTLP(payload) {
    return new Promise((resolve, reject) => {
      const url = new URL(this.endpoint);
      const options = {
        hostname: url.hostname,
        port: url.port || 5318,
        path: url.pathname,
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        }
      };
      
      const req = http.request(options, (res) => {
        let data = '';
        res.on('data', (chunk) => { data += chunk; });
        res.on('end', () => {
          if (res.statusCode >= 200 && res.statusCode < 300) {
            resolve({ ok: true, status: res.statusCode });
          } else {
            reject(new Error(`OTLP failed: ${res.statusCode} ${data}`));
          }
        });
      });
      
      req.on('error', (err) => {
        console.error('[otlp] Failed to emit span:', err.message);
        reject(err);
      });
      
      req.write(JSON.stringify(payload));
      req.end();
    });
  }
}

module.exports = { OTLPEmitter };

