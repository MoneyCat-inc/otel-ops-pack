/**
 * Agent Queue Runner with Admission Control and Shadow Writes
 * 
 * Implements job processing with:
 * - Admission control (queue depth limits)
 * - Exponential backoff with jitter for retries
 * - Shadow-only writes (canonical artifacts untouched)
 * - Budget enforcement and guardrails
 */

import { existsSync } from 'fs';
import { join } from 'path';
import { SQLiteQueueDB, Job, Run, JobMetrics } from './db';
import { getQueueConfig, QueueConfig } from '../../lib/config/queue';
import { writeFileAtomicIfChanged, readJsonFile, ensureDir } from './io';

export interface RunnerStatus {
  timestamp: string;
  queueDepth: number;
  runningCount: number;
  lastRuns: Array<{
    id: string;
    kind: string;
    status: string;
    durationMs?: number;
  }>;
  admissionCap: number;
  shadowMode: boolean;
  driver: string;
}

export interface QueueMetrics {
  ts: string;
  queue_depth: number;
  running: number;
  p95_job_ms?: number;
  failures_total: number;
}

export class AgentRunner {
  private config: QueueConfig;
  private db?: SQLiteQueueDB;
  private isRunning = false;
  private stopRequested = false;
  private metrics: QueueMetrics[] = [];
  private lastRunTimes: number[] = [];

  constructor() {
    this.config = getQueueConfig();
  }

  /**
   * Initialize the runner
   */
  async initialize(): Promise<void> {
    if (this.config.driver === 'sqlite') {
      const dbPath = '.agent/queue.db';
      this.db = new SQLiteQueueDB(dbPath, this.config);
      console.log(`[runner] Initialized SQLite driver with DB: ${dbPath}`);
    } else {
      console.log('[runner] Using JSON driver');
    }

    // Ensure shadow directory exists
    if (this.config.shadow) {
      await ensureDir('.agent/shadow');
    }

    // Ensure metrics directory exists if metrics are enabled
    if (process.env.QUEUE_METRICS === '1') {
      await ensureDir('C:/logs/queue');
    }
  }

  /**
   * Check if agent lock is present
   */
  private checkLock(): boolean {
    if (existsSync('.agent/LOCK')) {
      console.log('[agent] LOCK present - skipping job processing');
      return true;
    }
    return false;
  }

  /**
   * Calculate exponential backoff with jitter
   */
  private expoJitter(
    attempt: number,
    baseMs: number = 60000, // 1 minute
    capMs: number = 900000  // 15 minutes
  ): number {
    const exponential = Math.min(capMs, baseMs * Math.pow(2, attempt));
    const jitter = exponential * 0.15 * (Math.random() * 2 - 1); // ±15%
    return Math.floor(exponential + jitter);
  }

  /**
   * Get queue depth for admission control
   */
  private async getQueueDepth(): Promise<number> {
    if (this.db) {
      const stats = this.db.getQueueStats();
      return stats.pending + stats.running;
    } else {
      // For JSON driver, count pending jobs
      const queueData = await readJsonFile('.agent/agent_queue.json', { jobs: [] });
      return queueData.jobs?.filter((job: any) => job.status === 'pending').length || 0;
    }
  }

  /**
   * Check admission control
   */
  private async checkAdmission(): Promise<boolean> {
    const admissionCap = parseInt(process.env.QUEUE_ADMISSION_CAP || '200', 10);
    const currentDepth = await this.getQueueDepth();
    
    if (currentDepth >= admissionCap) {
      console.log(`[admission] Queue at capacity (${currentDepth}/${admissionCap}) - refusing new jobs`);
      return false;
    }
    
    return true;
  }

  /**
   * Execute a job with budget enforcement
   */
  private async executeJob(job: Job): Promise<{ success: boolean; metrics?: JobMetrics; error?: string }> {
    const startTime = Date.now();
    let runId: string | null = null;

    try {
      // Budget enforcement
      const maxFiles = parseInt(process.env.QUEUE_MAX_FILES || '10', 10);
      const maxLines = parseInt(process.env.QUEUE_MAX_LINES || '1000', 10);

      // Parse job payload
      const payload = JSON.parse(job.payload_json);
      
      // Simulate job execution based on kind
      let success = false;
      let error: string | undefined;

      switch (job.kind) {
        case 'test-job':
          // Simple test job that always succeeds
          success = true;
          break;
          
        case 'failing-job':
          // Deterministic failing job for testing retry logic
          success = false;
          error = 'Simulated failure for testing retry logic';
          break;
          
        case 'over-budget-job':
          // Job that exceeds budget limits
          if (payload.files > maxFiles || payload.lines > maxLines) {
            throw new Error(`GUARDRAIL ERROR: Job exceeds budget limits (files: ${payload.files}/${maxFiles}, lines: ${payload.lines}/${maxLines})`);
          }
          success = true;
          break;
          
        case 'slow-job':
          // Job that takes time to complete
          await new Promise(resolve => setTimeout(resolve, 2000));
          success = true;
          break;
          
        default:
          // Generic job processing
          success = Math.random() > 0.3; // 70% success rate
          if (!success) {
            error = 'Random failure for testing';
          }
      }

      const durationMs = Date.now() - startTime;
      const metrics: JobMetrics = {
        duration_ms: durationMs,
        memory_mb: Math.floor(Math.random() * 100) + 50,
        cpu_percent: Math.floor(Math.random() * 20) + 5,
        retry_count: job.attempts - 1
      };

      // Record run
      if (this.db) {
        runId = this.db.addRun({
          job_id: job.id,
          started_at: startTime,
          finished_at: Date.now(),
          exit_code: success ? 0 : 1,
          stdout: success ? 'Job completed successfully' : '',
          stderr: error || '',
          metrics_json: JSON.stringify(metrics)
        });
      }

      // Update last run times for P95 calculation
      this.lastRunTimes.push(durationMs);
      if (this.lastRunTimes.length > 100) {
        this.lastRunTimes.shift();
      }

      return { success, metrics, error };

    } catch (error) {
      const durationMs = Date.now() - startTime;
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';

      // Record failed run
      if (this.db) {
        runId = this.db.addRun({
          job_id: job.id,
          started_at: startTime,
          finished_at: Date.now(),
          exit_code: 1,
          stdout: '',
          stderr: errorMessage,
          metrics_json: JSON.stringify({ duration_ms: durationMs, error_type: errorMessage })
        });
      }

      return { success: false, error: errorMessage };
    }
  }

