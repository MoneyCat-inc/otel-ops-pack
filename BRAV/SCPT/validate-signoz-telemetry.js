#!/usr/bin/env node

/**
 * SigNoz Telemetry Validation Script
 * Generates comprehensive traces, metrics, and logs for validation
 * BossCat OEM - Production Validation Protocol
 */

const http = require('http');
const https = require('https');

// Configuration
const CONFIG = {
  signozUrl: 'http://localhost:8080',
  otelCollectorUrl: 'http://localhost:4318',
  validationDuration: 60000, // 60 seconds
  logInterval: 1000, // 1 second
  metricInterval: 2000, // 2 seconds
  traceInterval: 3000, // 3 seconds
};

// Counters for validation
let logsSent = 0;
let metricsSent = 0;
let tracesSent = 0;
let errors = 0;

// Service configurations
const services = [
  { name: 'web-api', version: '1.2.3', environment: 'production' },
  { name: 'auth-service', version: '2.1.0', environment: 'production' },
  { name: 'payment-gateway', version: '1.5.2', environment: 'production' },
  { name: 'notification-service', version: '3.0.1', environment: 'production' },
  { name: 'analytics-engine', version: '1.8.4', environment: 'production' },
];

// HTTP helper with timeout
function makeRequest(url, data, options = {}) {
  return new Promise((resolve, reject) => {
    const urlObj = new URL(url);
    const client = urlObj.protocol === 'https:' ? https : http;
    
    const requestOptions = {
      hostname: urlObj.hostname,
      port: urlObj.port,
      path: urlObj.pathname,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(JSON.stringify(data))
      },
      timeout: 5000,
      ...options
    };

    const req = client.request(requestOptions, (res) => {
      let body = '';
      res.on('data', (chunk) => body += chunk);
      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          resolve({ status: res.statusCode, body });
        } else {
          reject(new Error(`HTTP ${res.statusCode}: ${body}`));
        }
      });
    });

    req.on('error', (error) => {
      reject(new Error(`Connection failed: ${error.message}`));
    });

    req.on('timeout', () => {
      req.destroy();
      reject(new Error('Request timeout'));
    });

    req.write(JSON.stringify(data));
    req.end();
  });
}

// Generate OTLP Log
function generateOTLPLog(service, message, level = 'INFO') {
  return {
    resourceLogs: [{
      resource: {
        attributes: [
          { key: 'service.name', value: { stringValue: service.name } },
          { key: 'service.version', value: { stringValue: service.version } },
          { key: 'deployment.environment', value: { stringValue: service.environment } },
          { key: 'validation.test', value: { boolValue: true } }
        ]
      },
      scopeLogs: [{
        scope: { name: 'signoz-validation', version: '1.0.0' },
        logRecords: [{
          timeUnixNano: (Date.now() * 1000000).toString(),
          severityNumber: level === 'ERROR' ? 17 : level === 'WARN' ? 13 : 9,
          severityText: level,
          body: { stringValue: message },
          attributes: [
            { key: 'test.type', value: { stringValue: 'comprehensive-validation' } },
            { key: 'validation.phase', value: { stringValue: 'production-ready' } }
          ]
        }]
      }]
    }]
  };
}

// Generate OTLP Metric
function generateOTLPMetric(service, metricName, value, type = 'gauge') {
  return {
    resourceMetrics: [{
      resource: {
        attributes: [
          { key: 'service.name', value: { stringValue: service.name } },
          { key: 'service.version', value: { stringValue: service.version } },
          { key: 'deployment.environment', value: { stringValue: service.environment } },
          { key: 'validation.test', value: { boolValue: true } }
        ]
      },
      scopeMetrics: [{
        scope: { name: 'signoz-validation', version: '1.0.0' },
        metrics: [{
          name: metricName,
          description: `Validation metric: ${metricName}`,
          unit: type === 'counter' ? '1' : type === 'gauge' ? '1' : 'By',
          [type]: {
            dataPoints: [{
              [type === 'counter' ? 'asInt' : 'asDouble']: type === 'counter' ? Math.floor(value) : value,
              startTimeUnixNano: (Date.now() * 1000000).toString(),
              timeUnixNano: (Date.now() * 1000000).toString(),
              attributes: [
                { key: 'test.type', value: { stringValue: 'comprehensive-validation' } },
                { key: 'validation.phase', value: { stringValue: 'production-ready' } }
              ]
            }]
          }
        }]
      }]
    }]
  };
}

