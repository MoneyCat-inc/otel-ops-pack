/**
 * Export Schema Validation Tests
 * 
 * C2: Export & Delete UX
 * Tests for export data structure, schema validation, and data integrity.
 */

import { describe, it, expect, beforeEach } from 'vitest';

// Mock session data structure
interface MockSession {
  id: number;
  ts: number;
  medianF0: number | null;
  inBandPct?: number;
  prosodyVar?: number;
  voicedTimePct?: number;
  jitterEma?: number;
  comfort?: number;
  fatigue?: number;
  euphoria?: number;
  orb?: string;
  memx?: {
    memoryStrainPct?: number;
    bucketBias?: {
      front: number;
      central: number;
      back: number;
    };
  };
  schemaVersion: number;
}

// Export data structure
interface ExportData {
  schemaVersion: number;
  exportedAt: string;
  build: string;
  appVersion: string;
  sessions: MockSession[];
  summary: {
    totalSessions: number;
    dateRange: {
      start: string | null;
      end: string | null;
    };
    metrics: {
      averageInBandPct: number;
      averageExpressiveness: number;
      averageComfort: number;
    };
  };
}

describe('Export Schema Validation', () => {
  let mockSessions: MockSession[];

  beforeEach(() => {
    mockSessions = [
      {
        id: 1,
        ts: new Date('2024-01-01').getTime(),
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
        schemaVersion: 1
      },
      {
        id: 2,
        ts: new Date('2024-01-02').getTime(),
        medianF0: 160,
        inBandPct: 0.8,
        prosodyVar: 0.6,
        voicedTimePct: 0.9,
        jitterEma: 0.08,
        comfort: 4,
        fatigue: 1,
        euphoria: 5,
        orb: 'practice',
        memx: {
          memoryStrainPct: 0.03,
          bucketBias: {
            front: 0.5,
            central: 0.3,
            back: 0.2
          }
        },
        schemaVersion: 1
      }
    ];
  });

  describe('Export Data Structure', () => {
    it('should create valid export data with all required fields', () => {
      const exportData = createExportData(mockSessions);

      // Check top-level structure
      expect(exportData).toHaveProperty('schemaVersion');
      expect(exportData).toHaveProperty('exportedAt');
      expect(exportData).toHaveProperty('build');
      expect(exportData).toHaveProperty('appVersion');
      expect(exportData).toHaveProperty('sessions');
      expect(exportData).toHaveProperty('summary');

      // Check data types
      expect(typeof exportData.schemaVersion).toBe('number');
      expect(typeof exportData.exportedAt).toBe('string');
      expect(typeof exportData.build).toBe('string');
      expect(typeof exportData.appVersion).toBe('string');
      expect(Array.isArray(exportData.sessions)).toBe(true);
      expect(typeof exportData.summary).toBe('object');
    });

    it('should include correct schema version', () => {
      const exportData = createExportData(mockSessions);
      expect(exportData.schemaVersion).toBe(1);
    });

    it('should include valid timestamp', () => {
      const exportData = createExportData(mockSessions);
      const exportedAt = new Date(exportData.exportedAt);
      expect(exportedAt).toBeInstanceOf(Date);
      expect(exportedAt.getTime()).toBeLessThanOrEqual(Date.now());
    });

    it('should include build and app version', () => {
      const exportData = createExportData(mockSessions);
      expect(exportData.build).toMatch(/^C2-data-control-v\d+$/);
      expect(exportData.appVersion).toMatch(/^\d+\.\d+\.\d+$/);
    });
  });

  describe('Sessions Data', () => {
    it('should include all sessions in export', () => {
      const exportData = createExportData(mockSessions);
      expect(exportData.sessions).toHaveLength(2);
      expect(exportData.sessions[0]).toEqual(mockSessions[0]);
      expect(exportData.sessions[1]).toEqual(mockSessions[1]);
    });

    it('should handle empty sessions array', () => {
      const exportData = createExportData([]);
      expect(exportData.sessions).toHaveLength(0);
      expect(exportData.summary.totalSessions).toBe(0);
    });

    it('should preserve all session fields', () => {
      const exportData = createExportData(mockSessions);
      const session = exportData.sessions[0];

      expect(session).toHaveProperty('id');
      expect(session).toHaveProperty('ts');
      expect(session).toHaveProperty('medianF0');
      expect(session).toHaveProperty('inBandPct');
      expect(session).toHaveProperty('prosodyVar');
      expect(session).toHaveProperty('voicedTimePct');
      expect(session).toHaveProperty('jitterEma');
      expect(session).toHaveProperty('comfort');
      expect(session).toHaveProperty('fatigue');
      expect(session).toHaveProperty('euphoria');
      expect(session).toHaveProperty('orb');
      expect(session).toHaveProperty('memx');
      expect(session).toHaveProperty('schemaVersion');
    });

    it('should not include audio or blob data', () => {
      const sessionsWithAudio = [
        ...mockSessions,
        {
          ...mockSessions[0],
          id: 3,
          audioBlob: new Blob(['fake audio data']), // This should be excluded
          audioData: 'base64encodedaudio', // This should be excluded
          recording: 'audio-file.wav' // This should be excluded
        } as any
      ];

      const exportData = createExportData(sessionsWithAudio);
      const sessionWithAudio = exportData.sessions.find(s => s.id === 3);

      expect(sessionWithAudio).not.toHaveProperty('audioBlob');
      expect(sessionWithAudio).not.toHaveProperty('audioData');
      expect(sessionWithAudio).not.toHaveProperty('recording');
    });
  });

  describe('Summary Statistics', () => {
    it('should calculate correct total sessions', () => {
      const exportData = createExportData(mockSessions);
      expect(exportData.summary.totalSessions).toBe(2);
    });

    it('should calculate correct date range', () => {
      const exportData = createExportData(mockSessions);
      expect(exportData.summary.dateRange.start).toBe('2024-01-01T00:00:00.000Z');
      expect(exportData.summary.dateRange.end).toBe('2024-01-02T00:00:00.000Z');
    });

    it('should handle single session date range', () => {
      const singleSession = [mockSessions[0]];
      const exportData = createExportData(singleSession);
      expect(exportData.summary.dateRange.start).toBe(exportData.summary.dateRange.end);
    });

    it('should handle empty sessions date range', () => {
      const exportData = createExportData([]);
      expect(exportData.summary.dateRange.start).toBeNull();
      expect(exportData.summary.dateRange.end).toBeNull();
    });

    it('should calculate correct average metrics', () => {
      const exportData = createExportData(mockSessions);
      
      // Average inBandPct: (0.7 + 0.8) / 2 = 0.75
      expect(exportData.summary.metrics.averageInBandPct).toBeCloseTo(0.75);
      
      // Average expressiveness: (0.5 + 0.6) / 2 = 0.55
      expect(exportData.summary.metrics.averageExpressiveness).toBeCloseTo(0.55);
      
      // Average comfort: (3 + 4) / 2 = 3.5
      expect(exportData.summary.metrics.averageComfort).toBeCloseTo(3.5);
    });

    it('should handle sessions with missing metrics', () => {
      const sessionsWithMissing = [
        {
          ...mockSessions[0],
          inBandPct: undefined,
          prosodyVar: undefined,
          comfort: undefined
        },
        mockSessions[1]
      ];

      const exportData = createExportData(sessionsWithMissing);
      
      // Should only calculate averages from sessions with data
      expect(exportData.summary.metrics.averageInBandPct).toBeCloseTo(0.8); // Only second session
      expect(exportData.summary.metrics.averageExpressiveness).toBeCloseTo(0.6); // Only second session
      expect(exportData.summary.metrics.averageComfort).toBeCloseTo(4); // Only second session
    });

    it('should handle all sessions with missing metrics', () => {
      const sessionsWithMissing = [
        {
          ...mockSessions[0],
          inBandPct: undefined,
          prosodyVar: undefined,
          comfort: undefined
        }
      ];

      const exportData = createExportData(sessionsWithMissing);
      
      // Should default to 0 when no data available
      expect(exportData.summary.metrics.averageInBandPct).toBe(0);
      expect(exportData.summary.metrics.averageExpressiveness).toBe(0);
      expect(exportData.summary.metrics.averageComfort).toBe(0);
    });
  });

  describe('Data Integrity', () => {
    it('should produce valid JSON', () => {
      const exportData = createExportData(mockSessions);
      const jsonString = JSON.stringify(exportData);
      
      expect(() => JSON.parse(jsonString)).not.toThrow();
      
      const parsed = JSON.parse(jsonString);
      expect(parsed).toEqual(exportData);
    });

    it('should handle large datasets efficiently', () => {
      const largeSessions = Array.from({ length: 1000 }, (_, i) => ({
        ...mockSessions[0],
        id: i + 1,
        ts: new Date('2024-01-01').getTime() + i * 24 * 60 * 60 * 1000
      }));

      const start = Date.now();
      const exportData = createExportData(largeSessions);
      const end = Date.now();

      expect(exportData.sessions).toHaveLength(1000);
      expect(end - start).toBeLessThan(100); // Should complete quickly
    });

    it('should maintain data precision', () => {
      const preciseSession = {
        ...mockSessions[0],
        inBandPct: 0.123456789,
        prosodyVar: 0.987654321,
        jitterEma: 0.000123456
      };

      const exportData = createExportData([preciseSession]);
      const jsonString = JSON.stringify(exportData);
      const parsed = JSON.parse(jsonString);

      expect(parsed.sessions[0].inBandPct).toBeCloseTo(0.123456789, 9);
      expect(parsed.sessions[0].prosodyVar).toBeCloseTo(0.987654321, 9);
      expect(parsed.sessions[0].jitterEma).toBeCloseTo(0.000123456, 9);
    });
  });

  describe('Edge Cases', () => {
    it('should handle null values gracefully', () => {
      const sessionWithNulls = {
        ...mockSessions[0],
        medianF0: null,
        orb: null
      };

      const exportData = createExportData([sessionWithNulls]);
      expect(exportData.sessions[0].medianF0).toBeNull();
      expect(exportData.sessions[0].orb).toBeNull();
    });

    it('should handle extreme values', () => {
      const extremeSession = {
        ...mockSessions[0],
        inBandPct: 1.0,
        prosodyVar: 0.0,
        comfort: 5,
        fatigue: 1,
        euphoria: 5
      };

      const exportData = createExportData([extremeSession]);
      expect(exportData.sessions[0].inBandPct).toBe(1.0);
      expect(exportData.sessions[0].prosodyVar).toBe(0.0);
      expect(exportData.sessions[0].comfort).toBe(5);
    });

    it('should handle sessions with different schema versions', () => {
      const mixedSessions = [
        mockSessions[0],
        {
          ...mockSessions[1],
          schemaVersion: 2 // Different version
        }
      ];

      const exportData = createExportData(mixedSessions);
      expect(exportData.sessions[0].schemaVersion).toBe(1);
      expect(exportData.sessions[1].schemaVersion).toBe(2);
    });
  });

  describe('File Naming', () => {
    it('should generate correct filename format', () => {
      const filename = generateFilename(1, new Date('2024-01-15'));
      expect(filename).toBe('resonai_sessions_v1_2024-01-15.json');
    });

    it('should handle different schema versions in filename', () => {
      const filename = generateFilename(2, new Date('2024-12-31'));
      expect(filename).toBe('resonai_sessions_v2_2024-12-31.json');
    });
  });
});

