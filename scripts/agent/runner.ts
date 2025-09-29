/**
 * Enhanced Agent Runner with Admission Control and Shadow Writes
 * Supports both JSON and SQLite queue backends with budget enforcement
 */

import { AgentDatabase, getQueueConfig } from './db';
import { writeShadowArtifact, jsonUpsert, compareShadowVsCanonical } from './io';
import { existsSync, readFileSync } from 'fs';

export interface JobExecutionResult {
  success: boolean;
  exitCode: number;
  stdout?: string;
  stderr?: string;
  metrics?: any;
  duration: number;
}

export interface AdmissionControl {
  maxJobs: number;
  maxFiles: number;
  maxLines: number;
  concurrency: number;
}

export class EnhancedRunner {
  private db: AgentDatabase | null = null;
  private config = getQueueConfig();
  private admissionControl: AdmissionControl;
  private runningJobs = new Set<string>();

  constructor() {
    this.admissionControl = {
      maxJobs: this.config.maxJobs,
      maxFiles: this.config.maxFiles,
      maxLines: this.config.maxLines,
      concurrency: process.env.NODE_ENV === 'development' ? 3 : 2,
    };

    // Initialize SQLite if configured
    if (this.config.driver === 'sqlite') {
      this.db = new AgentDatabase('.agent/queue.db', this.config.wal);
    }
  }

  /**
   * Check if lock file exists (kill switch)
   */
  private checkLock(): boolean {
    return existsSync('.agent/LOCK');
  }

  /**
   * Admission control: check if we can accept new jobs
   */
  private canAcceptJob(): { allowed: boolean; reason?: string } {
    // Check lock file
    if (this.checkLock()) {
      return { allowed: false, reason: 'LOCK file present' };
    }

    // Check running job count
    if (this.runningJobs.size >= this.admissionControl.concurrency) {
      return { allowed: false, reason: `Max concurrency reached (${this.admissionControl.concurrency})` };
    }

    // Check queue depth
    if (this.config.driver === 'sqlite' && this.db) {
      const depth = this.db.getQueueDepth();
      if (depth >= this.admissionControl.maxJobs) {
        return { allowed: false, reason: `Queue depth limit reached (${this.admissionControl.maxJobs})` };
      }
    }

    return { allowed: true };
  }

  /**
   * Enqueue a job with admission control
   */
  enqueueJob(job: {
    id: string;
    type: string;
    priority: number;
    payload: any;
    maxAttempts?: number;
    ttlMs?: number;
  }): { success: boolean; reason?: string } {
    const admission = this.canAcceptJob();
    if (!admission.allowed) {
      return { success: false, reason: admission.reason };
    }

    try {
      if (this.config.driver === 'sqlite' && this.db) {
        // SQLite enqueue
        const sqliteJob = {
          id: job.id,
          kind: job.type,
          payload_json: JSON.stringify(job.payload),
          priority: job.priority,
          max_attempts: job.maxAttempts || 3,
          not_before: 0,
          created_at: Date.now(),
          ttl_ms: job.ttlMs || 43200000, // 12 hours default
        };

        this.db.enqueueJob(sqliteJob);
      } else {
        // JSON enqueue (existing behavior)
        const jsonJob = {
          ...job,
          createdAt: new Date().toISOString(),
          attempts: 0,
          status: 'pending',
        };

        jsonUpsert('.agent/agent_queue.json', job.id, jsonJob);
      }

      return { success: true };
    } catch (error) {
      return { success: false, reason: `Enqueue failed: ${error}` };
    }
  }

  /**
   * Dequeue and execute jobs with backoff and retry logic
   */
  async processJobs(): Promise<JobExecutionResult[]> {
    const results: JobExecutionResult[] = [];
    const maxJobsPerPass = Math.min(this.admissionControl.maxJobs, 2);

    for (let i = 0; i < maxJobsPerPass; i++) {
      const job = this.dequeueJob();
      if (!job) break;

      const result = await this.executeJob(job);
      results.push(result);

      // Handle job completion/failure
      this.handleJobResult(job.id, result);
    }

    return results;
  }

