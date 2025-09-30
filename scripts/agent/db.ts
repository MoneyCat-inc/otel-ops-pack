/**
 * SQLite Database Access Layer for Agent Queue
 * 
 * Provides a clean interface for managing jobs and runs in SQLite.
 * Supports WAL mode for better concurrency and crash recovery.
 */

import Database from 'better-sqlite3';
import { QueueConfig } from '../../lib/config/queue';

export interface Job {
  id: string;
  kind: string;
  payload_json: string;
  priority: number;
  attempts: number;
  max_attempts: number;
  not_before: number; // Unix timestamp
  created_at: number; // Unix timestamp
  ttl_ms: number;
  status: 'pending' | 'running' | 'completed' | 'failed' | 'cancelled';
}

export interface Run {
  id: string;
  job_id: string;
  started_at: number; // Unix timestamp
  finished_at?: number; // Unix timestamp
  exit_code?: number;
  stdout?: string;
  stderr?: string;
  metrics_json?: string;
}

export interface JobMetrics {
  duration_ms?: number;
  memory_mb?: number;
  cpu_percent?: number;
  retry_count?: number;
  error_type?: string;
}

export class SQLiteQueueDB {
  private db: Database.Database;
  private config: QueueConfig;

  constructor(dbPath: string, config: QueueConfig) {
    this.config = config;
    this.db = new Database(dbPath);
    
    // Enable WAL mode if configured
    if (config.wal) {
      this.db.pragma('journal_mode = WAL');
      this.db.pragma('synchronous = NORMAL');
      this.db.pragma('cache_size = -64000'); // 64MB cache
    }
    
    this.initializeSchema();
  }

  private initializeSchema(): void {
    // Create jobs table
    this.db.exec(`
      CREATE TABLE IF NOT EXISTS jobs (
        id TEXT PRIMARY KEY,
        kind TEXT NOT NULL,
        payload_json TEXT NOT NULL,
        priority INTEGER NOT NULL DEFAULT 0,
        attempts INTEGER NOT NULL DEFAULT 0,
        max_attempts INTEGER NOT NULL DEFAULT 3,
        not_before INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        ttl_ms INTEGER NOT NULL DEFAULT 86400000,
        status TEXT NOT NULL DEFAULT 'pending',
        CHECK (status IN ('pending', 'running', 'completed', 'failed', 'cancelled'))
      )
    `);

    // Create runs table
    this.db.exec(`
      CREATE TABLE IF NOT EXISTS runs (
        id TEXT PRIMARY KEY,
        job_id TEXT NOT NULL,
        started_at INTEGER NOT NULL,
        finished_at INTEGER,
        exit_code INTEGER,
        stdout TEXT,
        stderr TEXT,
        metrics_json TEXT,
        FOREIGN KEY (job_id) REFERENCES jobs (id) ON DELETE CASCADE
      )
    `);

    // Create indexes for performance
    this.db.exec(`
      CREATE INDEX IF NOT EXISTS idx_jobs_status_priority 
      ON jobs (status, priority DESC, not_before)
    `);
    
    this.db.exec(`
      CREATE INDEX IF NOT EXISTS idx_jobs_created_at 
      ON jobs (created_at)
    `);
    
    this.db.exec(`
      CREATE INDEX IF NOT EXISTS idx_runs_job_id 
      ON runs (job_id)
    `);
    
    this.db.exec(`
      CREATE INDEX IF NOT EXISTS idx_runs_started_at 
      ON runs (started_at)
    `);
  }

