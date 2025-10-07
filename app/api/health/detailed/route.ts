import { NextRequest, NextResponse } from 'next/server';
import { trace } from '@opentelemetry/api';
import { checkDatabaseHealth, getDatabaseStats } from '@/lib/db';
import { withOTel } from '@/lib/middleware/otel';
import { checkEnvironmentHealth, checkOTelHealth } from '../utils';

export const runtime = 'nodejs';

export const GET = withOTel(async (_req: NextRequest) => {
  const span = trace.getActiveSpan();

  try {
    const startTime = Date.now();

    const [dbHealth, dbStats, otelHealth, envHealth] = await Promise.all([
      checkDatabaseHealth(),
      getDatabaseStats(),
      checkOTelHealth(),
      Promise.resolve(checkEnvironmentHealth()),
    ]);

    const responseTime = Date.now() - startTime;
    const isHealthy = dbHealth.status === 'healthy'
      && otelHealth.status === 'healthy'
      && envHealth.status === 'healthy';

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
          endpoint: process.env['OTEL_EXPORTER_OTLP_ENDPOINT'],
          serviceName: process.env['OTEL_SERVICE_NAME'],
          environment: process.env['OTEL_ENVIRONMENT'],
          error: otelHealth.error,
        },
        environment: {
          status: envHealth.status,
          missing: envHealth.missing,
          features: {
            magicLinkAuth: process.env['FEATURE_MAGIC_LINK_AUTH'] === 'true',
            passkeyAuth: process.env['FEATURE_PASSKEY_AUTH'] === 'true',
            coachPortal: process.env['FEATURE_COACH_PORTAL'] === 'true',
            storyProgress: process.env['FEATURE_STORY_PROGRESS'] === 'true',
            feedbackSystem: process.env['FEATURE_FEEDBACK_SYSTEM'] === 'true',
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
        nodeEnv: process.env['NODE_ENV'],
        version: process.env['OTEL_SERVICE_VERSION'] || '1.0.0',
        service: process.env['OTEL_SERVICE_NAME'] || 'resonai-backend',
        region: process.env['VERCEL_REGION'] || 'local',
      },
    }, { status: statusCode });
  } catch (error) {
    span?.setAttributes({
      'health.detailed_check_error': true,
      'health.error.message': error instanceof Error ? error.message : 'Unknown error',
    });

    console.error('Detailed health check failed:', error);

    return NextResponse.json({
      status: 'unhealthy',
      timestamp: new Date().toISOString(),
      error: {
        code: 'DETAILED_HEALTH_CHECK_ERROR',
        message: 'Detailed health check failed',
        details: process.env['NODE_ENV'] === 'development'
          ? (error instanceof Error ? error.message : 'Unknown error')
          : undefined,
      },
    }, { status: 503 });
  }
});
