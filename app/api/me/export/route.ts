// Resonai Backend - Data Export/Deletion API Routes
// GDPR/CCPA compliant data export and deletion endpoints

import { NextRequest, NextResponse } from 'next/server';
import { trace } from '@opentelemetry/api';
import { DataExportRequestSchema, DataDeletionRequestSchema } from '@/lib/validation/schemas';
import { requireAuth } from '@/lib/middleware/auth';
import { withOTel } from '@/lib/middleware/otel';
import { withRateLimit, rateLimitConfigs } from '@/lib/middleware/rate-limit';
import { db } from '@/lib/db';
import { createHash, randomBytes } from 'crypto';
import { writeFile, mkdir } from 'fs/promises';
import { join } from 'path';

// POST /api/me/export - Request data export
export const POST = withOTel(
  withRateLimit(rateLimitConfigs.user,
    requireAuth(async (req: NextRequest, { user }) => {
      const span = trace.getActiveSpan();
      
      try {
        const body = await req.json();
        const parseResult = DataExportRequestSchema.safeParse(body);
        
        if (!parseResult.success) {
          span?.setAttributes({
            'data.export_validation_failed': true,
            'data.error.details': parseResult.error.message
          });
          
          return NextResponse.json(
            {
              success: false,
              error: {
                code: 'VALIDATION_ERROR',
                message: 'Invalid export request',
                details: parseResult.error.errors
              }
            },
            { status: 400 }
          );
        }

        const { includeEngagement, includeStoryProgress, includeFeedback, format } = parseResult.data;

        // Check for existing pending export
        const existingExport = await db.dataExport.findFirst({
          where: {
            userId: user.id,
            status: { in: ['PENDING', 'PROCESSING'] }
          }
        });

        if (existingExport) {
          span?.setAttributes({
            'data.export_already_pending': true,
            'data.user_id': user.id,
          });

          return NextResponse.json(
            {
              success: false,
              error: {
                code: 'EXPORT_ALREADY_PENDING',
                message: 'Data export already in progress',
                details: {
                  exportId: existingExport.id,
                  status: existingExport.status,
                  createdAt: existingExport.createdAt,
                }
              }
            },
            { status: 409 }
          );
        }

        // Create export request
        const exportId = randomBytes(16).toString('hex');
        const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000); // 7 days

        const dataExport = await db.dataExport.create({
          data: {
            id: exportId,
            userId: user.id,
            status: 'PENDING',
            expiresAt,
          }
        });

        // Start background export process
        processDataExport(dataExport.id, user.id, {
          includeEngagement,
          includeStoryProgress,
          includeFeedback,
          format,
        }).catch(error => {
          console.error('Background export failed:', error);
        });

        span?.setAttributes({
          'data.export_requested': true,
          'data.user_id': user.id,
          'data.export_id': exportId,
          'data.format': format,
        });

        return NextResponse.json({
          success: true,
          data: {
            exportId,
            status: 'PENDING',
            expiresAt: expiresAt.toISOString(),
            estimatedCompletionTime: new Date(Date.now() + 5 * 60 * 1000).toISOString(), // 5 minutes
          },
          message: 'Data export request submitted successfully'
        });

      } catch (error) {
        span?.setAttributes({
          'data.export_error': true,
          'data.error.message': error instanceof Error ? error.message : 'Unknown error'
        });

        console.error('Failed to request data export:', error);

        return NextResponse.json(
          {
            success: false,
            error: {
              code: 'EXPORT_REQUEST_ERROR',
              message: 'Failed to request data export'
            }
          },
          { status: 500 }
        );
      }
    })
  )
);

// GET /api/me/export/:exportId - Get export status and download
export const GET = withOTel(
  withRateLimit(rateLimitConfigs.user,
    requireAuth(async (req: NextRequest, { user }, { params }: { params: { exportId: string } }) => {
      const span = trace.getActiveSpan();
      
      try {
        const { exportId } = params;

        if (!exportId) {
          return NextResponse.json(
            {
              success: false,
              error: {
                code: 'MISSING_EXPORT_ID',
                message: 'Export ID is required'
              }
            },
            { status: 400 }
          );
        }

        // Find export
        const dataExport = await db.dataExport.findFirst({
          where: {
            id: exportId,
            userId: user.id, // Ensure user can only access their own exports
          }
        });

        if (!dataExport) {
          span?.setAttributes({
            'data.export_not_found': true,
            'data.export_id': exportId,
            'data.user_id': user.id,
          });

          return NextResponse.json(
            {
              success: false,
              error: {
                code: 'EXPORT_NOT_FOUND',
                message: 'Export not found or not owned by user'
              }
            },
            { status: 404 }
          );
        }

        // Check if export is expired
        if (dataExport.expiresAt < new Date()) {
          span?.setAttributes({
            'data.export_expired': true,
            'data.export_id': exportId,
          });

          return NextResponse.json(
            {
              success: false,
              error: {
                code: 'EXPORT_EXPIRED',
                message: 'Export has expired'
              }
            },
            { status: 410 }
          );
        }

        span?.setAttributes({
          'data.export_status_retrieved': true,
          'data.export_id': exportId,
          'data.status': dataExport.status,
        });

        return NextResponse.json({
          success: true,
          data: {
            exportId: dataExport.id,
            status: dataExport.status,
            createdAt: dataExport.createdAt,
            completedAt: dataExport.completedAt,
            expiresAt: dataExport.expiresAt,
            downloadUrl: dataExport.status === 'COMPLETED' && dataExport.filePath 
              ? `/api/me/export/${exportId}/download`
              : null,
          }
        });

      } catch (error) {
        span?.setAttributes({
          'data.export_status_error': true,
          'data.error.message': error instanceof Error ? error.message : 'Unknown error'
        });

        console.error('Failed to get export status:', error);

        return NextResponse.json(
          {
            success: false,
            error: {
              code: 'EXPORT_STATUS_ERROR',
              message: 'Failed to get export status'
            }
          },
          { status: 500 }
        );
      }
    })
  )
);

