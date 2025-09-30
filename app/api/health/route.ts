// Resonai Backend - Health Check API Route
// Provides system health status and environment validation

import { NextRequest, NextResponse } from 'next/server';
import { trace } from '@opentelemetry/api';
import { checkDatabaseHealth, getDatabaseStats } from '@/lib/db';
import { withOTel } from '@/lib/middleware/otel';

// GET /api/health - Basic health check
export const GET = withOTel(async (req: NextRequest) => {
  const span = trace.getActiveSpan();
  
  try {
    const startTime = Date.now();
    
    // Check database health
    const dbHealth = await checkDatabaseHealth();
    
    // Check OTel endpoint
    const otelHealth = await checkOTelHealth();
    
    // Check environment variables
    const envHealth = checkEnvironmentHealth();
    
    const responseTime = Date.now() - startTime;
    
    // Determine overall health
    const isHealthy = dbHealth.status === 'healthy' && 
                     otelHealth.status === 'healthy' && 
                     envHealth.status === 'healthy';
    
    const statusCode = isHealthy ? 200 : 503;
    
    span?.setAttributes({
      'health.check_success': isHealthy,
      'health.response_time_ms': responseTime,
      'health.db_status': dbHealth.status,
      'health.otel_status': otelHealth.status,
      'health.env_status': envHealth.status,
    });

    return NextResponse.json({
      status: isHealthy ? 'healthy' : 'unhealthy',
      timestamp: new Date().toISOString(),
      responseTime: `${responseTime}ms`,
      services: {
        database: {
          status: dbHealth.status,
          latency: dbHealth.latency,
          error: dbHealth.error,
        },
        otel: {
          status: otelHealth.status,
          endpoint: process.env.OTEL_EXPORTER_OTLP_ENDPOINT,
          error: otelHealth.error,
        },
        environment: {
          status: envHealth.status,
          missing: envHealth.missing,
        },
      },
      environment: {
        nodeEnv: process.env.NODE_ENV,
        version: process.env.OTEL_SERVICE_VERSION || '1.0.0',
        service: process.env.OTEL_SERVICE_NAME || 'resonai-backend',
      },
    }, { status: statusCode });

  } catch (error) {
    span?.setAttributes({
      'health.check_error': true,
      'health.error.message': error instanceof Error ? error.message : 'Unknown error'
    });

    console.error('Health check failed:', error);

    return NextResponse.json({
      status: 'unhealthy',
      timestamp: new Date().toISOString(),
      error: {
        code: 'HEALTH_CHECK_ERROR',
        message: 'Health check failed',
        details: process.env.NODE_ENV === 'development' 
          ? error instanceof Error ? error.message : 'Unknown error'
          : undefined
      },
    }, { status: 503 });
  }
});

