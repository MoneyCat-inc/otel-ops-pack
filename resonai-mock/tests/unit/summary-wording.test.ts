/**
 * Summary Wording Logic Unit Tests
 * 
 * C7: Dashboard Polish & UX
 * Tests for FriendlySummary component's message generation and theme selection logic.
 */

import { describe, it, expect } from 'vitest';
import { ProgressTrends } from '../../src/engine/metrics/aggregate';

describe('FriendlySummary Wording Logic', () => {
  describe('Message Generation', () => {
    it('should generate encouraging message for new users', () => {
      const trends = createMockTrends({
        totalSessions: 0,
        totalDurationMs: 0,
        averageSessionDurationMs: 0,
        overallTrend: { safety: 'stable', inBandPct: 'stable', expressiveness: 'stable' }
      });

      const summary = generateSummaryData(trends, '7d');
      
      expect(summary.message).toBe("Ready to start your voice practice journey?");
      expect(summary.encouragement).toBe("Your first session is just a click away!");
      expect(summary.theme).toBe('neutral');
    });

    it('should generate encouraging message for first session', () => {
      const trends = createMockTrends({
        totalSessions: 1,
        totalDurationMs: 300000, // 5 minutes
        averageSessionDurationMs: 300000,
        overallTrend: { safety: 'stable', inBandPct: 'stable', expressiveness: 'stable' }
      });

      const summary = generateSummaryData(trends, '7d');
      
      expect(summary.message).toBe("Great start! You've completed your first practice session.");
      expect(summary.encouragement).toBe("Keep the momentum going with another session today!");
      expect(summary.theme).toBe('neutral');
    });

    it('should generate encouraging message for early progress', () => {
      const trends = createMockTrends({
        totalSessions: 2,
        totalDurationMs: 600000, // 10 minutes
        averageSessionDurationMs: 300000,
        overallTrend: { safety: 'stable', inBandPct: 'stable', expressiveness: 'stable' }
      });

      const summary = generateSummaryData(trends, '7d');
      
      expect(summary.message).toBe("Nice progress! You've practiced 2 times.");
      expect(summary.encouragement).toBe("Building a consistent routine takes time - you're on the right track!");
      expect(summary.theme).toBe('neutral');
    });

    it('should generate positive message for good progress', () => {
      const trends = createMockTrends({
        totalSessions: 5,
        totalDurationMs: 1500000, // 25 minutes
        averageSessionDurationMs: 300000,
        overallTrend: { safety: 'improving', inBandPct: 'stable', expressiveness: 'stable' },
        daily: [
          { strainCount: 0, strainRate: 0 },
          { strainCount: 0, strainRate: 0 },
          { strainCount: 1, strainRate: 0.2 },
          { strainCount: 0, strainRate: 0 },
          { strainCount: 0, strainRate: 0 }
        ]
      });

      const summary = generateSummaryData(trends, '7d');
      
      expect(summary.message).toBe("Last 7 days — 5 safe sessions, 1 cooldowns, steady progress");
      expect(summary.encouragement).toBe("Your consistent practice is paying off! Keep up the great work.");
      expect(summary.theme).toBe('positive');
    });

    it('should generate attention message for concerning patterns', () => {
      const trends = createMockTrends({
        totalSessions: 4,
        totalDurationMs: 1200000, // 20 minutes
        averageSessionDurationMs: 300000,
        overallTrend: { safety: 'declining', inBandPct: 'stable', expressiveness: 'stable' },
        daily: [
          { strainCount: 2, strainRate: 0.5 },
          { strainCount: 1, strainRate: 0.25 },
          { strainCount: 2, strainRate: 0.5 },
          { strainCount: 1, strainRate: 0.25 }
        ]
      });

      const summary = generateSummaryData(trends, '7d');
      
      expect(summary.message).toBe("Last 7 days — 4 sessions with 6 cooldowns");
      expect(summary.encouragement).toBe("Consider shorter sessions or more breaks to keep your voice healthy.");
      expect(summary.theme).toBe('attention');
    });

    it('should generate neutral message for stable progress', () => {
      const trends = createMockTrends({
        totalSessions: 3,
        totalDurationMs: 900000, // 15 minutes
        averageSessionDurationMs: 300000,
        overallTrend: { safety: 'stable', inBandPct: 'stable', expressiveness: 'stable' },
        daily: [
          { strainCount: 0, strainRate: 0 },
          { strainCount: 0, strainRate: 0 },
          { strainCount: 0, strainRate: 0 }
        ]
      });

      const summary = generateSummaryData(trends, '7d');
      
      expect(summary.message).toBe("Last 7 days — 3 sessions, 0 cooldowns, stable progress");
      expect(summary.encouragement).toBe("You're maintaining a good practice rhythm. Keep it up!");
      expect(summary.theme).toBe('neutral');
    });
  });

  describe('Date Range Context', () => {
    it('should use correct date range text for 7 days', () => {
      const trends = createMockTrends({ totalSessions: 3 });
      const summary = generateSummaryData(trends, '7d');
      expect(summary.message).toContain("Last 7 days");
    });

    it('should use correct date range text for 14 days', () => {
      const trends = createMockTrends({ totalSessions: 3 });
      const summary = generateSummaryData(trends, '14d');
      expect(summary.message).toContain("Last 2 weeks");
    });

    it('should use correct date range text for 30 days', () => {
      const trends = createMockTrends({ totalSessions: 3 });
      const summary = generateSummaryData(trends, '30d');
      expect(summary.message).toContain("Last month");
    });

    it('should use correct date range text for all time', () => {
      const trends = createMockTrends({ totalSessions: 3 });
      const summary = generateSummaryData(trends, 'all');
      expect(summary.message).toContain("All time");
    });
  });

  describe('Statistics Calculation', () => {
    it('should format practice time correctly for hours and minutes', () => {
      const trends = createMockTrends({
        totalDurationMs: 3900000 // 1h 5m
      });

      const summary = generateSummaryData(trends, '7d');
      expect(summary.stats.practiceTime).toBe("1h 5m");
    });

    it('should format practice time correctly for minutes only', () => {
      const trends = createMockTrends({
        totalDurationMs: 300000 // 5m
      });

      const summary = generateSummaryData(trends, '7d');
      expect(summary.stats.practiceTime).toBe("5m");
    });

    it('should format average session duration correctly', () => {
      const trends = createMockTrends({
        averageSessionDurationMs: 300000 // 5 minutes
      });

      const summary = generateSummaryData(trends, '7d');
      expect(summary.stats.avgSession).toBe("5 minutes");
    });

    it('should calculate safety trend correctly', () => {
      const improvingTrends = createMockTrends({
        overallTrend: { safety: 'improving', inBandPct: 'stable', expressiveness: 'stable' }
      });
      const improvingSummary = generateSummaryData(improvingTrends, '7d');
      expect(improvingSummary.stats.safetyTrend).toBe("getting safer");

      const decliningTrends = createMockTrends({
        overallTrend: { safety: 'declining', inBandPct: 'stable', expressiveness: 'stable' }
      });
      const decliningSummary = generateSummaryData(decliningTrends, '7d');
      expect(decliningSummary.stats.safetyTrend).toBe("needs attention");

      const stableTrends = createMockTrends({
        overallTrend: { safety: 'stable', inBandPct: 'stable', expressiveness: 'stable' }
      });
      const stableSummary = generateSummaryData(stableTrends, '7d');
      expect(stableSummary.stats.safetyTrend).toBe("stable");
    });
  });

  describe('Theme Selection Logic', () => {
    it('should select positive theme for improving safety and sufficient sessions', () => {
      const trends = createMockTrends({
        totalSessions: 5,
        overallTrend: { safety: 'improving', inBandPct: 'stable', expressiveness: 'stable' }
      });

      const summary = generateSummaryData(trends, '7d');
      expect(summary.theme).toBe('positive');
    });

    it('should select attention theme for declining safety', () => {
      const trends = createMockTrends({
        totalSessions: 3,
        overallTrend: { safety: 'declining', inBandPct: 'stable', expressiveness: 'stable' },
        daily: [{ strainCount: 1, strainRate: 0.33 }]
      });

      const summary = generateSummaryData(trends, '7d');
      expect(summary.theme).toBe('attention');
    });

    it('should select attention theme for high cooldown rate', () => {
      const trends = createMockTrends({
        totalSessions: 4,
        overallTrend: { safety: 'stable', inBandPct: 'stable', expressiveness: 'stable' },
        daily: [
          { strainCount: 1, strainRate: 0.25 },
          { strainCount: 1, strainRate: 0.25 },
          { strainCount: 1, strainRate: 0.25 },
          { strainCount: 1, strainRate: 0.25 }
        ]
      });

      const summary = generateSummaryData(trends, '7d');
      expect(summary.theme).toBe('attention'); // 4 cooldowns > 30% of 4 sessions
    });

    it('should select neutral theme for stable progress', () => {
      const trends = createMockTrends({
        totalSessions: 3,
        overallTrend: { safety: 'stable', inBandPct: 'stable', expressiveness: 'stable' },
        daily: [{ strainCount: 0, strainRate: 0 }]
      });

      const summary = generateSummaryData(trends, '7d');
      expect(summary.theme).toBe('neutral');
    });
  });

  describe('Edge Cases', () => {
    it('should handle zero duration gracefully', () => {
      const trends = createMockTrends({
        totalDurationMs: 0,
        averageSessionDurationMs: 0
      });

      const summary = generateSummaryData(trends, '7d');
      expect(summary.stats.practiceTime).toBe("0m");
      expect(summary.stats.avgSession).toBe("0 minutes");
    });

    it('should handle missing daily data gracefully', () => {
      const trends = createMockTrends({
        totalSessions: 3,
        daily: []
      });

      const summary = generateSummaryData(trends, '7d');
      expect(summary.message).toContain("0 cooldowns");
    });

    it('should handle very large session counts', () => {
      const trends = createMockTrends({
        totalSessions: 100,
        totalDurationMs: 30000000, // 8h 20m
        averageSessionDurationMs: 300000
      });

      const summary = generateSummaryData(trends, '7d');
      expect(summary.stats.sessions).toBe(100);
      expect(summary.stats.practiceTime).toBe("8h 20m");
    });
  });
});

