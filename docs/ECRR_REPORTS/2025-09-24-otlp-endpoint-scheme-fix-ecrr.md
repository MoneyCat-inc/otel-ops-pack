# ECRR Report — OTLP Endpoint Scheme Correction (2025-09-24)

## Examine

- Found OTLP gRPC endpoints documented/defined with HTTP schema (`http://localhost:4317`) in:
  - `collector/otel-local.yaml`
  - `docs/OBSERVABILITY_SETUP.md` (guide + snippet)
  - `verify-collector.ps1` (status line)
- Risk: Misleading examples/config for gRPC exporter; gRPC uses host:port, not HTTP URL.

## Clean

- `collector/otel-local.yaml`: set `endpoint: localhost:4317` (gRPC syntax).
- `docs/OBSERVABILITY_SETUP.md`: clarified text (gRPC on 4317) and snippet to `localhost:4317`.
- `verify-collector.ps1`: guidance string updated to reference gRPC on `localhost:4317`.

## Report

- Files updated: 3 (config + doc + script string).
- No functional change to pipeline; improves correctness and avoids confusion.

### Verification

- Lint checks: passed for all edited files.
- `docker-compose.yml` continues exposing 14317/14318 for Windows collector → SigNoz path.

## Role

- Actor: Cursor Agent — Observability Copilot
- Scope: Correct endpoint scheme usage across config and docs.

## ✅ ECRR Gate

- Examine: identified incorrect HTTP schema on gRPC endpoint references.
- Clean: corrected endpoint syntax in all locations.
- Report: this document with verification notes.
- Role: declared.

## Next Actions

- Add a simple CI lint to flag `http://localhost:4317` in YAML/documentation.


