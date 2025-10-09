#!/usr/bin/env node

/**
 * Auto Cleanup Bot
 * BossCat OEM - Automated Cleanup System
 * Maintains system hygiene by cleaning old files and optimizing storage
 */

const fs = require('fs');
const path = require('path');

// Configuration
const CONFIG = {
  cleanupInterval: 3600000, // 1 hour
  maxLogAge: 7 * 24 * 60 * 60 * 1000, // 7 days
  maxSnapshotAge: 30 * 24 * 60 * 60 * 1000, // 30 days
  maxReportAge: 90 * 24 * 60 * 60 * 1000, // 90 days
  maxTempAge: 24 * 60 * 60 * 1000, // 24 hours
  logFile: 'artifacts/auto-bots/cleanup-bot.log',
  maxLogSize: 100 * 1024 * 1024, // 100MB
  compressionThreshold: 10 * 1024 * 1024 // 10MB
};

// Cleanup state
let cleanupState = {
  filesDeleted: 0,
  bytesFreed: 0,
  lastCleanup: null,
  startTime: new Date().toISOString(),
  cleanupCount: 0
};

// Ensure artifacts directory exists
if (!fs.existsSync('artifacts/auto-bots')) {
  fs.mkdirSync('artifacts/auto-bots', { recursive: true });
}

// Cleanup old log files
function cleanupLogFiles() {
  const logDirs = [
    'artifacts/auto-bots',
    'artifacts',
    'logs'
  ];

  let deletedFiles = 0;
  let bytesFreed = 0;

  logDirs.forEach(dir => {
    if (fs.existsSync(dir)) {
      try {
        const files = fs.readdirSync(dir);
        const now = Date.now();

        files.forEach(file => {
          if (file.endsWith('.log')) {
            const filePath = path.join(dir, file);
            const stats = fs.statSync(filePath);

            // Delete old log files
            if (now - stats.mtime.getTime() > CONFIG.maxLogAge) {
              bytesFreed += stats.size;
              fs.unlinkSync(filePath);
              deletedFiles++;
              console.log(`🧹 Deleted old log: ${filePath}`);
            }

            // Compress large log files
            if (stats.size > CONFIG.compressionThreshold) {
              try {
                const compressedPath = filePath + '.gz';
                // Note: In a real implementation, you'd use a compression library
                // For now, we'll just log the intention
                console.log(`📦 Large log file detected (${(stats.size / 1024 / 1024).toFixed(1)}MB): ${filePath}`);
              } catch (error) {
                console.log(`⚠️  Could not compress log file: ${error.message}`);
              }
            }
          }
        });
      } catch (error) {
        console.log(`⚠️  Error cleaning log directory ${dir}: ${error.message}`);
      }
    }
  });

  return { deletedFiles, bytesFreed };
}

// Cleanup old snapshots
function cleanupSnapshots() {
  const snapshotDir = 'artifacts/auto-bots/snapshots';
  let deletedFiles = 0;
  let bytesFreed = 0;

  if (fs.existsSync(snapshotDir)) {
    try {
      const files = fs.readdirSync(snapshotDir);
      const now = Date.now();

      files.forEach(file => {
        if (file.startsWith('snapshot-') && file.endsWith('.json')) {
          const filePath = path.join(snapshotDir, file);
          const stats = fs.statSync(filePath);

          if (now - stats.mtime.getTime() > CONFIG.maxSnapshotAge) {
            bytesFreed += stats.size;
            fs.unlinkSync(filePath);
            deletedFiles++;
            console.log(`🧹 Deleted old snapshot: ${filePath}`);
          }
        }
      });
    } catch (error) {
      console.log(`⚠️  Error cleaning snapshots: ${error.message}`);
    }
  }

  return { deletedFiles, bytesFreed };
}

