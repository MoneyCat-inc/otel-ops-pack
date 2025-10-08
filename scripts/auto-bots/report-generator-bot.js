#!/usr/bin/env node

/**
 * Auto Report Generator Bot
 * BossCat OEM - Automated Report Generation System
 * Generates comprehensive reports on observability platform status
 */

const http = require('http');
const https = require('https');
const fs = require('fs');
const path = require('path');

// Configuration
const CONFIG = {
  signozUrl: 'http://localhost:8080',
  reportInterval: 900000, // 15 minutes
  dailyReportTime: '06:00', // 6 AM daily
  logFile: 'artifacts/auto-bots/report-generator.log',
  reportsDir: 'artifacts/auto-bots/reports'
};

// Report generation state
let reportState = {
  reportsGenerated: 0,
  lastReport: null,
  startTime: new Date().toISOString()
};

// Ensure artifacts directory exists
if (!fs.existsSync('artifacts/auto-bots')) {
  fs.mkdirSync('artifacts/auto-bots', { recursive: true });
}

if (!fs.existsSync(CONFIG.reportsDir)) {
  fs.mkdirSync(CONFIG.reportsDir, { recursive: true });
}

// HTTP helper
function makeRequest(url, options = {}, timeout = 10000) {
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

// Collect health data
async function collectHealthData() {
  const healthData = {
    timestamp: new Date().toISOString(),
    signoz: {},
    otelCollector: {},
    windowsCollector: {},
    system: {}
  };

  try {
    // Read health status from health monitor bot
    const healthStatusFile = 'artifacts/auto-bots/health-status.json';
    if (fs.existsSync(healthStatusFile)) {
      const healthStatus = JSON.parse(fs.readFileSync(healthStatusFile, 'utf8'));
      healthData.signoz = healthStatus.signoz || {};
      healthData.otelCollector = healthStatus.otelCollector || {};
      healthData.windowsCollector = healthStatus.windowsCollector || {};
      healthData.system = healthStatus.system || {};
    }
  } catch (error) {
    console.log('⚠️  Could not read health status file');
  }

  return healthData;
}

// Collect alert data
async function collectAlertData() {
  const alertData = {
    timestamp: new Date().toISOString(),
    activeAlerts: [],
    alertHistory: []
  };

  try {
    // Read alerts from alert manager bot
    const alertsFile = 'artifacts/auto-bots/active-alerts.json';
    if (fs.existsSync(alertsFile)) {
      const alertState = JSON.parse(fs.readFileSync(alertsFile, 'utf8'));
      alertData.activeAlerts = alertState.activeAlerts || [];
      alertData.alertHistory = alertState.alertHistory || [];
    }
  } catch (error) {
    console.log('⚠️  Could not read alerts file');
  }

  return alertData;
}

// Collect SigNoz data
async function collectSigNozData() {
  const signozData = {
    timestamp: new Date().toISOString(),
    health: 'unknown',
    metrics: [],
    services: [],
    logs: []
  };

  try {
    // Get SigNoz health
    const healthResponse = await makeRequest(`${CONFIG.signozUrl}/api/v1/health`);
    signozData.health = healthResponse.status === 200 ? 'healthy' : 'unhealthy';

    // Get metrics
    const metricsResponse = await makeRequest(`${CONFIG.signozUrl}/api/v1/metrics`);
    if (metricsResponse.status === 200) {
      const metrics = JSON.parse(metricsResponse.body);
      signozData.metrics = metrics.metrics || [];
    }

    // Get recent logs (if API available)
    try {
      const logsResponse = await makeRequest(`${CONFIG.signozUrl}/api/v1/logs`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ limit: 100, order: 'desc' })
      });
      if (logsResponse.status === 200) {
        const logs = JSON.parse(logsResponse.body);
        signozData.logs = logs.logs || [];
      }
    } catch (error) {
      // Logs API may not be available
    }

  } catch (error) {
    console.log(`⚠️  Could not collect SigNoz data: ${error.message}`);
  }

  return signozData;
}

