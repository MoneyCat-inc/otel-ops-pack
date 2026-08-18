<!-- markdownlint-disable MD013 MD031 MD034 -->
# ECRR — Kiro pilot Examine (credit pool + abort threshold)

**Date:** 2026-07-26  
**Gate:** Gate #022 follow-on / Kiro seat audition  
**Briefing:** `docs/BossCat/BRIEFING_KIRO_PILOT_CLEAN_HOST_E2E_AUTOMATION.md` (merged #396 @ `d181fdb14`)  
**Seat line:** `AGENTS.md` provisional `Kiro{Implementer}` (merged #397 @ `7c5067769`)  
**Phase:** **Examine only** — Clean **blocked** until this artifact carries pool finding + pinned absolute threshold  
**Status:** Examine **COMPLETE** — Clean not started

---

## Examine refinements applied (OEM handoff 2026-07-26)

1. **Read-only on ops-pack disk** — no `.kiro/` created under `C:\otel`. D4 probe ran in throwaway scratch outside the repo; scratch deleted after measurement.  
2. **Absolute abort threshold** — not a floating “50% of remaining.”  
3. **`/usage` twice** — open baseline + close (prove Examine near-free).

---

## Examine (numbers)

### Identity

| Field | Value |
|-------|-------|
| `kiro-cli whoami` | Logged in with Builder ID — `fubumaki@gmail.com` |
| Plan | **KIRO PRO** |
| Reset | 2026-08-01 |

### SHA snapshots (ops-pack @ `7c5067769` = `origin/main`)

| Object | Blob / ref |
|--------|------------|
| HEAD | `7c5067769` |
| Briefing | `1f67ace79c9589e51abe2822f9407851f4c24a81` |
| `AGENTS.md` | `5b30c35d3cc0c4797219ce15daf57efa7d7e4e34` |
| `C:\otel\.kiro` present? | **No** (before and after Examine) |

### `/usage` open vs close

| Checkpoint | Credits consumed | Cap |
|------------|------------------|-----|
| **Examine open** | **0.69** | 1000 |
| After control chats (no hooks) | 0.69 | 1000 |
| After treatment chats (hooks) | 0.73 | 1000 |
| **Examine close** | **0.73** | 1000 |

**Examine burn:** `0.73 − 0.69 = **0.04**` credits.  
All of that burn landed during the D4 treatment series; `whoami` + repeated `/usage` reads showed **0.00** movement at 0.01 resolution → Examine identity/usage reads are **near-free**.

---

## D4 probe (scratch outside ops-pack)

**Location:** `C:\ISO\kiro-d4-probe\` (deleted after run; numbers retained in this ECRR + `C:\ISO\kiro-d4-probe-result.json`).

| Arm | Setup | n | Per-chat Δ (credits) | Mean Δ |
|-----|-------|---|----------------------|--------|
| **Control** | `.kiro/agents/d4-control.json` — no hooks; prompt “ok” | 3 | 0.00, 0.00, 0.00 | **0.00** |
| **Treatment** | `.kiro/agents/d4-treatment.json` — `agentSpawn` + `userPromptSubmit` `echo` hooks; same prompt | 3 | 0.00, **0.04**, 0.00 | **0.0133** |

### Pool finding

**Same Pro credit pool (conservative).** Matched control series: no movement. Treatment series (shell `echo` hooks on spawn/submit): counter advanced **+0.04** once (0.69 → 0.73). At 0.01 display resolution this is not a clean per-hook tariff, and delayed settlement cannot be ruled out — but the only measured burn in Examine occurred on the hooked arm.

**Implication for H1–H3:** budget hook-adjacent sessions against the **same** 1000-credit Pro pool as spec/agent work. Echo-class hooks did **not** show a large discrete surcharge; H1 (markdownlint subprocess) remains plausible under D4 if session count stays modest. **Projected hook burn (separate ECRR line item):** treat as **session-adjacent**, not free infrastructure — re-measure with a real H1 command during Clean bootstrap before declaring H1–H3 sustainable beyond the pilot.

---

## Pinned absolute abort threshold (D4)

| Symbol | Meaning | Value |
|--------|---------|-------|
| **X** | `/usage` at Examine open | **0.69** credits consumed |
| **Y** | Monthly Pro allowance | **1000** credits |
| **Abort at** | `X + 0.5Y` consumed | **500.69** credits consumed |

**One number Kiro checks mid-delivery:** if `/usage` shows consumed **≥ 500.69**, **hard stop** — report partial + verdict. No re-deriving “50% of month” during the run.

Pilot headroom from Examine open: **500.00** credits (to the abort line). Examine already used **0.04** of that headroom via the D4 probe.

---

## Actor / commit discipline (parked for Clean — recorded now)

- Feature-branch commits by Kiro carry `Actor: Kiro{Implementer}` **in the commit message**, not ECRR-only.  
- Cursor raises/reviews PRs from that branch via existing lanes.  
- H2 false positives on legitimate cross-lane commits: record in closing ECRR if fired.

---

## Clean

**Not started.** Gate condition: pool finding + pinned absolute threshold are now in this ECRR → Clean may be authorized by OEM/chat seat next.

---

## Report

| Artifact | Path |
|----------|------|
| This ECRR | `CHAR/ECRR/ECRR_REPORTS/ECRR_KIRO_PILOT_EXAMINE_20260726.md` |
| Probe raw JSON (machine-local) | `C:\ISO\kiro-d4-probe-result.json` |
| Examine close JSON (machine-local) | `C:\ISO\kiro-examine-close.json` |

---

## Role

- **OEM / chat seat:** authorized Examine with three refinements (scratch D4, absolute threshold, dual `/usage`).  
- **Cursor{Implementer}:** executed Examine protocol with `kiro-cli` as instrument; authored this ECRR; ops-pack disk unchanged (no `.kiro/`).  
- **Kiro{Implementer} (provisional):** idle for Clean until explicitly authorized; subject account measured = Builder ID `fubumaki@gmail.com` / KIRO PRO.

## ECRR Gate

- Gate: PASS
- Scope: Structural normalization only.
- Evidence Reference: artifacts/ecrr-compliance-metrics.json.
- Guardrail: Append-only; original report body unchanged.
