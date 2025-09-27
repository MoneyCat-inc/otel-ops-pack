/**
 * IndexedDB Database Schema with MEMX Integration
 * 
 * PR-1: Extend session schema with MEMX aggregates
 * Extends existing SessionSummary with nullable MEMX fields
 */

import Dexie, { Table } from 'dexie';
import { MemxSession } from '../src/engine/memx/types';

// Existing Resonai session schema (from code map)
export interface SessionSummary {
  id?: number;
  ts: number;
  medianF0: number | null;
  inBandPct?: number;
  prosodyVar?: number;
  voicedTimePct?: number;
  jitterEma?: number;
  comfort?: 1 | 2 | 3 | 4 | 5;
  fatigue?: 1 | 2 | 3 | 4 | 5;
  euphoria?: 1 | 2 | 3 | 4 | 5;
  orb?: string;
  
  // PR-1: MEMX aggregates (nullable, additive)
  memx?: MemxSession;
}

// Flow definitions (existing)
export interface FlowV1 {
  version: 1;
  flowName: string;
  steps: Array<
    | { id: string; type: 'info'; title: string; content: string; next?: string }
    | {
        id: string;
        type: 'drill';
        title: string;
        copy: string;
        durationSec?: number;
        target?: {
          pitchRange?: ['low', 'high'];
          intonation?: 'rising' | 'falling';
          phraseText?: string;
        };
        metrics: Array<
          | 'voicedTimePct'
          | 'jitterEma'
          | 'timeInTargetPct'
          | 'smoothness'
          | 'endRiseDetected'
          | 'expressiveness'
        >;
        successThreshold?: Record<string, number | boolean>;
        next?: string;
      }
    | { id: string; type: 'reflection'; title: string; copy: string; prompts: string[] }
  >;
}

export class ResonaiDatabase extends Dexie {
  sessions!: Table<SessionSummary>;
  flows!: Table<FlowV1>;

  constructor() {
    super('ResonaiDatabase');
    
    // PR-1: Bump version to add MEMX fields
    this.version(2).stores({
      sessions: '++id, ts, medianF0, inBandPct, prosodyVar, voicedTimePct, jitterEma, comfort, fatigue, euphoria, orb, memx',
      flows: '++id, flowName, version',
    });
  }
}

export const db = new ResonaiDatabase();

// PR-1: Session management with MEMX support
export class SessionManager {
  /**
   * Save session with optional MEMX data
   */
  static async saveSession(session: SessionSummary): Promise<number> {
    return await db.sessions.add(session) as number;
  }

  /**
   * Update existing session with MEMX data
   */
  static async updateSessionWithMemx(id: number, memxData: MemxSession): Promise<void> {
    await db.sessions.update(id, { memx: memxData });
  }

  /**
   * Get session by ID
   */
  static async getSession(id: number): Promise<SessionSummary | undefined> {
    return await db.sessions.get(id);
  }

  /**
   * Get all sessions (for export)
   */
  static async getAllSessions(): Promise<SessionSummary[]> {
    return await db.sessions.toCollection().sortBy('ts');
  }

  /**
   * Get recent sessions with MEMX data
   */
  static async getRecentSessionsWithMemx(limit: number = 50): Promise<SessionSummary[]> {
    return await db.sessions
      .where('memx')
      .notEqual(undefined)
      .reverse()
      .limit(limit)
      .toArray();
  }

  /**
   * Delete session by ID
   */
  static async deleteSession(id: number): Promise<void> {
    await db.sessions.delete(id);
  }

  /**
   * Clear all sessions (for privacy)
   */
  static async clearAllSessions(): Promise<void> {
    await db.sessions.clear();
  }

  /**
   * Export sessions to JSON
   */
  static async exportSessions(): Promise<string> {
    const sessions = await this.getAllSessions();
    const exportData = {
      version: '1.0',
      exportedAt: new Date().toISOString(),
      sessionCount: sessions.length,
      sessions: sessions,
    };
    return JSON.stringify(exportData, null, 2);
  }

  /**
   * Export sessions with MEMX data only
   */
  static async exportMemxSessions(): Promise<string> {
    const sessions = await this.getRecentSessionsWithMemx();
    const memxData = sessions.map(session => ({
      id: session.id,
      ts: session.ts,
      memx: session.memx,
      duration: session.memx?.sessionDurationMs,
      strain: session.memx?.memoryStrainPct,
    }));
    
    const exportData = {
      version: '1.0',
      exportedAt: new Date().toISOString(),
      sessionCount: memxData.length,
      memxSessions: memxData,
    };
    return JSON.stringify(exportData, null, 2);
  }
}

// Flow management (existing functionality)
export class FlowManager {
  static async saveFlow(flow: FlowV1): Promise<number> {
    return await db.flows.add(flow) as number;
  }

  static async getFlow(id: number): Promise<FlowV1 | undefined> {
    return await db.flows.get(id);
  }

  static async getAllFlows(): Promise<FlowV1[]> {
    return await db.flows.toCollection().sortBy('flowName');
  }

  static async deleteFlow(id: number): Promise<void> {
    await db.flows.delete(id);
  }
}
