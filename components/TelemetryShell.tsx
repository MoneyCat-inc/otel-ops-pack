'use client';

/**
 * IONA Telemetry Shell Component
 * 
 * Purpose: Main container for diagnostic telemetry panels
 * Orchestrates: Metrics, Traces, Logs, and Control panels
 * 
 * Part of: IONA-GATE-002 - Diagnostics Shell
 */

import React, { useState } from 'react';
import MetricsPanel from '@/components/telemetry/MetricsPanel';
import TracesPanel from '@/components/telemetry/TracesPanel';
import LogsPanel from '@/components/telemetry/LogsPanel';
import ControlsPanel from '@/components/telemetry/ControlsPanel';

export default function TelemetryShell() {
  const [activeTab, setActiveTab] = useState<'metrics' | 'traces' | 'logs' | 'controls'>('metrics');
  const [refreshKey, setRefreshKey] = useState(0);

  const handleRefresh = () => {
    setRefreshKey(prev => prev + 1);
  };

  const tabs = [
    { id: 'metrics' as const, label: 'Metrics', icon: '📊' },
    { id: 'traces' as const, label: 'Traces', icon: '🔍' },
    { id: 'logs' as const, label: 'Logs', icon: '📝' },
    { id: 'controls' as const, label: 'Controls', icon: '⚙️' },
  ];

  return (
    <div className="bg-white dark:bg-gray-800 rounded-lg shadow-lg overflow-hidden">
      {/* Tab Navigation */}
      <div className="border-b border-gray-200 dark:border-gray-700">
        <nav className="flex -mb-px">
          {tabs.map((tab) => (
            <button
              key={tab.id}
              onClick={() => setActiveTab(tab.id)}
              className={`
                flex items-center gap-2 px-6 py-4 text-sm font-medium transition-colors
                ${activeTab === tab.id
                  ? 'border-b-2 border-blue-500 text-blue-600 dark:text-blue-400'
                  : 'text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-300'
                }
              `}
            >
              <span className="text-lg">{tab.icon}</span>
              <span>{tab.label}</span>
            </button>
          ))}
          
          {/* Refresh Button */}
          <div className="ml-auto flex items-center px-4">
            <button
              onClick={handleRefresh}
              className="px-4 py-2 text-sm font-medium text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700 rounded-md transition-colors"
              title="Refresh telemetry data"
            >
              🔄 Refresh
            </button>
          </div>
        </nav>
      </div>

      {/* Tab Content */}
      <div className="p-6">
        {activeTab === 'metrics' && <MetricsPanel key={`metrics-${refreshKey}`} />}
        {activeTab === 'traces' && <TracesPanel key={`traces-${refreshKey}`} />}
        {activeTab === 'logs' && <LogsPanel key={`logs-${refreshKey}`} />}
        {activeTab === 'controls' && <ControlsPanel key={`controls-${refreshKey}`} onRefresh={handleRefresh} />}
      </div>
    </div>
  );
}