// DELETE /api/me - Complete account deletion
export const DELETE = withOTel(
  withRateLimit(rateLimitConfigs.user,
    requireAuth(async (req: NextRequest, { user }) => {
      const span = trace.getActiveSpan();
      
      try {
        const body = await req.json().catch(() => ({}));
        const parseResult = DataDeletionRequestSchema.safeParse(body);
        
        if (!parseResult.success) {
          span?.setAttributes({
            'data.deletion_validation_failed': true,
            'data.error.details': parseResult.error.message
          });
          
          return NextResponse.json(
            {
              success: false,
              error: {
                code: 'VALIDATION_ERROR',
                message: 'Invalid deletion request',
                details: parseResult.error.errors
              }
            },
            { status: 400 }
          );
        }

        const { reason, confirmDeletion } = parseResult.data;

        if (!confirmDeletion) {
          return NextResponse.json(
            {
              success: false,
              error: {
                code: 'DELETION_NOT_CONFIRMED',
                message: 'Account deletion must be explicitly confirmed'
              }
            },
            { status: 400 }
          );
        }

        // Log deletion request
        await db.deletionLog.create({
          data: {
            userId: user.id,
            reason: reason || 'User requested deletion',
            dataTypes: ['user_profile', 'engagement_data', 'story_progress', 'events', 'coach_grants'],
          }
        });

        // Perform cascade deletion
        await db.$transaction(async (tx) => {
          // Delete in order to respect foreign key constraints
          await tx.badge.deleteMany({ where: { userId: user.id } });
          await tx.engagementProfile.deleteMany({ where: { userId: user.id } });
          await tx.storyProgress.deleteMany({ where: { userId: user.id } });
          await tx.event.deleteMany({ where: { userId: user.id } });
          await tx.coachGrant.deleteMany({ where: { userId: user.id } });
          await tx.consentAuditLog.deleteMany({ where: { userId: user.id } });
          await tx.feedbackReport.updateMany({ 
            where: { userId: user.id },
            data: { userId: null } // Anonymize instead of delete
          });
          await tx.session.deleteMany({ where: { userId: user.id } });
          await tx.dataExport.deleteMany({ where: { userId: user.id } });
          await tx.user.delete({ where: { id: user.id } });
        });

        // Clear session cookie
        const response = NextResponse.json({
          success: true,
          data: { deleted: true },
          message: 'Account and all associated data deleted successfully'
        });

        response.cookies.set('session_token', '', {
          httpOnly: true,
          secure: process.env.NODE_ENV === 'production',
          sameSite: 'strict',
          maxAge: 0,
          path: '/',
        });

        span?.setAttributes({
          'data.account_deleted': true,
          'data.user_id': user.id,
          'data.deletion_reason': reason || 'not_provided',
        });

        return response;

      } catch (error) {
        span?.setAttributes({
          'data.deletion_error': true,
          'data.error.message': error instanceof Error ? error.message : 'Unknown error'
        });

        console.error('Failed to delete account:', error);

        return NextResponse.json(
          {
            success: false,
            error: {
              code: 'ACCOUNT_DELETION_ERROR',
              message: 'Failed to delete account'
            }
          },
          { status: 500 }
        );
      }
    })
  )
);

