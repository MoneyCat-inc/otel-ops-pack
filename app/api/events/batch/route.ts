// Resonai Backend - Events Batch API Route
// Edge runtime for optimal performance and global distribution

import { NextRequest, NextResponse } from 'next/server';
import { trace } from '@opentelemetry/api';
import { EventsBatchSchema, type EventsBatch } from '@/lib/validation/schemas';
import { createHash } from 'crypto';
import { db } from '@/lib/db';
import { withRateLimit } from '@/lib/middleware/rate-limit';
import { withOTel } from '@/lib/middleware/otel';

// Rate limiting: 100 requests per minute per IP + userIdHash
const rateLimitConfig = {
  requests: 100,
  windowMs: 60 * 1000, // 1 minute
  keyGenerator: (req: NextRequest) => {
    // Use IP + user identifier for rate limiting
    const ip = req.ip || req.headers.get('x-forwarded-for') || 'unknown';
    const userIdHash = req.headers.get('x-user-id-hash') || 'anonymous';
    return `${ip}:${userIdHash}`;
  }
};

export const POST = withOTel(
  withRateLimit(rateLimitConfig, async (req: NextRequest) => {
    const span = trace.getActiveSpan();
    
    try {
      // 1. Parse and validate request
      const body = await req.json();
      const parseResult = EventsBatchSchema.safeParse(body);
      
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
              message: 'Invalid event batch format',
              details: parseResult.error.errors
            }
          },
          { status: 400 }
        );
      }

      const { events }: EventsBatch = parseResult.data;
      
      // 2. Anonymize user IDs and prepare database records
      const serverSalt = process.env.USER_HASH_SALT;
      if (!serverSalt) {
        throw new Error('USER_HASH_SALT environment variable not set');
      }

      const dbRecords = events.map(event => {
        // Hash user ID for privacy (not reversible)
        const userIdHash = createHash('sha256')
          .update(event.props.userId + serverSalt)
          .digest('hex')
          .substring(0, 16); // Truncate for performance

        // Derive cohort from hash for analytics grouping
        const cohort = `cohort_${parseInt(userIdHash.substring(0, 2), 16) % 10}`;

        return {
          userId: event.props.userId, // Keep for relation, but hashed in props
          ts: new Date(event.ts || Date.now()),
          kind: event.kind.toUpperCase(),
          props: {
            ...event.props,
            userId: userIdHash, // Replace with hashed version
            // Remove any potential PII
            email: undefined,
            name: undefined,
            phone: undefined,
          },
          schema: event.schema || 'v1',
          cohort,
        };
      });

      // 3. Batch insert to database
      await db.event.createMany({
        data: dbRecords,
        skipDuplicates: true, // Prevent duplicate events
      });

      // 4. Set OTel attributes for observability
      span?.setAttributes({
        'api.route': 'events_batch',
        'batch.size': events.length,
        'batch.cohorts': [...new Set(dbRecords.map(r => r.cohort))].length,
        'batch.event_types': [...new Set(events.map(e => e.kind))].length,
      });

      // 5. Return success response
      return NextResponse.json({
        success: true,
        data: {
          processed: events.length,
          cohorts: [...new Set(dbRecords.map(r => r.cohort))],
        },
        message: `Successfully processed ${events.length} events`
      });

    } catch (error) {
      // Log error with OTel
      span?.setAttributes({
        'api.error': 'processing_failed',
        'api.error.message': error instanceof Error ? error.message : 'Unknown error'
      });

      console.error('Events batch processing failed:', error);

      return NextResponse.json(
        {
          success: false,
          error: {
            code: 'PROCESSING_ERROR',
            message: 'Failed to process event batch',
            details: process.env.NODE_ENV === 'development' 
              ? error instanceof Error ? error.message : 'Unknown error'
              : undefined
          }
        },
        { status: 500 }
      );
    }
  })
);

// Handle preflight requests for CORS
export const OPTIONS = async () => {
  return new NextResponse(null, {
    status: 200,
    headers: {
      'Access-Control-Allow-Origin': process.env.ALLOWED_ORIGIN || '*',
      'Access-Control-Allow-Methods': 'POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, x-user-id-hash',
      'Access-Control-Max-Age': '86400', // 24 hours
    },
  });
};

// Export config for Edge Runtime
export const config = {
  runtime: 'edge',
  regions: ['iad1', 'sfo1', 'lhr1', 'sin1'], // Global edge locations
};
