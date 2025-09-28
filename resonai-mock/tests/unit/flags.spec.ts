/**
 * Cohort Flags Unit Tests
 * 
 * C4: Cohort Analytics Toggles
 * Tests for flag resolver, environment detection, and validation.
 */

import { describe, it, expect, beforeEach, vi } from 'vitest';

// Mock environment variables
const mockEnv = (envVars: Record<string, string>) => {
  const originalEnv = process.env;
  process.env = { ...originalEnv, ...envVars };
  
  return () => {
    process.env = originalEnv;
  };
};

// Mock window object for client-side tests
const mockWindow = (envVars: Record<string, string>) => {
  const originalWindow = global.window;
  global.window = {
    ...originalWindow,
    __env: envVars
  } as any;
  
  return () => {
    global.window = originalWindow;
  };
};

describe('Cohort Flags', () => {
  beforeEach(() => {
    // Clear module cache to ensure fresh imports
    vi.resetModules();
  });

  describe('Flag Resolver', () => {
    it('should default all flags to OFF', async () => {
      const cleanup = mockEnv({});
      const { flags } = await import('../../src/config/flags');
      
      expect(flags.enabled).toBe(false);
      expect(flags.dashboardEntry).toBe(false);
      expect(flags.eventSummary).toBe(false);
      
      cleanup();
    });

    it('should read environment variables correctly', async () => {
      const cleanup = mockEnv({
        NEXT_PUBLIC_COHORT_ENABLED: '1',
        NEXT_PUBLIC_COHORT_DASHBOARD_ENTRY: '1',
        NEXT_PUBLIC_COHORT_EVENT_SUMMARY: '1'
      });
      const { flags } = await import('../../src/config/flags');
      
      expect(flags.enabled).toBe(true);
      expect(flags.dashboardEntry).toBe(true);
      expect(flags.eventSummary).toBe(true);
      
      cleanup();
    });

    it('should handle partial flag configuration', async () => {
      const cleanup = mockEnv({
        NEXT_PUBLIC_COHORT_ENABLED: '1',
        NEXT_PUBLIC_COHORT_DASHBOARD_ENTRY: '0',
        NEXT_PUBLIC_COHORT_EVENT_SUMMARY: '1'
      });
      const { flags } = await import('../../src/config/flags');
      
      expect(flags.enabled).toBe(true);
      expect(flags.dashboardEntry).toBe(false);
      expect(flags.eventSummary).toBe(true);
      
      cleanup();
    });

    it('should handle invalid environment values', async () => {
      const cleanup = mockEnv({
        NEXT_PUBLIC_COHORT_ENABLED: 'true',
        NEXT_PUBLIC_COHORT_DASHBOARD_ENTRY: 'yes',
        NEXT_PUBLIC_COHORT_EVENT_SUMMARY: 'on'
      });
      const { flags } = await import('../../src/config/flags');
      
      // Should default to false for non-'1' values
      expect(flags.enabled).toBe(false);
      expect(flags.dashboardEntry).toBe(false);
      expect(flags.eventSummary).toBe(false);
      
      cleanup();
    });
  });

  describe('Client-Side Environment', () => {
    it('should read from window.__env on client side', async () => {
      const cleanupWindow = mockWindow({
        NEXT_PUBLIC_COHORT_ENABLED: '1',
        NEXT_PUBLIC_COHORT_DASHBOARD_ENTRY: '1',
        NEXT_PUBLIC_COHORT_EVENT_SUMMARY: '0'
      });
      
      // Mock window being defined (client-side)
      Object.defineProperty(global, 'window', {
        value: {
          __env: {
            NEXT_PUBLIC_COHORT_ENABLED: '1',
            NEXT_PUBLIC_COHORT_DASHBOARD_ENTRY: '1',
            NEXT_PUBLIC_COHORT_EVENT_SUMMARY: '0'
          }
        },
        writable: true
      });
      
      const { flags } = await import('../../src/config/flags');
      
      expect(flags.enabled).toBe(true);
      expect(flags.dashboardEntry).toBe(true);
      expect(flags.eventSummary).toBe(false);
      
      cleanupWindow();
    });

    it('should fallback to process.env when window.__env is undefined', async () => {
      const cleanup = mockEnv({
        NEXT_PUBLIC_COHORT_ENABLED: '1'
      });
      
      // Mock window being defined but __env is undefined
      Object.defineProperty(global, 'window', {
        value: {},
        writable: true
      });
      
      const { flags } = await import('../../src/config/flags');
      
      expect(flags.enabled).toBe(true);
      
      cleanup();
    });
  });

  describe('Helper Functions', () => {
    it('should correctly identify enabled features', async () => {
      const cleanup = mockEnv({
        NEXT_PUBLIC_COHORT_ENABLED: '1',
        NEXT_PUBLIC_COHORT_DASHBOARD_ENTRY: '1',
        NEXT_PUBLIC_COHORT_EVENT_SUMMARY: '0'
      });
      const { getEnabledFeatures } = await import('../../src/config/flags');
      
      const enabled = getEnabledFeatures();
      
      expect(enabled).toContain('cohort');
      expect(enabled).toContain('dashboard-entry');
      expect(enabled).not.toContain('event-summary');
      
      cleanup();
    });

    it('should validate flag combinations', async () => {
      const cleanup = mockEnv({
        NEXT_PUBLIC_COHORT_ENABLED: '0',
        NEXT_PUBLIC_COHORT_DASHBOARD_ENTRY: '1', // Invalid: enabled without master
        NEXT_PUBLIC_COHORT_EVENT_SUMMARY: '0'
      });
      const { validateFlags } = await import('../../src/config/flags');
      
      const isValid = validateFlags();
      
      expect(isValid).toBe(false);
      
      cleanup();
    });

    it('should return true for valid flag combinations', async () => {
      const cleanup = mockEnv({
        NEXT_PUBLIC_COHORT_ENABLED: '1',
        NEXT_PUBLIC_COHORT_DASHBOARD_ENTRY: '1',
        NEXT_PUBLIC_COHORT_EVENT_SUMMARY: '1'
      });
      const { validateFlags } = await import('../../src/config/flags');
      
      const isValid = validateFlags();
      
      expect(isValid).toBe(true);
      
      cleanup();
    });
  });

  describe('Conditional Functions', () => {
    it('should show dashboard entry when both flags enabled', async () => {
      const cleanup = mockEnv({
        NEXT_PUBLIC_COHORT_ENABLED: '1',
        NEXT_PUBLIC_COHORT_DASHBOARD_ENTRY: '1'
      });
      const { shouldShowDashboardEntry } = await import('../../src/config/flags');
      
      expect(shouldShowDashboardEntry()).toBe(true);
      
      cleanup();
    });

    it('should not show dashboard entry when master flag disabled', async () => {
      const cleanup = mockEnv({
        NEXT_PUBLIC_COHORT_ENABLED: '0',
        NEXT_PUBLIC_COHORT_DASHBOARD_ENTRY: '1'
      });
      const { shouldShowDashboardEntry } = await import('../../src/config/flags');
      
      expect(shouldShowDashboardEntry()).toBe(false);
      
      cleanup();
    });

    it('should show event summary when both flags enabled', async () => {
      const cleanup = mockEnv({
        NEXT_PUBLIC_COHORT_ENABLED: '1',
        NEXT_PUBLIC_COHORT_EVENT_SUMMARY: '1'
      });
      const { shouldShowEventSummary } = await import('../../src/config/flags');
      
      expect(shouldShowEventSummary()).toBe(true);
      
      cleanup();
    });

    it('should not show event summary when master flag disabled', async () => {
      const cleanup = mockEnv({
        NEXT_PUBLIC_COHORT_ENABLED: '0',
        NEXT_PUBLIC_COHORT_EVENT_SUMMARY: '1'
      });
      const { shouldShowEventSummary } = await import('../../src/config/flags');
      
      expect(shouldShowEventSummary()).toBe(false);
      
      cleanup();
    });
  });

  describe('Debug Information', () => {
    it('should provide comprehensive debug info', async () => {
      const cleanup = mockEnv({
        NEXT_PUBLIC_COHORT_ENABLED: '1',
        NEXT_PUBLIC_COHORT_DASHBOARD_ENTRY: '1',
        NEXT_PUBLIC_COHORT_EVENT_SUMMARY: '0',
        NODE_ENV: 'test'
      });
      const { getDebugInfo } = await import('../../src/config/flags');
      
      const debugInfo = getDebugInfo();
      
      expect(debugInfo.flags).toBeDefined();
      expect(debugInfo.enabledFeatures).toContain('cohort');
      expect(debugInfo.enabledFeatures).toContain('dashboard-entry');
      expect(debugInfo.isValid).toBe(true);
      expect(debugInfo.environment).toBeDefined();
      expect(debugInfo.environment.nodeEnv).toBe('test');
      
      cleanup();
    });
  });

  describe('Edge Cases', () => {
    it('should handle undefined environment variables', async () => {
      const cleanup = mockEnv({
        NEXT_PUBLIC_COHORT_ENABLED: undefined as any,
        NEXT_PUBLIC_COHORT_DASHBOARD_ENTRY: undefined as any,
        NEXT_PUBLIC_COHORT_EVENT_SUMMARY: undefined as any
      });
      const { flags } = await import('../../src/config/flags');
      
      expect(flags.enabled).toBe(false);
      expect(flags.dashboardEntry).toBe(false);
      expect(flags.eventSummary).toBe(false);
      
      cleanup();
    });

    it('should handle empty string environment variables', async () => {
      const cleanup = mockEnv({
        NEXT_PUBLIC_COHORT_ENABLED: '',
        NEXT_PUBLIC_COHORT_DASHBOARD_ENTRY: '',
        NEXT_PUBLIC_COHORT_EVENT_SUMMARY: ''
      });
      const { flags } = await import('../../src/config/flags');
      
      expect(flags.enabled).toBe(false);
      expect(flags.dashboardEntry).toBe(false);
      expect(flags.eventSummary).toBe(false);
      
      cleanup();
    });

    it('should handle mixed valid and invalid values', async () => {
      const cleanup = mockEnv({
        NEXT_PUBLIC_COHORT_ENABLED: '1',
        NEXT_PUBLIC_COHORT_DASHBOARD_ENTRY: 'invalid',
        NEXT_PUBLIC_COHORT_EVENT_SUMMARY: '1'
      });
      const { flags } = await import('../../src/config/flags');
      
      expect(flags.enabled).toBe(true);
      expect(flags.dashboardEntry).toBe(false); // Invalid value
      expect(flags.eventSummary).toBe(true);
      
      cleanup();
    });
  });

  describe('Performance', () => {
    it('should resolve flags quickly', async () => {
      const cleanup = mockEnv({
        NEXT_PUBLIC_COHORT_ENABLED: '1',
        NEXT_PUBLIC_COHORT_DASHBOARD_ENTRY: '1',
        NEXT_PUBLIC_COHORT_EVENT_SUMMARY: '1'
      });
      
      const start = Date.now();
      const { flags } = await import('../../src/config/flags');
      const end = Date.now();
      
      expect(end - start).toBeLessThan(10); // Should resolve in < 10ms
      expect(flags.enabled).toBe(true);
      
      cleanup();
    });
  });
});
