'use client';

/**
 * IONA Logs Panel
 * 
 * Purpose: Display recent log entries
 * Data source: /api/telemetry/logs
 */

import React, { useEffect, useState } from 'react';

interface LogEntry {
  level: 'info' | 'warn' | 'error' | 'debug';
  message: string;
  timestamp: string;
  attributes?: Record<string, any>;
}

interface LogsResponse {
  logs: LogEntry[];
  summary: {
    total: number;
    lastUpdate: string;
  };
}

export default function LogsPanel() {
  const [logs, setLogs] = useState<LogEntry[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [filter, setFilter] = useState<'all' | 'info' | 'warn' | 'error'>('all');

  useEffect(() => {
    async function fetchLogs() {
      try {
        setLoading(true);
        const response = await fetch('/api/telemetry/logs');
        
        if (!response.ok) {
          throw new Error(`Failed to fetch logs: ${response.status}`);
        }
        
        const data: LogsResponse = await response.json();
        setLogs(data.logs || []);
        setError(null);
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Unknown error');
      } finally {
        setLoading(false);
      }
    }

    fetchLogs();
    const interval = setInterval(fetchLogs, 5000); // Refresh every 5 seconds
    
    return () => clearInterval(interval);
  }, []);

  const filteredLogs = filter === 'all' 
    ? logs 
    : logs.filter(log => log.level === filter);

  const getLevelColor = (level: string) => {
    switch (level) {
      case 'error': return 'text-red-600 dark:text-red-400 bg-red-50 dark:bg-red-900/20';
      case 'warn': return 'text-yellow-600 dark:text-yellow-400 bg-yellow-50 dark:bg-yellow-900/20';
      case 'info': return 'text-blue-600 dark:text-blue-400 bg-blue-50 dark:bg-blue-900/20';
      case 'debug': return 'text-gray-600 dark:text-gray-400 bg-gray-50 dark:bg-gray-700';
      default: return 'text-gray-600 dark:text-gray-400 bg-gray-50 dark:bg-gray-700';
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="text-gray-500">Loading logs...</div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg p-4">
        <p className="text-red-600 dark:text-red-400">Error: {error}</p>
      </div>
    );
  }

  return (
    <div className="space-y-4">
      {/* Filter Controls */}
      <div className="flex gap-2">
        {['all', 'info', 'warn', 'error'].map((level) => (
          <button
            key={level}
            onClick={() => setFilter(level as any)}
            className={`
              px-3 py-1 text-sm rounded-md transition-colors
              ${filter === level
                ? 'bg-blue-500 text-white'
                : 'bg-gray-200 dark:bg-gray-700 text-gray-700 dark:text-gray-300 hover:bg-gray-300 dark:hover:bg-gray-600'
              }
            `}
          >
            {level.charAt(0).toUpperCase() + level.slice(1)}
          </button>
        ))}
      </div>

      {/* Log Entries */}
      {filteredLogs.length === 0 ? (
        <div className="text-center text-gray-500 py-8">
          No logs available
        </div>
      ) : (
        <div className="space-y-2 max-h-96 overflow-y-auto">
          {filteredLogs.map((log, idx) => (
            <div
              key={idx}
              className={`rounded-lg p-3 border ${getLevelColor(log.level)} border-current`}
            >
              <div className="flex items-start justify-between gap-4">
                <div className="flex-1">
                  <div className="text-xs font-semibold uppercase mb-1">
                    {log.level}
                  </div>
                  <div className="text-sm font-mono">
                    {log.message}
                  </div>
                  {log.attributes && Object.keys(log.attributes).length > 0 && (
                    <details className="mt-2">
                      <summary className="text-xs cursor-pointer opacity-70">
                        Attributes
                      </summary>
                      <pre className="mt-1 text-xs opacity-70 overflow-x-auto">
                        {JSON.stringify(log.attributes, null, 2)}
                      </pre>
                    </details>
                  )}
                </div>
                <div className="text-xs opacity-70 whitespace-nowrap">
                  {new Date(log.timestamp).toLocaleTimeString()}
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

