import { NextRequest, NextResponse } from 'next/server';
import { trace } from '@opentelemetry/api';
import { AbuseReportSchema } from '@/lib/validation/schemas';
import { requireAuth } from '@/lib/middleware/auth';
import { withOTel } from '@/lib/middleware/otel';
import { withRateLimit, rateLimitConfigs } from '@/lib/middleware/rate-limit';
import { db } from '@/lib/db';
import { resonaiMetrics } from '@/lib/observability/signoz';

// POST /api/feedback/report - Submit abuse report (authenticated)
export const POST = withOTel(
  withRateLimit(rateLimitConfigs.feedback,
    requireAuth(async (req: NextRequest, { user }) => {
      const span = trace.getActiveSpan();

      try {
        const body = await req.json();
        const parseResult = AbuseReportSchema.safeParse(body);

        if (!parseResult.success) {
          span?.setAttributes({
            'report.validation_failed': true,
            'report.error.details': parseResult.error.message,
          });

          return NextResponse.json(
            {
              success: false,
              error: {
                code: 'VALIDATION_ERROR',
                message: 'Invalid abuse report',
                details: parseResult.error.issues,
              },
            },
            { status: 400 },
          );
        }

        const { content, category, context } = parseResult.data;

        const report = await db.feedbackReport.create({
          data: {
            userId: user.id,
            type: 'GENERAL',
            content,
            metadata: {
              reportKind: 'abuse',
              category,
              context: context || '',
            },
            status: 'OPEN',
          },
        });

        // Track privacy event for abuse reports
        resonaiMetrics.trackPrivacyEvent({
          eventType: 'pii_detected',
          userId: user.id,
          details: {
            reportId: report.id,
            category,
            hasContext: !!context,
          },
        });

        span?.setAttributes({
          'report.submitted': true,
          'report.id': report.id,
          'report.category': category,
          'report.has_context': !!context,
        });

        return NextResponse.json({
          success: true,
          data: {
            reportId: report.id,
            category,
            status: report.status,
            submittedAt: report.createdAt,
          },
          message: 'Abuse report submitted successfully',
        });
      } catch (error) {
        span?.setAttributes({
          'report.submission_error': true,
          'report.error.message': error instanceof Error ? error.message : 'Unknown error',
        });

        console.error('Failed to submit abuse report:', error);

        return NextResponse.json(
          {
            success: false,
            error: {
              code: 'REPORT_SUBMISSION_ERROR',
              message: 'Failed to submit abuse report',
            },
          },
          { status: 500 },
        );
      }
    }),
  ),
);

export const runtime = 'nodejs';
