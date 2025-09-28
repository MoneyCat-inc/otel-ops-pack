// Resonai Backend - Authentication Middleware
// Handles session management, user authentication, and authorization

import { NextRequest, NextResponse } from 'next/server';
import { cookies } from 'next/headers';
import { createHash, randomBytes } from 'crypto';
import { db } from '@/lib/db';
import { trace } from '@opentelemetry/api';

// Session configuration
const SESSION_DURATION = 24 * 60 * 60 * 1000; // 24 hours
const REFRESH_TOKEN_DURATION = 7 * 24 * 60 * 60 * 1000; // 7 days

// User context interface
export interface UserContext {
  id: string;
  email?: string;
  userIdHash: string;
  consentShareMetrics: boolean;
  consentShareClips: boolean;
  consentCoachPortal: boolean;
  createdAt: Date;
}

// Authentication middleware
export function requireAuth<T extends any[]>(
  handler: (req: NextRequest, context: { user: UserContext }, ...args: T) => Promise<NextResponse>
) {
  return async (req: NextRequest, ...args: T): Promise<NextResponse> => {
    const span = trace.getActiveSpan();
    
    try {
      // Extract session token from cookies
      const cookieStore = cookies();
      const sessionToken = cookieStore.get('session_token')?.value;
      
      if (!sessionToken) {
        span?.setAttributes({
          'auth.error': 'no_session_token',
          'auth.required': true,
        });
        
        return NextResponse.json(
          {
            success: false,
            error: {
              code: 'AUTHENTICATION_REQUIRED',
              message: 'Authentication required',
              details: { redirectTo: '/auth/login' }
            }
          },
          { status: 401 }
        );
      }

      // Validate session token
      const session = await db.session.findUnique({
        where: { token: sessionToken },
        include: {
          user: true,
        }
      });

      if (!session || session.expiresAt < new Date()) {
        // Clean up expired session
        if (session) {
          await db.session.delete({
            where: { id: session.id }
          });
        }

        span?.setAttributes({
          'auth.error': 'session_expired',
          'auth.session_id': session?.id || 'unknown',
        });

        return NextResponse.json(
          {
            success: false,
            error: {
              code: 'SESSION_EXPIRED',
              message: 'Session expired',
              details: { redirectTo: '/auth/login' }
            }
          },
          { 
            status: 401,
            headers: {
              'Set-Cookie': 'session_token=; Path=/; HttpOnly; Secure; SameSite=Strict; Max-Age=0'
            }
          }
        );
      }

      // Check if user still exists and is active
      if (!session.user) {
        span?.setAttributes({
          'auth.error': 'user_not_found',
          'auth.session_id': session.id,
        });

        return NextResponse.json(
          {
            success: false,
            error: {
              code: 'USER_NOT_FOUND',
              message: 'User account not found'
            }
          },
          { status: 404 }
        );
      }

      // Create user context
      const userContext: UserContext = {
        id: session.user.id,
        email: session.user.email || undefined,
        userIdHash: session.user.userIdHash,
        consentShareMetrics: session.user.consentShareMetrics,
        consentShareClips: session.user.consentShareClips,
        consentCoachPortal: session.user.consentCoachPortal,
        createdAt: session.user.createdAt,
      };

      // Update last activity
      await db.session.update({
        where: { id: session.id },
        data: { 
          // Update expiresAt to extend session
          expiresAt: new Date(Date.now() + SESSION_DURATION)
        }
      });

      span?.setAttributes({
        'auth.success': true,
        'auth.user_id': userContext.id,
        'auth.user_id_hash': userContext.userIdHash,
        'auth.consent_metrics': userContext.consentShareMetrics,
        'auth.consent_coach': userContext.consentCoachPortal,
      });

      // Execute the handler with user context
      return await handler(req, { user: userContext }, ...args);

    } catch (error) {
      span?.setAttributes({
        'auth.error': 'middleware_error',
        'auth.error.message': error instanceof Error ? error.message : 'Unknown error'
      });

      console.error('Authentication middleware error:', error);

      return NextResponse.json(
        {
          success: false,
          error: {
            code: 'AUTHENTICATION_ERROR',
            message: 'Authentication failed'
          }
        },
        { status: 500 }
      );
    }
  };
}

// Optional authentication middleware (doesn't require auth)
export function optionalAuth<T extends any[]>(
  handler: (req: NextRequest, context: { user?: UserContext }, ...args: T) => Promise<NextResponse>
) {
  return async (req: NextRequest, ...args: T): Promise<NextResponse> => {
    const span = trace.getActiveSpan();
    
    try {
      const cookieStore = cookies();
      const sessionToken = cookieStore.get('session_token')?.value;
      
      let userContext: UserContext | undefined;

      if (sessionToken) {
        const session = await db.session.findUnique({
          where: { token: sessionToken },
          include: { user: true }
        });

        if (session && session.expiresAt > new Date() && session.user) {
          userContext = {
            id: session.user.id,
            email: session.user.email || undefined,
            userIdHash: session.user.userIdHash,
            consentShareMetrics: session.user.consentShareMetrics,
            consentShareClips: session.user.consentShareClips,
            consentCoachPortal: session.user.consentCoachPortal,
            createdAt: session.user.createdAt,
          };

          span?.setAttributes({
            'auth.optional_success': true,
            'auth.user_id': userContext.id,
          });
        }
      }

      span?.setAttributes({
        'auth.optional_user_present': !!userContext,
      });

      return await handler(req, { user: userContext }, ...args);

    } catch (error) {
      span?.setAttributes({
        'auth.optional_error': true,
        'auth.error.message': error instanceof Error ? error.message : 'Unknown error'
      });

      // Continue without authentication on error
      return await handler(req, { user: undefined }, ...args);
    }
  };
}

