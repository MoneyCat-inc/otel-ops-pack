'use client';

/**
 * IONA Controls Panel
 * 
 * Purpose: Interactive controls for telemetry instrumentation
 * Features:
 *  - Instrumentation toggle
 *  - Sampling rate adjustment
 *  - Manual span emission
 */

import React, { useState } from 'react';
import { getOtelIngestHttpBase } from '@/lib/otel-ports';

interface ControlsPanelProps {
  onRefresh?: () => void;
}

export default function ControlsPanel({ onRefresh }: ControlsPanelProps) {
  const [instrumentationEnabled, setInstrumentationEnabled] = useState(true);
  const [samplingRate, setSamplingRate] = useState(100);
  const [emitting, setEmitting] = useState(false);
  const [lastEmitResult, setLastEmitResult] = useState<{ success: boolean; message: string } | null>(null);

  const handleToggleInstrumentation = () => {
    setInstrumentationEnabled(!instrumentationEnabled);
    // In a real implementation, this would call an API to toggle instrumentation
    console.log(`Instrumentation ${!instrumentationEnabled ? 'enabled' : 'disabled'}`);
  };

  const handleSamplingChange = (value: number) => {
    setSamplingRate(value);
    // In a real implementation, this would update the sampling configuration
    console.log(`Sampling rate changed to ${value}%`);
  };

  const handleEmitSpan = async () => {
    setEmitting(true);
    setLastEmitResult(null);
    
    try {
      const response = await fetch('/api/telemetry/emit-span', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          spanName: 'manual.diagnostic.span',
          attributes: {
            'test.type': 'manual',
            'test.source': 'diagnostics-panel',
            'test.timestamp': new Date().toISOString(),
          },
        }),
      });
      
      if (!response.ok) {
        throw new Error(`Failed to emit span: ${response.status}`);
      }
      
      const result = await response.json();
      setLastEmitResult({
        success: true,
        message: result.message || 'Span emitted successfully',
      });
      
      // Refresh telemetry data after emitting
      if (onRefresh) {
        setTimeout(onRefresh, 1000);
      }
    } catch (error) {
      setLastEmitResult({
        success: false,
        message: error instanceof Error ? error.message : 'Unknown error',
      });
    } finally {
      setEmitting(false);
    }
  };

  return (
    <div className="space-y-6">
      {/* Instrumentation Toggle */}
      <div className="bg-gray-50 dark:bg-gray-700 rounded-lg p-6 border border-gray-200 dark:border-gray-600">
        <div className="flex items-center justify-between">
          <div>
            <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-1">
              Instrumentation
            </h3>
            <p className="text-sm text-gray-600 dark:text-gray-400">
              Enable or disable telemetry collection
            </p>
          </div>
          <button
            onClick={handleToggleInstrumentation}
            className={`
              relative inline-flex h-8 w-14 items-center rounded-full transition-colors
              ${instrumentationEnabled ? 'bg-blue-500' : 'bg-gray-300 dark:bg-gray-600'}
            `}
            role="switch"
            aria-checked={instrumentationEnabled}
          >
            <span
              className={`
                inline-block h-6 w-6 transform rounded-full bg-white transition-transform
                ${instrumentationEnabled ? 'translate-x-7' : 'translate-x-1'}
              `}
            />
          </button>
        </div>
        <div className="mt-4">
          <span className={`
            inline-flex items-center px-3 py-1 rounded-full text-sm font-medium
            ${instrumentationEnabled 
              ? 'bg-green-100 dark:bg-green-900/20 text-green-800 dark:text-green-400'
              : 'bg-gray-200 dark:bg-gray-600 text-gray-700 dark:text-gray-300'
            }
          `}>
            {instrumentationEnabled ? '✓ Active' : '✗ Disabled'}
          </span>
        </div>
      </div>

      {/* Sampling Rate */}
      <div className="bg-gray-50 dark:bg-gray-700 rounded-lg p-6 border border-gray-200 dark:border-gray-600">
        <div className="flex items-center justify-between mb-4">
          <div>
            <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-1">
              Sampling Rate
            </h3>
            <p className="text-sm text-gray-600 dark:text-gray-400">
              Adjust trace sampling percentage
            </p>
          </div>
          <div className="text-2xl font-bold text-blue-600 dark:text-blue-400">
            {samplingRate}%
          </div>
        </div>
        <input
          type="range"
          min="0"
          max="100"
          step="10"
          value={samplingRate}
          onChange={(e) => handleSamplingChange(Number(e.target.value))}
          className="w-full h-2 bg-gray-200 dark:bg-gray-600 rounded-lg appearance-none cursor-pointer"
        />
        <div className="flex justify-between text-xs text-gray-500 dark:text-gray-400 mt-2">
          <span>0%</span>
          <span>50%</span>
          <span>100%</span>
        </div>
      </div>

      {/* Manual Span Emission */}
      <div className="bg-gray-50 dark:bg-gray-700 rounded-lg p-6 border border-gray-200 dark:border-gray-600">
        <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-1">
          Manual Span Emission
        </h3>
        <p className="text-sm text-gray-600 dark:text-gray-400 mb-4">
          Emit a test span to verify telemetry pipeline
        </p>
        
        <button
          onClick={handleEmitSpan}
          disabled={emitting}
          className={`
            w-full px-6 py-3 rounded-lg font-medium transition-colors
            ${emitting
              ? 'bg-gray-300 dark:bg-gray-600 text-gray-500 cursor-not-allowed'
              : 'bg-blue-500 hover:bg-blue-600 text-white'
            }
          `}
        >
          {emitting ? 'Emitting...' : '📡 Emit Test Span'}
        </button>
        
        {lastEmitResult && (
          <div className={`
            mt-4 p-3 rounded-lg border
            ${lastEmitResult.success
              ? 'bg-green-50 dark:bg-green-900/20 border-green-200 dark:border-green-800 text-green-700 dark:text-green-400'
              : 'bg-red-50 dark:bg-red-900/20 border-red-200 dark:border-red-800 text-red-700 dark:text-red-400'
            }
          `}>
            <div className="flex items-start gap-2">
              <span className="text-lg">{lastEmitResult.success ? '✓' : '✗'}</span>
              <div className="flex-1 text-sm">
                {lastEmitResult.message}
              </div>
            </div>
          </div>
        )}
      </div>

      {/* Telemetry Stats */}
      <div className="bg-gray-50 dark:bg-gray-700 rounded-lg p-6 border border-gray-200 dark:border-gray-600">
        <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">
          Pipeline Status
        </h3>
        <div className="space-y-3">
          <div className="flex justify-between text-sm">
            <span className="text-gray-600 dark:text-gray-400">OTLP Endpoint</span>
            <span className="font-mono text-gray-900 dark:text-white">{getOtelIngestHttpBase()}</span>
          </div>
          <div className="flex justify-between text-sm">
            <span className="text-gray-600 dark:text-gray-400">Protocol</span>
            <span className="font-mono text-gray-900 dark:text-white">HTTP/protobuf</span>
          </div>
          <div className="flex justify-between text-sm">
            <span className="text-gray-600 dark:text-gray-400">Service Name</span>
            <span className="font-mono text-gray-900 dark:text-white">iona-app</span>
          </div>
        </div>
      </div>
    </div>
  );
}

