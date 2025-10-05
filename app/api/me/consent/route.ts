// Resonai Backend - Consent Management API Route
// Handles consent updates with audit logging for privacy compliance

import { NextRequest, NextResponse } from 'next/server';
import { trace } from '@opentelemetry/api';
import { ConsentUpdateSchema } from '@/lib/validation/schemas';
import { db } from '@/lib/db';
import { requireAuth } from '@/lib/middleware/auth';
import { withOTel } from '@/lib/middleware/otel';

// GET /api/me/consent - Retrieve current consent settings
export const GET = withOTel(
  requireAuth(async (req: NextRequest, { user }) => {
    const span = trace.getActiveSpan();
    
    try {
      const consentSettings = {
        shareMetrics: user.consentShareMetrics,
        shareClips: user.consentShareClips,
        coachPortal: user.consentCoachPortal,
      };

      span?.setAttributes({
        'api.route': 'consent_get',
        'consent.share_metrics': user.consentShareMetrics,
        'consent.share_clips': user.consentShareClips,
        'consent.coach_portal': user.consentCoachPortal,
      });

      return NextResponse.json({
        success: true,
        data: consentSettings
      });

    } catch (error) {
      span?.setAttributes({
        'api.error': 'retrieval_failed',
        'api.error.message': error instanceof Error ? error.message : 'Unknown error'
      });

      console.error('Failed to retrieve consent settings:', error);

      return NextResponse.json(
        {
          success: false,
          error: {
            code: 'RETRIEVAL_ERROR',
            message: 'Failed to retrieve consent settings'
          }
        },
        { status: 500 }
      );
    }
  })
);

// PUT /api/me/consent - Update consent settings with audit logging
export const PUT = withOTel(
  requireAuth(async (req: NextRequest, { user }) => {
    const span = trace.getActiveSpan();
    
    try {
      const body = await req.json();
      const parseResult = ConsentUpdateSchema.safeParse(body);
      
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
              message: 'Invalid consent update format',
              details: parseResult.error.errors
            }
          },
          { status: 400 }
        );
      }

      const consentUpdate = parseResult.data;
      const currentConsent = {
        shareMetrics: user.consentShareMetrics,
        shareClips: user.consentShareClips,
        coachPortal: user.consentCoachPortal,
      };

      // Track changes for audit log
      const auditEntries = [];
      const newConsent = { ...currentConsent };

      // Check each consent field for changes
      Object.entries(consentUpdate).forEach(([field, newValue]) => {
        const oldValue = currentConsent[field as keyof typeof currentConsent];
        if (oldValue !== newValue) {
          auditEntries.push({
            userId: user.id,
            field,
            oldValue,
            newValue,
            changedAt: new Date(),
            ipAddress: req.ip || req.headers.get('x-forwarded-for'),
            userAgent: req.headers.get('user-agent'),
          });
          
          newConsent[field as keyof typeof newConsent] = newValue;
        }
      });

      // If no changes, return current state
      if (auditEntries.length === 0) {
        span?.setAttributes({
          'api.route': 'consent_update',
          'consent.changes': 0,
        });

        return NextResponse.json({
          success: true,
          data: currentConsent,
          message: 'No consent changes detected'
        });
      }

      // Update user consent settings
      const updatedUser = await db.user.update({
        where: { id: user.id },
        data: {
          consentShareMetrics: newConsent.shareMetrics,
          consentShareClips: newConsent.shareClips,
          consentCoachPortal: newConsent.coachPortal,
        }
      });

      // Create audit log entries
      await db.consentAuditLog.createMany({
        data: auditEntries,
      });

      // Log consent change events for analytics
      const eventPromises = auditEntries.map(entry => 
        db.event.create({
          data: {
            userId: user.id,
            kind: 'CONSENT_CHANGE',
            props: {
              field: entry.field,
              oldValue: entry.oldValue,
              newValue: entry.newValue,
              userIdHash: user.userIdHash,
            },
            schema: 'v1',
            cohort: `cohort_${parseInt(user.userIdHash.substring(0, 2), 16) % 10}`,
          }
        })
      );

      await Promise.all(eventPromises);

      span?.setAttributes({
        'api.route': 'consent_update',
        'consent.changes': auditEntries.length,
        'consent.share_metrics': updatedUser.consentShareMetrics,
        'consent.share_clips': updatedUser.consentShareClips,
        'consent.coach_portal': updatedUser.consentCoachPortal,
      });

      return NextResponse.json({
        success: true,
        data: {
          shareMetrics: updatedUser.consentShareMetrics,
          shareClips: updatedUser.consentShareClips,
          coachPortal: updatedUser.consentCoachPortal,
        },
        message: `Successfully updated ${auditEntries.length} consent setting(s)`
      });

    } catch (error) {
      span?.setAttributes({
        'api.error': 'update_failed',
        'api.error.message': error instanceof Error ? error.message : 'Unknown error'
      });

      console.error('Failed to update consent settings:', error);

      return NextResponse.json(
        {
          success: false,
          error: {
            code: 'UPDATE_ERROR',
            message: 'Failed to update consent settings'
          }
        },
        { status: 500 }
      );
    }
  })
);

// Export config for Edge Runtime
export const runtime = 'nodejs';

