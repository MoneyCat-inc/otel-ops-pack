import { test, expect } from '../setup/deterministic';
import fs from 'node:fs';
import path from 'node:path';

test('crossOriginIsolated is true', async ({ page }) => {
  await page.goto('/');
  const { isolated, bucket } = await page.evaluate(() => {
    const win = window as unknown as {
      crossOriginIsolated?: boolean;
      __deterministic__?: { crossOriginIsolated?: boolean };
    };
    return {
      isolated: Boolean(win.crossOriginIsolated),
      bucket: win.__deterministic__ ?? null,
    };
  });
  const outDir = path.join(process.cwd(), '.artifacts');
  fs.mkdirSync(outDir, { recursive: true });
  fs.writeFileSync(path.join(outDir, 'isolation.txt'), isolated ? '✅' : '❌', 'utf8');
  expect.soft(isolated, 'Expected window.crossOriginIsolated === true').toBeTruthy();
  expect(bucket?.crossOriginIsolated).toBe(true);
});
