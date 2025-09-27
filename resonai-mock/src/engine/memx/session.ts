/**
 * MEMX Session Management
 * 
 * PR-1: Session persistence and export functionality
 * Integrates with IndexedDB for session aggregates storage
 */

import { MemxFrame, MemxSession } from './types';
import { getMemxStore } from './store';
import { SessionManager, SessionSummary } from '../../../lib/db';

export interface MemxExportData {
  version: string;
  exportedAt: string;
  duration: number;
  frameCount: number;
  frames: MemxFrame[];
  session: MemxSession;
  strainEvents: Array<{ type: string; value: number; timestamp: number }>;
}

export class MemxSessionManager {
  private currentSessionId: number | null = null;
  private store = getMemxStore();

  /**
   * Start a new MEMX session
   */
  async startSession(): Promise<number> {
    // Create a new session in the database
    const sessionId = await SessionManager.saveSession({
      ts: Date.now(),
      medianF0: null, // Will be updated by audio processing
      memx: undefined, // Will be updated when session ends
    });
    
    this.currentSessionId = sessionId;
    this.store.reset(); // Clear any existing frames
    
    console.log(`MEMX: Started session ${sessionId}`);
    return sessionId;
  }

  /**
   * End current session and save MEMX aggregates
   */
  async endSession(): Promise<void> {
    if (!this.currentSessionId) {
      console.warn('MEMX: No active session to end');
      return;
    }

    const aggregates = this.store.getSessionAggregates();
    await SessionManager.updateSessionWithMemx(this.currentSessionId, aggregates);
    
    console.log(`MEMX: Ended session ${this.currentSessionId}`, aggregates);
    this.currentSessionId = null;
  }

  /**
   * Get current session ID
   */
  getCurrentSessionId(): number | null {
    return this.currentSessionId;
  }

  /**
   * Check if session is active
   */
  isSessionActive(): boolean {
    return this.currentSessionId !== null;
  }

  /**
   * Export MEMX data for current session
   */
  exportCurrentSession(durationMs: number = 120000): MemxExportData {
    const frames = this.store.getRecentFrames(durationMs);
    const session = this.store.getSessionAggregates();
    const strainEvents = this.store.getStrainEvents();

    return {
      version: '1.0',
      exportedAt: new Date().toISOString(),
      duration: durationMs,
      frameCount: frames.length,
      frames,
      session,
      strainEvents,
    };
  }

  /**
   * Export MEMX data for a specific session by ID
   */
  async exportSessionById(sessionId: number): Promise<MemxExportData | null> {
    const session = await SessionManager.getSession(sessionId);
    if (!session || !session.memx) {
      return null;
    }

    // Note: Frame data is not persisted, only aggregates
    return {
      version: '1.0',
      exportedAt: new Date().toISOString(),
      duration: session.memx.sessionDurationMs || 0,
      frameCount: session.memx.frameCount || 0,
      frames: [], // Frame data is not persisted
      session: session.memx,
      strainEvents: [], // Strain events are not persisted
    };
  }

  /**
   * Export all sessions with MEMX data
   */
  async exportAllMemxSessions(): Promise<string> {
    return await SessionManager.exportMemxSessions();
  }

  /**
   * Get recent sessions with MEMX data
   */
  async getRecentMemxSessions(limit: number = 10) {
    return await SessionManager.getRecentSessionsWithMemx(limit);
  }

  /**
   * Clear all MEMX session data (for privacy)
   */
  async clearAllMemxData(): Promise<void> {
    await SessionManager.clearAllSessions();
    this.store.reset();
    console.log('MEMX: Cleared all session data');
  }

  /**
   * Get session statistics
   */
  async getSessionStats() {
    const allSessions = await SessionManager.getAllSessions();
    const memxSessions = allSessions.filter(s => s.memx !== undefined);
    
    const totalSessions = allSessions.length;
    const memxEnabledSessions = memxSessions.length;
    const memxEnabledPct = totalSessions > 0 ? (memxEnabledSessions / totalSessions) * 100 : 0;

    // Calculate average strain across all MEMX sessions
    const avgStrain = memxSessions.length > 0 
      ? memxSessions.reduce((sum, s) => sum + (s.memx?.memoryStrainPct || 0), 0) / memxSessions.length
      : 0;

    // Find peak strain session
    const peakStrainSession = memxSessions.reduce((peak, current) => {
      const currentStrain = current.memx?.memoryStrainPct || 0;
      const peakStrain = peak?.memx?.memoryStrainPct || 0;
      return currentStrain > peakStrain ? current : peak;
    }, undefined as SessionSummary | undefined);

    return {
      totalSessions,
      memxEnabledSessions,
      memxEnabledPct: Math.round(memxEnabledPct * 100) / 100,
      averageStrain: Math.round(avgStrain * 100) / 100,
      peakStrain: peakStrainSession?.memx?.memoryStrainPct || 0,
      peakStrainSessionId: peakStrainSession?.id,
    };
  }
}

// Singleton instance
let memxSessionManager: MemxSessionManager | null = null;

export function getMemxSessionManager(): MemxSessionManager {
  if (!memxSessionManager) {
    memxSessionManager = new MemxSessionManager();
  }
  return memxSessionManager;
}

// Utility functions for JSON export
export function downloadMemxData(data: MemxExportData, filename?: string): void {
  const jsonString = JSON.stringify(data, null, 2);
  const blob = new Blob([jsonString], { type: 'application/json' });
  
  const url = URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.href = url;
  link.download = filename || `memx-export-${new Date().toISOString().slice(0, 19).replace(/:/g, '-')}.json`;
  
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
  URL.revokeObjectURL(url);
}

export function formatMemxDataForDisplay(data: MemxExportData): string {
  const { session, frameCount, strainEvents } = data;
  
  const summary = [
    `MEMX Export Summary`,
    `==================`,
    `Exported: ${data.exportedAt}`,
    `Duration: ${Math.round(data.duration / 1000)}s`,
    `Frames: ${frameCount}`,
    ``,
    `Memory Aggregates:`,
    `  Peak WASM Heap: ${session.peakWasmHeapBytes ? formatBytes(session.peakWasmHeapBytes) : 'N/A'}`,
    `  Peak SAB Usage: ${session.peakSabUsagePct ? session.peakSabUsagePct.toFixed(1) + '%' : 'N/A'}`,
    `  Avg Worklet Lag: ${session.avgWorkletLagMs ? session.avgWorkletLagMs.toFixed(1) + 'ms' : 'N/A'}`,
    `  P95 Worklet Lag: ${session.p95WorkletLagMs ? session.p95WorkletLagMs.toFixed(1) + 'ms' : 'N/A'}`,
    `  Memory Strain: ${session.memoryStrainPct ? session.memoryStrainPct.toFixed(1) + '%' : 'N/A'}`,
    ``,
    `Strain Events: ${strainEvents.length}`,
  ];

  if (strainEvents.length > 0) {
    summary.push(``);
    strainEvents.forEach((event, index) => {
      summary.push(`  ${index + 1}. ${event.type}: ${event.value} (${new Date(event.timestamp).toLocaleTimeString()})`);
    });
  }

  return summary.join('\n');
}

// Helper function for formatting bytes
function formatBytes(bytes: number): string {
  if (bytes === 0) return '0 Bytes';
  
  const k = 1024;
  const sizes = ['Bytes', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
}
