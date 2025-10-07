// Resonai Backend - Feedback and Moderation API Routes
// Handles user feedback, abuse reports, and content moderation

import { NextRequest, NextResponse } from 'next/server';
import { trace } from '@opentelemetry/api';
import { FeedbackReportSchema } from '@/lib/validation/schemas';
import { requireAuth, optionalAuth } from '@/lib/middleware/auth';
import { withOTel } from '@/lib/middleware/otel';
import { withRateLimit, rateLimitConfigs } from '@/lib/middleware/rate-limit';
import { db } from '@/lib/db';
import { resonaiMetrics } from '@/lib/observability/signoz';

// POST /api/feedback - Submit user feedback
export const POST = withOTel(
  withRateLimit(rateLimitConfigs.feedback,
    optionalAuth(async (req: NextRequest, { user }) => {
      const span = trace.getActiveSpan();
      
      try {
        const body = await req.json();
        const parseResult = FeedbackReportSchema.safeParse(body);
        
        if (!parseResult.success) {
          span?.setAttributes({
            'feedback.validation_failed': true,
            'feedback.error.details': parseResult.error.message
          });
          
          return NextResponse.json(
            {
              success: false,
              error: {
                code: 'VALIDATION_ERROR',
                message: 'Invalid feedback format',
                details: parseResult.error.issues
              }
            },
            { status: 400 }
          );
        }

        const { type, content, metadata } = parseResult.data;

        // Check if feedback system is enabled
        if (process.env['FEATURE_FEEDBACK_SYSTEM'] !== 'true') {
          return NextResponse.json(
            {
              success: false,
              error: {
                code: 'FEATURE_DISABLED',
                message: 'Feedback system is currently disabled'
              }
            },
            { status: 503 }
          );
        }

        // Create feedback report
        const feedback = await db.feedbackReport.create({
          data: {
            userId: user?.id || null,
            type: type.toUpperCase() as any,
            content,
            metadata: metadata || {},
            status: 'OPEN',
          }
        });

        // Track feedback event
        resonaiMetrics.trackPrivacyEvent({
          eventType: 'pii_detected',
          ...(user?.id && { userId: user.id }),
          details: {
            feedbackType: type,
            feedbackId: feedback.id,
            hasUser: !!user,
          }
        });

        span?.setAttributes({
          'feedback.submitted': true,
          'feedback.id': feedback.id,
          'feedback.type': type,
          'feedback.user_id': user?.id || 'anonymous',
          'feedback.has_metadata': !!metadata,
        });

        return NextResponse.json({
          success: true,
          data: {
            feedbackId: feedback.id,
            type,
            status: 'OPEN',
            submittedAt: feedback.createdAt,
          },
          message: 'Feedback submitted successfully'
        });

      } catch (error) {
        span?.setAttributes({
          'feedback.submission_error': true,
          'feedback.error.message': error instanceof Error ? error.message : 'Unknown error'
        });

        console.error('Failed to submit feedback:', error);

        return NextResponse.json(
          {
            success: false,
            error: {
              code: 'FEEDBACK_SUBMISSION_ERROR',
              message: 'Failed to submit feedback'
            }
          },
          { status: 500 }
        );
      }
    })
  )
);

