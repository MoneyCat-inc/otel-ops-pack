import { NextRequest, NextResponse } from 'next/server';
import { trace } from '@opentelemetry/api';
import { requireAuth } from '@/lib/middleware/auth';
import { withOTel } from '@/lib/middleware/otel';
import { withRateLimit, rateLimitConfigs } from '@/lib/middleware/rate-limit';
import { db } from '@/lib/db';

// GET /api/feedback/stats - Get feedback statistics (admin only)
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

        const [
          totalFeedback,
          openFeedback,
          resolvedFeedback,
          feedbackByType,
          recentFeedback,
        ] = await Promise.all([
          db.feedbackReport.count(),
          db.feedbackReport.count({ where: { status: 'OPEN' } }),
          db.feedbackReport.count({ where: { status: 'RESOLVED' } }),
          db.feedbackReport.groupBy({
            by: ['type'],
            _count: { type: true },
          }),
          db.feedbackReport.findMany({
            where: {
              createdAt: {
                gte: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000),
              },
            },
            orderBy: { createdAt: 'desc' },
            take: 10,
            select: {
              id: true,
              type: true,
              status: true,
              createdAt: true,
            },
          }),
        ]);

        span?.setAttributes({
          'feedback.stats_retrieved': true,
          'feedback.total_count': totalFeedback,
          'feedback.open_count': openFeedback,
          'feedback.resolved_count': resolvedFeedback,
        });

        return NextResponse.json({
          success: true,
          data: {
            summary: {
              total: totalFeedback,
              open: openFeedback,
              resolved: resolvedFeedback,
              resolutionRate: totalFeedback > 0
                ? Math.round((resolvedFeedback / totalFeedback) * 100)
                : 0,
            },
            byType: feedbackByType.map((item: any) => ({
              type: item.type,
              count: item._count.type,
            })),
            recent: recentFeedback,
          },
        });
      } catch (error) {
        span?.setAttributes({
          'feedback.stats_error': true,
          'feedback.error.message': error instanceof Error ? error.message : 'Unknown error',
        });

        console.error('Failed to get feedback statistics:', error);

        return NextResponse.json(
          {
            success: false,
            error: {
              code: 'FEEDBACK_STATS_ERROR',
              message: 'Failed to get feedback statistics',
            },
          },
          { status: 500 },
        );
      }
    }),
  ),
);

export const runtime = 'nodejs';
