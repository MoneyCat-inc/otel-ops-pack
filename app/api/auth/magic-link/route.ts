// Resonai Backend - Magic Link Authentication API Route
// Handles magic link generation and verification

import { NextRequest, NextResponse } from 'next/server';
import { trace } from '@opentelemetry/api';
import { MagicLinkRequestSchema } from '@/lib/validation/schemas';
import { UserManager } from '@/lib/middleware/auth';
import { withOTel } from '@/lib/middleware/otel';
import { withRateLimit, rateLimitConfigs } from '@/lib/middleware/rate-limit';
import { randomBytes } from 'crypto';
import { db } from '@/lib/db';

// Magic link configuration
const MAGIC_LINK_EXPIRY = 15 * 60 * 1000; // 15 minutes
const MAGIC_LINK_SECRET = process.env['MAGIC_LINK_SECRET'] || process.env['NEXTAUTH_SECRET'];

if (!MAGIC_LINK_SECRET) {
  throw new Error('MAGIC_LINK_SECRET or NEXTAUTH_SECRET environment variable is required');
}

// POST /api/auth/magic-link - Send magic link
export const POST = withOTel(
  withRateLimit(rateLimitConfigs.auth, async (req: NextRequest) => {
    const span = trace.getActiveSpan();
    
    try {
      const body = await req.json();
      const parseResult = MagicLinkRequestSchema.safeParse(body);
      
      if (!parseResult.success) {
        span?.setAttributes({
          'auth.magic_link_validation_failed': true,
          'auth.error.details': parseResult.error.message
        });
        
        return NextResponse.json(
          {
            success: false,
            error: {
              code: 'VALIDATION_ERROR',
              message: 'Invalid magic link request',
              details: parseResult.error.issues
            }
          },
          { status: 400 }
        );
      }

      const { email, redirectUrl } = parseResult.data;

      // Check if magic links are enabled
      if (process.env['FEATURE_MAGIC_LINK_AUTH'] !== 'true') {
        return NextResponse.json(
          {
            success: false,
            error: {
              code: 'FEATURE_DISABLED',
              message: 'Magic link authentication is disabled'
            }
          },
          { status: 503 }
        );
      }

      // Find or create user
      const user = await UserManager.findOrCreateUser(email);

      // Generate magic link token
      const token = randomBytes(32).toString('hex');
      const expiresAt = new Date(Date.now() + MAGIC_LINK_EXPIRY);

      // Store magic link in database
      await db.magicLink.create({
        data: {
          email,
          token,
          expiresAt,
          redirectUrl: redirectUrl || '/dashboard',
          used: false,
        }
      });

      // Generate magic link URL
      const magicLinkUrl = `${process.env['NEXTAUTH_URL']}/api/auth/callback?token=${token}&type=magic_link`;

      // Send email (in production, integrate with your email service)
      await sendMagicLinkEmail(email, magicLinkUrl, redirectUrl);

      span?.setAttributes({
        'auth.magic_link_sent': true,
        'auth.user_id': user.id,
        'auth.email': email,
        'auth.expires_at': expiresAt.toISOString(),
      });

      return NextResponse.json({
        success: true,
        data: {
          message: 'Magic link sent to your email',
          expiresIn: MAGIC_LINK_EXPIRY / 1000, // seconds
        },
        message: 'Magic link sent successfully'
      });

    } catch (error) {
      span?.setAttributes({
        'auth.magic_link_error': true,
        'auth.error.message': error instanceof Error ? error.message : 'Unknown error'
      });

      console.error('Failed to send magic link:', error);

      return NextResponse.json(
        {
          success: false,
          error: {
            code: 'MAGIC_LINK_ERROR',
            message: 'Failed to send magic link'
          }
        },
        { status: 500 }
      );
    }
  })
);

// Email sending function (replace with your email service)
async function sendMagicLinkEmail(email: string, magicLinkUrl: string, redirectUrl?: string): Promise<void> {
  const span = trace.getActiveSpan();
  
  try {
    // In development, just log the link
    if (process.env.NODE_ENV === 'development') {
      console.log(`🔗 Magic link for ${email}: ${magicLinkUrl}`);
      return;
    }

    // In production, send actual email
    const emailService = process.env['SMTP_HOST'] ? 'smtp' : 'sendgrid';
    
    if (emailService === 'smtp') {
      await sendSMTPEmail(email, magicLinkUrl, redirectUrl);
    } else if (emailService === 'sendgrid') {
      await sendSendGridEmail(email, magicLinkUrl, redirectUrl);
    }

    span?.setAttributes({
      'email.magic_link_sent': true,
      'email.service': emailService,
      'email.recipient': email,
    });

  } catch (error) {
    span?.setAttributes({
      'email.magic_link_error': true,
      'email.error.message': error instanceof Error ? error.message : 'Unknown error'
    });

    console.error('Failed to send magic link email:', error);
    throw error;
  }
}

// SMTP email sending
async function sendSMTPEmail(email: string, magicLinkUrl: string, _redirectUrl?: string): Promise<void> {
  // Implement SMTP email sending
  // This is a placeholder - integrate with your preferred SMTP service
  console.log(`SMTP: Sending magic link to ${email}: ${magicLinkUrl}`);
}

// SendGrid email sending
async function sendSendGridEmail(email: string, magicLinkUrl: string, _redirectUrl?: string): Promise<void> {
  // Implement SendGrid email sending
  // This is a placeholder - integrate with SendGrid API
  console.log(`SendGrid: Sending magic link to ${email}: ${magicLinkUrl}`);
}

// Export runtime configuration for Edge Runtime
export const runtime = 'nodejs';
