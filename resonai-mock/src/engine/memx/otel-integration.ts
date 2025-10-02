/**
 * MEMX OTel Integration
 * 
 * Integrates MEMX memory monitoring with OpenTelemetry metrics
 * Provides snapshot callbacks for real-time observability
 */

import { initMemxOtel, MemxOtelHandle, MemxSnapshots } from './otel';
import { getMemxStore } from './store';
import { MemxConfig } from './types';

// Global OTel handle
let memxOtelHandle: MemxOtelHandle | null = null;

/**
 * Initialize MEMX OTel instrumentation with snapshot callbacks
 */
export function initMemxOtelIntegration(config: MemxConfig): MemxOtelHandle | null {
  // Only initialize if MEMX is enabled and streaming is configured
  if (!config.enabled || !config.streamDefault || !config.otlpEndpoint) {
    console.log('MEMX OTel: Disabled or not configured for streaming');
    return null;
  }

  // Create snapshot callbacks that read from the MEMX store
  const snapshots: MemxSnapshots = {
    wasmHeapBytes: () => {
      const store = getMemxStore();
      const aggregates = store.getSessionAggregates();
      return aggregates.peakWasmHeapBytes;
    },

    sabUsage: () => {
      const store = getMemxStore();
      // Prefer most recent concrete bytes from frames to satisfy bytes-based gauges
      const recent = store.getRecentFrames(60000); // last 60s
      for (let i = recent.length - 1; i >= 0; i--) {
        const f = recent[i];
        if (typeof f.sabUsedBytes === 'number') {
          return {
            used: f.sabUsedBytes,
            capacity: typeof f.sabCapacityBytes === 'number' ? f.sabCapacityBytes : undefined,
            ring: 'worklet_io',
          };
        }
      }
      return undefined;
    },

    strainPct: () => {
      const store = getMemxStore();
      const aggregates = store.getSessionAggregates();
      
      if (aggregates.memoryStrainPct !== undefined) {
        return {
          value: aggregates.memoryStrainPct,
          kind: 'memory_strain'
        };
      }
      return undefined;
    }
  };

  // Initialize OTel with streaming enabled
  memxOtelHandle = initMemxOtel({
    endpoint: config.otlpEndpoint,
    stream: true,
    exportIntervalMillis: config.exportIntervalMs,
    resourceAttributes: {
      'service.name': 'resonai-frontend',
      'service.version': '1.0.0',
      'telemetry.sdk.language': 'webjs',
      'telemetry.sdk.name': 'memx-otel',
      'component': 'memx'
    },
    snapshots
  });

  console.log('MEMX OTel: Initialized with streaming to', config.otlpEndpoint);
  return memxOtelHandle;
}

/**
 * Record UI-to-AudioWorklet lag measurement
 */
export function recordMemxLag(durationMs: number, attributes?: Record<string, string>): void {
  if (memxOtelHandle) {
    memxOtelHandle.recordLag(durationMs, attributes);
  }
}

/**
 * Get current MEMX OTel handle
 */
export function getMemxOtelHandle(): MemxOtelHandle | null {
  return memxOtelHandle;
}

/**
 * Shutdown MEMX OTel instrumentation
 */
export async function shutdownMemxOtel(): Promise<void> {
  if (memxOtelHandle) {
    await memxOtelHandle.shutdown();
    memxOtelHandle = null;
    console.log('MEMX OTel: Shutdown complete');
  }
}

/**
 * Check if MEMX OTel is active
 */
export function isMemxOtelActive(): boolean {
  return memxOtelHandle !== null;
}
