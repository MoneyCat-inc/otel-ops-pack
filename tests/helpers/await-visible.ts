/**
 * ICF Heuristic 01: Retry-on-slow-UI helper
 * 
 * Reduces flakiness from transient UI slowness with bounded retry logic.
 * Budget: 15 LOC (within ≤20 LOC constraint)
 * Lane: FLAK/SELE (test helpers)
 * Authority: BossCat OEM Directive 008
 */

import { Page } from '@playwright/test';

export async function awaitVisible(page: Page, selector: string, timeout = 1500): Promise<void> {
  const t0 = Date.now();
  try {
    await page.waitForSelector(selector, { state: 'visible', timeout });
  } catch (e) {
    if (Date.now() - t0 < timeout * 1.1) {
      await page.waitForTimeout(350);  // tiny backoff
      await page.waitForSelector(selector, { state: 'visible', timeout });  // one retry
    } else {
      throw e;
    }
  }
}

