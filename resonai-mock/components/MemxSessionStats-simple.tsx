/**
 * MEMX Session Statistics Component (Simplified)
 * 
 * PR-1: Display session statistics and memory aggregates
 */

'use client';

import React, { useEffect, useState } from 'react';
import { getMemxStore } from '../src/engine/memx/store';
import { MemxSession } from '../src/engine/memx/types';

const formatBytes = (bytes?: number) => {
  if (bytes === undefined) return '--';
  if (bytes === 0) return '0 Bytes';
  const k = 1024;
  const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
};

export function MemxSessionStats() {
  const [sessionSummary, setSessionSummary] = useState<MemxSession | null>(null);

  useEffect(() => {
    const interval = setInterval(() => {
      const store = getMemxStore();
      if (store) {
        setSessionSummary(store.getSessionAggregates());
      }
    }, 1000); // Update every second

    return () => clearInterval(interval);
  }, []);

  return (
    <div className="bg-white rounded-lg shadow p-6">
      <h2 className="text-xl font-semibold mb-4">Session Statistics</h2>
      <div className="space-y-4">
        <div className="flex justify-between items-center">
          <span className="text-sm font-medium text-gray-600">Peak WASM Heap</span>
          <span className="text-lg font-mono text-gray-900">{formatBytes(sessionSummary?.peakWasmHeapBytes)}</span>
        </div>
        <div className="flex justify-between items-center">
          <span className="text-sm font-medium text-gray-600">Peak SAB Usage</span>
          <span className="text-lg font-mono text-gray-900">{sessionSummary?.peakSabUsagePct !== undefined ? `${sessionSummary.peakSabUsagePct.toFixed(2)}%` : '--'}</span>
        </div>
        <div className="flex justify-between items-center">
          <span className="text-sm font-medium text-gray-600">Avg Worklet Lag</span>
          <span className="text-lg font-mono text-gray-900">{sessionSummary?.avgWorkletLagMs !== undefined ? `${sessionSummary.avgWorkletLagMs.toFixed(2)} ms` : '--'}</span>
        </div>
        <div className="flex justify-between items-center">
          <span className="text-sm font-medium text-gray-600">P95 Worklet Lag</span>
          <span className="text-lg font-mono text-gray-900">{sessionSummary?.p95WorkletLagMs !== undefined ? `${sessionSummary.p95WorkletLagMs.toFixed(2)} ms` : '--'}</span>
        </div>
        <div className="flex justify-between items-center">
          <span className="text-sm font-medium text-gray-600">Memory Strain</span>
          <span className="text-lg font-mono text-gray-900">{sessionSummary?.memoryStrainPct !== undefined ? `${sessionSummary.memoryStrainPct.toFixed(2)}%` : '--'}</span>
        </div>
        <div className="flex justify-between items-center">
          <span className="text-sm font-medium text-gray-600">Frame Count</span>
          <span className="text-lg font-mono text-gray-900">{sessionSummary?.frameCount !== undefined ? sessionSummary.frameCount.toLocaleString() : '--'}</span>
        </div>
        <div className="flex justify-between items-center">
          <span className="text-sm font-medium text-gray-600">Session Duration</span>
          <span className="text-lg font-mono text-gray-900">{sessionSummary?.sessionDurationMs !== undefined ? `${(sessionSummary.sessionDurationMs / 1000).toFixed(1)} s` : '--'}</span>
        </div>
      </div>
    </div>
  );
}
