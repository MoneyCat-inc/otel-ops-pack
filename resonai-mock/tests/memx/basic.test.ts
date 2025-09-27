/**
 * Basic MEMX Tests
 * 
 * PR-1: Simple tests for core functionality
 */

import { describe, it, expect } from 'vitest';
import { MemxFrame, MemxSession } from '../../src/engine/memx/types';
import { MemxStore } from '../../src/engine/memx/store';

describe('MEMX Core Types', () => {
  it('should create valid MemxFrame', () => {
    const frame: MemxFrame = {
      ts: Date.now(),
      wasmHeapBytes: 1024 * 1024,
      sabUsedBytes: 512,
      sabCapacityBytes: 1024,
      workletLagMs: 10,
      flags: {
        sabBacklog: false,
        wasmGrow: true,
      },
    };

    expect(frame.ts).toBeGreaterThan(0);
    expect(frame.wasmHeapBytes).toBe(1024 * 1024);
    expect(frame.sabUsedBytes).toBe(512);
    expect(frame.sabCapacityBytes).toBe(1024);
    expect(frame.workletLagMs).toBe(10);
    expect(frame.flags?.wasmGrow).toBe(true);
  });

  it('should create valid MemxSession', () => {
    const session: MemxSession = {
      peakWasmHeapBytes: 2048 * 1024,
      peakSabUsagePct: 75,
      avgWorkletLagMs: 15,
      p95WorkletLagMs: 30,
      memoryStrainPct: 40,
      frameCount: 100,
      sessionDurationMs: 60000,
    };

    expect(session.peakWasmHeapBytes).toBe(2048 * 1024);
    expect(session.peakSabUsagePct).toBe(75);
    expect(session.avgWorkletLagMs).toBe(15);
    expect(session.p95WorkletLagMs).toBe(30);
    expect(session.memoryStrainPct).toBe(40);
    expect(session.frameCount).toBe(100);
    expect(session.sessionDurationMs).toBe(60000);
  });
});

describe('MEMX Store', () => {
  let store: MemxStore;

  beforeEach(() => {
    store = new MemxStore();
  });

  it('should add frames to ring buffer', () => {
    const frame1: MemxFrame = {
      ts: Date.now(),
      wasmHeapBytes: 1024 * 1024,
      sabUsedBytes: 512,
      sabCapacityBytes: 1024,
      workletLagMs: 10,
    };

    const frame2: MemxFrame = {
      ts: Date.now() + 1000,
      wasmHeapBytes: 2048 * 1024,
      sabUsedBytes: 800,
      sabCapacityBytes: 1024,
      workletLagMs: 15,
    };

    store.addFrame(frame1);
    store.addFrame(frame2);

    const aggregates = store.getSessionAggregates();
    expect(aggregates.peakWasmHeapBytes).toBe(2048 * 1024);
    expect(aggregates.peakSabUsagePct).toBeCloseTo(78.125, 1); // (800/1024) * 100
    expect(aggregates.frameCount).toBe(2);
  });

  it('should calculate strain percentage', () => {
    // Add frames that should trigger strain
    const highStrainFrame: MemxFrame = {
      ts: Date.now(),
      wasmHeapBytes: 20 * 1024 * 1024, // 20MB (above 10MB threshold)
      sabUsedBytes: 900, // 87.9% usage (above 80% threshold)
      sabCapacityBytes: 1024,
      workletLagMs: 60, // Above 50ms threshold
      flags: {
        sabBacklog: true,
        wasmGrow: true,
      },
    };

    store.addFrame(highStrainFrame);
    
    const aggregates = store.getSessionAggregates();
    expect(aggregates.memoryStrainPct).toBeGreaterThan(0);
    expect(aggregates.memoryStrainPct).toBeLessThanOrEqual(100);
  });

  it('should maintain ring buffer size', () => {
    // Add more frames than the ring buffer capacity
    const maxFrames = 7200;
    
    for (let i = 0; i < maxFrames + 100; i++) {
      store.addFrame({
        ts: Date.now() + i,
        wasmHeapBytes: 1024 * 1024,
      });
    }

    const recentFrames = store.getRecentFrames();
    expect(recentFrames.length).toBeLessThanOrEqual(maxFrames);
  });

  it('should reset session data', () => {
    // Add some data
    store.addFrame({
      ts: Date.now(),
      wasmHeapBytes: 1024 * 1024,
    });

    expect(store.getSessionAggregates().frameCount).toBe(1);

    // Reset
    store.reset();
    
    const aggregates = store.getSessionAggregates();
    expect(aggregates.frameCount).toBeUndefined();
    expect(store.getRecentFrames()).toHaveLength(0);
  });

  it('should detect strain events', () => {
    const strainFrame: MemxFrame = {
      ts: Date.now(),
      wasmHeapBytes: 15 * 1024 * 1024, // Above threshold
      sabUsedBytes: 850, // Above threshold (83%)
      sabCapacityBytes: 1024,
      workletLagMs: 55, // Above threshold
      flags: {
        sabBacklog: true,
        wasmGrow: true,
      },
    };

    store.addFrame(strainFrame);
    
    const strainEvents = store.getStrainEvents();
    expect(strainEvents.length).toBeGreaterThan(0);
    
    // Should have events for SAB backlog, WASM grow, and worklet lag
    const eventTypes = strainEvents.map(e => e.type);
    expect(eventTypes).toContain('SAB_BACKLOG');
    expect(eventTypes).toContain('WASM_GROW');
    expect(eventTypes).toContain('WORKLET_LAG');
  });
});

describe('Export Data Format', () => {
  it('should format export data correctly', () => {
    const exportData = {
      version: '1.0',
      exportedAt: '2024-01-01T00:00:00.000Z',
      duration: 120000,
      frameCount: 100,
      frames: [
        {
          ts: Date.now(),
          wasmHeapBytes: 1024 * 1024,
          sabUsedBytes: 512,
          sabCapacityBytes: 1024,
          workletLagMs: 10,
        },
      ],
      session: {
        peakWasmHeapBytes: 1024 * 1024,
        peakSabUsagePct: 50,
        avgWorkletLagMs: 10,
        p95WorkletLagMs: 20,
        memoryStrainPct: 25,
        frameCount: 100,
        sessionDurationMs: 120000,
      },
      strainEvents: [
        {
          type: 'SAB_BACKLOG',
          value: 85,
          timestamp: Date.now(),
        },
      ],
    };

    expect(exportData.version).toBe('1.0');
    expect(exportData.duration).toBe(120000);
    expect(exportData.frameCount).toBe(100);
    expect(exportData.frames).toHaveLength(1);
    expect(exportData.session).toBeDefined();
    expect(exportData.strainEvents).toHaveLength(1);
    expect(exportData.strainEvents[0].type).toBe('SAB_BACKLOG');
  });
});
