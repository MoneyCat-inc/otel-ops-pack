/**
 * MEMX Export Button Component (Simplified)
 * 
 * PR-1: Basic export functionality for MEMX data
 */

'use client';

import React from 'react';
import { exportMemxData, getAllMemxSessions } from '../src/engine/memx/session-simple';

const downloadJson = (data: any, filename: string) => {
  const jsonStr = JSON.stringify(data, null, 2);
  const blob = new Blob([jsonStr], { type: 'application/json' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = filename;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  URL.revokeObjectURL(url);
};

export function MemxExportButton() {
  const handleExport = () => {
    const data = exportMemxData();
    const timestamp = new Date().toISOString().replace(/[:.-]/g, '');
    downloadJson(data, `memx_data_${timestamp}.json`);
    console.log('Exported recent MEMX data.');
  };

  return (
    <button
      onClick={handleExport}
      className="w-full bg-indigo-600 text-white py-2 px-4 rounded-md hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 transition-colors"
    >
      Download Recent MEMX JSON
    </button>
  );
}

export function MemxExportAllSessionsButton() {
  const handleExportAll = async () => {
    const allSessions = await getAllMemxSessions();
    const timestamp = new Date().toISOString().replace(/[:.-]/g, '');
    downloadJson(allSessions, `memx_all_sessions_${timestamp}.json`);
    console.log('Exported all MEMX sessions.');
  };

  return (
    <button
      onClick={handleExportAll}
      className="w-full bg-gray-200 text-gray-800 py-2 px-4 rounded-md hover:bg-gray-300 focus:outline-none focus:ring-2 focus:ring-gray-400 focus:ring-offset-2 transition-colors"
    >
      Download All Sessions JSON (Placeholder)
    </button>
  );
}

export function MemxExportPresets() {
  const presets = [
    { label: 'Last 30 seconds', duration: 30 * 1000 },
    { label: 'Last 1 minute', duration: 60 * 1000 },
    { label: 'Last 5 minutes', duration: 5 * 60 * 1000 },
  ];

  return (
    <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3">
      {presets.map((preset) => (
        <button
          key={preset.label}
          onClick={() => {
            const data = exportMemxData(preset.duration);
            const timestamp = new Date().toISOString().replace(/[:.-]/g, '');
            downloadJson(data, `memx_data_${preset.duration / 1000}s_${timestamp}.json`);
          }}
          className="bg-blue-100 text-blue-800 py-2 px-4 rounded-md hover:bg-blue-200 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 transition-colors text-sm"
        >
          {preset.label}
        </button>
      ))}
    </div>
  );
}
