/**
 * IONA Telemetry Traces API
 * 
 * Purpose: Return mock/recent trace data for diagnostics
 * Part of: IONA-GATE-002 - Diagnostics Shell
 * 
 * Note: In production, this would query SigNoz API for real trace data
 */

import { NextResponse } from 'next/server';

// Mock trace data for demonstration
function generateMockTraces(count: number = 5) {
  const traces = [];
  const now = Date.now();

  for (let i = 0; i < count; i++) {
    const traceId = Math.random().toString(16).substring(2, 34);
    const spanId = Math.random().toString(16).substring(2, 18);
    const timestamp = new Date(now - (i * 60000)).toISOString(); // 1 minute intervals

    traces.push({
      traceId,
      spanId,
      name: i === 0 ? 'iona.boot' : `iona.operation.${i}`,
      duration: Math.random() * 100 + 10,
      timestamp,
      attributes: {
        'service.name': 'iona-app',
        'iona.gate': 'bosscat',
        'test.type': 'synthetic',
      },
    });
  }

  return traces;
}

export async function GET() {
  try {
    // In production, query SigNoz API:
    // const response = await fetch('http://localhost:8080/api/v2/traces', {
    //   headers: { 'Authorization': 'Bearer ...' }
    // });
    
    const traces = generateMockTraces(10);

    return NextResponse.json({
      traces,
      summary: {
        total: traces.length,
        lastUpdate: new Date().toISOString(),
      },
    });
  } catch (error) {
    console.error('[IONA] Error fetching traces:', error);
    return NextResponse.json(
      { error: 'Failed to fetch traces' },
      { status: 500 }
    );
  }
}

