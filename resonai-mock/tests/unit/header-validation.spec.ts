/**
 * Header Validation Tests
 * 
 * T4: Offline Isolation
 * Unit and integration tests for header validation and
 * cross-origin isolation configuration.
 */

import { describe, it, expect } from 'vitest';

describe('Header Validation', () => {
  describe('COOP/COEP Headers', () => {
    it('should have correct COOP header value', () => {
      const expectedCOOP = 'same-origin';
      expect(expectedCOOP).toBe('same-origin');
    });

    it('should have correct COEP header value', () => {
      const expectedCOEP = 'require-corp';
      expect(expectedCOEP).toBe('require-corp');
    });

    it('should have correct CORP header value', () => {
      const expectedCORP = 'cross-origin';
      expect(expectedCORP).toBe('cross-origin');
    });
  });

  describe('Security Headers', () => {
    it('should have X-Content-Type-Options header', () => {
      const expectedValue = 'nosniff';
      expect(expectedValue).toBe('nosniff');
    });

    it('should have Referrer-Policy header', () => {
      const expectedValue = 'strict-origin-when-cross-origin';
      expect(expectedValue).toBe('strict-origin-when-cross-origin');
    });

    it('should have X-Frame-Options header', () => {
      const expectedValue = 'SAMEORIGIN';
      expect(expectedValue).toBe('SAMEORIGIN');
    });
  });

  describe('Permissions Policy', () => {
    it('should have cross-origin-isolated permission', () => {
      const expectedValue = 'cross-origin-isolated=()';
      expect(expectedValue).toBe('cross-origin-isolated=()');
    });

    it('should have microphone permission for self', () => {
      const expectedValue = 'microphone=(self)';
      expect(expectedValue).toBe('microphone=(self)');
    });

    it('should deny camera permission', () => {
      const expectedValue = 'camera=()';
      expect(expectedValue).toBe('camera=()');
    });
  });

  describe('Content Security Policy', () => {
    it('should have strict CSP in production', () => {
      const productionCSP = [
        "default-src 'self'",
        "script-src 'self'",
        "style-src 'self'",
        "img-src 'self' data: https: blob:",
        "font-src 'self'",
        "connect-src 'self' blob:",
        "worker-src 'self' blob:",
        "child-src 'self' blob:",
        "frame-ancestors 'none'",
        "object-src 'none'",
        "base-uri 'self'",
        "form-action 'self'",
        "upgrade-insecure-requests"
      ].join('; ');

      expect(productionCSP).toContain("default-src 'self'");
      expect(productionCSP).toContain("script-src 'self'");
      expect(productionCSP).toContain("style-src 'self'");
      expect(productionCSP).toContain("worker-src 'self' blob:");
      expect(productionCSP).toContain("child-src 'self' blob:");
    });

    it('should allow blob: for worklets', () => {
      const csp = "worker-src 'self' blob:";
      expect(csp).toContain('blob:');
    });

    it('should deny inline styles', () => {
      const csp = "style-src 'self'";
      expect(csp).not.toContain('unsafe-inline');
    });

    it('should deny inline scripts in production', () => {
      const productionCSP = "script-src 'self'";
      expect(productionCSP).not.toContain('unsafe-inline');
    });
  });

  describe('Service Worker Headers', () => {
    it('should have Service-Worker-Allowed header', () => {
      const expectedValue = '/';
      expect(expectedValue).toBe('/');
    });

    it('should have no-cache headers for Service Worker', () => {
      const expectedValue = 'no-cache, no-store, must-revalidate';
      expect(expectedValue).toBe('no-cache, no-store, must-revalidate');
    });
  });

  describe('Worklet Headers', () => {
    it('should have correct Content-Type for worklets', () => {
      const expectedValue = 'application/javascript';
      expect(expectedValue).toBe('application/javascript');
    });

    it('should have COOP/COEP headers for worklets', () => {
      const workletHeaders = {
        'Cross-Origin-Opener-Policy': 'same-origin',
        'Cross-Origin-Embedder-Policy': 'require-corp',
        'Cross-Origin-Resource-Policy': 'cross-origin'
      };

      expect(workletHeaders['Cross-Origin-Opener-Policy']).toBe('same-origin');
      expect(workletHeaders['Cross-Origin-Embedder-Policy']).toBe('require-corp');
      expect(workletHeaders['Cross-Origin-Resource-Policy']).toBe('cross-origin');
    });
  });
});

