#!/usr/bin/env node

/**
 * Auto Alert Manager Bot
 * BossCat OEM - Automated Alert Management System
 * Monitors thresholds and triggers alerts based on telemetry data
 */

const http = require('http');
const https = require('https');
const fs = require('fs');
const path = require('path');

// Configuration
const CONFIG = {
  signozUrl: 'http://localhost:8080',
  alertInterval: 60000, // 1 minute
  alertHistoryDays: 30,
  logFile: 'artifacts/auto-bots/alert-manager.log',
  alertsFile: 'artifacts/auto-bots/active-alerts.json',
  thresholdsFile: 'artifacts/auto-bots/alert-thresholds.json'
};

// Alert thresholds
const defaultThresholds = {
  signoz: {
    responseTime: { warning: 1000, critical: 3000 }, // ms
    availability: { warning: 95, critical: 90 } // percentage
  },
  otelCollector: {
    responseTime: { warning: 500, critical: 2000 }, // ms
    throughput: { warning: 1000, critical: 500 } // logs/sec
  },
  system: {
    cpuUsage: { warning: 80, critical: 95 }, // percentage
    memoryUsage: { warning: 85, critical: 95 } // percentage
  },
  telemetry: {
    errorRate: { warning: 5, critical: 10 }, // percentage
    latency: { warning: 200, critical: 500 } // ms
  }
};

// Alert state tracking
let alertState = {
  activeAlerts: [],
  alertHistory: [],
  lastCheck: null,
  totalAlerts: 0,
  resolvedAlerts: 0
};

// Ensure artifacts directory exists
if (!fs.existsSync('artifacts/auto-bots')) {
  fs.mkdirSync('artifacts/auto-bots', { recursive: true });
}

// Load or create thresholds
let thresholds = defaultThresholds;
if (fs.existsSync(CONFIG.thresholdsFile)) {
  try {
    thresholds = JSON.parse(fs.readFileSync(CONFIG.thresholdsFile, 'utf8'));
  } catch (error) {
    console.log('⚠️  Could not load thresholds, using defaults');
  }
}

