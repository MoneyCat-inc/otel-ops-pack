import { test, expect } from '../setup/deterministic';

test('microphone flow resolves without hardware prompts', async ({ page }) => {
  await page.goto('/');
  const result = await page.evaluate(async () => {
    const bucket = (window as unknown as { __deterministic__?: Record<string, unknown> }).__deterministic__ ?? null;
    const response: Record<string, unknown> = { bucketPresent: Boolean(bucket) };

    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: { channelCount: 1 } });
      response.ok = true;
      response.trackCount = typeof stream.getTracks === 'function' ? stream.getTracks().length : null;
    } catch (error) {
      response.ok = false;
      response.error = error instanceof Error ? error.message : String(error);
    }

    if (bucket) {
      response.lastConstraints = bucket['lastMicConstraints'] ?? null;
    }

    return response;
  });

  expect(result.bucketPresent).toBeTruthy();
  expect(result.ok).toBeTruthy();
  expect(result.lastConstraints).toMatchObject({ audio: { channelCount: 1 } });
});

test('sendBeacon stub captures payload deterministically', async ({ page }) => {
  await page.goto('/');
  const beacon = await page.evaluate(() => {
    const payload = JSON.stringify({ event: 'mic-flow', ts: Date.now() });
    const success = navigator.sendBeacon('/analytics', payload);
    const bucket = (window as unknown as { __deterministic__?: Record<string, unknown> }).__deterministic__ ?? {};
    return { success, lastBeacon: bucket['lastBeacon'] ?? null };
  });

  expect(beacon.success).toBeTruthy();
  expect(beacon.lastBeacon).not.toBeNull();
  expect(beacon.lastBeacon.url).toContain('/analytics');
  expect(beacon.lastBeacon.preview).toContain('mic-flow');
});
