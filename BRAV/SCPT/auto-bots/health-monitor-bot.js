#!/usr/bin/env node

/**
 * Auto Health Monitor Bot
 * BossCat OEM - Automated Health Monitoring System
 * Continuously monitors SigNoz, OTel Collector, and system health
 */

const http = require('http');
const https = require('https');
const fs = require('fs');
const path = require('path');

// Configuration
const CONFIG = {
  signozUrl: 'http://localhost:8080',
  otelCollectorUrl: 'http://localhost:4318',
  windowsCollectorUrl: 'http://localhost:5321',
  checkInterval: 30000, // 30 seconds
  reportInterval: 300000, // 5 minutes
  maxHistoryDays: 7,
  logFile: 'artifacts/auto-bots/health-monitor.log',
  statusFile: 'artifacts/auto-bots/health-status.json'
};

// Health status tracking
let healthStatus = {
  timestamp: new Date().toISOString(),
  signoz: { status: 'unknown', responseTime: 0, lastCheck: null },
  otelCollector: { status: 'unknown', responseTime: 0, lastCheck: null },
  windowsCollector: { status: 'unknown', responseTime: 0, lastCheck: null },
  system: { status: 'unknown', cpuUsage: 0, memoryUsage: 0, lastCheck: null },
  uptime: { startTime: new Date().toISOString(), checks: 0, failures: 0 }
};

// Ensure artifacts directory exists
if (!fs.existsSync('artifacts/auto-bots')) {
  fs.mkdirSync('artifacts/auto-bots', { recursive: true });
}

// HTTP helper with timeout
function makeRequest(url, options = {}, timeout = 5000) {
  return new Promise((resolve, reject) => {
    const urlObj = new URL(url);
    const client = urlObj.protocol === 'https:' ? https : http;
    
    const startTime = Date.now();
    
    const requestOptions = {
      hostname: urlObj.hostname,
      port: urlObj.port,
      path: urlObj.pathname + urlObj.search,
      method: options.method || 'GET',
      timeout: timeout,
      ...options
    };

    const req = client.request(requestOptions, (res) => {
      const responseTime = Date.now() - startTime;
      let body = '';
      res.on('data', (chunk) => body += chunk);
      res.on('end', () => {
        resolve({ 
          status: res.statusCode, 
          body, 
          responseTime,
          headers: res.headers
        });
      });
    });

    req.on('error', (error) => {
      const responseTime = Date.now() - startTime;
      reject(new Error(`Connection failed: ${error.message}`));
    });

    req.on('timeout', () => {
      req.destroy();
      reject(new Error('Request timeout'));
    });

    if (options.body) {
      req.write(options.body);
    }
    req.end();
  });
}

// Check SigNoz health
async function checkSigNozHealth() {
  try {
    const response = await makeRequest(`${CONFIG.signozUrl}/api/v1/health`);
    healthStatus.signoz = {
      status: response.status === 200 ? 'healthy' : 'unhealthy',
      responseTime: response.responseTime,
      lastCheck: new Date().toISOString(),
      details: response.body
    };
    return response.status === 200;
  } catch (error) {
    healthStatus.signoz = {
      status: 'unhealthy',
      responseTime: 0,
      lastCheck: new Date().toISOString(),
      error: error.message
    };
    return false;
  }
}

// Check OTel Collector health
async function checkOTelCollectorHealth() {
  try {
    // Try to send a test log
    const testLog = {
      resourceLogs: [{
        resource: {
          attributes: [
            { key: 'service.name', value: { stringValue: 'health-monitor-bot' } },
            { key: 'health.check', value: { boolValue: true } }
          ]
        },
        scopeLogs: [{
          logRecords: [{
            timeUnixNano: (Date.now() * 1000000).toString(),
            severityText: 'INFO',
            body: { stringValue: 'Health check from Auto Health Monitor Bot' }
          }]
        }]
      }]
    };

    const response = await makeRequest(`${CONFIG.otelCollectorUrl}/v1/logs`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(testLog)
    });

    healthStatus.otelCollector = {
      status: response.status === 200 ? 'healthy' : 'unhealthy',
      responseTime: response.responseTime,
      lastCheck: new Date().toISOString(),
      details: `HTTP ${response.status}`
    };
    return response.status === 200;
  } catch (error) {
    healthStatus.otelCollector = {
      status: 'unhealthy',
      responseTime: 0,
      lastCheck: new Date().toISOString(),
      error: error.message
    };
    return false;
  }
}

// Check Windows Collector health
async function checkWindowsCollectorHealth() {
  try {
    const response = await makeRequest(`${CONFIG.windowsCollectorUrl}/v1/logs`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ test: 'health-check' })
    });

    healthStatus.windowsCollector = {
      status: response.status === 200 ? 'healthy' : 'unhealthy',
      responseTime: response.responseTime,
      lastCheck: new Date().toISOString(),
      details: `HTTP ${response.status}`
    };
    return response.status === 200;
  } catch (error) {
    healthStatus.windowsCollector = {
      status: 'unhealthy',
      responseTime: 0,
      lastCheck: new Date().toISOString(),
      error: error.message
    };
    return false;
  }
}

