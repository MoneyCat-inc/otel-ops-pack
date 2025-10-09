#!/usr/bin/env tsx
/**
 * AUTO-BOTS Bounded Retry Helper
 * Max 3 attempts with backoff, job TTL enforcement
 * 
 * Exit Codes:
 * - 0: Success within retry budget
 * - 53: Final failure after exhausting retries (with rollback)
 */

import * as fs from 'fs';
import * as path from 'path';
import { execSync } from 'child_process';

const EXIT_RETRY_EXHAUSTED = 53;

interface RetryConfig {
  maxAttempts: number;
  baseBackoffMs: number;
  ttlMs: number;
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
  attempts: Array<{
    attempt: number;
    error?: string;
    timestamp: string;
  }>;
}

class BoundedRetry {
  private config: RetryConfig;
  private startTime: number;

  constructor(config?: Partial<RetryConfig>) {
    const defaultConfig = this.loadConfig();
    this.config = {
      maxAttempts: config?.maxAttempts ?? defaultConfig.maxAttempts,
      baseBackoffMs: config?.baseBackoffMs ?? defaultConfig.baseBackoffMs,
      ttlMs: config?.ttlMs ?? defaultConfig.ttlMs
    };
    this.startTime = Date.now();
  }

  private loadConfig(): RetryConfig {
    const configPath = path.join(process.cwd(), '.agent', 'config.json');
    if (fs.existsSync(configPath)) {
      const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
      return config.retry;
    }
    // Defaults
    return {
      maxAttempts: 3,
      baseBackoffMs: 900000, // 15 minutes
      ttlMs: 43200000 // 12 hours
    };
  }

  private checkTTL(): boolean {
    const elapsed = Date.now() - this.startTime;
    return elapsed >= this.config.ttlMs;
  }

  private calculateBackoff(attempt: number): number {
    // Exponential backoff with jitter
    const baseDelay = this.config.baseBackoffMs;
    const exponentialDelay = baseDelay * Math.pow(1.5, attempt - 1);
    const jitter = Math.random() * 0.3 * exponentialDelay; // ±30% jitter
    return Math.min(exponentialDelay + jitter, baseDelay * 4); // Cap at 4x base
  }