// Generate OTLP Trace
function generateOTLPTrace(service, operation) {
  const traceId = Array.from({ length: 16 }, () => Math.floor(Math.random() * 256).toString(16).padStart(2, '0')).join('');
  const spanId = Array.from({ length: 8 }, () => Math.floor(Math.random() * 256).toString(16).padStart(2, '0')).join('');
  const parentSpanId = Array.from({ length: 8 }, () => Math.floor(Math.random() * 256).toString(16).padStart(2, '0')).join('');
  
  const startTime = Date.now() * 1000000;
  const duration = 50000 + Math.random() * 200000; // 50-250ms
  
  return {
    resourceSpans: [{
      resource: {
        attributes: [
          { key: 'service.name', value: { stringValue: service.name } },
          { key: 'service.version', value: { stringValue: service.version } },
          { key: 'deployment.environment', value: { stringValue: service.environment } },
          { key: 'validation.test', value: { boolValue: true } }
        ]
      },
      scopeSpans: [{
        scope: { name: 'signoz-validation', version: '1.0.0' },
        spans: [
          // Parent span
          {
            traceId: traceId,
            spanId: parentSpanId,
            name: `${operation}-parent`,
            kind: 2, // SPAN_KIND_SERVER
            startTimeUnixNano: startTime.toString(),
            endTimeUnixNano: (startTime + duration).toString(),
            attributes: [
              { key: 'test.type', value: { stringValue: 'comprehensive-validation' } },
              { key: 'validation.phase', value: { stringValue: 'production-ready' } },
              { key: 'http.method', value: { stringValue: 'POST' } },
              { key: 'http.route', value: { stringValue: '/api/validate' } },
              { key: 'http.status_code', value: { intValue: 200 } }
            ]
          },
          // Child span
          {
            traceId: traceId,
            spanId: spanId,
            parentSpanId: parentSpanId,
            name: `${operation}-child`,
            kind: 1, // SPAN_KIND_CLIENT
            startTimeUnixNano: (startTime + 10000).toString(),
            endTimeUnixNano: (startTime + duration - 10000).toString(),
            attributes: [
              { key: 'test.type', value: { stringValue: 'comprehensive-validation' } },
              { key: 'validation.phase', value: { stringValue: 'production-ready' } },
              { key: 'db.system', value: { stringValue: 'postgresql' } },
              { key: 'db.statement', value: { stringValue: 'SELECT * FROM validation_data' } },
              { key: 'db.operation', value: { stringValue: 'SELECT' } }
            ]
          }
        ]
      }]
    }]
  };
}

// Send log to SigNoz
async function sendLog(service, message, level = 'INFO') {
  try {
    const log = generateOTLPLog(service, message, level);
    await makeRequest(`${CONFIG.otelCollectorUrl}/v1/logs`, log);
    logsSent++;
    console.log(`✅ Log sent: ${service.name} - ${level}: ${message}`);
  } catch (error) {
    errors++;
    console.error(`❌ Failed to send log: ${error.message}`);
  }
}

// Send metric to SigNoz
async function sendMetric(service, metricName, value, type = 'gauge') {
  try {
    const metric = generateOTLPMetric(service, metricName, value, type);
    await makeRequest(`${CONFIG.otelCollectorUrl}/v1/metrics`, metric);
    metricsSent++;
    console.log(`📊 Metric sent: ${service.name} - ${metricName}: ${value}`);
  } catch (error) {
    errors++;
    console.error(`❌ Failed to send metric: ${error.message}`);
  }
}

// Send trace to SigNoz
async function sendTrace(service, operation) {
  try {
    const trace = generateOTLPTrace(service, operation);
    await makeRequest(`${CONFIG.otelCollectorUrl}/v1/traces`, trace);
    tracesSent++;
    console.log(`🔗 Trace sent: ${service.name} - ${operation}`);
  } catch (error) {
    errors++;
    console.error(`❌ Failed to send trace: ${error.message}`);
  }
}

// Validation scenarios
const scenarios = [
  {
    name: 'Normal Operation',
    logMessages: [
      'User authentication successful',
      'Payment processing completed',
      'Notification sent successfully',
      'Analytics data processed',
      'API request handled'
    ],
    metrics: [
      { name: 'requests_total', value: () => Math.floor(Math.random() * 1000) + 100, type: 'counter' },
      { name: 'response_time_ms', value: () => Math.random() * 500 + 50, type: 'gauge' },
      { name: 'memory_usage_percent', value: () => Math.random() * 80 + 20, type: 'gauge' },
      { name: 'cpu_usage_percent', value: () => Math.random() * 60 + 10, type: 'gauge' }
    ],
    operations: ['user_login', 'process_payment', 'send_notification', 'process_analytics', 'handle_api']
  },
  {
    name: 'High Load',
    logMessages: [
      'High traffic detected - scaling up',
      'Cache miss rate increased',
      'Database connection pool exhausted',
      'Load balancer redirecting traffic',
      'Performance degradation detected'
    ],
    metrics: [
      { name: 'requests_total', value: () => Math.floor(Math.random() * 5000) + 2000, type: 'counter' },
      { name: 'response_time_ms', value: () => Math.random() * 2000 + 500, type: 'gauge' },
      { name: 'memory_usage_percent', value: () => Math.random() * 40 + 60, type: 'gauge' },
      { name: 'cpu_usage_percent', value: () => Math.random() * 30 + 70, type: 'gauge' }
    ],
    operations: ['scale_up', 'cache_miss', 'db_pool_full', 'load_balance', 'perf_degradation']
  },
  {
    name: 'Error Conditions',
    logMessages: [
      'Database connection timeout',
      'External API rate limit exceeded',
      'Authentication service unavailable',
      'Payment gateway error',
      'Notification delivery failed'
    ],
    metrics: [
      { name: 'error_rate_percent', value: () => Math.random() * 20 + 5, type: 'gauge' },
      { name: 'timeout_count', value: () => Math.floor(Math.random() * 50) + 10, type: 'counter' },
      { name: 'failed_requests', value: () => Math.floor(Math.random() * 100) + 20, type: 'counter' },
      { name: 'retry_count', value: () => Math.floor(Math.random() * 200) + 50, type: 'counter' }
    ],
    operations: ['db_timeout', 'api_rate_limit', 'auth_unavailable', 'payment_error', 'notification_failed']
  }
];

