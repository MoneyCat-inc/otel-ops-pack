/**
 * Cohort Feature Flags
 * 
 * C4: Cohort Analytics Toggles
 * Runtime feature flags for controlled cohort rollout. Defaults OFF.
 */

export type CohortFlags = {
  enabled: boolean;           // master switch
  dashboardEntry: boolean;    // show /progress CTA
  eventSummary: boolean;      // show local-only session summary block
};

/**
 * Environment variable reader that works both SSR and CSR
 * @param key Environment variable name
 * @param defaultValue Default value ('0' or '1')
 * @returns Environment variable value or default
 */
const env = (key: string, defaultValue: '0' | '1' = '0'): string => {
  if (typeof window === 'undefined') {
    // Server-side rendering
    return process.env[key] ?? defaultValue;
  } else {
    // Client-side rendering
    return (window as any).__env?.[key] ?? defaultValue;
  }
};

/**
 * Cohort feature flags configuration
 * All flags default to OFF (false) for privacy and controlled rollout
 */
export const flags: CohortFlags = {
  enabled: env('NEXT_PUBLIC_COHORT_ENABLED', '0') === '1',
  dashboardEntry: env('NEXT_PUBLIC_COHORT_DASHBOARD_ENTRY', '0') === '1',
  eventSummary: env('NEXT_PUBLIC_COHORT_EVENT_SUMMARY', '0') === '1',
};

/**
 * Check if cohort features are enabled
 * @returns true if any cohort feature is enabled
 */
export const isCohortEnabled = (): boolean => {
  return flags.enabled;
};

/**
 * Check if dashboard entry CTA should be shown
 * @returns true if both master and dashboard entry flags are enabled
 */
export const shouldShowDashboardEntry = (): boolean => {
  return flags.enabled && flags.dashboardEntry;
};

/**
 * Check if event summary should be shown
 * @returns true if both master and event summary flags are enabled
 */
export const shouldShowEventSummary = (): boolean => {
  return flags.enabled && flags.eventSummary;
};

/**
 * Get all enabled cohort features
 * @returns Array of enabled feature names
 */
export const getEnabledFeatures = (): string[] => {
  const enabled: string[] = [];
  
  if (flags.enabled) {
    enabled.push('cohort');
  }
  
  if (flags.dashboardEntry) {
    enabled.push('dashboard-entry');
  }
  
  if (flags.eventSummary) {
    enabled.push('event-summary');
  }
  
  return enabled;
};

/**
 * Validate flag combinations
 * @returns true if flags are in a valid state
 */
export const validateFlags = (): boolean => {
  // Dashboard entry and event summary require master flag
  if (flags.dashboardEntry && !flags.enabled) {
    console.warn('Cohort: dashboardEntry enabled but master flag disabled');
    return false;
  }
  
  if (flags.eventSummary && !flags.enabled) {
    console.warn('Cohort: eventSummary enabled but master flag disabled');
    return false;
  }
  
  return true;
};

/**
 * Debug information for development
 * @returns Object with flag states and environment info
 */
export const getDebugInfo = () => {
  return {
    flags,
    enabledFeatures: getEnabledFeatures(),
    isValid: validateFlags(),
    environment: {
      nodeEnv: process.env.NODE_ENV,
      cohortEnabled: process.env.NEXT_PUBLIC_COHORT_ENABLED,
      dashboardEntry: process.env.NEXT_PUBLIC_COHORT_DASHBOARD_ENTRY,
      eventSummary: process.env.NEXT_PUBLIC_COHORT_EVENT_SUMMARY,
    }
  };
};
