/**
 * MEMX Session Management (Simplified)
 * 
 * PR-1: Basic session persistence and export functionality
 */

import { MemxFrame, MemxSession } from './types';
import { getMemxStore } from './store';

export interface MemxExportData {
  version: string;
  exportedAt: string;
  duration: number;
  frameCount: number;
  frames: MemxFrame[];
  session: MemxSession;
  strainEvents: Array<{ type: string; value: number; timestamp: number }>;
}

/**
 * Export recent MEMX data (frames + session summary)
 */
export function exportMemxData(durationMs: number = 120000): MemxExportData {
  const store = getMemxStore();
  if (!store) {
    console.warn('MEMX store not initialized');
    return {
      version: '1.0',
      exportedAt: new Date().toISOString(),
      duration: 0,
      frameCount: 0,
      frames: [],
      session: {},
      strainEvents: [],
    };
  }

  const frames = store.getRecentFrames(durationMs);
  const session = store.getSessionAggregates();
  const strainEvents = store.getStrainEvents();

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
 * Export all MEMX sessions (placeholder for PR-1)
 * In a real implementation, this would query IndexedDB
 */
export async function getAllMemxSessions(): Promise<MemxSession[]> {
  console.log('Fetching all MEMX sessions (placeholder)');
  // In PR-1, we return empty array as we're not yet persisting to IndexedDB
  // This will be implemented in PR-2 when we add real session management
  return [];
}

/**
 * Get session statistics (placeholder for PR-1)
 */
export async function getSessionStatistics() {
  return {
    totalSessions: 0,
    memxSessions: 0,
    adoptionRate: 0,
    avgStrain: 0,
    peakStrain: 0,
  };
}
