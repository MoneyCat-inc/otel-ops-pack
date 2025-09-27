/**
 * MEMX Store - In-memory ring buffer + IndexedDB session roll-up
 * 
 * PR-1: Schema & storage - extend session schema with memory aggregates
 * Keeps per-frame data local only; exports only on demand
 */

import { MemxFrame, MemxSession, MemxStrainThresholds } from './types';

export class MemxStore {
  private frames: MemxFrame[] = [];
  private maxFrames = 7200; // 2 minutes at 60fps
  private sessionAggregates: Partial<MemxSession> = {};
  private thresholds: MemxStrainThresholds;
  private strainEvents: Array<{ type: string; value: number; timestamp: number }> = [];

  constructor(thresholds?: Partial<MemxStrainThresholds>) {
    this.thresholds = {
      sabBacklogPct: 80,
      wasmGrowThreshold: 10 * 1024 * 1024,
      workletLagP95Ms: 50,
      gpuUtilPct: 90,
      ...thresholds,
    };
  }

  /**
   * Add a new frame to the ring buffer
   */
  addFrame(frame: MemxFrame): void {
    this.frames.push(frame);
    
    // Maintain ring buffer size
    if (this.frames.length > this.maxFrames) {
      this.frames.shift();
    }

    // Update session aggregates
    this.updateAggregates(frame);
    
    // Check for strain events
    this.checkStrainEvents(frame);
  }

  /**
   * Update rolling aggregates (O(1) operations)
   */
  private updateAggregates(frame: MemxFrame): void {
    const { sessionAggregates } = this;
    
    // Peak WASM heap
    if (frame.wasmHeapBytes !== undefined) {
      sessionAggregates.peakWasmHeapBytes = Math.max(
        sessionAggregates.peakWasmHeapBytes || 0,
        frame.wasmHeapBytes
      );
    }

    // Peak SAB usage percentage
    if (frame.sabUsedBytes !== undefined && frame.sabCapacityBytes !== undefined) {
      const usagePct = (frame.sabUsedBytes / frame.sabCapacityBytes) * 100;
      sessionAggregates.peakSabUsagePct = Math.max(
        sessionAggregates.peakSabUsagePct || 0,
        usagePct
      );
    }

    // Worklet lag statistics (simplified - would need proper P95 calculation)
    if (frame.workletLagMs !== undefined) {
      const currentAvg = sessionAggregates.avgWorkletLagMs || 0;
      const frameCount = sessionAggregates.frameCount || 0;
      sessionAggregates.avgWorkletLagMs = (currentAvg * frameCount + frame.workletLagMs) / (frameCount + 1);
      sessionAggregates.p95WorkletLagMs = Math.max(
        sessionAggregates.p95WorkletLagMs || 0,
        frame.workletLagMs
      );
    }

    // Memory strain percentage (simplified calculation)
    sessionAggregates.memoryStrainPct = this.calculateStrainPct();
    
    // Frame count and duration
    sessionAggregates.frameCount = (sessionAggregates.frameCount || 0) + 1;
    if (this.frames.length > 1) {
      sessionAggregates.sessionDurationMs = frame.ts - this.frames[0].ts;
    }
  }

  /**
   * Check for strain threshold crossings
   */
  private checkStrainEvents(frame: MemxFrame): void {
    const { flags } = frame;
    if (!flags) return;

    // SAB backlog
    if (flags.sabBacklog && frame.sabUsedBytes && frame.sabCapacityBytes) {
      const usagePct = (frame.sabUsedBytes / frame.sabCapacityBytes) * 100;
      if (usagePct > this.thresholds.sabBacklogPct) {
        this.strainEvents.push({
          type: 'SAB_BACKLOG',
          value: usagePct,
          timestamp: frame.ts,
        });
      }
    }

    // WASM growth
    if (flags.wasmGrow && frame.wasmHeapBytes) {
      if (frame.wasmHeapBytes > this.thresholds.wasmGrowThreshold) {
        this.strainEvents.push({
          type: 'WASM_GROW',
          value: frame.wasmHeapBytes,
          timestamp: frame.ts,
        });
      }
    }

    // Worklet lag
    if (frame.workletLagMs && frame.workletLagMs > this.thresholds.workletLagP95Ms) {
      this.strainEvents.push({
        type: 'WORKLET_LAG',
        value: frame.workletLagMs,
        timestamp: frame.ts,
      });
    }

    // GPU strain
    if (flags.gpuStrain && frame.gpuUtilPct) {
      if (frame.gpuUtilPct > this.thresholds.gpuUtilPct) {
        this.strainEvents.push({
          type: 'GPU_STRAIN',
          value: frame.gpuUtilPct,
          timestamp: frame.ts,
        });
      }
    }
  }

  /**
   * Calculate memory strain percentage (0-100)
   */
  private calculateStrainPct(): number {
    let strainScore = 0;
    let factorCount = 0;

    // SAB usage factor
    const sabUsage = this.sessionAggregates.peakSabUsagePct || 0;
    if (sabUsage > 0) {
      strainScore += Math.min(sabUsage / this.thresholds.sabBacklogPct, 1) * 25;
      factorCount++;
    }

    // WASM heap factor
    const wasmPeak = this.sessionAggregates.peakWasmHeapBytes || 0;
    if (wasmPeak > 0) {
      strainScore += Math.min(wasmPeak / this.thresholds.wasmGrowThreshold, 1) * 25;
      factorCount++;
    }

    // Worklet lag factor
    const avgLag = this.sessionAggregates.avgWorkletLagMs || 0;
    if (avgLag > 0) {
      strainScore += Math.min(avgLag / this.thresholds.workletLagP95Ms, 1) * 25;
      factorCount++;
    }

    // GPU factor (if available)
    // Note: GPU data would come from host taps in PR-5

    return factorCount > 0 ? Math.min((strainScore / factorCount) * 100, 100) : 0;
  }

  /**
   * Get current session aggregates
   */
  getSessionAggregates(): MemxSession {
    return { ...this.sessionAggregates };
  }

  /**
   * Get recent frames for export (last N seconds)
   */
  getRecentFrames(durationMs: number = 120000): MemxFrame[] {
    const cutoff = Date.now() - durationMs;
    return this.frames.filter(frame => frame.ts >= cutoff);
  }

  /**
   * Get strain events for export
   */
  getStrainEvents(): Array<{ type: string; value: number; timestamp: number }> {
    return [...this.strainEvents];
  }

  /**
   * Clear strain events (after export)
   */
  clearStrainEvents(): void {
    this.strainEvents = [];
  }

  /**
   * Reset session data
   */
  reset(): void {
    this.frames = [];
    this.sessionAggregates = {};
    this.strainEvents = [];
  }
}

// Singleton instance
let memxStore: MemxStore | null = null;

export function getMemxStore(): MemxStore {
  if (!memxStore) {
    memxStore = new MemxStore();
  }
  return memxStore;
}