// Check system health
async function checkSystemHealth() {
  try {
    const os = require('os');
    
    healthStatus.system = {
      status: 'healthy',
      cpuUsage: os.loadavg()[0] * 100 / os.cpus().length,
      memoryUsage: (os.totalmem() - os.freemem()) / os.totalmem() * 100,
      lastCheck: new Date().toISOString(),
      details: {
        platform: os.platform(),
        arch: os.arch(),
        uptime: os.uptime(),
        totalMemory: os.totalmem(),
        freeMemory: os.freemem()
      }
    };
    return true;
  } catch (error) {
    healthStatus.system = {
      status: 'unhealthy',
      cpuUsage: 0,
      memoryUsage: 0,
      lastCheck: new Date().toISOString(),
      error: error.message
    };
    return false;
  }
}

// Log health status
function logHealthStatus() {
  const timestamp = new Date().toISOString();
  const logEntry = {
    timestamp,
    health: healthStatus,
    summary: {
      healthyServices: Object.values(healthStatus).filter(s => 
        typeof s === 'object' && s.status === 'healthy'
      ).length,
      totalServices: 4,
      overallHealth: healthStatus.signoz.status === 'healthy' && 
                   healthStatus.otelCollector.status === 'healthy' ? 'healthy' : 'degraded'
    }
  };

  // Append to log file
  fs.appendFileSync(CONFIG.logFile, JSON.stringify(logEntry) + '\n');
  
  // Update status file
  fs.writeFileSync(CONFIG.statusFile, JSON.stringify(healthStatus, null, 2));
  
  // Console output
  const status = logEntry.summary.overallHealth === 'healthy' ? '✅' : '⚠️';
  console.log(`[${timestamp}] ${status} Health Check - ${logEntry.summary.healthyServices}/4 services healthy`);
  
  if (logEntry.summary.overallHealth === 'degraded') {
    console.log(`   SigNoz: ${healthStatus.signoz.status}`);
    console.log(`   OTel Collector: ${healthStatus.otelCollector.status}`);
    console.log(`   Windows Collector: ${healthStatus.windowsCollector.status}`);
    console.log(`   System: ${healthStatus.system.status}`);
  }
}

// Main health monitoring loop
async function runHealthMonitoring() {
  console.log('🤖 Auto Health Monitor Bot Starting...');
  console.log('=====================================');
  console.log(`📊 SigNoz: ${CONFIG.signozUrl}`);
  console.log(`🔧 OTel Collector: ${CONFIG.otelCollectorUrl}`);
  console.log(`🪟 Windows Collector: ${CONFIG.windowsCollectorUrl}`);
  console.log(`⏱️  Check Interval: ${CONFIG.checkInterval / 1000} seconds`);
  console.log('');

  // Initial health check
  await checkSigNozHealth();
  await checkOTelCollectorHealth();
  await checkWindowsCollectorHealth();
  await checkSystemHealth();
  logHealthStatus();

  // Start monitoring loop
  const healthInterval = setInterval(async () => {
    healthStatus.uptime.checks++;
    
    const results = await Promise.allSettled([
      checkSigNozHealth(),
      checkOTelCollectorHealth(),
      checkWindowsCollectorHealth(),
      checkSystemHealth()
    ]);
    
    const failures = results.filter(r => r.status === 'rejected' || !r.value).length;
    if (failures > 0) {
      healthStatus.uptime.failures += failures;
    }
    
    logHealthStatus();
  }, CONFIG.checkInterval);

  // Keep running
  process.on('SIGINT', () => {
    console.log('\n🤖 Auto Health Monitor Bot shutting down...');
    clearInterval(healthInterval);
    
    // Final status report
    const finalReport = {
      shutdown: new Date().toISOString(),
      totalChecks: healthStatus.uptime.checks,
      totalFailures: healthStatus.uptime.failures,
      uptime: Date.now() - new Date(healthStatus.uptime.startTime).getTime(),
      finalHealth: healthStatus
    };
    
    fs.writeFileSync('artifacts/auto-bots/health-monitor-shutdown.json', JSON.stringify(finalReport, null, 2));
    console.log('📋 Final report saved to artifacts/auto-bots/health-monitor-shutdown.json');
    process.exit(0);
  });

  // Keep process alive
  console.log('🤖 Auto Health Monitor Bot running... (Press Ctrl+C to stop)');
}

// Start the bot
runHealthMonitoring().catch(error => {
  console.error('💥 Auto Health Monitor Bot failed:', error.message);
  process.exit(1);
});
