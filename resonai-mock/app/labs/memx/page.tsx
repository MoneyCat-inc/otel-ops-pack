/**
 * MEMX Labs Page
 * 
 * PR-0: Empty page with gated message "MEMX disabled"
 * PR-3: Labs UI & HUD - diagnostics page + mini overlay HUD
 */

'use client';

import React, { useState, useEffect } from 'react';
import { MemxExportButton, MemxExportPresets, MemxExportAllSessionsButton } from '../../../components/MemxExportButton-simple';
import { MemxSessionStats } from '../../../components/MemxSessionStats-simple';
import { MemxDebugInfo } from '../../../components/MemxDebugInfo';

// Feature flag check
const isMemxEnabled = process.env.NEXT_PUBLIC_FEATURE_MEMX === '1';

export default function MemxLabsPage() {
  const [isStreaming, setIsStreaming] = useState(false);

  // Check streaming configuration
  useEffect(() => {
    const streamDefault = process.env.NEXT_PUBLIC_MEMX_STREAM_DEFAULT === '1';
    setIsStreaming(streamDefault);
  }, []);

  // Feature disabled state
  if (!isMemxEnabled) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="max-w-md mx-auto text-center p-8">
          <div className="mb-6">
            <div className="w-16 h-16 mx-auto mb-4 bg-gray-200 rounded-full flex items-center justify-center">
              <svg className="w-8 h-8 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
              </svg>
            </div>
            <h1 className="text-2xl font-bold text-gray-900 mb-2">MEMX Disabled</h1>
            <p className="text-gray-600 mb-4">
              The Memory Observation Layer (MEMX) feature is currently disabled.
            </p>
            <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-4">
              <p className="text-sm text-yellow-800">
                <strong>To enable:</strong> Set <code className="bg-yellow-100 px-1 rounded">NEXT_PUBLIC_FEATURE_MEMX=1</code> in your environment variables.
              </p>
            </div>
          </div>
          
          <div className="space-y-4">
            <h2 className="text-lg font-semibold text-gray-900">What is MEMX?</h2>
            <div className="text-left space-y-3 text-sm text-gray-600">
              <p>
                <strong>Memory Observation Layer</strong> - A browser-side memory monitoring system that tracks:
              </p>
              <ul className="list-disc list-inside space-y-1 ml-4">
                <li>WASM heap usage (ONNX runtime)</li>
                <li>SharedArrayBuffer utilization (audio ring buffer)</li>
                <li>AudioWorklet processing lag</li>
                <li>Memory strain indicators</li>
              </ul>
              <p>
                <strong>Privacy-first:</strong> All data stays local; optional streaming to SigNoz via OTLP/HTTP.
              </p>
            </div>
          </div>
        </div>
      </div>
    );
  }

  // Feature enabled state - placeholder for PR-3
  return (
    <div className="min-h-screen bg-gray-50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-gray-900 mb-2">MEMX Diagnostics</h1>
          <p className="text-gray-600">
            Memory Observation Layer - Real-time browser memory monitoring
          </p>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          {/* Live Metrics */}
          <div className="bg-white rounded-lg shadow p-6" data-testid="memx-metrics">
            <h2 className="text-xl font-semibold mb-4">Live Metrics</h2>
            <div className="space-y-4">
              <div className="flex justify-between items-center">
                <span className="text-sm font-medium text-gray-600">WASM Heap (Peak)</span>
                <span className="text-lg font-mono text-gray-900">--</span>
              </div>
              <div className="flex justify-between items-center">
                <span className="text-sm font-medium text-gray-600">SAB Usage %</span>
                <span className="text-lg font-mono text-gray-900">--</span>
              </div>
              <div className="flex justify-between items-center">
                <span className="text-sm font-medium text-gray-600">Worklet Lag (p95)</span>
                <span className="text-lg font-mono text-gray-900">--</span>
              </div>
              <div className="flex justify-between items-center">
                <span className="text-sm font-medium text-gray-600">Memory Strain %</span>
                <span className="text-lg font-mono text-gray-900">--</span>
              </div>
            </div>
          </div>

          {/* Controls */}
          <div className="bg-white rounded-lg shadow p-6">
            <h2 className="text-xl font-semibold mb-4">Controls</h2>
            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <label className="text-sm font-medium text-gray-700">
                  Enable SigNoz Streaming
                </label>
                <button
                  className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors ${
                    isStreaming ? 'bg-blue-600' : 'bg-gray-200'
                  }`}
                  onClick={() => setIsStreaming(!isStreaming)}
                  aria-label={`${isStreaming ? 'Disable' : 'Enable'} streaming`}
                >
                  <span
                    className={`inline-block h-4 w-4 transform rounded-full bg-white transition-transform ${
                      isStreaming ? 'translate-x-6' : 'translate-x-1'
                    }`}
                  />
                </button>
              </div>
              
              <div className="pt-4 space-y-3">
                <MemxExportButton />
                <MemxExportAllSessionsButton />
              </div>
            </div>
          </div>

          {/* Browser Compatibility */}
          <MemxDebugInfo />
        </div>

        {/* Additional row for Session Statistics */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8 mt-8">
          <div className="lg:col-span-3">
            <MemxSessionStats />
          </div>
        </div>

        {/* Export Presets */}
        <div className="mt-8 bg-white rounded-lg shadow p-6">
          <h2 className="text-xl font-semibold mb-4">Export Presets</h2>
          <MemxExportPresets />
        </div>

        {/* Sparklines placeholder */}
        <div className="mt-8 bg-white rounded-lg shadow p-6">
          <h2 className="text-xl font-semibold mb-4">Memory Trends</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div>
              <h3 className="text-sm font-medium text-gray-600 mb-2">WASM Heap (Last 2 minutes)</h3>
              <div className="h-32 bg-gray-100 rounded flex items-center justify-center">
                <span className="text-gray-500">Sparkline placeholder</span>
              </div>
            </div>
            <div>
              <h3 className="text-sm font-medium text-gray-600 mb-2">SAB Usage % (Last 2 minutes)</h3>
              <div className="h-32 bg-gray-100 rounded flex items-center justify-center">
                <span className="text-gray-500">Sparkline placeholder</span>
              </div>
            </div>
          </div>
        </div>

        {/* Status indicator */}
        <div className="mt-6 flex items-center justify-center">
          <div className="flex items-center space-x-2 text-sm text-gray-600">
            <div className="w-2 h-2 bg-green-400 rounded-full"></div>
            <span>MEMX Active</span>
            {isStreaming && (
              <>
                <span>•</span>
                <div className="w-2 h-2 bg-blue-400 rounded-full"></div>
                <span>Streaming to SigNoz</span>
              </>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}

