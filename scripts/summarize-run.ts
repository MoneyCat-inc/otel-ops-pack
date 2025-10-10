#!/usr/bin/env tsx
/**
 * CHAR-2 Summarizer
 * - Reads events.jsonl + signatures.json + meta.json
 * - Writes an 8-line synopsis summary.md
 */

import fs from 'fs'
import path from 'path'

type Meta = {
  org: string
  repo: string
  run_id: number
  run_number?: number
  name?: string
  event?: string
  status?: string
  conclusion?: string
  head_branch?: string
  head_sha?: string
  created_at: string
  updated_at?: string
  storage: { root: string; date: string; dir: string }
}

type Sigs = { total: number; top: { id: string; sample: string; count: number; component: string }[] }

function readJSON<T>(file: string): T { return JSON.parse(fs.readFileSync(file, 'utf-8')) as T }

async function main() {
  const args = process.argv.slice(2)
  const dirFlag = args.indexOf('--dir')
  const dir = dirFlag >= 0 ? args[dirFlag + 1] : process.env.RUN_DIR
  if (!dir) {
    console.error('Usage: tsx scripts/summarize-run.ts --dir <ecrr_run_dir>')
    process.exit(2)
  }
  const meta = readJSON<Meta>(path.join(dir, 'meta.json'))
  const sigs = readJSON<Sigs>(path.join(dir, 'signatures.json'))

  const top = sigs.top.slice(0, 3)
  const dominant = top[0]?.component || 'other'
  const hypothesis = (() => {
    switch (dominant) {
      case 'test': return 'Likely flaky/failed tests; rerun or quarantine candidates.'
      case 'deps': return 'Dependency resolution failures; check lockfiles and registries.'
      case 'build': return 'Build pipeline errors; inspect compiler/bundler logs.'
      case 'infra': return 'Infra or network issues; verify rate limits and endpoints.'
      case 'cache': return 'Cache/artifact issues; clear or adjust retention.'
      default: return 'Investigate top signatures for root cause.'
    }
  })()

  const lines = [
    `Run: ${meta.repo} #${meta.run_number ?? meta.run_id} (${meta.name ?? 'workflow'}) — ${meta.conclusion ?? meta.status ?? ''}`,
    `Org/Repo: ${meta.org}/${meta.repo} | Branch: ${meta.head_branch ?? ''} | SHA: ${(meta.head_sha ?? '').slice(0,7)}`,
    `When: ${meta.created_at} (updated ${meta.updated_at ?? meta.created_at}) | Event: ${meta.event ?? ''}`,
    `Dominant Component: ${dominant}`,
    `Top Signatures: ${top.map(t => `${t.component}:${t.id}×${t.count}`).join('; ') || 'none'}`,
    `Samples: ${top.map(t => t.sample).join(' | ').slice(0, 300)}`,
    `Hypothesis: ${hypothesis}`,
    `Artifacts: ${path.relative(process.cwd(), dir)}`,
  ]

  fs.writeFileSync(path.join(dir, 'summary.md'), lines.join('\n') + '\n')
  console.log(`Summary written: ${dir}/summary.md`)
}

main().catch((e) => { console.error(e); process.exit(1) })

