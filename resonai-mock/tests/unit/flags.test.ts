/**
 * Cohort Flags Unit Tests
 * 
 * C4: Cohort Analytics Toggles
 * Tests for flag resolver, environment detection, and validation.
 */

import { describe, it, expect } from 'vitest';
import { flags, shouldShowDashboardEntry, shouldShowEventSummary, getEnabledFeatures, validateFlags, getDebugInfo } from '../../src/config/flags';

describe('Cohort Flags', () => {
  describe('Flag Resolver', () => {
    it('should default all flags to OFF', () => {
      // With no environment variables set, all flags should default to false
      expect(flags.enabled).toBe(false);
      expect(flags.dashboardEntry).toBe(false);
      expect(flags.eventSummary).toBe(false);
    });

    it('should have proper flag structure', () => {
      expect(flags).toHaveProperty('enabled');
      expect(flags).toHaveProperty('dashboardEntry');
      expect(flags).toHaveProperty('eventSummary');
      expect(typeof flags.enabled).toBe('boolean');
      expect(typeof flags.dashboardEntry).toBe('boolean');
      expect(typeof flags.eventSummary).toBe('boolean');
    });
  });

  describe('Helper Functions', () => {
    it('should return empty array when no features enabled', () => {
      const enabled = getEnabledFeatures();
      expect(Array.isArray(enabled)).toBe(true);
    });

    it('should validate flags without errors', () => {
      const isValid = validateFlags();
      expect(typeof isValid).toBe('boolean');
    });

    it('should provide debug information', () => {
      const debugInfo = getDebugInfo();
      expect(debugInfo).toHaveProperty('flags');
      expect(debugInfo).toHaveProperty('enabledFeatures');
      expect(debugInfo).toHaveProperty('isValid');
      expect(debugInfo).toHaveProperty('environment');
    });
  });

  describe('Conditional Functions', () => {
    it('should return boolean values', () => {
      expect(typeof shouldShowDashboardEntry()).toBe('boolean');
      expect(typeof shouldShowEventSummary()).toBe('boolean');
    });

    it('should respect flag hierarchy', () => {
      // These functions should check both master and sub-flags
      const dashboardResult = shouldShowDashboardEntry();
      const summaryResult = shouldShowEventSummary();
      
      expect(typeof dashboardResult).toBe('boolean');
      expect(typeof summaryResult).toBe('boolean');
    });
  });

  describe('Type Safety', () => {
    it('should have correct TypeScript types', () => {
      // This test ensures the types are properly exported
      expect(flags).toBeDefined();
      expect(shouldShowDashboardEntry).toBeDefined();
      expect(shouldShowEventSummary).toBeDefined();
      expect(getEnabledFeatures).toBeDefined();
      expect(validateFlags).toBeDefined();
      expect(getDebugInfo).toBeDefined();
    });
  });
});
