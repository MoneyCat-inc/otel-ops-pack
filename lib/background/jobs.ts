// Resonai Backend - Background Job System
// Handles cleanup tasks, maintenance, and scheduled operations

import { trace } from '@opentelemetry/api';
import { db } from '@/lib/db';
import { SessionManager } from '@/lib/middleware/auth';
import { CoachGrantManager } from '@/lib/encryption/coach-portal';
import { resonaiMetrics } from '@/lib/observability/signoz';

// Background job types
export enum JobType {
  SESSION_CLEANUP = 'SESSION_CLEANUP',
  COACH_GRANT_CLEANUP = 'COACH_GRANT_CLEANUP',
  DATA_EXPORT_CLEANUP = 'DATA_EXPORT_CLEANUP',
  EVENT_RETENTION_CLEANUP = 'EVENT_RETENTION_CLEANUP',
  MAGIC_LINK_CLEANUP = 'MAGIC_LINK_CLEANUP',
  ENGAGEMENT_ROLLUP = 'ENGAGEMENT_ROLLUP',
  COHORT_ANALYTICS = 'COHORT_ANALYTICS',
  HEALTH_CHECK = 'HEALTH_CHECK',
}

export enum JobStatus {
  PENDING = 'PENDING',
  RUNNING = 'RUNNING',
  COMPLETED = 'COMPLETED',
  FAILED = 'FAILED',
  RETRYING = 'RETRYING',
}

// Background job manager
export class BackgroundJobManager {
  private static instance: BackgroundJobManager;
  private isRunning = false;
  private intervalId: NodeJS.Timeout | null = null;

  private constructor() {}

  static getInstance(): BackgroundJobManager {
    if (!BackgroundJobManager.instance) {
      BackgroundJobManager.instance = new BackgroundJobManager();
    }
    return BackgroundJobManager.instance;
  }

  // Start the background job processor
  start(): void {
    if (this.isRunning) {
      console.log('Background job manager is already running');
      return;
    }

    this.isRunning = true;
    console.log('🔄 Starting background job manager...');

    // Process jobs every 5 minutes
    this.intervalId = setInterval(async () => {
      await this.processJobs();
    }, 5 * 60 * 1000);

    // Run initial job processing
    this.processJobs().catch(error => {
      console.error('Initial job processing failed:', error);
    });
  }

  // Stop the background job processor
  stop(): void {
    if (this.intervalId) {
      clearInterval(this.intervalId);
      this.intervalId = null;
    }
    this.isRunning = false;
    console.log('⏹️ Background job manager stopped');
  }

  // Process pending jobs
  private async processJobs(): Promise<void> {
    const span = trace.getActiveSpan();
    
    try {
      // Get pending jobs
      const pendingJobs = await db.backgroundJob.findMany({
        where: {
          status: JobStatus.PENDING,
        },
        orderBy: { createdAt: 'asc' },
        take: 10, // Process up to 10 jobs at a time
      });

      if (pendingJobs.length === 0) {
        return;
      }

      span?.setAttributes({
        'background.jobs_processing': true,
        'background.jobs_count': pendingJobs.length,
      });

      // Process each job
      for (const job of pendingJobs) {
        await this.executeJob(job);
      }

    } catch (error) {
      span?.setAttributes({
        'background.job_processing_error': true,
        'background.error.message': error instanceof Error ? error.message : 'Unknown error'
      });

      console.error('Failed to process background jobs:', error);
    }
  }

  // Execute a single job
  private async executeJob(job: any): Promise<void> {
    const span = trace.getActiveSpan();
    
    try {
      // Update job status to running
      await db.backgroundJob.update({
        where: { id: job.id },
        data: {
          status: JobStatus.RUNNING,
          startedAt: new Date(),
        }
      });

      span?.setAttributes({
        'background.job_started': true,
        'background.job_id': job.id,
        'background.job_type': job.type,
      });

      // Execute the job based on type
      let result: any;
      switch (job.type) {
        case JobType.SESSION_CLEANUP:
          result = await this.cleanupExpiredSessions();
          break;
        case JobType.COACH_GRANT_CLEANUP:
          result = await this.cleanupExpiredCoachGrants();
          break;
        case JobType.DATA_EXPORT_CLEANUP:
          result = await this.cleanupExpiredDataExports();
          break;
        case JobType.EVENT_RETENTION_CLEANUP:
          result = await this.cleanupOldEvents();
          break;
        case JobType.MAGIC_LINK_CLEANUP:
          result = await this.cleanupExpiredMagicLinks();
          break;
        case JobType.ENGAGEMENT_ROLLUP:
          result = await this.processEngagementRollup();
          break;
        case JobType.COHORT_ANALYTICS:
          result = await this.processCohortAnalytics();
          break;
        case JobType.HEALTH_CHECK:
          result = await this.performHealthCheck();
          break;
        default:
          throw new Error(`Unknown job type: ${job.type}`);
      }

      // Update job status to completed
      await db.backgroundJob.update({
        where: { id: job.id },
        data: {
          status: JobStatus.COMPLETED,
          completedAt: new Date(),
        }
      });

      span?.setAttributes({
        'background.job_completed': true,
        'background.job_id': job.id,
        'background.job_result': JSON.stringify(result),
      });

      console.log(`✅ Background job ${job.type} completed successfully`);

    } catch (error) {
      // Update job status to failed
      await db.backgroundJob.update({
        where: { id: job.id },
        data: {
          status: JobStatus.FAILED,
          error: error instanceof Error ? error.message : 'Unknown error',
          completedAt: new Date(),
        }
      });

      span?.setAttributes({
        'background.job_failed': true,
        'background.job_id': job.id,
        'background.job_error': error instanceof Error ? error.message : 'Unknown error',
      });

      console.error(`❌ Background job ${job.type} failed:`, error);
    }
  }

