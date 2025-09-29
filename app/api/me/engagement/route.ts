// Resonai Backend - Engagement Profile API Route
// Handles GET (retrieve) and PUT (sync) operations for user engagement data

import { NextRequest, NextResponse } from 'next/server';
import { trace } from '@opentelemetry/api';
import { EngagementProfileSchema, BadgeUnlockSchema } from '@/lib/validation/schemas';
import { db } from '@/lib/db';
import { requireAuth } from '@/lib/middleware/auth';
import { withOTel } from '@/lib/middleware/otel';

// GET /api/me/engagement - Retrieve user's engagement profile
export const GET = withOTel(
  requireAuth(async (req: NextRequest, { user }) => {
    const span = trace.getActiveSpan();
    
    try {
      // Fetch engagement profile with badges
      const profile = await db.engagementProfile.findUnique({
        where: { userId: user.id },
        include: {
          badges: {
            select: {
              badgeType: true,
              unlockedAt: true,
              metadata: true,
            },
            orderBy: { unlockedAt: 'desc' }
          }
        }
      });

      if (!profile) {
        // Create default profile if none exists
        const newProfile = await db.engagementProfile.create({
          data: {
            userId: user.id,
            streakDays: 0,
            reducedMotion: false,
            theme: 'auto',
            preferredLanguage: 'en',
          }
        });

        span?.setAttributes({
          'api.route': 'engagement_get',
          'profile.created': true,
          'profile.streak_days': newProfile.streakDays,
        });

        return NextResponse.json({
          success: true,
          data: {
            ...newProfile,
            badges: []
          }
        });
      }

      span?.setAttributes({
        'api.route': 'engagement_get',
        'profile.streak_days': profile.streakDays,
        'profile.badges_count': profile.badges.length,
        'profile.last_practice': profile.lastPracticeAt?.toISOString(),
      });

      return NextResponse.json({
        success: true,
        data: profile
      });

    } catch (error) {
      span?.setAttributes({
        'api.error': 'retrieval_failed',
        'api.error.message': error instanceof Error ? error.message : 'Unknown error'
      });

      console.error('Failed to retrieve engagement profile:', error);

      return NextResponse.json(
        {
          success: false,
          error: {
            code: 'RETRIEVAL_ERROR',
            message: 'Failed to retrieve engagement profile'
          }
        },
        { status: 500 }
      );
    }
  })
);

// PUT /api/me/engagement - Sync engagement data from client
export const PUT = withOTel(
  requireAuth(async (req: NextRequest, { user }) => {
    const span = trace.getActiveSpan();
    
    try {
      const body = await req.json();
      const parseResult = EngagementProfileSchema.safeParse(body);
      
      if (!parseResult.success) {
        span?.setAttributes({
          'api.error': 'validation_failed',
          'api.error.details': parseResult.error.message
        });
        
        return NextResponse.json(
          {
            success: false,
            error: {
              code: 'VALIDATION_ERROR',
              message: 'Invalid engagement profile format',
              details: parseResult.error.errors
            }
          },
          { status: 400 }
        );
      }

      const engagementData = parseResult.data;

      // Upsert engagement profile (client remains source of truth)
      const updatedProfile = await db.engagementProfile.upsert({
        where: { userId: user.id },
        update: {
          streakDays: engagementData.streakDays,
          lastPracticeAt: engagementData.lastPracticeAt 
            ? new Date(engagementData.lastPracticeAt) 
            : undefined,
          reducedMotion: engagementData.reducedMotion,
          theme: engagementData.theme,
          preferredLanguage: engagementData.preferredLanguage,
          lastSyncAt: new Date(),
        },
        create: {
          userId: user.id,
          streakDays: engagementData.streakDays,
          lastPracticeAt: engagementData.lastPracticeAt 
            ? new Date(engagementData.lastPracticeAt) 
            : undefined,
          reducedMotion: engagementData.reducedMotion ?? false,
          theme: engagementData.theme ?? 'auto',
          preferredLanguage: engagementData.preferredLanguage ?? 'en',
          lastSyncAt: new Date(),
        }
      });

      // Check for new badges in the request
      if (body.badges && Array.isArray(body.badges)) {
        const badgePromises = body.badges.map(async (badge: any) => {
          const badgeResult = BadgeUnlockSchema.safeParse(badge);
          if (!badgeResult.success) return null;

          const { badgeType, metadata } = badgeResult.data;

          // Only create if badge doesn't already exist
          return db.badge.upsert({
            where: {
              userId_badgeType: {
                userId: user.id,
                badgeType,
              }
            },
            update: {
              metadata,
            },
            create: {
              userId: user.id,
              badgeType,
              metadata,
            }
          });
        });

        await Promise.all(badgePromises.filter(Boolean));
      }

      span?.setAttributes({
        'api.route': 'engagement_sync',
        'profile.streak_days': updatedProfile.streakDays,
        'profile.sync_timestamp': updatedProfile.lastSyncAt.toISOString(),
      });

      return NextResponse.json({
        success: true,
        data: updatedProfile,
        message: 'Engagement profile synchronized successfully'
      });

    } catch (error) {
      span?.setAttributes({
        'api.error': 'sync_failed',
        'api.error.message': error instanceof Error ? error.message : 'Unknown error'
      });

      console.error('Failed to sync engagement profile:', error);

      return NextResponse.json(
        {
          success: false,
          error: {
            code: 'SYNC_ERROR',
            message: 'Failed to synchronize engagement profile'
          }
        },
        { status: 500 }
      );
    }
  })
);

// Export config for Edge Runtime
export const runtime = 'edge';

