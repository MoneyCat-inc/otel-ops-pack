#!/usr/bin/env node
/**
 * ECRR Autowiring Script
 * 
 * Automatically ingests ECRR reports and generates actionable tasks.
 * Maintains the ECRR index and task backlog.
 * 
 * Usage: node scripts/ecrr/wire.mjs
 */

import fs from 'node:fs';
import path from 'node:path';

const SPINNER = ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏'];
let spinnerIndex = 0;

function log(message, type = 'info') {
  const timestamp = new Date().toISOString();
  const prefix = type === 'error' ? '❌' : type === 'success' ? '✅' : '🔧';
  console.log(`${prefix} [${timestamp}] ${message}`);
}

function animateProgress(message, progress = 0) {
  spinnerIndex = (spinnerIndex + 1) % SPINNER.length;
  const spinner = SPINNER[spinnerIndex];
  process.stdout.write(`\r${spinner} ${message} ${progress}%`);
}

function ensureDirectory(dirPath) {
  if (!fs.existsSync(dirPath)) {
    fs.mkdirSync(dirPath, { recursive: true });
    return true;
  }
  return false;
}

function loadECRRIndex() {
  const indexPath = 'ecrr/index.json';
  if (!fs.existsSync(indexPath)) {
    return {
      items: [],
      lastUpdated: new Date().toISOString(),
      version: 1
    };
  }
  
  try {
    return JSON.parse(fs.readFileSync(indexPath, 'utf8'));
  } catch (error) {
    log(`Failed to load ECRR index: ${error.message}`, 'error');
    return {
      items: [],
      lastUpdated: new Date().toISOString(),
      version: 1
    };
  }
}

function saveECRRIndex(index) {
  const indexPath = 'ecrr/index.json';
  index.lastUpdated = new Date().toISOString();
  fs.writeFileSync(indexPath, JSON.stringify(index, null, 2));
}

function loadECRRTasks() {
  const tasksPath = 'ecrr/tasks.json';
  if (!fs.existsSync(tasksPath)) {
    return {
      backlog: [],
      completed: [],
      lastUpdated: new Date().toISOString(),
      version: 1
    };
  }
  
  try {
    return JSON.parse(fs.readFileSync(tasksPath, 'utf8'));
  } catch (error) {
    log(`Failed to load ECRR tasks: ${error.message}`, 'error');
    return {
      backlog: [],
      completed: [],
      lastUpdated: new Date().toISOString(),
      version: 1
    };
  }
}

function saveECRRTasks(tasks) {
  const tasksPath = 'ecrr/tasks.json';
  tasks.lastUpdated = new Date().toISOString();
  fs.writeFileSync(tasksPath, JSON.stringify(tasks, null, 2));
}

function scanECRRReports() {
  const reportsDir = 'ecrr/reports';
  if (!fs.existsSync(reportsDir)) {
    return [];
  }
  
  const files = fs.readdirSync(reportsDir)
    .filter(file => file.endsWith('.md'))
    .map(file => ({
      filename: file,
      path: path.join(reportsDir, file),
      mtime: fs.statSync(path.join(reportsDir, file)).mtime
    }))
    .sort((a, b) => b.mtime - a.mtime); // Most recent first
  
  return files;
}

function extractGapsFromReport(reportPath) {
  try {
    const content = fs.readFileSync(reportPath, 'utf8');
    const gaps = [];
    
    // Look for various gap patterns
    const gapPatterns = [
      /^#{2,3}\s+(Critical Gaps|Gaps|Recommendations|Issues|Problems)[:\s]*\n([\s\S]+?)(\n#+|$)/gmi,
      /^#{2,3}\s+(Action Items|Next Steps|TODOs)[:\s]*\n([\s\S]+?)(\n#+|$)/gmi,
      /^#{2,3}\s+(Risks|Concerns|Blockers)[:\s]*\n([\s\S]+?)(\n#+|$)/gmi
    ];
    
    for (const pattern of gapPatterns) {
      let match;
      while ((match = pattern.exec(content)) !== null) {
        const [, title, block] = match;
        const lines = block.split('\n')
          .map(line => line.trim())
          .filter(line => line.length > 0 && !line.startsWith('#'))
          .filter(line => line.match(/^[-*+]\s+|^\d+\.\s+|^-\s+/)); // List items
        
        for (const line of lines) {
          // Clean up the line
          const cleanLine = line.replace(/^[-*+]\s+|^\d+\.\s+|^-\s+/, '').trim();
          if (cleanLine.length > 10) { // Avoid very short items
            gaps.push({
              text: cleanLine,
              section: title,
              source: path.basename(reportPath)
            });
          }
        }
      }
    }
    
    return gaps;
  } catch (error) {
    log(`Failed to extract gaps from ${reportPath}: ${error.message}`, 'error');
    return [];
  }
}

function extractMetricsFromReport(reportPath) {
  try {
    const content = fs.readFileSync(reportPath, 'utf8');
    const metrics = {};
    
    // Extract common metrics
    const metricPatterns = [
      { pattern: /(\d+)\s*%/, key: 'percentage' },
      { pattern: /(\d+)\s*ms/, key: 'latency' },
      { pattern: /(\d+)\s*seconds?/, key: 'time' },
      { pattern: /(\d+)\s*jobs?/, key: 'jobs' },
      { pattern: /(\d+)\s*files?/, key: 'files' }
    ];
    
    for (const { pattern, key } of metricPatterns) {
      const matches = content.match(pattern);
      if (matches) {
        metrics[key] = matches.map(m => parseInt(m.match(/\d+/)[0]));
      }
    }
    
    return metrics;
  } catch (error) {
    log(`Failed to extract metrics from ${reportPath}: ${error.message}`, 'error');
    return {};
  }
}