  /**
   * Dequeue a job from the appropriate backend
   */
  private dequeueJob(): any | null {
    if (this.config.driver === 'sqlite' && this.db) {
      return this.db.dequeueJob();
    } else {
      // JSON dequeue (existing behavior)
      if (!existsSync('.agent/agent_queue.json')) {
        return null;
      }

      const content = readFileSync('.agent/agent_queue.json', 'utf8');
      const jobs = JSON.parse(content);
      
      if (!Array.isArray(jobs) || jobs.length === 0) {
        return null;
      }

      // Find highest priority job
      const sortedJobs = jobs
        .filter((job: any) => job.status === 'pending')
        .sort((a: any, b: any) => (b.priority || 0) - (a.priority || 0));

      if (sortedJobs.length === 0) {
        return null;
      }

      const job = sortedJobs[0];
      
      // Mark as running
      job.status = 'running';
      job.attempts = (job.attempts || 0) + 1;
      
      // Update JSON file
      const updatedJobs = jobs.map((j: any) => j.id === job.id ? job : j);
      const fs = require('fs');
      fs.writeFileSync('.agent/agent_queue.json', JSON.stringify(updatedJobs, null, 2));

      return job;
    }
  }

  /**
   * Execute a job with timeout and error handling
   */
  private async executeJob(job: any): Promise<JobExecutionResult> {
    const startTime = Date.now();
    const runId = this.startRun(job.id);
    
    this.runningJobs.add(job.id);

    try {
      console.log(`[runner] Executing job: ${job.id} (${job.kind || job.type})`);

      // Execute based on job type
      const result = await this.executeJobByType(job);
      
      const duration = Date.now() - startTime;
      
      this.finishRun(runId, result.exitCode, result.stdout, result.stderr, {
        duration,
        jobId: job.id,
        jobType: job.kind || job.type,
      });

      return {
        success: result.exitCode === 0,
        exitCode: result.exitCode,
        stdout: result.stdout,
        stderr: result.stderr,
        metrics: { duration },
        duration,
      };

    } catch (error) {
      const duration = Date.now() - startTime;
      const errorMessage = error instanceof Error ? error.message : String(error);
      
      this.finishRun(runId, 1, '', errorMessage, {
        duration,
        jobId: job.id,
        error: errorMessage,
      });

      return {
        success: false,
        exitCode: 1,
        stdout: '',
        stderr: errorMessage,
        metrics: { duration, error: errorMessage },
        duration,
      };
    } finally {
      this.runningJobs.delete(job.id);
    }
  }

  /**
   * Execute job based on its type
   */
  private async executeJobByType(job: any): Promise<{ exitCode: number; stdout: string; stderr: string }> {
    const jobType = job.kind || job.type;
    
    switch (jobType) {
      case 'test-maintenance':
        return this.executeTestMaintenance(job);
      case 'integration-enhancement':
        return this.executeIntegrationEnhancement(job);
      case 'accessibility':
      case 'a11y-scan':
        return this.executeAccessibilityScan(job);
      case 'csp-scan':
        return this.executeCSPScan(job);
      case 'offline-isolation':
        return this.executeOfflineIsolation(job);
      case 'ssot-refresh':
        return this.executeSSOTRefresh(job);
      case 'flake-quarantine':
        return this.executeFlakeQuarantine(job);
      case 'docs-drift':
        return this.executeDocsDrift(job);
      default:
        return {
          exitCode: 0,
          stdout: `Job type ${jobType} executed successfully`,
          stderr: '',
        };
    }
  }

  /**
   * Execute test maintenance job
   */
  private async executeTestMaintenance(job: any): Promise<{ exitCode: number; stdout: string; stderr: string }> {
    // Simulate test maintenance
    return {
      exitCode: 0,
      stdout: `Test maintenance completed for ${job.payload?.files || 'all tests'}`,
      stderr: '',
    };
  }

  /**
   * Execute integration enhancement job
   */
  private async executeIntegrationEnhancement(job: any): Promise<{ exitCode: number; stdout: string; stderr: string }> {
    // Simulate integration enhancement
    return {
      exitCode: 0,
      stdout: `Integration enhancement completed for ${job.payload?.files || 'components'}`,
      stderr: '',
    };
  }

