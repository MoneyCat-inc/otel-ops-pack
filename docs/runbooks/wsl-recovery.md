<!-- markdownlint-disable MD013 MD034 -->
# WSL / Docker Engine Recovery

**Authority:** BossCat OEM  
**Status:** ACTIVE  
**Date:** 2026-08-16  
**Scope:** Host where SigNoz runs under Docker Desktop (WSL2 backend)

---

## When to use this

Use when the Windows collector is fine but SigNoz / Docker looks dead:

| Symptom | Typical signal |
|---------|----------------|
| `docker ps` / `docker info` | HTTP **500** on `dockerDesktopLinuxEngine`, or hangs |
| SigNoz UI `http://localhost:8080/api/v1/health` | Timeout while ports 8080/4317/4318 still “listen” |
| `wsl -l -v` | Hangs or never returns |
| Docker backend log | `still waiting for the engine to respond to _ping` / `context deadline exceeded` on `/ping` |
| Zombie VM | Old `vmmem` with **WorkingSet 0** (often from a prior session) |

**Do not** burn time on collector repair first — `otelcol-contrib` can be Running and OTLP `5320`/`5321` healthy while the Docker/WSL side is wedged.

Related: [windows-collector.md](./windows-collector.md) · [docker-fix-steps.md](./misc/docker-fix-steps.md)

---

## Prefer reboot first

If WSL is wedged (`wsl -l -v` or `wsl --shutdown` hang), a **Windows reboot is faster and safer** than a long kill sequence. Reboot clears zombie `vmmem` / stuck Hyper-V state that soft restarts often miss.

After reboot:

```powershell
docker info
docker ps --format "table {{.Names}}\t{{.Status}}"
Invoke-RestMethod http://localhost:8080/api/v1/health
pwsh -File C:\otel\scripts\quick-monitor.ps1 -PreflightCheck
pwsh -File C:\otel\BRAV\SCPT\verify-pipeline.ps1
```

---

## Soft recovery (when reboot is not an option)

Proven sequence from host recovery on **2026-08-16** (engine returned to GREEN without reboot).

### 1) Confirm the failure mode

```powershell
# Cap hangs — do not wait forever
$j = Start-Job { wsl -l -v 2>&1 | Out-String }
if (-not (Wait-Job $j -Timeout 15)) {
  Write-Host "WSL LIST HUNG — prefer reboot, or continue soft recovery"
  Stop-Job $j; Remove-Job $j -Force
} else {
  Receive-Job $j; Remove-Job $j -Force
}

docker info 2>&1 | Select-Object -First 20
```

Backend log (optional): `%LOCALAPPDATA%\Docker\log\host\com.docker.backend.exe.log`

Look for repeated `engines ... GET /ping` → `context deadline exceeded` and `HTTP 500` on `_ping`.

### 2) Quit Docker Desktop hard

```powershell
Get-Process "Docker Desktop","com.docker.backend","com.docker.build","docker-agent","docker" `
  -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
```

Leave `com.docker.service` alone unless Step 3 also fails.

### 3) Unstick WSL

Try graceful first (60 s cap):

```powershell
$j = Start-Job { wsl --shutdown 2>&1 }
if (-not (Wait-Job $j -Timeout 60)) {
  Stop-Job $j; Remove-Job $j -Force
  # Escalation — machine operator / admin shell
  Stop-Service vmcompute -Force -ErrorAction SilentlyContinue
  Get-Process wsl,wslservice,wslhost,vmmem,vmmemWSL -ErrorAction SilentlyContinue |
    Stop-Process -Force -ErrorAction SilentlyContinue
  Start-Service vmcompute -ErrorAction SilentlyContinue
} else {
  Receive-Job $j; Remove-Job $j -Force
}
```

Probe:

```powershell
$j = Start-Job { wsl -l -v 2>&1 | Out-String }
if (Wait-Job $j -Timeout 20) { Receive-Job $j; Remove-Job $j -Force }
else { Write-Host "WSL still hung — reboot"; Stop-Job $j; Remove-Job $j -Force }
```

Expect `Ubuntu` / `docker-desktop` listed (often **Stopped** right after shutdown).

### 4) Start Docker Desktop and wait for the engine

```powershell
Start-Process "${env:ProgramFiles}\Docker\Docker\Docker Desktop.exe"

$deadline = (Get-Date).AddMinutes(3)
do {
  docker info --format "{{.ServerVersion}}" 2>$null
  if ($LASTEXITCODE -eq 0) { break }
  Start-Sleep -Seconds 5
} while ((Get-Date) -lt $deadline)

docker ps --format "table {{.Names}}\t{{.Status}}"
```

### 5) Confirm SigNoz + pipeline

```powershell
Invoke-RestMethod http://localhost:8080/api/v1/health
pwsh -File C:\otel\scripts\quick-monitor.ps1 -PreflightCheck
pwsh -File C:\otel\BRAV\SCPT\verify-pipeline.ps1
```

**Pass:** quick-monitor exit 0; verify-pipeline exit 0 (WARN only for non-blocking clock skew — see below).

---

## Clock skew note (ingest latency)

WSL inherits the Windows host clock. If verify-pipeline reports absurd / negative ingest latency after an outage:

```powershell
w32tm /query /status
w32tm /query /source
```

Healthy example: `Source: time.windows.com`, recent **Last Successful Sync Time**, not `Local CMOS Clock`.

Only if stale / CMOS:

```powershell
w32tm /resync /force
```

Negative latency right after a SigNoz outage is often an **artifact of the outage window**, not a broken clock — check sync status before forcing resync.

---

## Escalation

| If… | Then… |
|-----|--------|
| Soft recovery fails twice | **Reboot Windows** |
| Engine starts but `docker-desktop-data` missing / data disk broken | [docker-fix-steps.md](./misc/docker-fix-steps.md) Step 3 (unregister distros — **data loss**) |
| Privileged helper service dialog | [docker-fix-steps.md](./misc/docker-fix-steps.md) Step 1–2 |
| Collector RED after Docker is green | [windows-collector.md](./windows-collector.md) |

---

## Incident reference

- **2026-08-16:** Docker Desktop up; engine `_ping` → 500; `wsl -l -v` hung; OTLP ports held by `wslrelay` but SigNoz UI timed out. Soft recovery (kill Docker → force WSL/vmcompute path → restart Docker) restored engine **29.6.1** and SigNoz stack; verify-pipeline **GREEN**. Zombie `vmmem` from prior day remained — reboot preferred next time.

---

**Authority:** BossCat OEM  
**Actor (recovery):** Cursor{Implementer} + machine operator
