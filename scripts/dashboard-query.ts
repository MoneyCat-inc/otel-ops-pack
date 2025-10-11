#!/usr/bin/env tsx
/**
 * DELT-2 Dashboard rollup (7d aggregates)
 * - Scans ECRR tree for recent runs
 * - Aggregates signature counts and dominant components
 * - Writes rollups to output directory; optional snapshot file
 */
import fs from 'fs'
import path from 'path'

type SigTop = { id: string; sample: string; count: number; component: string }
type Sigs = { total: number; top: SigTop[] }
type Labels = { dominant_class?: string; labels?: { component: string; class: string; count: number }[] }

function daysAgoUTC(days: number) {
  const d = new Date()
  d.setUTCDate(d.getUTCDate() - days)
  d.setUTCHours(0, 0, 0, 0)
  return d
}

function walk(dir: string, acc: string[] = []): string[] {
  if (!fs.existsSync(dir)) return acc
  for (const entry of fs.readdirSync(dir)) {
    const full = path.join(dir, entry)
    const st = fs.statSync(full)
    if (st.isDirectory()) {
      if (/run=/.test(entry)) acc.push(full)
      walk(full, acc)
    }
  }
  return acc
}

function inWindowByPath(runDir: string, since: Date): boolean {
  // try to parse dt=YYYY/MM/DD from path
  const parts = runDir.split(path.sep)
  const dtIndex = parts.findIndex((p) => p.startsWith('dt='))
  if (dtIndex >= 0 && parts.length >= dtIndex + 3) {
    const yyyy = parts[dtIndex].slice(3)
    const mm = parts[dtIndex + 1]
    const dd = parts[dtIndex + 2]
    const stamp = Date.parse(`${yyyy}-${mm}-${dd}T00:00:00Z`)
    return isFinite(stamp) ? new Date(stamp) >= since : true
  }
  return true
}

function ensureDir(p: string) { if (!fs.existsSync(p)) fs.mkdirSync(p, { recursive: true }) }

async function main() {
  const args = process.argv.slice(2)
  const get = (key: string, def?: string) => {
    const i = args.indexOf(key)
    return i >= 0 ? args[i + 1] : def
  }
  const root = get('--root', 'artifacts/ecrr')!
  const days = Number(get('--days', '7'))
  const outDir = get('--out', 'DELT/ARTF')!
  const snapshotDir = get('--snapshot')

  const since = daysAgoUTC(days)
  const runs = walk(root).filter((d) => inWindowByPath(d, since))

  const sigCounts = new Map<string, number>()
  const compCounts = new Map<string, number>()

  for (const rd of runs) {
    try {
      const sigFile = path.join(rd, 'signatures.json')
      if (fs.existsSync(sigFile)) {
        const sigs = JSON.parse(fs.readFileSync(sigFile, 'utf-8')) as Sigs
        for (const t of sigs.top || []) {
          sigCounts.set(t.id, (sigCounts.get(t.id) || 0) + (t.count || 0))
          compCounts.set(t.component, (compCounts.get(t.component) || 0) + 1)
        }
      }
      const labelsFile = path.join(rd, 'labels.json')
      if (fs.existsSync(labelsFile)) {
        const labels = JSON.parse(fs.readFileSync(labelsFile, 'utf-8')) as Labels
        const dom = labels.dominant_class
        if (dom) compCounts.set(dom, (compCounts.get(dom) || 0) + 1)
      }
    } catch {}
  }

  ensureDir(outDir)
  const sigArray = Array.from(sigCounts.entries()).map(([sig_id, total]) => ({ sig_id, total }))
  const compArray = Array.from(compCounts.entries()).map(([component, total]) => ({ component, total }))

  const sigOut = path.join(outDir, 'ecrr_signature_counts_7d.json')
  const compOut = path.join(outDir, 'ecrr_dominant_components_7d.json')
  fs.writeFileSync(sigOut, JSON.stringify({ generated_at: new Date().toISOString(), days, data: sigArray }, null, 2))
  fs.writeFileSync(compOut, JSON.stringify({ generated_at: new Date().toISOString(), days, data: compArray }, null, 2))

  if (snapshotDir) {
    ensureDir(snapshotDir)
    const yyyymmdd = new Date().toISOString().slice(0, 10).replace(/-/g, '')
    const snap = path.join(snapshotDir, `ecrr-aggregates-${yyyymmdd}.json`)
    fs.writeFileSync(snap, JSON.stringify({ signature_counts: sigArray, dominant_components: compArray }, null, 2))
    console.log(`Snapshot written: ${snap}`)
  }

  console.log(`Aggregated ${runs.length} runs -> ${sigOut}, ${compOut}`)
}

main().catch((e) => { console.error(e); process.exit(1) })

