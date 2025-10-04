#!/usr/bin/env node

/**
 * Error Ledger CLI Tool
 * Manages error fingerprint tracking and monetization
 */

const { readFileSync, writeFileSync, existsSync } = require('fs');
const { join } = require('path');

const LEDGER_PATH = 'docs/observability/ERROR_LEDGER.md';
const REGISTRY_PATH = '.agent/error_index.json';

/**
 * Load error registry
 */
function loadRegistry() {
    try {
        if (!existsSync(REGISTRY_PATH)) {
            return {};
        }
        return JSON.parse(readFileSync(REGISTRY_PATH, 'utf8'));
    } catch (error) {
        console.error('Failed to load error registry:', error.message);
        return {};
    }
}

/**
 * Load ledger markdown file
 */
function loadLedger() {
    try {
        if (!existsSync(LEDGER_PATH)) {
            return '';
        }
        return readFileSync(LEDGER_PATH, 'utf8');
    } catch (error) {
        console.error('Failed to load error ledger:', error.message);
        return '';
    }
}

/**
 * Update ledger with new error entry
 */
function updateLedger(fingerprint, entry, prId, note) {
    const ledger = loadLedger();
    
    // Parse existing table or create new one
    const tableMatch = ledger.match(/\| Fingerprint \| First Seen \| First PR \| Status \| Total Repeats \| Last Seen \| Resolution \|\n\|[^|]*\|[^|]*\|[^|]*\|[^|]*\|[^|]*\|[^|]*\|[^|]*\|\n([\s\S]*?)(?=\n##|\n---|$)/);
    
    let tableRows = '';
    if (tableMatch && tableMatch[2]) {
        tableRows = tableMatch[2].trim();
    }
    
    // Add new row
    const firstSeen = new Date(entry.firstSeen * 1000).toISOString().split('T')[0];
    const lastSeen = new Date(entry.lastSeen * 1000).toISOString().split('T')[0];
    const status = entry.count === 1 ? 'open' : 'tracking';
    const resolution = prId ? `PR #${prId}: ${note}` : 'TBD';
    
    const newRow = `| ${fingerprint} | ${firstSeen} | ${prId || '-'} | ${status} | ${entry.count} | ${lastSeen} | ${resolution} |\n`;
    
    // Update table
    const updatedTable = `| Fingerprint | First Seen | First PR | Status | Total Repeats | Last Seen | Resolution |
|-------------|------------|----------|--------|---------------|-----------|------------|
${tableRows}${newRow}`;
    
    // Replace table in ledger
    const updatedLedger = ledger.replace(
        /\| Fingerprint \| First Seen \| First PR \| Status \| Total Repeats \| Last Seen \| Resolution \|\n\|[^|]*\|[^|]*\|[^|]*\|[^|]*\|[^|]*\|[^|]*\|[^|]*\|\n([\s\S]*?)(?=\n##|\n---|$)/,
        updatedTable
    );
    
    // Update last modified timestamp
    const timestamp = new Date().toISOString();
    const finalLedger = updatedLedger.replace(
        /\*\*Last Updated\*\*: [^\n]*/,
        `**Last Updated**: ${timestamp}`
    );
    
    writeFileSync(LEDGER_PATH, finalLedger);
    console.log(`✅ Updated error ledger with fingerprint: ${fingerprint}`);
}

/**
 * Generate error report
 */
function generateReport(period = '7d') {
    const registry = loadRegistry();
    const now = Date.now() / 1000;
    
    let timeWindow;
    switch (period) {
        case '1d':
            timeWindow = 24 * 3600;
            break;
        case '7d':
            timeWindow = 7 * 24 * 3600;
            break;
        case '30d':
            timeWindow = 30 * 24 * 3600;
            break;
        default:
            timeWindow = 7 * 24 * 3600;
    }
    
    const recentErrors = Object.entries(registry).filter(([fp, entry]) => {
        return entry.lastSeen > (now - timeWindow);
    });
    
    const newErrors = recentErrors.filter(([fp, entry]) => entry.count === 1);
    const knownErrors = recentErrors.filter(([fp, entry]) => entry.count > 1);
    
    const totalOccurrences = recentErrors.reduce((sum, [fp, entry]) => sum + entry.count, 0);
    
    console.log(`\n📊 Error Report (Last ${period})`);
    console.log('=====================================');
    console.log(`New Errors: ${newErrors.length}`);
    console.log(`Known Errors: ${knownErrors.length}`);
    console.log(`Total Occurrences: ${totalOccurrences}`);
    console.log(`Average per Error: ${(totalOccurrences / recentErrors.length).toFixed(1)}`);
    
    if (newErrors.length > 0) {
        console.log('\n🚨 New Errors (Billable):');
        newErrors.forEach(([fp, entry]) => {
            const date = new Date(entry.firstSeen * 1000).toISOString().split('T')[0];
            console.log(`  ${fp} - ${date} - ${entry.lastMessage}`);
        });
    }
    
    if (knownErrors.length > 0) {
        console.log('\n🔄 Most Frequent Known Errors:');
        knownErrors
            .sort(([,a], [,b]) => b.count - a.count)
            .slice(0, 10)
            .forEach(([fp, entry]) => {
                console.log(`  ${fp} - ${entry.count} occurrences - ${entry.lastMessage}`);
            });
    }
}

/**
 * Check specific error status
 */
function checkError(fingerprint) {
    const registry = loadRegistry();
    const entry = registry[fingerprint];
    
    if (!entry) {
        console.log(`❌ Error fingerprint not found: ${fingerprint}`);
        return;
    }
    
    const firstSeen = new Date(entry.firstSeen * 1000).toISOString();
    const lastSeen = new Date(entry.lastSeen * 1000).toISOString();
    const age = Math.floor((Date.now() / 1000 - entry.firstSeen) / 3600);
    
    console.log(`\n🔍 Error Details: ${fingerprint}`);
    console.log('=====================================');
    console.log(`First Seen: ${firstSeen}`);
    console.log(`Last Seen: ${lastSeen}`);
    console.log(`Total Occurrences: ${entry.count}`);
    console.log(`Age: ${age} hours`);
    console.log(`Status: ${entry.count === 1 ? 'New (Billable)' : 'Known (Tracking)'}`);
    console.log(`Last Message: ${entry.lastMessage}`);
    
    if (entry.lastStack) {
        console.log(`\nLast Stack Trace:`);
        console.log(entry.lastStack.split('\n').slice(0, 5).join('\n'));
    }
}

/**
 * Main CLI handler
 */
function main() {
    const args = process.argv.slice(2);
    const command = args[0];
    
    switch (command) {
        case 'add':
            const fingerprint = args[1];
            if (!fingerprint) {
                console.error('❌ Error: Fingerprint required');
                process.exit(1);
            }
            
            const registry = loadRegistry();
            const entry = registry[fingerprint];
            if (!entry) {
                console.error(`❌ Error: Fingerprint ${fingerprint} not found in registry`);
                process.exit(1);
            }
            
            // Parse optional arguments
            let prId, note;
            for (let i = 2; i < args.length; i += 2) {
                const flag = args[i];
                const value = args[i + 1];
                if (flag === '--pr') prId = value;
                if (flag === '--note') note = value;
            }
            
            updateLedger(fingerprint, entry, prId, note);
            break;
            
        case 'report':
            const period = args[1] || '7d';
            generateReport(period);
            break;
            
        case 'check':
            const fp = args[1];
            if (!fp) {
                console.error('❌ Error: Fingerprint required');
                process.exit(1);
            }
            checkError(fp);
            break;
            
        default:
            console.log(`
🔍 Error Ledger CLI

Usage:
  node ledger-cli.js add <fingerprint> [--pr <pr-id>] [--note <description>]
  node ledger-cli.js report [<period>]     # period: 1d, 7d, 30d (default: 7d)
  node ledger-cli.js check <fingerprint>

Examples:
  node ledger-cli.js add abc123def456 --pr 123 --note "Fixed database connection timeout"
  node ledger-cli.js report 30d
  node ledger-cli.js check abc123def456
            `);
    }
}

// Run CLI if called directly
if (require.main === module) {
    main();
}