// Session management utilities
export class SessionManager {
  // Create new session
  static async createSession(userId: string, req: NextRequest): Promise<string> {
    const token = randomBytes(32).toString('hex');
    const expiresAt = new Date(Date.now() + SESSION_DURATION);
    
    const ipAddress = req.ip || req.headers.get('x-forwarded-for') || 'unknown';
    const userAgent = req.headers.get('user-agent') || '';

    await db.session.create({
      data: {
        userId,
        token,
        expiresAt,
        ipAddress,
        userAgent,
      }
    });

    return token;
  }

  // Refresh session
  static async refreshSession(sessionToken: string): Promise<string | null> {
    const session = await db.session.findUnique({
      where: { token: sessionToken }
    });

    if (!session || session.expiresAt < new Date()) {
      return null;
    }

    const newToken = randomBytes(32).toString('hex');
    const newExpiresAt = new Date(Date.now() + SESSION_DURATION);

    await db.session.update({
      where: { id: session.id },
      data: {
        token: newToken,
        expiresAt: newExpiresAt,
      }
    });

    return newToken;
  }

  // Revoke session
  static async revokeSession(sessionToken: string): Promise<void> {
    await db.session.deleteMany({
      where: { token: sessionToken }
    });
  }

  // Revoke all user sessions
  static async revokeAllUserSessions(userId: string): Promise<void> {
    await db.session.deleteMany({
      where: { userId }
    });
  }

  // Clean up expired sessions
  static async cleanupExpiredSessions(): Promise<number> {
    const result = await db.session.deleteMany({
      where: {
        expiresAt: {
          lt: new Date()
        }
      }
    });

    return result.count;
  }
}

// User management utilities
export class UserManager {
  // Create or find user by email
  static async findOrCreateUser(email: string): Promise<UserContext> {
    const serverSalt = process.env.USER_HASH_SALT;
    if (!serverSalt) {
      throw new Error('USER_HASH_SALT environment variable not set');
    }

    // Check if user exists
    let user = await db.user.findUnique({
      where: { email }
    });

    if (!user) {
      // Create new user
      const userIdHash = createHash('sha256')
        .update(email + serverSalt)
        .digest('hex')
        .substring(0, 16);

      user = await db.user.create({
        data: {
          email,
          userIdHash,
          consentShareMetrics: false,
          consentShareClips: false,
          consentCoachPortal: false,
        }
      });
    }

    return {
      id: user.id,
      email: user.email || undefined,
      userIdHash: user.userIdHash,
      consentShareMetrics: user.consentShareMetrics,
      consentShareClips: user.consentShareClips,
      consentCoachPortal: user.consentCoachPortal,
      createdAt: user.createdAt,
    };
  }

  // Create anonymous user
  static async createAnonymousUser(): Promise<UserContext> {
    const serverSalt = process.env.USER_HASH_SALT;
    if (!serverSalt) {
      throw new Error('USER_HASH_SALT environment variable not set');
    }

    const anonymousId = randomBytes(16).toString('hex');
    const userIdHash = createHash('sha256')
      .update(anonymousId + serverSalt)
      .digest('hex')
      .substring(0, 16);

    const user = await db.user.create({
      data: {
        userIdHash,
        consentShareMetrics: false,
        consentShareClips: false,
        consentCoachPortal: false,
      }
    });

    return {
      id: user.id,
      userIdHash: user.userIdHash,
      consentShareMetrics: user.consentShareMetrics,
      consentShareClips: user.consentShareClips,
      consentCoachPortal: user.consentCoachPortal,
      createdAt: user.createdAt,
    };
  }

  // Update user consent
  static async updateUserConsent(
    userId: string, 
    consent: Partial<{
      shareMetrics: boolean;
      shareClips: boolean;
      coachPortal: boolean;
    }>
  ): Promise<UserContext> {
    const user = await db.user.update({
      where: { id: userId },
      data: consent
    });

    return {
      id: user.id,
      email: user.email || undefined,
      userIdHash: user.userIdHash,
      consentShareMetrics: user.consentShareMetrics,
      consentShareClips: user.consentShareClips,
      consentCoachPortal: user.consentCoachPortal,
      createdAt: user.createdAt,
    };
  }
}

// Authorization helpers
export class Authorization {
  // Check if user can access coach portal
  static canAccessCoachPortal(user: UserContext): boolean {
    return user.consentCoachPortal;
  }

  // Check if user can share metrics
  static canShareMetrics(user: UserContext): boolean {
    return user.consentShareMetrics;
  }

  // Check if user can share clips (always false for now)
  static canShareClips(user: UserContext): boolean {
    return false; // Always false per privacy policy
  }

  // Check if user has email (opted into account features)
  static hasEmail(user: UserContext): boolean {
    return !!user.email;
  }
}
