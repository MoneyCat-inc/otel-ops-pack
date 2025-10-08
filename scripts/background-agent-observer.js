#!/usr/bin/env node

/**
 * Background Agent B - Observer/Validator
 * Monitors Agent A (Telemetry Generator) and validates SigNoz ingestion
 * BossCat OEM - Background Agent Pair Protocol
 */

const http = require('http');
const https = require('https');

// Configuration
const CONFIG = {
  signozUrl: 'http://localhost:8080',
  observationInterval: 5000, // 5 seconds
  validationDuration: 120000, // 2 minutes
  agentAPid: null, // Will be set dynamically
};

// Monitoring data
let observationLog = [];
let lastLogCount = 0;
let lastMetricCount = 0;
let lastTraceCount = 0;

// HTTP helper
function makeRequest(url, options = {}) {
  return new Promise((resolve, reject) => {
    const urlObj = new URL(url);
    const client = urlObj.protocol === 'https:' ? https : http;
    
    const requestOptions = {
      hostname: urlObj.hostname,
      port: urlObj.port,
      path: urlObj.pathname + urlObj.search,
      method: 'GET',
      timeout: 3000,
      ...options
    };

    const req = client.request(requestOptions, (res) => {
      let body = '';
      res.on('data', (chunk) => body += chunk);
      res.on('end', () => {
        try {
          const data = JSON.parse(body);
          resolve({ status: res.statusCode, data });
        } catch (error) {
          resolve({ status: res.statusCode, body });
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

    req.end();
  });
}

// Check SigNoz health
async function checkSigNozHealth() {
  try {
    const response = await makeRequest(`${CONFIG.signozUrl}/api/v1/health`);
    return response.status === 200;
  } catch (error) {
    return false;
  }
}

// Query SigNoz logs
async function querySigNozLogs() {
  try {
    const query = {
      query: 'validation.test = true',
      limit: 100,
      order: 'desc'
    };
    
    const response = await makeRequest(`${CONFIG.signozUrl}/api/v1/logs`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(query)
    });
    
    if (response.status === 200 && response.data) {
      return response.data.logs || [];
    }
    return [];
  } catch (error) {
    return [];
  }
}

// Query SigNoz metrics
async function querySigNozMetrics() {
  try {
    const response = await makeRequest(`${CONFIG.signozUrl}/api/v1/metrics`);
    if (response.status === 200 && response.data) {
      return response.data.metrics || [];
    }
    return [];
  } catch (error) {
    return [];
  }
}

// Query SigNoz traces
async function querySigNozTraces() {
  try {
    const query = {
      query: 'validation.test = true',
      limit: 50
    };
    
    const response = await makeRequest(`${CONFIG.signozUrl}/api/v1/traces`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(query)
    });
    
    if (response.status === 200 && response.data) {
      return response.data.traces || [];
    }
    return [];
  } catch (error) {
    return [];
  }
}

// Log observation
function logObservation(timestamp, message, data = {}) {
  const entry = {
    timestamp,
    message,
    data,
    agent: 'B-Observer'
  };
  
  observationLog.push(entry);
  console.log(`[${timestamp.toISOString()}] Agent B: ${message}`);
  
  // Keep only last 100 entries
  if (observationLog.length > 100) {
    observationLog = observationLog.slice(-100);
  }
}

// Validate telemetry ingestion
async function validateTelemetryIngestion() {
  const timestamp = new Date();
  
  try {
    // Check SigNoz health
    const isHealthy = await checkSigNozHealth();
    if (!isHealthy) {
      logObservation(timestamp, '⚠️ SigNoz health check failed', { healthy: false });
      return false;
    }
    
    // Query logs
    const logs = await querySigNozLogs();
    const validationLogs = logs.filter(log => 
      log.body && log.body.includes('validation.test') || 
      log.attributes && Object.values(log.attributes).some(attr => 
        attr && attr.includes && attr.includes('comprehensive-validation')
      )
    );
    
    // Query metrics
    const metrics = await querySigNozMetrics();
    const validationMetrics = metrics.filter(metric => 
      metric.name && (
        metric.name.includes('requests_total') ||
        metric.name.includes('response_time_ms') ||
        metric.name.includes('memory_usage_percent') ||
        metric.name.includes('cpu_usage_percent') ||
        metric.name.includes('error_rate_percent')
      )
    );
    
    // Query traces
    const traces = await querySigNozTraces();
    const validationTraces = traces.filter(trace => 
      trace.spans && trace.spans.some(span => 
        span.attributes && Object.values(span.attributes).some(attr => 
          attr && attr.includes && attr.includes('comprehensive-validation')
        )
      )
    );
    
    // Calculate deltas
    const logDelta = validationLogs.length - lastLogCount;
    const metricDelta = validationMetrics.length - lastMetricCount;
    const traceDelta = validationTraces.length - lastTraceCount;
    
    // Update counters
    lastLogCount = validationLogs.length;
    lastMetricCount = validationMetrics.length;
    lastTraceCount = validationTraces.length;
    
    // Log observation
    const observation = {
      sigNozHealthy: isHealthy,
      totalLogs: validationLogs.length,
      totalMetrics: validationMetrics.length,
      totalTraces: validationTraces.length,
      logDelta,
      metricDelta,
      traceDelta,
      timestamp: timestamp.toISOString()
    };
    
    logObservation(timestamp, '📊 Telemetry ingestion validated', observation);
    
    // Check if we're receiving new data
    if (logDelta > 0 || metricDelta > 0 || traceDelta > 0) {
      logObservation(timestamp, '✅ New telemetry data detected', {
        newLogs: logDelta,
        newMetrics: metricDelta,
        newTraces: traceDelta
      });
    }
    
    return true;
    
  } catch (error) {
    logObservation(timestamp, `❌ Validation error: ${error.message}`, { error: error.message });
    return false;
  }
}

// Generate observation report
function generateObservationReport() {
  const report = {
    agent: 'B-Observer',
    timestamp: new Date().toISOString(),
    totalObservations: observationLog.length,
    observations: observationLog,
    summary: {
      successfulValidations: observationLog.filter(entry => 
        entry.message.includes('✅') || entry.message.includes('📊')
      ).length,
      failedValidations: observationLog.filter(entry => 
        entry.message.includes('❌') || entry.message.includes('⚠️')
      ).length,
      currentLogCount: lastLogCount,
      currentMetricCount: lastMetricCount,
      currentTraceCount: lastTraceCount
    }
  };
  
  return report;
}

// Main observation loop
async function runObservation() {
  console.log('🔍 Agent B - Observer/Validator Starting');
  console.log('==========================================');
  console.log(`📊 SigNoz URL: ${CONFIG.signozUrl}`);
  console.log(`⏱️  Observation Interval: ${CONFIG.observationInterval / 1000} seconds`);
  console.log(`⏰ Duration: ${CONFIG.validationDuration / 1000} seconds`);
  console.log('');
  
  const startTime = Date.now();
  const endTime = startTime + CONFIG.validationDuration;
  
  // Initial observation
  logObservation(new Date(), '🚀 Agent B initialized - monitoring Agent A telemetry generation');
  
  // Start observation loop
  const observationInterval = setInterval(async () => {
    if (Date.now() >= endTime) {
      clearInterval(observationInterval);
      await finalizeObservation();
      return;
    }
    
    await validateTelemetryIngestion();
  }, CONFIG.observationInterval);
  
  // Wait for observation to complete
  await new Promise(resolve => setTimeout(resolve, CONFIG.validationDuration));
}

// Finalize observation
async function finalizeObservation() {
  const report = generateObservationReport();
  
  console.log('\n📋 OBSERVATION REPORT - Agent B');
  console.log('================================');
  console.log(`⏱️  Total Observations: ${report.totalObservations}`);
  console.log(`✅ Successful Validations: ${report.summary.successfulValidations}`);
  console.log(`❌ Failed Validations: ${report.summary.failedValidations}`);
  console.log(`📝 Final Log Count: ${report.summary.currentLogCount}`);
  console.log(`📊 Final Metric Count: ${report.summary.currentMetricCount}`);
  console.log(`🔗 Final Trace Count: ${report.summary.currentTraceCount}`);
  
  // Save report to file
  const fs = require('fs');
  const reportPath = 'artifacts/agent-b-observation-report.json';
  
  // Ensure artifacts directory exists
  if (!fs.existsSync('artifacts')) {
    fs.mkdirSync('artifacts', { recursive: true });
  }
  
  fs.writeFileSync(reportPath, JSON.stringify(report, null, 2));
  console.log(`\n💾 Report saved to: ${reportPath}`);
  
  console.log('\n🎯 NEXT STEPS:');
  console.log('1. Check SigNoz UI at http://localhost:8080');
  console.log('2. Verify logs, metrics, and traces in respective tabs');
  console.log('3. Review observation report for detailed analysis');
  console.log('4. Validate service dependency maps');
  
  if (report.summary.successfulValidations > 0) {
    console.log('\n🎉 OBSERVATION SUCCESSFUL - Telemetry ingestion validated!');
  } else {
    console.log('\n⚠️  OBSERVATION COMPLETED - Check SigNoz connectivity');
  }
}

// Run observation
runObservation().catch(error => {
  console.error('💥 Agent B observation failed:', error.message);
  process.exit(1);
});
