<!-- GENERATED FILE — do not hand-edit. Sources: BRIEFING_CLEAN_HOST_E2E.md. Regen: regen-steering.ps1 -->
# OTel stranger-path ports (steering projection)

Generated: 2026-07-26T17:23:13Z

| Concern | Canonical |
|---------|-----------|
| SigNoz UI | http://localhost:8080 |
| SigNoz OTLP (Docker) | 4317 gRPC / 4318 HTTP |
| Windows collector ingest | **5320** gRPC / **5321** HTTP |
| Collector → SigNoz | localhost:4317 |
| Collector pin | otelcol-contrib **0.104.0** |

Do **not** use historical 5317/5318 for Windows collector ingest (PlariumPlay conflict class).
