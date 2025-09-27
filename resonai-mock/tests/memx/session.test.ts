/**
 * MEMX Session Management Tests
 * 
 * PR-1: Unit tests for IDB migration and session management
 */

import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { ResonaiDatabase, SessionManager } from '../../lib/db';
import { MemxSessionManager, MemxExportData } from '../../src/engine/memx/session';
import { MemxFrame, MemxSession } from '../../src/engine/memx/types';

// Mock IndexedDB for testing
const mockDB = {
  sessions: new Map<number, any>(),
  flows: new Map<number, any>(),
  version: 2,
};

// Mock Dexie
vi.mock('dexie', () => ({
  default: class MockDexie {
    constructor() {
      this.version = vi.fn().mockReturnValue({
        stores: vi.fn().mockReturnValue({
          upgrade: vi.fn(),
        }),
      });
    }
  },
  Table: class MockTable {
    add = vi.fn((item) => {
      const id = mockDB.sessions.size + 1;
      mockDB.sessions.set(id, { ...item, id });
      return Promise.resolve(id);
    });
    
    update = vi.fn((id, updates) => {
      const existing = mockDB.sessions.get(id);
      if (existing) {
        mockDB.sessions.set(id, { ...existing, ...updates });
      }
      return Promise.resolve();
    });
    
    get = vi.fn((id) => Promise.resolve(mockDB.sessions.get(id)));
    
    orderBy = vi.fn().mockReturnValue({
      toArray: vi.fn(() => Promise.resolve(Array.from(mockDB.sessions.values()))),
      reverse: vi.fn().mockReturnThis(),
      limit: vi.fn().mockReturnThis(),
    });
    
    where = vi.fn().mockReturnValue({
      notEqual: vi.fn().mockReturnThis(),
      orderBy: vi.fn().mockReturnThis(),
      reverse: vi.fn().mockReturnThis(),
      limit: vi.fn().mockReturnThis(),
      toArray: vi.fn(() => Promise.resolve([])),
    });
    
    delete = vi.fn((id) => {
      mockDB.sessions.delete(id);
      return Promise.resolve();
    });
    
    clear = vi.fn(() => {
      mockDB.sessions.clear();
      return Promise.resolve();
    });
  },
}));

