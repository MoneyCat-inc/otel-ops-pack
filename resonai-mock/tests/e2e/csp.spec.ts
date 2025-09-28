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
