/**
 * MEMX Session Statistics Component
 * 
 * PR-1: Display session statistics and MEMX usage metrics
 */

'use client';

import React, { useState, useEffect } from 'react';
import { getMemxSessionManager } from '../src/engine/memx/session';

interface SessionStats {
  totalSessions: number;
  memxEnabledSessions: number;
  memxEnabledPct: number;
  averageStrain: number;
  peakStrain: number;
  peakStrainSessionId?: number;
}

// Helper function to get progress bar width class
const getProgressWidthClass = (percentage: number): string => {
  const rounded = Math.round(percentage / 5) * 5; // Round to nearest 5%
  return `progress-${Math.min(Math.max(rounded, 0), 100)}`;
};

export function MemxSessionStats({ className = '' }: { className?: string }) {
  const [stats, setStats] = useState<SessionStats | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    loadStats();
  }, []);

  const loadStats = async () => {
    try {
      setLoading(true);
      setError(null);
      
      const sessionManager = getMemxSessionManager();
      const sessionStats = await sessionManager.getSessionStats();
      setStats(sessionStats);
      
    } catch (err) {
      console.error('MEMX: Failed to load session stats', err);
      setError('Failed to load statistics');
    } finally {
      setLoading(false);
    }
  };

  const refreshStats = () => {
    loadStats();
  };

  if (loading) {
    return (
      <div className={`bg-white rounded-lg shadow p-6 ${className}`}>
        <h2 className="text-xl font-semibold mb-4">Session Statistics</h2>
        <div className="space-y-3">
          <div className="animate-pulse">
            <div className="h-4 bg-gray-200 rounded w-3/4 mb-2"></div>
            <div className="h-4 bg-gray-200 rounded w-1/2 mb-2"></div>
            <div className="h-4 bg-gray-200 rounded w-2/3"></div>
          </div>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className={`bg-white rounded-lg shadow p-6 ${className}`}>
        <h2 className="text-xl font-semibold mb-4">Session Statistics</h2>
        <div className="text-center text-red-600 mb-4">
          <p>{error}</p>
          <button
            onClick={refreshStats}
            className="mt-2 px-3 py-1 text-sm bg-red-100 text-red-700 rounded hover:bg-red-200 transition-colors"
          >
            Retry
          </button>
        </div>
      </div>
    );
  }

  if (!stats) {
    return null;
  }

  return (
    <div className={`bg-white rounded-lg shadow p-6 ${className}`}>
      <div className="flex items-center justify-between mb-4">
        <h2 className="text-xl font-semibold">Session Statistics</h2>
        <button
          onClick={refreshStats}
          className="p-1 text-gray-400 hover:text-gray-600 transition-colors"
          aria-label="Refresh statistics"
        >
          <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
          </svg>
        </button>
      </div>

      <div className="grid grid-cols-2 gap-4 mb-6">
        <div className="text-center">
          <div className="text-2xl font-bold text-gray-900">{stats.totalSessions}</div>
          <div className="text-sm text-gray-600">Total Sessions</div>
        </div>
        <div className="text-center">
          <div className="text-2xl font-bold text-blue-600">{stats.memxEnabledSessions}</div>
          <div className="text-sm text-gray-600">MEMX Enabled</div>
        </div>
      </div>

      <div className="space-y-4">
        <div>
          <div className="flex justify-between items-center mb-2">
            <span className="text-sm font-medium text-gray-700">MEMX Adoption Rate</span>
            <span className="text-sm text-gray-600">{stats.memxEnabledPct}%</span>
          </div>
          <div className="w-full bg-gray-200 rounded-full h-2">
            <div
              className={`progress-bar progress-bar-blue ${getProgressWidthClass(stats.memxEnabledPct)}`}
            ></div>
          </div>
        </div>

        <div>
          <div className="flex justify-between items-center mb-2">
            <span className="text-sm font-medium text-gray-700">Average Memory Strain</span>
            <span className="text-sm text-gray-600">{stats.averageStrain}%</span>
          </div>
          <div className="w-full bg-gray-200 rounded-full h-2">
            <div
              className={`progress-bar ${
                stats.averageStrain > 70 ? 'progress-bar-red' :
                stats.averageStrain > 40 ? 'progress-bar-yellow' : 'progress-bar-green'
              } ${getProgressWidthClass(stats.averageStrain)}`}
            ></div>
          </div>
        </div>

        <div>
          <div className="flex justify-between items-center mb-2">
            <span className="text-sm font-medium text-gray-700">Peak Memory Strain</span>
            <span className="text-sm text-gray-600">{stats.peakStrain}%</span>
          </div>
          <div className="w-full bg-gray-200 rounded-full h-2">
            <div
              className={`progress-bar ${
                stats.peakStrain > 80 ? 'progress-bar-red' :
                stats.peakStrain > 60 ? 'progress-bar-yellow' : 'progress-bar-green'
              } ${getProgressWidthClass(stats.peakStrain)}`}
            ></div>
          </div>
          {stats.peakStrainSessionId && (
            <p className="text-xs text-gray-500 mt-1">
              Peak in session #{stats.peakStrainSessionId}
            </p>
          )}
        </div>
      </div>

      <div className="mt-6 pt-4 border-t border-gray-200">
        <div className="text-xs text-gray-500 space-y-1">
          <p>• MEMX adoption rate: percentage of sessions with memory monitoring</p>
          <p>• Memory strain: 0-100% scale based on WASM heap, SAB usage, and worklet lag</p>
          <p>• Peak strain: highest strain observed across all sessions</p>
        </div>
      </div>
    </div>
  );
}

// Compact version for dashboard
export function MemxSessionStatsCompact({ className = '' }: { className?: string }) {
  const [stats, setStats] = useState<SessionStats | null>(null);

  useEffect(() => {
    const loadStats = async () => {
      try {
        const sessionManager = getMemxSessionManager();
        const sessionStats = await sessionManager.getSessionStats();
        setStats(sessionStats);
      } catch (err) {
        console.error('MEMX: Failed to load compact stats', err);
      }
    };
    loadStats();
  }, []);

  if (!stats) {
    return (
      <div className={`bg-white rounded-lg shadow p-4 ${className}`}>
        <div className="animate-pulse">
          <div className="h-4 bg-gray-200 rounded w-1/2 mb-2"></div>
          <div className="h-3 bg-gray-200 rounded w-3/4"></div>
        </div>
      </div>
    );
  }

  return (
    <div className={`bg-white rounded-lg shadow p-4 ${className}`}>
      <h3 className="text-lg font-semibold mb-3">MEMX Overview</h3>
      <div className="grid grid-cols-3 gap-3 text-center">
        <div>
          <div className="text-xl font-bold text-gray-900">{stats.memxEnabledSessions}</div>
          <div className="text-xs text-gray-600">Sessions</div>
        </div>
        <div>
          <div className="text-xl font-bold text-blue-600">{stats.memxEnabledPct}%</div>
          <div className="text-xs text-gray-600">Adoption</div>
        </div>
        <div>
          <div className={`text-xl font-bold ${
            stats.averageStrain > 70 ? 'text-red-600' :
            stats.averageStrain > 40 ? 'text-yellow-600' : 'text-green-600'
          }`}>
            {stats.averageStrain}%
          </div>
          <div className="text-xs text-gray-600">Avg Strain</div>
        </div>
      </div>
    </div>
  );
}
