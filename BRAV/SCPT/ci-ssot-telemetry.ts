#!/usr/bin/env node
/**
 * ci-ssot-telemetry.ts
 * Builds the canonical SSOT block with telemetry counts and writes:
 *  - .artifacts/SSOT.md
 *  - Injects/updates the top SSOT block in RUN_AND_VERIFY.md
 * Also prints the block to STDOUT for the CI step summary.
 *
 * Inputs (best-effort; safe defaults if missing):
 *   - artifacts/ssot-telemetry-summary.json   (preferred)
 *   - .artifacts/flake-report.json            (fallback for flaky count)
 *   - .agent/state.json                       (optional: last run stats)
 * Env:
 *   - GITHUB_SHA (or GIT_COMMIT_SHA) for build/commit attribution
 */

import fs from 'node:fs';
import path from 'node:path';

type AnyRec = Record<string, any>;
const ROOT = process.cwd();

function readJson<T = AnyRec>(p: string, fallback: T): T {
  try { return JSON.parse(fs.readFileSync(p, 'utf8')) as T; }
  catch { return fallback; }
}

function ensureDir(p: string) {
  const d = path.dirname(p);
  if (!fs.existsSync(d)) fs.mkdirSync(d, { recursive: true });
}

function shortSha(sha?: string) {
  return (sha || '').slice(0, 7) || 'dev';
}

function nowIso() {
  return new Date().toISOString();
}

function buildBlock(data: {
  sha: string;
  jobsProcessed: number;
  jobsFailed: number;
  queueDepthMax: number;
  flakyActive: number;
  rehabilitated7d: number;
}) {
  const lines = [
    '<!-- SSOT:BEGIN -->',
    `**Build**: \`${data.sha}\` • **Generated**: ${nowIso()}`,
    '',
    '### Agent Telemetry (OTel)',
    `- Jobs processed: **${data.jobsProcessed}**`,
    `- Jobs failed: **${data.jobsFailed}**`,
    `- Queue depth (max): **${data.queueDepthMax}**`,
    `- Flaky tests (active): **${data.flakyActive}**`,
    `- Rehabilitated (last 7d): **${data.rehabilitated7d}**`,
    '',
    '> SSOT is the single source of truth for gate decisions. Keep PRs artifact‑driven.',
    '<!-- SSOT:END -->',
    '',
  ];
  return lines.join('\n');
}

function updateTopBlock(mdPath: string, block: string) {
  let exists = true;
  let original = '';
  try { original = fs.readFileSync(mdPath, 'utf8'); } catch { exists = false; }
  const begin = '<!-- SSOT:BEGIN -->';
  const end = '<!-- SSOT:END -->';

  if (!exists || !original.includes(begin)) {
    const newContent = block + (exists ? original.replace(/^\s+/, '\n') : '');
    fs.writeFileSync(mdPath, newContent, 'utf8');
    return;
  }

  const updated = original.replace(
    new RegExp(`${begin}[\\s\\S]*?${end}`),
    block.split('\n').join('\n')
  );
  fs.writeFileSync(mdPath, updated, 'utf8');
}

function main() {
  // Preferred summary (already created in your verification step)
  const summary = readJson<AnyRec>(path.join(ROOT, 'artifacts', 'ssot-telemetry-summary.json'), {});
  // Fallback sources
  const flake = readJson<AnyRec>(path.join(ROOT, '.artifacts', 'flake-report.json'), { specs: [] });
  const state = readJson<AnyRec>(path.join(ROOT, '.agent', 'state.json'), {});

  const sha = shortSha(process.env.GITHUB_SHA || process.env.GIT_COMMIT_SHA);

  const jobsProcessed = Number(summary.jobsProcessed ?? state.jobsProcessed ?? 0);
  const jobsFailed    = Number(summary.jobsFailed    ?? state.jobsFailed    ?? 0);
  const queueDepthMax = Number(summary.queueDepthMax ?? state.queueDepthMax ?? 0);

  // Prefer explicit flaky count if provided; else derive from flake report length
  const flakyActive = Number(summary.flakyActive ?? (Array.isArray(flake.specs) ? flake.specs.length : 0));
  const rehabilitated7d = Number(summary.rehabilitated7d ?? 0);

  const block = buildBlock({
    sha,
    jobsProcessed,
    jobsFailed,
    queueDepthMax,
    flakyActive,
    rehabilitated7d,
  });

  // 1) Write .artifacts/SSOT.md
  const ssotPath = path.join(ROOT, '.artifacts', 'SSOT.md');
  ensureDir(ssotPath);
  fs.writeFileSync(ssotPath, block + '\n', 'utf8');

  // 2) Inject/replace top block in RUN_AND_VERIFY.md
  const runbook = path.join(ROOT, 'RUN_AND_VERIFY.md');
  updateTopBlock(runbook, block);

  // 3) Print to STDOUT for CI step summary
  console.log(block);
}

main();