// Background function to process data export
async function processDataExport(
  exportId: string,
  userId: string,
  options: {
    includeEngagement: boolean;
    includeStoryProgress: boolean;
    includeFeedback: boolean;
    format: 'json' | 'csv';
  }
): Promise<void> {
  const span = trace.getActiveSpan();
  
  try {
    // Update status to processing
    await db.dataExport.update({
      where: { id: exportId },
      data: { status: 'PROCESSING' }
    });

    // Collect user data
    const userData: any = {
      exportMetadata: {
        exportId,
        userId,
        exportedAt: new Date().toISOString(),
        format: options.format,
        version: '1.0',
      },
      user: {},
      engagement: null,
      storyProgress: null,
      feedback: null,
    };

    // Get user profile
    const user = await db.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        email: true,
        createdAt: true,
        consentShareMetrics: true,
        consentShareClips: true,
        consentCoachPortal: true,
        userIdHash: true,
      }
    });

    if (user) {
      userData.user = {
        id: user.id,
        email: user.email,
        createdAt: user.createdAt,
        consent: {
          shareMetrics: user.consentShareMetrics,
          shareClips: user.consentShareClips,
          coachPortal: user.consentCoachPortal,
        },
        userIdHash: user.userIdHash,
      };
    }

    // Get engagement data if requested
    if (options.includeEngagement) {
      const engagement = await db.engagementProfile.findUnique({
        where: { userId },
        include: {
          badges: {
            select: {
              badgeType: true,
              unlockedAt: true,
              metadata: true,
            }
          }
        }
      });

      if (engagement) {
        userData.engagement = {
          streakDays: engagement.streakDays,
          lastPracticeAt: engagement.lastPracticeAt,
          lastSyncAt: engagement.lastSyncAt,
          preferences: {
            reducedMotion: engagement.reducedMotion,
            theme: engagement.theme,
            preferredLanguage: engagement.preferredLanguage,
          },
          badges: engagement.badges,
        };
      }
    }

    // Get story progress if requested
    if (options.includeStoryProgress) {
      const storyProgress = await db.storyProgress.findMany({
        where: { userId },
        include: {
          chapter: {
            select: {
              title: true,
              chapterId: true,
            }
          }
        },
        orderBy: { completedAt: 'desc' }
      });

      userData.storyProgress = storyProgress.map(progress => ({
        chapterTitle: progress.chapter.title,
        chapterId: progress.chapter.chapterId,
        completedAt: progress.completedAt,
        choices: progress.choices,
      }));
    }

    // Get feedback if requested
    if (options.includeFeedback) {
      const feedback = await db.feedbackReport.findMany({
        where: { userId },
        select: {
          id: true,
          type: true,
          content: true,
          createdAt: true,
          status: true,
        },
        orderBy: { createdAt: 'desc' }
      });

      userData.feedback = feedback;
    }

    // Generate export file
    const exportData = options.format === 'json' 
      ? JSON.stringify(userData, null, 2)
      : convertToCSV(userData);

    // Save file
    const fileName = `resonai-export-${userId}-${Date.now()}.${options.format}`;
    const filePath = join(process.cwd(), 'exports', fileName);
    
    await mkdir(join(process.cwd(), 'exports'), { recursive: true });
    await writeFile(filePath, exportData, 'utf8');

    // Update export record
    await db.dataExport.update({
      where: { id: exportId },
      data: {
        status: 'COMPLETED',
        filePath,
        completedAt: new Date(),
      }
    });

    span?.setAttributes({
      'data.export_completed': true,
      'data.export_id': exportId,
      'data.file_path': filePath,
      'data.format': options.format,
    });

  } catch (error) {
    // Update export record with error
    await db.dataExport.update({
      where: { id: exportId },
      data: {
        status: 'FAILED',
        completedAt: new Date(),
      }
    });

    span?.setAttributes({
      'data.export_failed': true,
      'data.export_id': exportId,
      'data.error': error instanceof Error ? error.message : 'Unknown error',
    });

    console.error('Data export processing failed:', error);
  }
}

// Helper function to convert data to CSV format
function convertToCSV(data: any): string {
  const lines: string[] = [];
  
  // Add metadata
  lines.push('Section,Field,Value');
  lines.push(`Metadata,Export ID,"${data.exportMetadata.exportId}"`);
  lines.push(`Metadata,Exported At,"${data.exportMetadata.exportedAt}"`);
  lines.push(`Metadata,Format,"${data.exportMetadata.format}"`);
  
  // Add user data
  if (data.user) {
    Object.entries(data.user).forEach(([key, value]) => {
      if (typeof value === 'object' && value !== null) {
        Object.entries(value as any).forEach(([subKey, subValue]) => {
          lines.push(`User,${key}.${subKey},"${subValue}"`);
        });
      } else {
        lines.push(`User,${key},"${value}"`);
      }
    });
  }
  
  // Add engagement data
  if (data.engagement) {
    Object.entries(data.engagement).forEach(([key, value]) => {
      if (Array.isArray(value)) {
        value.forEach((item, index) => {
          if (typeof item === 'object') {
            Object.entries(item).forEach(([subKey, subValue]) => {
              lines.push(`Engagement,${key}[${index}].${subKey},"${subValue}"`);
            });
          } else {
            lines.push(`Engagement,${key}[${index}],"${item}"`);
          }
        });
      } else if (typeof value === 'object' && value !== null) {
        Object.entries(value as any).forEach(([subKey, subValue]) => {
          lines.push(`Engagement,${key}.${subKey},"${subValue}"`);
        });
      } else {
        lines.push(`Engagement,${key},"${value}"`);
      }
    });
  }
  
  return lines.join('\n');
}

// Export config for Edge Runtime
export const runtime = 'edge';

