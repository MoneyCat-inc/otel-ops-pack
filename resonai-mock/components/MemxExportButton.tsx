/**
 * MEMX Export Button Component
 * 
 * PR-1: Export functionality for MEMX data
 * Downloads JSON with recent frames and session aggregates
 */

'use client';

import React, { useState } from 'react';
import { getMemxSessionManager, downloadMemxData, MemxExportData } from '../src/engine/memx/session';

interface MemxExportButtonProps {
  duration?: number; // Duration in milliseconds, default 2 minutes
  className?: string;
  disabled?: boolean;
}

export function MemxExportButton({ 
  duration = 120000, 
  className = '',
  disabled = false 
}: MemxExportButtonProps) {
  const [isExporting, setIsExporting] = useState(false);
  const [lastExport, setLastExport] = useState<string | null>(null);

  const handleExport = async () => {
    if (isExporting || disabled) return;

    setIsExporting(true);
    
    try {
      const sessionManager = getMemxSessionManager();
      const exportData = sessionManager.exportCurrentSession(duration);
      
      // Generate filename with timestamp
      const timestamp = new Date().toISOString().slice(0, 19).replace(/:/g, '-');
      const filename = `memx-export-${timestamp}.json`;
      
      // Download the data
      downloadMemxData(exportData, filename);
      
      // Update last export time
      setLastExport(new Date().toLocaleTimeString());
      
      console.log('MEMX: Data exported successfully', {
        frames: exportData.frameCount,
        duration: Math.round(duration / 1000) + 's',
        strainEvents: exportData.strainEvents.length,
      });
      
    } catch (error) {
      console.error('MEMX: Export failed', error);
      alert('Export failed. Please try again.');
    } finally {
      setIsExporting(false);
    }
  };

  const formatDuration = (ms: number): string => {
    const seconds = Math.round(ms / 1000);
    if (seconds < 60) return `${seconds}s`;
    const minutes = Math.floor(seconds / 60);
    const remainingSeconds = seconds % 60;
    return `${minutes}m ${remainingSeconds}s`;
  };

  return (
    <div className={`space-y-2 ${className}`}>
      <button
        onClick={handleExport}
        disabled={disabled || isExporting}
        className={`
          w-full px-4 py-2 rounded-lg font-medium transition-colors
          ${disabled || isExporting
            ? 'bg-gray-300 text-gray-500 cursor-not-allowed'
            : 'bg-blue-600 text-white hover:bg-blue-700 focus:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2'
          }
        `}
        aria-label={`Export MEMX data for last ${formatDuration(duration)}`}
      >
        {isExporting ? (
          <div className="flex items-center justify-center space-x-2">
            <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin"></div>
            <span>Exporting...</span>
          </div>
        ) : (
          <div className="flex items-center justify-center space-x-2">
            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 10v6m0 0l-3-3m3 3l3-3m2 8H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
            </svg>
            <span>Export MEMX JSON</span>
          </div>
        )}
      </button>
      
      {lastExport && (
        <p className="text-xs text-gray-500 text-center">
          Last exported: {lastExport}
        </p>
      )}
      
      <div className="text-xs text-gray-600 space-y-1">
        <p>• Exports last {formatDuration(duration)} of frame data</p>
        <p>• Includes session aggregates and strain events</p>
        <p>• File size typically &lt;2MB</p>
      </div>
    </div>
  );
}

// Export button with different duration presets
export function MemxExportPresets() {
  const presets = [
    { label: '30s', duration: 30000 },
    { label: '2m', duration: 120000 },
    { label: '5m', duration: 300000 },
    { label: '10m', duration: 600000 },
  ];

  return (
    <div className="space-y-3">
      <h3 className="text-sm font-medium text-gray-700">Export Duration</h3>
      <div className="grid grid-cols-2 gap-2">
        {presets.map((preset) => (
          <MemxExportButton
            key={preset.label}
            duration={preset.duration}
            className="text-sm"
          />
        ))}
      </div>
    </div>
  );
}

// Export all sessions button (for admin/debugging)
export function MemxExportAllSessionsButton({ className = '' }: { className?: string }) {
  const [isExporting, setIsExporting] = useState(false);

  const handleExportAll = async () => {
    if (isExporting) return;

    setIsExporting(true);
    
    try {
      const sessionManager = getMemxSessionManager();
      const exportData = await sessionManager.exportAllMemxSessions();
      
      // Download the data
      const blob = new Blob([exportData], { type: 'application/json' });
      const url = URL.createObjectURL(blob);
      const link = document.createElement('a');
      link.href = url;
      link.download = `memx-all-sessions-${new Date().toISOString().slice(0, 19).replace(/:/g, '-')}.json`;
      
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
      URL.revokeObjectURL(url);
      
      console.log('MEMX: All sessions exported successfully');
      
    } catch (error) {
      console.error('MEMX: Export all sessions failed', error);
      alert('Export failed. Please try again.');
    } finally {
      setIsExporting(false);
    }
  };

  return (
    <button
      onClick={handleExportAll}
      disabled={isExporting}
      className={`
        w-full px-3 py-2 text-sm rounded-lg font-medium transition-colors
        ${isExporting
          ? 'bg-gray-300 text-gray-500 cursor-not-allowed'
          : 'bg-gray-600 text-white hover:bg-gray-700 focus:bg-gray-700 focus:outline-none focus:ring-2 focus:ring-gray-500 focus:ring-offset-2'
        }
        ${className}
      `}
      aria-label="Export all MEMX sessions"
    >
      {isExporting ? (
        <div className="flex items-center justify-center space-x-2">
          <div className="w-3 h-3 border-2 border-white border-t-transparent rounded-full animate-spin"></div>
          <span>Exporting...</span>
        </div>
      ) : (
        'Export All Sessions'
      )}
    </button>
  );
}
