/**
 * Cohort CTA Component
 * 
 * C4: Cohort Analytics Toggles
 * Conditional dashboard entry CTA for cohort users.
 */

'use client';

import React from 'react';
import Link from 'next/link';
import { shouldShowDashboardEntry } from '../config/flags';
import { useReducedMotion } from '../hooks/useReducedMotion';

export const CohortCTA: React.FC = () => {
  const reducedMotion = useReducedMotion();

  // Only show if cohort flags are enabled
  if (!shouldShowDashboardEntry()) {
    return null;
  }

  return (
    <Link
      href="/progress"
      className={`inline-flex items-center px-3 py-2 text-sm font-medium text-white bg-gradient-to-r from-purple-600 to-indigo-600 rounded-lg hover:from-purple-700 hover:to-indigo-700 focus:ring-2 focus:ring-purple-500 focus:ring-offset-2 ${reducedMotion ? '' : 'transition-all duration-200'} shadow-sm`}
      aria-label="View your progress dashboard"
    >
      <span className="mr-2">📊</span>
      Progress
    </Link>
  );
};
