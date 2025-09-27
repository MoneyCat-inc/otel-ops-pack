/**
 * MEMX Browser Instrumentation
 * 
 * PR-2: Browser instrumentation - collect zero-overhead memory stats
 * alongside RAF/PerfOverlay loop
 */

import { MemxFrame, MemxConfig, DEFAULT_MEMX_CONFIG } from './types';
import { getMemxStore } from './store';

export class MemxInstrumentation {
  private config: MemxConfig;
  private store = getMemxStore();
  private isRunning = false;
  private rafId: number | null = null;
  private lastWasmHeapBytes = 0;

  constructor(config: Partial<MemxConfig> = {}) {
    this.config = { ...DEFAULT_MEMX_CONFIG, ...config };
  }

  /**
   * Start memory instrumentation
   */
  start(): void {
    if (!this.config.enabled || this.isRunning) {
      return;
    }

    this.isRunning = true;
    this.collectFrame();
  }

  /**
   * Stop memory instrumentation
   */
  stop(): void {
    if (!this.isRunning) {
      return;
    }

    this.isRunning = false;
    if (this.rafId !== null) {
      cancelAnimationFrame(this.rafId);
      this.rafId = null;
    }
  }

  /**
   * Update configuration
   */
  updateConfig(config: Partial<MemxConfig>): void {
    this.config = { ...this.config, ...config };
  }

  /**
   * Collect memory frame data
   */
  private collectFrame(): void {
    if (!this.isRunning) {
      return;
    }

    const frame: MemxFrame = {
      ts: performance.now(),
    };

    // Collect WASM heap bytes
    this.collectWasmHeap(frame);

    // Collect SAB usage (audio ring buffer)
    this.collectSabUsage(frame);

    // Collect worklet lag (stamp in worklet, read here)
    this.collectWorkletLag(frame);

    // GPU utilization (placeholder for PR-5)
    frame.gpuUtilPct = null;

    // Add frame to store
    this.store.addFrame(frame);

    // Schedule next frame
    this.rafId = requestAnimationFrame(() => this.collectFrame());
  }

  /**
   * Collect WASM heap memory usage
   */
  private collectWasmHeap(frame: MemxFrame): void {
    try {
      // Try to get WASM memory from global ONNX runtime or WebAssembly
      const wasmMemory = this.getWasmMemory();
      if (wasmMemory) {
        const currentHeapBytes = wasmMemory.buffer.byteLength;
        frame.wasmHeapBytes = currentHeapBytes;
        
        // Detect memory growth
        if (currentHeapBytes > this.lastWasmHeapBytes) {
          frame.flags = { ...frame.flags, wasmGrow: true };
        }
        this.lastWasmHeapBytes = currentHeapBytes;
      }
    } catch (error) {
      // WASM memory not available or accessible
      console.debug('MEMX: WASM memory not accessible:', error);
    }
  }

  /**
   * Get WASM memory from various sources
   */
  private getWasmMemory(): WebAssembly.Memory | null {
    // Try ONNX Runtime Web (CREPE detector)
    if (typeof window !== 'undefined' && (window as any).ort?.env?.wasm?.memory) {
      return (window as any).ort.env.wasm.memory;
    }

    // Try global WebAssembly memory
    if (typeof window !== 'undefined' && (window as any).wasmMemory) {
      return (window as any).wasmMemory;
    }

    // Try to find WASM memory in module instances
    if (typeof window !== 'undefined') {
      const globalThis = window as any;
      for (const key in globalThis) {
        const obj = globalThis[key];
        if (obj && obj.memory instanceof WebAssembly.Memory) {
          return obj.memory;
        }
      }
    }

    return null;
  }

  /**
   * Collect SharedArrayBuffer usage for audio ring buffer
   */
  private collectSabUsage(frame: MemxFrame): void {
    try {
      // Try to access audio ring buffer SAB
      const audioRingBuffer = this.getAudioRingBuffer();
      if (audioRingBuffer && audioRingBuffer.buffer instanceof SharedArrayBuffer) {
        const sab = audioRingBuffer.buffer as SharedArrayBuffer;
        const sabView = new Int32Array(sab);
        
        // Read write/read indices (assuming standard ring buffer layout)
        const writeIndex = sabView[0] || 0;
        const readIndex = sabView[1] || 0;
        const capacity = sabView[2] || sab.byteLength;
        
        frame.sabCapacityBytes = capacity;
        frame.sabUsedBytes = Math.abs(writeIndex - readIndex);
        
        // Check for backlog
        const usagePct = (frame.sabUsedBytes / frame.sabCapacityBytes) * 100;
        if (usagePct > 80) { // Threshold from config
          frame.flags = { ...frame.flags, sabBacklog: true };
        }
      }
    } catch (error) {
      // SAB not available or accessible
      console.debug('MEMX: SAB not accessible:', error);
    }
  }

  /**
   * Get audio ring buffer reference
   */
  private getAudioRingBuffer(): ArrayBufferView | null {
    // Try to access audio worklet's ring buffer
    if (typeof window !== 'undefined') {
      const globalThis = window as any;
      
      // Look for audio worklet context
      if (globalThis.audioWorkletContext?.ringBuffer) {
        return globalThis.audioWorkletContext.ringBuffer;
      }
      
      // Look for audio processing context
      if (globalThis.audioContext?.ringBuffer) {
        return globalThis.audioContext.ringBuffer;
      }
      
      // Look for detector context
      if (globalThis.detectorContext?.ringBuffer) {
        return globalThis.detectorContext.ringBuffer;
      }
    }

    return null;
  }

  /**
   * Collect worklet lag (stamp in worklet, read here)
   */
  private collectWorkletLag(frame: MemxFrame): void {
    try {
      // Try to read worklet timestamp from shared memory or global
      const workletTimestamp = this.getWorkletTimestamp();
      if (workletTimestamp) {
        const currentTime = performance.now();
        frame.workletLagMs = Math.max(0, currentTime - workletTimestamp);
      }
    } catch (error) {
      console.debug('MEMX: Worklet lag not accessible:', error);
    }
  }

  /**
   * Get worklet timestamp from shared memory or global
   */
  private getWorkletTimestamp(): number | null {
    if (typeof window !== 'undefined') {
      const globalThis = window as any;
      
      // Try shared memory timestamp
      if (globalThis.workletTimestamp) {
        return globalThis.workletTimestamp;
      }
      
      // Try audio worklet context timestamp
      if (globalThis.audioWorkletContext?.lastProcessTime) {
        return globalThis.audioWorkletContext.lastProcessTime;
      }
    }

    return null;
  }

  /**
   * Get current configuration
   */
  getConfig(): MemxConfig {
    return { ...this.config };
  }

  /**
   * Check if instrumentation is running
   */
  isActive(): boolean {
    return this.isRunning;
  }
}

// Singleton instance
let memxInstrumentation: MemxInstrumentation | null = null;

export function getMemxInstrumentation(): MemxInstrumentation {
  if (!memxInstrumentation) {
    memxInstrumentation = new MemxInstrumentation();
  }
  return memxInstrumentation;
}

// Utility function to stamp worklet processing time
export function stampWorkletTime(): void {
  if (typeof window !== 'undefined') {
    (window as any).workletTimestamp = performance.now();
  }
}