// Run validation scenario
async function runScenario(scenario, service) {
  console.log(`\n🎯 Running scenario: ${scenario.name} for ${service.name}`);
  
  // Send logs
  const logMessage = scenario.logMessages[Math.floor(Math.random() * scenario.logMessages.length)];
  const logLevel = scenario.name === 'Error Conditions' ? 'ERROR' : Math.random() < 0.1 ? 'WARN' : 'INFO';
  await sendLog(service, logMessage, logLevel);
  
  // Send metrics
  const metric = scenario.metrics[Math.floor(Math.random() * scenario.metrics.length)];
  const value = typeof metric.value === 'function' ? metric.value() : metric.value;
  await sendMetric(service, metric.name, value, metric.type);
  
  // Send trace
  const operation = scenario.operations[Math.floor(Math.random() * scenario.operations.length)];
  await sendTrace(service, operation);
}

// Main validation function
async function runValidation() {
  console.log('🐾 BossCat OEM - SigNoz Telemetry Validation Protocol');
  console.log('====================================================');
  console.log(`📊 SigNoz URL: ${CONFIG.signozUrl}`);
  console.log(`🔧 OTel Collector: ${CONFIG.otelCollectorUrl}`);
  console.log(`⏱️  Duration: ${CONFIG.validationDuration / 1000} seconds`);
  console.log(`🏗️  Services: ${services.length} services`);
  console.log(`📋 Scenarios: ${scenarios.length} scenarios`);
  console.log('');
  
  const startTime = Date.now();
  const endTime = startTime + CONFIG.validationDuration;
  
  // Run validation loops
  const logInterval = setInterval(async () => {
    if (Date.now() >= endTime) {
      clearInterval(logInterval);
      return;
    }
    
    const service = services[Math.floor(Math.random() * services.length)];
    const scenario = scenarios[Math.floor(Math.random() * scenarios.length)];
    await runScenario(scenario, service);
  }, CONFIG.logInterval);
  
  // Wait for validation to complete
  await new Promise(resolve => setTimeout(resolve, CONFIG.validationDuration));
  
  // Clear intervals
  clearInterval(logInterval);
  
  // Validation summary
  const duration = (Date.now() - startTime) / 1000;
  console.log('\n📊 VALIDATION SUMMARY');
  console.log('=====================');
  console.log(`⏱️  Duration: ${duration.toFixed(1)} seconds`);
  console.log(`📝 Logs sent: ${logsSent}`);
  console.log(`📊 Metrics sent: ${metricsSent}`);
  console.log(`🔗 Traces sent: ${tracesSent}`);
  console.log(`❌ Errors: ${errors}`);
  console.log(`✅ Success rate: ${((logsSent + metricsSent + tracesSent - errors) / (logsSent + metricsSent + tracesSent) * 100).toFixed(1)}%`);
  
  console.log('\n🔍 NEXT STEPS:');
  console.log('1. Check SigNoz UI at http://localhost:8080');
  console.log('2. Verify logs in Logs tab');
  console.log('3. Check metrics in Metrics tab');
  console.log('4. View traces in Traces tab');
  console.log('5. Validate service dependency maps');
  console.log('');
  
  if (errors === 0) {
    console.log('🎉 VALIDATION SUCCESSFUL - All telemetry types delivered to SigNoz!');
    process.exit(0);
  } else {
    console.log('⚠️  VALIDATION COMPLETED WITH ERRORS - Check SigNoz connectivity');
    process.exit(1);
  }
}

// Run validation
runValidation().catch(error => {
  console.error('💥 Validation failed:', error.message);
  process.exit(1);
});
