/**
 * MEMX (Memory Observation Layer) Types
 * 
 * PR-0: Feature flag scaffolding with off-by-default toggles
 * PR-1: Schema & storage - extend session schema with memory aggregates
 */

// Feature flag types
export type MemxConfig = {
  enabled: boolean;
  otlpEndpoint?: string;
  streamDefault: boolean;
  exportIntervalMs: number;
};

// Frame-level memory data (kept local only)
export type MemxFrame = {
  ts: number;
  wasmHeapBytes?: number;
  sabUsedBytes?: number;
  sabCapacityBytes?: number;
  workletLagMs?: number;
  gpuUtilPct?: number | null;
  flags?: {
    sabBacklog?: boolean;
    wasmGrow?: boolean;
    sysMem?: boolean;
    gpuStrain?: boolean;
  };
};

// Session roll-up aggregates (stored in IndexedDB)
export type MemxSession = {
  peakWasmHeapBytes?: number;
  peakSabUsagePct?: number;
  avgWorkletLagMs?: number;
  p95WorkletLagMs?: number;
  memoryStrainPct?: number;
  frameCount?: number;
  sessionDurationMs?: number;
};

// Strain threshold configuration
export type MemxStrainThresholds = {
  sabBacklogPct: number;      // Default: 80%
  wasmGrowThreshold: number;  // Default: 10MB
  workletLagP95Ms: number;    // Default: 50ms
  gpuUtilPct: number;         // Default: 90%
};

// OTLP export types
export type MemxMetric = {
  name: string;
  value: number;
  timestamp: number;
  labels?: Record<string, string>;
};

export type MemxLogEvent = {
  type: 'SAB_BACKLOG' | 'WASM_GROW' | 'SYS_MEM' | 'GPU';
  value: number;
  threshold: number;
  timestamp: number;
  message: string;
};

// Default configuration
export const DEFAULT_MEMX_CONFIG: MemxConfig = {
  enabled: false,
  streamDefault: false,
  exportIntervalMs: 5000,
};

export const DEFAULT_STRAIN_THRESHOLDS: MemxStrainThresholds = {
  sabBacklogPct: 80,
  wasmGrowThreshold: 10 * 1024 * 1024, // 10MB
  workletLagP95Ms: 50,
  gpuUtilPct: 90,
};
