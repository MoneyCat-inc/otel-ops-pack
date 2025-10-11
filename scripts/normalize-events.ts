#!/usr/bin/env tsx
/**
 * BRAV-2 Normalizer
 * - Reads ECRR run directory (meta.json + logs/*)
 * - Produces events.jsonl (normalized) and signatures.json (top signatures)
 */

import fs from 'fs'
import path from 'path'
import crypto from 'crypto'

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

type Sig = { id: string; sample: string; count: number; component: string }

function readJSON<T>(file: string): T {
  return JSON.parse(fs.readFileSync(file, 'utf-8')) as T
}

function listLogFiles(dir: string): string[] {
  const logsDir = path.join(dir, 'logs')
  if (!fs.existsSync(logsDir)) return []
  const all = fs.readdirSync(logsDir)
  return all
    .filter((f) => /\.(log|txt|out|err)$/i.test(f) || f === 'ingest.txt')
    .map((f) => path.join(logsDir, f))
}

function normalizeMessage(line: string): string {
  let s = line
  // Strip paths (Windows/Unix-like)
  s = s.replace(/[A-Za-z]:\\[^\s]+/g, '[path]')
  s = s.replace(/\/(?:[^\s/]+\/)+[^\s]+/g, '[path]')
  // Strip numbers (line numbers, PIDs, durations)
  s = s.replace(/:\d+/g, ':[n]')
  s = s.replace(/\b\d{3,}\b/g, '[n]')
  // Strip SHAs / long hex
  s = s.replace(/\b[a-f0-9]{7,64}\b/gi, '[hex]')
  // Collapse whitespace
  s = s.replace(/\s+/g, ' ').trim()
  return s
}

function classifyComponent(msg: string): string {
  const m = msg.toLowerCase()
  if (/(pytest|assertionerror|jest|test failed|expect\()/.test(m)) return 'test'
  if (/(npm|pnpm|yarn|pip|requirements|package\.json|dependency|module not found)/.test(m)) return 'deps'
  if (/(tsc|build failed|babel|webpack|esbuild)/.test(m)) return 'build'
  if (/(cache|artifact|upload-artifact|download-artifact)/.test(m)) return 'cache'
  if (/(timeout|rate limit|429|network error|dns)/.test(m)) return 'infra'
  return 'other'
}

function makeSigId(key: string): string {
  return crypto.createHash('sha1').update(key).digest('hex').slice(0, 12)
}

function appendEvent(file: string, record: any) {
  fs.appendFileSync(file, JSON.stringify(record) + '\n')
}

function ensureFileReset(file: string) {
  fs.writeFileSync(file, '')
}

async function main() {
  const args = process.argv.slice(2)
  const dirFlag = args.indexOf('--dir')
  const dir = dirFlag >= 0 ? args[dirFlag + 1] : process.env.RUN_DIR
  if (!dir) {
    console.error('Usage: tsx scripts/normalize-events.ts --dir <ecrr_run_dir>')
    process.exit(2)
  }

  const metaPath = path.join(dir, 'meta.json')
  if (!fs.existsSync(metaPath)) {
    console.error(`Missing meta.json in ${dir}`)
    process.exit(2)
  }
  const meta = readJSON<Meta>(metaPath)

  const eventsFile = path.join(dir, 'events.jsonl')
  const sigsFile = path.join(dir, 'signatures.json')
  ensureFileReset(eventsFile)

  const sigMap = new Map<string, Sig>()

  // Seed an event for meta
  appendEvent(eventsFile, { ts: new Date().toISOString(), kind: 'meta', data: meta })

  // Process logs
  const files = listLogFiles(dir)
  for (const f of files) {
    const content = fs.readFileSync(f, 'utf-8')
    const lines = content.split(/\r?\n/)
    for (const line of lines) {
      if (!line.trim()) continue
      const norm = normalizeMessage(line)
      const component = classifyComponent(norm)
      const sigKey = `${component}|${norm}`
      const id = makeSigId(sigKey)
      const rec = { ts: new Date().toISOString(), kind: 'log', file: path.basename(f), component, sig_id: id, msg: norm }
      appendEvent(eventsFile, rec)
      const prev = sigMap.get(id)
      if (prev) prev.count += 1
      else sigMap.set(id, { id, sample: norm.slice(0, 280), count: 1, component })
    }
  }

  // Aggregate
  const sigs = Array.from(sigMap.values()).sort((a, b) => b.count - a.count).slice(0, 25)
  fs.writeFileSync(sigsFile, JSON.stringify({ total: sigMap.size, top: sigs }, null, 2))

  console.log(`Normalized: ${files.length} files, ${sigMap.size} signatures -> ${dir}`)
}

main().catch((e) => { console.error(e); process.exit(1) })