  // Schedule a new job
  async scheduleJob(type: JobType, payload?: any): Promise<string> {
    const span = trace.getActiveSpan();
    
    try {
      const job = await db.backgroundJob.create({
        data: {
          type,
          status: JobStatus.PENDING,
          payload: payload || {},
        }
      });

      span?.setAttributes({
        'background.job_scheduled': true,
        'background.job_id': job.id,
        'background.job_type': type,
      });

      console.log(`📅 Scheduled background job: ${type} (ID: ${job.id})`);
      return job.id;

    } catch (error) {
      span?.setAttributes({
        'background.job_scheduling_error': true,
        'background.job_type': type,
        'background.error': error instanceof Error ? error.message : 'Unknown error',
      });

      console.error(`Failed to schedule job ${type}:`, error);
      throw error;
    }
  }

  // Cleanup expired sessions
  private async cleanupExpiredSessions(): Promise<{ cleaned: number }> {
    const span = trace.getActiveSpan();
    
    try {
      const cleaned = await SessionManager.cleanupExpiredSessions();
      
      span?.setAttributes({
        'background.session_cleanup': true,
        'background.sessions_cleaned': cleaned,
      });

      return { cleaned };
    } catch (error) {
      span?.setAttributes({
        'background.session_cleanup_error': true,
        'background.error': error instanceof Error ? error.message : 'Unknown error',
      });
      throw error;
    }
  }

  // Cleanup expired coach grants
  private async cleanupExpiredCoachGrants(): Promise<{ cleaned: number }> {
    const span = trace.getActiveSpan();
    
    try {
      const cleaned = await CoachGrantManager.cleanupExpiredGrants();
      
      span?.setAttributes({
        'background.coach_grant_cleanup': true,
        'background.grants_cleaned': cleaned,
      });

      return { cleaned };
    } catch (error) {
      span?.setAttributes({
        'background.coach_grant_cleanup_error': true,
        'background.error': error instanceof Error ? error.message : 'Unknown error',
      });
      throw error;
    }
  }

  // Cleanup expired data exports
  private async cleanupExpiredDataExports(): Promise<{ cleaned: number }> {
    const span = trace.getActiveSpan();
    
    try {
      const result = await db.dataExport.deleteMany({
        where: {
          expiresAt: {
            lt: new Date()
          }
        }
      });

      span?.setAttributes({
        'background.data_export_cleanup': true,
        'background.exports_cleaned': result.count,
      });

      return { cleaned: result.count };
    } catch (error) {
      span?.setAttributes({
        'background.data_export_cleanup_error': true,
        'background.error': error instanceof Error ? error.message : 'Unknown error',
      });
      throw error;
    }
  }

  // Cleanup old events (privacy compliance)
  private async cleanupOldEvents(): Promise<{ cleaned: number }> {
    const span = trace.getActiveSpan();
    
    try {
      const retentionMs = parseInt(process.env.EVENT_RETENTION_MS || '3600000'); // 1 hour default
      const cutoffDate = new Date(Date.now() - retentionMs);

      const result = await db.event.deleteMany({
        where: {
          ts: {
            lt: cutoffDate
          }
        }
      });

      span?.setAttributes({
        'background.event_cleanup': true,
        'background.events_cleaned': result.count,
        'background.retention_hours': retentionMs / (1000 * 60 * 60),
      });

      return { cleaned: result.count };
    } catch (error) {
      span?.setAttributes({
        'background.event_cleanup_error': true,
        'background.error': error instanceof Error ? error.message : 'Unknown error',
      });
      throw error;
    }
  }

  // Cleanup expired magic links
  private async cleanupExpiredMagicLinks(): Promise<{ cleaned: number }> {
    const span = trace.getActiveSpan();
    
    try {
      const result = await db.magicLink.deleteMany({
        where: {
          OR: [
            { expiresAt: { lt: new Date() } },
            { used: true }
          ]
        }
      });

      span?.setAttributes({
        'background.magic_link_cleanup': true,
        'background.links_cleaned': result.count,
      });

      return { cleaned: result.count };
    } catch (error) {
      span?.setAttributes({
        'background.magic_link_cleanup_error': true,
        'background.error': error instanceof Error ? error.message : 'Unknown error',
      });
      throw error;
    }
  }

