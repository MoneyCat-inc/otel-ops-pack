/**
 * Thin TypeScript binding over DELT/CONF/otel-ports.json.
 * Second Pass B3. Numbers must match windows/otelcol/otelcol-contrib-config.yaml
 * (enforced by BRAV/SCPT/check-otel-ports-drift.ps1).
 *
 * Uses a static JSON import so Next.js client and server bundles stay fs-free.
 */
import portsJson from '../../../DELT/CONF/otel-ports.json'

export type OtelPorts = {
  ingestGrpc: number
  ingestHttp: number
  signozOtlpGrpc: number
  signozOtlpHttp: number
  signozUiHttp: number
  authority: string
}

function fromJson(raw: typeof portsJson): OtelPorts {
  return {
    ingestGrpc: raw.windows_collector_ingest.grpc,
    ingestHttp: raw.windows_collector_ingest.http,
    signozOtlpGrpc: raw.signoz_otlp.grpc,
    signozOtlpHttp: raw.signoz_otlp.http,
    signozUiHttp: raw.signoz_ui.http,
    authority: raw.authority,
  }
}

/** @param _repoRoot retained for call-site compatibility; JSON import is authoritative. */
export function getOtelPorts(_repoRoot?: string): OtelPorts {
  return fromJson(portsJson)
}

/** Convenience: http://127.0.0.1:{ingestHttp} */
export function getOtelIngestHttpBase(host = '127.0.0.1', ports = getOtelPorts()): string {
  return `http://${host}:${ports.ingestHttp}`
}
