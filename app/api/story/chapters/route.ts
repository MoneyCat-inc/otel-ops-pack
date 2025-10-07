// Resonai Backend - Narrative Content API Routes
// Handles story chapters with immutable versioning and progress tracking

import { NextRequest, NextResponse } from 'next/server';
import { trace } from '@opentelemetry/api';
import { StoryProgressSchema } from '@/lib/validation/schemas';
import { optionalAuth } from '@/lib/middleware/auth';
import { withOTel } from '@/lib/middleware/otel';
import { withRateLimit, rateLimitConfigs } from '@/lib/middleware/rate-limit';
import { db } from '@/lib/db';

// GET /api/story/chapters - Get story chapters with versioning
export const GET = withOTel(
  withRateLimit(rateLimitConfigs.user, async (req: NextRequest) => {
    const span = trace.getActiveSpan();
    
    try {
      const { searchParams } = new URL(req.url);
      const version = searchParams.get('v');
      const chapterId = searchParams.get('chapterId');
      const includeInactive = searchParams.get('includeInactive') === 'true';

      // Validate version format (YYYYMMDD)
      if (version && !/^\d{8}$/.test(version)) {
        return NextResponse.json(
          {
            success: false,
            error: {
              code: 'INVALID_VERSION_FORMAT',
              message: 'Version must be in YYYYMMDD format'
            }
          },
          { status: 400 }
        );
      }

      // Build query conditions
      const whereConditions: any = {};
      
      if (version) {
        whereConditions.version = version;
      }
      
      if (chapterId) {
        whereConditions.chapterId = chapterId;
      }
      
      if (!includeInactive) {
        whereConditions.isActive = true;
      }

      // Get chapters
      const chapters = await db.storyChapter.findMany({
        where: whereConditions,
        orderBy: [
          { publishedAt: 'asc' },
          { chapterId: 'asc' }
        ],
        select: {
          id: true,
          chapterId: true,
          version: true,
          title: true,
          body: true,
          choices: true,
          publishedAt: true,
          isActive: true,
        }
      });

      // Get available versions
      const versions = await db.storyChapter.findMany({
        select: { version: true },
        distinct: ['version'],
        orderBy: { version: 'desc' }
      });

      span?.setAttributes({
        'story.chapters_retrieved': true,
        'story.count': chapters.length,
        'story.version': version || 'latest',
        'story.chapter_filter': chapterId || 'all',
      });

      return NextResponse.json({
        success: true,
        data: {
          chapters,
          metadata: {
            version: version || 'latest',
            totalChapters: chapters.length,
            availableVersions: versions.map((v: any) => v.version),
            requestedAt: new Date().toISOString(),
          }
        }
      });

    } catch (error) {
      span?.setAttributes({
        'story.chapters_error': true,
        'story.error.message': error instanceof Error ? error.message : 'Unknown error'
      });

      console.error('Failed to retrieve story chapters:', error);

      return NextResponse.json(
        {
          success: false,
          error: {
            code: 'CHAPTERS_RETRIEVAL_ERROR',
            message: 'Failed to retrieve story chapters'
          }
        },
        { status: 500 }
      );
    }
  })
);

// POST /api/story/progress - Save story progress (optional, requires auth)
export const POST = withOTel(
  withRateLimit(rateLimitConfigs.user,
    optionalAuth(async (req: NextRequest, { user }) => {
      const span = trace.getActiveSpan();
      
      try {
        const body = await req.json();
        const parseResult = StoryProgressSchema.safeParse(body);
        
        if (!parseResult.success) {
          span?.setAttributes({
            'story.progress_validation_failed': true,
            'story.error.details': parseResult.error.message
          });
          
          return NextResponse.json(
            {
              success: false,
              error: {
                code: 'VALIDATION_ERROR',
                message: 'Invalid story progress format',
                details: parseResult.error.issues
              }
            },
            { status: 400 }
          );
        }

        const { chapterId, choices } = parseResult.data;

        // Check if chapter exists
        const chapter = await db.storyChapter.findFirst({
          where: {
            chapterId,
            isActive: true,
          }
        });

        if (!chapter) {
          span?.setAttributes({
            'story.chapter_not_found': true,
            'story.chapter_id': chapterId,
          });

          return NextResponse.json(
            {
              success: false,
              error: {
                code: 'CHAPTER_NOT_FOUND',
                message: 'Story chapter not found'
              }
            },
            { status: 404 }
          );
        }

        // If user is authenticated, save progress
        if (user) {
          const progress = await db.storyProgress.upsert({
            where: {
              userId_chapterId: {
                userId: user.id,
                chapterId: chapter.id,
              }
            },
            update: {
              choices,
              completedAt: new Date(),
            },
            create: {
              userId: user.id,
              chapterId: chapter.id,
              choices,
              completedAt: new Date(),
            }
          });

          span?.setAttributes({
            'story.progress_saved': true,
            'story.user_id': user.id,
            'story.chapter_id': chapterId,
            'story.has_choices': !!choices,
          });

          return NextResponse.json({
            success: true,
            data: {
              progressId: progress.id,
              chapterId,
              completedAt: progress.completedAt,
              choices: progress.choices,
            },
            message: 'Story progress saved successfully'
          });
        } else {
          // Anonymous user - just validate the chapter exists
          span?.setAttributes({
            'story.chapter_validated': true,
            'story.chapter_id': chapterId,
            'story.anonymous_user': true,
          });

          return NextResponse.json({
            success: true,
            data: {
              chapterId,
              title: chapter.title,
              validated: true,
            },
            message: 'Chapter validated (progress not saved for anonymous users)'
          });
        }

      } catch (error) {
        span?.setAttributes({
          'story.progress_error': true,
          'story.error.message': error instanceof Error ? error.message : 'Unknown error'
        });

        console.error('Failed to save story progress:', error);

        return NextResponse.json(
          {
            success: false,
            error: {
              code: 'PROGRESS_SAVE_ERROR',
              message: 'Failed to save story progress'
            }
          },
          { status: 500 }
        );
      }
    })
  )
);

// GET /api/story/progress - Get user's story progress

// Note: Progress and stats functionality moved to GET handler above with query parameters

// Export config for Edge Runtime
export const runtime = 'nodejs';

