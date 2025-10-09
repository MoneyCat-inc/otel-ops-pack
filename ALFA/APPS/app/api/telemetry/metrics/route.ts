/**
 * IONA Telemetry Metrics API
 * 
 * Purpose: Return current system and application metrics
 * Part of: IONA-GATE-002 - Diagnostics Shell
 */

import { NextResponse } from 'next/server';

export async function GET() {
  try {
    const memUsage = process.memoryUsage();
    const now = new Date().toISOString();

    const metrics = [
      {
        name: 'system.uptime',
        value: Math.floor(process.uptime()),
        unit: 's',
        timestamp: now,
      },
      {
        name: 'memory.heap.used',
        value: Math.floor(memUsage.heapUsed / 1024 / 1024),
        unit: 'MB',
        timestamp: now,
      },
      {
        name: 'memory.heap.total',
        value: Math.floor(memUsage.heapTotal / 1024 / 1024),
        unit: 'MB',
        timestamp: now,
      },
      {
        name: 'memory.external',
        value: Math.floor(memUsage.external / 1024 / 1024),
        unit: 'MB',
        timestamp: now,
      },
      {
        name: 'memory.rss',
        value: Math.floor(memUsage.rss / 1024 / 1024),
        unit: 'MB',
        timestamp: now,
      },
    ];

    // Add CPU usage if available (Node.js 19+)
    if (typeof process.cpuUsage === 'function') {
      const cpuUsage = process.cpuUsage();
      metrics.push({
        name: 'cpu.user',
        value: Math.floor(cpuUsage.user / 1000),
        unit: 'ms',
        timestamp: now,
      });
      metrics.push({
        name: 'cpu.system',
        value: Math.floor(cpuUsage.system / 1000),
        unit: 'ms',
        timestamp: now,
      });
    }

    return NextResponse.json({
      metrics,
      summary: {
        total: metrics.length,
        lastUpdate: now,
      },
    });
  } catch (error) {
    console.error('[IONA] Error fetching metrics:', error);
    return NextResponse.json(
      { error: 'Failed to fetch metrics' },
      { status: 500 }
    );
  }
}

