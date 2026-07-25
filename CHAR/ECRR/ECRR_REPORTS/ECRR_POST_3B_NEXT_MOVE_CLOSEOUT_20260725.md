# ECRR — Post–Pack 3B Next Move Closeout

**Timestamp:** 2026-07-25T15:40:00Z (initial) · **Addendum:** 2026-07-25T15:50:00Z (OEM-required rotate)  
**Gate / Site:** Post–Pack 3B / Unblock #1 + Prevent #5 (+ #6 PAT amber)  
**Actor:** Cursor{Implementer}  
**Machine operator:** `@fubumaki` (Cursor tab)  
**Authority:** Oversight board–approved plan (`post-3b_next_move_3b8e6b75`); OEM closeout acceptance + required rotate  
**Verdict:** **GREEN** — in-scope tracks complete; blast radius closed; least-privilege key in CI

---

## Examine

### Board scope (accepted)

| Track | Board item | Status |
|-------|------------|--------|
| Unblock | #1 Lumi `LUMI_API_KEY` on `MoneyCat-inc/viz-engine` | **DONE** (+ OEM rotate) |
| Prevent | #5 Evidence-repo retention (90d raw, quarterly prune) | **DONE** (prior ECRR) |
| Prevent | #6 FG PAT amber calendar (`EVIDENCE_REPO_TOKEN` → 2026-10-22) | **DONE** (shipped with #381) |

**Out of scope (follow-on queue, unchanged):** CHAR/docs 26 hash mismatches (D3) — **next**; CHAR / DELT / ALFA disposition; `deploy-moneycat` → `deploy-hub`; clean-host E2E — **matters most**; sibling maturity (socm / scorebot / viz-engine / moneycat-site).

### Pre-state (Phase A)

- `MoneyCat-inc/viz-engine` Actions secrets: **total_count = 0**
- `lumi-vizr-lane.yml` soft-skipped when `LUMI_API_KEY` unset (Pack 3B deferral)
- Actor routing corrected in root `AGENTS.md`: mint/Secrets UI = **machine operator**, not chat/review

### Pre-state (Phase B — already closed)

