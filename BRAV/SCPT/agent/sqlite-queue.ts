#!/usr/bin/env node

/**
 * SQLite Queue Manager - SQLite-based queue with offline isolation
 * 
 * This module provides a robust queue system using SQLite with WAL mode
 * for better concurrency and offline isolation capabilities.
 */

import { Database } from 'sqlite3';
import { promises as fs } from 'fs';
import path from 'path';
import crypto from 'crypto';

interface QueueJob {
  id: string;
  type: string;
  priority: number;
  payload: any;
  status: 'pending' | 'processing' | 'completed' | 'failed' | 'retrying';
  createdAt: string;
  startedAt?: string;
  completedAt?: string;
  attempts: number;
  maxAttempts: number;
  agentId?: string;
  metadata: any;
}

interface QueueConfig {
  dbPath: string;
  walMode: boolean;
  maxRetries: number;
  retryDelay: number;
  maxConcurrentJobs: number;
  offlineMode: boolean;
}

class SQLiteQueueManager {
  private db: Database;
  private config: QueueConfig;
  private isOffline: boolean = false;
  private processingJobs: Set<string> = new Set();

  constructor(config: Partial<QueueConfig> = {}) {
    this.config = {
      dbPath: '.agent/queue.db',
      walMode: true,
      maxRetries: 3,
      retryDelay: 5000,
      maxConcurrentJobs: 5,
      offlineMode: false,
      ...config
    };

    this.db = new Database(this.config.dbPath);
    this.initializeDatabase();
    this.setupOfflineDetection();
  }

  private async initializeDatabase(): Promise<void> {
    return new Promise((resolve, reject) => {
      const ensureColumn = (column: string, definition: string) => {
        this.db.run(`ALTER TABLE jobs ADD COLUMN ${definition}`, (err) => {
          if (err && !/duplicate column name/i.test(err.message)) {
            console.warn(`Failed to ensure column ${column}: ${err.message}`);
          }
        });
      };

      this.db.serialize(() => {
        // Enable WAL mode for better concurrency
        if (this.config.walMode) {
          this.db.run('PRAGMA journal_mode=WAL', (err) => {
            if (err) {
              console.warn('Failed to enable WAL mode:', err.message);
            }
          });
        }

        // Create jobs table
        this.db.run(`
          CREATE TABLE IF NOT EXISTS jobs (
            id TEXT PRIMARY KEY,
            type TEXT NOT NULL,
            priority INTEGER DEFAULT 0,
            payload TEXT NOT NULL,
            status TEXT DEFAULT 'pending',
            created_at TEXT NOT NULL,
            started_at TEXT,
            completed_at TEXT,
            attempts INTEGER DEFAULT 0,
            max_attempts INTEGER DEFAULT 3,
            agent_id TEXT,
            metadata TEXT DEFAULT '{}'
          )
        `);
        ensureColumn('agent_id', 'agent_id TEXT');
        ensureColumn('metadata', "metadata TEXT DEFAULT '{}'");
        this.db.run(`CREATE INDEX IF NOT EXISTS idx_jobs_status_priority ON jobs (status, priority DESC)`);
        this.db.run(`CREATE INDEX IF NOT EXISTS idx_jobs_created_at ON jobs (created_at)`);
        this.db.run(`CREATE INDEX IF NOT EXISTS idx_jobs_agent_id ON jobs (agent_id)`);

        // Create job history table for audit trail
        this.db.run(`
          CREATE TABLE IF NOT EXISTS job_history (
            id TEXT PRIMARY KEY,
            job_id TEXT NOT NULL,
            status TEXT NOT NULL,
            timestamp TEXT NOT NULL,
            message TEXT,
            metadata TEXT DEFAULT '{}',
            FOREIGN KEY (job_id) REFERENCES jobs (id)
          )
        `);

        // Create queue metrics table
        this.db.run(`
          CREATE TABLE IF NOT EXISTS queue_metrics (
            id TEXT PRIMARY KEY,
            timestamp TEXT NOT NULL,
            pending_count INTEGER DEFAULT 0,
            processing_count INTEGER DEFAULT 0,
            completed_count INTEGER DEFAULT 0,
            failed_count INTEGER DEFAULT 0,
            avg_processing_time REAL DEFAULT 0,
            throughput_per_minute REAL DEFAULT 0
          )
        `);

        resolve();
      });
    });
  }

