## ECRR Report — Per-Project OTEL Dev Sandboxes

Date: 2025-09-24
Scope: Windows OTEL dev sandboxes under `projects/<name>` with shared SigNoz routing
Actor: Cursor Agent — Observability Copilot

### 1) Examine

- Environment
  - Host: Windows 11; PowerShell 7; local Windows OTEL Collector
  - SigNoz (WSL): UI `http://localhost:8080`, OTLP gRPC `14317`, HTTP `14318`
  - Windows Collector: OTLP HTTP `http://localhost:5318`

- Current sandboxes (confirmed):
  - `projects/payments-dev`, `projects/payments-qa`, `projects/payments qa`, `projects/myproj`, `projects/myproj2`

- Evidence (commands and outcomes)
  - Scaffold sample and real sandboxes:
    - `pwsh -File scripts/init-project-env.ps1 -Name sample -Force` → created `projects/sample`
    - `pwsh -File scripts/init-project-env.ps1 -Name payments-dev` → created `projects/payments-dev`
    - `pwsh -File scripts/init-project-env.ps1 -Name myproj` / `myproj2` / `"payments qa"`
  - Scoped shell and canary emission:
    - `pwsh -File projects/<name>/scripts/enter.ps1 -EmitCanary` → writes `<repo>\projects\<name>\logs\canary.log`
  - SigNoz verification:
    - UI: Logs filter `service.name = <name>` (optional `log.file.path contains "/projects/<name>/logs"`)
    - ClickHouse (WSL): `docker exec signoz-clickhouse clickhouse-client --query "SELECT JSON_VALUE(CAST(resource AS String), '$.service.name') AS service_name, body, fromUnixTimestamp64Nano(timestamp) AS ts FROM signoz_logs.distributed_logs_v2 WHERE body LIKE '%ScopedShellCanary%' ORDER BY timestamp DESC LIMIT 1"` → entries present for `sample`, `payments-dev`, `payments-qa`, `payments qa`, `myproj`, `myproj2`

### 2) Clean

- Removed temporary sandboxes and logs to keep environment tidy:
  - `Remove-Item -Recurse -Force projects/sample`
  - `Remove-Item -Recurse -Force projects/acme` (and `C:\logs\projects\acme` if present)
- Ensured UTF-8 console to avoid garbled symbols when displaying arrows:
  - `[Console]::OutputEncoding = [System.Text.Encoding]::UTF8`

### 3) Report

- Implementation
  - Added `scripts/init-project-env.ps1` to scaffold project sandboxes with:
    - `.env`, `config/collector.project.yaml`, `scripts/enter.ps1`, `logs/`
    - OTEL vars scoped to Windows Collector HTTP `http://localhost:5318` → SigNoz gRPC `http://localhost:14317`
    - Optional `-EmitCanary` to write a canary line to `logs/canary.log`
  - Added guide `docs/PROJECT_ENV_SEPARATION.md` with workflow and verification.

- Verification
  - Multiple sandboxes created and canaries confirmed in SigNoz Logs via `service.name = <name>`.
  - Example entries visible for: `payments-dev`, `payments-qa`, `payments qa`, `myproj`, `myproj2`.

- Artifacts
  - `artifacts/sample_tree.txt` (file listing from initial scaffold verification)
  - Repo docs updated: `docs/PROJECT_ENV_SEPARATION.md`

#### Current project sandboxes (timestamped)

```
@{Name=myproj2; LastWriteTime=24.9.25 14:18:41}
@{Name=payments qa; LastWriteTime=24.9.25 14:16:52}
@{Name=payments-dev; LastWriteTime=24.9.25 14:10:58}
@{Name=payments-qa; LastWriteTime=24.9.25 14:15:46}
```

### 4) Role

- Actor: Cursor Agent — Observability Copilot
- Intent: Shorten feedback loops for per-project development while keeping a single shared SigNoz stack.
- Guardrails: Local-first, no secrets; idempotent scripts; ECRR evidence attached.

### ✅ ECRR Gate

- Examine: Environment and current sandboxes recorded; SigNoz route confirmed (5318 → 14317).
- Clean: Removed temporary sandboxes; enforced UTF-8 for clear output.
- Report: Script and docs added; ClickHouse/UI checks provided.
- Role: Declared (Cursor Agent — Observability Copilot).


