// Resonai Backend - Session Management API Route
// Handles session creation, refresh, and revocation

import { NextRequest, NextResponse } from 'next/server';
import { trace } from '@opentelemetry/api';
import { SessionManager, UserManager } from '@/lib/middleware/auth';
import { withOTel } from '@/lib/middleware/otel';
import { withRateLimit, rateLimitConfigs } from '@/lib/middleware/rate-limit';
import { requireAuth, optionalAuth } from '@/lib/middleware/auth';

// POST /api/auth/session - Create anonymous session
export const POST = withOTel(
  withRateLimit(rateLimitConfigs.user, async (req: NextRequest) => {
    const span = trace.getActiveSpan();
    
    try {
      // Create anonymous user
      const user = await UserManager.createAnonymousUser();

      // Create session
      const sessionToken = await SessionManager.createSession(user.id, req);

      // Set session cookie
      const response = NextResponse.json({
        success: true,
        data: {
          user: {
            id: user.id,
            consentShareMetrics: user.consentShareMetrics,
            consentShareClips: user.consentShareClips,
            consentCoachPortal: user.consentCoachPortal,
          },
        },
        message: 'Anonymous session created'
      });

      response.cookies.set('session_token', sessionToken, {
        httpOnly: true,
        secure: process.env.NODE_ENV === 'production',
        sameSite: 'strict',
        maxAge: 24 * 60 * 60, // 24 hours
        path: '/',
      });

      span?.setAttributes({
        'auth.anonymous_session_created': true,
        'auth.user_id': user.id,
        'auth.user_id_hash': user.userIdHash,
      });

      return response;

    } catch (error) {
      span?.setAttributes({
        'auth.session_creation_error': true,
        'auth.error.message': error instanceof Error ? error.message : 'Unknown error'
      });

      console.error('Failed to create anonymous session:', error);

      return NextResponse.json(
        {
          success: false,
          error: {
            code: 'SESSION_CREATION_ERROR',
            message: 'Failed to create session'
          }
        },
        { status: 500 }
      );
    }
  })
);

// PUT /api/auth/session - Refresh session
export const PUT = withOTel(
  withRateLimit(rateLimitConfigs.user,
    optionalAuth(async (req: NextRequest, { user }) => {
      const span = trace.getActiveSpan();
      
      try {
        if (!user) {
          span?.setAttributes({
            'auth.refresh_no_user': true,
          });

          return NextResponse.json(
            {
              success: false,
              error: {
                code: 'AUTHENTICATION_REQUIRED',
                message: 'No active session to refresh'
              }
            },
            { status: 401 }
          );
        }

        // Refresh session token
        const cookieStore = req.cookies;
        const currentToken = cookieStore.get('session_token')?.value;
        
        if (!currentToken) {
          return NextResponse.json(
            {
              success: false,
              error: {
                code: 'NO_SESSION_TOKEN',
                message: 'No session token found'
              }
            },
            { status: 401 }
          );
        }

        const newToken = await SessionManager.refreshSession(currentToken);

        if (!newToken) {
          span?.setAttributes({
            'auth.refresh_failed': true,
            'auth.user_id': user.id,
          });

          return NextResponse.json(
            {
              success: false,
              error: {
                code: 'SESSION_REFRESH_FAILED',
                message: 'Failed to refresh session'
              }
            },
            { status: 401 }
          );
        }

        // Set new session cookie
        const response = NextResponse.json({
          success: true,
          data: {
            user: {
              id: user.id,
              email: user.email,
              consentShareMetrics: user.consentShareMetrics,
              consentShareClips: user.consentShareClips,
              consentCoachPortal: user.consentCoachPortal,
            },
          },
          message: 'Session refreshed successfully'
        });

        response.cookies.set('session_token', newToken, {
          httpOnly: true,
          secure: process.env.NODE_ENV === 'production',
          sameSite: 'strict',
          maxAge: 24 * 60 * 60, // 24 hours
          path: '/',
        });

        span?.setAttributes({
          'auth.session_refreshed': true,
          'auth.user_id': user.id,
        });

        return response;

      } catch (error) {
        span?.setAttributes({
          'auth.refresh_error': true,
          'auth.error.message': error instanceof Error ? error.message : 'Unknown error'
        });

        console.error('Failed to refresh session:', error);

        return NextResponse.json(
          {
            success: false,
            error: {
              code: 'SESSION_REFRESH_ERROR',
              message: 'Failed to refresh session'
            }
          },
          { status: 500 }
        );
      }
    })
  )
);

// DELETE /api/auth/session - Revoke session
export const DELETE = withOTel(
  withRateLimit(rateLimitConfigs.user,
    optionalAuth(async (req: NextRequest, { user }) => {
      const span = trace.getActiveSpan();
      
      try {
        const cookieStore = req.cookies;
        const sessionToken = cookieStore.get('session_token')?.value;

        if (sessionToken) {
          // Revoke current session
          await SessionManager.revokeSession(sessionToken);
        }

        if (user) {
          // Revoke all user sessions if requested
          const { revokeAll } = await req.json().catch(() => ({}));
          if (revokeAll) {
            await SessionManager.revokeAllUserSessions(user.id);
          }
        }

        // Clear session cookie
        const response = NextResponse.json({
          success: true,
          data: { revoked: true },
          message: 'Session revoked successfully'
        });

        response.cookies.set('session_token', '', {
          httpOnly: true,
          secure: process.env.NODE_ENV === 'production',
          sameSite: 'strict',
          maxAge: 0, // Expire immediately
          path: '/',
        });

        span?.setAttributes({
          'auth.session_revoked': true,
          'auth.user_id': user?.id || 'anonymous',
          'auth.revoke_all': !!user,
        });

        return response;

      } catch (error) {
        span?.setAttributes({
          'auth.revoke_error': true,
          'auth.error.message': error instanceof Error ? error.message : 'Unknown error'
        });

        console.error('Failed to revoke session:', error);

        return NextResponse.json(
          {
            success: false,
            error: {
              code: 'SESSION_REVOKE_ERROR',
              message: 'Failed to revoke session'
            }
          },
          { status: 500 }
        );
      }
    })
  )
);

// GET /api/auth/session - Get current session info
export const GET = withOTel(
  optionalAuth(async (req: NextRequest, { user }) => {
    const span = trace.getActiveSpan();
    
    try {
      if (!user) {
        span?.setAttributes({
          'auth.session_get_no_user': true,
        });

        return NextResponse.json({
          success: true,
          data: {
            authenticated: false,
            user: null,
          }
        });
      }

      span?.setAttributes({
        'auth.session_get_success': true,
        'auth.user_id': user.id,
        'auth.has_email': !!user.email,
      });

      return NextResponse.json({
        success: true,
        data: {
          authenticated: true,
          user: {
            id: user.id,
            email: user.email,
            consentShareMetrics: user.consentShareMetrics,
            consentShareClips: user.consentShareClips,
            consentCoachPortal: user.consentCoachPortal,
            createdAt: user.createdAt,
          },
        }
      });

    } catch (error) {
      span?.setAttributes({
        'auth.session_get_error': true,
        'auth.error.message': error instanceof Error ? error.message : 'Unknown error'
      });

      console.error('Failed to get session info:', error);

      return NextResponse.json(
        {
          success: false,
          error: {
            code: 'SESSION_GET_ERROR',
            message: 'Failed to get session information'
          }
        },
        { status: 500 }
      );
    }
  })
);

// Export config for Edge Runtime
export const runtime = 'edge';