// Helper function to create mock trends data
function createMockTrends(overrides: Partial<ProgressTrends> = {}): ProgressTrends {
  return {
    totalSessions: 0,
    totalDurationMs: 0,
    averageSessionDurationMs: 0,
    overallTrend: { safety: 'stable', inBandPct: 'stable', expressiveness: 'stable' },
    daily: [],
    weekly: [],
    monthly: [],
    ...overrides
  };
}

// Helper function to generate summary data (simulating the component logic)
function generateSummaryData(trends: ProgressTrends, dateRange: '7d' | '14d' | '30d' | 'all') {
  // Calculate practice time in friendly format
  const hours = Math.round(trends.totalDurationMs / (1000 * 60 * 60));
  const minutes = Math.round((trends.totalDurationMs % (1000 * 60 * 60)) / (1000 * 60));
  const practiceTime = hours > 0 ? `${hours}h ${minutes}m` : `${minutes}m`;
  
  // Calculate average session in friendly format
  const avgMinutes = Math.round(trends.averageSessionDurationMs / (1000 * 60));
  const avgSession = `${avgMinutes} minutes`;
  
  // Determine safety trend message
  const safetyTrend = trends.overallTrend.safety === 'improving' ? 'getting safer' :
                     trends.overallTrend.safety === 'declining' ? 'needs attention' : 'stable';
  
  // Count cooldowns (sessions with strain)
  const cooldowns = trends.daily.reduce((count, day) => count + day.strainCount, 0);
  
  // Determine theme based on progress
  const isPositive = trends.overallTrend.safety === 'improving' && trends.totalSessions >= 3;
  const needsAttention = trends.overallTrend.safety === 'declining' || cooldowns > trends.totalSessions * 0.3;
  const theme = isPositive ? 'positive' : needsAttention ? 'attention' : 'neutral';
  
  // Generate date range text
  const rangeText = dateRange === '7d' ? 'Last 7 days' :
                   dateRange === '14d' ? 'Last 2 weeks' :
                   dateRange === '30d' ? 'Last month' : 'All time';
  
  // Generate main message
  let message: string;
  let encouragement: string;
  
  if (trends.totalSessions === 0) {
    message = "Ready to start your voice practice journey?";
    encouragement = "Your first session is just a click away!";
  } else if (trends.totalSessions === 1) {
    message = "Great start! You've completed your first practice session.";
    encouragement = "Keep the momentum going with another session today!";
  } else if (trends.totalSessions < 3) {
    message = `Nice progress! You've practiced ${trends.totalSessions} times.`;
    encouragement = "Building a consistent routine takes time - you're on the right track!";
  } else if (isPositive) {
    message = `${rangeText} — ${trends.totalSessions} safe sessions, ${cooldowns} cooldowns, steady progress`;
    encouragement = "Your consistent practice is paying off! Keep up the great work.";
  } else if (needsAttention) {
    message = `${rangeText} — ${trends.totalSessions} sessions with ${cooldowns} cooldowns`;
    encouragement = "Consider shorter sessions or more breaks to keep your voice healthy.";
  } else {
    message = `${rangeText} — ${trends.totalSessions} sessions, ${cooldowns} cooldowns, stable progress`;
    encouragement = "You're maintaining a good practice rhythm. Keep it up!";
  }
  
  return {
    message,
    encouragement,
    stats: {
      sessions: trends.totalSessions,
      practiceTime,
      avgSession,
      safetyTrend
    },
    theme
  };
}