import { test, expect } from '@playwright/test';
import fs from 'node:fs';
import path from 'node:path';

test('crossOriginIsolated is true', async ({ page }) => {
  await page.goto('/');
  const isolated = await page.evaluate(() => (window as any).crossOriginIsolated === true);
  const outDir = path.join(process.cwd(), '.artifacts');
  fs.mkdirSync(outDir, { recursive: true });
  fs.writeFileSync(path.join(outDir, 'isolation.txt'), isolated ? '✅' : '❌', 'utf8');
  expect.soft(isolated, 'Expected window.crossOriginIsolated === true').toBeTruthy();
});
