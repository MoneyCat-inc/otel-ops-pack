/**
 * Test fixture helpers for AggregatedMetrics
 * Provides complete test data that matches the AggregatedMetrics interface
 */

import { AggregatedMetrics } from '../../src/engine/metrics/aggregate';

export function createTestAggregatedMetrics(overrides: Partial<AggregatedMetrics> = {}): AggregatedMetrics {
  const now = Date.now();
  const today = new Date().toISOString().split('T')[0];
  
  return {
    date: today,
    sessions: 1,
    totalDurationMs: 300000, // 5 minutes
    
    // Core metrics
    inBandPct: {
      mean: 0.75,
      median: 0.8,
      trend: 'stable'
    },
    
    expressiveness01: {
      mean: 0.6,
      median: 0.65,
      trend: 'stable'
    },
    
    // Resonance bucket bias
    bucketBias: {
      front: 0.4,
      central: 0.3,
      back: 0.3,
      dominant: 'front'
    },
    
    // Safety metrics
    strainCount: 0,
    strainRate: 0,
    
    // Beta success metrics
    betaMetrics: {
      retentionPct: 0.8,
      retentionTrend: 'stable',
      
      comfortTrend: {
        mean: 4,
        median: 4,
        trend: 'stable'
      },
      fatigueTrend: {
        mean: 2,
        median: 2,
        trend: 'stable'
      },
      
      strainPer100Min: 0,
      strainHealth: 'excellent',
      
      sessionFrequency: 5,
      frequencyTrend: 'stable'
    },
    
    // Schema versioning
    schemaVersion: 1,
    aggregatedAt: now,
    
    // Apply overrides
    ...overrides
  };
}

export function createTestProgressTrends(overrides: any = {}) {
  const now = Date.now();
  const today = new Date().toISOString().split('T')[0];
  
  return {
    daily: [createTestAggregatedMetrics()],
    weekly: [createTestAggregatedMetrics()],
    monthly: [createTestAggregatedMetrics()],
    
    totalSessions: 5,
    totalDurationMs: 1500000,
    averageSessionDurationMs: 300000,
    
    overallTrend: {
      inBandPct: 'stable' as const,
      expressiveness: 'stable' as const,
      safety: 'stable' as const
    },
    
    dateRange: {
      start: today,
      end: today
    },
    
    ...overrides
  };
}