// GET /api/feedback - Get feedback reports (admin only)
export const GET = withOTel(
  withRateLimit(rateLimitConfigs.user,
    requireAuth(async (req: NextRequest, { user }) => {
      const span = trace.getActiveSpan();
      
      try {
        // Check if user is admin (simplified check - implement proper admin system)
        const isAdmin = user.email?.endsWith('@resonai.app') || 
                        process.env['ADMIN_USER_IDS']?.split(',').includes(user.id);

        if (!isAdmin) {
          span?.setAttributes({
            'feedback.admin_access_denied': true,
            'feedback.user_id': user.id,
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

        const { searchParams } = new URL(req.url);
        const status = searchParams.get('status');
        const type = searchParams.get('type');
        const limit = parseInt(searchParams.get('limit') || '50');
        const offset = parseInt(searchParams.get('offset') || '0');

        // Build query conditions
        const whereConditions: any = {};
        
        if (status) {
          whereConditions.status = status.toUpperCase();
        }
        
        if (type) {
          whereConditions.type = type.toUpperCase();
        }

        // Get feedback reports
        const feedback = await db.feedbackReport.findMany({
          where: whereConditions,
          orderBy: { createdAt: 'desc' },
          take: Math.min(limit, 100), // Cap at 100
          skip: offset,
          select: {
            id: true,
            type: true,
            content: true,
            status: true,
            createdAt: true,
            metadata: true,
            user: {
              select: {
                id: true,
                email: true,
                createdAt: true,
              }
            }
          }
        });

        // Get total count
        const totalCount = await db.feedbackReport.count({
          where: whereConditions
        });

        span?.setAttributes({
          'feedback.admin_retrieved': true,
          'feedback.count': feedback.length,
          'feedback.total_count': totalCount,
          'feedback.status_filter': status || 'none',
          'feedback.type_filter': type || 'none',
        });

        return NextResponse.json({
          success: true,
          data: {
            feedback: feedback.map((f: any) => ({
              id: f.id,
              type: f.type,
              content: f.content,
              status: f.status,
              createdAt: f.createdAt,
              metadata: f.metadata,
              user: f.user ? {
                id: f.user.id,
                email: f.user.email,
                createdAt: f.user.createdAt,
              } : null,
            })),
            pagination: {
              limit,
              offset,
              total: totalCount,
              hasMore: offset + feedback.length < totalCount,
            }
          }
        });

      } catch (error) {
        span?.setAttributes({
          'feedback.admin_retrieval_error': true,
          'feedback.error.message': error instanceof Error ? error.message : 'Unknown error'
        });

        console.error('Failed to retrieve feedback reports:', error);

        return NextResponse.json(
          {
            success: false,
            error: {
              code: 'FEEDBACK_RETRIEVAL_ERROR',
              message: 'Failed to retrieve feedback reports'
            }
          },
          { status: 500 }
        );
      }
    })
  )
);

// PUT /api/feedback/:feedbackId - Update feedback status (admin only)
export const PUT = withOTel(
  withRateLimit(rateLimitConfigs.user,
    requireAuth(async (req: NextRequest, { user }: { user: any }) => {
      const span = trace.getActiveSpan();
      
      try {
        const { searchParams } = new URL(req.url);
        const feedbackId = searchParams.get('feedbackId');

        if (!feedbackId) {
          return NextResponse.json(
            {
              success: false,
              error: {
                code: 'MISSING_FEEDBACK_ID',
                message: 'Feedback ID is required'
              }
            },
            { status: 400 }
          );
        }

        // Check if user is admin
        const isAdmin = user.email?.endsWith('@resonai.app') || 
                        process.env['ADMIN_USER_IDS']?.split(',').includes(user.id);

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

        const body = await req.json() as { status: string; adminNotes?: string };
        const { status, adminNotes } = body;

        if (!status || !['OPEN', 'IN_REVIEW', 'RESOLVED', 'CLOSED'].includes(status)) {
          return NextResponse.json(
            {
              success: false,
              error: {
                code: 'INVALID_STATUS',
                message: 'Invalid status value'
              }
            },
            { status: 400 }
          );
        }

        // Update feedback status
        const updatedFeedback = await db.feedbackReport.update({
          where: { id: feedbackId },
          data: {
            status: status as any,
            metadata: adminNotes ? {
              adminNotes,
              updatedBy: user.id,
              updatedAt: new Date().toISOString(),
            } : undefined,
          }
        });

        span?.setAttributes({
          'feedback.status_updated': true,
          'feedback.id': feedbackId,
          'feedback.new_status': status,
          'feedback.admin_id': user.id,
        });

        return NextResponse.json({
          success: true,
          data: {
            feedbackId: updatedFeedback.id,
            status: updatedFeedback.status,
            updatedAt: new Date().toISOString(),
          },
          message: 'Feedback status updated successfully'
        });

      } catch (error) {
        span?.setAttributes({
          'feedback.status_update_error': true,
          'feedback.error.message': error instanceof Error ? error.message : 'Unknown error'
        });

        console.error('Failed to update feedback status:', error);

        return NextResponse.json(
          {
            success: false,
            error: {
              code: 'FEEDBACK_UPDATE_ERROR',
              message: 'Failed to update feedback status'
            }
          },
          { status: 500 }
        );
      }
    })
  )
);

// Note: Additional functionality moved to main handlers above with query parameters

// Export config for Edge Runtime
export const runtime = 'nodejs';

