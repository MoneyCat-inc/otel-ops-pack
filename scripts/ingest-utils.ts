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

export function ecrrPath(root: string, org: string, repo: string, createdAtISO: string, runId: string | number): EcrrPaths {
  const d = new Date(createdAtISO)
  const yyyy = String(d.getUTCFullYear())
  const mm = String(d.getUTCMonth() + 1).padStart(2, '0')
  const dd = String(d.getUTCDate()).padStart(2, '0')
  const dir = path.join(root, `org=${org}`, `repo=${repo}`, `dt=${yyyy}`, mm, dd, `run=${runId}`)
  ensureDir(dir)
  return {
    root,
    org,
    repo,
    date: `${yyyy}-${mm}-${dd}`,
    run: String(runId),
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

