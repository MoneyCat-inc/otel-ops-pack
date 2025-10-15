#!/usr/bin/env node
/**
 * RSI Conservative Proposal Generator
 * Smaller tuning increments for safer optimization
 * @module propose-conservative
 */

const baseline = {
  index: {
    IndexConcurrency: 8,
    BatchSize: 1000
  },
  conveyor: {
    ARCH_QPS: 2.0,
    ARCH_CONCURRENCY: 48
  }
};

// Conservative tuning: +10% instead of +25%
const candidate = {
  index: {
    IndexConcurrency: Math.round(baseline.index.IndexConcurrency * 1.1), // 8 * 1.1 = 8.8 → 9
    BatchSize: baseline.index.BatchSize
  },
  conveyor: {
    ARCH_QPS: Math.round(baseline.conveyor.ARCH_QPS * 1.1 * 10) / 10, // 2.0 * 1.1 = 2.2
    ARCH_CONCURRENCY: Math.round(baseline.conveyor.ARCH_CONCURRENCY * 1.1) // 48 * 1.1 = 52.8 → 53
  }
};

console.log(JSON.stringify(candidate));