  private async sleep(ms: number): Promise<void> {
    console.log(`⏳ Backing off for ${Math.round(ms / 1000)}s...`);
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  private rollback(modifiedFiles: string[]): void {
    console.log(`🔄 Rolling back ${modifiedFiles.length} modified files...`);
    try {
      if (modifiedFiles.length === 0) {
        console.log('ℹ️  No files to rollback');
        return;
      }

      // Only rollback files that were actually modified, not everything
      for (const file of modifiedFiles) {
        try {
          execSync(`git restore --staged "${file}"`, { encoding: 'utf8', stdio: 'pipe' });
          execSync(`git checkout -- "${file}"`, { encoding: 'utf8', stdio: 'pipe' });
        } catch (fileError) {
          console.warn(`⚠️  Could not rollback ${file}:`, fileError);
        }
      }
      console.log('✅ Rollback complete');
    } catch (error) {
      console.error('⚠️  Rollback encountered errors:', error);
      // Continue to emit ECRR anyway
    }
  }

  private emitECRR(lane: string, attempts: number, ttlHit: boolean, errors: string[]): void {
    const report: ECRRReport = {
      actor: 'Agent A',
      lane,
      examine: 'Bounded retry attempt with backoff and TTL enforcement',
      clean: ttlHit ? 'TTL exceeded - rollback performed' : 'Max retries exceeded - rollback performed',
      report: `Failed after ${attempts} attempts. Errors: ${errors.join('; ')}`,
      role: 'AUTO-BOTS Retry System',
      status: 'failed',
      retries: attempts,
      ttlHit,
      timestamp: new Date().toISOString(),
      attempts: errors.map((error, i) => ({
        attempt: i + 1,
        error,
        timestamp: new Date(Date.now() - (errors.length - i - 1) * 60000).toISOString()
      }))
    };

    const ecrrDir = path.join(process.cwd(), 'artifacts', 'ecrr', lane);
    if (!fs.existsSync(ecrrDir)) {
      fs.mkdirSync(ecrrDir, { recursive: true });
    }

    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    const ecrrPath = path.join(ecrrDir, `retry-failure-${timestamp}.json`);
    fs.writeFileSync(ecrrPath, JSON.stringify(report, null, 2));

    console.log(`📄 ECRR report: ${ecrrPath}`);
  }

  async execute<T>(
    fn: () => Promise<T>,
    options: { 
      lane: string; 
      description?: string;
      getRetryInfo?: (info: { retries: number; ttlHit: boolean }) => void;
    }
  ): Promise<T> {
    const errors: string[] = [];
    const modifiedFiles: string[] = [];
    let lastError: Error | null = null;
    let actualAttempts = 0;

    console.log(`🔁 Starting bounded retry (max ${this.config.maxAttempts} attempts)`);
    console.log(`⏱️  TTL: ${this.config.ttlMs / 3600000}h`);

    for (let attempt = 1; attempt <= this.config.maxAttempts; attempt++) {
      actualAttempts = attempt;
      
      // Check TTL before each attempt
      if (this.checkTTL()) {
        console.error(`❌ TTL exceeded (${this.config.ttlMs / 3600000}h)`);
        
        // Get list of modified files before rollback
        try {
          const staged = execSync('git diff --name-only --cached', { encoding: 'utf8' });
          const unstaged = execSync('git diff --name-only', { encoding: 'utf8' });
          modifiedFiles.push(...staged.split('\n').filter(f => f.trim()));
          modifiedFiles.push(...unstaged.split('\n').filter(f => f.trim()));
        } catch {}
        
        this.rollback([...new Set(modifiedFiles)]);
        this.emitECRR(options.lane, attempt - 1, true, errors);
        
        // Report retry info back to caller
        if (options.getRetryInfo) {
          options.getRetryInfo({ retries: attempt - 1, ttlHit: true });
        }
        
        process.exit(EXIT_RETRY_EXHAUSTED);
      }

      console.log(`\n🔄 Attempt ${attempt}/${this.config.maxAttempts}`);

      try {
        const result = await fn();
        console.log(`✅ Success on attempt ${attempt}`);
        
        // Report retry info on success
        if (options.getRetryInfo) {
          options.getRetryInfo({ retries: attempt - 1, ttlHit: false });
        }
        
        return result;
      } catch (error: any) {
        lastError = error;
        const errorMsg = error.message || String(error);
        errors.push(errorMsg);
        console.error(`❌ Attempt ${attempt} failed: ${errorMsg}`);

        if (attempt < this.config.maxAttempts) {
          const backoff = this.calculateBackoff(attempt);
          await this.sleep(backoff);
        }
      }
    }

    // All attempts exhausted
    console.error(`\n❌ All ${this.config.maxAttempts} attempts exhausted`);
    
    // Get list of modified files before rollback
    try {
      const staged = execSync('git diff --name-only --cached', { encoding: 'utf8' });
      const unstaged = execSync('git diff --name-only', { encoding: 'utf8' });
      modifiedFiles.push(...staged.split('\n').filter(f => f.trim()));
      modifiedFiles.push(...unstaged.split('\n').filter(f => f.trim()));
    } catch {}
    
    this.rollback([...new Set(modifiedFiles)]);
    this.emitECRR(options.lane, this.config.maxAttempts, false, errors);
    
    // Report retry info on failure
    if (options.getRetryInfo) {
      options.getRetryInfo({ retries: this.config.maxAttempts, ttlHit: false });
    }
    
    // Mark error for proper exit code handling
    const exhaustionError = new Error('Retry exhausted: ' + (lastError?.message || 'Unknown error'));
    throw exhaustionError;
  }
}

// Helper function for quick retry
export async function withRetry<T>(
  fn: () => Promise<T>,
  options: { 
    lane: string; 
    description?: string; 
    maxAttempts?: number;
    getRetryInfo?: (info: { retries: number; ttlHit: boolean }) => void;
  }
): Promise<T> {
  const retry = new BoundedRetry({ maxAttempts: options.maxAttempts });
  return retry.execute(fn, options);
}

export { BoundedRetry, EXIT_RETRY_EXHAUSTED };

