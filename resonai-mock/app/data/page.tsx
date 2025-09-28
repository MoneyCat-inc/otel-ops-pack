/**
 * Data Control Page
 * 
 * C2: Export & Delete UX
 * Provides users with complete data sovereignty through export and delete controls.
 */

'use client';

import React, { useState, useEffect } from 'react';
import { useReducedMotion } from '../../src/hooks/useReducedMotion';
import Link from 'next/link';

export default function DataControlPage() {
  const [sessions, setSessions] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [announcement, setAnnouncement] = useState<string>('');
  const [showDeleteModal, setShowDeleteModal] = useState(false);
  const [deleteConfirmText, setDeleteConfirmText] = useState('');
  const [isDeleting, setIsDeleting] = useState(false);
  
  const reducedMotion = useReducedMotion();

  useEffect(() => {
    loadSessionData();
  }, []);

  const loadSessionData = async () => {
    try {
      setLoading(true);
      setError(null);

      // In a real implementation, this would read from IndexedDB
      // For now, we'll use mock data that matches the expected schema
      const mockSessions = generateMockSessions();
      setSessions(mockSessions);
      setAnnouncement(`Loaded ${mockSessions.length} practice sessions`);

    } catch (err) {
      console.error('Failed to load session data:', err);
      setError('Failed to load session data. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  const generateMockSessions = () => {
    const sessions = [];
    const now = Date.now();
    
    // Generate 10 mock sessions
    for (let i = 0; i < 10; i++) {
      const date = new Date(now - i * 24 * 60 * 60 * 1000);
      
      sessions.push({
        id: i + 1,
        ts: date.getTime(),
        medianF0: 150 + Math.random() * 50,
        inBandPct: 0.6 + Math.random() * 0.3,
        prosodyVar: 0.4 + Math.random() * 0.4,
        voicedTimePct: 0.7 + Math.random() * 0.2,
        jitterEma: 0.1 + Math.random() * 0.2,
        comfort: Math.floor(Math.random() * 5) + 1,
        fatigue: Math.floor(Math.random() * 5) + 1,
        euphoria: Math.floor(Math.random() * 5) + 1,
        orb: 'practice',
        memx: {
          memoryStrainPct: Math.random() * 0.3,
          bucketBias: {
            front: Math.random() * 0.4 + 0.2,
            central: Math.random() * 0.4 + 0.2,
            back: Math.random() * 0.4 + 0.2
          }
        },
        schemaVersion: 1
      });
    }
    
    return sessions;
  };

  const exportData = async () => {
    try {
      setAnnouncement('Preparing data export...');

      // Create export data with metadata
      const exportData = {
        schemaVersion: 1,
        exportedAt: new Date().toISOString(),
        build: 'C2-data-control-v1',
        appVersion: '1.0.0',
        sessions: sessions,
        summary: {
          totalSessions: sessions.length,
          dateRange: {
            start: sessions.length > 0 ? new Date(Math.min(...sessions.map(s => s.ts))).toISOString() : null,
            end: sessions.length > 0 ? new Date(Math.max(...sessions.map(s => s.ts))).toISOString() : null
          },
          metrics: {
            averageInBandPct: sessions.reduce((sum, s) => sum + (s.inBandPct || 0), 0) / sessions.length,
            averageExpressiveness: sessions.reduce((sum, s) => sum + (s.prosodyVar || 0), 0) / sessions.length,
            averageComfort: sessions.reduce((sum, s) => sum + (s.comfort || 0), 0) / sessions.length
          }
        }
      };

      // Create and download JSON file
      const jsonString = JSON.stringify(exportData, null, 2);
      const blob = new Blob([jsonString], { type: 'application/json' });
      const url = URL.createObjectURL(blob);
      
      const link = document.createElement('a');
      link.href = url;
      link.download = `resonai_sessions_v${exportData.schemaVersion}_${new Date().toISOString().split('T')[0]}.json`;
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
      
      URL.revokeObjectURL(url);
      
      setAnnouncement(`Data exported successfully. ${sessions.length} sessions downloaded.`);

    } catch (err) {
      console.error('Export failed:', err);
      setAnnouncement('Export failed. Please try again.');
    }
  };

  const deleteAllData = async () => {
    if (deleteConfirmText !== 'DELETE') {
      setAnnouncement('Please type DELETE to confirm deletion.');
      return;
    }

    try {
      setIsDeleting(true);
      setAnnouncement('Deleting all data...');

      // In a real implementation, this would delete from IndexedDB
      // For now, we'll simulate the deletion
      await new Promise(resolve => setTimeout(resolve, 1000)); // Simulate async operation
      
      // Clear local state
      setSessions([]);
      setShowDeleteModal(false);
      setDeleteConfirmText('');
      
      setAnnouncement('All data deleted successfully. Your practice history has been cleared.');

    } catch (err) {
      console.error('Delete failed:', err);
      setAnnouncement('Delete failed. Please try again.');
    } finally {
      setIsDeleting(false);
    }
  };

  const openDeleteModal = () => {
    setShowDeleteModal(true);
    setDeleteConfirmText('');
    setAnnouncement('Delete confirmation dialog opened. Type DELETE to confirm.');
  };

  const closeDeleteModal = () => {
    setShowDeleteModal(false);
    setDeleteConfirmText('');
    setAnnouncement('Delete confirmation cancelled.');
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-purple-50 to-indigo-100 flex items-center justify-center">
        <div className="text-center">
          <div className={`w-8 h-8 border-4 border-purple-600 border-t-transparent rounded-full ${reducedMotion ? '' : 'animate-spin'} mx-auto mb-4`}></div>
          <p className="text-gray-600">Loading your data...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-purple-50 to-indigo-100">
      {/* Screen reader announcements */}
      <div 
        aria-live="polite" 
        aria-atomic="true" 
        className="sr-only"
        role="status"
      >
        {announcement}
      </div>

      {/* Skip link for keyboard users */}
      <a 
        href="#main-content" 
        className="sr-only focus:not-sr-only focus:absolute focus:top-4 focus:left-4 bg-purple-600 text-white px-4 py-2 rounded-md z-50"
      >
        Skip to main content
      </a>

      {/* Header */}
      <header className="bg-white shadow-sm border-b">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center py-4">
            <div className="flex items-center space-x-3">
              <Link href="/" className="flex items-center space-x-3 hover:opacity-80 transition-opacity">
                <div className="w-8 h-8 bg-gradient-to-r from-purple-600 to-indigo-600 rounded-lg flex items-center justify-center">
                  <span className="text-white font-bold text-sm">R</span>
                </div>
                <span className="text-xl font-semibold text-gray-900">Resonai</span>
              </Link>
            </div>
            
            <nav className="flex items-center space-x-4">
              <Link
                href="/practice"
                className="text-gray-600 hover:text-gray-900 px-3 py-2 rounded-md text-sm font-medium transition-colors"
              >
                Practice
              </Link>
              <Link
                href="/progress"
                className="text-gray-600 hover:text-gray-900 px-3 py-2 rounded-md text-sm font-medium transition-colors"
              >
                Progress
              </Link>
              <Link
                href="/data"
                className="text-purple-600 hover:text-purple-700 px-3 py-2 rounded-md text-sm font-medium transition-colors"
              >
                Data Control
              </Link>
            </nav>
          </div>
        </div>
      </header>

      {/* Main content */}
      <main id="main-content" className="container mx-auto px-4 py-8">
        <div className="mb-8">
          <h1 className="text-4xl font-bold text-gray-900 mb-2">Data Control</h1>
          <p className="text-lg text-gray-600">
            Export your practice data or delete everything. You have complete control over your information.
          </p>
        </div>

        {/* Error state */}
        {error && (
          <div className="mb-8 bg-red-50 border border-red-200 rounded-lg p-6">
            <div className="flex items-center">
              <div className="text-red-500 text-2xl mr-3">⚠️</div>
              <div>
                <h3 className="text-lg font-semibold text-red-800">Error</h3>
                <p className="text-red-700">{error}</p>
              </div>
            </div>
          </div>
        )}

        {/* Data summary */}
        <div className="mb-8 bg-white rounded-lg shadow-sm p-6 border border-gray-200">
          <h2 className="text-xl font-semibold text-gray-900 mb-4">Your Data Summary</h2>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            <div className="text-center">
              <div className="text-3xl font-bold text-purple-600">{sessions.length}</div>
              <div className="text-sm text-gray-600">Practice Sessions</div>
            </div>
            <div className="text-center">
              <div className="text-3xl font-bold text-blue-600">
                {sessions.length > 0 ? Math.round(sessions.reduce((sum, s) => sum + (s.inBandPct || 0), 0) / sessions.length * 100) : 0}%
              </div>
              <div className="text-sm text-gray-600">Avg Pitch Accuracy</div>
            </div>
            <div className="text-center">
              <div className="text-3xl font-bold text-green-600">
                {sessions.length > 0 ? Math.round(sessions.reduce((sum, s) => sum + (s.comfort || 0), 0) / sessions.length) : 0}/5
              </div>
              <div className="text-sm text-gray-600">Avg Comfort</div>
            </div>
          </div>
        </div>

        {/* Control cards */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
          {/* Export card */}
          <div className="bg-white rounded-lg shadow-sm p-8 border border-gray-200">
            <div className="text-center">
              <div className="text-6xl mb-4">📥</div>
              <h3 className="text-2xl font-bold text-gray-900 mb-4">Export Your Data</h3>
              <p className="text-gray-600 mb-6">
                Download all your practice sessions as a JSON file. Includes metrics, timestamps, and summary statistics.
              </p>
              
              <button
                onClick={exportData}
                disabled={sessions.length === 0}
                className={`w-full px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:bg-gray-400 disabled:cursor-not-allowed font-medium ${reducedMotion ? '' : 'transition-colors'} focus:ring-2 focus:ring-blue-500 focus:ring-offset-2`}
                aria-label="Export all practice data as JSON file"
              >
                {sessions.length === 0 ? 'No Data to Export' : 'Export as JSON'}
              </button>
              
              <div className="mt-4 text-sm text-gray-500">
                <p>• Includes {sessions.length} practice sessions</p>
                <p>• No audio or personal files</p>
                <p>• Compatible with data analysis tools</p>
              </div>
            </div>
          </div>

          {/* Delete card */}
          <div className="bg-white rounded-lg shadow-sm p-8 border border-gray-200">
            <div className="text-center">
              <div className="text-6xl mb-4">🗑️</div>
              <h3 className="text-2xl font-bold text-gray-900 mb-4">Delete All Data</h3>
              <p className="text-gray-600 mb-6">
                Permanently remove all your practice data. This action cannot be undone.
              </p>
              
              <button
                onClick={openDeleteModal}
                disabled={sessions.length === 0}
                className={`w-full px-6 py-3 bg-red-600 text-white rounded-lg hover:bg-red-700 disabled:bg-gray-400 disabled:cursor-not-allowed font-medium ${reducedMotion ? '' : 'transition-colors'} focus:ring-2 focus:ring-red-500 focus:ring-offset-2`}
                aria-label="Delete all practice data permanently"
              >
                {sessions.length === 0 ? 'No Data to Delete' : 'Delete All Data'}
              </button>
              
              <div className="mt-4 text-sm text-red-600">
                <p>• Permanently removes {sessions.length} sessions</p>
                <p>• Cannot be undone</p>
                <p>• Consider exporting first</p>
              </div>
            </div>
          </div>
        </div>

        {/* Privacy notice */}
        <div className="mt-8 bg-blue-50 rounded-lg p-6 border border-blue-200">
          <h3 className="text-lg font-semibold text-blue-800 mb-3">Privacy & Data Control</h3>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm text-blue-700">
            <div>
              <strong>Local Storage:</strong> All your data is stored locally on your device. We never upload or access your practice data.
            </div>
            <div>
              <strong>Export Format:</strong> JSON format includes metrics, timestamps, and summaries. No audio files or personal information.
            </div>
            <div>
              <strong>Complete Control:</strong> You can export your data anytime or delete everything with a single click.
            </div>
            <div>
              <strong>No Recovery:</strong> Deleted data cannot be recovered. Make sure to export before deleting if you want to keep a backup.
            </div>
          </div>
        </div>
      </main>

      {/* Delete confirmation modal */}
      {showDeleteModal && (
        <div 
          className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50"
          role="dialog"
          aria-modal="true"
          aria-labelledby="delete-modal-title"
          aria-describedby="delete-modal-description"
        >
          <div className="bg-white rounded-lg p-8 max-w-md w-full mx-4">
            <h2 id="delete-modal-title" className="text-2xl font-bold text-gray-900 mb-4">
              Confirm Data Deletion
            </h2>
            
            <p id="delete-modal-description" className="text-gray-600 mb-6">
              This will permanently delete all {sessions.length} practice sessions. This action cannot be undone.
            </p>
            
            <div className="mb-6">
              <label htmlFor="delete-confirm" className="block text-sm font-medium text-gray-700 mb-2">
                Type <strong>DELETE</strong> to confirm:
              </label>
              <input
                id="delete-confirm"
                type="text"
                value={deleteConfirmText}
                onChange={(e) => setDeleteConfirmText(e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-red-500 focus:border-red-500"
                placeholder="Type DELETE here"
                autoComplete="off"
              />
            </div>
            
            <div className="flex space-x-4">
              <button
                onClick={closeDeleteModal}
                className={`flex-1 px-4 py-2 bg-gray-600 text-white rounded-lg hover:bg-gray-700 font-medium ${reducedMotion ? '' : 'transition-colors'} focus:ring-2 focus:ring-gray-500 focus:ring-offset-2`}
                aria-label="Cancel deletion"
              >
                Cancel
              </button>
              
              <button
                onClick={deleteAllData}
                disabled={deleteConfirmText !== 'DELETE' || isDeleting}
                className={`flex-1 px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 disabled:bg-gray-400 disabled:cursor-not-allowed font-medium ${reducedMotion ? '' : 'transition-colors'} focus:ring-2 focus:ring-red-500 focus:ring-offset-2`}
                aria-label="Permanently delete all data"
              >
                {isDeleting ? 'Deleting...' : 'Delete All'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