  /**
   * Add a new job to the queue
   */
  addJob(job: Omit<Job, 'id' | 'attempts' | 'status'>): string {
    const id = `job_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    
    const stmt = this.db.prepare(`
      INSERT INTO jobs (id, kind, payload_json, priority, max_attempts, not_before, created_at, ttl_ms, status)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'pending')
    `);
    
    stmt.run(
      id,
      job.kind,
      job.payload_json,
      job.priority,
      job.max_attempts,
      job.not_before,
      job.created_at,
      job.ttl_ms
    );
    
    return id;
  }

  /**
   * Get the next batch of jobs ready to run
   */
  getNextJobs(limit: number = 10): Job[] {
    const now = Date.now();
    
    const stmt = this.db.prepare(`
      SELECT * FROM jobs 
      WHERE status = 'pending' 
        AND not_before <= ?
        AND created_at + ttl_ms > ?
      ORDER BY priority DESC, created_at ASC
      LIMIT ?
    `);
    
    return stmt.all(now, now, limit) as Job[];
  }

  getAllJobs(): Job[] {
    const stmt = this.db.prepare(`
      SELECT * FROM jobs 
      ORDER BY created_at DESC
    `);
    
    return stmt.all() as Job[];
  }

  /**
   * Mark a job as running
   */
  markJobRunning(jobId: string): boolean {
    const stmt = this.db.prepare(`
      UPDATE jobs 
      SET status = 'running', attempts = attempts + 1
      WHERE id = ? AND status = 'pending'
    `);
    
    const result = stmt.run(jobId);
    return result.changes > 0;
  }

  /**
   * Mark a job as completed
   */
  markJobCompleted(jobId: string): boolean {
    const stmt = this.db.prepare(`
      UPDATE jobs 
      SET status = 'completed'
      WHERE id = ?
    `);
    
    const result = stmt.run(jobId);
    return result.changes > 0;
  }

  /**
   * Mark a job as failed and schedule retry if appropriate
   */
  markJobFailed(jobId: string, error?: string): boolean {
    const job = this.getJob(jobId);
    if (!job) return false;

    if (job.attempts < job.max_attempts) {
      // Schedule retry with exponential backoff
      const backoffMs = this.calculateBackoff(job.attempts);
      const notBefore = Date.now() + backoffMs;
      
      const stmt = this.db.prepare(`
        UPDATE jobs 
        SET status = 'pending', not_before = ?
        WHERE id = ?
      `);
      
      const result = stmt.run(notBefore, jobId);
      return result.changes > 0;
    } else {
      // Max attempts reached, mark as failed
      const stmt = this.db.prepare(`
        UPDATE jobs 
        SET status = 'failed'
        WHERE id = ?
      `);
      
      const result = stmt.run(jobId);
      return result.changes > 0;
    }
  }

  /**
   * Get a job by ID
   */
  getJob(jobId: string): Job | null {
    const stmt = this.db.prepare('SELECT * FROM jobs WHERE id = ?');
    const result = stmt.get(jobId) as Job | undefined;
    return result || null;
  }

  /**
   * Add a run record
   */
  addRun(run: Omit<Run, 'id'>): string {
    const id = `run_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    
    const stmt = this.db.prepare(`
      INSERT INTO runs (id, job_id, started_at, finished_at, exit_code, stdout, stderr, metrics_json)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    `);
    
    stmt.run(
      id,
      run.job_id,
      run.started_at,
      run.finished_at || null,
      run.exit_code || null,
      run.stdout || null,
      run.stderr || null,
      run.metrics_json || null
    );
    
    return id;
  }

  /**
   * Get recent runs for a job
   */
  getJobRuns(jobId: string, limit: number = 10): Run[] {
    const stmt = this.db.prepare(`
      SELECT * FROM runs 
      WHERE job_id = ?
      ORDER BY started_at DESC
      LIMIT ?
    `);
    
    return stmt.all(jobId, limit) as Run[];
  }

  /**
   * Clean up expired jobs
   */
  cleanupExpiredJobs(): number {
    const now = Date.now();
    
    const stmt = this.db.prepare(`
      DELETE FROM jobs 
      WHERE created_at + ttl_ms <= ?
    `);
    
    const result = stmt.run(now);
    return result.changes;
  }

  /**
   * Get queue statistics
   */
  getQueueStats(): {
    pending: number;
    running: number;
    completed: number;
    failed: number;
    total: number;
  } {
    const stmt = this.db.prepare(`
      SELECT status, COUNT(*) as count
      FROM jobs
      GROUP BY status
    `);
    
    const results = stmt.all() as { status: string; count: number }[];
    
    const stats = {
      pending: 0,
      running: 0,
      completed: 0,
      failed: 0,
      total: 0,
    };
    
    for (const row of results) {
      stats[row.status as keyof typeof stats] = row.count;
      stats.total += row.count;
    }
    
    return stats;
  }

  /**
   * Calculate exponential backoff with jitter
   */
  private calculateBackoff(attempt: number): number {
    const baseDelay = this.config.baseDelayMs;
    const exponentialDelay = baseDelay * Math.pow(2, attempt - 1);
    const jitter = exponentialDelay * this.config.jitterFactor * (Math.random() * 2 - 1);
    return Math.floor(exponentialDelay + jitter);
  }

  /**
   * Perform database integrity check
   */
  integrityCheck(): { status: string; details?: string } {
    try {
      const stmt = this.db.prepare('PRAGMA integrity_check');
      const result = stmt.get() as { integrity_check: string };
      
      if (result.integrity_check === 'ok') {
        return { status: 'ok' };
      } else {
        return { status: 'error', details: result.integrity_check };
      }
    } catch (error) {
      return { 
        status: 'error', 
        details: error instanceof Error ? error.message : 'Unknown error' 
      };
    }
  }

  /**
   * Close the database connection
   */
  close(): void {
    this.db.close();
  }
}