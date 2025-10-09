'use client';

/**
 * IONA Metrics Panel
 * 
 * Purpose: Display real-time telemetry metrics
 * Data source: /api/telemetry/metrics
 */

import React, { useEffect, useState } from 'react';

interface MetricData {
  name: string;
  value: number;
  unit?: string;
  timestamp: string;
}

interface MetricsResponse {
  metrics: MetricData[];
  summary: {
    total: number;
    lastUpdate: string;
  };
}

export default function MetricsPanel() {
  const [metrics, setMetrics] = useState<MetricData[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    async function fetchMetrics() {
      try {
        setLoading(true);
        const response = await fetch('/api/telemetry/metrics');
        
        if (!response.ok) {
          throw new Error(`Failed to fetch metrics: ${response.status}`);
        }
        
        const data: MetricsResponse = await response.json();
        setMetrics(data.metrics || []);
        setError(null);
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Unknown error');
      } finally {
        setLoading(false);
      }
    }

    fetchMetrics();
    const interval = setInterval(fetchMetrics, 5000); // Refresh every 5 seconds
    
    return () => clearInterval(interval);
  }, []);

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="text-gray-500">Loading metrics...</div>
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
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {metrics.length === 0 ? (
          <div className="col-span-full text-center text-gray-500 py-8">
            No metrics available
          </div>
        ) : (
          metrics.map((metric, idx) => (
            <div
              key={idx}
              className="bg-gray-50 dark:bg-gray-700 rounded-lg p-4 border border-gray-200 dark:border-gray-600"
            >
              <div className="text-sm text-gray-600 dark:text-gray-400 mb-1">
                {metric.name}
              </div>
              <div className="text-2xl font-bold text-gray-900 dark:text-white">
                {metric.value.toLocaleString()}
                {metric.unit && <span className="text-sm ml-1">{metric.unit}</span>}
              </div>
              <div className="text-xs text-gray-500 dark:text-gray-400 mt-2">
                {new Date(metric.timestamp).toLocaleTimeString()}
              </div>
            </div>
          ))
        )}
      </div>
    </div>
  );
}

