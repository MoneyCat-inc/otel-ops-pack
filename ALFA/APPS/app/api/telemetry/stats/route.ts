/**
 * IONA Telemetry Stats API
 * 
 * Purpose: Return aggregate telemetry statistics
 * Part of: IONA-GATE-002 - Diagnostics Shell
 */

import { NextResponse } from 'next/server';

export async function GET() {
  try {
    const stats = {
      system: {
        uptime: process.uptime(),
        memory: {
          used: process.memoryUsage().heapUsed,
          total: process.memoryUsage().heapTotal,
          external: process.memoryUsage().external,
        },
        platform: process.platform,
        nodeVersion: process.version,
      },
      telemetry: {
        enabled: true,
        endpoint: process.env.OTEL_EXPORTER_OTLP_ENDPOINT || 'http://127.0.0.1:5318',
        serviceName: process.env.OTEL_SERVICE_NAME || 'iona-app',
        protocol: 'http/protobuf',
      },
      timestamp: new Date().toISOString(),
    };

    return NextResponse.json(stats);
  } catch (error) {
    console.error('[IONA] Error fetching telemetry stats:', error);
    return NextResponse.json(
      { error: 'Failed to fetch telemetry stats' },
      { status: 500 }
    );
  }
}

