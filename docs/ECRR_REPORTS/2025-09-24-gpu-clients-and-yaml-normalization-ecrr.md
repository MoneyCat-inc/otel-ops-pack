# ECRR Report — GPU Clients Endpoint & YAML Path Normalization (2025-09-24)

## Examine

- Client defaults used HTTP-style `http://localhost:4317` for OTLP gRPC in:
  - `run-gpu-metrics.ps1`
  - `gpu-metrics-simple.py`
  - `gpu-metrics-emitter.py`
- Local collector YAML `collector/otel-local.yaml` used backslash paths `C:\\logs\\**\\*.log` which can be brittle; we standardize to `C:/...` for the Windows Collector.

## Clean

- Endpoints:
  - `run-gpu-metrics.ps1`: default endpoint → `localhost:4317`; renamed `$args` → `$pyArgs` to avoid PS automatic var.
  - `gpu-metrics-simple.py`: default and CLI help → `localhost:4317` (gRPC wording).
  - `gpu-metrics-emitter.py`: default and CLI help → `localhost:4317` (gRPC wording).
- YAML path normalization:
  - `collector/otel-local.yaml`: `filelog.include` → `C:/logs/**/*.log`.

## Report

- Files updated: 4
  - `run-gpu-metrics.ps1`
  - `gpu-metrics-simple.py`
  - `gpu-metrics-emitter.py`
  - `collector/otel-local.yaml`
- Rationale: align examples and local tools with canonical endpoint/paths to prevent confusion and parsing issues.

## Verification

- Lint: no warnings in `run-gpu-metrics.ps1` after variable rename.
- Syntax: Python scripts load and parse; help shows gRPC endpoint format.
- YAML: Collector includes path using forward slashes (preferred on Windows Collector).

## Role

- Actor: Cursor Agent — Observability Copilot
- Scope: Client endpoint correctness and YAML path normalization.

## ✅ ECRR Gate

- Examine: identified mismatched endpoint scheme and path style.
- Clean: applied endpoint and path updates.
- Report: this document.
- Role: declared.

## Next Actions

- Optionally normalize `config/otelcol-windows.yaml` paths to `C:/...` if that file is active in the service.
- Add CI lint to flag `http://localhost:4317` in code/docs.


