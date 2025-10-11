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

  // Load docs index for important documents
  let docsIndex: any = null
  const docsIdxPath = path.join('docs', 'reference', 'docs-index.json')
  if (fs.existsSync(docsIdxPath)) {
    try { docsIndex = JSON.parse(fs.readFileSync(docsIdxPath, 'utf-8')) } catch {}
  }
  const docNodes = (docsIndex?.items || []).map((d: any) => ({ id: `doc:${d.title || d.path}`, type: 'doc', files: [d.path], importance: d.importance || 'P2', tags: d.tags || [] }))

  // Taxonomy aligned to concept vision (Phases, Loops, ECRR, Importance)
  const taxonomy = {
    phases: {
      phase1: ['correlation'],
      phase2: ['ingest-worker', 'normalize', 'classify', 'summarize', 'actor-pr', 'dashboard-rollup'],
      phase3: ['policy', 'registry']
    },
    loops: {
      run: ['ingest-worker', 'normalize', 'classify', 'summarize'],
      pr: ['actor-pr'],
      workflow: ['dashboard-rollup'],
      org: ['policy', 'registry']
    },
    ecrr: ['examine', 'clean', 'report', 'role'],
    importanceLevels: {
      P0: 'Critical — canonical design/governance, gate‑deciding reports',
      P1: 'High — operational guides, indices, validations',
      P2: 'Medium — implementation notes, examples, playbooks',
      P3: 'Low — archival/history'
    }
  }

  // Existence check for robustness
  const missing: { node: string; file: string }[] = []
  for (const n of [...nodes, ...docNodes]) {
    for (const f of n.files) {
      if (!fs.existsSync(path.join(ROOT, f))) missing.push({ node: n.id, file: f })
    }
  }

  const allNodes = [...nodes, ...docNodes]
  const importanceCounts: Record<string, number> = { P0: 0, P1: 0, P2: 0, P3: 0 }
  for (const n of allNodes) {
    const imp = (n as any).importance
    if (imp && importanceCounts[imp] !== undefined) importanceCounts[imp]++
  }

  const out = { version: 1, generated_at: new Date().toISOString(), nodes: allNodes, edges, scripts, taxonomy, missing, stats: { importanceCounts } }
  const outDir = path.dirname(OUT)
  if (!fs.existsSync(outDir)) fs.mkdirSync(outDir, { recursive: true })
  fs.writeFileSync(OUT, JSON.stringify(out, null, 2))
  console.log(`Reference map written: ${OUT}`)
}

main()
