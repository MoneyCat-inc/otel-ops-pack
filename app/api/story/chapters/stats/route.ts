import { NextRequest, NextResponse } from 'next/server';
import { trace } from '@opentelemetry/api';
import { requireAuth } from '@/lib/middleware/auth';
import { withOTel } from '@/lib/middleware/otel';
import { withRateLimit, rateLimitConfigs } from '@/lib/middleware/rate-limit';
import { db } from '@/lib/db';

// GET /api/story/chapters/stats - Get story statistics for the authenticated user
export const GET = withOTel(
  withRateLimit(rateLimitConfigs.user,
    requireAuth(async (_req: NextRequest, { user }) => {
      const span = trace.getActiveSpan();

      try {
        const [totalChapters, completedChapters, recentProgress] = await Promise.all([
          db.storyChapter.count({ where: { isActive: true } }),
          db.storyProgress.count({ where: { userId: user.id } }),
          db.storyProgress.findMany({
            where: { userId: user.id },
            orderBy: { completedAt: 'desc' },
            take: 5,
            include: {
              chapter: {
                select: {
                  title: true,
                  chapterId: true,
                },
              },
            },
          }),
        ]);

        const completionPercentage = totalChapters > 0
          ? Math.round((completedChapters / totalChapters) * 100)
          : 0;

        span?.setAttributes({
          'story.stats_retrieved': true,
          'story.user_id': user.id,
          'story.total_chapters': totalChapters,
          'story.completed_chapters': completedChapters,
          'story.completion_percentage': completionPercentage,
        });

        return NextResponse.json({
          success: true,
          data: {
            totalChapters,
            completedChapters,
            completionPercentage,
            recentProgress: recentProgress.map((p: any) => ({
              chapterId: p.chapter.chapterId,
              chapterTitle: p.chapter.title,
              completedAt: p.completedAt,
            })),
            lastActivity: recentProgress[0]?.completedAt || null,
          },
        });
      } catch (error) {
        span?.setAttributes({
          'story.stats_error': true,
          'story.error.message': error instanceof Error ? error.message : 'Unknown error',
        });

        console.error('Failed to retrieve story stats:', error);

        return NextResponse.json(
          {
            success: false,
            error: {
              code: 'STATS_RETRIEVAL_ERROR',
              message: 'Failed to retrieve story statistics',
            },
          },
          { status: 500 },
        );
      }
    }),
  ),
);

export const runtime = 'nodejs';
