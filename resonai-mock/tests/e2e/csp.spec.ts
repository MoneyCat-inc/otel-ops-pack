import { test, expect } from '@playwright/test';

const isNextInternal = (style: string) =>
  /data-nextjs|__next|next-route-announcer|nextjs-portal/.test(style);

test.beforeEach(async ({ page }) => {
  await page.goto(process.env.PW_BASE_URL || '/');
  // Skip if Next dev overlay detected (extra inline styles)
  test.skip(await page.$('[data-nextjs-dialog]') !== null, 'Dev overlay present; run against prod build');
});

test('@flaky no unexpected inline styles/scripts in prod', async ({ page }) => {
  // Check inline <style> tags
  const inlineStyleCount = await page.$$eval('style', els =>
    els.filter(el => !el.hasAttribute('nonce') && !el.textContent?.includes('next')).length
  );

  // Check inline style attributes (excluding Next internals)
  const attrStyleCount = await page.$$eval('[style]', els =>
    els.filter(el => {
      const attr = (el.getAttribute('style') || '').trim();
      return attr && !/--next|next|__next/.test(attr);
    }).length
  );

  // Check inline <script> without nonce
  const inlineScriptCount = await page.$$eval('script', els =>
    els.filter(el => !el.src && !el.hasAttribute('nonce')).length
  );

  expect(inlineStyleCount, 'unexpected <style> blocks without nonce').toBe(0);
  expect(attrStyleCount, 'unexpected inline style attributes').toBe(0);
  expect(inlineScriptCount, 'unexpected inline scripts').toBe(0);
});

test('Content Security Policy headers are present', async ({ page, context }) => {
  const response = await page.goto(process.env.PW_BASE_URL || '/');
  
  // Check for CSP headers
  const cspHeader = response?.headers()['content-security-policy'];
  const cspReportOnlyHeader = response?.headers()['content-security-policy-report-only'];
  
  expect(cspHeader || cspReportOnlyHeader, 'CSP header should be present').toBeTruthy();
  
  if (cspHeader) {
    // Basic CSP directive checks
    expect(cspHeader, 'CSP should include default-src').toContain('default-src');
    expect(cspHeader, 'CSP should include script-src').toContain('script-src');
    expect(cspHeader, 'CSP should include style-src').toContain('style-src');
  }
});

test('External resource loading follows CSP', async ({ page }) => {
  const violations: string[] = [];
  
  // Listen for CSP violations
  page.on('console', msg => {
    if (msg.type() === 'error' && msg.text().includes('Content Security Policy')) {
      violations.push(msg.text());
    }
  });
  
  await page.goto(process.env.PW_BASE_URL || '/');
  await page.waitForLoadState('networkidle');
  
  // Check for any CSP violations
  expect(violations.length, `CSP violations detected: ${violations.join(', ')}`).toBe(0);
});

test('Secure headers are present', async ({ page }) => {
  const response = await page.goto(process.env.PW_BASE_URL || '/');
  const headers = response?.headers();
  
  // Check for security headers
  expect(headers?.['x-frame-options'], 'X-Frame-Options should be present').toBeTruthy();
  expect(headers?.['x-content-type-options'], 'X-Content-Type-Options should be present').toBeTruthy();
  expect(headers?.['referrer-policy'], 'Referrer-Policy should be present').toBeTruthy();
});