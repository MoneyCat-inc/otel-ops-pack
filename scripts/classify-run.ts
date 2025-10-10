#!/usr/bin/env tsx
/**
 * BRAV-2 Classifier
 * - Reads signatures.json and outputs labels.json with simple taxonomy
 */

import fs from 'fs'
import path from 'path'

type Sigs = { total: number; top: { id: string; sample: string; count: number; component: string }[] }

function readJSON<T>(file: string): T { return JSON.parse(fs.readFileSync(file, 'utf-8')) as T }

function mapComponentToClass(c: string): string {
  switch (c) {
    case 'test': return 'flake_or_test_failure'
    case 'deps': return 'dependency_issue'
    case 'build': return 'build_pipeline'
    case 'infra': return 'infrastructure_or_network'
    case 'cache': return 'artifact_cache'
    default: return 'other'
  }
}

async function main() {
  const args = process.argv.slice(2)
  const dirFlag = args.indexOf('--dir')
  const dir = dirFlag >= 0 ? args[dirFlag + 1] : process.env.RUN_DIR
  if (!dir) {
    console.error('Usage: tsx scripts/classify-run.ts --dir <ecrr_run_dir>')
    process.exit(2)
  }
  const sigsPath = path.join(dir, 'signatures.json')
  if (!fs.existsSync(sigsPath)) {
    console.error(`Missing signatures.json in ${dir}`)
    process.exit(2)
  }
  const sigs = readJSON<Sigs>(sigsPath)

  // Optional: load signature registry for known issues and owners
  let registry: any = null
  const registryPathCandidates = [
    path.join(process.cwd(), 'ALFA', 'APPS', 'signature-registry.json'),
    path.join(process.cwd(), 'signature-registry.json')
  ]
  for (const p of registryPathCandidates) {
    if (fs.existsSync(p)) { registry = JSON.parse(fs.readFileSync(p, 'utf-8')); break }
  }
  const regIndex: Record<string, any> = {}
  if (registry?.entries) {
    for (const e of registry.entries) regIndex[e.sig_id] = e
  }

  const labels = sigs.top.map((s) => {
    const klass = mapComponentToClass(s.component)
    const reg = regIndex[s.id]
    return {
      sig_id: s.id,
      class: klass,
      component: s.component,
      count: s.count,
      known: Boolean(reg),
      owner: reg?.owner || null,
      playbook_url: reg?.playbook_url || null,
      confidence: reg?.confidence || null,
    }
  })
  const dominant = labels[0]?.class || 'other'
  const out = {
    dominant_class: dominant,
    labels,
    rerun_suggested: dominant === 'flake_or_test_failure',
  }
  fs.writeFileSync(path.join(dir, 'labels.json'), JSON.stringify(out, null, 2))
  console.log(`Classified: ${dir}/labels.json -> dominant=${dominant}`)
}

main().catch((e) => { console.error(e); process.exit(1) })
