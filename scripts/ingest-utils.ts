import fs from 'fs'
import path from 'path'

export type EcrrPaths = {
  root: string
  org: string
  repo: string
  date: string
  run: string
  dir: string
}

export function ensureDir(p: string) {
  if (!fs.existsSync(p)) fs.mkdirSync(p, { recursive: true })
}

// GitHub org/repo names: alphanumeric plus ._- and no leading dot; also
// excludes anything that could act as a path or URL segment separator.
const SEGMENT_RE = /^[A-Za-z0-9][A-Za-z0-9_.-]{0,99}$/

export function safeSegment(v: any, fallback: string): string {
  const s = safeString(v)
  if (s === '.' || s === '..' || !SEGMENT_RE.test(s)) return fallback
  return s
}

export function ecrrPath(root: string, org: string, repo: string, createdAtISO: string, runId: string | number): EcrrPaths {
  const safeOrg = safeSegment(org, 'unknown-org')
  const safeRepo = safeSegment(repo, 'unknown-repo')
  const run = safeString(runId)
  if (!/^\d{1,20}$/.test(run)) throw new Error(`invalid run id: ${JSON.stringify(run).slice(0, 64)}`)
  const d = new Date(createdAtISO)
  if (Number.isNaN(d.getTime())) throw new Error('invalid created_at timestamp')
  const yyyy = String(d.getUTCFullYear())
  const mm = String(d.getUTCMonth() + 1).padStart(2, '0')
  const dd = String(d.getUTCDate()).padStart(2, '0')
  const dir = path.join(root, `org=${safeOrg}`, `repo=${safeRepo}`, `dt=${yyyy}`, mm, dd, `run=${run}`)
  const resolvedRoot = path.resolve(root)
  if (path.resolve(dir) !== resolvedRoot && !path.resolve(dir).startsWith(resolvedRoot + path.sep)) {
    throw new Error('resolved artifact path escapes ECRR root')
  }
  ensureDir(dir)
  return {
    root,
    org: safeOrg,
    repo: safeRepo,
    date: `${yyyy}-${mm}-${dd}`,
    run,
    dir,
  }
}

export function redact(text: string): string {
  let out = text
  // Redact common tokens/secrets
  out = out.replace(/(token|password|secret)[=:]\s*[^\s"']+/gi, '$1=[REDACTED]')
  // Redact emails
  out = out.replace(/[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[A-Za-z]{2,}/g, '[redacted-email]')
  // Redact SHA1/256 like hex hashes (20+ chars)
  out = out.replace(/\b[a-f0-9]{20,64}\b/gi, '[redacted-hash]')
  // Redact IPv4
  out = out.replace(/\b(\d{1,3}\.){3}\d{1,3}\b/g, '[redacted-ip]')
  return out
}

export function writeJson(file: string, data: any) {
  fs.writeFileSync(file, JSON.stringify(data, null, 2))
}

export function writeText(file: string, content: string) {
  fs.writeFileSync(file, content)
}

export function safeString(v: any): string {
  try { return String(v ?? '') } catch { return '' }
}

