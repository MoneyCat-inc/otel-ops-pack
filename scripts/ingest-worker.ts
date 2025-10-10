#!/usr/bin/env tsx
/**
 * ALFA-2 Ingest Worker (BossCat Phase 2 MVP)
 * - Webhook listener for GitHub workflow_run.completed
 * - Writes ECRR artifacts: meta.json, summary.md, events.jsonl
 * - Redacts sensitive strings
 * - Best-effort; continues without GH API calls if token missing
 */

import express from 'express'
import fs from 'fs'
import path from 'path'
import JSZip from 'jszip'
import { ecrrPath, ensureDir, redact, writeJson, writeText, safeString } from './ingest-utils'

type WorkflowRun = {
  id: number
  name?: string
  run_number?: number
  event?: string
  status?: string
  conclusion?: string
  created_at: string
  updated_at?: string
  head_branch?: string
  head_sha?: string
}

type WebhookBody = {
  action?: string
  repository?: { full_name?: string; name?: string; owner?: { login?: string } }
  workflow_run?: WorkflowRun
}

const PORT = Number(process.env.INGEST_PORT || 8787)
const ROOT = process.env.ECRR_ROOT || path.join('artifacts', 'ecrr')

function parseRepo(body: WebhookBody): { org: string; repo: string } {
  const full = safeString(body?.repository?.full_name)
  if (full.includes('/')) {
    const [org, repo] = full.split('/')
    return { org, repo }
  }
  const org = safeString(body?.repository?.owner?.login) || 'unknown-org'
  const repo = safeString(body?.repository?.name) || 'unknown-repo'
  return { org, repo }
}

function summarize(run: WorkflowRun, org: string, repo: string): string {
  const lines = [
    `Run: ${repo} #${run.run_number ?? run.id} (${run.name ?? 'workflow'})`,
    `Org/Repo: ${org}/${repo}`,
    `Event: ${run.event ?? ''}`,
    `Status: ${run.status ?? ''} -> ${run.conclusion ?? ''}`,
    `Branch: ${run.head_branch ?? ''}`,
    `SHA: ${(run.head_sha ?? '').slice(0, 7)}`,
    `Created: ${run.created_at}`,
    `Updated: ${run.updated_at ?? ''}`,
  ]
  return lines.join('\n') + '\n'
}

function recordEvent(dir: string, kind: string, data: any) {
  const file = path.join(dir, 'events.jsonl')
  const rec = { ts: new Date().toISOString(), kind, data }
  fs.appendFileSync(file, JSON.stringify(rec) + '\n')
}

async function handle(body: WebhookBody) {
  const run = body?.workflow_run
  if (!run?.id || !run?.created_at) return { ok: false, reason: 'no run' }
  const { org, repo } = parseRepo(body)
  const p = ecrrPath(ROOT, org, repo, run.created_at, run.id)

  // Files
  const meta = {
    org,
    repo,
    run_id: run.id,
    run_number: run.run_number,
    name: run.name,
    event: run.event,
    status: run.status,
    conclusion: run.conclusion,
    head_branch: run.head_branch,
    head_sha: run.head_sha,
    created_at: run.created_at,
    updated_at: run.updated_at,
    storage: { root: p.root, date: p.date, dir: p.dir },
  }
  writeJson(path.join(p.dir, 'meta.json'), meta)

  const sum = summarize(run, org, repo)
  writeText(path.join(p.dir, 'summary.md'), sum)

  recordEvent(p.dir, 'workflow_run.completed', { org, repo, id: run.id, conclusion: run.conclusion })

  // Placeholder for logs: write a stub file to indicate ingestion
  ensureDir(path.join(p.dir, 'logs'))
  writeText(path.join(p.dir, 'logs', 'ingest.txt'), redact(`ingested ${org}/${repo} run ${run.id} at ${new Date().toISOString()}`))

  // Optional enrichment via GitHub API (jobs + logs)
  if (process.env.GITHUB_TOKEN) {
    try {
      const base = `https://api.github.com/repos/${org}/${repo}/actions/runs/${run.id}`
      const headers: Record<string, string> = {
        Authorization: `Bearer ${process.env.GITHUB_TOKEN}`,
        'User-Agent': 'bosscat-ingest-worker',
        Accept: 'application/vnd.github+json',
      }
      // Jobs metadata
      const jobsRes = await fetch(`${base}/jobs`, { headers })
      if (jobsRes.ok) {
        const jobsJson = await jobsRes.json()
        writeJson(path.join(p.dir, 'jobs.json'), jobsJson)
        recordEvent(p.dir, 'enrich.jobs_saved', { count: jobsJson?.total_count ?? 0 })
      }
      // Logs ZIP
      const logsRes = await fetch(`${base}/logs`, { headers })
      if (logsRes.ok) {
        const ab = await logsRes.arrayBuffer()
        const zip = await JSZip.loadAsync(ab)
        const outDir = path.join(p.dir, 'logs')
        ensureDir(outDir)
        const entries = Object.keys(zip.files).slice(0, 50) // safety cap
        for (const name of entries) {
          const file = zip.files[name]
          if (!file) continue
          if (file.dir) continue
          const txt = await file.async('text')
          const rel = name.replace(/\\/g, '/').split('/').pop() || 'log.txt'
          const dest = path.join(outDir, rel)
          writeText(dest, redact(txt))
        }
        recordEvent(p.dir, 'enrich.logs_extracted', { files: entries.length })
      }
    } catch (e) {
      recordEvent(p.dir, 'enrich.error', { message: String(e) })
    }
  }

  return { ok: true, path: p.dir }
}

async function main() {
  const args = process.argv.slice(2)
  if (args.includes('--file')) {
    const idx = args.indexOf('--file')
    const file = args[idx + 1]
    const raw = fs.readFileSync(file, 'utf-8')
    const json = JSON.parse(raw)
    const res = await handle(json)
    console.log(JSON.stringify(res))
    return
  }

  const app = express()
  app.use(express.json({ limit: '2mb' }))

  app.post('/webhook', async (req, res) => {
    try {
      const event = req.header('x-github-event') || req.header('X-GitHub-Event')
      if (event !== 'workflow_run') {
        return res.status(202).json({ ok: true, skipped: `event=${event}` })
      }
      const body = req.body as WebhookBody
      if (body?.action && body.action !== 'completed') {
        return res.status(202).json({ ok: true, skipped: `action=${body.action}` })
      }
      const out = await handle(body)
      return res.status(out.ok ? 200 : 400).json(out)
    } catch (e: any) {
      return res.status(500).json({ ok: false, error: String(e?.message || e) })
    }
  })

  app.get('/healthz', (_req, res) => res.json({ ok: true }))

  app.listen(PORT, () => {
    console.log(`Ingest worker listening on http://127.0.0.1:${PORT}`)
    console.log(`Root: ${ROOT}`)
    console.log('POST /webhook with GitHub workflow_run payloads')
  })
}

main().catch((e) => { console.error(e); process.exit(1) })