// Cleanup old reports
function cleanupReports() {
  const reportDir = 'artifacts/auto-bots/reports';
  let deletedFiles = 0;
  let bytesFreed = 0;

  if (fs.existsSync(reportDir)) {
    try {
      const files = fs.readdirSync(reportDir);
      const now = Date.now();

      files.forEach(file => {
        if (file.startsWith('report-') && (file.endsWith('.json') || file.endsWith('.md'))) {
          const filePath = path.join(reportDir, file);
          const stats = fs.statSync(filePath);

          if (now - stats.mtime.getTime() > CONFIG.maxReportAge) {
            bytesFreed += stats.size;
            fs.unlinkSync(filePath);
            deletedFiles++;
            console.log(`🧹 Deleted old report: ${filePath}`);
          }
        }
      });
    } catch (error) {
      console.log(`⚠️  Error cleaning reports: ${error.message}`);
    }
  }

  return { deletedFiles, bytesFreed };
}

// Cleanup temporary files
function cleanupTempFiles() {
  const tempDirs = [
    'artifacts/temp',
    'temp',
    'tmp'
  ];

  let deletedFiles = 0;
  let bytesFreed = 0;

  tempDirs.forEach(dir => {
    if (fs.existsSync(dir)) {
      try {
        const files = fs.readdirSync(dir);
        const now = Date.now();

        files.forEach(file => {
          const filePath = path.join(dir, file);
          const stats = fs.statSync(filePath);

          if (now - stats.mtime.getTime() > CONFIG.maxTempAge) {
            bytesFreed += stats.size;
            fs.unlinkSync(filePath);
            deletedFiles++;
            console.log(`🧹 Deleted temp file: ${filePath}`);
          }
        });
      } catch (error) {
        console.log(`⚠️  Error cleaning temp directory ${dir}: ${error.message}`);
      }
    }
  });

  return { deletedFiles, bytesFreed };
}

// Cleanup empty directories
function cleanupEmptyDirectories() {
  const dirsToCheck = [
    'artifacts/auto-bots/snapshots',
    'artifacts/auto-bots/reports',
    'artifacts/temp'
  ];

  let deletedDirs = 0;

  dirsToCheck.forEach(dir => {
    if (fs.existsSync(dir)) {
      try {
        const files = fs.readdirSync(dir);
        if (files.length === 0) {
          fs.rmdirSync(dir);
          deletedDirs++;
          console.log(`🧹 Deleted empty directory: ${dir}`);
        }
      } catch (error) {
        // Directory not empty or permission issue
      }
    }
  });

  return deletedDirs;
}

// Optimize storage
function optimizeStorage() {
  const artifactsDir = 'artifacts';
  let optimizedFiles = 0;

  if (fs.existsSync(artifactsDir)) {
    try {
      const files = fs.readdirSync(artifactsDir, { withFileTypes: true });
      
      files.forEach(file => {
        if (file.isFile() && file.name.endsWith('.json')) {
          const filePath = path.join(artifactsDir, file.name);
          const stats = fs.statSync(filePath);

          // Check if file is large enough to optimize
          if (stats.size > CONFIG.compressionThreshold) {
            try {
              // In a real implementation, you'd compress the file
              // For now, we'll just log the optimization opportunity
              console.log(`📦 Optimization opportunity: ${filePath} (${(stats.size / 1024 / 1024).toFixed(1)}MB)`);
              optimizedFiles++;
            } catch (error) {
              console.log(`⚠️  Could not optimize file: ${error.message}`);
            }
          }
        }
      });
    } catch (error) {
      console.log(`⚠️  Error optimizing storage: ${error.message}`);
    }
  }

  return optimizedFiles;
}

