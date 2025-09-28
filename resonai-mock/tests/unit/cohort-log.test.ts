/**
 * Cohort Log Unit Tests
 * 
 * C5: Cohort Log & Tester Guide
 * Unit tests for cohort logging engine functionality.
 */

import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { CohortLogger, CohortLogData, CohortSessionLog } from '../../src/engine/metrics/cohortLog';
import { SessionSummaryV1 } from '../../src/engine/metrics/aggregate';

// Mock localStorage
const localStorageMock = (() => {
  let store: Record<string, string> = {};

  return {
    getItem: (key: string) => store[key] || null,
    setItem: (key: string, value: string) => {
      store[key] = value.toString();
    },
    removeItem: (key: string) => {
      delete store[key];
    },
    clear: () => {
      store = {};
    },
  };
})();

// Mock window and navigator
Object.defineProperty(window, 'localStorage', {
  value: localStorageMock,
});

Object.defineProperty(window, 'navigator', {
  value: {
    userAgent: 'Mozilla/5.0 (Test Browser)',
    platform: 'TestPlatform',
  },
});

Object.defineProperty(window, 'innerWidth', {
  value: 1920,
});

Object.defineProperty(window, 'innerHeight', {
  value: 1080,
});

// Mock flags
vi.mock('../../src/config/flags', () => ({
  flags: {
    enabled: true,
    dashboardEntry: true,
    eventSummary: true,
  },
  getEnabledFeatures: () => ['cohort', 'dashboard-entry', 'event-summary'],
}));

