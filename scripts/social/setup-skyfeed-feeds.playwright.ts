#!/usr/bin/env tsx
/**
 * Automate SkyFeed feed creation for Resonai AntiClickbait feeds.
 * NOTE: SkyFeed is Flutter web — standard Playwright selectors fail.
 * Prefer: npm run social:skyfeed-wizard
 */
import { readFileSync, mkdirSync } from 'fs';
import { join } from 'path';
import { chromium, type Page } from 'playwright';

const ARTIFACTS = 'artifacts/skyfeed-setup';

function loadEnv(): Record<string, string> {
  const config: Record<string, string> = {};
  for (const line of readFileSync('.env.socm', 'utf8').split('\n')) {
    const match = line.match(/^([A-Z_]+)=(.+)$/);
    if (match) config[match[1]] = match[2].trim();
  }
  return config;
}

type FeedSpec = {
  name: string;
  description: string;
  slug: string;
  authors: string[];
  hashtags: string[];
  textContains: string[];
  excludeText?: string[];
};

const FEEDS: FeedSpec[] = [
  {
    name: 'Fact-Check Firehose (Trusted)',
    slug: 'factcheck-firehose',
    description:
      'High-signal posts from vetted fact-checkers and newswires; quotes get a boost.',
    authors: ['fullfact.org', 'factcheck.afp.com', 'politifact.bsky.social', 'reuters.com'],
    hashtags: ['FactCheck', 'Debunk'],
    textContains: ['fact check', 'debunk', 'misleading', 'correction', 'false claim'],
    excludeText: ['satire', 'parody'],
  },
  {
    name: 'OSINT + Verification',
    slug: 'osint-verification',
    description: 'Reverse image, geolocation, EXIF/metadata, and method threads.',
    authors: [
      'bellingcat.com',
      'eliothiggins.bsky.social',
      'sector035.bsky.social',
      'mariannaspringbbc.bsky.social',
      'quiztime.bsky.social',
    ],
    hashtags: ['OSINT', 'Verification'],
    textContains: [
      'reverse image',
      'exif',
      'metadata',
      'geolocate',
      'osint',
      'verify',
      'geolocation',
    ],
  },
  {
    name: 'AntiClickbait HQ',
    slug: 'anticlickbait-hq',
    description:
      "BossCat evidence-first posts + community engagement with #AntiClickbait.",
    authors: ['resonai.bsky.social'],
    hashtags: ['AntiClickbait', 'OpenTelemetry'],
    textContains: ['hub.resonai.uk', 'otel-ops-pack', 'evidence', 'transparency'],
  },
];

async function snap(page: Page, label: string) {
  mkdirSync(ARTIFACTS, { recursive: true });
  const path = join(ARTIFACTS, `${label}.png`);
  await page.screenshot({ path, fullPage: true });
  console.log(`[skyfeed] screenshot: ${path}`);
}

async function login(page: Page, handle: string, password: string) {
  await page.goto('https://skyfeed.app/', { waitUntil: 'networkidle', timeout: 60000 });
  await snap(page, '01-landing');

  const userInput = page.locator(
    'input[placeholder*="handle" i], input[name="identifier"], input[type="text"]',
  ).first();
  const passInput = page.locator('input[type="password"]').first();

  await userInput.waitFor({ timeout: 15000 });
  await userInput.fill(handle);
  await passInput.fill(password);

  const continueBtn = page.getByRole('button', { name: /continue|log in|login|sign in/i }).first();
  await continueBtn.click();
  await page.waitForTimeout(4000);
  await snap(page, '02-after-login');
}

async function openFeedBuilder(page: Page) {
  const create = page.getByRole('button', { name: /create feed|new feed|feed builder/i }).first();
  if (await create.isVisible().catch(() => false)) {
    await create.click();
    await page.waitForTimeout(2000);
    return;
  }
  const link = page.getByRole('link', { name: /create feed|new feed|feed builder/i }).first();
  if (await link.isVisible().catch(() => false)) {
    await link.click();
    await page.waitForTimeout(2000);
    return;
  }
  // Flutter canvas fallback: try common nav text
  await page.getByText(/feed builder|create feed/i).first().click({ timeout: 10000 });
}

async function fillIfVisible(page: Page, selector: string, value: string) {
  const el = page.locator(selector).first();
  if (await el.isVisible().catch(() => false)) {
    await el.fill(value);
    return true;
  }
  return false;
}

async function addRuleTokens(page: Page, label: string, values: string[]) {
  for (const value of values) {
    const field = page.getByPlaceholder(new RegExp(label, 'i')).first();
    if (await field.isVisible().catch(() => false)) {
      await field.fill(value);
      await page.keyboard.press('Enter');
      continue;
    }
    const addBtn = page.getByRole('button', { name: new RegExp(`add.*${label}|${label}`, 'i') }).first();
    if (await addBtn.isVisible().catch(() => false)) {
      await addBtn.click();
      const input = page.locator('input:visible').last();
      await input.fill(value);
      await page.keyboard.press('Enter');
    }
  }
}

async function createFeed(page: Page, feed: FeedSpec, index: number) {
  console.log(`\n[skyfeed] Creating feed ${index + 1}: ${feed.name}`);
  await openFeedBuilder(page);
  await snap(page, `feed${index + 1}-01-builder`);

  await fillIfVisible(page, 'input[placeholder*="name" i]', feed.name);
  await page.getByLabel(/name/i).first().fill(feed.name).catch(() => {});
  await fillIfVisible(page, 'textarea', feed.description);
  await page.getByLabel(/description/i).first().fill(feed.description).catch(() => {});

  await addRuleTokens(page, 'author', feed.authors);
  await addRuleTokens(page, 'hashtag', feed.hashtags);
  await addRuleTokens(page, 'text', feed.textContains);
  if (feed.excludeText) {
    await addRuleTokens(page, 'exclude', feed.excludeText);
  }

  await snap(page, `feed${index + 1}-02-rules`);

  const publish = page.getByRole('button', { name: /publish|save|create/i }).last();
  await publish.click({ timeout: 15000 }).catch(async () => {
    await page.getByText(/publish/i).first().click();
  });
  await page.waitForTimeout(5000);
  await snap(page, `feed${index + 1}-03-published`);
}

async function main() {
  const env = loadEnv();
  const handle = env.BSKY_HANDLE || 'resonai.bsky.social';
  const password = env.BSKY_APP_PASSWORD;
  if (!password) {
    console.error('BSKY_APP_PASSWORD missing in .env.socm');
    process.exit(1);
  }

  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({ viewport: { width: 1400, height: 900 } });
  const page = await context.newPage();

  try {
    await login(page, handle, password);
    for (let i = 0; i < FEEDS.length; i++) {
      await createFeed(page, FEEDS[i], i);
    }
    console.log('\n[skyfeed] Done — re-run list-feed-generators.ts to capture URIs');
  } catch (err) {
    await snap(page, 'error');
    console.error('[skyfeed] Automation failed:', err);
    console.error('See artifacts/skyfeed-setup/*.png and docs/social/PHASE2_MANUAL_INSTRUCTIONS.md');
    process.exit(1);
  } finally {
    await browser.close();
  }
}

main();
