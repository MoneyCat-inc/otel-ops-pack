/**
 * Thin TypeScript binding over DELT/CONF/otel-ports.json.
 * Second Pass B3. Numbers must match windows/otelcol/otelcol-contrib-config.yaml
 * (enforced by BRAV/SCPT/check-otel-ports-drift.ps1).
 */
import fs from 'fs'
import path from 'path'

export type OtelPorts = {
  ingestGrpc: number
  ingestHttp: number
  signozOtlpGrpc: number
  signozOtlpHttp: number
  signozUiHttp: number
  authority: string
}

function findRepoRoot(startDir: string): string {
  let dir = path.resolve(startDir)
  for (;;) {
    const candidate = path.join(dir, 'DELT', 'CONF', 'otel-ports.json')
    if (fs.existsSync(candidate)) return dir
    const parent = path.dirname(dir)
    if (parent === dir) {
      throw new Error('getOtelPorts: could not locate DELT/CONF/otel-ports.json')
    }
    dir = parent
  }
}

export function getOtelPorts(repoRoot?: string): OtelPorts {
  const root = repoRoot ?? findRepoRoot(process.cwd())
  const jsonPath = path.join(root, 'DELT', 'CONF', 'otel-ports.json')
  const raw = JSON.parse(fs.readFileSync(jsonPath, 'utf8')) as {
    authority: string
    windows_collector_ingest: { grpc: number; http: number }
    signoz_otlp: { grpc: number; http: number }
    signoz_ui: { http: number }
  }
  return {
    ingestGrpc: raw.windows_collector_ingest.grpc,
    ingestHttp: raw.windows_collector_ingest.http,
    signozOtlpGrpc: raw.signoz_otlp.grpc,
    signozOtlpHttp: raw.signoz_otlp.http,
    signozUiHttp: raw.signoz_ui.http,
    authority: raw.authority,
  }
}

/** Convenience: http://127.0.0.1:{ingestHttp} */
export function getOtelIngestHttpBase(host = '127.0.0.1', ports = getOtelPorts()): string {
  return `http://${host}:${ports.ingestHttp}`
}
