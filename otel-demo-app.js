// Simple OpenTelemetry Demo App
// Uses environment variables for configuration

const express = require('express');
const { trace } = require('@opentelemetry/api');

const app = express();
const PORT = 3001;

// Middleware
app.use(express.json());

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ 
    status: 'ok', 
    timestamp: new Date().toISOString(),
    service: 'otel-demo-app',
    version: '1.0.0'
  });
});

// Demo endpoint that creates traces
app.get('/api/demo', (req, res) => {
  const tracer = trace.getTracer('otel-demo-app');
  const span = tracer.startSpan('demo-operation');
  
  try {
    // Simulate some work
    span.setAttributes({
      'operation.type': 'demo',
      'user.id': 'demo-user',
      'request.id': Math.random().toString(36).substr(2, 9),
    });
    
    // Simulate processing time
    setTimeout(() => {
      span.setStatus({ code: 1 }); // OK
      span.end();
      res.json({ 
        message: 'Demo operation completed!',
        traceId: span.spanContext().traceId,
        spanId: span.spanContext().spanId,
        timestamp: new Date().toISOString()
      });
    }, 100);
    
  } catch (error) {
    span.setStatus({ code: 2, message: error.message }); // ERROR
    span.recordException(error);
    span.end();
    res.status(500).json({ error: error.message });
  }
});

// Error endpoint to test error tracking
app.get('/api/error', (req, res) => {
  const tracer = trace.getTracer('otel-demo-app');
  const span = tracer.startSpan('error-operation');
  
  try {
    span.setAttributes({
      'operation.type': 'error-demo',
      'error.expected': true,
    });
    
    throw new Error('This is a demo error for testing error tracking');
    
  } catch (error) {
    span.setStatus({ code: 2, message: error.message }); // ERROR
    span.recordException(error);
    span.end();
    res.status(500).json({ 
      error: error.message,
      traceId: span.spanContext().traceId,
      spanId: span.spanContext().spanId,
    });
  }
});

// Metrics endpoint
app.get('/api/metrics', (req, res) => {
  const tracer = trace.getTracer('otel-demo-app');
  const span = tracer.startSpan('metrics-operation');
  
  span.setAttributes({
    'operation.type': 'metrics',
    'metrics.count': Math.floor(Math.random() * 100),
  });
  
  span.end();
  
  res.json({ 
    message: 'Metrics generated!',
    timestamp: new Date().toISOString(),
    randomValue: Math.floor(Math.random() * 100)
  });
});

// Load test endpoint
app.get('/api/load', (req, res) => {
  const tracer = trace.getTracer('otel-demo-app');
  const span = tracer.startSpan('load-test-operation');
  
  const iterations = parseInt(req.query.iterations) || 10;
  
  span.setAttributes({
    'operation.type': 'load-test',
    'load.iterations': iterations,
  });
  
  // Simulate some CPU work
  let result = 0;
  for (let i = 0; i < iterations * 1000; i++) {
    result += Math.random();
  }
  
  span.setAttributes({
    'load.result': result,
  });
  
  span.end();
  
  res.json({ 
    message: 'Load test completed!',
    iterations: iterations,
    result: result,
    timestamp: new Date().toISOString()
  });
});

// Start server
app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 OTel Demo App running on port ${PORT}`);
  console.log(`📊 Health check: http://localhost:${PORT}/health`);
  console.log(`🔍 Demo endpoint: http://localhost:${PORT}/api/demo`);
  console.log(`❌ Error endpoint: http://localhost:${PORT}/api/error`);
  console.log(`📈 Metrics endpoint: http://localhost:${PORT}/api/metrics`);
  console.log(`⚡ Load test: http://localhost:${PORT}/api/load?iterations=100`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('🛑 Shutting down gracefully...');
  process.exit(0);
});