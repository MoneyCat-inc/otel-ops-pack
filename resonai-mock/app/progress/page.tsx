/**
 * Progress Dashboard Page
 * 
 * C1: Progress Dashboard
 * Local-first progress visualization with trends, metrics, and safety timeline.
 */

'use client';

import React, { useState, useEffect } from 'react';
import { ProgressAggregator, ProgressTrends, SessionSummaryV1 } from '../../src/engine/metrics/aggregate';
import { MetricCard } from '../../src/components/progress/MetricCard';
import { SafetyStrip } from '../../src/components/progress/SafetyStrip';
import { FriendlySummary } from '../../src/components/progress/FriendlySummary';
import { OrbV2 } from '../../src/components/OrbV2';
import { useReducedMotion } from '../../src/hooks/useReducedMotion';
import Link from 'next/link';

export default function ProgressPage() {
  const [trends, setTrends] = useState<ProgressTrends | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [dateRange, setDateRange] = useState<'7d' | '14d' | '30d' | 'all'>('30d');
  const [selectedMetrics, setSelectedMetrics] = useState({
    inBand: true,
    expressiveness: true,
    resonance: true,
    safety: true
  });
  
  const reducedMotion = useReducedMotion();
  const aggregator = new ProgressAggregator();

  // Load session data from IndexedDB
  useEffect(() => {
    loadProgressData();
  }, [dateRange]);

  const loadProgressData = async () => {
    try {
      setLoading(true);
      setError(null);

      // In a real implementation, this would read from IndexedDB
      // For now, we'll use mock data that matches the expected schema
      const mockSessions: SessionSummaryV1[] = generateMockSessions();
      
      // Calculate date range
      const endDate = new Date();
      const startDate = new Date();
      switch (dateRange) {
        case '7d':
          startDate.setDate(endDate.getDate() - 7);
          break;
        case '14d':
          startDate.setDate(endDate.getDate() - 14);
          break;
        case '30d':
          startDate.setDate(endDate.getDate() - 30);
          break;
        case 'all':
          startDate.setTime(0); // All time
          break;
      }

      const range = {
        start: startDate.toISOString().split('T')[0],
        end: endDate.toISOString().split('T')[0]
      };

      // Generate trends
      const progressTrends = aggregator.generateTrends(mockSessions, range);
      setTrends(progressTrends);

    } catch (err) {
      console.error('Failed to load progress data:', err);
      setError('Failed to load progress data. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  const generateMockSessions = (): SessionSummaryV1[] => {
    const sessions: SessionSummaryV1[] = [];
    const now = Date.now();
    
    // Generate sessions for the last 30 days
    for (let i = 0; i < 30; i++) {
      const date = new Date(now - i * 24 * 60 * 60 * 1000);
      
      // Generate 1-3 sessions per day
      const sessionsPerDay = Math.floor(Math.random() * 3) + 1;
      
      for (let j = 0; j < sessionsPerDay; j++) {
        const sessionTime = new Date(date.getTime() + j * 2 * 60 * 60 * 1000); // 2 hours apart
        
        sessions.push({
          id: sessions.length + 1,
          ts: sessionTime.getTime(),
          medianF0: 150 + Math.random() * 50,
          inBandPct: 0.6 + Math.random() * 0.3,
          prosodyVar: 0.4 + Math.random() * 0.4,
          voicedTimePct: 0.7 + Math.random() * 0.2,
          jitterEma: 0.1 + Math.random() * 0.2,
          comfort: (Math.floor(Math.random() * 5) + 1) as 1 | 2 | 3 | 4 | 5,
          fatigue: (Math.floor(Math.random() * 5) + 1) as 1 | 2 | 3 | 4 | 5,
          euphoria: (Math.floor(Math.random() * 5) + 1) as 1 | 2 | 3 | 4 | 5,
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
    }
    
    return sessions.sort((a, b) => a.ts - b.ts);
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 flex items-center justify-center">
        <div className="text-center">
          <div className={`w-8 h-8 border-4 border-blue-600 border-t-transparent rounded-full ${reducedMotion ? '' : 'animate-spin'} mx-auto mb-4`}></div>
          <p className="text-gray-600">Loading your progress...</p>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 flex items-center justify-center">
        <div className="text-center">
          <div className="text-red-500 text-6xl mb-4">⚠️</div>
          <h2 className="text-2xl font-bold text-gray-800 mb-2">Unable to Load Progress</h2>
          <p className="text-gray-600 mb-6">{error}</p>
          <button
            onClick={loadProgressData}
            className="px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 transition-colors"
          >
            Try Again
          </button>
        </div>
      </div>
    );
  }

  if (!trends || trends.daily.length === 0) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100">
        <div className="container mx-auto px-4 py-8">
          <div className="text-center">
            <div className="text-blue-500 text-6xl mb-4">📊</div>
            <h1 className="text-3xl font-bold text-gray-800 mb-2">No Progress Data Yet</h1>
            <p className="text-gray-600 mb-6">Start practicing to see your progress trends!</p>
            <Link
              href="/practice"
              className="px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 transition-colors"
            >
              Start Practicing
            </Link>
          </div>
        </div>
      </div>
    );
  }

  // Get latest metrics for cards
  const latestDay = trends.daily[trends.daily.length - 1];
  const previousDay = trends.daily[trends.daily.length - 2];

  // Extract trend data for sparklines
  const inBandTrendData = trends.daily.map(d => d.inBandPct.mean);
  const expressivenessTrendData = trends.daily.map(d => d.expressiveness01.mean);
  const safetyTrendData = trends.daily.map(d => d.strainRate);

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100">
      {/* Screen reader announcements */}
      <div 
        aria-live="polite" 
        aria-atomic="true" 
        className="sr-only"
        role="status"
      >
        Progress dashboard loaded. {trends.totalSessions} sessions analyzed.
      </div>

      {/* Skip link for keyboard users */}
      <a 
        href="#main-content" 
        className="sr-only focus:not-sr-only focus:absolute focus:top-4 focus:left-4 bg-blue-600 text-white px-4 py-2 rounded-md z-50"
      >
        Skip to main content
      </a>

      {/* Header */}
      <header className="bg-white shadow-sm border-b">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center py-4">
            <div className="flex items-center space-x-3">
              <Link href="/" className="flex items-center space-x-3 hover:opacity-80 transition-opacity">
                <div className="w-8 h-8 bg-gradient-to-r from-blue-600 to-purple-600 rounded-lg flex items-center justify-center">
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
                href="/listen"
                className="text-gray-600 hover:text-gray-900 px-3 py-2 rounded-md text-sm font-medium transition-colors"
              >
                Listen
              </Link>
              <Link
                href="/progress"
                className="text-blue-600 hover:text-blue-700 px-3 py-2 rounded-md text-sm font-medium transition-colors"
              >
                Progress
              </Link>
            </nav>
          </div>
        </div>
      </header>

      {/* Main content */}
      <main id="main-content" className="container mx-auto px-4 py-8">
        <div className="mb-8">
          <h1 className="text-4xl font-bold text-gray-900 mb-2">Your Progress</h1>
          <p className="text-lg text-gray-600">
            Track your voice practice trends and improvements over time.
          </p>
        </div>

        {/* Controls */}
        <div className="mb-8 bg-white rounded-lg shadow-sm p-6 border border-gray-200">
          <h2 className="text-xl font-semibold text-gray-900 mb-4">View Options</h2>
          
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            {/* Date range selector */}
            <div>
              <label htmlFor="date-range" className="block text-sm font-medium text-gray-700 mb-2">
                Time Period
              </label>
              <select
                id="date-range"
                value={dateRange}
                onChange={(e) => setDateRange(e.target.value as any)}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
              >
                <option value="7d">Last 7 days</option>
                <option value="14d">Last 14 days</option>
                <option value="30d">Last 30 days</option>
                <option value="all">All time</option>
              </select>
            </div>

            {/* Metric toggles */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Show Metrics
              </label>
              <div className="space-y-2">
                {Object.entries(selectedMetrics).map(([key, value]) => (
                  <label key={key} className="flex items-center">
                    <input
                      type="checkbox"
                      checked={value}
                      onChange={(e) => setSelectedMetrics(prev => ({ ...prev, [key]: e.target.checked }))}
                      className="mr-2 focus:ring-2 focus:ring-blue-500"
                    />
                    <span className="text-sm text-gray-700 capitalize">
                      {key === 'inBand' ? 'Pitch Accuracy' : 
                       key === 'expressiveness' ? 'Expressiveness' :
                       key === 'resonance' ? 'Resonance' : 'Safety'}
                    </span>
                  </label>
                ))}
              </div>
            </div>
          </div>
        </div>

        {/* Summary stats */}
        <div className="mb-8 bg-white rounded-lg shadow-sm p-6 border border-gray-200">
          <h2 className="text-xl font-semibold text-gray-900 mb-4">Summary</h2>
          <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
            <div className="text-center">
              <div className="text-3xl font-bold text-blue-600">{trends.totalSessions}</div>
              <div className="text-sm text-gray-600">Total Sessions</div>
            </div>
            <div className="text-center">
              <div className="text-3xl font-bold text-green-600">
                {Math.round(trends.totalDurationMs / (1000 * 60 * 60))}h
              </div>
              <div className="text-sm text-gray-600">Practice Time</div>
            </div>
            <div className="text-center">
              <div className="text-3xl font-bold text-purple-600">
                {Math.round(trends.averageSessionDurationMs / (1000 * 60))}m
              </div>
              <div className="text-sm text-gray-600">Avg Session</div>
            </div>
            <div className="text-center">
              <div className="text-3xl font-bold text-orange-600">
                {trends.overallTrend.safety === 'improving' ? '↗' : 
                 trends.overallTrend.safety === 'declining' ? '↘' : '→'}
              </div>
              <div className="text-sm text-gray-600">Safety Trend</div>
            </div>
          </div>
        </div>

        {/* Metric cards */}
        <div className="mb-8">
          <h2 className="text-xl font-semibold text-gray-900 mb-4">Key Metrics</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {selectedMetrics.inBand && (
              <MetricCard
                title="Pitch Accuracy"
                currentValue={latestDay.inBandPct.mean}
                previousValue={previousDay?.inBandPct.mean || 0}
                trend={latestDay.inBandPct.trend}
                format="percentage"
                color="blue"
                trendData={inBandTrendData}
                description="Percentage of time spent in target pitch range"
              />
            )}
            
            {selectedMetrics.expressiveness && (
              <MetricCard
                title="Expressiveness"
                currentValue={latestDay.expressiveness01.mean}
                previousValue={previousDay?.expressiveness01.mean || 0}
                trend={latestDay.expressiveness01.trend}
                format="decimal"
                color="green"
                trendData={expressivenessTrendData}
                description="Variety and expressiveness in pitch delivery"
              />
            )}
            
            {selectedMetrics.resonance && (
              <MetricCard
                title="Resonance Balance"
                currentValue={latestDay.bucketBias.front}
                previousValue={previousDay?.bucketBias.front || 0}
                trend={latestDay.bucketBias.dominant === 'front' ? 'up' : 'stable'}
                format="percentage"
                color="purple"
                description={`Dominant resonance: ${latestDay.bucketBias.dominant}`}
              />
            )}
          </div>
        </div>

        {/* Safety timeline */}
        {selectedMetrics.safety && (
          <div className="mb-8">
            <h2 className="text-xl font-semibold text-gray-900 mb-4">Safety Timeline</h2>
            <SafetyStrip
              events={trends.daily.map(day => ({
                date: day.date,
                strainCount: day.strainCount,
                strainRate: day.strainRate
              }))}
            />
          </div>
        )}

        {/* What this means section */}
        <div className="bg-blue-50 rounded-lg p-6 border border-blue-200">
          <h3 className="text-lg font-semibold text-blue-800 mb-3">What This Means</h3>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm text-blue-700">
            <div>
              <strong>Pitch Accuracy:</strong> Higher percentages mean you're spending more time in your target pitch range.
            </div>
            <div>
              <strong>Expressiveness:</strong> Higher values indicate more variety and natural expression in your voice.
            </div>
            <div>
              <strong>Resonance Balance:</strong> Shows which part of your vocal tract you're using most (front, central, or back).
            </div>
            <div>
              <strong>Safety Timeline:</strong> Tracks vocal strain events to help you practice safely and avoid injury.
            </div>
          </div>
        </div>
      </main>
    </div>
  );
}
