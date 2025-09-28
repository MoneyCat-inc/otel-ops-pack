// Resonai Backend - Background Job API Routes
// Handles background job management and monitoring

import { NextRequest, NextResponse } from 'next/server';
import { trace } from '@opentelemetry/api';
import { backgroundJobManager, JobType, JobStatus } from '@/lib/background/jobs';
import { requireAuth } from '@/lib/middleware/auth';
import { withOTel } from '@/lib/middleware/otel';
import { withRateLimit, rateLimitConfigs } from '@/lib/middleware/rate-limit';
import { db } from '@/lib/db';

// POST /api/admin/jobs/schedule - Schedule a background job (admin only)
export const POST = withOTel(
  withRateLimit(rateLimitConfigs.user,
    requireAuth(async (req: NextRequest, { user }) => {
      const span = trace.getActiveSpan();
      
      try {
        // Check if user is admin
        const isAdmin = user.email?.endsWith('@resonai.app') || 
                        process.env.ADMIN_USER_IDS?.split(',').includes(user.id);

        if (!isAdmin) {
          span?.setAttributes({
            'admin.job_schedule_denied': true,
            'admin.user_id': user.id,
          });

          return NextResponse.json(
            {
              success: false,
              error: {
                code: 'INSUFFICIENT_PERMISSIONS',
                message: 'Admin access required'
              }
            },
            { status: 403 }
          );
        }

        const body = await req.json();
        const { jobType, payload } = body;

        if (!jobType || !Object.values(JobType).includes(jobType)) {
          return NextResponse.json(
            {
              success: false,
              error: {
                code: 'INVALID_JOB_TYPE',
                message: 'Invalid job type'
              }
            },
            { status: 400 }
          );
        }

        // Schedule the job
        const jobId = await backgroundJobManager.scheduleJob(jobType, payload);

        span?.setAttributes({
          'admin.job_scheduled': true,
          'admin.job_id': jobId,
          'admin.job_type': jobType,
          'admin.user_id': user.id,
        });

        return NextResponse.json({
          success: true,
          data: {
            jobId,
            jobType,
            status: 'PENDING',
            scheduledAt: new Date().toISOString(),
          },
          message: 'Background job scheduled successfully'
        });

      } catch (error) {
        span?.setAttributes({
          'admin.job_schedule_error': true,
          'admin.error.message': error instanceof Error ? error.message : 'Unknown error'
        });

        console.error('Failed to schedule background job:', error);

        return NextResponse.json(
          {
            success: false,
            error: {
              code: 'JOB_SCHEDULE_ERROR',
              message: 'Failed to schedule background job'
            }
          },
          { status: 500 }
        );
      }
    })
  )
);

