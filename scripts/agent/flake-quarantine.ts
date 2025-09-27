#!/usr/bin/env node
/**
 * Flake Quarantine Agent
 * Detects and quarantines flaky tests based on failure patterns
 * Part of the observability infrastructure
 */

import * as fs from 'fs/promises';
import * as path from 'path';
import { spawn } from 'child_process';

// Initialize OpenTelemetry if enabled
if (process.env.OTEL_ENABLED !== '0') {
  try {
    const { initializeOTel } = require('./otel');
    // Initialize OTel in background
    initializeOTel().catch((error: Error) => {
      console.warn('OTel initialization failed:', error.message);
    });
  } catch (error) {
    console.warn('Failed to load OTel module:', error);
  }
}

interface FlakeReport {
  testId: string;
  suite: string;
  browser: string;
  branch: string;
  failures: number;
  totalRuns: number;
  failureRate: number;
  firstSeen: string;
  lastSeen: string;
  reason: string;
  status: 'active' | 'quarantined' | 'rehabilitated';
}

interface TestResult {
  testId: string;
  suite: string;
  browser: string;
  branch: string;
  status: 'passed' | 'failed' | 'skipped';
  duration: number;
  timestamp: string;
  error?: string;
}

class FlakeQuarantineAgent {
  private flakeThreshold = 0.3; // 30% failure rate threshold
  private minRuns = 5; // Minimum runs before considering flaky
  private quarantineFile = '.agent/flake-quarantine.json';
  private reportsFile = '.artifacts/flake-report.json';

  constructor() {
    this.loadConfiguration();
  }

  private async loadConfiguration(): Promise<void> {
    try {
      const configPath = '.agent/config.json';
      const configData = await fs.readFile(configPath, 'utf-8');
      const config = JSON.parse(configData);
      
      // Override defaults from config if available
      if (config.flake_quarantine) {
        this.flakeThreshold = config.flake_quarantine.threshold || this.flakeThreshold;
        this.minRuns = config.flake_quarantine.min_runs || this.minRuns;
      }
    } catch (error) {
      console.warn('Could not load flake quarantine config, using defaults');
    }
  }

  private async loadQuarantineData(): Promise<FlakeReport[]> {
    try {
      const data = await fs.readFile(this.quarantineFile, 'utf-8');
      return JSON.parse(data);
    } catch {
      return [];
    }
  }

  private async saveQuarantineData(data: FlakeReport[]): Promise<void> {
    await fs.mkdir(path.dirname(this.quarantineFile), { recursive: true });
    await fs.writeFile(this.quarantineFile, JSON.stringify(data, null, 2));
  }

  private async loadTestResults(): Promise<TestResult[]> {
    try {
      const data = await fs.readFile(this.reportsFile, 'utf-8');
      return JSON.parse(data);
    } catch {
      return [];
    }
  }

  private generateTestId(suite: string, testName: string, browser: string): string {
    // Create a stable test ID from suite, test name, and browser
    const combined = `${suite}:${testName}:${browser}`;
    // Use a simple hash for stability
    let hash = 0;
    for (let i = 0; i < combined.length; i++) {
      const char = combined.charCodeAt(i);
      hash = ((hash << 5) - hash) + char;
      hash = hash & hash; // Convert to 32-bit integer
    }
    return `test_${Math.abs(hash).toString(36)}`;
  }

  private async detectFlakes(): Promise<FlakeReport[]> {
    const testResults = await this.loadTestResults();
    const flakeMap = new Map<string, FlakeReport>();

    // Group results by test ID
    for (const result of testResults) {
      const testId = this.generateTestId(result.suite, result.testId, result.browser);
      
      if (!flakeMap.has(testId)) {
        flakeMap.set(testId, {
          testId,
          suite: result.suite,
          browser: result.browser,
          branch: result.branch,
          failures: 0,
          totalRuns: 0,
          failureRate: 0,
          firstSeen: result.timestamp,
          lastSeen: result.timestamp,
          reason: '',
          status: 'active'
        });
      }

      const report = flakeMap.get(testId)!;
      report.totalRuns++;
      report.lastSeen = result.timestamp;

      if (result.status === 'failed') {
        report.failures++;
      }

      // Update first seen if this is earlier
      if (new Date(result.timestamp) < new Date(report.firstSeen)) {
        report.firstSeen = result.timestamp;
      }
    }

    // Calculate failure rates and identify flakes
    const flakes: FlakeReport[] = [];
    
    for (const report of flakeMap.values()) {
      report.failureRate = report.failures / report.totalRuns;
      
      if (report.totalRuns >= this.minRuns && report.failureRate >= this.flakeThreshold) {
        report.reason = `High failure rate: ${(report.failureRate * 100).toFixed(1)}% (${report.failures}/${report.totalRuns})`;
        flakes.push(report);
        
        // Record flake detection metrics
        if (process.env.OTEL_ENABLED !== '0') {
          try {
            const { recordFlakeDetected } = require('./otel');
            recordFlakeDetected(
              report.testId,
              report.suite,
              report.browser,
              report.branch,
              report.reason
            );
          } catch (otelError) {
            // Ignore OTel errors
          }
        }
      }
    }

    return flakes;
  }

