## Project-scoped OTEL dev sandboxes

Goal: Create isolated per-project sandboxes under `projects/<name>` that export OTEL variables locally while forwarding to the shared Windows Collector and central SigNoz stack.

Key facts
- Shared SigNoz (WSL): UI `http://localhost:8080`, OTLP gRPC `14317`, OTLP HTTP `14318`.
- Windows Collector service: OTLP HTTP on `http://localhost:5318` (used by projects).
- Projects inherit shared routing: `projects/<name>` → Windows Collector (5318) → SigNoz (14317).

Workflow
1) Scaffold a sandbox
```powershell
pwsh -File scripts/init-project-env.ps1 -Name myproj
```
Creates:
- `projects/myproj/.env`
- `projects/myproj/config/collector.project.yaml` (optional, not required to run)
- `projects/myproj/scripts/enter.ps1`
- `projects/myproj/logs/`

2) Enter scoped shell and optionally emit a canary
```powershell
pwsh -File projects/myproj/scripts/enter.ps1 -EmitCanary
```
Exports OTEL vars for the session and writes `logs/canary.log`.

3) Verify in SigNoz
- UI → Logs → add filter: `service.name = myproj`
- Optional: also filter `log.file.path contains "/projects/myproj/logs"`
Expect a canary row within seconds.

Routing details
- Projects use OTLP/HTTP to `http://localhost:5318` (Windows Collector).
- The Windows Collector forwards to SigNoz in WSL at `http://localhost:14317` (gRPC).
- No project runs its own SigNoz; isolation is by resource attributes (e.g., `service.name=<project>`).

Troubleshooting
- Collector service: `sc query otelcol-contrib`
- Ports: `pwsh -File .\check-ports.ps1`
- SigNoz health: `http://localhost:8080/api/v1/health`

Rollback
- Delete the project folder under `projects/` to remove the sandbox.

# OTEL Project Environment Separation

This guide explains how to maintain per-project developer environments while sharing the local OTEL/SigNoz stack. Each project receives an isolated workspace under `C:\otel\projects` with its own config, scripts, and artifacts. The shared SigNoz instance in WSL continues to collect telemetry on ports 14317/14318.

## Scaffold Layout

Running the scaffold creates the following layout:

```
C:\otel\projects\<project>
  ??? artifacts/            # Project-specific dashboards, verification notes
  ??? config/               # Local collector overrides (if needed)
  ??? docs/                 # Project runbooks
  ??? logs/                 # File logs for this project only
  ??? scripts/enter.ps1     # Opens a shell scoped to this project
  ??? README.md             # Isolation instructions for the project
  ??? .env                  # Default OTEL exporter variables
```

## Create a New Project Environment

1. Generate the scaffold:
   ```powershell
   pwsh -File scripts/init-project-env.ps1 -Name <project>
   ```
   - Use `-Force` to refresh managed files if you need to regenerate assets.
2. Review `projects/<project>/README.md` for project-specific instructions.
3. Capture additional docs in `projects/<project>/docs/` and store run artifacts under `artifacts/`.

## Working Inside a Project Shell

Launch an isolated shell that exports project-scoped OTEL variables:

```powershell
pwsh -File projects/<project>/scripts/enter.ps1
```

The script sets:
- `PROJECT_NAME=<project>`
- `OTEL_CONFIG_DIR=C:\otel\projects\<project>\config`
- `OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:14317`
- `OTEL_RESOURCE_ATTRIBUTES=service.name=<project>,environment=dev`

It then opens a new PowerShell session rooted at the project directory while leaving the shared SigNoz stack untouched in WSL.

## Telemetry Routing

- File logs written under `projects/<project>/logs` are shipped through the generated `config/otel-collector.yaml`, which forwards to the shared collector on `http://localhost:14317`.
- Windows Event Log ingestion and SigNoz itself remain centralized; no SigNoz components should run inside the project shell.

## Verification Checklist

1. Scaffold a test project:
   ```powershell
   pwsh -File scripts/init-project-env.ps1 -Name sample -Force
   Get-ChildItem projects/sample -Recurse
   ```
2. Open the scoped shell and confirm environment variables:
   ```powershell
   pwsh -File projects/sample/scripts/enter.ps1
   [Environment]::GetEnvironmentVariable('PROJECT_NAME')
   exit
   ```
3. Confirm SigNoz receives logs:
   - Write a log entry into `projects/sample/logs/test.log`.
   - Use SigNoz Logs with filter `service.name = sample` to validate ingestion.

Following these steps keeps each project's runtime isolated while reusing the hardened SigNoz stack.
