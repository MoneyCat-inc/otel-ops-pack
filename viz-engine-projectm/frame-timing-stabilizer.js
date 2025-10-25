// Gate #016 Job V2 - Frame Timing Stabilizer
// Purpose: Track guard sampling cadence, jitter ceiling, and stabilizer pin budget

class FrameTimingStabilizer {
  constructor(options = {}) {
    this.targetIntervalMs = options.targetIntervalMs || 100;
    this.jitterBudgetMs = options.jitterBudgetMs || 8;
    this.pinWindowMs = options.pinWindowMs || 60000;
    this.sampleSize = options.sampleSize || 120; // ~12s at 10 Hz
    this.ignoreInitialMs = options.ignoreInitialMs || 10000; // Ignore first 10s spikes

    this.reset();
  }

  reset() {
    this.lastTickStart = null;
    this.lastIntervalMs = 0;
    this.lastDurationMs = 0;
    this.lastJitterMs = 0;

    this.jitterSamples = [];
    this.jitterMaxMs = 0;

    this.pinEvents = [];
    this.totalPins = 0;
    
    this.startTime = Date.now();
  }

  recordTickStart(now = Date.now()) {
    if (this.lastTickStart !== null) {
      const interval = now - this.lastTickStart;
      this.lastIntervalMs = interval;

      const jitter = Math.abs(interval - this.targetIntervalMs);
      this.lastJitterMs = jitter;

      const runtime = now - this.startTime;
      
      // Only track jitter after initial warmup period
      if (runtime > this.ignoreInitialMs) {
        this.jitterSamples.push(jitter);
        if (this.jitterSamples.length > this.sampleSize) {
          this.jitterSamples.shift();
        }

        if (jitter > this.jitterMaxMs) {
          this.jitterMaxMs = jitter;
        }

        // Only register pins after warmup and for sustained issues
        if (jitter > this.jitterBudgetMs) {
          this.registerPin(now);
        } else {
          this.prunePins(now);
        }
      }
    }

    this.lastTickStart = now;
  }

  recordDuration(durationMs) {
    this.lastDurationMs = durationMs;
  }

  registerPin(now = Date.now()) {
    this.pinEvents.push(now);
    this.totalPins += 1;
    this.prunePins(now);
  }

  prunePins(now = Date.now()) {
    const threshold = now - this.pinWindowMs;
    this.pinEvents = this.pinEvents.filter((ts) => ts >= threshold);
  }

  getStats(now = Date.now()) {
    this.prunePins(now);

    const sampleCount = this.jitterSamples.length;
    let avg = 0;
    if (sampleCount > 0) {
      avg = this.jitterSamples.reduce((sum, value) => sum + value, 0) / sampleCount;
    }

    let p95 = 0;
    if (sampleCount > 0) {
      const sorted = [...this.jitterSamples].sort((a, b) => a - b);
      const idx = Math.min(sorted.length - 1, Math.floor(0.95 * (sorted.length - 1)));
      p95 = sorted[idx];
    }

    const round2 = (value) => Math.round(value * 100) / 100;

    return {
      targetIntervalMs: this.targetIntervalMs,
      jitterBudgetMs: this.jitterBudgetMs,
      jitterAvgMs: round2(avg),
      jitterP95Ms: round2(p95),
      jitterMaxMs: round2(this.jitterMaxMs),
      jitterLastMs: round2(this.lastJitterMs),
      lastIntervalMs: round2(this.lastIntervalMs),
      lastDurationMs: round2(this.lastDurationMs),
      stabilizerPinCount: this.pinEvents.length,
      totalPins: this.totalPins,
      sampleCount,
      pinWindowMs: this.pinWindowMs,
      lastTickStart: this.lastTickStart,
      runtime: now - this.startTime,
      warmupComplete: (now - this.startTime) > this.ignoreInitialMs
    };
  }
}

module.exports = { FrameTimingStabilizer };
