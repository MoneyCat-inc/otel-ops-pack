import fs from 'node:fs';
import path from 'node:path';

const A = path.resolve('.artifacts/test-reports/playwright-summary.json');
const B = path.resolve('.artifacts/test-reports/playwright-tests.json');
const OUT = path.resolve('.artifacts/SSOT.md');

function loadJson(p: string) {
  try { return JSON.parse(fs.readFileSync(p, 'utf8')); }
  catch { return null; }
}

function main() {
  const sum = loadJson(A) || { status: 'unknown', durationMs: 0 };
  const tests = (loadJson(B)?.tests || []) as any[];

  const passed = tests.filter(t => t.status === 'passed').length;
  const failed = tests.filter(t => t.status === 'failed').length;
  const flaky = tests.filter(t => (t.tags || []).includes('flaky')).length;

  const md = [
    `# SSOT — CI Snapshot`,
    ``,
    `**Status**: ${sum.status} • **Duration**: ${Math.round(sum.durationMs/1000)}s`,
    `**Totals**: passed=${passed} • failed=${failed} • @flaky=${flaky}`,
    ``,
    `## Top Failures`,
    ...tests.filter(t => t.status === 'failed').slice(0, 10).map(t =>
      `- ❌ ${t.title} (${t.location?.file}:${t.location?.line ?? 0})`
    ),
    ``,
    `_Generated: ${new Date().toISOString()}_`
  ].join('\n');

  fs.mkdirSync(path.dirname(OUT), { recursive: true });
  fs.writeFileSync(OUT, md);
  console.log('Wrote', OUT);
}

main();