// Generate comprehensive report
async function generateReport() {
  const timestamp = new Date().toISOString();
  const reportDate = new Date().toISOString().split('T')[0];

  console.log(`📊 Generating comprehensive report for ${reportDate}...`);

  try {
    // Collect all data
    const healthData = await collectHealthData();
    const alertData = await collectAlertData();
    const signozData = await collectSigNozData();

    // Generate report
    const report = {
      metadata: {
        generatedAt: timestamp,
        reportDate: reportDate,
        reportType: 'comprehensive',
        version: '1.0'
      },
      summary: {
        overallStatus: healthData.signoz.status === 'healthy' ? 'healthy' : 'degraded',
        activeAlerts: alertData.activeAlerts.length,
        criticalAlerts: alertData.activeAlerts.filter(a => a.severity === 'critical').length,
        warningAlerts: alertData.activeAlerts.filter(a => a.severity === 'warning').length,
        metricsCount: signozData.metrics.length,
        logsCount: signozData.logs.length
      },
      health: healthData,
      alerts: alertData,
      signoz: signozData,
      recommendations: generateRecommendations(healthData, alertData, signozData)
    };

    // Save report
    const reportFile = path.join(CONFIG.reportsDir, `report-${reportDate}.json`);
    fs.writeFileSync(reportFile, JSON.stringify(report, null, 2));

    // Generate markdown summary
    const markdownReport = generateMarkdownReport(report);
    const markdownFile = path.join(CONFIG.reportsDir, `report-${reportDate}.md`);
    fs.writeFileSync(markdownFile, markdownReport);

    reportState.reportsGenerated++;
    reportState.lastReport = timestamp;

    console.log(`✅ Report generated: ${reportFile}`);
    console.log(`📋 Markdown summary: ${markdownFile}`);

    return report;

  } catch (error) {
    console.log(`❌ Report generation failed: ${error.message}`);
    return null;
  }
}

// Generate recommendations
function generateRecommendations(healthData, alertData, signozData) {
  const recommendations = [];

  // Health recommendations
  if (healthData.signoz.status !== 'healthy') {
    recommendations.push({
      priority: 'high',
      category: 'health',
      issue: 'SigNoz health status is not healthy',
      recommendation: 'Check SigNoz logs and restart if necessary'
    });
  }

  if (healthData.otelCollector.status !== 'healthy') {
    recommendations.push({
      priority: 'high',
      category: 'health',
      issue: 'OTel Collector health status is not healthy',
      recommendation: 'Check OTel Collector configuration and restart service'
    });
  }

  // Alert recommendations
  const criticalAlerts = alertData.activeAlerts.filter(a => a.severity === 'critical');
  if (criticalAlerts.length > 0) {
    recommendations.push({
      priority: 'critical',
      category: 'alerts',
      issue: `${criticalAlerts.length} critical alerts active`,
      recommendation: 'Review and resolve critical alerts immediately'
    });
  }

  const warningAlerts = alertData.activeAlerts.filter(a => a.severity === 'warning');
  if (warningAlerts.length > 3) {
    recommendations.push({
      priority: 'medium',
      category: 'alerts',
      issue: `${warningAlerts.length} warning alerts active`,
      recommendation: 'Review warning alerts and adjust thresholds if necessary'
    });
  }

  // Performance recommendations
  if (healthData.system.cpuUsage > 80) {
    recommendations.push({
      priority: 'medium',
      category: 'performance',
      issue: `High CPU usage: ${healthData.system.cpuUsage.toFixed(1)}%`,
      recommendation: 'Monitor system resources and consider scaling'
    });
  }

  if (healthData.system.memoryUsage > 85) {
    recommendations.push({
      priority: 'medium',
      category: 'performance',
      issue: `High memory usage: ${healthData.system.memoryUsage.toFixed(1)}%`,
      recommendation: 'Monitor memory usage and consider cleanup or scaling'
    });
  }

  return recommendations;
}

