/**
 * Aggregation Engine Unit Tests
 * 
 * C1: Progress Dashboard
 * Comprehensive tests for progress metrics aggregation, edge cases, and schema versioning.
 */

import { describe, it, expect, beforeEach } from 'vitest';
import { ProgressAggregator, SessionSummaryV1, AggregatedMetrics } from '../../src/engine/metrics/aggregate';

describe('ProgressAggregator', () => {
  let aggregator: ProgressAggregator;

  beforeEach(() => {
    aggregator = new ProgressAggregator();
  });

  describe('Daily Aggregation', () => {
    it('should aggregate sessions by date', () => {
      const sessions: SessionSummaryV1[] = [
        createMockSession('2024-01-01', { inBandPct: 0.7, prosodyVar: 0.5 }),
        createMockSession('2024-01-01', { inBandPct: 0.8, prosodyVar: 0.6 }),
        createMockSession('2024-01-02', { inBandPct: 0.6, prosodyVar: 0.4 }),
      ];

      const daily = aggregator.aggregateDaily(sessions);

      expect(daily).toHaveLength(2);
      expect(daily[0].date).toBe('2024-01-01');
      expect(daily[0].sessions).toBe(2);
      expect(daily[0].inBandPct.mean).toBeCloseTo(0.75);
      expect(daily[1].date).toBe('2024-01-02');
      expect(daily[1].sessions).toBe(1);
    });

    it('should handle empty session list', () => {
      const daily = aggregator.aggregateDaily([]);
      expect(daily).toHaveLength(0);
    });

    it('should handle sessions with missing metrics', () => {
      const sessions: SessionSummaryV1[] = [
        createMockSession('2024-01-01', { inBandPct: undefined, prosodyVar: 0.5 }),
        createMockSession('2024-01-01', { inBandPct: 0.8, prosodyVar: undefined }),
      ];

      const daily = aggregator.aggregateDaily(sessions);

      expect(daily).toHaveLength(1);
      expect(daily[0].inBandPct.mean).toBeCloseTo(0.8); // Only valid values
      expect(daily[0].expressiveness01.mean).toBeCloseTo(0.5); // Only valid values
    });

    it('should calculate bucket bias correctly', () => {
      const sessions: SessionSummaryV1[] = [
        createMockSession('2024-01-01', {
          memx: {
            bucketBias: { front: 0.6, central: 0.3, back: 0.1 }
          }
        }),
        createMockSession('2024-01-01', {
          memx: {
            bucketBias: { front: 0.4, central: 0.4, back: 0.2 }
          }
        }),
      ];

      const daily = aggregator.aggregateDaily(sessions);

      expect(daily[0].bucketBias.front).toBeCloseTo(0.5); // (0.6 + 0.4) / 2
      expect(daily[0].bucketBias.central).toBeCloseTo(0.35); // (0.3 + 0.4) / 2
      expect(daily[0].bucketBias.back).toBeCloseTo(0.15); // (0.1 + 0.2) / 2
      expect(daily[0].bucketBias.dominant).toBe('front');
    });

    it('should calculate strain metrics correctly', () => {
      const sessions: SessionSummaryV1[] = [
        createMockSession('2024-01-01', {
          memx: { memoryStrainPct: 0.05 } // Below threshold
        }),
        createMockSession('2024-01-01', {
          memx: { memoryStrainPct: 0.15 } // Above threshold
        }),
        createMockSession('2024-01-01', {
          memx: { memoryStrainPct: 0.2 } // Above threshold
        }),
      ];

      const daily = aggregator.aggregateDaily(sessions);

      expect(daily[0].strainCount).toBe(2); // 2 sessions above threshold
      expect(daily[0].strainRate).toBeCloseTo(0.67); // 2/3 sessions
    });

    it('should handle sessions without schema version', () => {
      const sessions: SessionSummaryV1[] = [
        {
          id: 1,
          ts: new Date('2024-01-01').getTime(),
          medianF0: 150,
          inBandPct: 0.7,
          prosodyVar: 0.5,
          // No schemaVersion
        } as SessionSummaryV1
      ];

      const daily = aggregator.aggregateDaily(sessions);

      expect(daily).toHaveLength(0); // Invalid sessions should be filtered out
    });
  });

  describe('Weekly Aggregation', () => {
    it('should aggregate daily metrics into weekly metrics', () => {
      const daily: AggregatedMetrics[] = [
        createMockDailyMetrics('2024-01-01', { sessions: 2, strainCount: 1 }),
        createMockDailyMetrics('2024-01-02', { sessions: 1, strainCount: 0 }),
        createMockDailyMetrics('2024-01-03', { sessions: 3, strainCount: 2 }),
      ];

      const weekly = aggregator.aggregateWeekly(daily);

      expect(weekly).toHaveLength(1); // All days in same week
      expect(weekly[0].sessions).toBe(6); // 2 + 1 + 3
      expect(weekly[0].strainCount).toBe(3); // 1 + 0 + 2
      expect(weekly[0].strainRate).toBeCloseTo(0.5); // 3/6
    });

    it('should handle empty daily metrics', () => {
      const weekly = aggregator.aggregateWeekly([]);
      expect(weekly).toHaveLength(0);
    });

    it('should group days by week correctly', () => {
      const daily: AggregatedMetrics[] = [
        createMockDailyMetrics('2024-01-01'), // Monday
        createMockDailyMetrics('2024-01-02'), // Tuesday
        createMockDailyMetrics('2024-01-08'), // Next Monday
      ];

      const weekly = aggregator.aggregateWeekly(daily);

      expect(weekly).toHaveLength(2); // Two different weeks
    });
  });

  describe('Monthly Aggregation', () => {
    it('should aggregate daily metrics into monthly metrics', () => {
      const daily: AggregatedMetrics[] = [
        createMockDailyMetrics('2024-01-01'),
        createMockDailyMetrics('2024-01-15'),
        createMockDailyMetrics('2024-01-30'),
      ];

      const monthly = aggregator.aggregateMonthly(daily);

      expect(monthly).toHaveLength(1); // All days in same month
      expect(monthly[0].date).toBe('2024-01-01'); // First day of month
    });

    it('should handle empty daily metrics', () => {
      const monthly = aggregator.aggregateMonthly([]);
      expect(monthly).toHaveLength(0);
    });
  });

  describe('Trend Calculation', () => {
    it('should calculate overall trends correctly', () => {
      const sessions: SessionSummaryV1[] = [
        // First half - lower performance
        createMockSession('2024-01-01', { inBandPct: 0.6, prosodyVar: 0.4 }),
        createMockSession('2024-01-02', { inBandPct: 0.65, prosodyVar: 0.45 }),
        createMockSession('2024-01-03', { inBandPct: 0.7, prosodyVar: 0.5 }),
        // Second half - higher performance
        createMockSession('2024-01-04', { inBandPct: 0.8, prosodyVar: 0.6 }),
        createMockSession('2024-01-05', { inBandPct: 0.85, prosodyVar: 0.65 }),
        createMockSession('2024-01-06', { inBandPct: 0.9, prosodyVar: 0.7 }),
      ];

      const trends = aggregator.generateTrends(sessions);

      expect(trends.overallTrend.inBandPct).toBe('improving');
      expect(trends.overallTrend.expressiveness).toBe('improving');
    });

    it('should handle insufficient data for trends', () => {
      const sessions: SessionSummaryV1[] = [
        createMockSession('2024-01-01', { inBandPct: 0.7, prosodyVar: 0.5 }),
      ];

      const trends = aggregator.generateTrends(sessions);

      expect(trends.overallTrend.inBandPct).toBe('stable');
      expect(trends.overallTrend.expressiveness).toBe('stable');
    });
  });

  describe('Date Range Filtering', () => {
    it('should filter sessions by date range', () => {
      const sessions: SessionSummaryV1[] = [
        createMockSession('2024-01-01'),
        createMockSession('2024-01-15'),
        createMockSession('2024-01-30'),
        createMockSession('2024-02-01'),
      ];

      const trends = aggregator.generateTrends(sessions, {
        start: '2024-01-01',
        end: '2024-01-31'
      });

      expect(trends.totalSessions).toBe(3); // Only January sessions
    });

    it('should handle empty date range', () => {
      const sessions: SessionSummaryV1[] = [
        createMockSession('2024-01-01'),
      ];

      const trends = aggregator.generateTrends(sessions, {
        start: '2024-02-01',
        end: '2024-02-28'
      });

      expect(trends.totalSessions).toBe(0);
    });
  });

  describe('Edge Cases', () => {
    it('should handle zero values in calculations', () => {
      const sessions: SessionSummaryV1[] = [
        createMockSession('2024-01-01', { inBandPct: 0, prosodyVar: 0 }),
      ];

      const daily = aggregator.aggregateDaily(sessions);

      expect(daily[0].inBandPct.mean).toBe(0);
      expect(daily[0].expressiveness01.mean).toBe(0);
    });

    it('should handle single session', () => {
      const sessions: SessionSummaryV1[] = [
        createMockSession('2024-01-01', { inBandPct: 0.7, prosodyVar: 0.5 }),
      ];

      const daily = aggregator.aggregateDaily(sessions);

      expect(daily).toHaveLength(1);
      expect(daily[0].inBandPct.mean).toBe(0.7);
      expect(daily[0].inBandPct.median).toBe(0.7);
    });

    it('should handle sessions with missing memx data', () => {
      const sessions: SessionSummaryV1[] = [
        createMockSession('2024-01-01', { memx: undefined }),
      ];

      const daily = aggregator.aggregateDaily(sessions);

      expect(daily[0].bucketBias.front).toBe(0);
      expect(daily[0].bucketBias.central).toBe(0);
      expect(daily[0].bucketBias.back).toBe(0);
      expect(daily[0].bucketBias.dominant).toBe('central');
    });

    it('should handle sessions with partial memx data', () => {
      const sessions: SessionSummaryV1[] = [
        createMockSession('2024-01-01', {
          memx: {
            memoryStrainPct: 0.1,
            bucketBias: undefined
          }
        }),
      ];

      const daily = aggregator.aggregateDaily(sessions);

      expect(daily[0].strainCount).toBe(0); // Below threshold
      expect(daily[0].bucketBias.front).toBe(0);
    });
  });

  describe('Schema Versioning', () => {
    it('should include schema version in aggregated metrics', () => {
      const sessions: SessionSummaryV1[] = [
        createMockSession('2024-01-01'),
      ];

      const daily = aggregator.aggregateDaily(sessions);

      expect(daily[0].schemaVersion).toBe(1);
      expect(daily[0].aggregatedAt).toBeGreaterThan(0);
    });

    it('should handle future schema versions gracefully', () => {
      const sessions: SessionSummaryV1[] = [
        {
          ...createMockSession('2024-01-01'),
          schemaVersion: 2 // Future version
        },
      ];

      const daily = aggregator.aggregateDaily(sessions);

      expect(daily).toHaveLength(0); // Should filter out unknown versions
    });
  });

  describe('Performance', () => {
    it('should handle large number of sessions efficiently', () => {
      const sessions: SessionSummaryV1[] = [];
      
      // Generate 1000 sessions
      for (let i = 0; i < 1000; i++) {
        const date = new Date(2024, 0, 1 + Math.floor(i / 10)); // 10 sessions per day
        sessions.push(createMockSession(date.toISOString().split('T')[0]));
      }

      const start = Date.now();
      const daily = aggregator.aggregateDaily(sessions);
      const end = Date.now();

      expect(daily.length).toBeGreaterThan(0);
      expect(end - start).toBeLessThan(1000); // Should complete in under 1 second
    });
  });
});