// GET /api/admin/jobs - Get background job status (admin only)
export const GET = withOTel(
  withRateLimit(rateLimitConfigs.user,
    requireAuth(async (req: NextRequest, { user }) => {
      const span = trace.getActiveSpan();
      
      try {
        // Check if user is admin
        const isAdmin = user.email?.endsWith('@resonai.app') || 
                        process.env.ADMIN_USER_IDS?.split(',').includes(user.id);

        if (!isAdmin) {
          return NextResponse.json(
            {
              success: false,
              error: {
                code: 'INSUFFICIENT_PERMISSIONS',
                message: 'Admin access required'
              }
            },
            { status: 403 }
          );
        }

        const { searchParams } = new URL(req.url);
        const status = searchParams.get('status');
        const jobType = searchParams.get('jobType');
        const limit = parseInt(searchParams.get('limit') || '50');
        const offset = parseInt(searchParams.get('offset') || '0');

        // Build query conditions
        const whereConditions: any = {};
        
        if (status) {
          whereConditions.status = status.toUpperCase();
        }
        
        if (jobType) {
          whereConditions.type = jobType.toUpperCase();
        }

        // Get jobs
        const jobs = await db.backgroundJob.findMany({
          where: whereConditions,
          orderBy: { createdAt: 'desc' },
          take: Math.min(limit, 100), // Cap at 100
          skip: offset,
        });

        // Get job statistics
        const [
          totalJobs,
          pendingJobs,
          runningJobs,
          completedJobs,
          failedJobs,
        ] = await Promise.all([
          db.backgroundJob.count(),
          db.backgroundJob.count({ where: { status: JobStatus.PENDING } }),
          db.backgroundJob.count({ where: { status: JobStatus.RUNNING } }),
          db.backgroundJob.count({ where: { status: JobStatus.COMPLETED } }),
          db.backgroundJob.count({ where: { status: JobStatus.FAILED } }),
        ]);

        span?.setAttributes({
          'admin.jobs_retrieved': true,
          'admin.jobs_count': jobs.length,
          'admin.total_jobs': totalJobs,
          'admin.pending_jobs': pendingJobs,
          'admin.failed_jobs': failedJobs,
        });

        return NextResponse.json({
          success: true,
          data: {
            jobs: jobs.map(job => ({
              id: job.id,
              type: job.type,
              status: job.status,
              payload: job.payload,
              createdAt: job.createdAt,
              startedAt: job.startedAt,
              completedAt: job.completedAt,
              error: job.error,
              retryCount: job.retryCount,
            })),
            statistics: {
              total: totalJobs,
              pending: pendingJobs,
              running: runningJobs,
              completed: completedJobs,
              failed: failedJobs,
              successRate: totalJobs > 0 ? Math.round((completedJobs / totalJobs) * 100) : 0,
            },
            pagination: {
              limit,
              offset,
              total: totalJobs,
              hasMore: offset + jobs.length < totalJobs,
            }
          }
        });

      } catch (error) {
        span?.setAttributes({
          'admin.jobs_retrieval_error': true,
          'admin.error.message': error instanceof Error ? error.message : 'Unknown error'
        });

        console.error('Failed to retrieve background jobs:', error);

        return NextResponse.json(
          {
            success: false,
            error: {
              code: 'JOBS_RETRIEVAL_ERROR',
              message: 'Failed to retrieve background jobs'
            }
          },
          { status: 500 }
        );
      }
    })
  )
);

// DELETE /api/admin/jobs/:jobId - Cancel a background job (admin only)
export const DELETE = withOTel(
  withRateLimit(rateLimitConfigs.user,
    requireAuth(async (req: NextRequest, { user }, { params }: { params: { jobId: string } }) => {
      const span = trace.getActiveSpan();
      
      try {
        const { jobId } = params;

        // Check if user is admin
        const isAdmin = user.email?.endsWith('@resonai.app') || 
                        process.env.ADMIN_USER_IDS?.split(',').includes(user.id);

        if (!isAdmin) {
          return NextResponse.json(
            {
              success: false,
              error: {
                code: 'INSUFFICIENT_PERMISSIONS',
                message: 'Admin access required'
              }
            },
            { status: 403 }
          );
        }

        // Find the job
        const job = await db.backgroundJob.findUnique({
          where: { id: jobId }
        });

        if (!job) {
          span?.setAttributes({
            'admin.job_not_found': true,
            'admin.job_id': jobId,
          });

          return NextResponse.json(
            {
              success: false,
              error: {
                code: 'JOB_NOT_FOUND',
                message: 'Background job not found'
              }
            },
            { status: 404 }
          );
        }

        // Only allow cancellation of pending jobs
        if (job.status !== JobStatus.PENDING) {
          return NextResponse.json(
            {
              success: false,
              error: {
                code: 'JOB_CANNOT_BE_CANCELLED',
                message: 'Only pending jobs can be cancelled'
              }
            },
            { status: 400 }
          );
        }

        // Delete the job
        await db.backgroundJob.delete({
          where: { id: jobId }
        });

        span?.setAttributes({
          'admin.job_cancelled': true,
          'admin.job_id': jobId,
          'admin.job_type': job.type,
          'admin.user_id': user.id,
        });

        return NextResponse.json({
          success: true,
          data: { jobId },
          message: 'Background job cancelled successfully'
        });

      } catch (error) {
        span?.setAttributes({
          'admin.job_cancel_error': true,
          'admin.error.message': error instanceof Error ? error.message : 'Unknown error'
        });

        console.error('Failed to cancel background job:', error);

        return NextResponse.json(
          {
            success: false,
            error: {
              code: 'JOB_CANCEL_ERROR',
              message: 'Failed to cancel background job'
            }
          },
          { status: 500 }
        );
      }
    })
  )
);

