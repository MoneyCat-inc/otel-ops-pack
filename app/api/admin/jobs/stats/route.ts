import { NextRequest, NextResponse } from 'next/server';
import { trace } from '@opentelemetry/api';
import { JobStatus } from '@/lib/background/jobs';
import { requireAuth } from '@/lib/middleware/auth';
import { withOTel } from '@/lib/middleware/otel';
import { withRateLimit, rateLimitConfigs } from '@/lib/middleware/rate-limit';
import { db } from '@/lib/db';

type JobGroup = Awaited<ReturnType<typeof db.backgroundJob.groupBy>>[number];
type RecentJob = Awaited<ReturnType<typeof db.backgroundJob.findMany>>[number];

// GET /api/admin/jobs/stats - Get background job statistics (admin only)
export const GET = withOTel(
  withRateLimit(rateLimitConfigs.user,
    requireAuth(async (_req: NextRequest, { user }) => {
      const span = trace.getActiveSpan();

      try {
        const isAdmin = user.email?.endsWith('@resonai.app') ||
          process.env['ADMIN_USER_IDS']?.split(',').includes(user.id);

        if (!isAdmin) {
          return NextResponse.json(
            {
              success: false,
              error: {
                code: 'INSUFFICIENT_PERMISSIONS',
                message: 'Admin access required',
              },
            },
            { status: 403 },
          );
        }

        const jobsByType = await db.backgroundJob.groupBy({
          by: ['type'],
          _count: { type: true },
          _avg: { retryCount: true },
        });

        const recentJobs = await db.backgroundJob.findMany({
          where: {
            completedAt: {
              gte: new Date(Date.now() - 24 * 60 * 60 * 1000),
            },
          },
          orderBy: { completedAt: 'desc' },
          take: 100,
          select: {
            type: true,
            status: true,
            startedAt: true,
            completedAt: true,
            retryCount: true,
          },
        });

        const performanceMetrics: Record<string, {
          total: number;
          completed: number;
          failed: number;
          avgDuration: number;
          avgRetries: number;
          successRate?: number;
        }> = {};

        for (const job of recentJobs) {
          performanceMetrics[job.type] = performanceMetrics[job.type] || {
            total: 0,
            completed: 0,
            failed: 0,
            avgDuration: 0,
            avgRetries: 0,
          };

          const metrics = performanceMetrics[job.type]!;
          metrics.total++;
          if (job.status === JobStatus.COMPLETED) {
            metrics.completed++;
          } else if (job.status === JobStatus.FAILED) {
            metrics.failed++;
          }

          if (job.startedAt && job.completedAt) {
            metrics.avgDuration += job.completedAt.getTime() - job.startedAt.getTime();
          }

          metrics.avgRetries += job.retryCount || 0;
        }

        for (const metrics of Object.values(performanceMetrics)) {
          if (metrics.total > 0) {
            metrics.avgDuration = Math.round(metrics.avgDuration / metrics.total);
            metrics.avgRetries = Math.round((metrics.avgRetries / metrics.total) * 100) / 100;
            metrics.successRate = Math.round((metrics.completed / metrics.total) * 100);
          }
        }

        span?.setAttributes({
          'admin.job_stats_retrieved': true,
          'admin.job_types_count': jobsByType.length,
          'admin.recent_jobs_count': recentJobs.length,
        });

        return NextResponse.json({
          success: true,
          data: {
            jobsByType: jobsByType.map((item: JobGroup) => ({
              type: item.type,
              count: item._count.type,
              avgRetries: Math.round((item._avg.retryCount || 0) * 100) / 100,
            })),
            performance: performanceMetrics,
            summary: {
              totalJobTypes: jobsByType.length,
              recentJobsProcessed: recentJobs.length,
              systemHealth: recentJobs.filter((j: RecentJob) => j.status === JobStatus.FAILED).length > 10 ? 'degraded' : 'healthy',
            },
          },
        });
      } catch (error) {
        span?.setAttributes({
          'admin.job_stats_error': true,
          'admin.error.message': error instanceof Error ? error.message : 'Unknown error',
        });

        console.error('Failed to get background job statistics:', error);

        return NextResponse.json(
          {
            success: false,
            error: {
              code: 'JOB_STATS_ERROR',
              message: 'Failed to get background job statistics',
            },
          },
          { status: 500 },
        );
      }
    }),
  ),
);

export const runtime = 'nodejs';