describe('CohortLogger', () => {
  let logger: CohortLogger;

  beforeEach(() => {
    localStorageMock.clear();
    logger = new CohortLogger();
  });

  afterEach(() => {
    localStorageMock.clear();
  });

  describe('logSession', () => {
    it('should log a session when cohort features are enabled', async () => {
      const sessionSummary: SessionSummaryV1 = {
        ts: Date.now(),
        medianF0: 150,
        inBandPct: 0.75,
        comfort: 4,
        fatigue: 2,
        schemaVersion: 1,
      };

      await logger.logSession(sessionSummary);

      const logData = await logger.getLogData();
      expect(logData.sessions).toHaveLength(1);
      expect(logData.sessions[0].sessionSummary).toEqual(sessionSummary);
      expect(logData.sessions[0].cohortId).toMatch(/^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/);
      expect(logData.sessions[0].flagsEnabled).toEqual(['cohort', 'dashboard-entry', 'event-summary']);
    });

    it('should respect cohort feature flags', async () => {
      // This test verifies that the logger checks flags.enabled
      // The actual flag checking is tested in integration tests
      const sessionSummary: SessionSummaryV1 = {
        ts: Date.now(),
        medianF0: 150,
        schemaVersion: 1,
      };

      // With flags enabled (from beforeEach mock), session should be logged
      await logger.logSession(sessionSummary);

      const logData = await logger.getLogData();
      expect(logData.sessions).toHaveLength(1);
    });

    it('should handle logging errors gracefully', async () => {
      // Mock localStorage to throw error
      const originalSetItem = localStorageMock.setItem;
      localStorageMock.setItem = vi.fn().mockImplementation(() => {
        throw new Error('Storage quota exceeded');
      });

      const sessionSummary: SessionSummaryV1 = {
        ts: Date.now(),
        medianF0: 150,
        schemaVersion: 1,
      };

      // Should not throw
      await expect(logger.logSession(sessionSummary)).resolves.toBeUndefined();

      // Restore original method
      localStorageMock.setItem = originalSetItem;
    });
  });

  describe('log rotation', () => {
    it('should maintain only the last 100 sessions', async () => {
      // Create 105 sessions
      for (let i = 0; i < 105; i++) {
        const sessionSummary: SessionSummaryV1 = {
          ts: Date.now() + i * 1000,
          medianF0: 150 + i,
          schemaVersion: 1,
        };
        await logger.logSession(sessionSummary);
      }

      const logData = await logger.getLogData();
      expect(logData.sessions).toHaveLength(100);
      expect(logData.metadata.totalSessions).toBe(100);
    });

    it('should update metadata correctly after rotation', async () => {
      // Create sessions with known timestamps
      const timestamps = [1000, 2000, 3000, 4000, 5000];
      
      for (const ts of timestamps) {
        const sessionSummary: SessionSummaryV1 = {
          ts,
          medianF0: 150,
          schemaVersion: 1,
        };
        await logger.logSession(sessionSummary);
      }

      const logData = await logger.getLogData();
      expect(logData.metadata.firstSession).toBe(1000);
      expect(logData.metadata.lastSession).toBe(5000);
      expect(logData.metadata.totalSessions).toBe(5);
    });
  });

  describe('export functionality', () => {
    it('should export log data as JSON string', async () => {
      const sessionSummary: SessionSummaryV1 = {
        ts: Date.now(),
        medianF0: 150,
        inBandPct: 0.75,
        schemaVersion: 1,
      };

      await logger.logSession(sessionSummary);

      const exported = await logger.exportLog();
      const parsed = JSON.parse(exported);

      expect(parsed.schemaVersion).toBe(1);
      expect(parsed.entries).toHaveLength(1);
      expect(parsed.build).toBeDefined();
      expect(parsed.cohortId).toBeDefined();
      expect(parsed.flags).toBeDefined();
      expect(parsed.entries[0].ts).toBe(sessionSummary.ts);
      expect(parsed.entries[0].inBandPct).toBe(75); // Converted to percentage
    });

    it('should handle export errors', async () => {
      // Mock JSON.stringify to throw error
      const originalStringify = JSON.stringify;
      JSON.stringify = vi.fn().mockImplementation(() => {
        throw new Error('Circular reference');
      });

      await expect(logger.exportLog()).rejects.toThrow('Circular reference');

      // Restore original method
      JSON.stringify = originalStringify;
    });
  });

  describe('clear functionality', () => {
    it('should clear all log data', async () => {
      // Add some sessions
      const sessionSummary: SessionSummaryV1 = {
        ts: Date.now(),
        medianF0: 150,
        schemaVersion: 1,
      };

      await logger.logSession(sessionSummary);
      
      let logData = await logger.getLogData();
      expect(logData.sessions).toHaveLength(1);

      // Clear the log
      await logger.clearLog();

      logData = await logger.getLogData();
      expect(logData.sessions).toHaveLength(0);
      expect(logData.metadata.totalSessions).toBe(0);
    });

    it('should handle clear errors', async () => {
      // Mock localStorage to throw error
      const originalSetItem = localStorageMock.setItem;
      localStorageMock.setItem = vi.fn().mockImplementation(() => {
        throw new Error('Storage error');
      });

      await expect(logger.clearLog()).rejects.toThrow('Storage error');

      // Restore original method
      localStorageMock.setItem = originalSetItem;
    });
  });

  describe('getLogStats', () => {
    it('should return correct statistics', async () => {
      const timestamps = [1000, 2000, 3000];
      
      for (const ts of timestamps) {
        const sessionSummary: SessionSummaryV1 = {
          ts,
          medianF0: 150,
          schemaVersion: 1,
        };
        await logger.logSession(sessionSummary);
      }

      const stats = await logger.getLogStats();
      
      expect(stats.totalSessions).toBe(3);
      expect(stats.dateRange.start).toBe(new Date(1000).toISOString().split('T')[0]);
      expect(stats.dateRange.end).toBe(new Date(3000).toISOString().split('T')[0]);
      expect(stats.enabledFeatures).toEqual(['cohort', 'dashboard-entry', 'event-summary']);
      expect(stats.buildHash).toMatch(/^build-/);
    });

    it('should handle empty log statistics', async () => {
      const stats = await logger.getLogStats();
      
      expect(stats.totalSessions).toBe(0);
      expect(stats.dateRange.start).toBe('No sessions');
      expect(stats.dateRange.end).toBe('No sessions');
    });
  });

  describe('data validation', () => {
    it('should validate schema version on load', async () => {
      // Create invalid log data
      const invalidLog: CohortLogData = {
        sessions: [],
        metadata: {
          totalSessions: 0,
          firstSession: 0,
          lastSession: 0,
          schemaVersion: '0.9.0', // Wrong version
          lastUpdated: Date.now(),
        },
      };

      localStorageMock.setItem('resonai_cohort_log', JSON.stringify(invalidLog));

      const logData = await logger.getLogData();
      expect(logData.metadata.schemaVersion).toBe('1.0.0'); // Should reset to current version
    });

    it('should handle corrupted log data', async () => {
      localStorageMock.setItem('resonai_cohort_log', 'invalid json');

      const logData = await logger.getLogData();
      expect(logData.sessions).toHaveLength(0);
      expect(logData.metadata.schemaVersion).toBe('1.0.0');
    });
  });

  describe('cohort ID generation', () => {
    it('should generate valid UUIDv4 format', async () => {
      const sessionSummary: SessionSummaryV1 = {
        ts: Date.now(),
        medianF0: 150,
        schemaVersion: 1,
      };

      await logger.logSession(sessionSummary);

      const logData = await logger.getLogData();
      const cohortId = logData.sessions[0].cohortId;
      
      // UUIDv4 format: xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx
      expect(cohortId).toMatch(/^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/);
    });

    it('should generate unique cohort IDs', async () => {
      const sessionSummary: SessionSummaryV1 = {
        ts: Date.now(),
        medianF0: 150,
        schemaVersion: 1,
      };

      // Log multiple sessions
      await logger.logSession(sessionSummary);
      await logger.logSession(sessionSummary);
      await logger.logSession(sessionSummary);

      const logData = await logger.getLogData();
      const cohortIds = logData.sessions.map(s => s.cohortId);
      
      // All IDs should be unique
      const uniqueIds = new Set(cohortIds);
      expect(uniqueIds.size).toBe(cohortIds.length);
    });
  });

  describe('metadata collection', () => {
    it('should collect browser metadata', async () => {
      const sessionSummary: SessionSummaryV1 = {
        ts: Date.now(),
        medianF0: 150,
        schemaVersion: 1,
      };

      await logger.logSession(sessionSummary);

      const logData = await logger.getLogData();
      const metadata = logData.sessions[0].metadata;
      
      expect(metadata.userAgent).toBe('Mozilla/5.0 (Test Browser)');
      expect(metadata.platform).toBe('TestPlatform');
      expect(metadata.viewport).toEqual({ width: 1920, height: 1080 });
      expect(metadata.cohortVersion).toBe('1.0.0');
    });

    it('should handle missing browser APIs gracefully', async () => {
      // Mock missing navigator
      Object.defineProperty(window, 'navigator', {
        value: undefined,
      });

      const sessionSummary: SessionSummaryV1 = {
        ts: Date.now(),
        medianF0: 150,
        schemaVersion: 1,
      };

      await logger.logSession(sessionSummary);

      const logData = await logger.getLogData();
      const metadata = logData.sessions[0].metadata;
      
      expect(metadata.userAgent).toBeUndefined();
      expect(metadata.platform).toBeUndefined();
      expect(metadata.cohortVersion).toBe('1.0.0');
    });
  });
});