// GET /api/health/detailed - Detailed health check with more information
export const detailed = withOTel(async (req: NextRequest) => {
  const span = trace.getActiveSpan();
  
  try {
    const startTime = Date.now();
    
    // Comprehensive health checks
    const [dbHealth, dbStats, otelHealth, envHealth] = await Promise.all([
      checkDatabaseHealth(),
      getDatabaseStats(),
      checkOTelHealth(),
      Promise.resolve(checkEnvironmentHealth()),
    ]);
    
    const responseTime = Date.now() - startTime;
    
    // Determine overall health
    const isHealthy = dbHealth.status === 'healthy' && 
                     otelHealth.status === 'healthy' && 
                     envHealth.status === 'healthy';
    
    const statusCode = isHealthy ? 200 : 503;
    
    span?.setAttributes({
      'health.detailed_check_success': isHealthy,
      'health.response_time_ms': responseTime,
      'health.db_connections': dbStats.totalConnections,
    });

    return NextResponse.json({
      status: isHealthy ? 'healthy' : 'unhealthy',
      timestamp: new Date().toISOString(),
      responseTime: `${responseTime}ms`,
      services: {
        database: {
          status: dbHealth.status,
          latency: dbHealth.latency,
          error: dbHealth.error,
          connections: {
            active: dbStats.activeConnections,
            idle: dbStats.idleConnections,
            total: dbStats.totalConnections,
          },
        },
        otel: {
          status: otelHealth.status,
          endpoint: process.env.OTEL_EXPORTER_OTLP_ENDPOINT,
          serviceName: process.env.OTEL_SERVICE_NAME,
          environment: process.env.OTEL_ENVIRONMENT,
          error: otelHealth.error,
        },
        environment: {
          status: envHealth.status,
          missing: envHealth.missing,
          features: {
            magicLinkAuth: process.env.FEATURE_MAGIC_LINK_AUTH === 'true',
            passkeyAuth: process.env.FEATURE_PASSKEY_AUTH === 'true',
            coachPortal: process.env.FEATURE_COACH_PORTAL === 'true',
            storyProgress: process.env.FEATURE_STORY_PROGRESS === 'true',
            feedbackSystem: process.env.FEATURE_FEEDBACK_SYSTEM === 'true',
          },
        },
      },
      system: {
        nodeVersion: process.version,
        platform: process.platform,
        arch: process.arch,
        uptime: process.uptime(),
        memory: {
          used: Math.round(process.memoryUsage().heapUsed / 1024 / 1024),
          total: Math.round(process.memoryUsage().heapTotal / 1024 / 1024),
          external: Math.round(process.memoryUsage().external / 1024 / 1024),
        },
      },
      environment: {
        nodeEnv: process.env.NODE_ENV,
        version: process.env.OTEL_SERVICE_VERSION || '1.0.0',
        service: process.env.OTEL_SERVICE_NAME || 'resonai-backend',
        region: process.env.VERCEL_REGION || 'local',
      },
    }, { status: statusCode });

  } catch (error) {
    span?.setAttributes({
      'health.detailed_check_error': true,
      'health.error.message': error instanceof Error ? error.message : 'Unknown error'
    });

    console.error('Detailed health check failed:', error);

    return NextResponse.json({
      status: 'unhealthy',
      timestamp: new Date().toISOString(),
      error: {
        code: 'DETAILED_HEALTH_CHECK_ERROR',
        message: 'Detailed health check failed',
        details: process.env.NODE_ENV === 'development' 
          ? error instanceof Error ? error.message : 'Unknown error'
          : undefined
      },
    }, { status: 503 });
  }
});

// Helper function to check OTel endpoint health
async function checkOTelHealth(): Promise<{
  status: 'healthy' | 'unhealthy';
  error?: string;
}> {
  const span = trace.getActiveSpan();
  
  try {
    const otelEndpoint = process.env.OTEL_EXPORTER_OTLP_ENDPOINT;
    
    if (!otelEndpoint) {
      return {
        status: 'unhealthy',
        error: 'OTEL_EXPORTER_OTLP_ENDPOINT not configured'
      };
    }

    // Try to reach the OTel endpoint
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 5000); // 5 second timeout

    try {
      const response = await fetch(`${otelEndpoint}/v1/traces`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ resourceSpans: [] }), // Empty trace for health check
        signal: controller.signal,
      });

      clearTimeout(timeoutId);

      if (response.ok || response.status === 400) { // 400 is OK for empty trace
        span?.setAttributes({
          'otel.health_check': 'success',
          'otel.endpoint': otelEndpoint,
        });

        return { status: 'healthy' };
      } else {
        return {
          status: 'unhealthy',
          error: `OTel endpoint returned ${response.status}`
        };
      }

    } catch (fetchError) {
      clearTimeout(timeoutId);
      throw fetchError;
    }

  } catch (error) {
    span?.setAttributes({
      'otel.health_check': 'failed',
      'otel.error': error instanceof Error ? error.message : 'Unknown error'
    });

    return {
      status: 'unhealthy',
      error: error instanceof Error ? error.message : 'Unknown OTel error'
    };
  }
}

// Helper function to check environment variables
function checkEnvironmentHealth(): {
  status: 'healthy' | 'unhealthy';
  missing: string[];
} {
  const requiredEnvVars = [
    'DATABASE_URL',
    'NEXTAUTH_SECRET',
    'NEXTAUTH_URL',
    'USER_HASH_SALT',
    'ALLOWED_ORIGIN',
    'OTEL_EXPORTER_OTLP_ENDPOINT',
  ];

  const missing = requiredEnvVars.filter(key => !process.env[key]);

  return {
    status: missing.length === 0 ? 'healthy' : 'unhealthy',
    missing,
  };
}

// Export config for Edge Runtime
export const runtime = 'edge';

