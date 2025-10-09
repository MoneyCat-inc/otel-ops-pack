// Resonai Backend - Authentication Callback API Route
// Handles magic link verification and session creation

import { NextRequest, NextResponse } from 'next/server';
import { trace } from '@opentelemetry/api';
import { AuthCallbackSchema } from '@/lib/validation/schemas';
import { UserManager, SessionManager } from '@/lib/middleware/auth';
import { withOTel } from '@/lib/middleware/otel';
import { withRateLimit, rateLimitConfigs } from '@/lib/middleware/rate-limit';
import { db } from '@/lib/db';

// POST /api/auth/callback - Verify magic link and create session
export const POST = withOTel(
  withRateLimit(rateLimitConfigs.auth, async (req: NextRequest) => {
    const span = trace.getActiveSpan();
    
    try {
      const body = await req.json();
      const parseResult = AuthCallbackSchema.safeParse(body);
      
      if (!parseResult.success) {
        span?.setAttributes({
          'auth.callback_validation_failed': true,
          'auth.error.details': parseResult.error.message
        });
        
        return NextResponse.json(
          {
            success: false,
            error: {
              code: 'VALIDATION_ERROR',
              message: 'Invalid callback request',
              details: parseResult.error.issues
            }
          },
          { status: 400 }
        );
      }

      const { token } = parseResult.data;

      // Find magic link
      const magicLink = await db.magicLink.findUnique({
        where: { token },
        include: { user: true }
      });

      if (!magicLink) {
        span?.setAttributes({
          'auth.callback_token_not_found': true,
          'auth.token': token.substring(0, 8) + '...',
        });

        return NextResponse.json(
          {
            success: false,
            error: {
              code: 'INVALID_TOKEN',
              message: 'Invalid or expired magic link'
            }
          },
          { status: 400 }
        );
      }

      // Check if token is expired
      if (magicLink.expiresAt < new Date()) {
        span?.setAttributes({
          'auth.callback_token_expired': true,
          'auth.token': token.substring(0, 8) + '...',
          'auth.expires_at': magicLink.expiresAt.toISOString(),
        });

        // Clean up expired token
        await db.magicLink.delete({
          where: { id: magicLink.id }
        });

        return NextResponse.json(
          {
            success: false,
            error: {
              code: 'TOKEN_EXPIRED',
              message: 'Magic link has expired'
            }
          },
          { status: 400 }
        );
      }

      // Check if token was already used
      if (magicLink.used) {
        span?.setAttributes({
          'auth.callback_token_used': true,
          'auth.token': token.substring(0, 8) + '...',
        });

        return NextResponse.json(
          {
            success: false,
            error: {
              code: 'TOKEN_USED',
              message: 'Magic link has already been used'
            }
          },
          { status: 400 }
        );
      }

      // Mark token as used
      await db.magicLink.update({
        where: { id: magicLink.id },
        data: { used: true }
      });

      // Find or create user
      const user = await UserManager.findOrCreateUser(magicLink.email);

      // Create session
      const sessionToken = await SessionManager.createSession(user.id, req);

      // Set session cookie
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
          redirectUrl: magicLink.redirectUrl,
        },
        message: 'Authentication successful'
      });

      // Set secure session cookie
      response.cookies.set('session_token', sessionToken, {
        httpOnly: true,
        secure: process.env.NODE_ENV === 'production',
        sameSite: 'strict',
        maxAge: 24 * 60 * 60, // 24 hours
        path: '/',
      });

      span?.setAttributes({
        'auth.callback_success': true,
        'auth.user_id': user.id,
        'auth.email': magicLink.email,
        'auth.session_created': true,
      });

      return response;

    } catch (error) {
      span?.setAttributes({
        'auth.callback_error': true,
        'auth.error.message': error instanceof Error ? error.message : 'Unknown error'
      });

      console.error('Failed to process auth callback:', error);

      return NextResponse.json(
        {
          success: false,
          error: {
            code: 'CALLBACK_ERROR',
            message: 'Failed to process authentication'
          }
        },
        { status: 500 }
      );
    }
  })
);

// GET /api/auth/callback - Handle magic link redirects
export const GET = withOTel(async (req: NextRequest) => {
  const span = trace.getActiveSpan();
  
  try {
    const { searchParams } = new URL(req.url);
    const token = searchParams.get('token');
    const type = searchParams.get('type');

    if (!token || type !== 'magic_link') {
      span?.setAttributes({
        'auth.callback_get_invalid_params': true,
      });

      return NextResponse.redirect(`${process.env['NEXTAUTH_URL']}/auth/error?error=invalid_request`);
    }

    // Find magic link
    const magicLink = await db.magicLink.findUnique({
      where: { token }
    });

    if (!magicLink || magicLink.expiresAt < new Date() || magicLink.used) {
      span?.setAttributes({
        'auth.callback_get_invalid_token': true,
      });

      return NextResponse.redirect(`${process.env['NEXTAUTH_URL']}/auth/error?error=invalid_token`);
    }

    // Mark token as used
    await db.magicLink.update({
      where: { id: magicLink.id },
      data: { used: true }
    });

    // Find or create user
    const user = await UserManager.findOrCreateUser(magicLink.email);

    // Create session
    const sessionToken = await SessionManager.createSession(user.id, req);

    // Redirect to dashboard with session cookie
    const response = NextResponse.redirect(`${process.env['NEXTAUTH_URL']}${magicLink.redirectUrl}`);

    response.cookies.set('session_token', sessionToken, {
      httpOnly: true,
      secure: process.env.NODE_ENV === 'production',
      sameSite: 'strict',
      maxAge: 24 * 60 * 60, // 24 hours
      path: '/',
    });

    span?.setAttributes({
      'auth.callback_get_success': true,
      'auth.user_id': user.id,
      'auth.email': magicLink.email,
    });

    return response;

  } catch (error) {
    span?.setAttributes({
      'auth.callback_get_error': true,
      'auth.error.message': error instanceof Error ? error.message : 'Unknown error'
    });

    console.error('Failed to process GET auth callback:', error);

    return NextResponse.redirect(`${process.env['NEXTAUTH_URL']}/auth/error?error=server_error`);
  }
});

// Export config for Edge Runtime
export const runtime = 'nodejs';

