#!/usr/bin/env node

/**
 * Auto Dashboard Refresh Bot
 * BossCat OEM - Automated Dashboard Refresh System
 * Periodically refreshes dashboard data and generates snapshots
 */

const http = require('http');
const https = require('https');
const fs = require('fs');
const path = require('path');

// Configuration
const CONFIG = {
  signozUrl: 'http://localhost:8080',
  dashboardServer: 'http://localhost:3000',
  refreshInterval: 120000, // 2 minutes
  snapshotInterval: 300000, // 5 minutes
  logFile: 'artifacts/auto-bots/dashboard-refresh.log',
  snapshotsDir: 'artifacts/auto-bots/snapshots'
};

// Dashboard refresh state
let refreshState = {
  lastRefresh: null,
  refreshCount: 0,
  failedRefreshes: 0,
  snapshotsGenerated: 0,
  startTime: new Date().toISOString()
};

// Ensure artifacts directory exists
if (!fs.existsSync('artifacts/auto-bots')) {
  fs.mkdirSync('artifacts/auto-bots', { recursive: true });
}

if (!fs.existsSync(CONFIG.snapshotsDir)) {
  fs.mkdirSync(CONFIG.snapshotsDir, { recursive: true });
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

// Refresh dashboard data
async function refreshDashboardData() {
  const timestamp = new Date().toISOString();
  const refreshResults = [];

  try {
    // Refresh main dashboard
    const dashboardResponse = await makeRequest(`${CONFIG.dashboardServer}/docs/dashboards/index.html`);
    refreshResults.push({
      dashboard: 'main',
      status: dashboardResponse.status,
      success: dashboardResponse.status === 200
    });

    // Refresh live metrics dashboard
    const metricsResponse = await makeRequest(`${CONFIG.dashboardServer}/docs/dashboards/live-metrics.html`);
    refreshResults.push({
      dashboard: 'live-metrics',
      status: metricsResponse.status,
      success: metricsResponse.status === 200
    });

    // Refresh stress testing dashboard
    const stressResponse = await makeRequest(`${CONFIG.dashboardServer}/docs/dashboards/stress-testing.html`);
    refreshResults.push({
      dashboard: 'stress-testing',
      status: stressResponse.status,
      success: stressResponse.status === 200
    });

    // Refresh advanced visualizations
    const vizResponse = await makeRequest(`${CONFIG.dashboardServer}/docs/dashboards/advanced-visualizations.html`);
    refreshResults.push({
      dashboard: 'advanced-visualizations',
      status: vizResponse.status,
      success: vizResponse.status === 200
    });

    const successCount = refreshResults.filter(r => r.success).length;
    const totalCount = refreshResults.length;

    if (successCount === totalCount) {
      refreshState.refreshCount++;
      console.log(`✅ Dashboard refresh successful (${successCount}/${totalCount} dashboards)`);
    } else {
      refreshState.failedRefreshes++;
      console.log(`⚠️  Dashboard refresh partial (${successCount}/${totalCount} dashboards)`);
    }

    refreshState.lastRefresh = timestamp;

    return {
      timestamp,
      success: successCount === totalCount,
      results: refreshResults
    };

  } catch (error) {
    refreshState.failedRefreshes++;
    console.log(`❌ Dashboard refresh failed: ${error.message}`);
    
    return {
      timestamp,
      success: false,
      error: error.message
    };
  }
}

// Generate dashboard snapshot
async function generateDashboardSnapshot() {
  const timestamp = new Date().toISOString();
  const snapshotData = {
    timestamp,
    signoz: {},
    dashboards: {},
    system: {}
  };

  try {
    // Get SigNoz health
    try {
      const signozResponse = await makeRequest(`${CONFIG.signozUrl}/api/v1/health`);
      snapshotData.signoz.health = signozResponse.status === 200 ? 'healthy' : 'unhealthy';
    } catch (error) {
      snapshotData.signoz.health = 'unreachable';
    }

    // Get SigNoz metrics summary
    try {
      const metricsResponse = await makeRequest(`${CONFIG.signozUrl}/api/v1/metrics`);
      if (metricsResponse.status === 200) {
        const metrics = JSON.parse(metricsResponse.body);
        snapshotData.signoz.metricsCount = metrics.metrics ? metrics.metrics.length : 0;
      }
    } catch (error) {
      snapshotData.signoz.metricsCount = 0;
    }

    // Get dashboard status
    const dashboards = [
      'index.html',
      'docs/dashboards/index.html',
      'docs/dashboards/live-metrics.html',
      'docs/dashboards/stress-testing.html',
      'docs/dashboards/advanced-visualizations.html'
    ];

    for (const dashboard of dashboards) {
      try {
        const response = await makeRequest(`${CONFIG.dashboardServer}/${dashboard}`);
        snapshotData.dashboards[dashboard] = {
          status: response.status,
          accessible: response.status === 200
        };
      } catch (error) {
        snapshotData.dashboards[dashboard] = {
          status: 'error',
          accessible: false,
          error: error.message
        };
      }
    }

    // Get system info
    const os = require('os');
    snapshotData.system = {
      platform: os.platform(),
      arch: os.arch(),
      uptime: os.uptime(),
      totalMemory: os.totalmem(),
      freeMemory: os.freemem(),
      loadAverage: os.loadavg()
    };

    // Save snapshot
    const snapshotFile = path.join(CONFIG.snapshotsDir, `snapshot-${timestamp.replace(/[:.]/g, '-')}.json`);
    fs.writeFileSync(snapshotFile, JSON.stringify(snapshotData, null, 2));

    refreshState.snapshotsGenerated++;
    console.log(`📸 Dashboard snapshot generated: ${snapshotFile}`);

    return snapshotData;

  } catch (error) {
    console.log(`❌ Snapshot generation failed: ${error.message}`);
    return null;
  }
}

// Log refresh status
function logRefreshStatus(refreshResult) {
  const timestamp = new Date().toISOString();
  const logEntry = {
    timestamp,
    refresh: refreshResult,
    state: {
      refreshCount: refreshState.refreshCount,
      failedRefreshes: refreshState.failedRefreshes,
      snapshotsGenerated: refreshState.snapshotsGenerated,
      lastRefresh: refreshState.lastRefresh
    }
  };

  // Append to log file
  fs.appendFileSync(CONFIG.logFile, JSON.stringify(logEntry) + '\n');
}

// Cleanup old snapshots
function cleanupOldSnapshots() {
  try {
    const files = fs.readdirSync(CONFIG.snapshotsDir);
    const now = Date.now();
    const maxAge = 7 * 24 * 60 * 60 * 1000; // 7 days

    let deletedCount = 0;
    files.forEach(file => {
      if (file.startsWith('snapshot-') && file.endsWith('.json')) {
        const filePath = path.join(CONFIG.snapshotsDir, file);
        const stats = fs.statSync(filePath);
        
        if (now - stats.mtime.getTime() > maxAge) {
          fs.unlinkSync(filePath);
          deletedCount++;
        }
      }
    });

    if (deletedCount > 0) {
      console.log(`🧹 Cleaned up ${deletedCount} old snapshots`);
    }
  } catch (error) {
    console.log(`⚠️  Snapshot cleanup failed: ${error.message}`);
  }
}

// Main dashboard refresh loop
async function runDashboardRefresh() {
  console.log('🤖 Auto Dashboard Refresh Bot Starting...');
  console.log('=========================================');
  console.log(`📊 SigNoz: ${CONFIG.signozUrl}`);
  console.log(`🌐 Dashboard Server: ${CONFIG.dashboardServer}`);
  console.log(`⏱️  Refresh Interval: ${CONFIG.refreshInterval / 1000} seconds`);
  console.log(`📸 Snapshot Interval: ${CONFIG.snapshotInterval / 1000} seconds`);
  console.log('');

  // Initial refresh
  const initialRefresh = await refreshDashboardData();
  logRefreshStatus(initialRefresh);

  // Start refresh loop
  const refreshInterval = setInterval(async () => {
    const refreshResult = await refreshDashboardData();
    logRefreshStatus(refreshResult);
  }, CONFIG.refreshInterval);

  // Start snapshot loop
  const snapshotInterval = setInterval(async () => {
    await generateDashboardSnapshot();
    cleanupOldSnapshots();
  }, CONFIG.snapshotInterval);

  // Keep running
  process.on('SIGINT', () => {
    console.log('\n🤖 Auto Dashboard Refresh Bot shutting down...');
    clearInterval(refreshInterval);
    clearInterval(snapshotInterval);
    
    // Final status report
    const finalReport = {
      shutdown: new Date().toISOString(),
      startTime: refreshState.startTime,
      refreshCount: refreshState.refreshCount,
      failedRefreshes: refreshState.failedRefreshes,
      snapshotsGenerated: refreshState.snapshotsGenerated,
      uptime: Date.now() - new Date(refreshState.startTime).getTime()
    };
    
    fs.writeFileSync('artifacts/auto-bots/dashboard-refresh-shutdown.json', JSON.stringify(finalReport, null, 2));
    console.log('📋 Final report saved to artifacts/auto-bots/dashboard-refresh-shutdown.json');
    process.exit(0);
  });

  // Keep process alive
  console.log('🤖 Auto Dashboard Refresh Bot running... (Press Ctrl+C to stop)');
}

// Start the bot
runDashboardRefresh().catch(error => {
  console.error('💥 Auto Dashboard Refresh Bot failed:', error.message);
  process.exit(1);
});