  private async quarantineFlake(report: FlakeReport): Promise<void> {
    const quarantineData = await this.loadQuarantineData();
    
    // Check if already quarantined
    const existing = quarantineData.find(q => q.testId === report.testId);
    if (existing && existing.status === 'quarantined') {
      return; // Already quarantined
    }

    // Add or update quarantine entry
    const quarantineEntry: FlakeReport = {
      ...report,
      status: 'quarantined'
    };

    if (existing) {
      Object.assign(existing, quarantineEntry);
    } else {
      quarantineData.push(quarantineEntry);
    }

    await this.saveQuarantineData(quarantineData);

    // Record quarantine metrics
    if (process.env.OTEL_ENABLED !== '0') {
      try {
        const { recordFlakeQuarantined } = require('./otel');
        recordFlakeQuarantined(
          report.testId,
          report.suite,
          report.browser,
          report.branch
        );
      } catch (otelError) {
        // Ignore OTel errors
      }
    }

    console.log(`🔒 Quarantined flaky test: ${report.testId} (${report.suite}:${report.browser})`);
  }

  private async updateTestFiles(): Promise<void> {
    const quarantineData = await this.loadQuarantineData();
    const quarantinedTests = quarantineData.filter(q => q.status === 'quarantined');

    // This would typically update test files to add @flaky tags
    // For now, we'll create a summary file
    const summary = {
      timestamp: new Date().toISOString(),
      quarantinedCount: quarantinedTests.length,
      tests: quarantinedTests.map(t => ({
        testId: t.testId,
        suite: t.suite,
        browser: t.browser,
        failureRate: t.failureRate,
        reason: t.reason
      }))
    };

    await fs.mkdir('.agent', { recursive: true });
    await fs.writeFile('.agent/quarantine-summary.json', JSON.stringify(summary, null, 2));
    
    console.log(`📋 Updated quarantine summary: ${quarantinedTests.length} tests quarantined`);
  }

  private async checkRehabilitation(): Promise<void> {
    const quarantineData = await this.loadQuarantineData();
    const quarantinedTests = quarantineData.filter(q => q.status === 'quarantined');
    
    for (const test of quarantinedTests) {
      // Check if test has been stable recently
      const testResults = await this.loadTestResults();
      const recentResults = testResults
        .filter(r => {
          const testId = this.generateTestId(r.suite, r.testId, r.browser);
          return testId === test.testId && 
                 new Date(r.timestamp) > new Date(Date.now() - 7 * 24 * 60 * 60 * 1000); // Last 7 days
        });

      if (recentResults.length >= 5) {
        const recentFailures = recentResults.filter(r => r.status === 'failed').length;
        const recentFailureRate = recentFailures / recentResults.length;

        if (recentFailureRate < this.flakeThreshold * 0.5) { // 50% of threshold for rehabilitation
          test.status = 'rehabilitated';
          
          // Record rehabilitation metrics
          if (process.env.OTEL_ENABLED !== '0') {
            try {
              const { recordFlakeRehabilitated } = require('./otel');
              recordFlakeRehabilitated(
                test.testId,
                test.suite,
                test.browser,
                test.branch
              );
            } catch (otelError) {
              // Ignore OTel errors
            }
          }

          console.log(`✅ Rehabilitated test: ${test.testId} (recent failure rate: ${(recentFailureRate * 100).toFixed(1)}%)`);
        }
      }
    }

    await this.saveQuarantineData(quarantineData);
  }

  public async run(): Promise<void> {
    console.log('🔍 Starting flake quarantine analysis...');
    
    try {
      // Detect flaky tests
      const flakes = await this.detectFlakes();
      console.log(`🎯 Detected ${flakes.length} flaky tests`);

      // Quarantine detected flakes
      for (const flake of flakes) {
        await this.quarantineFlake(flake);
      }

      // Check for rehabilitation
      await this.checkRehabilitation();

      // Update test files
      await this.updateTestFiles();

      console.log('✅ Flake quarantine analysis complete');
      
    } catch (error) {
      console.error('❌ Flake quarantine analysis failed:', error);
      throw error;
    }
  }
}

// CLI interface
async function main() {
  const agent = new FlakeQuarantineAgent();
  
  try {
    await agent.run();
  } catch (error) {
    console.error('Flake quarantine failed:', error);
    process.exit(1);
  }
}

if (require.main === module) {
  main();
}

export { FlakeQuarantineAgent };
