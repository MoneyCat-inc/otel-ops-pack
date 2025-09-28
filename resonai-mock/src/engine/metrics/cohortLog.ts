/**
 * Cohort Log Engine
 * 
 * C5: Cohort Log & Tester Guide
 * Lightweight local cohort logging with bounded JSON storage and rotation.
 * All operations are local-only with no network calls.
 */

import { SessionSummaryV1 } from './aggregate';
import { flags, getEnabledFeatures } from '../../config/flags';

export interface CohortSessionLog {
  cohortId: string;           // Local UUIDv4 for this session
  timestamp: number;          // Session timestamp
  buildHash: string;          // Build hash for version tracking
  flagsEnabled: string[];     // Array of enabled feature flags
  sessionSummary: SessionSummaryV1;
  metadata: {
    userAgent?: string;
    viewport?: { width: number; height: number };
    platform?: string;
    cohortVersion: string;    // Schema version
  };
}

export interface CohortLogData {
  sessions: CohortSessionLog[];
  metadata: {
    totalSessions: number;
    firstSession: number;
    lastSession: number;
    schemaVersion: string;
    lastUpdated: number;
  };
}

export class CohortLogger {
  private readonly STORAGE_KEY = 'resonai_cohort_log';
  private readonly MAX_SESSIONS = 100;
  private readonly SCHEMA_VERSION = '1.0.0';
  private readonly BUILD_HASH = this.getBuildHash();

  /**
   * Log a session to the cohort log
   */
  async logSession(sessionSummary: SessionSummaryV1): Promise<void> {
    try {
      // Only log if cohort features are enabled
      if (!flags.enabled) {
        return;
      }

      const cohortLog = await this.loadLog();
      
      const sessionLog: CohortSessionLog = {
        cohortId: this.generateCohortId(),
        timestamp: sessionSummary.ts,
        buildHash: this.BUILD_HASH,
        flagsEnabled: getEnabledFeatures(),
        sessionSummary,
        metadata: {
          userAgent: typeof navigator !== 'undefined' ? navigator.userAgent : undefined,
          viewport: typeof window !== 'undefined' ? {
            width: window.innerWidth,
            height: window.innerHeight
          } : undefined,
          platform: typeof navigator !== 'undefined' ? navigator.platform : undefined,
          cohortVersion: this.SCHEMA_VERSION
        }
      };

      // Add to log
      cohortLog.sessions.push(sessionLog);

      // Rotate if needed
      if (cohortLog.sessions.length > this.MAX_SESSIONS) {
        cohortLog.sessions = cohortLog.sessions.slice(-this.MAX_SESSIONS);
      }

      // Update metadata
      cohortLog.metadata = {
        totalSessions: cohortLog.sessions.length,
        firstSession: Math.min(...cohortLog.sessions.map(s => s.timestamp)),
        lastSession: Math.max(...cohortLog.sessions.map(s => s.timestamp)),
        schemaVersion: this.SCHEMA_VERSION,
        lastUpdated: Date.now()
      };

      await this.saveLog(cohortLog);
    } catch (error) {
      console.warn('CohortLogger: Failed to log session', error);
      // Fail silently - don't break the main app flow
    }
  }

  /**
   * Get the current cohort log data
   */
  async getLogData(): Promise<CohortLogData> {
    return await this.loadLog();
  }

  /**
   * Export log data as JSON string
   */
  async exportLog(): Promise<string> {
    const logData = await this.getLogData();
    return JSON.stringify(logData, null, 2);
  }

  /**
   * Clear all log data
   */
  async clearLog(): Promise<void> {
    try {
      const emptyLog: CohortLogData = {
        sessions: [],
        metadata: {
          totalSessions: 0,
          firstSession: 0,
          lastSession: 0,
          schemaVersion: this.SCHEMA_VERSION,
          lastUpdated: Date.now()
        }
      };
      await this.saveLog(emptyLog);
    } catch (error) {
      console.warn('CohortLogger: Failed to clear log', error);
      throw error;
    }
  }

  /**
   * Get log statistics
   */
  async getLogStats(): Promise<{
    totalSessions: number;
    dateRange: { start: string; end: string };
    enabledFeatures: string[];
    buildHash: string;
  }> {
    const logData = await this.getLogData();
    
    return {
      totalSessions: logData.metadata.totalSessions,
      dateRange: {
        start: logData.metadata.firstSession > 0 
          ? new Date(logData.metadata.firstSession).toISOString().split('T')[0]
          : 'No sessions',
        end: logData.metadata.lastSession > 0
          ? new Date(logData.metadata.lastSession).toISOString().split('T')[0]
          : 'No sessions'
      },
      enabledFeatures: getEnabledFeatures(),
      buildHash: this.BUILD_HASH
    };
  }

  /**
   * Download log as JSON file
   */
  async downloadLog(): Promise<void> {
    try {
      const logData = await this.exportLog();
      const blob = new Blob([logData], { type: 'application/json' });
      const url = URL.createObjectURL(blob);
      
      const timestamp = new Date().toISOString().split('T')[0];
      const filename = `resonai-cohort-log-${timestamp}.json`;
      
      const link = document.createElement('a');
      link.href = url;
      link.download = filename;
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
      
      URL.revokeObjectURL(url);
    } catch (error) {
      console.error('CohortLogger: Failed to download log', error);
      throw error;
    }
  }

  /**
   * Load log data from localStorage
   */
  private async loadLog(): Promise<CohortLogData> {
    try {
      if (typeof window === 'undefined') {
        return this.createEmptyLog();
      }

      const stored = localStorage.getItem(this.STORAGE_KEY);
      if (!stored) {
        return this.createEmptyLog();
      }

      const parsed = JSON.parse(stored);
      
      // Validate schema version
      if (parsed.metadata?.schemaVersion !== this.SCHEMA_VERSION) {
        console.warn('CohortLogger: Schema version mismatch, creating new log');
        return this.createEmptyLog();
      }

      return parsed;
    } catch (error) {
      console.warn('CohortLogger: Failed to load log, creating new', error);
      return this.createEmptyLog();
    }
  }

  /**
   * Save log data to localStorage
   */
  private async saveLog(logData: CohortLogData): Promise<void> {
    try {
      if (typeof window === 'undefined') {
        return;
      }

      localStorage.setItem(this.STORAGE_KEY, JSON.stringify(logData));
    } catch (error) {
      console.warn('CohortLogger: Failed to save log', error);
      throw error;
    }
  }

  /**
   * Create empty log data structure
   */
  private createEmptyLog(): CohortLogData {
    return {
      sessions: [],
      metadata: {
        totalSessions: 0,
        firstSession: 0,
        lastSession: 0,
        schemaVersion: this.SCHEMA_VERSION,
        lastUpdated: Date.now()
      }
    };
  }

  /**
   * Generate a local UUIDv4 for cohort tracking
   */
  private generateCohortId(): string {
    // Simple UUIDv4 implementation for local use
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c) => {
      const r = Math.random() * 16 | 0;
      const v = c === 'x' ? r : (r & 0x3 | 0x8);
      return v.toString(16);
    });
  }

  /**
   * Get build hash for version tracking
   */
  private getBuildHash(): string {
    // In a real app, this would come from build process
    // For now, use a simple hash based on timestamp
    const timestamp = Date.now().toString(36);
    return `build-${timestamp}`;
  }
}

// Singleton instance
export const cohortLogger = new CohortLogger();