// Helper functions
function createExportData(sessions: MockSession[]): ExportData {
  const now = new Date();
  
  return {
    schemaVersion: 1,
    exportedAt: now.toISOString(),
    build: 'C2-data-control-v1',
    appVersion: '1.0.0',
    sessions: sessions.map(session => {
      // Remove any audio/blob data
      const { audioBlob, audioData, recording, ...cleanSession } = session as any;
      return cleanSession;
    }),
    summary: {
      totalSessions: sessions.length,
      dateRange: {
        start: sessions.length > 0 ? new Date(Math.min(...sessions.map(s => s.ts))).toISOString() : null,
        end: sessions.length > 0 ? new Date(Math.max(...sessions.map(s => s.ts))).toISOString() : null
      },
      metrics: {
        averageInBandPct: sessions.length > 0 
          ? sessions.reduce((sum, s) => sum + (s.inBandPct || 0), 0) / sessions.length 
          : 0,
        averageExpressiveness: sessions.length > 0 
          ? sessions.reduce((sum, s) => sum + (s.prosodyVar || 0), 0) / sessions.length 
          : 0,
        averageComfort: sessions.length > 0 
          ? sessions.reduce((sum, s) => sum + (s.comfort || 0), 0) / sessions.length 
          : 0
      }
    }
  };
}

function generateFilename(schemaVersion: number, date: Date): string {
  return `resonai_sessions_v${schemaVersion}_${date.toISOString().split('T')[0]}.json`;
}