// Helper functions
function createMockSession(date: string, overrides: Partial<SessionSummaryV1> = {}): SessionSummaryV1 {
  return {
    id: Math.random(),
    ts: new Date(date).getTime(),
    medianF0: 150,
    inBandPct: 0.7,
    prosodyVar: 0.5,
    voicedTimePct: 0.8,
    jitterEma: 0.1,
    comfort: 3,
    fatigue: 2,
    euphoria: 4,
    orb: 'practice',
    memx: {
      memoryStrainPct: 0.05,
      bucketBias: {
        front: 0.4,
        central: 0.4,
        back: 0.2
      }
    },
    schemaVersion: 1,
    ...overrides
  };
}

function createMockDailyMetrics(date: string, overrides: Partial<AggregatedMetrics> = {}): AggregatedMetrics {
  return {
    date,
    sessions: 1,
    totalDurationMs: 300000,
    inBandPct: { mean: 0.7, median: 0.7, trend: 'stable' },
    expressiveness01: { mean: 0.5, median: 0.5, trend: 'stable' },
    bucketBias: { front: 0.4, central: 0.4, back: 0.2, dominant: 'front' },
    strainCount: 0,
    strainRate: 0,
    betaMetrics: {
      retentionPct: 0.8,
      retentionTrend: 'stable',
      comfortTrend: { mean: 4, median: 4, trend: 'stable' },
      fatigueTrend: { mean: 2, median: 2, trend: 'stable' },
      strainPer100Min: 0,
      strainHealth: 'excellent',
      sessionFrequency: 5,
      frequencyTrend: 'stable'
    },
    schemaVersion: 1,
    aggregatedAt: Date.now(),
    ...overrides
  };
}
