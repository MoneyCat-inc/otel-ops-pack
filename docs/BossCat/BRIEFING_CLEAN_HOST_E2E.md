# BRIEFING — Clean-host E2E (stranger gate)

**Authority:** BossCat OEM / oversight seat (post–Pack 3B follow-on)  
**Owner (brief):** Cursor{Implementer}  
**Owner (run):** Machine operator at Cursor tab + Cursor{Implementer} verify  
**Status:** READY TO EXECUTE — no measured baseline yet  
**Promise under test:** A stranger on a fresh Windows host can go from clone → first span in SigNoz without tribal knowledge.

This is the first gate in the project that tests the **promise to strangers**, not the machinery behind it. Draft it to fail closed: if a step needs tribal knowledge, the briefing is incomplete.

---

## Why this exists

Ops-pack health on a configured workstation is GREEN. That does **not** prove the README promise. Clean-host E2E asks: starting from a blank Windows machine, how long until a canary span is visible in SigNoz, and which steps break without an insider?

Board order: after CHAR review (Unblock #2 closed). This item is the highest-leverage remaining gate.

---

## Clean-host profile (definition — hard)

| Attribute | Required |
|-----------|----------|
| OS | Fresh Windows 10/11 (VM OK) — **not** the daily MoneyCat workstation |
| Prior state | No Docker images for SigNoz; no `otelcol-contrib` service; no `C:\otel` clone; no leftover `C:\logs` canaries |
| Operator | Can run elevated PowerShell for Event Log source + service install |
| Network | Localhost only for this gate (no cloud SigNoz) |
| Out of scope | pnpm CI parity, Resonai app, GPU/viz lanes, social bots, CHAR disposition |

**Fail closed:** If the host already has SigNoz containers or a collector service, wipe or use a new VM. Contaminated hosts invalidate the clock.

---

## Actor seats (from `AGENTS.md`)

| Step | Seat |
|------|------|
| Docker Desktop install, MSI download/install, admin Event Log, first SigNoz UI login | **Machine operator** |
| Scripted compose up, config sync, canary, verify, ECRR + timing artifact | **Cursor{Implementer}** |
| Accept GREEN / AMBER / RED; decide README fixes | **Chat / review / OEM** |

No credential mint required for baseline path (ClickHouse fallback in gate verify). Optional later: scoped `SIGNOZ_API_KEY` for API-path confirmation.

---

## Canonical targets (stranger-facing — single story)

Lock these for the run. Document drift; do not improvise mid-gate.

| Concern | Canonical | Do **not** use |
|---------|-----------|----------------|
| Repo path | `C:\otel` (verify scripts assume it) | Arbitrary clone path without updating scripts |
| SigNoz UI | http://localhost:8080 | — |
| SigNoz OTLP (Docker host) | `4317` gRPC / `4318` HTTP | — |
| Windows collector ingest | `5320` gRPC / `5321` HTTP | `5317`/`5318` (historical / PlariumPlay conflict) |
| Collector → SigNoz export | `localhost:4317` (template `windows/otelcol/otelcol-contrib-config.yaml`) | Mid-run inventing `14317` unless runbook path is explicitly chosen |
| Collector config | Service `--config C:\otel\config.yaml` (runbook) synced from template | Silent ProgramData-only drift |
| Compose file | Root `docker-compose.yml` via `start-signoz.ps1` or `docker compose up -d` | Parked `compose/docker-compose-signoz.yml` |
| Gate verify | `BRAV\SCPT\verify-pipeline.ps1` | Missing `scripts\verify-pipeline.ps1`; root `verify-pipeline.ps1` (legacy ClickHouse log script) |
| Fast health | `scripts\quick-monitor.ps1` | — |
| Canary (no Python) | `canary-test.ps1` (repo root) | `scripts\windows\test-otlp-e2e.ps1` (**HISTORICAL**, wrong ports) |

**Known tension to resolve in Examine (not mid-Clean):** runbook still elevates `14317` for .NET direct export; README/template elevate `4317` + collector `5320/5321`. Clean-host baseline uses **collector path** (apps → `5321` → collector → `4317` → SigNoz). Direct `.NET → 14317` is a separate optional probe, not the stranger path.

---

## Examine (before the clock starts)

Capture on the clean host:

1. `winver` / OS build  
2. `pwsh -v` (need 7+)  
3. `docker version` (Desktop installed, engine running) — or note “not installed”  
4. `sc query otelcol-contrib` — expect SERVICE_NOT_FOUND  
5. `Test-Path C:\otel` — expect false  
6. Free ports: `8080`, `4317`, `4318`, `5320`, `5321`  
7. Stopwatch ready (wall clock from “clone starts” → “span visible”)

Write Examine block into ECRR before any install.

---

## Clean — ordered bootstrap (zero → first trace)

Times below are **targets for the briefing**, not yet measured. Record actuals.

### Phase 0 — Tooling (machine operator)

| # | Step | Notes |
|---|------|-------|
| 0.1 | Install PowerShell 7+ | — |
| 0.2 | Install Docker Desktop; start engine | WSL2 backend as required by Docker |
| 0.3 | Install Git | — |
| 0.4 | Install Python 3.11+ on PATH | Needed for `BRAV\SCPT\verify-pipeline.ps1` synthetic |
| 0.5 | `pip install opentelemetry-api opentelemetry-sdk opentelemetry-exporter-otlp-proto-http` | Match `synthetic/send_synthetic_otel_simple.py` needs |

### Phase 1 — Clone

```powershell
git clone https://github.com/MoneyCat-inc/otel-ops-pack.git C:\otel
cd C:\otel
```

### Phase 2 — SigNoz

```powershell
pwsh -File C:\otel\start-signoz.ps1
# wait until http://localhost:8080/api/v1/health is OK
pwsh -File C:\otel\scripts\preflight-health-check.ps1
```

Machine operator: complete SigNoz first-run UI if prompted (admin user). Note whether UI blocked the clock.

### Phase 3 — Windows collector

| # | Step |
|---|------|
| 3.1 | Download/install official `otelcol-contrib` Windows MSI (machine operator — URL pinned in run ECRR; do not leave “find the MSI” tribal) |
| 3.2 | Sync template → live config: ensure `C:\otel\config.yaml` matches `windows\otelcol\otelcol-contrib-config.yaml` (or documented sync command) |
| 3.3 | `pwsh -File C:\otel\scripts\windows\install-or-repair-otel-collector.ps1` — service must point at `C:\otel\config.yaml` |
| 3.4 | `sc qc otelcol-contrib` — confirm BINARY_PATH_NAME includes `C:\otel\config.yaml` |
| 3.5 | `sc query otelcol-contrib` — RUNNING |

### Phase 4 — Prove the promise

```powershell
pwsh -File C:\otel\scripts\quick-monitor.ps1
pwsh -File C:\otel\canary-test.ps1
pwsh -File C:\otel\BRAV\SCPT\verify-pipeline.ps1
```

**Span visibility:** SigNoz UI → Traces/Logs; query canary / synthetic service name from verify output. Screenshot optional but preferred for stranger-facing evidence.

---

## Report — acceptance criteria

| Criterion | Pass | Fail |
|-----------|------|------|
| Wall clock clone → first span visible | Record minutes; **target ≤ 30 min** stranger path (aspirational until measured) | Abandoned / blocked > 60 min without ECRR |
| `quick-monitor` | Exit 0 / all critical green | RED on SigNoz or collector |
| `verify-pipeline` | Exit **0** (OK); WARN (1) = AMBER with reasons | Exit 2 FAIL |
| Ingest latency (gate sample) | ≤ **5000 ms** (existing SLO in verify-pipeline) | Sustained > 5 s |
| Ports story | Stranger used only 5320/5321 + 4317/4318 + 8080 | Had to discover 5317/14317 from folklore |
| Docs honesty | Every command in this briefing exists at the path given | Broken README pointers required insider fix mid-run |

**Artifacts (mandatory):**

- ECRR: `CHAR/ECRR/ECRR_REPORTS/ECRR_CLEAN_HOST_E2E_<YYYYMMDD>.md`
- Timing JSON: `artifacts/clean-host-e2e-<stamp>.json` with phase timestamps + total minutes + exit codes
- Gate JSON if produced: `out/gate_verification.json` (or path verify-pipeline writes)
- BOSSCAT_LOG one-liner: `[CLEAN-HOST E2E]` GREEN/AMBER/RED + minutes + top blocker

**Verdict language:**

- **GREEN** — stranger path works within target; README needs at most link fixes  
- **AMBER** — path works but required undocumented steps / port folklore / >30 min  
- **RED** — cannot reach first span without changing code or tribal rescue  

AMBER/RED must list **README / script fixes** as follow-on PRs (broken `scripts\verify-pipeline.ps1` pointer, HISTORICAL e2e in Quick Commands, MSI URL pin, config sync one-liner).

---

## Gaps this briefing already names (fix during or after run)

1. Root README Quick Commands still cite `scripts\windows\test-otlp-e2e.ps1` (HISTORICAL).  
2. No `scripts\verify-pipeline.ps1` wrapper → `BRAV\SCPT\verify-pipeline.ps1`.  
3. `install-or-repair-otel-collector.ps1` does not download MSI — stranger stuck at “install collector.”  
4. `CURSOR_IMPLEMENTER_QUICKSTART.md` still mentions 5317 and parked compose names.  
5. Config path ProgramData vs `C:\otel\config.yaml` tension.  
6. No prior measured clean-host wall clock — **this run creates the baseline.**

Do not expand scope into sibling maturity, CHAR disposition, or deploy-hub rename during the E2E run.

---

## Role

| Seat | Does |
|------|------|
| Machine operator | Docker/MSI/UI/admin; owns the stopwatch honesty |
| Cursor{Implementer} | Scripts, Examine capture, ECRR, timing artifact, docs fix PRs from findings |
| Oversight / OEM | Accept verdict; authorize README fixes |

---

## Exit

When the run completes: merge ECRR + timing artifact + BOSSCAT_LOG; open fix PRs for every AMBER/RED doc lie discovered. Only then is the stranger promise evidenced.

— Cursor{Implementer} → BossCat OEM
