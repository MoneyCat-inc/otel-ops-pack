/**
 * BetaMetricsPanel Component
 * 
 * C6: Beta Success Metrics
 * Displays retention, comfort/fatigue trends, strain health, and session frequency metrics.
 */

import React from 'react';
import { ProgressTrends } from '../../engine/metrics/aggregate';
import { MetricCard } from './MetricCard';
import { TrendSpark } from './TrendSpark';
import { useReducedMotion } from '../../hooks/useReducedMotion';

interface BetaMetricsPanelProps {
  trends: ProgressTrends;
  className?: string;
}

export const BetaMetricsPanel: React.FC<BetaMetricsPanelProps> = ({
  trends,
  className = ''
}) => {
  const reducedMotion = useReducedMotion();

  // Get latest metrics
  const latestDay = trends.daily[trends.daily.length - 1];
  const previousDay = trends.daily[trends.daily.length - 2];

  if (!latestDay) {
    return (
      <div className={`bg-white rounded-lg shadow-sm p-6 border border-gray-200 ${className}`}>
        <h2 className="text-xl font-semibold text-gray-900 mb-4">Beta Success Metrics</h2>
        <p className="text-gray-600">No data available yet. Start practicing to see your beta metrics!</p>
      </div>
    );
  }

  // Extract trend data for sparklines
  const retentionTrendData = trends.daily.map(d => d.betaMetrics.retentionPct);
  const comfortTrendData = trends.daily.map(d => d.betaMetrics.comfortTrend.mean);
  const fatigueTrendData = trends.daily.map(d => d.betaMetrics.fatigueTrend.mean);
  const frequencyTrendData = trends.daily.map(d => d.betaMetrics.sessionFrequency);

  // Get strain health color
  const getStrainHealthColor = (health: string) => {
    switch (health) {
      case 'excellent': return 'green';
      case 'good': return 'blue';
      case 'moderate': return 'orange';
      case 'poor': return 'red';
      default: return 'gray';
    }
  };

  const getStrainHealthIcon = (health: string) => {
    switch (health) {
      case 'excellent': return '🟢';
      case 'good': return '🔵';
      case 'moderate': return '🟡';
      case 'poor': return '🔴';
      default: return '⚪';
    }
  };

  return (
    <div 
      className={`bg-white rounded-lg shadow-sm p-6 border border-gray-200 ${className}`}
      role="region"
      aria-labelledby="beta-metrics-title"
    >
      {/* Header */}
      <div className="mb-6">
        <h2 
          id="beta-metrics-title"
          className="text-xl font-semibold text-gray-900 mb-2"
        >
          Beta Success Metrics
        </h2>
        <p className="text-sm text-gray-600">
          Track your engagement, comfort, and practice health over time.
        </p>
      </div>

      {/* Metrics Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {/* Retention */}
        <MetricCard
          title="Retention"
          currentValue={latestDay.betaMetrics.retentionPct}
          previousValue={previousDay?.betaMetrics.retentionPct || 0}
          trend={latestDay.betaMetrics.retentionTrend}
          format="percentage"
          color="blue"
          trendData={retentionTrendData}
          description="Days with practice / days since install"
        />

        {/* Comfort Trend */}
        <MetricCard
          title="Comfort Level"
          currentValue={latestDay.betaMetrics.comfortTrend.mean}
          previousValue={previousDay?.betaMetrics.comfortTrend.mean || 0}
          trend={latestDay.betaMetrics.comfortTrend.trend}
          format="decimal"
          color="green"
          trendData={comfortTrendData}
          description="Average comfort rating (1-5 scale)"
        />

        {/* Strain Health */}
        <div 
          className="p-6 rounded-lg border-2 bg-gray-50 border-gray-200"
          role="region"
          aria-labelledby="strain-health-title"
        >
          <div className="flex items-center justify-between mb-4">
            <h3 
              id="strain-health-title"
              className="text-lg font-semibold text-gray-800"
            >
              Strain Health
            </h3>
            <div className="flex items-center space-x-2">
              <span className="text-2xl" aria-hidden="true">
                {getStrainHealthIcon(latestDay.betaMetrics.strainHealth)}
              </span>
              <span className="text-sm font-medium text-gray-600 capitalize">
                {latestDay.betaMetrics.strainHealth}
              </span>
            </div>
          </div>

          <div className="mb-4">
            <div className="text-3xl font-bold text-gray-800 mb-1">
              {latestDay.betaMetrics.strainPer100Min.toFixed(1)}
              <span className="text-lg ml-1 text-gray-600">per 100min</span>
            </div>
            
            {previousDay && (
              <div className="text-sm text-gray-600">
                {latestDay.betaMetrics.strainPer100Min > previousDay.betaMetrics.strainPer100Min ? '+' : ''}
                {(latestDay.betaMetrics.strainPer100Min - previousDay.betaMetrics.strainPer100Min).toFixed(1)}
                <span className="ml-1">from yesterday</span>
              </div>
            )}
          </div>

          {/* Strain trend sparkline */}
          <div className="mb-3">
            <TrendSpark
              data={trends.daily.map(d => d.betaMetrics.strainPer100Min)}
              color="#6B7280"
              aria-label="Strain rate trend over time"
            />
          </div>

          <p className="text-sm text-gray-600 opacity-75">
            Strain events per 100 minutes of practice
          </p>
        </div>

        {/* Session Frequency */}
        <MetricCard
          title="Session Frequency"
          currentValue={latestDay.betaMetrics.sessionFrequency}
          previousValue={previousDay?.betaMetrics.sessionFrequency || 0}
          trend={latestDay.betaMetrics.frequencyTrend}
          format="decimal"
          color="purple"
          trendData={frequencyTrendData}
          description="Average sessions per week"
        />
      </div>

      {/* Additional Insights */}
      <div className="mt-8 pt-6 border-t border-gray-200">
        <h3 className="text-lg font-semibold text-gray-900 mb-4">Health Insights</h3>
        
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          {/* Comfort vs Fatigue */}
          <div className="bg-blue-50 rounded-lg p-4 border border-blue-200">
            <h4 className="font-medium text-blue-800 mb-2">Comfort vs Fatigue</h4>
            <div className="space-y-2">
              <div className="flex justify-between text-sm">
                <span className="text-blue-700">Comfort:</span>
                <span className="font-medium text-blue-800">
                  {latestDay.betaMetrics.comfortTrend.mean.toFixed(1)}/5
                </span>
              </div>
              <div className="flex justify-between text-sm">
                <span className="text-blue-700">Fatigue:</span>
                <span className="font-medium text-blue-800">
                  {latestDay.betaMetrics.fatigueTrend.mean.toFixed(1)}/5
                </span>
              </div>
              <div className="mt-2">
                <div className="w-full bg-blue-200 rounded-full h-2">
                  <div 
                    className="bg-blue-600 h-2 rounded-full transition-all duration-300"
                    style={{ 
                      width: `${Math.min(100, (latestDay.betaMetrics.comfortTrend.mean / 5) * 100)}%` 
                    }}
                  ></div>
                </div>
                <p className="text-xs text-blue-600 mt-1">
                  Comfort level: {latestDay.betaMetrics.comfortTrend.trend === 'up' ? 'Improving' : 
                                 latestDay.betaMetrics.comfortTrend.trend === 'down' ? 'Declining' : 'Stable'}
                </p>
              </div>
            </div>
          </div>

          {/* Practice Consistency */}
          <div className="bg-green-50 rounded-lg p-4 border border-green-200">
            <h4 className="font-medium text-green-800 mb-2">Practice Consistency</h4>
            <div className="space-y-2">
              <div className="flex justify-between text-sm">
                <span className="text-green-700">Retention:</span>
                <span className="font-medium text-green-800">
                  {(latestDay.betaMetrics.retentionPct * 100).toFixed(1)}%
                </span>
              </div>
              <div className="flex justify-between text-sm">
                <span className="text-green-700">Frequency:</span>
                <span className="font-medium text-green-800">
                  {latestDay.betaMetrics.sessionFrequency.toFixed(1)}/week
                </span>
              </div>
              <div className="mt-2">
                <div className="w-full bg-green-200 rounded-full h-2">
                  <div 
                    className="bg-green-600 h-2 rounded-full transition-all duration-300"
                    style={{ 
                      width: `${Math.min(100, latestDay.betaMetrics.retentionPct * 100)}%` 
                    }}
                  ></div>
                </div>
                <p className="text-xs text-green-600 mt-1">
                  Retention trend: {latestDay.betaMetrics.retentionTrend === 'up' ? 'Improving' : 
                                  latestDay.betaMetrics.retentionTrend === 'down' ? 'Declining' : 'Stable'}
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Screen reader summary */}
      <div 
        aria-live="polite" 
        aria-atomic="true" 
        className="sr-only"
        role="status"
      >
        Beta metrics summary: {Math.round(latestDay.betaMetrics.retentionPct * 100)}% retention, 
        {latestDay.betaMetrics.comfortTrend.mean.toFixed(1)} comfort level, 
        {latestDay.betaMetrics.strainHealth} strain health, 
        {latestDay.betaMetrics.sessionFrequency.toFixed(1)} sessions per week.
      </div>
    </div>
  );
};
