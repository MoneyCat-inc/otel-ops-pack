#!/usr/bin/env -S node --enable-source-maps
/**
 * BossCat Agent Lane Runner (ICFX)
 * - Dry-run validator for lane-scoped changes
 * - Emits ECRR evidence without modifying repo state
 */
import { execSync } from 'node:child_process';
import { readFileSync, mkdirSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { globSync, hasMagic } from 'glob';

type LaneConfig = {
  allow: string[];
  budgets: { jobs: number; files: number; lines: number };
};

function parseArgs() {
  const args = new Map<string, string | boolean>();
  for (let i = 2; i < process.argv.length; i++) {
    const a = process.argv[i];
    if (!a.startsWith('--')) continue;
    const [k0, v0] = a.split('=', 2);
    const key = k0.replace(/^--/, '');
    if (typeof v0 === 'string' && v0.length > 0) {
      args.set(key, v0);
      continue;
    }
    const next = process.argv[i + 1];
    if (next && !next.startsWith('--')) {
      args.set(key, next);
      i++;
    } else {
      args.set(key, 'true');
    }
  }
  return args;
}

function getChangedFiles(): string[] {
  try {
    const out = execSync('git status --porcelain=v1', { stdio: ['ignore', 'pipe', 'pipe'] })
      .toString()
      .trim();
    if (!out) return [];
    return out
      .split('\n')
      .map((l) => l.slice(3).trim())
      .filter(Boolean);
  } catch {
    return [];
  }
}

function withinAllowSet(file: string, allow: string[]): boolean {
  return allow.some((pattern) => {
    if (hasMagic(pattern)) {
      const matches = globSync(pattern, { nodir: true });
      return matches.includes(file);
    }
    const base = pattern.replace(/\*\*/g, '');
    return file.startsWith(base);
  });
}

function emitEcrr(lane: string, verdict: string, reasons: string[]) {
  const ts = new Date();
  const stamp = ts.toISOString().replace(/[:]/g, '').replace(/\..+/, '');
  const outDir = join('artifacts', 'ecrr', lane);
  mkdirSync(outDir, { recursive: true });
  const file = join(outDir, `ECRR_${lane.toUpperCase()}_${stamp}.md`);
  const lines = [
    `# ECRR Lane Run - ${lane.toUpperCase()}`,
    '',
    `Timestamp: ${ts.toISOString()}`,
    `Lane: ${lane}`,
    '',
    '## Examine',
    '- Dry-run validation only (no writes outside allow-set)',
    '',
    '## Report',
    `Verdict: ${verdict}`,
  ];
  if (reasons.length) {
    lines.push('', 'Reasons:');
    for (const r of reasons) lines.push(`- ${r}`);
  }
  writeFileSync(file, lines.join('\n'), 'utf8');
  // Also mirror latest for convenience
  writeFileSync(join(outDir, `LATEST.md`), lines.join('\n'), 'utf8');
  return file;
}

async function main() {
  const args = parseArgs();
  const lane = String(args.get('lane') || 'icfx');
  const dryRun = String(args.get('dry-run') || 'true') === 'true';

  const cfgRaw = readFileSync('.agent/config.json', 'utf8');
  const cfg = JSON.parse(cfgRaw);
  const lanes = (cfg.lanes || {}) as Record<string, LaneConfig>;
  const lc = lanes[lane];
  if (!lc) {
    const file = emitEcrr(lane, 'NOT_READY', [`Lane '${lane}' not defined in .agent/config.json`]);
    console.error(`[ICFX] Lane missing. ECRR: ${file}`);
    process.exit(2);
  }

  const changed = getChangedFiles();
  const outside = changed.filter((f) => !withinAllowSet(f, lc.allow));
  const reasons: string[] = [];
  let verdict = 'READY';
  if (outside.length > 0) {
    verdict = 'NOT_READY';
    reasons.push(`Changes outside allow-set: ${outside.join(', ')}`);
  }

  if (changed.length > lc.budgets.files) {
    verdict = 'NOT_READY';
    reasons.push(`File budget exceeded: ${changed.length}/${lc.budgets.files}`);
  }

  const ecrrPath = emitEcrr(lane, verdict, reasons);
  console.log(`[ICFX] ${verdict} \u2014 ECRR: ${ecrrPath}`);

  if (verdict !== 'READY') process.exit(2);
  if (!dryRun) process.exit(0);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
