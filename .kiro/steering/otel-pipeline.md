<!-- GENERATED FILE - do not hand-edit. Sources: BRIEFING_CLEAN_HOST_E2E.md + DELT/CONF/otel-ports.json. Regen: regen-steering.ps1 -->
# OTel stranger-path ports (steering projection)

Generated: 2026-08-25T12:55:01Z

| Concern | Canonical |
|---------|-----------|
| SigNoz UI | http://localhost:8080 |
| SigNoz OTLP (Docker) | 4317 gRPC / 4318 HTTP |
| Windows collector ingest | **5320** gRPC / **5321** HTTP |
| Collector -> SigNoz | localhost:4317 |
| Collector pin | otelcol-contrib **0.159.0** |

Do **not** bind Windows collector ingest in the PlariumPlay range 5300-5319; use DELT/CONF/otel-ports.json.