describe('MEMX Session Management', () => {
  let sessionManager: MemxSessionManager;

  beforeEach(() => {
    mockDB.sessions.clear();
    mockDB.flows.clear();
    sessionManager = new MemxSessionManager();
  });

  afterEach(() => {
    mockDB.sessions.clear();
    mockDB.flows.clear();
  });

  describe('Session Lifecycle', () => {
    it('should start a new session', async () => {
      const sessionId = await sessionManager.startSession();
      
      expect(sessionId).toBe(1);
      expect(sessionManager.isSessionActive()).toBe(true);
      expect(sessionManager.getCurrentSessionId()).toBe(1);
    });

    it('should end a session and save MEMX aggregates', async () => {
      const sessionId = await sessionManager.startSession();
      
      // Add some test frames to generate aggregates
      const testFrame: MemxFrame = {
        ts: Date.now(),
        wasmHeapBytes: 1024 * 1024, // 1MB
        sabUsedBytes: 512,
        sabCapacityBytes: 1024,
        workletLagMs: 10,
      };
      
      // This would normally be done by the instrumentation
      // For testing, we'll directly add to the store
      const store = sessionManager['store'];
      store.addFrame(testFrame);
      
      await sessionManager.endSession();
      
      expect(sessionManager.isSessionActive()).toBe(false);
      expect(sessionManager.getCurrentSessionId()).toBe(null);
      
      // Verify session was saved with MEMX data
      const savedSession = await SessionManager.getSession(sessionId);
      expect(savedSession?.memx).toBeDefined();
      expect(savedSession?.memx?.peakWasmHeapBytes).toBe(1024 * 1024);
    });

    it('should handle ending session when no session is active', async () => {
      await expect(sessionManager.endSession()).resolves.not.toThrow();
    });
  });

  describe('Export Functionality', () => {
    it('should export current session data', () => {
      const exportData = sessionManager.exportCurrentSession(60000); // 1 minute
      
      expect(exportData).toMatchObject({
        version: '1.0',
        exportedAt: expect.any(String),
        duration: 60000,
        frameCount: expect.any(Number),
        frames: expect.any(Array),
        session: expect.any(Object),
        strainEvents: expect.any(Array),
      });
    });

    it('should export session by ID', async () => {
      // Create a session with MEMX data
      const sessionId = await SessionManager.saveSession({
        ts: Date.now(),
        medianF0: null,
        memx: {
          peakWasmHeapBytes: 2048 * 1024,
          peakSabUsagePct: 75,
          avgWorkletLagMs: 15,
          p95WorkletLagMs: 30,
          memoryStrainPct: 25,
          frameCount: 100,
          sessionDurationMs: 60000,
        },
      });

      const exportData = await sessionManager.exportSessionById(sessionId);
      
      expect(exportData).not.toBeNull();
      expect(exportData?.session.peakWasmHeapBytes).toBe(2048 * 1024);
      expect(exportData?.session.peakSabUsagePct).toBe(75);
    });

    it('should return null for non-existent session', async () => {
      const exportData = await sessionManager.exportSessionById(999);
      expect(exportData).toBeNull();
    });

    it('should return null for session without MEMX data', async () => {
      const sessionId = await SessionManager.saveSession({
        ts: Date.now(),
        medianF0: null,
        // No memx field
      });

      const exportData = await sessionManager.exportSessionById(sessionId);
      expect(exportData).toBeNull();
    });
  });

  describe('Session Statistics', () => {
    it('should calculate session statistics', async () => {
      // Create test sessions
      await SessionManager.saveSession({
        ts: Date.now() - 1000,
        medianF0: null,
        memx: {
          peakWasmHeapBytes: 1024 * 1024,
          memoryStrainPct: 30,
          frameCount: 50,
          sessionDurationMs: 30000,
        },
      });

      await SessionManager.saveSession({
        ts: Date.now() - 2000,
        medianF0: null,
        memx: {
          peakWasmHeapBytes: 2048 * 1024,
          memoryStrainPct: 70,
          frameCount: 100,
          sessionDurationMs: 60000,
        },
      });

      await SessionManager.saveSession({
        ts: Date.now() - 3000,
        medianF0: null,
        // No MEMX data
      });

      const stats = await sessionManager.getSessionStats();
      
      expect(stats.totalSessions).toBe(3);
      expect(stats.memxEnabledSessions).toBe(2);
      expect(stats.memxEnabledPct).toBe(66.67); // 2/3 * 100
      expect(stats.averageStrain).toBe(50); // (30 + 70) / 2
      expect(stats.peakStrain).toBe(70);
      expect(stats.peakStrainSessionId).toBe(2);
    });

    it('should handle empty database', async () => {
      const stats = await sessionManager.getSessionStats();
      
      expect(stats.totalSessions).toBe(0);
      expect(stats.memxEnabledSessions).toBe(0);
      expect(stats.memxEnabledPct).toBe(0);
      expect(stats.averageStrain).toBe(0);
      expect(stats.peakStrain).toBe(0);
      expect(stats.peakStrainSessionId).toBeUndefined();
    });
  });

  describe('Data Management', () => {
    it('should clear all MEMX data', async () => {
      // Create test data
      await SessionManager.saveSession({
        ts: Date.now(),
        medianF0: null,
        memx: { peakWasmHeapBytes: 1024 * 1024 },
      });

      expect(mockDB.sessions.size).toBe(1);

      await sessionManager.clearAllMemxData();
      
      expect(mockDB.sessions.size).toBe(0);
    });

    it('should get recent sessions with MEMX data', async () => {
      // Create test sessions
      await SessionManager.saveSession({
        ts: Date.now() - 1000,
        medianF0: null,
        memx: { peakWasmHeapBytes: 1024 * 1024 },
      });

      await SessionManager.saveSession({
        ts: Date.now() - 2000,
        medianF0: null,
        // No MEMX data
      });

      const recentSessions = await sessionManager.getRecentMemxSessions(10);
      
      expect(recentSessions).toHaveLength(1);
      expect(recentSessions[0].memx).toBeDefined();
    });
  });
});

describe('Database Schema Migration', () => {
  it('should handle database version upgrade', () => {
    const db = new ResonaiDatabase();
    expect(db.version).toBeDefined();
  });

  it('should save session with MEMX data', async () => {
    const sessionId = await SessionManager.saveSession({
      ts: Date.now(),
      medianF0: 200,
      memx: {
        peakWasmHeapBytes: 1024 * 1024,
        peakSabUsagePct: 50,
        avgWorkletLagMs: 10,
        p95WorkletLagMs: 20,
        memoryStrainPct: 25,
        frameCount: 100,
        sessionDurationMs: 60000,
      },
    });

    const savedSession = await SessionManager.getSession(sessionId);
    
    expect(savedSession?.memx).toBeDefined();
    expect(savedSession?.memx?.peakWasmHeapBytes).toBe(1024 * 1024);
    expect(savedSession?.memx?.memoryStrainPct).toBe(25);
  });

  it('should update existing session with MEMX data', async () => {
    const sessionId = await SessionManager.saveSession({
      ts: Date.now(),
      medianF0: 200,
      // No MEMX data initially
    });

    const memxData: MemxSession = {
      peakWasmHeapBytes: 2048 * 1024,
      peakSabUsagePct: 75,
      avgWorkletLagMs: 15,
      p95WorkletLagMs: 30,
      memoryStrainPct: 40,
      frameCount: 200,
      sessionDurationMs: 120000,
    };

    await SessionManager.updateSessionWithMemx(sessionId, memxData);

    const updatedSession = await SessionManager.getSession(sessionId);
    
    expect(updatedSession?.memx).toEqual(memxData);
  });
});

describe('Export Data Format', () => {
  it('should format export data correctly', () => {
    const exportData: MemxExportData = {
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
  });
});