// Generate markdown report
function generateMarkdownReport(report) {
  const { metadata, summary, health, alerts, recommendations } = report;

  let markdown = `# Observability Platform Report\n\n`;
  markdown += `**Generated:** ${metadata.generatedAt}\n`;
  markdown += `**Report Date:** ${metadata.reportDate}\n`;
  markdown += `**Report Type:** ${metadata.reportType}\n\n`;

  // Summary
  markdown += `## Summary\n\n`;
  markdown += `- **Overall Status:** ${summary.overallStatus}\n`;
  markdown += `- **Active Alerts:** ${summary.activeAlerts} (${summary.criticalAlerts} critical, ${summary.warningAlerts} warning)\n`;
  markdown += `- **Metrics Count:** ${summary.metricsCount}\n`;
  markdown += `- **Logs Count:** ${summary.logsCount}\n\n`;

  // Health Status
  markdown += `## Health Status\n\n`;
  markdown += `| Service | Status | Response Time | Last Check |\n`;
  markdown += `|---------|--------|---------------|------------|\n`;
  markdown += `| SigNoz | ${health.signoz.status} | ${health.signoz.responseTime}ms | ${health.signoz.lastCheck} |\n`;
  markdown += `| OTel Collector | ${health.otelCollector.status} | ${health.otelCollector.responseTime}ms | ${health.otelCollector.lastCheck} |\n`;
  markdown += `| Windows Collector | ${health.windowsCollector.status} | ${health.windowsCollector.responseTime}ms | ${health.windowsCollector.lastCheck} |\n`;
  markdown += `| System | ${health.system.status} | - | ${health.system.lastCheck} |\n\n`;

  // Active Alerts
  if (alerts.activeAlerts.length > 0) {
    markdown += `## Active Alerts\n\n`;
    markdown += `| Severity | Service | Metric | Value | Threshold | Message |\n`;
    markdown += `|----------|---------|--------|-------|-----------|----------|\n`;
    
    alerts.activeAlerts.forEach(alert => {
      markdown += `| ${alert.severity} | ${alert.service} | ${alert.metric} | ${alert.value} | ${alert.threshold} | ${alert.message} |\n`;
    });
    markdown += `\n`;
  }

  // Recommendations
  if (recommendations.length > 0) {
    markdown += `## Recommendations\n\n`;
    recommendations.forEach(rec => {
      markdown += `### ${rec.priority.toUpperCase()} - ${rec.category}\n`;
      markdown += `**Issue:** ${rec.issue}\n\n`;
      markdown += `**Recommendation:** ${rec.recommendation}\n\n`;
    });
  }

  return markdown;
}

// Log report status
function logReportStatus(reportResult) {
  const timestamp = new Date().toISOString();
  const logEntry = {
    timestamp,
    reportGenerated: reportResult !== null,
    state: {
      reportsGenerated: reportState.reportsGenerated,
      lastReport: reportState.lastReport
    }
  };

  // Append to log file
  fs.appendFileSync(CONFIG.logFile, JSON.stringify(logEntry) + '\n');
}

// Main report generation loop
async function runReportGeneration() {
  console.log('🤖 Auto Report Generator Bot Starting...');
  console.log('=========================================');
  console.log(`📊 SigNoz: ${CONFIG.signozUrl}`);
  console.log(`⏱️  Report Interval: ${CONFIG.reportInterval / 60000} minutes`);
  console.log(`📋 Reports Directory: ${CONFIG.reportsDir}`);
  console.log('');

  // Initial report
  const initialReport = await generateReport();
  logReportStatus(initialReport);

  // Start report loop
  const reportInterval = setInterval(async () => {
    const reportResult = await generateReport();
    logReportStatus(reportResult);
  }, CONFIG.reportInterval);

  // Keep running
  process.on('SIGINT', () => {
    console.log('\n🤖 Auto Report Generator Bot shutting down...');
    clearInterval(reportInterval);
    
    // Final status report
    const finalReport = {
      shutdown: new Date().toISOString(),
      startTime: reportState.startTime,
      reportsGenerated: reportState.reportsGenerated,
      uptime: Date.now() - new Date(reportState.startTime).getTime()
    };
    
    fs.writeFileSync('artifacts/auto-bots/report-generator-shutdown.json', JSON.stringify(finalReport, null, 2));
    console.log('📋 Final report saved to artifacts/auto-bots/report-generator-shutdown.json');
    process.exit(0);
  });

  // Keep process alive
  console.log('🤖 Auto Report Generator Bot running... (Press Ctrl+C to stop)');
}

// Start the bot
runReportGeneration().catch(error => {
  console.error('💥 Auto Report Generator Bot failed:', error.message);
  process.exit(1);
});
