import { chromium, Browser, Page } from 'playwright';
import fs from 'fs';
import path from 'path';

type Check = { name: string; ok: boolean; details?: string };

async function ensureDir(p: string) {
  await fs.promises.mkdir(p, { recursive: true });
}

async function run() {
  const baseUrl = process.env.STATUS_URL || 'http://localhost:8889/docs/status.html';
  const root = process.cwd();
  const snapsDir = path.join(root, 'docs', 'observability', 'snapshots');
  const artfDir = path.join(root, 'DELT', 'ARTF');
  await ensureDir(snapsDir);
  await ensureDir(artfDir);

  const ts = new Date();
  const tsStamp = ts.toISOString().replace(/[:.]/g, '-').replace('T', '_').slice(0, 19);
  const pngPath = path.join(snapsDir, `status-browser-${tsStamp}.png`);
  const reportPath = path.join(root, `STATUS_PAGE_BROWSER_VALIDATION_${ts.toISOString().slice(0,10).replace(/-/g,'')}.md`);
  const jsonPath = path.join(artfDir, 'status-browser-validation.json');

  let browser: Browser | undefined;
  let page: Page | undefined;
  const checks: Check[] = [];
  const consoleMessages: string[] = [];
  const requests: { url: string; status: number | null }[] = [];

  try {
    browser = await chromium.launch({ headless: true });
    const ctx = await browser.newContext({ ignoreHTTPSErrors: true });
    page = await ctx.newPage();

    page.on('console', (msg) => consoleMessages.push(`[${msg.type()}] ${msg.text()}`));
    page.on('requestfinished', async (req) => {
      try { const r = await req.response(); requests.push({ url: req.url(), status: r ? r.status() : null }); } catch {}
    });

    const resp = await page.goto(baseUrl, { waitUntil: 'networkidle', timeout: 30000 });
    checks.push({ name: 'Page load status 200', ok: !!resp && resp.status() === 200, details: String(resp?.status()) });

    // Gate panel
    const gateVisible = await page.locator('#gate-latest').isVisible();
    checks.push({ name: 'Gate panel visible', ok: gateVisible });

    // Refmap JSON present and Mermaid rendered (SVG under .mermaid)
    await page.waitForTimeout(500); // small settle time after idle
    const refJson = await page.evaluate(async () => {
      try { const r = await fetch('reference/reference-map.json', { cache: 'no-store' }); return r.ok; } catch { return false; }
    });
    checks.push({ name: 'Reference map JSON accessible', ok: !!refJson });
    const mermaidSvg = await page.locator('#refmap-graph .mermaid svg').first().count();
    checks.push({ name: 'Mermaid graph rendered', ok: mermaidSvg > 0 });

    // RSI metrics (allow fallback dashes as non-blocking)
    const rsiTexts = await page.locator('#icf-rsi .metrics-grid .value span').allTextContents();
    const rsiHasData = rsiTexts.some(t => t.trim() !== '-' && t.trim() !== '');
    checks.push({ name: 'RSI metrics populated (non-blocking)', ok: rsiHasData, details: rsiTexts.join(' | ') });

    // Validate a few key links
    const linkSelectors = [
      'a[href="../DELT/ARTF/sbom.json"]',
      'a[href="../DELT/ARTF/ecrr-benchmark.json"]',
      'a[href="./reference/reference-map.json"]'
    ];
    for (const sel of linkSelectors) {
      const el = page.locator(sel);
      const present = await el.first().count();
      if (present === 0) {
        checks.push({ name: `Link present ${sel}`, ok: false, details: 'not found' });
        continue;
      }
      const href = await el.first().getAttribute('href');
      const url = new URL(href!, baseUrl).toString();
      const r = await page.request.get(url, { timeout: 15000 });
      const ok = r.status() >= 200 && r.status() < 400;
      checks.push({ name: `Link fetch ${href}`, ok, details: String(r.status()) });
    }

    // Screenshot
    await page.screenshot({ path: pngPath, fullPage: true });
    checks.push({ name: 'Screenshot saved', ok: fs.existsSync(pngPath), details: path.relative(root, pngPath) });

  } catch (e: any) {
    checks.push({ name: 'Unhandled error', ok: false, details: String(e?.message || e) });
  } finally {
    await browser?.close();
  }

  const pass = checks.filter(c => c.ok).length;
  const total = checks.length;
  const summary = { pass, total, ts: ts.toISOString(), baseUrl, pngPath, checks, console: consoleMessages.slice(-50), requests: requests.slice(-200) };

  await fs.promises.writeFile(jsonPath, JSON.stringify(summary, null, 2), 'utf8');

  const md = [
    `# STATUS PAGE BROWSER VALIDATION`,
    ``,
    `- Timestamp: ${ts.toISOString()}`,
    `- URL: ${baseUrl}`,
    `- Result: ${pass}/${total} checks passed`,
    `- Screenshot: ${path.relative(root, pngPath)}`,
    `- Artifact (JSON): ${path.relative(root, jsonPath)}`,
    ``,
    `## Checks`,
    ...checks.map(c => `- ${c.ok ? '✅' : '❌'} ${c.name}${c.details ? ` — ${c.details}` : ''}`),
    ``,
    `## Console (tail)`,
    ...consoleMessages.slice(-20).map(l => `- ${l}`)
  ].join('\n');
  await fs.promises.writeFile(reportPath, md, 'utf8');

  // Emit brief stdout summary
  console.log(JSON.stringify({ ok: pass === total, pass, total, report: reportPath, screenshot: pngPath, json: jsonPath }, null, 2));
}

run();

