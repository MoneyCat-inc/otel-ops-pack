# CLEAN-HOST E2E ΓÇö Run card (SCHEDULED)

**Run ID:** `clean-host-e2e-20260725`  
**Scheduled:** 2026-07-25T16:20:00Z  
**Briefing:** `docs/BossCat/BRIEFING_CLEAN_HOST_E2E.md`  
**Status:** **COMPLETE ΓÇö RED on clock (68 min > 30), GREEN on pipeline (verify exit 0, canary trace confirmed).** See `CHAR/ECRR/ECRR_REPORTS/ECRR_CLEAN_HOST_E2E_20260725.md` and `artifacts/clean-host-e2e-20260725.json` for findings F1ΓÇôF7.

## Contamination proof (do not run gate clock on daily host)

| Check | This workstation (`D-MONOLITH`) |
|-------|----------------------------------|
| `C:\otel` | Present |
| `otelcol-contrib` | RUNNING |
| SigNoz containers | Present (`signoz`, `signoz-clickhouse`, ΓÇª) |

## Fresh VM (provisioned 2026-07-25)

| Item | Value |
|------|--------|
| Hypervisor | Hyper-V on `D-MONOLITH` |
| VM name | `clean-host-e2e` |
| Generation | 2 (Secure Boot + TPM) |
| Nested virt | **On** (`ExposeVirtualizationExtensions` + MAC spoofing) ΓÇö required for Docker-in-guest |
| vCPU / RAM | 4 vCPU; **static 8 GB** (dynamic memory breaks nested virt ΓÇö Docker reported "Virtualization support not detected" until disabled) |
| Disk | `C:\VMs\clean-host-e2e\clean-host-e2e\Virtual Hard Disks\clean-host-e2e.vhdx` (120 GB) |
| Network | Default Switch |
| Install media | `C:\ISO\Win11_25H2_EnglishInternational_x64.iso` (~7.9 GB, Fido / Microsoft CDN) |
| Connect | `vmconnect.exe localhost clean-host-e2e` |

**Do not** treat the Hyper-V *host* as the clean host. Gate clock runs **inside** this guest only.

### Machine operator ΓÇö Phase 0 (do this now)

OOBE is done (desktop visible). Guest RAM bumped to **8 GB**. Phase 0 payload is already on the guest (BitLocker blocked offline VHD write).

1. [x] OOBE complete  
2. [ ] In **VM Connect**, open **Public Desktop ΓåÆ `RUN-PHASE0.cmd`** (or `C:\Phase0\RUN-PHASE0.cmd`)  
   - First attempt aborted with parser errors: the script contained non-ASCII dashes that the guest's ANSI codepage mangled into a stray quote. Script is now ASCII-only and parse-verified before push; nothing was installed on that failed run.  
3. [ ] Accept the **UAC** prompt  
4. [ ] Wait until the window finishes (Git / pwsh / Python / Docker / otelcol MSI + pip). Docker may need a **reboot** + first Docker Desktop start after.  
5. [ ] Confirm `C:\Phase0\DONE.json` exists; note `phase0_minutes`  
6. [ ] Optional but recommended: Start Docker Desktop, wait for engine healthy  
7. [ ] Ping Cursor: ΓÇ£Phase 0 done, N minutesΓÇ¥

If UAC/desktop launcher missing: open elevated PowerShell in guest and run:
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File C:\Phase0\phase0-setup.ps1
```

## Gate clock (Phases 1ΓÇô4 only)

**Start:** first `git clone` byte  
**Stop:** first canary/synthetic span visible in SigNoz UI (or verify-pipeline exit 0 with span evidence)  
**Target:** Γëñ 30 minutes  
**Phase 0:** recorded separately ΓÇö excluded from gate clock

## Pinned MSI (Phase 0 ΓÇö no tribal hunt)

- **Version:** `otelcol-contrib` **0.104.0** (Gate #022 / runbook-proven; not ΓÇ£latestΓÇ¥)
- **Asset:** `otelcol-contrib_0.104.0_windows_x64.msi`
- **URL:** https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v0.104.0/otelcol-contrib_0.104.0_windows_x64.msi
- **Release page:** https://github.com/open-telemetry/opentelemetry-collector-releases/releases/tag/v0.104.0

## Machine operator ΓÇö Phase 0 checklist (inside guest, before pinging Cursor)

1. [ ] PowerShell 7+  
2. [ ] Git  
3. [ ] Docker Desktop (engine running; nested virt is already enabled on this VM)  
4. [ ] Python 3.11+ on PATH  
5. [ ] `pip install opentelemetry-api opentelemetry-sdk opentelemetry-exporter-otlp-proto-http`  
6. [ ] Download + install pinned MSI above (elevated)  
7. [ ] **Immediately after MSI install** ΓÇö stop and disable the default service (prevents 4317/4318 collision with SigNoz in Phase 1):
   ```powershell
   sc.exe stop otelcol-contrib
   sc.exe config otelcol-contrib start= disabled
   ```
8. [ ] Confirm **before clone:** `Test-Path C:\otel` ΓåÆ false; no leftover SigNoz containers  
9. [ ] Record Phase 0 wall-clock minutes (optional but preferred)

**When Phase 0 is done:** reply in chat with VM ready + Phase 0 minutes. Cursor starts gate clock at clone.

## Cursor ΓÇö Phases 1ΓÇô4 (after ping)

```powershell
# GATE CLOCK START
git clone https://github.com/MoneyCat-inc/otel-ops-pack.git C:\otel
cd C:\otel
pwsh -File .\start-signoz.ps1
pwsh -File .\scripts\preflight-health-check.ps1
# repair script writes config to $env:ProgramData\otelcol-contrib\config.yaml and
# sets HKLM:\SYSTEM\CurrentControlSet\Services\otelcol-contrib ImagePath --config there
pwsh -File .\scripts\windows\install-or-repair-otel-collector.ps1
# verify: (Get-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Services\otelcol-contrib).ImagePath
# should contain ProgramData\otelcol-contrib\config.yaml (not the MSI Program Files default)
pwsh -File .\scripts\quick-monitor.ps1
pwsh -File .\canary-test.ps1
pwsh -File .\BRAV\SCPT\verify-pipeline.ps1
# GATE CLOCK STOP ΓÇö first span visible / verify exit 0
```

## Artifacts to produce

- `artifacts/clean-host-e2e-20260725.json` (timing + exits)  
- `CHAR/ECRR/ECRR_REPORTS/ECRR_CLEAN_HOST_E2E_20260725.md`  
- BOSSCAT_LOG `[CLEAN-HOST E2E]` GREEN/AMBER/RED  

ΓÇö Cursor{Implementer}