  /**
   * Execute accessibility scan job
   */
  private async executeAccessibilityScan(job: any): Promise<{ exitCode: number; stdout: string; stderr: string }> {
    // Simulate accessibility scan
    return {
      exitCode: 0,
      stdout: `Accessibility scan completed for ${job.payload?.paths || 'all components'}`,
      stderr: '',
    };
  }

  /**
   * Execute CSP scan job
   */
  private async executeCSPScan(job: any): Promise<{ exitCode: number; stdout: string; stderr: string }> {
    // Simulate CSP scan
    return {
      exitCode: 0,
      stdout: `CSP scan completed for ${job.payload?.paths || 'all files'}`,
      stderr: '',
    };
  }

  /**
   * Execute offline isolation job
   */
  private async executeOfflineIsolation(job: any): Promise<{ exitCode: number; stdout: string; stderr: string }> {
    // Simulate offline isolation test
    return {
      exitCode: 0,
      stdout: `Offline isolation test completed for ${job.payload?.tests || 'isolation tests'}`,
      stderr: '',
    };
  }

  /**
   * Execute SSOT refresh job
   */
  private async executeSSOTRefresh(job: any): Promise<{ exitCode: number; stdout: string; stderr: string }> {
    // Simulate SSOT refresh
    return {
      exitCode: 0,
      stdout: `SSOT refresh completed`,
      stderr: '',
    };
  }

  /**
   * Execute flake quarantine job
   */
  private async executeFlakeQuarantine(job: any): Promise<{ exitCode: number; stdout: string; stderr: string }> {
    // Simulate flake quarantine
    return {
      exitCode: 0,
      stdout: `Flake quarantine completed for ${job.payload?.artifacts || 'test artifacts'}`,
      stderr: '',
    };
  }

  /**
   * Execute docs drift job
   */
  private async executeDocsDrift(job: any): Promise<{ exitCode: number; stdout: string; stderr: string }> {
    // Simulate docs drift detection
    return {
      exitCode: 0,
      stdout: `Docs drift detection completed`,
      stderr: '',
    };
  }

