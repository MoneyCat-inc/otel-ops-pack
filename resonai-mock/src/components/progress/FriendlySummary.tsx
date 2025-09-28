/**
 * FriendlySummary Component
 * 
 * C7: Dashboard Polish & UX
 * User-friendly summary blocks with encouraging, non-technical language.
 * Includes accessibility announcements via polite live regions.
 */

'use client';

import React, { useMemo } from 'react';
import { ProgressTrends } from '../../engine/metrics/aggregate';

interface FriendlySummaryProps {
  /** Progress trends data */
  trends: ProgressTrends;
  /** Date range for context */
  dateRange: '7d' | '14d' | '30d' | 'all';
  /** Custom className */
  className?: string;
}

interface SummaryData {
  /** Main summary message */
  message: string;
  /** Encouraging sub-message */
  encouragement: string;
  /** Key statistics */
  stats: {
    sessions: number;
    practiceTime: string;
    avgSession: string;
    safetyTrend: string;
  };
  /** Color theme based on progress */
  theme: 'positive' | 'neutral' | 'attention';
}

export const FriendlySummary: React.FC<FriendlySummaryProps> = ({
  trends,
  dateRange,
  className = ''
}) => {
  const summaryData = useMemo((): SummaryData => {
    const { totalSessions, totalDurationMs, averageSessionDurationMs, overallTrend } = trends;
    
    // Calculate practice time in friendly format
    const hours = Math.round(totalDurationMs / (1000 * 60 * 60));
    const minutes = Math.round((totalDurationMs % (1000 * 60 * 60)) / (1000 * 60));
    const practiceTime = hours > 0 ? `${hours}h ${minutes}m` : `${minutes}m`;
    
    // Calculate average session in friendly format
    const avgMinutes = Math.round(averageSessionDurationMs / (1000 * 60));
    const avgSession = `${avgMinutes} minutes`;
    
    // Determine safety trend message
    const safetyTrend = overallTrend.safety === 'improving' ? 'getting safer' :
                       overallTrend.safety === 'declining' ? 'needs attention' : 'stable';
    
    // Count cooldowns (sessions with strain)
    const cooldowns = trends.daily.reduce((count, day) => count + day.strainCount, 0);
    
    // Determine theme based on progress
    const isPositive = overallTrend.safety === 'improving' && totalSessions >= 3;
    const needsAttention = overallTrend.safety === 'declining' || cooldowns > totalSessions * 0.3;
    const theme = isPositive ? 'positive' : needsAttention ? 'attention' : 'neutral';
    
    // Generate date range text
    const rangeText = dateRange === '7d' ? 'Last 7 days' :
                     dateRange === '14d' ? 'Last 2 weeks' :
                     dateRange === '30d' ? 'Last month' : 'All time';
    
    // Generate main message
    let message: string;
    let encouragement: string;
    
    if (totalSessions === 0) {
      message = "Ready to start your voice practice journey?";
      encouragement = "Your first session is just a click away!";
    } else if (totalSessions === 1) {
      message = "Great start! You've completed your first practice session.";
      encouragement = "Keep the momentum going with another session today!";
    } else if (totalSessions < 3) {
      message = `Nice progress! You've practiced ${totalSessions} times.`;
      encouragement = "Building a consistent routine takes time - you're on the right track!";
    } else if (isPositive) {
      message = `${rangeText} — ${totalSessions} safe sessions, ${cooldowns} cooldowns, steady progress`;
      encouragement = "Your consistent practice is paying off! Keep up the great work.";
    } else if (needsAttention) {
      message = `${rangeText} — ${totalSessions} sessions with ${cooldowns} cooldowns`;
      encouragement = "Consider shorter sessions or more breaks to keep your voice healthy.";
    } else {
      message = `${rangeText} — ${totalSessions} sessions, ${cooldowns} cooldowns, stable progress`;
      encouragement = "You're maintaining a good practice rhythm. Keep it up!";
    }
    
    return {
      message,
      encouragement,
      stats: {
        sessions: totalSessions,
        practiceTime,
        avgSession,
        safetyTrend
      },
      theme
    };
  }, [trends, dateRange]);

  // Theme classes
  const themeClasses = {
    positive: {
      container: 'bg-green-50 border-green-200',
      message: 'text-green-800',
      encouragement: 'text-green-600',
      accent: 'text-green-700'
    },
    neutral: {
      container: 'bg-blue-50 border-blue-200',
      message: 'text-blue-800',
      encouragement: 'text-blue-600',
      accent: 'text-blue-700'
    },
    attention: {
      container: 'bg-amber-50 border-amber-200',
      message: 'text-amber-800',
      encouragement: 'text-amber-600',
      accent: 'text-amber-700'
    }
  };

  const theme = themeClasses[summaryData.theme];

  return (
    <div 
      className={`p-6 rounded-lg border-2 ${theme.container} ${className}`}
      role="region"
      aria-labelledby="friendly-summary-title"
    >
      {/* Screen reader announcement */}
      <div 
        aria-live="polite" 
        aria-atomic="true" 
        className="sr-only"
        role="status"
      >
        Progress summary: {summaryData.message}. {summaryData.encouragement}
      </div>

      {/* Header */}
      <h2 
        id="friendly-summary-title"
        className={`text-xl font-semibold ${theme.message} mb-3`}
      >
        Your Practice Summary
      </h2>

      {/* Main message */}
      <p className={`text-lg ${theme.message} mb-4 leading-relaxed`}>
        {summaryData.message}
      </p>

      {/* Encouragement */}
      <p className={`text-sm ${theme.encouragement} mb-4 italic`}>
        {summaryData.encouragement}
      </p>

      {/* Stats grid */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <div className="text-center">
          <div className={`text-2xl font-bold ${theme.accent}`}>
            {summaryData.stats.sessions}
          </div>
          <div className={`text-xs ${theme.message} opacity-75`}>
            Sessions
          </div>
        </div>
        
        <div className="text-center">
          <div className={`text-2xl font-bold ${theme.accent}`}>
            {summaryData.stats.practiceTime}
          </div>
          <div className={`text-xs ${theme.message} opacity-75`}>
            Practice Time
          </div>
        </div>
        
        <div className="text-center">
          <div className={`text-2xl font-bold ${theme.accent}`}>
            {summaryData.stats.avgSession}
          </div>
          <div className={`text-xs ${theme.message} opacity-75`}>
            Avg Session
          </div>
        </div>
        
        <div className="text-center">
          <div className={`text-2xl font-bold ${theme.accent}`}>
            {summaryData.stats.safetyTrend === 'getting safer' ? '🛡️' :
             summaryData.stats.safetyTrend === 'needs attention' ? '⚠️' : '➡️'}
          </div>
          <div className={`text-xs ${theme.message} opacity-75`}>
            Safety
          </div>
        </div>
      </div>

      {/* Additional context for screen readers */}
      <div className="sr-only">
        <p>
          You have completed {summaryData.stats.sessions} practice sessions totaling {summaryData.stats.practiceTime} of practice time.
          Your average session length is {summaryData.stats.avgSession}.
          Your safety trend is {summaryData.stats.safetyTrend}.
        </p>
      </div>
    </div>
  );
};

export default FriendlySummary;