  /**
   * Write shadow artifacts
   */
  private async writeShadowArtifacts(job: Job, result: any): Promise<void> {
    if (!this.config.shadow) return;

    const shadowPath = '.agent/shadow';
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    
    // Write job result to shadow
    const resultPath = join(shadowPath, `job-${job.id}-${timestamp}.json`);
    await writeFileAtomicIfChanged(resultPath, JSON.stringify({
      jobId: job.id,
      kind: job.kind,
      timestamp: new Date().toISOString(),
      result
    }, null, 2));

    // Update shadow status
    const statusPath = join(shadowPath, 'status.json');
    const currentStatus = await readJsonFile(statusPath, { lastProcessed: null, totalProcessed: 0 });
    
    await writeFileAtomicIfChanged(statusPath, JSON.stringify({
      ...currentStatus,
      lastProcessed: job.id,
      lastProcessedAt: new Date().toISOString(),
      totalProcessed: (currentStatus.totalProcessed || 0) + 1
    }, null, 2));
  }

  /**
   * Export queue metrics to telemetry
   */
  private async exportMetrics(): Promise<void> {
    if (process.env.QUEUE_METRICS !== '1') return;

    const p95JobMs = this.lastRunTimes.length > 0 
      ? this.lastRunTimes.sort((a, b) => a - b)[Math.floor(this.lastRunTimes.length * 0.95)]
      : undefined;

    const queueDepth = await this.getQueueDepth();
    const stats = this.db?.getQueueStats();
    
    const metrics: QueueMetrics = {
      ts: new Date().toISOString(),
      queue_depth: queueDepth,
      running: stats?.running || 0,
      p95_job_ms: p95JobMs,
      failures_total: stats?.failed || 0
    };

    // Append to metrics log
    const logLine = JSON.stringify(metrics) + '\n';
    const logPath = 'C:/logs/queue/health.log';
    
    try {
      await writeFileAtomicIfChanged(logPath, logLine, { encoding: 'utf8' });
      console.log(`[metrics] Exported queue metrics: depth=${queueDepth}, running=${metrics.running}`);
    } catch (error) {
      console.warn('[metrics] Failed to export metrics:', error);
    }
  }

  /**
   * Update runner status
   */
  private async updateStatus(lastRuns: Array<{ id: string; kind: string; status: string; durationMs?: number }>): Promise<void> {
    const queueDepth = await this.getQueueDepth();
    const stats = this.db?.getQueueStats();
    
    const status: RunnerStatus = {
      timestamp: new Date().toISOString(),
      queueDepth,
      runningCount: stats?.running || 0,
      lastRuns,
      admissionCap: parseInt(process.env.QUEUE_ADMISSION_CAP || '200', 10),
      shadowMode: this.config.shadow,
      driver: this.config.driver
    };

    await writeFileAtomicIfChanged('.agent/status.json', JSON.stringify(status, null, 2));
  }

  /**
   * Process a single job
   */
  private async processJob(job: Job): Promise<void> {
    console.log(`[runner] Processing job ${job.id} (${job.kind}) - attempt ${job.attempts + 1}`);

    // Mark job as running
    if (this.db) {
      this.db.markJobRunning(job.id);
    }

    // Execute job
    const result = await this.executeJob(job);

    if (result.success) {
      console.log(`[runner] Job ${job.id} completed successfully`);
      
      // Mark as completed
      if (this.db) {
        this.db.markJobCompleted(job.id);
      }

      // Write shadow artifacts
      await this.writeShadowArtifacts(job, { success: true, metrics: result.metrics });
    } else {
      console.log(`[runner] Job ${job.id} failed: ${result.error}`);
      
      // Handle retry or DLQ
      if (this.db) {
        const success = this.db.markJobFailed(job.id, result.error);
        if (!success) {
          console.log(`[runner] Job ${job.id} moved to DLQ after max attempts`);
        } else {
          console.log(`[runner] Job ${job.id} scheduled for retry`);
        }
      }

      // Write shadow artifacts
      await this.writeShadowArtifacts(job, { success: false, error: result.error });
    }
  }

