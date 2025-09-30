/**
 * Unit Tests for Beta Metrics Calculation Logic
 * 
 * C6: Beta Success Metrics
 * Tests the calculation methods for retention, comfort/fatigue trends, strain health, and session frequency.
 */

import { ProgressAggregator, SessionSummaryV1 } from '../../src/engine/metrics/aggregate';

describe('Beta Metrics Calculation', () => {
  let aggregator: ProgressAggregator;

  beforeEach(() => {
    aggregator = new ProgressAggregator();
  });

  describe('Retention Percentage Calculation', () => {
    it('should calculate retention correctly for daily practice', () => {
      const now = Date.now();
      const sessions: SessionSummaryV1[] = [];
      
      // Create sessions for 7 consecutive days
      for (let i = 0; i < 7; i++) {
        sessions.push({
          ts: now - i * 24 * 60 * 60 * 1000, medianF0: 150, comfort: 4, fatigue: 2, schemaVersion: 1
        });
      }

      const daily = aggregator.aggregateDaily(sessions);
      const retention = daily[0].betaMetrics.retentionPct;

      expect(retention).toBeCloseTo(1.0, 2); // 100% retention
    });

    it('should calculate retention correctly for irregular practice', () => {
      const now = Date.now();
      const sessions: SessionSummaryV1[] = [];
      
      // Create sessions for 3 out of 7 days
      sessions.push({ ts: now, medianF0: 150, comfort: 4, fatigue: 2, schemaVersion: 1 });
      sessions.push({ ts: now - 2 * 24 * 60 * 60 * 1000, medianF0: 150, comfort: 3, fatigue: 3, schemaVersion: 1 });
      sessions.push({ ts: now - 5 * 24 * 60 * 60 * 1000, medianF0: 150, comfort: 4, fatigue: 2, schemaVersion: 1 });

      const daily = aggregator.aggregateDaily(sessions);
      const retention = daily[0].betaMetrics.retentionPct;

      expect(retention).toBeCloseTo(0.5, 2); // 50% retention (3 days out of 6)
    });

    it('should handle empty sessions array', () => {
      const sessions: SessionSummaryV1[] = [];
      const daily = aggregator.aggregateDaily(sessions);
      
      expect(daily).toHaveLength(0);
    });

    it('should handle single session', () => {
      const sessions: SessionSummaryV1[] = [{
        ts: Date.now(), medianF0: 150, comfort: 4, fatigue: 2, schemaVersion: 1
      }];

      const daily = aggregator.aggregateDaily(sessions);
      const retention = daily[0].betaMetrics.retentionPct;

      expect(retention).toBeCloseTo(1.0, 2); // 100% retention for single day
    });
  });

  describe('Comfort and Fatigue Trends', () => {
    it('should calculate comfort trend correctly', () => {
      const now = Date.now();
      const sessions: SessionSummaryV1[] = [
        { ts: now, medianF0: 150, comfort: 3, fatigue: 3, schemaVersion: 1 },
        { ts: now - 24 * 60 * 60 * 1000, medianF0: 150, comfort: 4, fatigue: 2, schemaVersion: 1 },
        { ts: now - 2 * 24 * 60 * 60 * 1000, medianF0: 150, comfort: 5, fatigue: 1, schemaVersion: 1 }
      ];

      const daily = aggregator.aggregateDaily(sessions);
      const latestDay = daily[daily.length - 1];

      expect(latestDay.betaMetrics.comfortTrend.mean).toBeCloseTo(4.0, 1);
      expect(latestDay.betaMetrics.comfortTrend.median).toBeCloseTo(4.0, 1);
    });

    it('should calculate fatigue trend correctly', () => {
      const now = Date.now();
      const sessions: SessionSummaryV1[] = [
        { ts: now, medianF0: 150, comfort: 4, fatigue: 2, schemaVersion: 1 },
        { ts: now - 24 * 60 * 60 * 1000, medianF0: 150, comfort: 3, fatigue: 3, schemaVersion: 1 },
        { ts: now - 2 * 24 * 60 * 60 * 1000, medianF0: 150, comfort: 2, fatigue: 4, schemaVersion: 1 }
      ];

      const daily = aggregator.aggregateDaily(sessions);
      const latestDay = daily[daily.length - 1];

      expect(latestDay.betaMetrics.fatigueTrend.mean).toBeCloseTo(3.0, 1);
      expect(latestDay.betaMetrics.fatigueTrend.median).toBeCloseTo(3.0, 1);
    });

    it('should handle missing comfort/fatigue values', () => {
      const now = Date.now();
      const sessions: SessionSummaryV1[] = [
        { ts: now, comfort: 4, schemaVersion: 1 }, // missing fatigue
        { ts: now - 24 * 60 * 60 * 1000, fatigue: 2, schemaVersion: 1 }, // missing comfort
        { ts: now - 2 * 24 * 60 * 60 * 1000, medianF0: 150, comfort: 3, fatigue: 3, schemaVersion: 1 }
      ];

      const daily = aggregator.aggregateDaily(sessions);
      const latestDay = daily[daily.length - 1];

      expect(latestDay.betaMetrics.comfortTrend.mean).toBeCloseTo(3.5, 1);
      expect(latestDay.betaMetrics.fatigueTrend.mean).toBeCloseTo(2.5, 1);
    });
  });

  describe('Strain Health Calculation', () => {
    it('should categorize strain health correctly', () => {
      const now = Date.now();
      
      // Test excellent strain health (<10%)
      const excellentSessions: SessionSummaryV1[] = [
        { 
          ts: now, 
          comfort: 4, 
          fatigue: 2, 
          memx: { memoryStrainPct: 0.05 },
          schemaVersion: 1 
        },
        { 
          ts: now - 24 * 60 * 60 * 1000, 
          comfort: 4, 
          fatigue: 2, 
          memx: { memoryStrainPct: 0.08 },
          schemaVersion: 1 
        }
      ];

      const excellentDaily = aggregator.aggregateDaily(excellentSessions);
      expect(excellentDaily[0].betaMetrics.strainHealth).toBe('excellent');

      // Test good strain health (10-25%)
      const goodSessions: SessionSummaryV1[] = [
        { 
          ts: now, 
          comfort: 3, 
          fatigue: 3, 
          memx: { memoryStrainPct: 0.15 },
          schemaVersion: 1 
        },
        { 
          ts: now - 24 * 60 * 60 * 1000, 
          comfort: 3, 
          fatigue: 3, 
          memx: { memoryStrainPct: 0.20 },
          schemaVersion: 1 
        }
      ];

      const goodDaily = aggregator.aggregateDaily(goodSessions);
      expect(goodDaily[0].betaMetrics.strainHealth).toBe('good');

      // Test moderate strain health (25-50%)
      const moderateSessions: SessionSummaryV1[] = [
        { 
          ts: now, 
          comfort: 2, 
          fatigue: 4, 
          memx: { memoryStrainPct: 0.30 },
          schemaVersion: 1 
        },
        { 
          ts: now - 24 * 60 * 60 * 1000, 
          comfort: 2, 
          fatigue: 4, 
          memx: { memoryStrainPct: 0.35 },
          schemaVersion: 1 
        }
      ];

      const moderateDaily = aggregator.aggregateDaily(moderateSessions);
      expect(moderateDaily[0].betaMetrics.strainHealth).toBe('moderate');

      // Test poor strain health (>50%)
      const poorSessions: SessionSummaryV1[] = [
        { 
          ts: now, 
          comfort: 1, 
          fatigue: 5, 
          memx: { memoryStrainPct: 0.60 },
          schemaVersion: 1 
        },
        { 
          ts: now - 24 * 60 * 60 * 1000, 
          comfort: 1, 
          fatigue: 5, 
          memx: { memoryStrainPct: 0.70 },
          schemaVersion: 1 
        }
      ];

      const poorDaily = aggregator.aggregateDaily(poorSessions);
      expect(poorDaily[0].betaMetrics.strainHealth).toBe('poor');
    });

    it('should calculate strain per 100 minutes correctly', () => {
      const now = Date.now();
      const sessions: SessionSummaryV1[] = [
        { 
          ts: now, 
          comfort: 4, 
          fatigue: 2, 
          memx: { memoryStrainPct: 0.1 },
          schemaVersion: 1 
        },
        { 
          ts: now - 24 * 60 * 60 * 1000, 
          comfort: 4, 
          fatigue: 2, 
          memx: { memoryStrainPct: 0.1 },
          schemaVersion: 1 
        }
      ];

      const daily = aggregator.aggregateDaily(sessions);
      const strainPer100Min = daily[0].betaMetrics.strainPer100Min;

      // Should be normalized to per 100 minutes
      expect(strainPer100Min).toBeGreaterThan(0);
      expect(strainPer100Min).toBeLessThan(100);
    });
  });

  describe('Session Frequency Calculation', () => {
    it('should calculate session frequency correctly', () => {
      const now = Date.now();
      const sessions: SessionSummaryV1[] = [];
      
      // Create 14 sessions over 2 weeks (1 per day)
      for (let i = 0; i < 14; i++) {
        sessions.push({
          ts: now - i * 24 * 60 * 60 * 1000, medianF0: 150, comfort: 4, fatigue: 2, schemaVersion: 1
        });
      }

      const daily = aggregator.aggregateDaily(sessions);
      const frequency = daily[0].betaMetrics.sessionFrequency;

      expect(frequency).toBeCloseTo(7.0, 1); // 7 sessions per week
    });

    it('should handle irregular session frequency', () => {
      const now = Date.now();
      const sessions: SessionSummaryV1[] = [];
      
      // Create 6 sessions over 2 weeks (3 per week)
      for (let i = 0; i < 6; i++) {
        sessions.push({
          ts: now - i * 2 * 24 * 60 * 60 * 1000, // Every other day
          comfort: 4,
          fatigue: 2,
          schemaVersion: 1
        });
      }

      const daily = aggregator.aggregateDaily(sessions);
      const frequency = daily[0].betaMetrics.sessionFrequency;

      expect(frequency).toBeCloseTo(3.0, 1); // 3 sessions per week
    });
  });

  describe('Trend Analysis', () => {
    it('should identify improving trends', () => {
      const now = Date.now();
      const sessions: SessionSummaryV1[] = [];
      
      // Create sessions with improving comfort over time
      for (let i = 0; i < 5; i++) {
        sessions.push({
          ts: now - i * 24 * 60 * 60 * 1000,
          comfort: 2 + i, // 2, 3, 4, 5, 6
          fatigue: 5 - i, // 5, 4, 3, 2, 1
          schemaVersion: 1
        });
      }

      const daily = aggregator.aggregateDaily(sessions);
      const latestDay = daily[daily.length - 1];

      expect(latestDay.betaMetrics.comfortTrend.trend).toBe('up');
      expect(latestDay.betaMetrics.fatigueTrend.trend).toBe('down');
    });

    it('should identify declining trends', () => {
      const now = Date.now();
      const sessions: SessionSummaryV1[] = [];
      
      // Create sessions with declining comfort over time
      for (let i = 0; i < 5; i++) {
        sessions.push({
          ts: now - i * 24 * 60 * 60 * 1000,
          comfort: 5 - i, // 5, 4, 3, 2, 1
          fatigue: 1 + i, // 1, 2, 3, 4, 5
          schemaVersion: 1
        });
      }

      const daily = aggregator.aggregateDaily(sessions);
      const latestDay = daily[daily.length - 1];

      expect(latestDay.betaMetrics.comfortTrend.trend).toBe('down');
      expect(latestDay.betaMetrics.fatigueTrend.trend).toBe('up');
    });

    it('should identify stable trends', () => {
      const now = Date.now();
      const sessions: SessionSummaryV1[] = [];
      
      // Create sessions with stable comfort over time
      for (let i = 0; i < 5; i++) {
        sessions.push({
          ts: now - i * 24 * 60 * 60 * 1000,
          comfort: 3, // All the same
          fatigue: 3, // All the same
          schemaVersion: 1
        });
      }

      const daily = aggregator.aggregateDaily(sessions);
      const latestDay = daily[daily.length - 1];

      expect(latestDay.betaMetrics.comfortTrend.trend).toBe('stable');
      expect(latestDay.betaMetrics.fatigueTrend.trend).toBe('stable');
    });
  });

  describe('Weekly and Monthly Aggregation', () => {
    it('should aggregate beta metrics correctly for weekly data', () => {
      const now = Date.now();
      const sessions: SessionSummaryV1[] = [];
      
      // Create sessions for 2 weeks
      for (let i = 0; i < 14; i++) {
        sessions.push({
          ts: now - i * 24 * 60 * 60 * 1000,
          comfort: 4,
          fatigue: 2,
          memx: { memoryStrainPct: 0.1 },
          schemaVersion: 1
        });
      }

      const daily = aggregator.aggregateDaily(sessions);
      const weekly = aggregator.aggregateWeekly(daily);

      expect(weekly).toHaveLength(2);
      expect(weekly[0].betaMetrics.sessionFrequency).toBeGreaterThan(0);
      expect(weekly[0].betaMetrics.retentionPct).toBeGreaterThan(0);
    });

    it('should aggregate beta metrics correctly for monthly data', () => {
      const now = Date.now();
      const sessions: SessionSummaryV1[] = [];
      
      // Create sessions for 2 months
      for (let i = 0; i < 60; i++) {
        sessions.push({
          ts: now - i * 24 * 60 * 60 * 1000,
          comfort: 4,
          fatigue: 2,
          memx: { memoryStrainPct: 0.1 },
          schemaVersion: 1
        });
      }

      const daily = aggregator.aggregateDaily(sessions);
      const monthly = aggregator.aggregateMonthly(daily);

      expect(monthly).toHaveLength(2);
      expect(monthly[0].betaMetrics.sessionFrequency).toBeGreaterThan(0);
      expect(monthly[0].betaMetrics.retentionPct).toBeGreaterThan(0);
    });
  });

  describe('Edge Cases', () => {
    it('should handle sessions with missing memx data', () => {
      const now = Date.now();
      const sessions: SessionSummaryV1[] = [
        { ts: now, medianF0: 150, comfort: 4, fatigue: 2, schemaVersion: 1 },
        { ts: now - 24 * 60 * 60 * 1000, medianF0: 150, comfort: 3, fatigue: 3, schemaVersion: 1 }
      ];

      const daily = aggregator.aggregateDaily(sessions);
      const latestDay = daily[daily.length - 1];

      expect(latestDay.betaMetrics.strainHealth).toBe('excellent');
      expect(latestDay.betaMetrics.strainPer100Min).toBe(0);
    });

    it('should handle sessions with invalid timestamps', () => {
      const sessions: SessionSummaryV1[] = [
        { ts: 0, medianF0: 150, comfort: 4, fatigue: 2, schemaVersion: 1 },
        { ts: -1, medianF0: 150, comfort: 3, fatigue: 3, schemaVersion: 1 }
      ];

      const daily = aggregator.aggregateDaily(sessions);
      
      // Should filter out invalid sessions
      expect(daily).toHaveLength(0);
    });

    it('should handle sessions with missing schema version', () => {
      const now = Date.now();
      const sessions: SessionSummaryV1[] = [
        { ts: now, medianF0: 150, comfort: 4, fatigue: 2 }, // missing schemaVersion
        { ts: now - 24 * 60 * 60 * 1000, medianF0: 150, comfort: 3, fatigue: 3, schemaVersion: 1 }
      ];

      const daily = aggregator.aggregateDaily(sessions);
      
      // Should filter out sessions without schema version
      expect(daily).toHaveLength(1);
    });

    it('should handle zero duration sessions (no NaN/∞)', () => {
      const now = Date.now();
      const sessions: SessionSummaryV1[] = [
        { 
          ts: now, 
          comfort: 4, 
          fatigue: 2, 
          memx: { memoryStrainPct: 0.1 },
          schemaVersion: 1 
        }
      ];

      // Mock zero duration
      const originalCalculateTotalDuration = aggregator['calculateTotalDuration'];
      aggregator['calculateTotalDuration'] = () => 0;

      const daily = aggregator.aggregateDaily(sessions);
      const latestDay = daily[daily.length - 1];

      expect(latestDay.betaMetrics.strainPer100Min).toBe(0);
      expect(isFinite(latestDay.betaMetrics.strainPer100Min)).toBe(true);

      // Restore original method
      aggregator['calculateTotalDuration'] = originalCalculateTotalDuration;
    });

    it('should handle sparse data (weeks with 0 sessions)', () => {
      const now = Date.now();
      const sessions: SessionSummaryV1[] = [
        { ts: now, medianF0: 150, comfort: 4, fatigue: 2, schemaVersion: 1 },
        { ts: now - 14 * 24 * 60 * 60 * 1000, medianF0: 150, comfort: 3, fatigue: 3, schemaVersion: 1 } // 2 weeks ago
      ];

      const daily = aggregator.aggregateDaily(sessions);
      const weekly = aggregator.aggregateWeekly(daily);

      // Should handle gaps without NaN/∞
      expect(weekly).toHaveLength(2);
      expect(weekly.every(w => isFinite(w.betaMetrics.retentionPct))).toBe(true);
      expect(weekly.every(w => isFinite(w.betaMetrics.sessionFrequency))).toBe(true);
    });

    it('should handle comfort/fatigue scale validation (1-5)', () => {
      const now = Date.now();
      const sessions: SessionSummaryV1[] = [
        { ts: now, medianF0: 150, comfort: 0, fatigue: 6, schemaVersion: 1 }, // Invalid values
        { ts: now - 24 * 60 * 60 * 1000, medianF0: 150, comfort: 3, fatigue: 3, schemaVersion: 1 }, // Valid
        { ts: now - 2 * 24 * 60 * 60 * 1000, medianF0: 150, comfort: 5, fatigue: 1, schemaVersion: 1 } // Valid
      ];

      const daily = aggregator.aggregateDaily(sessions);
      const latestDay = daily[daily.length - 1];

      // Should only use valid values (3, 5 for comfort; 3, 1 for fatigue)
      expect(latestDay.betaMetrics.comfortTrend.mean).toBeCloseTo(4.0, 1); // (3+5)/2
      expect(latestDay.betaMetrics.fatigueTrend.mean).toBeCloseTo(2.0, 1); // (3+1)/2
    });

    it('should handle timezone boundaries correctly', () => {
      // Test sessions near midnight
      const midnight = new Date('2024-01-01T00:00:00Z').getTime();
      const sessions: SessionSummaryV1[] = [
        { ts: midnight - 1000, medianF0: 150, comfort: 4, fatigue: 2, schemaVersion: 1 }, // Just before midnight
        { ts: midnight + 1000, medianF0: 150, comfort: 3, fatigue: 3, schemaVersion: 1 }  // Just after midnight
      ];

      const daily = aggregator.aggregateDaily(sessions);
      
      // Should create separate days
      expect(daily).toHaveLength(2);
      expect(daily[0].date).not.toBe(daily[1].date);
    });

    it('should handle very short sessions (minimum duration threshold)', () => {
      const now = Date.now();
      const sessions: SessionSummaryV1[] = [
        { 
          ts: now, medianF0: 150, comfort: 4, fatigue: 2, schemaVersion: 1 
        },
        { 
          ts: now - 24 * 60 * 60 * 1000, medianF0: 150, comfort: 3, fatigue: 3, schemaVersion: 1 
        }
      ];

      const daily = aggregator.aggregateDaily(sessions);
      const latestDay = daily[daily.length - 1];

      // Should handle short sessions gracefully
      expect(latestDay.betaMetrics.sessionFrequency).toBeGreaterThan(0);
      expect(isFinite(latestDay.betaMetrics.sessionFrequency)).toBe(true);
    });

    it('should handle install vs first-session date correctly', () => {
      const now = Date.now();
      const sessions: SessionSummaryV1[] = [
        { ts: now - 7 * 24 * 60 * 60 * 1000, medianF0: 150, comfort: 4, fatigue: 2, schemaVersion: 1 }, // First session 7 days ago
        { ts: now - 3 * 24 * 60 * 60 * 1000, medianF0: 150, comfort: 3, fatigue: 3, schemaVersion: 1 },  // Second session 3 days ago
        { ts: now, medianF0: 150, comfort: 5, fatigue: 1, schemaVersion: 1 } // Latest session today
      ];

      const daily = aggregator.aggregateDaily(sessions);
      const latestDay = daily[daily.length - 1];

      // Retention should be calculated from first session (7 days ago), not install date
      // 3 unique days out of 7 days since first session = ~43%
      expect(latestDay.betaMetrics.retentionPct).toBeCloseTo(3/7, 2);
    });
  });
});
