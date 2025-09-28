// Resonai Backend - Rate Limiting Middleware
// Implements token bucket rate limiting for API endpoints

import { NextRequest, NextResponse } from 'next/server';

// Rate limit configuration
interface RateLimitConfig {
  requests: number;
  windowMs: number;
  keyGenerator: (req: NextRequest) => string;
  message?: string;
  skipSuccessfulRequests?: boolean;
  skipFailedRequests?: boolean;
}

// In-memory store for rate limiting (use Redis in production)
const rateLimitStore = new Map<string, { count: number; resetTime: number }>();

// Clean up expired entries periodically
setInterval(() => {
  const now = Date.now();
  for (const [key, value] of rateLimitStore.entries()) {
    if (value.resetTime < now) {
      rateLimitStore.delete(key);
    }
  }
}, 60000); // Clean up every minute

// Rate limiting middleware
export function withRateLimit(
  config: RateLimitConfig,
  handler: (req: NextRequest) => Promise<NextResponse>
) {
  return async (req: NextRequest): Promise<NextResponse> => {
    const key = config.keyGenerator(req);
    const now = Date.now();
    const windowStart = now - config.windowMs;

    // Get or create rate limit entry
    let entry = rateLimitStore.get(key);
    if (!entry || entry.resetTime < now) {
      entry = {
        count: 0,
        resetTime: now + config.windowMs,
      };
      rateLimitStore.set(key, entry);
    }

    // Check if limit exceeded
    if (entry.count >= config.requests) {
      const retryAfter = Math.ceil((entry.resetTime - now) / 1000);
      
      return NextResponse.json(
        {
          success: false,
          error: {
            code: 'RATE_LIMIT_EXCEEDED',
            message: config.message || 'Too many requests',
            details: {
              limit: config.requests,
              windowMs: config.windowMs,
              retryAfter,
            }
          }
        },
        {
          status: 429,
          headers: {
            'Retry-After': retryAfter.toString(),
            'X-RateLimit-Limit': config.requests.toString(),
            'X-RateLimit-Remaining': Math.max(0, config.requests - entry.count - 1).toString(),
            'X-RateLimit-Reset': new Date(entry.resetTime).toISOString(),
          }
        }
      );
    }

    // Increment counter
    entry.count++;

    try {
      // Execute the handler
      const response = await handler(req);

      // Add rate limit headers to response
      response.headers.set('X-RateLimit-Limit', config.requests.toString());
      response.headers.set('X-RateLimit-Remaining', Math.max(0, config.requests - entry.count).toString());
      response.headers.set('X-RateLimit-Reset', new Date(entry.resetTime).toISOString());

      return response;

    } catch (error) {
      // On error, still increment counter unless configured otherwise
      if (!config.skipFailedRequests) {
        entry.count++;
      }
      throw error;
    }
  };
}

// Predefined rate limit configurations
export const rateLimitConfigs = {
  // Strict limits for sensitive operations
  auth: {
    requests: 5,
    windowMs: 15 * 60 * 1000, // 15 minutes
    keyGenerator: (req: NextRequest) => {
      const ip = req.ip || req.headers.get('x-forwarded-for') || 'unknown';
      return `auth:${ip}`;
    },
    message: 'Too many authentication attempts',
  },

  // Moderate limits for user actions
  user: {
    requests: 100,
    windowMs: 15 * 60 * 1000, // 15 minutes
    keyGenerator: (req: NextRequest) => {
      const ip = req.ip || req.headers.get('x-forwarded-for') || 'unknown';
      const userId = req.headers.get('x-user-id') || 'anonymous';
      return `user:${ip}:${userId}`;
    },
    message: 'Too many user requests',
  },

  // Lenient limits for analytics events
  events: {
    requests: 1000,
    windowMs: 60 * 1000, // 1 minute
    keyGenerator: (req: NextRequest) => {
      const ip = req.ip || req.headers.get('x-forwarded-for') || 'unknown';
      const userIdHash = req.headers.get('x-user-id-hash') || 'anonymous';
      return `events:${ip}:${userIdHash}`;
    },
    message: 'Too many events submitted',
  },

  // Very strict limits for feedback/reports
  feedback: {
    requests: 10,
    windowMs: 60 * 60 * 1000, // 1 hour
    keyGenerator: (req: NextRequest) => {
      const ip = req.ip || req.headers.get('x-forwarded-for') || 'unknown';
      return `feedback:${ip}`;
    },
    message: 'Too many feedback submissions',
  },

  // Global IP-based limits
  global: {
    requests: 1000,
    windowMs: 60 * 1000, // 1 minute
    keyGenerator: (req: NextRequest) => {
      const ip = req.ip || req.headers.get('x-forwarded-for') || 'unknown';
      return `global:${ip}`;
    },
    message: 'Global rate limit exceeded',
  },
};

// Utility function to check rate limit without applying it
export function checkRateLimit(
  req: NextRequest,
  config: RateLimitConfig
): { allowed: boolean; remaining: number; resetTime: number } {
  const key = config.keyGenerator(req);
  const now = Date.now();
  
  let entry = rateLimitStore.get(key);
  if (!entry || entry.resetTime < now) {
    return {
      allowed: true,
      remaining: config.requests,
      resetTime: now + config.windowMs,
    };
  }

  return {
    allowed: entry.count < config.requests,
    remaining: Math.max(0, config.requests - entry.count),
    resetTime: entry.resetTime,
  };
}
