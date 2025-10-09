/**
 * Unit tests for SQLite Queue Database
 */

import { SQLiteQueueDB } from './db';
import { QueueConfig } from '../../lib/config/queue';
import { unlinkSync } from 'fs';

describe('SQLiteQueueDB', () => {
  let db: SQLiteQueueDB;
  let config: QueueConfig;
  const testDbPath = '.agent/test-queue.db';

  beforeEach(() => {
    // Clean up any existing test database
    try {
      unlinkSync(testDbPath);
    } catch (error) {
      // File doesn't exist, that's fine
    }

    config = {
      driver: 'sqlite',
      wal: false, // Disable WAL for tests
      shadow: true,
      enabled: true,
      maxJobs: 10,
      maxConcurrency: 2,
      maxAttempts: 3,
      baseDelayMs: 1000,
      jitterFactor: 0.15,
    };

    db = new SQLiteQueueDB(testDbPath, config);
  });

  afterEach(() => {
    if (db) {
      db.close();
    }
    try {
      unlinkSync(testDbPath);
    } catch (error) {
      // File doesn't exist, that's fine
    }
  });

  describe('Schema initialization', () => {
    it('should create tables and indexes', () => {
      // Test that we can add a job (which requires tables to exist)
      const jobId = db.addJob({
        kind: 'test',
        payload_json: '{"test": true}',
        priority: 0,
        max_attempts: 3,
        not_before: Date.now(),
        created_at: Date.now(),
        ttl_ms: 86400000,
      });

      expect(jobId).toBeTruthy();
      expect(jobId).toMatch(/^job_\d+_[a-z0-9]+$/);
    });
  });

  describe('Job management', () => {
    it('should add and retrieve jobs', () => {
      const now = Date.now();
      const jobId = db.addJob({
        kind: 'test-job',
        payload_json: '{"message": "hello"}',
        priority: 5,
        max_attempts: 3,
        not_before: now,
        created_at: now,
        ttl_ms: 3600000,
      });

      const job = db.getJob(jobId);
      expect(job).toBeTruthy();
      expect(job?.kind).toBe('test-job');
      expect(job?.payload_json).toBe('{"message": "hello"}');
      expect(job?.priority).toBe(5);
      expect(job?.status).toBe('pending');
      expect(job?.attempts).toBe(0);
    });

    it('should get next jobs in priority order', () => {
      const now = Date.now();
      
      // Add jobs with different priorities
      db.addJob({
        kind: 'low-priority',
        payload_json: '{}',
        priority: 1,
        max_attempts: 3,
        not_before: now,
        created_at: now,
        ttl_ms: 86400000,
      });

      db.addJob({
        kind: 'high-priority',
        payload_json: '{}',
        priority: 10,
        max_attempts: 3,
        not_before: now,
        created_at: now,
        ttl_ms: 86400000,
      });

      const nextJobs = db.getNextJobs(10);
      expect(nextJobs).toHaveLength(2);
      expect(nextJobs[0].priority).toBe(10); // High priority first
      expect(nextJobs[0].kind).toBe('high-priority');
    });

    it('should respect not_before timestamp', () => {
      const future = Date.now() + 60000; // 1 minute in future
      
      db.addJob({
        kind: 'future-job',
        payload_json: '{}',
        priority: 10,
        max_attempts: 3,
        not_before: future,
        created_at: Date.now(),
        ttl_ms: 86400000,
      });

      const nextJobs = db.getNextJobs(10);
      expect(nextJobs).toHaveLength(0); // Should not be ready yet
    });

    it('should mark jobs as running', () => {
      const now = Date.now();
      const jobId = db.addJob({
        kind: 'test',
        payload_json: '{}',
        priority: 0,
        max_attempts: 3,
        not_before: now,
        created_at: now,
        ttl_ms: 86400000,
      });

      const success = db.markJobRunning(jobId);
      expect(success).toBe(true);

      const job = db.getJob(jobId);
      expect(job?.status).toBe('running');
      expect(job?.attempts).toBe(1);
    });

    it('should mark jobs as completed', () => {
      const now = Date.now();
      const jobId = db.addJob({
        kind: 'test',
        payload_json: '{}',
        priority: 0,
        max_attempts: 3,
        not_before: now,
        created_at: now,
        ttl_ms: 86400000,
      });

      db.markJobRunning(jobId);
      const success = db.markJobCompleted(jobId);
      expect(success).toBe(true);

      const job = db.getJob(jobId);
      expect(job?.status).toBe('completed');
    });

    it('should handle job failures with retry logic', () => {
      const now = Date.now();
      const jobId = db.addJob({
        kind: 'test',
        payload_json: '{}',
        priority: 0,
        max_attempts: 3,
        not_before: now,
        created_at: now,
        ttl_ms: 86400000,
      });

      // First failure - should retry
      db.markJobRunning(jobId);
      const retrySuccess = db.markJobFailed(jobId);
      expect(retrySuccess).toBe(true);

      let job = db.getJob(jobId);
      expect(job?.status).toBe('pending'); // Should be retried
      expect(job?.attempts).toBe(1);
      expect(job?.not_before).toBeGreaterThan(now); // Should be scheduled for later

      // Second failure - should retry again
      db.markJobRunning(jobId);
      db.markJobFailed(jobId);

      job = db.getJob(jobId);
      expect(job?.status).toBe('pending');
      expect(job?.attempts).toBe(2);

      // Third failure - should fail permanently
      db.markJobRunning(jobId);
      db.markJobFailed(jobId);

      job = db.getJob(jobId);
      expect(job?.status).toBe('failed');
      expect(job?.attempts).toBe(3);
    });
  });

  describe('Run management', () => {
    it('should add and retrieve runs', () => {
      const now = Date.now();
      const jobId = db.addJob({
        kind: 'test',
        payload_json: '{}',
        priority: 0,
        max_attempts: 3,
        not_before: now,
        created_at: now,
        ttl_ms: 86400000,
      });

      const runId = db.addRun({
        job_id: jobId,
        started_at: now,
        finished_at: now + 1000,
        exit_code: 0,
        stdout: 'Success',
        stderr: '',
        metrics_json: '{"duration_ms": 1000}',
      });

      expect(runId).toBeTruthy();
      expect(runId).toMatch(/^run_\d+_[a-z0-9]+$/);

      const runs = db.getJobRuns(jobId);
      expect(runs).toHaveLength(1);
      expect(runs[0].job_id).toBe(jobId);
      expect(runs[0].exit_code).toBe(0);
      expect(runs[0].stdout).toBe('Success');
    });
  });

  describe('Queue statistics', () => {
    it('should provide accurate queue statistics', () => {
      const now = Date.now();
      
      // Add jobs in different states
      const job1 = db.addJob({
        kind: 'pending',
        payload_json: '{}',
        priority: 0,
        max_attempts: 3,
        not_before: now,
        created_at: now,
        ttl_ms: 86400000,
      });

      const job2 = db.addJob({
        kind: 'running',
        payload_json: '{}',
        priority: 0,
        max_attempts: 3,
        not_before: now,
        created_at: now,
        ttl_ms: 86400000,
      });

      db.markJobRunning(job2);

      const stats = db.getQueueStats();
      expect(stats.pending).toBe(1);
      expect(stats.running).toBe(1);
      expect(stats.completed).toBe(0);
      expect(stats.failed).toBe(0);
      expect(stats.total).toBe(2);
    });
  });

  describe('Cleanup operations', () => {
    it('should clean up expired jobs', () => {
      const oldTime = Date.now() - 86400000; // 24 hours ago
      
      // Add an expired job
      db.addJob({
        kind: 'expired',
        payload_json: '{}',
        priority: 0,
        max_attempts: 3,
        not_before: oldTime,
        created_at: oldTime,
        ttl_ms: 1000, // Very short TTL
      });

      // Add a non-expired job
      const now = Date.now();
      db.addJob({
        kind: 'current',
        payload_json: '{}',
        priority: 0,
        max_attempts: 3,
        not_before: now,
        created_at: now,
        ttl_ms: 86400000,
      });

      const cleaned = db.cleanupExpiredJobs();
      expect(cleaned).toBe(1);

      const stats = db.getQueueStats();
      expect(stats.total).toBe(1);
      expect(stats.pending).toBe(1);
    });
  });

  describe('Integrity checks', () => {
    it('should pass integrity check on clean database', () => {
      const result = db.integrityCheck();
      expect(result.status).toBe('ok');
    });
  });
});