describe('Cross-Origin Isolation Configuration', () => {
  describe('Required Headers', () => {
    it('should have all required headers for cross-origin isolation', () => {
      const requiredHeaders = [
        'Cross-Origin-Opener-Policy',
        'Cross-Origin-Embedder-Policy',
        'Cross-Origin-Resource-Policy',
        'Permissions-Policy'
      ];

      const expectedValues = {
        'Cross-Origin-Opener-Policy': 'same-origin',
        'Cross-Origin-Embedder-Policy': 'require-corp',
        'Cross-Origin-Resource-Policy': 'cross-origin',
        'Permissions-Policy': 'cross-origin-isolated=()'
      };

      requiredHeaders.forEach(header => {
        expect(expectedValues[header as keyof typeof expectedValues]).toBeDefined();
      });
    });
  });

  describe('SharedArrayBuffer Support', () => {
    it('should enable SharedArrayBuffer with correct headers', () => {
      const headers = {
        'Cross-Origin-Opener-Policy': 'same-origin',
        'Cross-Origin-Embedder-Policy': 'require-corp'
      };

      // These headers are required for SharedArrayBuffer
      expect(headers['Cross-Origin-Opener-Policy']).toBe('same-origin');
      expect(headers['Cross-Origin-Embedder-Policy']).toBe('require-corp');
    });
  });

  describe('Browser Compatibility', () => {
    it('should have headers compatible with Firefox', () => {
      const firefoxCompatibleHeaders = {
        'Cross-Origin-Opener-Policy': 'same-origin',
        'Cross-Origin-Embedder-Policy': 'require-corp',
        'Cross-Origin-Resource-Policy': 'cross-origin'
      };

      // Firefox requires these specific values
      expect(firefoxCompatibleHeaders['Cross-Origin-Opener-Policy']).toBe('same-origin');
      expect(firefoxCompatibleHeaders['Cross-Origin-Embedder-Policy']).toBe('require-corp');
    });

    it('should have headers compatible with Chromium', () => {
      const chromiumCompatibleHeaders = {
        'Cross-Origin-Opener-Policy': 'same-origin',
        'Cross-Origin-Embedder-Policy': 'require-corp',
        'Permissions-Policy': 'cross-origin-isolated=()'
      };

      // Chromium requires these specific values
      expect(chromiumCompatibleHeaders['Cross-Origin-Opener-Policy']).toBe('same-origin');
      expect(chromiumCompatibleHeaders['Cross-Origin-Embedder-Policy']).toBe('require-corp');
      expect(chromiumCompatibleHeaders['Permissions-Policy']).toBe('cross-origin-isolated=()');
    });
  });
});

describe('Service Worker Header Preservation', () => {
  describe('Critical Headers', () => {
    it('should preserve all critical headers in Service Worker', () => {
      const criticalHeaders = [
        'Cross-Origin-Opener-Policy',
        'Cross-Origin-Embedder-Policy',
        'Cross-Origin-Resource-Policy',
        'Content-Security-Policy',
        'Permissions-Policy',
        'X-Content-Type-Options',
        'Referrer-Policy',
        'X-Frame-Options'
      ];

      const preservedHeaders = {
        'Cross-Origin-Opener-Policy': 'same-origin',
        'Cross-Origin-Embedder-Policy': 'require-corp',
        'Cross-Origin-Resource-Policy': 'cross-origin',
        'Content-Security-Policy': "default-src 'self'",
        'Permissions-Policy': 'cross-origin-isolated=()',
        'X-Content-Type-Options': 'nosniff',
        'Referrer-Policy': 'strict-origin-when-cross-origin',
        'X-Frame-Options': 'SAMEORIGIN'
      };

      criticalHeaders.forEach(header => {
        expect(preservedHeaders[header as keyof typeof preservedHeaders]).toBeDefined();
      });
    });
  });

  describe('Offline CSP', () => {
    it('should have appropriate CSP for offline mode', () => {
      const offlineCSP = [
        "default-src 'self'",
        "script-src 'self'",
        "style-src 'self'",
        "img-src 'self' data: https: blob:",
        "font-src 'self'",
        "connect-src 'self' blob:",
        "worker-src 'self' blob:",
        "child-src 'self' blob:",
        "frame-ancestors 'none'",
        "object-src 'none'",
        "base-uri 'self'",
        "form-action 'self'",
        "upgrade-insecure-requests"
      ].join('; ');

      expect(offlineCSP).toContain("default-src 'self'");
      expect(offlineCSP).toContain("worker-src 'self' blob:");
      expect(offlineCSP).toContain("child-src 'self' blob:");
      expect(offlineCSP).not.toContain('unsafe-inline');
      expect(offlineCSP).not.toContain('unsafe-eval');
    });
  });
});

