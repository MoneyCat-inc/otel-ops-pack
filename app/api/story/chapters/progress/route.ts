import { NextRequest, NextResponse } from 'next/server';
import { trace } from '@opentelemetry/api';
import { requireAuth } from '@/lib/middleware/auth';
import { withOTel } from '@/lib/middleware/otel';
import { withRateLimit, rateLimitConfigs } from '@/lib/middleware/rate-limit';
import { db } from '@/lib/db';

// GET /api/story/chapters/progress - Get user's story progress
export const GET = withOTel(
  withRateLimit(rateLimitConfigs.user,
    requireAuth(async (req: NextRequest, { user }) => {
      const span = trace.getActiveSpan();

      try {
        const { searchParams } = new URL(req.url);
        const limit = Math.min(parseInt(searchParams.get('limit') || '50', 10), 100);
        const offset = Math.max(parseInt(searchParams.get('offset') || '0', 10), 0);

        const progress = await db.storyProgress.findMany({
          where: { userId: user.id },
          include: {
            chapter: {
              select: {
                title: true,
                chapterId: true,
                version: true,
              },
            },
          },
          orderBy: { completedAt: 'desc' },
          take: limit,
          skip: offset,
        });

        const totalCount = await db.storyProgress.count({
          where: { userId: user.id },
        });

        span?.setAttributes({
          'story.progress_retrieved': true,
          'story.user_id': user.id,
          'story.progress_count': progress.length,
          'story.total_count': totalCount,
        });

        return NextResponse.json({
          success: true,
          data: {
            progress: progress.map((p: any) => ({
              id: p.id,
              chapterId: p.chapter.chapterId,
              chapterTitle: p.chapter.title,
              version: p.chapter.version,
              completedAt: p.completedAt,
              choices: p.choices,
            })),
            pagination: {
              limit,
              offset,
              total: totalCount,
              hasMore: offset + progress.length < totalCount,
            },
          },
        });
      } catch (error) {
        span?.setAttributes({
          'story.progress_retrieval_error': true,
          'story.error.message': error instanceof Error ? error.message : 'Unknown error',
        });

        console.error('Failed to retrieve story progress:', error);

        return NextResponse.json(
          {
            success: false,
            error: {
              code: 'PROGRESS_RETRIEVAL_ERROR',
              message: 'Failed to retrieve story progress',
            },
          },
          { status: 500 },
        );
      }
    }),
  ),
);

export const runtime = 'nodejs';