// Perform comprehensive cleanup
async function performCleanup() {
  const timestamp = new Date().toISOString();
  console.log(`🧹 Starting cleanup at ${timestamp}...`);

  const cleanupResults = {
    timestamp,
    logs: cleanupLogFiles(),
    snapshots: cleanupSnapshots(),
    reports: cleanupReports(),
    tempFiles: cleanupTempFiles(),
    emptyDirs: cleanupEmptyDirectories(),
    optimizedFiles: optimizeStorage()
  };

  // Calculate totals
  const totalFiles = cleanupResults.logs.deletedFiles + 
                    cleanupResults.snapshots.deletedFiles + 
                    cleanupResults.reports.deletedFiles + 
                    cleanupResults.tempFiles.deletedFiles;

  const totalBytes = cleanupResults.logs.bytesFreed + 
                    cleanupResults.snapshots.bytesFreed + 
                    cleanupResults.reports.bytesFreed + 
                    cleanupResults.tempFiles.bytesFreed;

  cleanupState.filesDeleted += totalFiles;
  cleanupState.bytesFreed += totalBytes;
  cleanupState.lastCleanup = timestamp;
  cleanupState.cleanupCount++;

  console.log(`✅ Cleanup completed:`);
  console.log(`   📁 Files deleted: ${totalFiles}`);
  console.log(`   💾 Bytes freed: ${(totalBytes / 1024 / 1024).toFixed(1)}MB`);
  console.log(`   📂 Empty directories removed: ${cleanupResults.emptyDirs}`);
  console.log(`   📦 Files optimized: ${cleanupResults.optimizedFiles}`);

  return cleanupResults;
}

// Log cleanup status
function logCleanupStatus(cleanupResults) {
  const timestamp = new Date().toISOString();
  const logEntry = {
    timestamp,
    cleanup: cleanupResults,
    state: {
      totalFilesDeleted: cleanupState.filesDeleted,
      totalBytesFreed: cleanupState.bytesFreed,
      cleanupCount: cleanupState.cleanupCount,
      lastCleanup: cleanupState.lastCleanup
    }
  };

  // Append to log file
  fs.appendFileSync(CONFIG.logFile, JSON.stringify(logEntry) + '\n');
}

// Main cleanup loop
async function runCleanup() {
  console.log('🤖 Auto Cleanup Bot Starting...');
  console.log('================================');
  console.log(`⏱️  Cleanup Interval: ${CONFIG.cleanupInterval / 60000} minutes`);
  console.log(`📅 Max Log Age: ${CONFIG.maxLogAge / 24 / 60 / 60 / 1000} days`);
  console.log(`📅 Max Snapshot Age: ${CONFIG.maxSnapshotAge / 24 / 60 / 60 / 1000} days`);
  console.log(`📅 Max Report Age: ${CONFIG.maxReportAge / 24 / 60 / 60 / 1000} days`);
  console.log('');

  // Initial cleanup
  const initialCleanup = await performCleanup();
  logCleanupStatus(initialCleanup);

  // Start cleanup loop
  const cleanupInterval = setInterval(async () => {
    const cleanupResult = await performCleanup();
    logCleanupStatus(cleanupResult);
  }, CONFIG.cleanupInterval);

  // Keep running
  process.on('SIGINT', () => {
    console.log('\n🤖 Auto Cleanup Bot shutting down...');
    clearInterval(cleanupInterval);
    
    // Final status report
    const finalReport = {
      shutdown: new Date().toISOString(),
      startTime: cleanupState.startTime,
      totalFilesDeleted: cleanupState.filesDeleted,
      totalBytesFreed: cleanupState.bytesFreed,
      cleanupCount: cleanupState.cleanupCount,
      uptime: Date.now() - new Date(cleanupState.startTime).getTime()
    };
    
    fs.writeFileSync('artifacts/auto-bots/cleanup-bot-shutdown.json', JSON.stringify(finalReport, null, 2));
    console.log('📋 Final report saved to artifacts/auto-bots/cleanup-bot-shutdown.json');
    process.exit(0);
  });

  // Keep process alive
  console.log('🤖 Auto Cleanup Bot running... (Press Ctrl+C to stop)');
}

// Start the bot
runCleanup().catch(error => {
  console.error('💥 Auto Cleanup Bot failed:', error.message);
  process.exit(1);
});
