import { test, expect } from '@playwright/test';

const EXPECTED_HEADERS = {
  'cross-origin-opener-policy': 'same-origin',
  'cross-origin-embedder-policy': 'require-corp',
  'cross-origin-resource-policy': 'same-origin',
};

const PATHS: Array<{ path: string; description: string }> = [
  { path: '/', description: 'HTML entry point' },
  { path: '/workers/pipeline.js', description: 'worker script' },
];

test.describe('security headers', () => {
  for (const target of PATHS) {
    test(`${target.description} exposes COOP/COEP`, async ({ request }) => {
      const response = await request.get(target.path, { failOnStatusCode: true });
      expect(response.status(), `${target.path} should return a successful status`).toBeLessThan(400);

      const headers = response.headers();
      for (const [key, value] of Object.entries(EXPECTED_HEADERS)) {
        expect(headers[key], `${key} missing on ${target.path}`).toBe(value);
      }

      const csp = headers['content-security-policy'];
      expect(csp, `Content-Security-Policy missing on ${target.path}`).toBeTruthy();
      expect(csp, `CSP must lock default-src to 'self' for ${target.path}`).toContain("default-src 'self'");
    });
  }
});
