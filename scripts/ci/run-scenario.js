#!/usr/bin/env node
/**
 * BossCat OEM - Scenario Runner for CI/CD
 * Executes stress test scenarios and collects results
 */

const http = require('http');
const fs = require('fs');
const path = require('path');

// Configuration
const CONFIG = {
  dashboardUrl: 'http://localhost:3000',
  signozUrl: 'http://localhost:8080',
  otelCollectorUrl: 'http://localhost:5318',
  scenariosFile: path.join(__dirname, '../../docs/dashboards/scenarios-example.json'),
  resultsDir: path.join(__dirname, '../../test-results')
};

// Load scenario definitions
function loadScenarios() {
  const data = fs.readFileSync(CONFIG.scenariosFile, 'utf8');
  return JSON.parse(data);
}

// Execute scenario
async function runScenario(scenarioName) {
  console.log(`🚀 Starting scenario: ${scenarioName}`);
  
  // Check service health first
  console.log('🔍 Checking service health...');
  await checkServiceHealth();
  
  const scenarios = loadScenarios();
  const scenario = scenarios.scenarios[scenarioName];
  
  if (!scenario) {
    throw new Error(`Scenario '${scenarioName}' not found`);
  }
  
  console.log(`📋 ${scenario.name}`);
  console.log(`📝 ${scenario.description}`);
  console.log(`⏱️  Duration: ${scenario.duration}s`);
  console.log(`📊 Expected: ${scenario.expectedThroughput}`);
  
  // Create results directory
  if (!fs.existsSync(CONFIG.resultsDir)) {
    fs.mkdirSync(CONFIG.resultsDir, { recursive: true });
  }
  
  // Check if OTel Collector is accessible
  let otelAccessible = false;
  try {
    const testResponse = await fetch(CONFIG.otelCollectorUrl + '/v1/logs');
    otelAccessible = true;
    console.log('✅ OTel Collector is accessible');
  } catch (error) {
    console.log('⚠️  OTel Collector not accessible - running in simulation mode');
    console.log('   This will generate simulated data without actual OTLP sending');
  }
  
  // Execute scenario
  if (scenario.phases) {
    await runMultiPhaseScenario(scenario, otelAccessible);
  } else {
    await runSinglePhaseScenario(scenario, otelAccessible);
  }
  
  console.log(`✅ Scenario completed: ${scenarioName}`);
}

// Run single-phase scenario
async function runSinglePhaseScenario(scenario, otelAccessible = true) {
  console.log(`▶️  Running single-phase scenario...`);
  
  // Send logs based on scenario settings
  await generateLoad(scenario.settings, scenario.duration, otelAccessible);
}

// Run multi-phase scenario
async function runMultiPhaseScenario(scenario, otelAccessible = true) {
  console.log(`🔄 Running multi-phase scenario with ${scenario.phases.length} phases...`);
  
  for (let i = 0; i < scenario.phases.length; i++) {
    const phase = scenario.phases[i];
    console.log(`📋 Phase ${i + 1}: ${phase.name} (${phase.duration}s)`);
    
    await generateLoad(phase.settings, phase.duration, otelAccessible);
  }
}

// Generate load based on settings
async function generateLoad(settings, duration, otelAccessible = true) {
  const startTime = Date.now();
  const endTime = startTime + (duration * 1000);
  
  let logCount = 0;
  let metricCount = 0;
  let traceCount = 0;
  
  while (Date.now() < endTime) {
    // Multi-source logs
    if (settings.multiSource?.enabled) {
      if (otelAccessible) {
        await sendLog('multi-source', settings.multiSource.frequency);
      } else {
        console.log(`📝 [SIM] Multi-source log: ${settings.multiSource.frequency} logs/sec`);
      }
      logCount++;
    }
    
    // Metrics
    if (settings.metrics?.enabled) {
      if (otelAccessible) {
        await sendMetric('synthetic', settings.metrics.volume);
      } else {
        console.log(`📊 [SIM] Synthetic metric: ${settings.metrics.volume} metrics/sec`);
      }
      metricCount++;
    }
    
    // Noise
    if (settings.noise?.enabled) {
      if (otelAccessible) {
        await sendLog('noise', settings.noise.intensity);
      } else {
        console.log(`🎲 [SIM] Noise log: intensity ${settings.noise.intensity}`);
      }
      logCount++;
    }
    
    // Traces
    if (settings.traces?.enabled) {
      if (otelAccessible) {
        await sendTrace('synthetic', settings.traces.rate);
      } else {
        console.log(`🔗 [SIM] Synthetic trace: ${settings.traces.rate} traces/sec`);
      }
      traceCount++;
    }
    
    // Wait 1 second between batches
    await sleep(1000);
  }
  
  console.log(`📊 Generated ${logCount} logs, ${metricCount} metrics, ${traceCount} traces in ${duration}s`);
}