  // Process engagement rollup (daily streak updates)
  private async processEngagementRollup(): Promise<{ processed: number }> {
    const span = trace.getActiveSpan();
    
    try {
      // Get users who haven't practiced today
      const yesterday = new Date();
      yesterday.setDate(yesterday.getDate() - 1);
      yesterday.setHours(0, 0, 0, 0);

      const usersToUpdate = await db.engagementProfile.findMany({
        where: {
          lastPracticeAt: {
            lt: yesterday
          }
        },
        select: { userId: true }
      });

      let processed = 0;
      for (const profile of usersToUpdate) {
        // Reset streak if no practice in 24+ hours
        await db.engagementProfile.update({
          where: { userId: profile.userId },
          data: {
            streakDays: 0,
            lastSyncAt: new Date(),
          }
        });
        processed++;
      }

      span?.setAttributes({
        'background.engagement_rollup': true,
        'background.users_processed': processed,
      });

      return { processed };
    } catch (error) {
      span?.setAttributes({
        'background.engagement_rollup_error': true,
        'background.error': error instanceof Error ? error.message : 'Unknown error',
      });
      throw error;
    }
  }

  // Process cohort analytics
  private async processCohortAnalytics(): Promise<{ cohorts: number }> {
    const span = trace.getActiveSpan();
    
    try {
      // Get cohort statistics
      const cohortStats = await db.event.groupBy({
        by: ['cohort'],
        _count: { cohort: true },
        where: {
          ts: {
            gte: new Date(Date.now() - 24 * 60 * 60 * 1000) // Last 24 hours
          }
        }
      });

      // Track cohort analytics
      cohortStats.forEach(stat => {
        resonaiMetrics.trackEngagementEvent({
          userId: 'system',
          eventType: 'cohort_analytics',
          metadata: {
            cohort: stat.cohort,
            eventCount: stat._count.cohort,
            timestamp: Date.now(),
          }
        });
      });

      span?.setAttributes({
        'background.cohort_analytics': true,
        'background.cohorts_processed': cohortStats.length,
      });

      return { cohorts: cohortStats.length };
    } catch (error) {
      span?.setAttributes({
        'background.cohort_analytics_error': true,
        'background.error': error instanceof Error ? error.message : 'Unknown error',
      });
      throw error;
    }
  }

  // Perform system health check
  private async performHealthCheck(): Promise<{ status: string }> {
    const span = trace.getActiveSpan();
    
    try {
      // Check database health
      const dbHealth = await db.$queryRaw`SELECT 1`;
      
      // Check job queue health
      const pendingJobs = await db.backgroundJob.count({
        where: { status: JobStatus.PENDING }
      });

      const failedJobs = await db.backgroundJob.count({
        where: { status: JobStatus.FAILED }
      });

      const status = failedJobs > 10 ? 'degraded' : 'healthy';

      span?.setAttributes({
        'background.health_check': true,
        'background.status': status,
        'background.pending_jobs': pendingJobs,
        'background.failed_jobs': failedJobs,
      });

      return { status };
    } catch (error) {
      span?.setAttributes({
        'background.health_check_error': true,
        'background.error': error instanceof Error ? error.message : 'Unknown error',
      });
      throw error;
    }
  }
}

// Scheduled job functions
export class ScheduledJobs {
  // Schedule daily cleanup jobs
  static async scheduleDailyCleanup(): Promise<void> {
    const jobManager = BackgroundJobManager.getInstance();
    
    await Promise.all([
      jobManager.scheduleJob(JobType.SESSION_CLEANUP),
      jobManager.scheduleJob(JobType.COACH_GRANT_CLEANUP),
      jobManager.scheduleJob(JobType.DATA_EXPORT_CLEANUP),
      jobManager.scheduleJob(JobType.EVENT_RETENTION_CLEANUP),
      jobManager.scheduleJob(JobType.MAGIC_LINK_CLEANUP),
    ]);

    console.log('📅 Daily cleanup jobs scheduled');
  }

  // Schedule hourly maintenance jobs
  static async scheduleHourlyMaintenance(): Promise<void> {
    const jobManager = BackgroundJobManager.getInstance();
    
    await Promise.all([
      jobManager.scheduleJob(JobType.ENGAGEMENT_ROLLUP),
      jobManager.scheduleJob(JobType.COHORT_ANALYTICS),
      jobManager.scheduleJob(JobType.HEALTH_CHECK),
    ]);

    console.log('⏰ Hourly maintenance jobs scheduled');
  }

  // Schedule weekly analytics jobs
  static async scheduleWeeklyAnalytics(): Promise<void> {
    const jobManager = BackgroundJobManager.getInstance();
    
    await jobManager.scheduleJob(JobType.COHORT_ANALYTICS, {
      timeRange: '7d',
      generateReport: true,
    });

    console.log('📊 Weekly analytics jobs scheduled');
  }
}

// Initialize background job manager
export function initializeBackgroundJobs(): void {
  const jobManager = BackgroundJobManager.getInstance();
  jobManager.start();

  // Schedule initial jobs
  ScheduledJobs.scheduleDailyCleanup().catch(console.error);
  ScheduledJobs.scheduleHourlyMaintenance().catch(console.error);

  console.log('🔄 Background job system initialized');
}

// Export instances
export const backgroundJobManager = BackgroundJobManager.getInstance();
