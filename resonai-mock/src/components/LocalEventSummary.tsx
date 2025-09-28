/**
 * Local Event Summary Component
 * 
 * C4: Cohort Analytics Toggles
 * Shows local-only session summary for cohort users.
 */

'use client';

import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import { shouldShowEventSummary } from '../config/flags';
import { useReducedMotion } from '../hooks/useReducedMotion';

interface SessionSummary {
  totalSessions: number;
  lastSevenDays: number;
  averageAccuracy: number;
  averageComfort: number;
  lastSessionDate: string | null;
}

export const LocalEventSummary: React.FC = () => {
  const [summary, setSummary] = useState<SessionSummary | null>(null);
  const [loading, setLoading] = useState(true);
  const reducedMotion = useReducedMotion();

  useEffect(() => {
    loadLocalSummary();
  }, []);

  const loadLocalSummary = async () => {
    try {
      setLoading(true);

      // In a real implementation, this would read from IndexedDB
      // For now, we'll use mock data that matches the expected schema
      const mockSummary: SessionSummary = {
        totalSessions: 15,
        lastSevenDays: 8,
        averageAccuracy: 78.5,
        averageComfort: 4.2,
        lastSessionDate: new Date().toISOString().split('T')[0]
      };

      setSummary(mockSummary);
    } catch (error) {
      console.error('Failed to load local summary:', error);
    } finally {
      setLoading(false);
    }
  };

  // Only show if cohort flags are enabled
  if (!shouldShowEventSummary()) {
    return null;
  }

  if (loading) {
    return (
      <div className="bg-gradient-to-r from-blue-50 to-indigo-50 rounded-lg p-4 border border-blue-200">
        <div className="flex items-center space-x-3">
          <div className={`w-4 h-4 border-2 border-blue-600 border-t-transparent rounded-full ${reducedMotion ? '' : 'animate-spin'}`}></div>
          <span className="text-blue-700 text-sm">Loading your practice summary...</span>
        </div>
      </div>
    );
  }

  if (!summary) {
    return (
      <div className="bg-gradient-to-r from-gray-50 to-gray-100 rounded-lg p-4 border border-gray-200">
        <div className="text-center">
          <span className="text-gray-600 text-sm">No practice data available yet</span>
        </div>
      </div>
    );
  }

  return (
    <div className="bg-gradient-to-r from-blue-50 to-indigo-50 rounded-lg p-4 border border-blue-200">
      <div className="flex items-center justify-between mb-3">
        <h3 className="text-lg font-semibold text-blue-800">Your Practice Summary</h3>
        <Link
          href="/progress"
          className={`text-blue-600 hover:text-blue-700 text-sm font-medium ${reducedMotion ? '' : 'transition-colors'} focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 rounded px-2 py-1`}
          aria-label="View detailed progress dashboard"
        >
          View Details →
        </Link>
      </div>
      
      <div className="grid grid-cols-2 gap-4 text-sm">
        <div className="text-center">
          <div className={`text-2xl font-bold text-blue-600 ${reducedMotion ? '' : 'transition-all duration-300'}`}>
            {summary.totalSessions}
          </div>
          <div className="text-blue-700">Total Sessions</div>
        </div>
        
        <div className="text-center">
          <div className={`text-2xl font-bold text-blue-600 ${reducedMotion ? '' : 'transition-all duration-300'}`}>
            {summary.lastSevenDays}
          </div>
          <div className="text-blue-700">This Week</div>
        </div>
        
        <div className="text-center">
          <div className={`text-2xl font-bold text-blue-600 ${reducedMotion ? '' : 'transition-all duration-300'}`}>
            {summary.averageAccuracy.toFixed(0)}%
          </div>
          <div className="text-blue-700">Avg Accuracy</div>
        </div>
        
        <div className="text-center">
          <div className={`text-2xl font-bold text-blue-600 ${reducedMotion ? '' : 'transition-all duration-300'}`}>
            {summary.averageComfort.toFixed(1)}/5
          </div>
          <div className="text-blue-700">Avg Comfort</div>
        </div>
      </div>
      
      {summary.lastSessionDate && (
        <div className="mt-3 pt-3 border-t border-blue-200">
          <div className="text-center text-xs text-blue-600">
            Last session: {new Date(summary.lastSessionDate).toLocaleDateString()}
          </div>
        </div>
      )}
      
      <div className="mt-3 pt-3 border-t border-blue-200">
        <div className="text-xs text-blue-600 text-center">
          📊 All data stays local • No uploads • Complete privacy
        </div>
      </div>
    </div>
  );
};