// Send OTLP log
async function sendLog(source, intensity) {
  const log = {
    resourceLogs: [{
      resource: {
        attributes: [
          { key: 'service.name', value: { stringValue: `ci-${source}` } },
          { key: 'stress.test', value: { boolValue: true } },
          { key: 'ci.run', value: { boolValue: true } }
        ]
      },
      scopeLogs: [{
        scope: { name: 'ci-stress-test' },
        logRecords: [{
          timeUnixNano: Date.now() * 1000000,
          severityText: 'INFO',
          body: { stringValue: `CI stress test log - ${source} - intensity ${intensity}` },
          attributes: [
            { key: 'generator', value: { stringValue: source } },
            { key: 'intensity', value: { intValue: intensity } }
          ]
        }]
      }]
    }]
  };
  
  try {
    await postData(`${CONFIG.otelCollectorUrl}/v1/logs`, log);
  } catch (error) {
    console.error(`❌ Failed to send log: ${error.message}`);
  }
}

// Send OTLP metric
async function sendMetric(source, volume) {
  const metric = {
    resourceMetrics: [{
      resource: {
        attributes: [
          { key: 'service.name', value: { stringValue: `ci-${source}` } },
          { key: 'stress.test', value: { boolValue: true } }
        ]
      },
      scopeMetrics: [{
        scope: { name: 'ci-stress-test' },
        metrics: [{
          name: 'stress_test_metric',
          unit: 'count',
          sum: {
            dataPoints: [{
              asInt: volume,
              timeUnixNano: Date.now() * 1000000
            }]
          }
        }]
      }]
    }]
  };
  
  try {
    await postData(`${CONFIG.otelCollectorUrl}/v1/metrics`, metric);
  } catch (error) {
    console.error(`❌ Failed to send metric: ${error.message}`);
  }
}

// Send OTLP trace
async function sendTrace(source, rate) {
  const traceId = Buffer.from(Array(16).fill(0).map(() => Math.floor(Math.random() * 256)));
  const spanId = Buffer.from(Array(8).fill(0).map(() => Math.floor(Math.random() * 256)));
  
  const trace = {
    resourceSpans: [{
      resource: {
        attributes: [
          { key: 'service.name', value: { stringValue: `ci-${source}` } },
          { key: 'stress.test', value: { boolValue: true } }
        ]
      },
      scopeSpans: [{
        scope: { name: 'ci-stress-test' },
        spans: [{
          traceId: traceId.toString('hex'),
          spanId: spanId.toString('hex'),
          name: `CI-Trace-${source}`,
          startTimeUnixNano: Date.now() * 1000000,
          endTimeUnixNano: (Date.now() + 100) * 1000000,
          attributes: [
            { key: 'rate', value: { intValue: rate } }
          ]
        }]
      }]
    }]
  };
  
  try {
    await postData(`${CONFIG.otelCollectorUrl}/v1/traces`, trace);
  } catch (error) {
    console.error(`❌ Failed to send trace: ${error.message}`);
  }
}

// HTTP POST helper with timeout and better error handling
function postData(url, data) {
  return new Promise((resolve, reject) => {
    const parsedUrl = new URL(url);
    const options = {
      hostname: parsedUrl.hostname,
      port: parsedUrl.port,
      path: parsedUrl.pathname,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(JSON.stringify(data))
      },
      timeout: 5000 // 5 second timeout
    };
    
    const req = http.request(options, (res) => {
      let body = '';
      res.on('data', (chunk) => body += chunk);
      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          resolve(body);
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

// Health check for services
async function checkServiceHealth() {
  const services = [
    { name: 'SigNoz', url: 'http://localhost:8080/api/v1/health' },
    { name: 'OTel Collector', url: 'http://localhost:5318/v1/logs' }
  ];
  
  for (const service of services) {
    try {
      const response = await fetch(service.url);
      if (response.ok) {
        console.log(`✅ ${service.name} is healthy`);
      } else {
        console.log(`⚠️  ${service.name} responded with ${response.status}`);
      }
    } catch (error) {
      console.log(`❌ ${service.name} is not accessible: ${error.message}`);
    }
  }
}

// Sleep helper
function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

// Main execution
if (require.main === module) {
  const scenarioName = process.argv[2];
  
  if (!scenarioName) {
    console.error('❌ Usage: node run-scenario.js <scenario-name>');
    process.exit(1);
  }
  
  runScenario(scenarioName)
    .then(() => {
      console.log('✅ Scenario execution complete');
      process.exit(0);
    })
    .catch((error) => {
      console.error(`❌ Scenario execution failed: ${error.message}`);
      process.exit(1);
    });
}

module.exports = { runScenario };