// GET /api/admin/jobs/stats - Get background job statistics (admin only)
export const stats = withOTel(
  withRateLimit(rateLimitConfigs.user,
    requireAuth(async (req: NextRequest, { user }) => {
      const span = trace.getActiveSpan();
      
      try {
        // Check if user is admin
        const isAdmin = user.email?.endsWith('@resonai.app') || 
                        process.env.ADMIN_USER_IDS?.split(',').includes(user.id);

        if (!isAdmin) {
          return NextResponse.json(
            {
              success: false,
              error: {
                code: 'INSUFFICIENT_PERMISSIONS',
                message: 'Admin access required'
              }
            },
            { status: 403 }
          );
        }

        // Get job statistics by type
        const jobsByType = await db.backgroundJob.groupBy({
          by: ['type'],
          _count: { type: true },
          _avg: { retryCount: true },
        });

        // Get recent job performance
        const recentJobs = await db.backgroundJob.findMany({
          where: {
            completedAt: {
              gte: new Date(Date.now() - 24 * 60 * 60 * 1000) // Last 24 hours
            }
          },
          orderBy: { completedAt: 'desc' },
          take: 100,
          select: {
            type: true,
            status: true,
            startedAt: true,
            completedAt: true,
            retryCount: true,
          }
        });

        // Calculate performance metrics
        const performanceMetrics = recentJobs.reduce((acc, job) => {
          if (!acc[job.type]) {
            acc[job.type] = {
              total: 0,
              completed: 0,
              failed: 0,
              avgDuration: 0,
              avgRetries: 0,
            };
          }

          acc[job.type].total++;
          if (job.status === JobStatus.COMPLETED) {
            acc[job.type].completed++;
          } else if (job.status === JobStatus.FAILED) {
            acc[job.type].failed++;
          }

          if (job.startedAt && job.completedAt) {
            const duration = job.completedAt.getTime() - job.startedAt.getTime();
            acc[job.type].avgDuration += duration;
          }

          acc[job.type].avgRetries += job.retryCount || 0;
        }, {} as any);

        // Calculate averages
        Object.keys(performanceMetrics).forEach(type => {
          const metrics = performanceMetrics[type];
          if (metrics.total > 0) {
            metrics.avgDuration = Math.round(metrics.avgDuration / metrics.total);
            metrics.avgRetries = Math.round((metrics.avgRetries / metrics.total) * 100) / 100;
            metrics.successRate = Math.round((metrics.completed / metrics.total) * 100);
          }
        });

        span?.setAttributes({
          'admin.job_stats_retrieved': true,
          'admin.job_types_count': jobsByType.length,
          'admin.recent_jobs_count': recentJobs.length,
        });

        return NextResponse.json({
          success: true,
          data: {
            jobsByType: jobsByType.map(item => ({
              type: item.type,
              count: item._count.type,
              avgRetries: Math.round((item._avg.retryCount || 0) * 100) / 100,
            })),
            performance: performanceMetrics,
            summary: {
              totalJobTypes: jobsByType.length,
              recentJobsProcessed: recentJobs.length,
              systemHealth: recentJobs.filter(j => j.status === JobStatus.FAILED).length > 10 ? 'degraded' : 'healthy',
            }
          }
        });

      } catch (error) {
        span?.setAttributes({
          'admin.job_stats_error': true,
          'admin.error.message': error instanceof Error ? error.message : 'Unknown error'
        });

        console.error('Failed to get background job statistics:', error);

        return NextResponse.json(
          {
            success: false,
            error: {
              code: 'JOB_STATS_ERROR',
              message: 'Failed to get background job statistics'
            }
          },
          { status: 500 }
        );
      }
    })
  )
);

// Export config for Edge Runtime
export const config = {
  runtime: 'edge',
};