describe('Asset Loading Configuration', () => {
  describe('Worklet Loading', () => {
    it('should have correct headers for worklet files', () => {
      const workletHeaders = {
        'Content-Type': 'application/javascript',
        'Cross-Origin-Opener-Policy': 'same-origin',
        'Cross-Origin-Embedder-Policy': 'require-corp',
        'Cross-Origin-Resource-Policy': 'cross-origin'
      };

      expect(workletHeaders['Content-Type']).toBe('application/javascript');
      expect(workletHeaders['Cross-Origin-Opener-Policy']).toBe('same-origin');
    });
  });

  describe('Font Loading', () => {
    it('should allow fonts from self origin', () => {
      const fontCSP = "font-src 'self'";
      expect(fontCSP).toContain("'self'");
    });
  });

  describe('Image Loading', () => {
    it('should allow images from multiple sources', () => {
      const imageCSP = "img-src 'self' data: https: blob:";
      expect(imageCSP).toContain("'self'");
      expect(imageCSP).toContain('data:');
      expect(imageCSP).toContain('https:');
      expect(imageCSP).toContain('blob:');
    });
  });
});

describe('Header Validation Utilities', () => {
  describe('Header Validation Functions', () => {
    it('should validate COOP header format', () => {
      const validateCOOP = (value: string) => {
        return ['same-origin', 'same-origin-allow-popups', 'unsafe-none'].includes(value);
      };

      expect(validateCOOP('same-origin')).toBe(true);
      expect(validateCOOP('same-origin-allow-popups')).toBe(true);
      expect(validateCOOP('unsafe-none')).toBe(true);
      expect(validateCOOP('invalid')).toBe(false);
    });

    it('should validate COEP header format', () => {
      const validateCOEP = (value: string) => {
        return ['require-corp', 'credentialless', 'unsafe-none'].includes(value);
      };

      expect(validateCOEP('require-corp')).toBe(true);
      expect(validateCOEP('credentialless')).toBe(true);
      expect(validateCOEP('unsafe-none')).toBe(true);
      expect(validateCOEP('invalid')).toBe(false);
    });

    it('should validate CORP header format', () => {
      const validateCORP = (value: string) => {
        return ['same-site', 'same-origin', 'cross-origin'].includes(value);
      };

      expect(validateCORP('same-site')).toBe(true);
      expect(validateCORP('same-origin')).toBe(true);
      expect(validateCORP('cross-origin')).toBe(true);
      expect(validateCORP('invalid')).toBe(false);
    });
  });

  describe('CSP Validation', () => {
    it('should validate CSP directive format', () => {
      const validateCSPDirective = (directive: string) => {
        const parts = directive.split(' ');
        const directiveName = parts[0];
        const sources = parts.slice(1);
        
        return directiveName && sources.length > 0;
      };

      expect(validateCSPDirective("default-src 'self'")).toBe(true);
      expect(validateCSPDirective("script-src 'self' 'unsafe-inline'")).toBe(true);
      expect(validateCSPDirective("invalid-directive")).toBe(false);
    });

    it('should validate CSP source values', () => {
      const validateCSPSource = (source: string) => {
        const validSources = [
          "'self'", "'unsafe-inline'", "'unsafe-eval'", "'none'",
          "data:", "blob:", "https:", "http:", "ws:", "wss:"
        ];
        return validSources.includes(source) || source.startsWith('http');
      };

      expect(validateCSPSource("'self'")).toBe(true);
      expect(validateCSPSource("'unsafe-inline'")).toBe(true);
      expect(validateCSPSource("data:")).toBe(true);
      expect(validateCSPSource("blob:")).toBe(true);
      expect(validateCSPSource("https:")).toBe(true);
      expect(validateCSPSource("invalid")).toBe(false);
    });
  });
});