function updateECRRIndex(reports, index) {
  const knownFiles = new Set(index.items.map(item => item.file));
  let newItems = 0;
  
  for (const report of reports) {
    if (!knownFiles.has(report.filename)) {
      const item = {
        file: report.filename,
        status: 'open',
        addedTs: Date.now(),
        mtime: report.mtime.getTime(),
        metrics: extractMetricsFromReport(report.path)
      };
      
      index.items.push(item);
      newItems++;
      log(`Added new ECRR report: ${report.filename}`, 'success');
    }
  }
  
  if (newItems > 0) {
    log(`Added ${newItems} new ECRR reports to index`, 'success');
  }
  
  return newItems;
}

function updateECRRTasks(reports, tasks) {
  let newTasks = 0;
  
  for (const report of reports) {
    const gaps = extractGapsFromReport(report.path);
    
    for (const gap of gaps) {
      // Check if task already exists
      const existingTask = tasks.backlog.find(task => 
        task.title === gap.text && task.source === gap.source
      );
      
      if (!existingTask) {
        const task = {
          id: `task_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
          title: gap.text,
          source: gap.source,
          section: gap.section,
          status: 'todo',
          priority: gap.section.toLowerCase().includes('critical') ? 'high' : 'medium',
          createdAt: Date.now(),
          assignedTo: null,
          dueDate: null,
          tags: []
        };
        
        tasks.backlog.push(task);
        newTasks++;
      }
    }
  }
  
  if (newTasks > 0) {
    log(`Generated ${newTasks} new tasks from ECRR reports`, 'success');
  }
  
  return newTasks;
}

function generateTaskSummary(tasks) {
  const summary = {
    total: tasks.backlog.length + tasks.completed.length,
    backlog: tasks.backlog.length,
    completed: tasks.completed.length,
    byPriority: {},
    bySource: {},
    byStatus: {}
  };
  
  // Count by priority
  for (const task of tasks.backlog) {
    summary.byPriority[task.priority] = (summary.byPriority[task.priority] || 0) + 1;
  }
  
  // Count by source
  for (const task of tasks.backlog) {
    summary.bySource[task.source] = (summary.bySource[task.source] || 0) + 1;
  }
  
  // Count by status
  for (const task of tasks.backlog) {
    summary.byStatus[task.status] = (summary.byStatus[task.status] || 0) + 1;
  }
  
  return summary;
}

function generateECRRReport(index, tasks) {
  const report = {
    timestamp: new Date().toISOString(),
    index: {
      totalReports: index.items.length,
      openReports: index.items.filter(item => item.status === 'open').length,
      closedReports: index.items.filter(item => item.status === 'closed').length
    },
    tasks: generateTaskSummary(tasks),
    recentReports: index.items
      .sort((a, b) => b.addedTs - a.addedTs)
      .slice(0, 5)
      .map(item => ({
        file: item.file,
        status: item.status,
        added: new Date(item.addedTs).toISOString()
      }))
  };
  
  const reportPath = 'artifacts/ecrr-wiring-report.json';
  if (!fs.existsSync('artifacts')) {
    fs.mkdirSync('artifacts', { recursive: true });
  }
  
  fs.writeFileSync(reportPath, JSON.stringify(report, null, 2));
  log(`ECRR wiring report saved to ${reportPath}`, 'success');
  
  return report;
}

async function main() {
  try {
    log('Starting ECRR autowiring...');
    
    // Ensure directories exist
    ensureDirectory('ecrr');
    ensureDirectory('ecrr/reports');
    ensureDirectory('artifacts');
    
    // Load existing data
    const index = loadECRRIndex();
    const tasks = loadECRRTasks();
    
    // Scan for reports
    const reports = scanECRRReports();
    log(`Found ${reports.length} ECRR reports`);
    
    if (reports.length === 0) {
      log('No ECRR reports found. Create some reports in ecrr/reports/ first.', 'error');
      return;
    }
    
    // Update index with new reports
    const newReports = updateECRRIndex(reports, index);
    
    // Update tasks from reports
    const newTasks = updateECRRTasks(reports, tasks);
    
    // Save updated data
    saveECRRIndex(index);
    saveECRRTasks(tasks);
    
    // Generate summary report
    const report = generateECRRReport(index, tasks);
    
    log('ECRR autowiring complete!', 'success');
    log(`Index: ${index.items.length} reports, ${newReports} new`);
    log(`Tasks: ${tasks.backlog.length} backlog, ${newTasks} new`);
    log(`Completed: ${tasks.completed.length} tasks`);
    
    // Show task summary
    if (tasks.backlog.length > 0) {
      log('Top priority tasks:');
      const highPriorityTasks = tasks.backlog
        .filter(task => task.priority === 'high')
        .slice(0, 3);
      
      for (const task of highPriorityTasks) {
        log(`  - ${task.title} (from ${task.source})`);
      }
    }
    
  } catch (error) {
    log(`ECRR autowiring failed: ${error.message}`, 'error');
    process.exit(1);
  }
}

main();
