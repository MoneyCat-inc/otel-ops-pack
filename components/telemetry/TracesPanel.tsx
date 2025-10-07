'use client';

/**
 * IONA Traces Panel
 * 
 * Purpose: Display recent trace data and spans
 * Data source: /api/telemetry/traces
 */

import React, { useEffect, useState } from 'react';

interface Span {
  traceId: string;
  spanId: string;
  name: string;
  duration: number;
  timestamp: string;
  attributes?: Record<string, any>;
}

interface TracesResponse {
  traces: Span[];
  summary: {
    total: number;
    lastUpdate: string;
  };
}

export default function TracesPanel() {
  const [traces, setTraces] = useState<Span[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    async function fetchTraces() {
      try {
        setLoading(true);
        const response = await fetch('/api/telemetry/traces');
        
        if (!response.ok) {
          throw new Error(`Failed to fetch traces: ${response.status}`);
        }
        
        const data: TracesResponse = await response.json();
        setTraces(data.traces || []);
        setError(null);
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Unknown error');
      } finally {
        setLoading(false);
      }
    }

    fetchTraces();
    const interval = setInterval(fetchTraces, 10000); // Refresh every 10 seconds
    
    return () => clearInterval(interval);
  }, []);

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="text-gray-500">Loading traces...</div>
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
      {traces.length === 0 ? (
        <div className="text-center text-gray-500 py-8">
          No traces available
        </div>
      ) : (
        <div className="space-y-2">
          {traces.map((span, idx) => (
            <div
              key={idx}
              className="bg-gray-50 dark:bg-gray-700 rounded-lg p-4 border border-gray-200 dark:border-gray-600"
            >
              <div className="flex items-start justify-between">
                <div className="flex-1">
                  <div className="font-semibold text-gray-900 dark:text-white mb-1">
                    {span.name}
                  </div>
                  <div className="text-xs text-gray-500 dark:text-gray-400 space-y-1">
                    <div>Trace ID: <code className="bg-gray-200 dark:bg-gray-600 px-1 rounded">{span.traceId.slice(0, 16)}...</code></div>
                    <div>Span ID: <code className="bg-gray-200 dark:bg-gray-600 px-1 rounded">{span.spanId.slice(0, 16)}...</code></div>
                    <div>Time: {new Date(span.timestamp).toLocaleString()}</div>
                  </div>
                </div>
                <div className="text-right">
                  <div className="text-sm font-medium text-blue-600 dark:text-blue-400">
                    {span.duration.toFixed(2)}ms
                  </div>
                </div>
              </div>
              
              {span.attributes && Object.keys(span.attributes).length > 0 && (
                <details className="mt-3">
                  <summary className="text-xs text-gray-600 dark:text-gray-400 cursor-pointer">
                    Attributes ({Object.keys(span.attributes).length})
                  </summary>
                  <pre className="mt-2 text-xs bg-gray-100 dark:bg-gray-800 p-2 rounded overflow-x-auto">
                    {JSON.stringify(span.attributes, null, 2)}
                  </pre>
                </details>
              )}
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