  private setupOfflineDetection(): void {
    // Check for offline mode file
    const offlineFile = '.agent/OFFLINE';
    
    const checkOffline = async () => {
      try {
        await fs.access(offlineFile);
        this.isOffline = true;
        console.log('📴 Queue operating in offline mode');
      } catch {
        this.isOffline = false;
      }
    };

    checkOffline();
    
    // Check every 30 seconds
    setInterval(checkOffline, 30000);
  }

  async enqueue(job: Omit<QueueJob, 'id' | 'status' | 'createdAt' | 'attempts'>): Promise<string> {
    const jobId = this.generateJobId();
    const now = new Date().toISOString();

    const fullJob: QueueJob = {
      id: jobId,
      status: 'pending',
      createdAt: now,
      attempts: 0,
      ...job
    };

    return new Promise((resolve, reject) => {
      this.db.run(
        `INSERT INTO jobs (id, type, priority, payload, status, created_at, attempts, max_attempts, agent_id, metadata)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
        [
          fullJob.id,
          fullJob.type,
          fullJob.priority,
          JSON.stringify(fullJob.payload),
          fullJob.status,
          fullJob.createdAt,
          fullJob.attempts,
          fullJob.maxAttempts,
          fullJob.agentId || null,
          JSON.stringify(fullJob.metadata)
        ],
        function(err) {
          if (err) {
            reject(err);
          } else {
            resolve(jobId);
          }
        }
      );
    });
  }

  async dequeue(agentId: string, maxJobs: number = 1): Promise<QueueJob[]> {
    return new Promise((resolve, reject) => {
      // Get jobs that are not being processed and within concurrency limits
      this.db.all(
        `SELECT * FROM jobs 
         WHERE status = 'pending' 
         AND (agent_id IS NULL OR agent_id = ?)
         AND id NOT IN (SELECT id FROM jobs WHERE status = 'processing')
         ORDER BY priority DESC, created_at ASC 
         LIMIT ?`,
        [agentId, maxJobs],
        (err, rows) => {
          if (err) {
            reject(err);
            return;
          }

          const jobs = rows.map(this.mapRowToJob);
          
          // Mark jobs as processing
          if (jobs.length > 0) {
            const jobIds = jobs.map(job => job.id);
            this.markJobsAsProcessing(jobIds, agentId)
              .then(() => resolve(jobs))
              .catch(reject);
          } else {
            resolve([]);
          }
        }
      );
    });
  }

  private async markJobsAsProcessing(jobIds: string[], agentId: string): Promise<void> {
    return new Promise((resolve, reject) => {
      const placeholders = jobIds.map(() => '?').join(',');
      const now = new Date().toISOString();

      this.db.run(
        `UPDATE jobs 
         SET status = 'processing', started_at = ?, agent_id = ?, attempts = attempts + 1
         WHERE id IN (${placeholders})`,
        [now, agentId, ...jobIds],
        (err) => {
          if (err) reject(err);
          else resolve();
        }
      );
    });
  }

  async completeJob(jobId: string, result?: any): Promise<void> {
    return this.updateJobStatus(jobId, 'completed', result);
  }

  async failJob(jobId: string, error: string, shouldRetry: boolean = true): Promise<void> {
    const job = await this.getJob(jobId);
    
    if (!job) {
      throw new Error(`Job ${jobId} not found`);
    }

    if (shouldRetry && job.attempts < job.maxAttempts) {
      // Retry the job
      await this.updateJobStatus(jobId, 'retrying', { error, retryAt: Date.now() + this.config.retryDelay });
      
      // Schedule retry
      setTimeout(() => {
        this.db.run(
          'UPDATE jobs SET status = ? WHERE id = ?',
          ['pending', jobId],
          (err) => {
            if (err) console.error('Failed to reset job status:', err);
          }
        );
      }, this.config.retryDelay);
    } else {
      // Mark as permanently failed
      await this.updateJobStatus(jobId, 'failed', { error, finalAttempt: true });
    }
  }

  private async updateJobStatus(jobId: string, status: string, metadata?: any): Promise<void> {
    return new Promise((resolve, reject) => {
      const now = new Date().toISOString();
      const updates: any = { status };
      
      if (status === 'completed' || status === 'failed') {
        updates.completed_at = now;
      }

      let query = 'UPDATE jobs SET status = ?, completed_at = ?';
      let params: any[] = [status, updates.completed_at];

      if (metadata) {
        query += ', metadata = ?';
        params.push(JSON.stringify(metadata));
      }

      query += ' WHERE id = ?';
      params.push(jobId);

      this.db.run(query, params, (err) => {
        if (err) {
          reject(err);
        } else {
          // Log to history
          this.logJobHistory(jobId, status, metadata?.error || 'Job completed')
            .then(() => resolve())
            .catch(reject);
        }
      });
    });
  }

  private async logJobHistory(jobId: string, status: string, message: string): Promise<void> {
    return new Promise((resolve, reject) => {
      const historyId = this.generateJobId();
      const now = new Date().toISOString();

      this.db.run(
        'INSERT INTO job_history (id, job_id, status, timestamp, message) VALUES (?, ?, ?, ?, ?)',
        [historyId, jobId, status, now, message],
        (err) => {
          if (err) reject(err);
          else resolve();
        }
      );
    });
  }

  async getJob(jobId: string): Promise<QueueJob | null> {
    return new Promise((resolve, reject) => {
      this.db.get(
        'SELECT * FROM jobs WHERE id = ?',
        [jobId],
        (err, row) => {
          if (err) {
            reject(err);
          } else if (row) {
            resolve(this.mapRowToJob(row));
          } else {
            resolve(null);
          }
        }
      );
    });
  }

  async getQueueStats(): Promise<any> {
    return new Promise((resolve, reject) => {
      this.db.all(
        `SELECT 
           status,
           COUNT(*) as count,
           AVG(CASE WHEN completed_at IS NOT NULL 
               THEN (julianday(completed_at) - julianday(started_at)) * 24 * 60 * 60 * 1000 
               ELSE NULL END) as avg_processing_time_ms
         FROM jobs 
         GROUP BY status`,
        (err, rows) => {
          if (err) {
            reject(err);
          } else {
            const stats: any = {};
            rows.forEach((row: any) => {
              stats[row.status] = {
                count: row.count,
                avgProcessingTime: row.avg_processing_time_ms || 0
              };
            });
            resolve(stats);
          }
        }
      );
    });
  }

  async getJobHistory(jobId: string): Promise<any[]> {
    return new Promise((resolve, reject) => {
      this.db.all(
        'SELECT * FROM job_history WHERE job_id = ? ORDER BY timestamp ASC',
        [jobId],
        (err, rows) => {
          if (err) reject(err);
          else resolve(rows);
        }
      );
    });
  }

  async cleanupOldJobs(olderThanDays: number = 7): Promise<number> {
    return new Promise((resolve, reject) => {
      const cutoffDate = new Date();
      cutoffDate.setDate(cutoffDate.getDate() - olderThanDays);
      const cutoffISO = cutoffDate.toISOString();

      this.db.run(
        'DELETE FROM jobs WHERE completed_at IS NOT NULL AND completed_at < ?',
        [cutoffISO],
        function(err) {
          if (err) {
            reject(err);
          } else {
            resolve(this.changes);
          }
        }
      );
    });
  }

  async exportQueueData(): Promise<any> {
    return new Promise((resolve, reject) => {
      this.db.all(
        'SELECT * FROM jobs ORDER BY created_at DESC',
        (err, jobs) => {
          if (err) {
            reject(err);
            return;
          }

          this.db.all(
            'SELECT * FROM job_history ORDER BY timestamp DESC',
            (err, history) => {
              if (err) {
                reject(err);
                return;
              }

              resolve({
                jobs: jobs.map(this.mapRowToJob),
                history,
                exportedAt: new Date().toISOString()
              });
            }
          );
        }
      );
    });
  }

  async importQueueData(data: any): Promise<void> {
    return new Promise((resolve, reject) => {
      this.db.serialize(() => {
        this.db.run('BEGIN TRANSACTION');

        // Import jobs
        const jobStmt = this.db.prepare(`
          INSERT OR REPLACE INTO jobs 
          (id, type, priority, payload, status, created_at, started_at, completed_at, attempts, max_attempts, agent_id, metadata)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        `);

        data.jobs.forEach((job: QueueJob) => {
          jobStmt.run(
            job.id,
            job.type,
            job.priority,
            JSON.stringify(job.payload),
            job.status,
            job.createdAt,
            job.startedAt || null,
            job.completedAt || null,
            job.attempts,
            job.maxAttempts,
            job.agentId || null,
            JSON.stringify(job.metadata)
          );
        });

        jobStmt.finalize();

        // Import history
        const historyStmt = this.db.prepare(`
          INSERT OR REPLACE INTO job_history 
          (id, job_id, status, timestamp, message, metadata)
          VALUES (?, ?, ?, ?, ?, ?)
        `);

        data.history.forEach((entry: any) => {
          historyStmt.run(
            entry.id,
            entry.job_id,
            entry.status,
            entry.timestamp,
            entry.message,
            JSON.stringify(entry.metadata || {})
          );
        });

        historyStmt.finalize();

        this.db.run('COMMIT', (err) => {
          if (err) {
            this.db.run('ROLLBACK');
            reject(err);
          } else {
            resolve();
          }
        });
      });
    });
  }

  private mapRowToJob(row: any): QueueJob {
    return {
      id: row.id,
      type: row.type,
      priority: row.priority,
      payload: JSON.parse(row.payload),
      status: row.status,
      createdAt: row.created_at,
      startedAt: row.started_at,
      completedAt: row.completed_at,
      attempts: row.attempts,
      maxAttempts: row.max_attempts,
      agentId: row.agent_id,
      metadata: JSON.parse(row.metadata || '{}')
    };
  }

  private generateJobId(): string {
    return `job-${Date.now()}-${crypto.randomBytes(8).toString('hex')}`;
  }

  async close(): Promise<void> {
    return new Promise((resolve, reject) => {
      this.db.close((err) => {
        if (err) reject(err);
        else resolve();
      });
    });
  }

  // Offline isolation methods
  async enableOfflineMode(): Promise<void> {
    await fs.writeFile('.agent/OFFLINE', JSON.stringify({
      enabled: true,
      timestamp: new Date().toISOString(),
      reason: 'Manual offline mode activation'
    }));
    this.isOffline = true;
  }

  async disableOfflineMode(): Promise<void> {
    try {
      await fs.unlink('.agent/OFFLINE');
    } catch {
      // File might not exist
    }
    this.isOffline = false;
  }

  isOfflineMode(): boolean {
    return this.isOffline;
  }
}

// Main execution for testing
if (require.main === module) {
  const queue = new SQLiteQueueManager();
  
  // Test the queue
  async function testQueue() {
    try {
      // Enqueue a test job
      const jobId = await queue.enqueue({
        type: 'test',
        priority: 1,
        payload: { message: 'Hello World' },
        maxAttempts: 3,
        metadata: { test: true }
      });
      
      console.log('Enqueued job:', jobId);
      
      // Dequeue the job
      const jobs = await queue.dequeue('test-agent', 1);
      console.log('Dequeued jobs:', jobs);
      
      // Complete the job
      if (jobs.length > 0) {
        await queue.completeJob(jobs[0].id, { result: 'success' });
        console.log('Job completed');
      }
      
      // Get stats
      const stats = await queue.getQueueStats();
      console.log('Queue stats:', stats);
      
    } catch (error) {
      console.error('Test failed:', error);
    } finally {
      await queue.close();
    }
  }
  
  testQueue();
}

export { SQLiteQueueManager, QueueJob, QueueConfig };
