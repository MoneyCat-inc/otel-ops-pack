// Resonai Backend - Coach Portal API Routes
// Handles E2E encrypted coach grants and data sharing

import { NextRequest, NextResponse } from 'next/server';
import { trace } from '@opentelemetry/api';
import { CoachGrantRequestSchema } from '@/lib/validation/schemas';
import { CoachGrantManager, CoachDataPreparer } from '@/lib/encryption/coach-portal';
import { requireAuth } from '@/lib/middleware/auth';
import { withOTel } from '@/lib/middleware/otel';
import { withRateLimit, rateLimitConfigs } from '@/lib/middleware/rate-limit';

// POST /api/coach/grant - Create E2E encrypted coach grant
export const POST = withOTel(
  withRateLimit(rateLimitConfigs.user, 
    requireAuth(async (req: NextRequest, { user }) => {
      const span = trace.getActiveSpan();
      
      try {
        // Check if user has consented to coach portal
        if (!user.consentCoachPortal) {
          span?.setAttributes({
            'coach.grant_rejected': true,
            'coach.reason': 'no_consent',
          });

          return NextResponse.json(
            {
              success: false,
              error: {
                code: 'CONSENT_REQUIRED',
                message: 'Coach portal access requires explicit consent',
                details: { 
                  requiredConsent: 'coachPortal',
                  currentConsent: {
                    shareMetrics: user.consentShareMetrics,
                    shareClips: user.consentShareClips,
                    coachPortal: user.consentCoachPortal,
                  }
                }
              }
            },
            { status: 403 }
          );
        }

        const body = await req.json();
        const parseResult = CoachGrantRequestSchema.safeParse(body);
        
        if (!parseResult.success) {
          span?.setAttributes({
            'coach.grant_validation_failed': true,
            'coach.error.details': parseResult.error.message
          });
          
          return NextResponse.json(
            {
              success: false,
              error: {
                code: 'VALIDATION_ERROR',
                message: 'Invalid coach grant request',
                details: parseResult.error.errors
              }
            },
            { status: 400 }
          );
        }

        const { coachId, scope, expiresAt, encryptedBlob } = parseResult.data;

        // Validate expiration date
        const expirationDate = new Date(expiresAt);
        if (expirationDate <= new Date()) {
          return NextResponse.json(
            {
              success: false,
              error: {
                code: 'INVALID_EXPIRATION',
                message: 'Grant expiration must be in the future'
              }
            },
            { status: 400 }
          );
        }

        // Maximum 30 days expiration
        const maxExpiration = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);
        if (expirationDate > maxExpiration) {
          return NextResponse.json(
            {
              success: false,
              error: {
                code: 'EXPIRATION_TOO_LONG',
                message: 'Grant expiration cannot exceed 30 days'
              }
            },
            { status: 400 }
          );
        }

        // Prepare data based on scope
        let dataToEncrypt: any;
        
        if (scope === 'metrics') {
          dataToEncrypt = await CoachDataPreparer.prepareEngagementMetrics(user.id);
        } else if (scope === 'notes') {
          dataToEncrypt = await CoachDataPreparer.prepareProgressNotes(user.id);
        } else {
          return NextResponse.json(
            {
              success: false,
              error: {
                code: 'INVALID_SCOPE',
                message: 'Invalid grant scope'
              }
            },
            { status: 400 }
          );
        }

        // Create the grant (server never sees plaintext)
        const { grantId, encryptionKey } = await CoachGrantManager.createGrant(
          user.id,
          coachId,
          scope,
          expirationDate,
          dataToEncrypt
        );

        span?.setAttributes({
          'coach.grant_created': true,
          'coach.grant_id': grantId,
          'coach.scope': scope,
          'coach.coach_id': coachId,
          'coach.expires_at': expirationDate.toISOString(),
        });

        return NextResponse.json({
          success: true,
          data: {
            grantId,
            encryptionKey, // Client needs this to decrypt
            expiresAt: expirationDate.toISOString(),
            scope,
            coachId,
          },
          message: 'Coach grant created successfully'
        });

      } catch (error) {
        span?.setAttributes({
          'coach.grant_error': true,
          'coach.error.message': error instanceof Error ? error.message : 'Unknown error'
        });

        console.error('Failed to create coach grant:', error);

        return NextResponse.json(
          {
            success: false,
            error: {
              code: 'GRANT_CREATION_ERROR',
              message: 'Failed to create coach grant'
            }
          },
          { status: 500 }
        );
      }
    })
  )
);

