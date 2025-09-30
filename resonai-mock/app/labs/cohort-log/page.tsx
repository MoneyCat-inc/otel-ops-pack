/**
 * Cohort Log UI Page
 * 
 * C5: Cohort Log & Tester Guide
 * Local-only cohort log viewer with export and clear functionality.
 * Accessible via /labs/cohort-log with privacy-first design.
 */

'use client';

import { useState, useEffect } from 'react';
import { cohortLogger, CohortLogData, CohortSessionLog } from '../../../src/engine/metrics/cohortLog';
import { flags, getEnabledFeatures } from '../../../src/config/flags';

interface LogStats {
  totalSessions: number;
  dateRange: { start: string; end: string };
  enabledFeatures: string[];
  buildHash: string;
}

export default function CohortLogPage() {
  const [logData, setLogData] = useState<CohortLogData | null>(null);
  const [stats, setStats] = useState<LogStats | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [actionLoading, setActionLoading] = useState<string | null>(null);
  const [announcement, setAnnouncement] = useState<string>('');

  // Load log data on mount
  useEffect(() => {
    loadLogData();
  }, []);

  const loadLogData = async () => {
    try {
      setLoading(true);
      setError(null);
      
      const [data, logStats] = await Promise.all([
        cohortLogger.getLogData(),
        cohortLogger.getLogStats()
      ]);
      
      setLogData(data);
      setStats(logStats);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load log data');
    } finally {
      setLoading(false);
    }
  };

  const handleExport = async () => {
    try {
      setActionLoading('export');
      await cohortLogger.downloadLog();
      setAnnouncement('Log data exported successfully');
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to export log');
      setAnnouncement('Export failed');
    } finally {
      setActionLoading(null);
    }
  };

  const handleClear = async () => {
    if (!confirm('Are you sure you want to clear all cohort log data? This action cannot be undone.')) {
      return;
    }

    try {
      setActionLoading('clear');
      await cohortLogger.clearLog();
      await loadLogData(); // Reload to show empty state
      setAnnouncement('All log data cleared');
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to clear log');
      setAnnouncement('Clear operation failed');
    } finally {
      setActionLoading(null);
    }
  };

  const formatTimestamp = (timestamp: number): string => {
    return new Date(timestamp).toLocaleString();
  };

  const formatSessionSummary = (session: CohortSessionLog): string => {
    const { sessionSummary } = session;
    const parts = [];
    
    if (sessionSummary.inBandPct !== undefined) {
      parts.push(`In-band: ${(sessionSummary.inBandPct * 100).toFixed(1)}%`);
    }
    if (sessionSummary.comfort !== undefined) {
      parts.push(`Comfort: ${sessionSummary.comfort}/5`);
    }
    if (sessionSummary.fatigue !== undefined) {
      parts.push(`Fatigue: ${sessionSummary.fatigue}/5`);
    }
    
    return parts.length > 0 ? parts.join(', ') : 'No metrics available';
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600 mx-auto mb-4"></div>
          <p className="text-gray-600">Loading cohort log...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Screen reader announcements */}
      <div aria-live="polite" aria-atomic="true" className="sr-only">
        {announcement}
      </div>
      
      <div className="max-w-6xl mx-auto px-4 py-8">
        {/* Header */}
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-gray-900 mb-2">
            Cohort Log Viewer
          </h1>
          <p className="text-gray-600">
            Local-only session logging for beta testing. All data stays on your device.
          </p>
        </div>

        {/* Privacy Notice */}
        <div className="bg-blue-50 border border-blue-200 rounded-lg p-4 mb-6">
          <div className="flex items-start">
            <div className="flex-shrink-0">
              <svg className="h-5 w-5 text-blue-400" fill="currentColor" viewBox="0 0 20 20">
                <path fillRule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clipRule="evenodd" />
              </svg>
            </div>
            <div className="ml-3">
              <h3 className="text-sm font-medium text-blue-800">
                Privacy Notice
              </h3>
              <p className="mt-1 text-sm text-blue-700">
                This log contains only local session data. No information is sent to external servers.
                You can export or delete this data at any time.
              </p>
            </div>
          </div>
        </div>

        {/* Error Display */}
        {error && (
          <div className="bg-red-50 border border-red-200 rounded-lg p-4 mb-6">
            <div className="flex">
              <div className="flex-shrink-0">
                <svg className="h-5 w-5 text-red-400" fill="currentColor" viewBox="0 0 20 20">
                  <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clipRule="evenodd" />
                </svg>
              </div>
              <div className="ml-3">
                <h3 className="text-sm font-medium text-red-800">
                  Error
                </h3>
                <p className="mt-1 text-sm text-red-700">{error}</p>
              </div>
            </div>
          </div>
        )}

        {/* Stats and Actions */}
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6 mb-6">
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-6">
            <div>
              <h3 className="text-sm font-medium text-gray-500">Total Sessions</h3>
              <p className="text-2xl font-semibold text-gray-900">
                {stats?.totalSessions || 0}
              </p>
            </div>
            <div>
              <h3 className="text-sm font-medium text-gray-500">Date Range</h3>
              <p className="text-sm text-gray-900">
                {stats?.dateRange.start === 'No sessions' ? 'No sessions' : 
                 `${stats?.dateRange.start} to ${stats?.dateRange.end}`}
              </p>
            </div>
            <div>
              <h3 className="text-sm font-medium text-gray-500">Build Hash</h3>
              <p className="text-sm text-gray-900 font-mono">
                {stats?.buildHash || 'Unknown'}
              </p>
            </div>
            <div>
              <h3 className="text-sm font-medium text-gray-500">Cohort Status</h3>
              <p className="text-sm text-gray-900">
                {flags.enabled ? 'Enabled' : 'Disabled'}
              </p>
            </div>
          </div>

          {/* Action Buttons */}
          <div className="flex flex-wrap gap-3">
            <button
              onClick={handleExport}
              disabled={actionLoading === 'export' || !logData?.sessions.length}
              aria-label="Export cohort log data as JSON file"
              className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed focus:ring-2 focus:ring-blue-500 focus:ring-offset-2"
            >
              {actionLoading === 'export' ? (
                <>
                  <svg className="animate-spin -ml-1 mr-2 h-4 w-4 text-white" fill="none" viewBox="0 0 24 24">
                    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                  </svg>
                  Exporting...
                </>
              ) : (
                <>
                  <svg className="-ml-1 mr-2 h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 10v6m0 0l-3-3m3 3l3-3m2 8H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                  </svg>
                  Export JSON
                </>
              )}
            </button>

            <button
              onClick={handleClear}
              disabled={actionLoading === 'clear' || !logData?.sessions.length}
              aria-label="Clear all cohort log data"
              className="inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed focus:ring-2 focus:ring-gray-500 focus:ring-offset-2"
            >
              {actionLoading === 'clear' ? (
                <>
                  <svg className="animate-spin -ml-1 mr-2 h-4 w-4 text-gray-500" fill="none" viewBox="0 0 24 24">
                    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                  </svg>
                  Clearing...
                </>
              ) : (
                <>
                  <svg className="-ml-1 mr-2 h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                  </svg>
                  Clear All Data
                </>
              )}
            </button>

            <button
              onClick={loadLogData}
              disabled={actionLoading !== null}
              aria-label="Refresh cohort log data"
              className="inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed focus:ring-2 focus:ring-gray-500 focus:ring-offset-2"
            >
              <svg className="-ml-1 mr-2 h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
              </svg>
              Refresh
            </button>
          </div>
        </div>

        {/* Enabled Features */}
        {stats?.enabledFeatures?.length && stats.enabledFeatures.length > 0 && (
          <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6 mb-6">
            <h3 className="text-lg font-medium text-gray-900 mb-4">Enabled Features</h3>
            <div className="flex flex-wrap gap-2">
              {stats.enabledFeatures.map((feature) => (
                <span
                  key={feature}
                  className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800"
                >
                  {feature}
                </span>
              ))}
            </div>
          </div>
        )}

        {/* Session Logs */}
        <div className="bg-white rounded-lg shadow-sm border border-gray-200">
          <div className="px-6 py-4 border-b border-gray-200">
            <h3 className="text-lg font-medium text-gray-900">
              Session Logs ({logData?.sessions.length || 0})
            </h3>
          </div>

          {!logData?.sessions.length ? (
            <div className="px-6 py-12 text-center">
              <svg className="mx-auto h-12 w-12 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
              </svg>
              <h3 className="mt-2 text-sm font-medium text-gray-900">No sessions logged</h3>
              <p className="mt-1 text-sm text-gray-500">
                {flags.enabled 
                  ? 'Complete practice sessions to see them logged here.'
                  : 'Enable cohort features to start logging sessions.'}
              </p>
            </div>
          ) : (
            <div className="divide-y divide-gray-200">
              {logData.sessions.map((session, index) => (
                <div key={session.cohortId} className="px-6 py-4">
                  <div className="flex items-center justify-between">
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center space-x-3">
                        <h4 className="text-sm font-medium text-gray-900 truncate">
                          Session #{logData.sessions.length - index}
                        </h4>
                        <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
                          {session.cohortId.slice(0, 8)}...
                        </span>
                      </div>
                      <div className="mt-1 text-sm text-gray-500">
                        <p>{formatTimestamp(session.timestamp)}</p>
                        <p className="mt-1">{formatSessionSummary(session)}</p>
                        {session.flagsEnabled.length > 0 && (
                          <div className="mt-2 flex flex-wrap gap-1">
                            {session.flagsEnabled.map((flag) => (
                              <span
                                key={flag}
                                className="inline-flex items-center px-1.5 py-0.5 rounded text-xs font-medium bg-gray-100 text-gray-800"
                              >
                                {flag}
                              </span>
                            ))}
                          </div>
                        )}
                      </div>
                    </div>
                    <div className="ml-4 text-sm text-gray-500">
                      <p>Build: {session.buildHash}</p>
                      <p>Version: {session.metadata.cohortVersion}</p>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>

        {/* Footer */}
        <div className="mt-8 text-center text-sm text-gray-500">
          <p>
            Cohort logging is {flags.enabled ? 'enabled' : 'disabled'}. 
            All data is stored locally and never transmitted.
          </p>
        </div>
      </div>
    </div>
  );
}
