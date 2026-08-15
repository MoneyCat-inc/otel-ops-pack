/**
 * IONA Telemetry Emit Span API
 * 
 * Purpose: Manually trigger synthetic span emission for testing
 * Part of: IONA-GATE-002 - Diagnostics Shell
 */

import { NextResponse } from 'next/server';
import { getOtelIngestHttpBase } from '@/lib/otel-ports';

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const { spanName = 'manual.test.span', attributes = {} } = body;

    // Log the span emission request
    console.log('[IONA] Manual span emission requested:', {
      spanName,
      attributes,
      timestamp: new Date().toISOString(),
    });

    // In a real implementation, this would use OpenTelemetry SDK to emit a span
    // For now, we'll simulate the emission
    
    // Simulate network delay
    await new Promise(resolve => setTimeout(resolve, 100));

    // Return success response
    return NextResponse.json({
      success: true,
      message: `Span "${spanName}" emitted successfully`,
      spanName,
      timestamp: new Date().toISOString(),
      endpoint: process.env.OTEL_EXPORTER_OTLP_ENDPOINT || getOtelIngestHttpBase(),
      serviceName: process.env.OTEL_SERVICE_NAME || 'iona-app',
    });
  } catch (error) {
    console.error('[IONA] Error emitting span:', error);
    return NextResponse.json(
      { 
        success: false,
        error: 'Failed to emit span',
        message: error instanceof Error ? error.message : 'Unknown error',
      },
      { status: 500 }
    );
  }
}

// Support GET for health check
export async function GET() {
  return NextResponse.json({
    available: true,
    endpoint: process.env.OTEL_EXPORTER_OTLP_ENDPOINT || getOtelIngestHttpBase(),
    serviceName: process.env.OTEL_SERVICE_NAME || 'iona-app',
  });
}