// GET /api/coach/:grantId - Retrieve encrypted coach grant
export const GET = withOTel(
  withRateLimit(rateLimitConfigs.user, async (req: NextRequest, { params }: { params: { grantId: string } }) => {
    const span = trace.getActiveSpan();
    
    try {
      const { grantId } = params;

      if (!grantId) {
        return NextResponse.json(
          {
            success: false,
            error: {
              code: 'MISSING_GRANT_ID',
              message: 'Grant ID is required'
            }
          },
          { status: 400 }
        );
      }

      // Retrieve the encrypted grant (server never sees plaintext)
      const grant = await CoachGrantManager.getGrant(grantId);

      if (!grant) {
        span?.setAttributes({
          'coach.grant_not_found': true,
          'coach.grant_id': grantId,
        });

        return NextResponse.json(
          {
            success: false,
            error: {
              code: 'GRANT_NOT_FOUND',
              message: 'Grant not found or expired'
            }
          },
          { status: 404 }
        );
      }

      span?.setAttributes({
        'coach.grant_retrieved': true,
        'coach.grant_id': grantId,
        'coach.expires_at': grant.expiresAt.toISOString(),
      });

      return NextResponse.json({
        success: true,
        data: {
          grantId,
          encryptedBlob: grant.encryptedBlob,
          expiresAt: grant.expiresAt.toISOString(),
        },
        message: 'Grant retrieved successfully'
      });

    } catch (error) {
      span?.setAttributes({
        'coach.retrieval_error': true,
        'coach.error.message': error instanceof Error ? error.message : 'Unknown error'
      });

      console.error('Failed to retrieve coach grant:', error);

      return NextResponse.json(
        {
          success: false,
          error: {
            code: 'GRANT_RETRIEVAL_ERROR',
            message: 'Failed to retrieve coach grant'
          }
        },
        { status: 500 }
      );
    }
  })
);

// DELETE /api/coach/:grantId - Revoke coach grant
export const DELETE = withOTel(
  withRateLimit(rateLimitConfigs.user,
    requireAuth(async (req: NextRequest, { user }, { params }: { params: { grantId: string } }) => {
      const span = trace.getActiveSpan();
      
      try {
        const { grantId } = params;

        if (!grantId) {
          return NextResponse.json(
            {
              success: false,
              error: {
                code: 'MISSING_GRANT_ID',
                message: 'Grant ID is required'
              }
            },
            { status: 400 }
          );
        }

        // Revoke the grant (user can only revoke their own grants)
        const success = await CoachGrantManager.revokeGrant(grantId, user.id);

        if (!success) {
          span?.setAttributes({
            'coach.revoke_failed': true,
            'coach.grant_id': grantId,
            'coach.user_id': user.id,
          });

          return NextResponse.json(
            {
              success: false,
              error: {
                code: 'GRANT_REVOKE_FAILED',
                message: 'Failed to revoke grant (not found or not owned by user)'
              }
            },
            { status: 404 }
          );
        }

        span?.setAttributes({
          'coach.grant_revoked': true,
          'coach.grant_id': grantId,
          'coach.user_id': user.id,
        });

        return NextResponse.json({
          success: true,
          data: { grantId },
          message: 'Grant revoked successfully'
        });

      } catch (error) {
        span?.setAttributes({
          'coach.revoke_error': true,
          'coach.error.message': error instanceof Error ? error.message : 'Unknown error'
        });

        console.error('Failed to revoke coach grant:', error);

        return NextResponse.json(
          {
            success: false,
            error: {
              code: 'GRANT_REVOKE_ERROR',
              message: 'Failed to revoke coach grant'
            }
          },
          { status: 500 }
        );
      }
    })
  )
);

// Export config for Edge Runtime
export const config = {
  runtime: 'edge',
};
