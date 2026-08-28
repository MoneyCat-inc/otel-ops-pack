#!/usr/bin/env tsx
/**
 * AUTO-BOTS Lane-Scoped Executor
 * Agent A only - enforces budgets and lane restrictions
 * 
 * Exit Codes:
 * - 0: Success
 * - 1: General error
 * - 52: Lock conflict
 * - 53: Retry exhausted
 */

import * as fs from 'fs';
import * as path from 'path';
import { minimatch } from 'minimatch';
import { WriterLock } from './lock';
import { withRetry } from './retry';
import { execSync } from 'child_process';

interface Config {
  budgets: {
    maxJobs: number;
    maxFiles: number;
    maxLines: number;
  };
  lanes: Record<string, { allow: string[] }>;
}

interface ECRRReport {
  actor: string;
  lane: string;
  examine: string;
  clean: string;
  report: string;
  role: string;
  status: 'success' | 'failed';
  retries: number;
  ttlHit: boolean;
  timestamp: string;
  filesModified: string[];
  linesChanged: number;
}

interface RetryResult {
  success: boolean;
  retries: number;
  ttlHit: boolean;
  error?: string;
}

class LaneExecutor {
  private config: Config;
  private lane: string;
  private lock: WriterLock;

  constructor(lane: string) {
    this.lane = lane;
    this.config = this.loadConfig();
    this.lock = new WriterLock();

    if (!this.config.lanes[lane]) {
      throw new Error(`Unknown lane: ${lane}`);
    }
  }

  private loadConfig(): Config {
    const configPath = path.join(process.cwd(), '.agent', 'config.json');
    return JSON.parse(fs.readFileSync(configPath, 'utf8'));
  }

  private isFileInLane(filePath: string): boolean {
    const allowPatterns = this.config.lanes[this.lane].allow;
    return allowPatterns.some(pattern => minimatch(filePath, pattern));
  }

  private getChangedFiles(): string[] {
    try {
      // Check both staged and unstaged changes in working tree
      const staged = execSync('git diff --name-only --cached', { 
        encoding: 'utf8' 
      }).split('\n').filter(line => line.trim());
      
      const unstaged = execSync('git diff --name-only', { 
        encoding: 'utf8' 
      }).split('\n').filter(line => line.trim());
      
      // Combine and deduplicate
      const allFiles = [...new Set([...staged, ...unstaged])];
      return allFiles;
    } catch {
      return [];
    }
  }

  private countChangedLines(): number {
    try {
      // Count both staged and unstaged changes
      const stagedDiff = execSync('git diff --cached --numstat', { 
        encoding: 'utf8' 
      });
      
      const unstagedDiff = execSync('git diff --numstat', { 
        encoding: 'utf8' 
      });
      
      let totalLines = 0;
      
      for (const diff of [stagedDiff, unstagedDiff]) {
        for (const line of diff.split('\n')) {
          const match = line.match(/^(\d+)\s+(\d+)\s+/);
          if (match) {
            totalLines += parseInt(match[1]) + parseInt(match[2]);
          }
        }
      }
      
      return totalLines;
    } catch {
      return 0;
    }
  }

  private enforceBudgets(files: string[], lines: number): void {
    const budgets = this.config.budgets;

    if (files.length > budgets.maxFiles) {
      throw new Error(
        `Budget exceeded: ${files.length} files (max ${budgets.maxFiles})`
      );
    }

    if (lines > budgets.maxLines) {
      throw new Error(
        `Budget exceeded: ${lines} lines (max ${budgets.maxLines})`
      );
    }

    console.log(`✅ Budgets OK: ${files.length}/${budgets.maxFiles} files, ${lines}/${budgets.maxLines} lines`);
  }

  private validateLaneScope(files: string[]): void {
    const outOfLane = files.filter(file => !this.isFileInLane(file));
    
    if (outOfLane.length > 0) {
      console.error(`❌ Files outside lane scope:`);
      outOfLane.forEach(file => console.error(`  - ${file}`));
      throw new Error(`Lane violation: ${outOfLane.length} files outside allowed patterns`);
    }

    console.log(`✅ Lane scope: All ${files.length} files within allowed patterns`);
  }

