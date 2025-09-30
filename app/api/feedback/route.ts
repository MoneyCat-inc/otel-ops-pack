// Resonai Backend - Feedback and Moderation API Routes
// Handles user feedback, abuse reports, and content moderation

import { NextRequest, NextResponse } from 'next/server';
import { trace } from '@opentelemetry/api';
import { FeedbackReportSchema, AbuseReportSchema } from '@/lib/validation/schemas';
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
                details: parseResult.error.errors
              }
            },
            { status: 400 }
          );
        }

        const { type, content, metadata } = parseResult.data;

        // Check if feedback system is enabled
        if (process.env.FEATURE_FEEDBACK_SYSTEM !== 'true') {
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
          eventType: 'feedback_submitted',
          userId: user?.id,
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
                        process.env.ADMIN_USER_IDS?.split(',').includes(user.id);

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
          'feedback.filters': { status, type },
        });

        return NextResponse.json({
          success: true,
          data: {
            feedback: feedback.map(f => ({
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
    requireAuth(async (req: NextRequest, { user }, { params }: { params: { feedbackId: string } }) => {
      const span = trace.getActiveSpan();
      
      try {
        const { feedbackId } = params;

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

        const body = await req.json();
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

// POST /api/report - Submit abuse report
export const report = withOTel(
  withRateLimit(rateLimitConfigs.feedback,
    optionalAuth(async (req: NextRequest, { user }) => {
      const span = trace.getActiveSpan();
      
      try {
        const body = await req.json();
        const parseResult = AbuseReportSchema.safeParse(body);
        
        if (!parseResult.success) {
          span?.setAttributes({
            'report.validation_failed': true,
            'report.error.details': parseResult.error.message
          });
          
          return NextResponse.json(
            {
              success: false,
              error: {
                code: 'VALIDATION_ERROR',
                message: 'Invalid abuse report format',
                details: parseResult.error.errors
              }
            },
            { status: 400 }
          );
        }

        const { content, context, category } = parseResult.data;

        // Create abuse report
        const report = await db.feedbackReport.create({
          data: {
            userId: user?.id || null,
            type: 'ABUSE_REPORT',
            content,
            metadata: {
              category,
              context: context || '',
              reportedAt: new Date().toISOString(),
              reporterType: user ? 'authenticated' : 'anonymous',
            },
            status: 'OPEN',
          }
        });

        // Track abuse report event
        resonaiMetrics.trackPrivacyEvent({
          eventType: 'abuse_reported',
          userId: user?.id,
          details: {
            reportId: report.id,
            category,
            hasContext: !!context,
            hasUser: !!user,
          }
        });

        span?.setAttributes({
          'report.submitted': true,
          'report.id': report.id,
          'report.category': category,
          'report.user_id': user?.id || 'anonymous',
          'report.has_context': !!context,
        });

        return NextResponse.json({
          success: true,
          data: {
            reportId: report.id,
            category,
            status: 'OPEN',
            submittedAt: report.createdAt,
          },
          message: 'Abuse report submitted successfully'
        });

      } catch (error) {
        span?.setAttributes({
          'report.submission_error': true,
          'report.error.message': error instanceof Error ? error.message : 'Unknown error'
        });

        console.error('Failed to submit abuse report:', error);

        return NextResponse.json(
          {
            success: false,
            error: {
              code: 'REPORT_SUBMISSION_ERROR',
              message: 'Failed to submit abuse report'
            }
          },
          { status: 500 }
        );
      }
    })
  )
);

// GET /api/feedback/stats - Get feedback statistics (admin only)
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

        // Get feedback statistics
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
                gte: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000), // Last 7 days
              }
            },
            orderBy: { createdAt: 'desc' },
            take: 10,
            select: {
              id: true,
              type: true,
              status: true,
              createdAt: true,
            }
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
              resolutionRate: totalFeedback > 0 ? Math.round((resolvedFeedback / totalFeedback) * 100) : 0,
            },
            byType: feedbackByType.map(item => ({
              type: item.type,
              count: item._count.type,
            })),
            recent: recentFeedback,
          }
        });

      } catch (error) {
        span?.setAttributes({
          'feedback.stats_error': true,
          'feedback.error.message': error instanceof Error ? error.message : 'Unknown error'
        });

        console.error('Failed to get feedback statistics:', error);

        return NextResponse.json(
          {
            success: false,
            error: {
              code: 'FEEDBACK_STATS_ERROR',
              message: 'Failed to get feedback statistics'
            }
          },
          { status: 500 }
        );
      }
    })
  )
);

// Export config for Edge Runtime
export const runtime = 'edge';