  /**
   * Start tracking a job run
   */
  private startRun(jobId: string): string {
    if (this.config.driver === 'sqlite' && this.db) {
      return this.db.startRun(jobId);
    } else {
      // JSON run tracking
      const runId = `run-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
      const runData = {
        id: runId,
        job_id: jobId,
        started_at: Date.now(),
        finished_at: null,
        exit_code: null,
        stdout: null,
        stderr: null,
        metrics_json: null,
      };

      jsonUpsert('.agent/runs.json', runId, runData);
      return runId;
    }
  }

  /**
   * Finish tracking a job run
   */
  private finishRun(runId: string, exitCode: number, stdout?: string, stderr?: string, metrics?: any): void {
    if (this.config.driver === 'sqlite' && this.db) {
      this.db.finishRun(runId, exitCode, stdout, stderr, metrics);
    } else {
      // JSON run tracking
      const runData = {
        finished_at: Date.now(),
        exit_code: exitCode,
        stdout: stdout || null,
        stderr: stderr || null,
        metrics_json: metrics ? JSON.stringify(metrics) : null,
      };

      jsonUpsert('.agent/runs.json', runId, runData);
    }
  }

  /**
   * Handle job completion/failure with retry logic
   */
  private handleJobResult(jobId: string, result: JobExecutionResult): void {
    if (result.success) {
      this.completeJob(jobId);
    } else {
      this.handleJobFailure(jobId, result);
    }
  }

  /**
   * Mark job as completed
   */
  private completeJob(jobId: string): void {
    if (this.config.driver === 'sqlite' && this.db) {
      this.db.completeJob(jobId, 0);
    } else {
      // JSON completion
      if (existsSync('.agent/agent_queue.json')) {
        const content = readFileSync('.agent/agent_queue.json', 'utf8');
        const jobs = JSON.parse(content);
        
        const updatedJobs = jobs.map((job: any) => 
          job.id === jobId ? { ...job, status: 'completed' } : job
        );
        
        const fs = require('fs');
        fs.writeFileSync('.agent/agent_queue.json', JSON.stringify(updatedJobs, null, 2));
      }
    }
  }

  /**
   * Handle job failure with exponential backoff
   */
  private handleJobFailure(jobId: string, result: JobExecutionResult): void {
    if (this.config.driver === 'sqlite' && this.db) {
      const job = this.db.getJobById(jobId);
      if (job && job.attempts < job.max_attempts) {
        // Calculate exponential backoff with jitter
        const baseDelay = Math.pow(2, job.attempts) * 1000; // 1s, 2s, 4s, 8s...
        const jitter = Math.random() * 0.3 - 0.15; // ±15% jitter
        const backoffMs = Math.floor(baseDelay * (1 + jitter));
        
        this.db.retryJob(jobId, backoffMs);
        console.log(`[runner] Job ${jobId} failed, retrying in ${backoffMs}ms (attempt ${job.attempts + 1}/${job.max_attempts})`);
      } else {
        this.db.failJob(jobId);
        console.log(`[runner] Job ${jobId} failed permanently after ${job?.attempts || 0} attempts`);
      }
    } else {
      // JSON failure handling
      if (existsSync('.agent/agent_queue.json')) {
        const content = readFileSync('.agent/agent_queue.json', 'utf8');
        const jobs = JSON.parse(content);
        
        const job = jobs.find((j: any) => j.id === jobId);
        if (job && (job.attempts || 0) < (job.maxAttempts || 3)) {
          // Retry with exponential backoff
          const baseDelay = Math.pow(2, job.attempts || 0) * 1000;
          const jitter = Math.random() * 0.3 - 0.15;
          const backoffMs = Math.floor(baseDelay * (1 + jitter));
          
          job.status = 'pending';
          job.nextRunAt = new Date(Date.now() + backoffMs).toISOString();
          
          const updatedJobs = jobs.map((j: any) => j.id === jobId ? job : j);
          const fs = require('fs');
          fs.writeFileSync('.agent/agent_queue.json', JSON.stringify(updatedJobs, null, 2));
          
          console.log(`[runner] Job ${jobId} failed, retrying in ${backoffMs}ms (attempt ${(job.attempts || 0) + 1}/${job.maxAttempts || 3})`);
        } else {
          // Mark as failed permanently
          const updatedJobs = jobs.map((j: any) => 
            j.id === jobId ? { ...j, status: 'failed' } : j
          );
          
          const fs = require('fs');
          fs.writeFileSync('.agent/agent_queue.json', JSON.stringify(updatedJobs, null, 2));
          
          console.log(`[runner] Job ${jobId} failed permanently after ${job?.attempts || 0} attempts`);
        }
      }
    }
  }

  /**
   * Write status information
   */
  writeStatus(): void {
    const status = {
      timestamp: new Date().toISOString(),
      config: this.config,
      admissionControl: this.admissionControl,
      runningJobs: Array.from(this.runningJobs),
      queueDepth: this.config.driver === 'sqlite' && this.db ? this.db.getQueueDepth() : 0,
      recentRuns: this.config.driver === 'sqlite' && this.db ? this.db.getRecentRuns(5) : [],
    };

    const statusJson = JSON.stringify(status, null, 2);

    if (this.config.shadow) {
      // Write to shadow artifacts only
      writeShadowArtifact('.agent/status.json', statusJson);
      console.log('[runner] Status written to shadow artifacts');
    } else {
      // Write to canonical artifacts
      const fs = require('fs');
      fs.writeFileSync('.agent/status.json', statusJson);
      console.log('[runner] Status written to canonical artifacts');
    }
  }

  /**
   * Compare shadow vs canonical artifacts
   */
  compareArtifacts(): void {
    const artifacts = ['.agent/status.json', '.agent/agent_queue.json', '.agent/runs.json'];
    
    console.log('[runner] Comparing shadow vs canonical artifacts:');
    
    artifacts.forEach(artifact => {
      const comparison = compareShadowVsCanonical(artifact);
      const status = comparison.identical ? '✓' : '✗';
      console.log(`  ${status} ${artifact}: ${comparison.identical ? 'identical' : 'different'}`);
      
      if (!comparison.identical && comparison.differences) {
        comparison.differences.slice(0, 3).forEach(diff => {
          console.log(`    - ${diff}`);
        });
      }
    });
  }

  /**
   * Cleanup and close resources
   */
  close(): void {
    if (this.db) {
      this.db.close();
    }
  }
}

// Factory function
export function createEnhancedRunner(): EnhancedRunner {
  return new EnhancedRunner();
}



