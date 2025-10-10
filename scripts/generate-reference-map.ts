#!/usr/bin/env tsx
/**
 * Reference Map Generator
 * - Scans selected repo locations, reads package.json scripts and workflows
 * - Writes docs/reference/reference-map.json with nodes/edges and timestamp
 */
import fs from 'fs'
import path from 'path'

const ROOT = process.cwd()
const OUT = path.join('docs', 'reference', 'reference-map.json')

function readJSON<T>(p: string): T | null { try { return JSON.parse(fs.readFileSync(p, 'utf-8')) } catch { return null } }
function listWorkflows(): string[] {
  const d = path.join('.github', 'workflows')
  if (!fs.existsSync(d)) return []
  return fs.readdirSync(d).filter(f => f.endsWith('.yml') || f.endsWith('.yaml')).map(f => path.join('.github', 'workflows', f))
}

function main() {
  const pkg = readJSON<any>('package.json') || { scripts: {} }
  const scripts = pkg.scripts || {}
  const workflows = listWorkflows()
  const nodes = [
    { id: 'ingest-worker', type: 'script', files: ['scripts/ingest-worker.ts', 'scripts/ingest-utils.ts', 'scripts/ingest-backfill.ps1'] },
    { id: 'normalize', type: 'script', files: ['scripts/normalize-events.ts'] },
    { id: 'classify', type: 'script', files: ['scripts/classify-run.ts'] },
    { id: 'summarize', type: 'script', files: ['scripts/summarize-run.ts'] },
    { id: 'actor-pr', type: 'script', files: ['scripts/actor-pr-comment.ts'] },
    { id: 'policy', type: 'config', files: ['config/policy/ecrr-policy.json'] },
    { id: 'registry', type: 'data', files: ['ALFA/APPS/signature-registry.json'] },
    { id: 'dashboard-rollup', type: 'script', files: ['scripts/dashboard-query.ts'] },
    { id: 'workflows', type: 'workflow', files: workflows },
    { id: 'correlation', type: 'lib', files: ['scripts/lib/correlation.ts', 'scripts/lib/logger.ts', 'scripts/emit-synthetic-span.ts', 'scripts/examples/log-with-trace.ts', 'scripts/verify-correlation.ps1'] }
  ]
  const edges: [string, string][] = [
    ['ingest-worker', 'normalize'],
    ['normalize', 'classify'],
    ['classify', 'summarize'],
    ['summarize', 'actor-pr'],
    ['registry', 'classify'],
    ['policy', 'actor-pr'],
    ['dashboard-rollup', 'workflows'],
    ['correlation', 'ingest-worker'],
    ['correlation', 'normalize']
  ]

  const out = { version: 1, generated_at: new Date().toISOString(), nodes, edges, scripts }
  const outDir = path.dirname(OUT)
  if (!fs.existsSync(outDir)) fs.mkdirSync(outDir, { recursive: true })
  fs.writeFileSync(OUT, JSON.stringify(out, null, 2))
  console.log(`Reference map written: ${OUT}`)
}

main()