  /**
   * Run a single processing pass
   */
  private async runPass(): Promise<void> {
    if (this.checkLock()) return;

    // Check admission control
    if (!(await this.checkAdmission())) {
      console.log('[runner] Admission control: queue at capacity');
      return;
    }

    // Get next jobs
    let jobs: Job[] = [];
    if (this.db) {
      jobs = this.db.getNextJobs(this.config.maxJobs);
    } else {
      // JSON driver fallback
      const queueData = await readJsonFile('.agent/agent_queue.json', { jobs: [] });
      jobs = queueData.jobs
        ?.filter((job: any) => job.status === 'pending' && (!job.not_before || job.not_before <= Date.now()))
        ?.slice(0, this.config.maxJobs) || [];
    }

    if (jobs.length === 0) {
      console.log('[runner] No jobs to process');
      return;
    }

    console.log(`[runner] Processing ${jobs.length} jobs (max concurrency: ${this.config.maxConcurrency})`);

    // Process jobs with concurrency limit
    const lastRuns: Array<{ id: string; kind: string; status: string; durationMs?: number }> = [];
    const startTime = Date.now();

    // Process jobs in batches
    for (let i = 0; i < jobs.length; i += this.config.maxConcurrency) {
      const batch = jobs.slice(i, i + this.config.maxConcurrency);
      
      const promises = batch.map(async (job) => {
        const jobStartTime = Date.now();
        try {
          await this.processJob(job);
          const durationMs = Date.now() - jobStartTime;
          lastRuns.push({
            id: job.id,
            kind: job.kind,
            status: 'completed',
            durationMs
          });
        } catch (error) {
          const durationMs = Date.now() - jobStartTime;
          lastRuns.push({
            id: job.id,
            kind: job.kind,
            status: 'failed',
            durationMs
          });
          console.error(`[runner] Error processing job ${job.id}:`, error);
        }
      });

      await Promise.all(promises);
    }

    const totalDuration = Date.now() - startTime;
    console.log(`[runner] Completed ${jobs.length} jobs in ${totalDuration}ms`);

    // Update status
    await this.updateStatus(lastRuns.slice(-5)); // Keep last 5 runs

    // Export metrics
    await this.exportMetrics();
  }

  /**
   * Start the runner
   */
  async start(): Promise<void> {
    if (this.isRunning) {
      console.log('[runner] Already running');
      return;
    }

    await this.initialize();
    this.isRunning = true;
    this.stopRequested = false;

    console.log(`[runner] Starting with config: ${JSON.stringify({
      driver: this.config.driver,
      shadow: this.config.shadow,
      maxJobs: this.config.maxJobs,
      maxConcurrency: this.config.maxConcurrency,
      enabled: this.config.enabled
    })}`);

    // Main processing loop
    while (this.isRunning && !this.stopRequested && this.config.enabled) {
      try {
        await this.runPass();
        
        // Wait before next pass
        await new Promise(resolve => setTimeout(resolve, 5000)); // 5 second intervals
      } catch (error) {
        console.error('[runner] Error in processing loop:', error);
        await new Promise(resolve => setTimeout(resolve, 10000)); // Wait 10 seconds on error
      }
    }

    console.log('[runner] Stopped');
  }

  /**
   * Stop the runner
   */
  async stop(): Promise<void> {
    console.log('[runner] Stopping...');
    this.stopRequested = true;
    this.isRunning = false;

    if (this.db) {
      this.db.close();
    }
  }

  /**
   * Get current status
   */
  async getStatus(): Promise<RunnerStatus> {
    const queueDepth = await this.getQueueDepth();
    const stats = this.db?.getQueueStats();
    
    return {
      timestamp: new Date().toISOString(),
      queueDepth,
      runningCount: stats?.running || 0,
      lastRuns: [], // Will be populated by runPass
      admissionCap: parseInt(process.env.QUEUE_ADMISSION_CAP || '200', 10),
      shadowMode: this.config.shadow,
      driver: this.config.driver
    };
  }
}

/**
 * CLI interface
 */
export async function runRunner(): Promise<void> {
  const runner = new AgentRunner();
  
  // Handle graceful shutdown
  process.on('SIGINT', async () => {
    console.log('\n[runner] Received SIGINT, shutting down gracefully...');
    await runner.stop();
    process.exit(0);
  });

  process.on('SIGTERM', async () => {
    console.log('\n[runner] Received SIGTERM, shutting down gracefully...');
    await runner.stop();
    process.exit(0);
  });

  try {
    await runner.start();
  } catch (error) {
    console.error('[runner] Fatal error:', error);
    process.exit(1);
  }
}

// Run if this file is executed directly
if (require.main === module) {
  runRunner().catch(error => {
    console.error('Runner failed:', error);
    process.exit(1);
  });
}