// HTTP helper
function makeRequest(url, options = {}, timeout = 5000) {
  return new Promise((resolve, reject) => {
    const urlObj = new URL(url);
    const client = urlObj.protocol === 'https:' ? https : http;
    
    const requestOptions = {
      hostname: urlObj.hostname,
      port: urlObj.port,
      path: urlObj.pathname + urlObj.search,
      method: options.method || 'GET',
      timeout: timeout,
      ...options
    };

    const req = client.request(requestOptions, (res) => {
      let body = '';
      res.on('data', (chunk) => body += chunk);
      res.on('end', () => {
        resolve({ 
          status: res.statusCode, 
          body,
          headers: res.headers
        });
      });
    });

    req.on('error', (error) => {
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

// Check health status
async function getHealthStatus() {
  try {
    const statusFile = 'artifacts/auto-bots/health-status.json';
    if (fs.existsSync(statusFile)) {
      return JSON.parse(fs.readFileSync(statusFile, 'utf8'));
    }
  } catch (error) {
    // Health status not available
  }
  return null;
}

// Query SigNoz metrics
async function querySigNozMetrics() {
  try {
    const response = await makeRequest(`${CONFIG.signozUrl}/api/v1/metrics`);
    if (response.status === 200) {
      return JSON.parse(response.body);
    }
  } catch (error) {
    // Metrics not available
  }
  return null;
}

// Evaluate alerts
function evaluateAlerts(healthStatus, metrics) {
  const newAlerts = [];
  const resolvedAlerts = [];
  const timestamp = new Date().toISOString();

  // Check SigNoz health
  if (healthStatus && healthStatus.signoz) {
    const signoz = healthStatus.signoz;
    
    if (signoz.responseTime > thresholds.signoz.responseTime.critical) {
      newAlerts.push({
        id: 'signoz-response-critical',
        severity: 'critical',
        service: 'SigNoz',
        metric: 'Response Time',
        value: signoz.responseTime,
        threshold: thresholds.signoz.responseTime.critical,
        message: `SigNoz response time critical: ${signoz.responseTime}ms > ${thresholds.signoz.responseTime.critical}ms`,
        timestamp
      });
    } else if (signoz.responseTime > thresholds.signoz.responseTime.warning) {
      newAlerts.push({
        id: 'signoz-response-warning',
        severity: 'warning',
        service: 'SigNoz',
        metric: 'Response Time',
        value: signoz.responseTime,
        threshold: thresholds.signoz.responseTime.warning,
        message: `SigNoz response time warning: ${signoz.responseTime}ms > ${thresholds.signoz.responseTime.warning}ms`,
        timestamp
      });
    }

    if (signoz.status !== 'healthy') {
      newAlerts.push({
        id: 'signoz-unhealthy',
        severity: 'critical',
        service: 'SigNoz',
        metric: 'Health Status',
        value: signoz.status,
        threshold: 'healthy',
        message: `SigNoz health status: ${signoz.status}`,
        timestamp
      });
    }
  }

  // Check OTel Collector health
  if (healthStatus && healthStatus.otelCollector) {
    const otel = healthStatus.otelCollector;
    
    if (otel.responseTime > thresholds.otelCollector.responseTime.critical) {
      newAlerts.push({
        id: 'otel-response-critical',
        severity: 'critical',
        service: 'OTel Collector',
        metric: 'Response Time',
        value: otel.responseTime,
        threshold: thresholds.otelCollector.responseTime.critical,
        message: `OTel Collector response time critical: ${otel.responseTime}ms > ${thresholds.otelCollector.responseTime.critical}ms`,
        timestamp
      });
    } else if (otel.responseTime > thresholds.otelCollector.responseTime.warning) {
      newAlerts.push({
        id: 'otel-response-warning',
        severity: 'warning',
        service: 'OTel Collector',
        metric: 'Response Time',
        value: otel.responseTime,
        threshold: thresholds.otelCollector.responseTime.warning,
        message: `OTel Collector response time warning: ${otel.responseTime}ms > ${thresholds.otelCollector.responseTime.warning}ms`,
        timestamp
      });
    }

    if (otel.status !== 'healthy') {
      newAlerts.push({
        id: 'otel-unhealthy',
        severity: 'critical',
        service: 'OTel Collector',
        metric: 'Health Status',
        value: otel.status,
        threshold: 'healthy',
        message: `OTel Collector health status: ${otel.status}`,
        timestamp
      });
    }
  }

  // Check system health
  if (healthStatus && healthStatus.system) {
    const system = healthStatus.system;
    
    if (system.cpuUsage > thresholds.system.cpuUsage.critical) {
      newAlerts.push({
        id: 'system-cpu-critical',
        severity: 'critical',
        service: 'System',
        metric: 'CPU Usage',
        value: system.cpuUsage,
        threshold: thresholds.system.cpuUsage.critical,
        message: `System CPU usage critical: ${system.cpuUsage.toFixed(1)}% > ${thresholds.system.cpuUsage.critical}%`,
        timestamp
      });
    } else if (system.cpuUsage > thresholds.system.cpuUsage.warning) {
      newAlerts.push({
        id: 'system-cpu-warning',
        severity: 'warning',
        service: 'System',
        metric: 'CPU Usage',
        value: system.cpuUsage,
        threshold: thresholds.system.cpuUsage.warning,
        message: `System CPU usage warning: ${system.cpuUsage.toFixed(1)}% > ${thresholds.system.cpuUsage.warning}%`,
        timestamp
      });
    }

    if (system.memoryUsage > thresholds.system.memoryUsage.critical) {
      newAlerts.push({
        id: 'system-memory-critical',
        severity: 'critical',
        service: 'System',
        metric: 'Memory Usage',
        value: system.memoryUsage,
        threshold: thresholds.system.memoryUsage.critical,
        message: `System memory usage critical: ${system.memoryUsage.toFixed(1)}% > ${thresholds.system.memoryUsage.critical}%`,
        timestamp
      });
    } else if (system.memoryUsage > thresholds.system.memoryUsage.warning) {
      newAlerts.push({
        id: 'system-memory-warning',
        severity: 'warning',
        service: 'System',
        metric: 'Memory Usage',
        value: system.memoryUsage,
        threshold: thresholds.system.memoryUsage.warning,
        message: `System memory usage warning: ${system.memoryUsage.toFixed(1)}% > ${thresholds.system.memoryUsage.warning}%`,
        timestamp
      });
    }
  }

  return { newAlerts, resolvedAlerts };
}

// Process alerts
function processAlerts(newAlerts, resolvedAlerts) {
  const timestamp = new Date().toISOString();

  // Add new alerts
  newAlerts.forEach(alert => {
    const existingIndex = alertState.activeAlerts.findIndex(a => a.id === alert.id);
    if (existingIndex === -1) {
      alertState.activeAlerts.push(alert);
      alertState.totalAlerts++;
      console.log(`🚨 NEW ALERT [${alert.severity.toUpperCase()}] ${alert.message}`);
    }
  });

  // Remove resolved alerts
  resolvedAlerts.forEach(alert => {
    const index = alertState.activeAlerts.findIndex(a => a.id === alert.id);
    if (index !== -1) {
      const resolvedAlert = { ...alertState.activeAlerts[index], resolvedAt: timestamp };
      alertState.alertHistory.push(resolvedAlert);
      alertState.activeAlerts.splice(index, 1);
      alertState.resolvedAlerts++;
      console.log(`✅ RESOLVED ALERT: ${alert.message}`);
    }
  });

  // Update last check
  alertState.lastCheck = timestamp;
}

// Log alert status
function logAlertStatus() {
  const timestamp = new Date().toISOString();
  const logEntry = {
    timestamp,
    activeAlerts: alertState.activeAlerts.length,
    totalAlerts: alertState.totalAlerts,
    resolvedAlerts: alertState.resolvedAlerts,
    alerts: alertState.activeAlerts
  };

  // Append to log file
  fs.appendFileSync(CONFIG.logFile, JSON.stringify(logEntry) + '\n');
  
  // Update alerts file
  fs.writeFileSync(CONFIG.alertsFile, JSON.stringify(alertState, null, 2));
  
  // Console output
  const alertCount = alertState.activeAlerts.length;
  const criticalCount = alertState.activeAlerts.filter(a => a.severity === 'critical').length;
  const warningCount = alertState.activeAlerts.filter(a => a.severity === 'warning').length;
  
  if (alertCount === 0) {
    console.log(`[${timestamp}] ✅ No active alerts`);
  } else {
    console.log(`[${timestamp}] 🚨 ${alertCount} active alerts (${criticalCount} critical, ${warningCount} warning)`);
  }
}

// Main alert monitoring loop
async function runAlertMonitoring() {
  console.log('🤖 Auto Alert Manager Bot Starting...');
  console.log('=====================================');
  console.log(`📊 SigNoz: ${CONFIG.signozUrl}`);
  console.log(`⏱️  Check Interval: ${CONFIG.alertInterval / 1000} seconds`);
  console.log(`📋 Thresholds loaded from: ${CONFIG.thresholdsFile}`);
  console.log('');

  // Initial alert check
  const healthStatus = await getHealthStatus();
  const metrics = await querySigNozMetrics();
  const { newAlerts, resolvedAlerts } = evaluateAlerts(healthStatus, metrics);
  processAlerts(newAlerts, resolvedAlerts);
  logAlertStatus();

  // Start monitoring loop
  const alertInterval = setInterval(async () => {
    const healthStatus = await getHealthStatus();
    const metrics = await querySigNozMetrics();
    const { newAlerts, resolvedAlerts } = evaluateAlerts(healthStatus, metrics);
    processAlerts(newAlerts, resolvedAlerts);
    logAlertStatus();
  }, CONFIG.alertInterval);

  // Keep running
  process.on('SIGINT', () => {
    console.log('\n🤖 Auto Alert Manager Bot shutting down...');
    clearInterval(alertInterval);
    
    // Final status report
    const finalReport = {
      shutdown: new Date().toISOString(),
      totalAlerts: alertState.totalAlerts,
      resolvedAlerts: alertState.resolvedAlerts,
      activeAlerts: alertState.activeAlerts.length,
      alertHistory: alertState.alertHistory
    };
    
    fs.writeFileSync('artifacts/auto-bots/alert-manager-shutdown.json', JSON.stringify(finalReport, null, 2));
    console.log('📋 Final report saved to artifacts/auto-bots/alert-manager-shutdown.json');
    process.exit(0);
  });

  // Keep process alive
  console.log('🤖 Auto Alert Manager Bot running... (Press Ctrl+C to stop)');
}

// Start the bot
runAlertMonitoring().catch(error => {
  console.error('💥 Auto Alert Manager Bot failed:', error.message);
  process.exit(1);
});
