#!/usr/bin/env node
/**
 * Flake Status Gauges Emitter
 * Emits nightly flake status metrics for observability
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

interface TestManifest {
  testId: string;
  suite: string;
  browser: string;
  branch: string;
  filePath: string;
  testName: string;
  isFlaky: boolean;
  firstFlakySeen?: string;
  lastFlakySeen?: string;
}

class FlakeGaugesEmitter {
  private quarantineFile = '.agent/flake-quarantine.json';
  private manifestFile = '.agent/test-manifest.json';
  private stateFile = '.agent/state.json';

  private async loadQuarantineData(): Promise<FlakeReport[]> {
    try {
      const data = await fs.readFile(this.quarantineFile, 'utf-8');
      return JSON.parse(data);
    } catch {
      return [];
    }
  }

  private async loadTestManifest(): Promise<TestManifest[]> {
    try {
      const data = await fs.readFile(this.manifestFile, 'utf-8');
      return JSON.parse(data);
    } catch {
      return [];
    }
  }

  private async loadAgentState(): Promise<any> {
    try {
      const data = await fs.readFile(this.stateFile, 'utf-8');
      return JSON.parse(data);
    } catch {
      return {};
    }
  }

  private async saveAgentState(state: any): Promise<void> {
    await fs.mkdir(path.dirname(this.stateFile), { recursive: true });
    await fs.writeFile(this.stateFile, JSON.stringify(state, null, 2));
  }

  private async scanTestFiles(): Promise<TestManifest[]> {
    const manifest: TestManifest[] = [];
    const testDirs = ['tests', 'spec', 'e2e', 'playwright'];
    
    for (const dir of testDirs) {
      try {
        const files = await this.findTestFiles(dir);
        for (const file of files) {
          const tests = await this.extractTestsFromFile(file);
          manifest.push(...tests);
        }
      } catch (error) {
        // Directory doesn't exist or can't be read
        continue;
      }
    }

    return manifest;
  }

  private async findTestFiles(dir: string): Promise<string[]> {
    const files: string[] = [];
    
    try {
      const entries = await fs.readdir(dir, { withFileTypes: true });
      
      for (const entry of entries) {
        const fullPath = path.join(dir, entry.name);
        
        if (entry.isDirectory()) {
          const subFiles = await this.findTestFiles(fullPath);
          files.push(...subFiles);
        } else if (this.isTestFile(entry.name)) {
          files.push(fullPath);
        }
      }
    } catch (error) {
      // Directory doesn't exist or can't be read
    }

    return files;
  }

  private isTestFile(filename: string): boolean {
    const testExtensions = ['.spec.ts', '.spec.js', '.test.ts', '.test.js', '.spec.tsx', '.test.tsx'];
    return testExtensions.some(ext => filename.endsWith(ext));
  }

  private async extractTestsFromFile(filePath: string): Promise<TestManifest[]> {
    const tests: TestManifest[] = [];
    
    try {
      const content = await fs.readFile(filePath, 'utf-8');
      
      // Simple regex to find test descriptions (basic implementation)
      const testRegex = /(?:it|test|describe)\s*\(\s*['"`]([^'"`]+)['"`]/g;
      const suiteRegex = /describe\s*\(\s*['"`]([^'"`]+)['"`]/g;
      
      let suite = 'unknown';
      let match;
      
      // Extract suite name
      const suiteMatch = content.match(/describe\s*\(\s*['"`]([^'"`]+)['"`]/);
      if (suiteMatch) {
        suite = suiteMatch[1];
      }
      
      // Extract test names
      while ((match = testRegex.exec(content)) !== null) {
        const testName = match[1];
        const testId = this.generateTestId(suite, testName, 'chromium'); // Default browser
        
        // Check if test is marked as flaky
        const testStart = match.index;
        const testEnd = content.indexOf('\n', testStart);
        const testBlock = content.substring(testStart, testEnd);
        const isFlaky = testBlock.includes('@flaky') || testBlock.includes('@skip') || testBlock.includes('@quarantine');
        
        tests.push({
          testId,
          suite,
          browser: 'chromium',
          branch: 'main',
          filePath,
          testName,
          isFlaky,
          ...(isFlaky && {
            firstFlakySeen: new Date().toISOString(),
            lastFlakySeen: new Date().toISOString()
          })
        });
      }
    } catch (error) {
      console.warn(`Could not extract tests from ${filePath}:`, error);
    }

    return tests;
  }

  private generateTestId(suite: string, testName: string, browser: string): string {
    const combined = `${suite}:${testName}:${browser}`;
    let hash = 0;
    for (let i = 0; i < combined.length; i++) {
      const char = combined.charCodeAt(i);
      hash = ((hash << 5) - hash) + char;
      hash = hash & hash;
    }
    return `test_${Math.abs(hash).toString(36)}`;
  }

  private calculateFlakeAge(firstSeen: string): number {
    const firstDate = new Date(firstSeen);
    const now = new Date();
    const diffTime = now.getTime() - firstDate.getTime();
    return Math.floor(diffTime / (1000 * 60 * 60 * 24)); // Days
  }

  private async emitFlakeGauges(): Promise<void> {
    console.log('📊 Emitting flake status gauges...');
    
    try {
      const quarantineData = await this.loadQuarantineData();
      const testManifest = await this.loadTestManifest();
      const agentState = await this.loadAgentState();
      
      // Get active flaky tests
      const activeFlakes = quarantineData.filter(f => f.status === 'quarantined');
      const allTests = testManifest.filter(t => t.isFlaky);
      
      // Prepare gauge data
      const flakyTestData = activeFlakes.map(flake => ({
        testId: flake.testId,
        suite: flake.suite,
        browser: flake.browser,
        branch: flake.branch,
        ageDays: this.calculateFlakeAge(flake.firstSeen)
      }));

      // Record flake status gauges
      if (process.env.OTEL_ENABLED !== '0') {
        try {
          const { recordFlakeStatusGauges } = require('./otel');
          recordFlakeStatusGauges(flakyTestData);
          
          console.log(`📈 Emitted gauges for ${flakyTestData.length} flaky tests`);
        } catch (otelError) {
          console.warn('Failed to emit OTel gauges:', otelError);
        }
      }

      // Update agent state with latest metrics
      const newState = {
        ...agentState,
        lastFlakeGaugeEmission: new Date().toISOString(),
        flakeMetrics: {
          activeFlakes: activeFlakes.length,
          totalFlakyTests: allTests.length,
          averageAge: flakyTestData.length > 0 
            ? flakyTestData.reduce((sum, test) => sum + test.ageDays, 0) / flakyTestData.length 
            : 0
        }
      };

      await this.saveAgentState(newState);
      
      console.log(`✅ Flake gauges emitted successfully`);
      console.log(`   - Active quarantined: ${activeFlakes.length}`);
      console.log(`   - Total flaky tests: ${allTests.length}`);
      console.log(`   - Average age: ${newState.flakeMetrics.averageAge.toFixed(1)} days`);
      
    } catch (error) {
      console.error('❌ Failed to emit flake gauges:', error);
      throw error;
    }
  }

  private async updateTestManifest(): Promise<void> {
    console.log('🔍 Scanning test files for flaky tests...');
    
    try {
      const manifest = await this.scanTestFiles();
      await fs.mkdir(path.dirname(this.manifestFile), { recursive: true });
      await fs.writeFile(this.manifestFile, JSON.stringify(manifest, null, 2));
      
      const flakyCount = manifest.filter(t => t.isFlaky).length;
      console.log(`📋 Updated test manifest: ${manifest.length} tests found, ${flakyCount} marked as flaky`);
      
    } catch (error) {
      console.error('❌ Failed to update test manifest:', error);
      throw error;
    }
  }

  public async run(): Promise<void> {
    console.log('🌙 Starting nightly flake gauges emission...');
    
    try {
      // Update test manifest
      await this.updateTestManifest();
      
      // Emit flake gauges
      await this.emitFlakeGauges();
      
      console.log('✅ Nightly flake gauges emission complete');
      
    } catch (error) {
      console.error('❌ Nightly flake gauges emission failed:', error);
      throw error;
    }
  }
}

// CLI interface
async function main() {
  const emitter = new FlakeGaugesEmitter();
  
  try {
    await emitter.run();
  } catch (error) {
    console.error('Flake gauges emission failed:', error);
    process.exit(1);
  }
}

if (require.main === module) {
  main();
}

export { FlakeGaugesEmitter };