  private emitECRR(
    status: 'success' | 'failed', 
    files: string[], 
    lines: number, 
    retryInfo: { retries: number; ttlHit: boolean },
    error?: string
  ): void {
    const report: ECRRReport = {
      actor: 'Agent A',
      lane: this.lane,
      examine: `Lane-scoped execution for ${this.lane} lane`,
      clean: status === 'success' 
        ? `Modified ${files.length} files (${lines} lines) within lane scope`
        : `Failed after ${retryInfo.retries} attempts: ${error}`,
      report: status === 'success'
        ? `Successfully processed ${files.length} files with ${lines} line changes`
        : `Error: ${error}. TTL hit: ${retryInfo.ttlHit}`,
      role: 'AUTO-BOTS Lane Executor (Agent A)',
      status,
      retries: retryInfo.retries,
      ttlHit: retryInfo.ttlHit,
      timestamp: new Date().toISOString(),
      filesModified: files,
      linesChanged: lines
    };

    const ecrrDir = path.join(process.cwd(), 'artifacts', 'ecrr', this.lane);
    if (!fs.existsSync(ecrrDir)) {
      fs.mkdirSync(ecrrDir, { recursive: true });
    }

    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    const ecrrPath = path.join(ecrrDir, `lane-execution-${timestamp}.json`);
    fs.writeFileSync(ecrrPath, JSON.stringify(report, null, 2));

    console.log(`📄 ECRR report: ${ecrrPath}`);
  }

  private appendBossCatLog(status: 'success' | 'failed', files: string[], lines: number, error?: string): void {
    const logPath = path.join(process.cwd(), 'docs', 'BossCat', 'BOSSCAT_LOG.md');
    const timestamp = new Date().toISOString();
    const lesson = status === 'success'
      ? `Lane ${this.lane}: Processed ${files.length} files (${lines} lines) successfully`
      : `Lane ${this.lane}: Failed - ${error}`;

    const logEntry = `- **${timestamp}** - ${lesson}\n`;

    const header = `# BossCat Operations Log\n## AUTO-BOTS Lessons Learned\n\n`;
    try {
      fs.writeFileSync(logPath, header + logEntry, { flag: 'wx' });
    } catch (e: any) {
      if (e?.code !== 'EEXIST') throw e;
      fs.appendFileSync(logPath, logEntry);
    }

    console.log(`📝 BossCat log updated: ${lesson}`);
  }

  async execute(workFn: () => Promise<void>): Promise<void> {
    console.log(`🤖 AUTO-BOTS Lane Executor`);
    console.log(`Lane: ${this.lane}`);
    console.log(`Agent: A (Writer)`);
    console.log('─'.repeat(50));

    // Acquire write lock
    await this.lock.acquire('A', this.lane);

    let retryInfo = { retries: 0, ttlHit: false };

    try {
      // Execute work with retry
      const result = await withRetry(async () => {
        await workFn();

        // Validate after work
        const files = this.getChangedFiles();
        const lines = this.countChangedLines();

        this.enforceBudgets(files, lines);
        this.validateLaneScope(files);

        return { files, lines };
      }, {
        lane: this.lane,
        description: `Lane ${this.lane} execution`,
        getRetryInfo: (info) => { retryInfo = info; }
      });

      // Success
      const files = this.getChangedFiles();
      const lines = this.countChangedLines();
      
      this.emitECRR('success', files, lines, retryInfo);
      this.appendBossCatLog('success', files, lines);

      console.log('─'.repeat(50));
      console.log('✅ Lane execution complete');
    } catch (error: any) {
      const files = this.getChangedFiles();
      const lines = this.countChangedLines();
      const errorMsg = error.message || String(error);

      // Check if this was retry exhaustion
      const isRetryExhausted = error.message?.includes('Retry exhausted');
      
      this.emitECRR('failed', files, lines, retryInfo, errorMsg);
      this.appendBossCatLog('failed', files, lines, errorMsg);

      console.error('─'.repeat(50));
      console.error('❌ Lane execution failed');
      
      this.lock.release();
      
      // Exit with proper code on retry exhaustion
      if (isRetryExhausted) {
        process.exit(53);
      }
      
      process.exit(1);
    } finally {
      this.lock.release();
    }
  }
}

async function main() {
  const laneArg = process.argv.find(arg => arg.startsWith('--lane='));
  if (!laneArg) {
    console.error('❌ Usage: run-lane.ts --lane=<lane-name>');
    process.exit(1);
  }

  const lane = laneArg.split('=')[1];
  const executor = new LaneExecutor(lane);

  // Placeholder work function - replace with actual work
  const workFn = async () => {
    console.log('🔧 Executing lane work...');
    // Actual work would be injected here or read from a job spec
    console.log('✅ Work complete');
  };

  await executor.execute(workFn);
}

// Only run if called directly
if (require.main === module) {
  main().catch(error => {
    console.error('❌ Execution failed:', error);
    process.exit(1);
  });
}

export { LaneExecutor };