See `CHAR/ECRR/ECRR_REPORTS/ECRR_EVIDENCE_RETENTION_20260725.md` (PRs #381–#385). Live prune run [30162695304](https://github.com/MoneyCat-inc/otel-ops-pack/actions/runs/30162695304): **would-delete = deleted = 12532**.

---

## Clean

### Phase A — Lumi provision (initial)

1. Machine operator authenticated at OpenAI (Money Cat org, project **leto**).
2. Cursor{Implementer} created project API key name **`lumi-vizr`** (Owned by: You; Permissions: **All** — plan violation).
3. Secret set via `gh secret set LUMI_API_KEY --repo MoneyCat-inc/viz-engine` (value never written to BOSSCAT_LOG / this ECRR).
4. Dispatched `lumi-vizr-lane.yml` with `dryRun=true` → [30164008053](https://github.com/MoneyCat-inc/viz-engine/actions/runs/30164008053) non-skip SUCCESS.
5. Logged `[LUMI PROVISIONED]` (name only).

### Phase A′ — OEM-required rotate (blast radius + least privilege)

Standing rule (post FG-r2): **any credential whose value transited automation is rotated — no per-case deliberation.** Independently: Phase A plan required a *scoped* project key; **Permissions: All** on a CI secret is the same class of error as classic `repo`-scope PAT.

1. Revoked burned `lumi-vizr` (All) in OpenAI leto project.
2. Minted replacement name **`lumi-vizr`** — project **leto**; Permissions **Restricted**; **Model capabilities = Request** only (all other resource scopes None).
3. `gh secret set LUMI_API_KEY` on viz-engine (`updated_at` 2026-07-25T15:49:04Z).
4. Confirming dry-run [30164377792](https://github.com/MoneyCat-inc/viz-engine/actions/runs/30164377792) SUCCESS — secret present, Invoke Lumi Ticket 4 DryRun=true, **not SKIPPED**.
5. Logged `[LUMI ROTATED]` (name + permission shape only; no value).

### Phase B — Evidence retention (reference)

Merged: #381 (code), #382 (briefing), #383 (dry-run ECRR), #384 (actor seats + live prune ECRR), #385 (BOSSCAT_LOG). Age from filename / `git %ct` only — **never mtime**.

---

## Report

### Phase A / A′ verification

| Check | Result |
|-------|--------|
| Initial dry-run | [30164008053](https://github.com/MoneyCat-inc/viz-engine/actions/runs/30164008053) SUCCESS non-skip |
| Burned key | `lumi-vizr` (All) **revoked** |
| Replacement | `lumi-vizr` · leto · **Restricted** · Model capabilities **Request** only |
| Secret re-set | `LUMI_API_KEY` `updated_at` 2026-07-25T15:49:04Z |
| Confirm dry-run | [30164377792](https://github.com/MoneyCat-inc/viz-engine/actions/runs/30164377792) SUCCESS — `LUMI_API_KEY: ***`, Invoke Lumi ran |

### Phase B verification (summary)

| Check | Result |
|-------|--------|
| Dry-run | [30160387171](https://github.com/MoneyCat-inc/otel-ops-pack/actions/runs/30160387171) — would-delete 12532, all `date_source=filename` |
| Live prune | [30162695304](https://github.com/MoneyCat-inc/otel-ops-pack/actions/runs/30162695304) — deleted 12532 (= would-delete) |
| Boundary | Newest delete `archived/2025/10/...`; oldest keep `archived/2026/06/run-27413707649.md` |
| PAT amber | Workflow armed; `EXPIRES_ON=2026-10-22` |

### Phase B boundary note (record only — no action)

Newest-delete `2025/10` and oldest-keep `2026/06` leave a seasonal gap around the actual 90-day line (~2026-04-26). Boundary is **consistent** but was not tightly exercised with data on both sides of the cut. First scheduled quarterly prune in **October** is the first real line test; FG PAT amber watches the same week.

### Exit criteria

| Criterion | Met |
|-----------|-----|
| viz-engine secret present | Yes |
| Non-skip dry-run (initial + post-rotate) | Yes (30164008053, 30164377792) |
| Automation-transit rotate + least privilege | Yes (OEM required) |
| BOSSCAT_LOG provision + rotate + GREEN | Yes (this docs PR) |
| Retention would-delete = deleted | Yes (prior) |

---

## Role

| Seat | Action |
|------|--------|
| **Cursor{Implementer}** | Mint/revoke UI after operator login; `gh secret set`; dry-runs; ECRR + BOSSCAT_LOG + AGENTS standing rules |
| **Machine operator** (`@fubumaki`) | OpenAI session / org access at Cursor tab |
| **Chat / review** | Board + OEM acceptance; no mint ownership |
| **BossCat OEM** | GREEN accepted; required rotate; docs PR as audit trail |

---

## ECRR Gate

- **Gate:** PASS / **GREEN** (stands; blast radius closed)
- **Scope:** Post–Pack 3B next move (Lumi unblock + evidence retention + FG PAT amber) + OEM rotate
- **Closeout:** Delivery complete when this ECRR + log lines merge; board reverts to follow-on queue (CHAR review first; clean-host E2E highest leverage)
- **Evidence pointers:**
  - Lumi dry-runs: [30164008053](https://github.com/MoneyCat-inc/viz-engine/actions/runs/30164008053) (initial), [30164377792](https://github.com/MoneyCat-inc/viz-engine/actions/runs/30164377792) (post-rotate)
  - Retention ECRR: `CHAR/ECRR/ECRR_REPORTS/ECRR_EVIDENCE_RETENTION_20260725.md`
  - Actor seats + credential standing rules: root `AGENTS.md`
  - Log: `docs/BossCat/BOSSCAT_LOG.md` → `[LUMI PROVISIONED]` / `[LUMI ROTATED]` / `[POST-3B NEXT MOVE GREEN]`

— Cursor{Implementer} → BossCat OEM
