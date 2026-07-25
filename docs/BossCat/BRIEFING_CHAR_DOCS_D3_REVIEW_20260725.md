# BRIEFING — CHAR/docs D3 hash review (2026-07-25)

**Seat:** Cursor{Implementer} (15-min parked review, Unblock #2)  
**Authority:** Pack 2 D3 — pure mirror → delete; diverged → STOP, list paths  
**Board question:** Is anything in live `docs/` *stale* relative to CHAR’s copy?  
**Artifact:** `artifacts/char-docs-hash-compare-20260725.json`

---

## Verdict

| Decision | Status |
|----------|--------|
| **D3** | **DIVERGED** — confirmed. **Do not delete** `CHAR/DOCS/`. |
| Live `docs/` stale vs CHAR? | **No** for 26/27 overlapping mismatches (`docs/` is git-newer). |
| Exception | `docs/status.html` — CHAR is git-newer and larger; one-file follow-up under CHAR disposition, not an emergency restore. |
| Unblock #2 | **CLOSED** (reviewed). Feeds Decide #3 (CHAR disposition). |

---

## Examine (numbers)

| Metric | Count |
|--------|------:|
| `CHAR/DOCS/docs/` files | 1211 |
| `docs/` files | 779 |
| Path overlap (both) | 60 |
| SHA256 identical | 33 |
| SHA256 **mismatch** | **27** (parked figure was 26; +1 = today’s `BOSSCAT_LOG` churn) |
| CHAR-only | 1151 |
| docs-only | 719 |

Age for “who wins” uses `git log -1 --format=%ct` (not filesystem mtime).

Almost every CHAR overlap path shares one bulk commit time (`ct≈1759994317` / ~2025-10-16) — a frozen snapshot, not an ongoing publish sync. `CHAR/DOCS/README.md` still claims “publish mirror of /docs”; the tree shape falsifies that.

---

## Mismatch list (27)

`git_newer=docs` (26):

1. `BossCat/BOSSCAT_LOG.md`
2. `BossCat/DEPENDABOT_SECURITY_GUIDE.md`
3. `BossCat/ENTERPRISE_READINESS_CHECKLIST.md`
4. `BossCat/EXECUTIVE_SUMMARY.md`
5. `BossCat/README.md`
6. `BossCat/SECURITY_MAINTENANCE_MASTER_GUIDE.md`
7. `BossCat/STAKEHOLDER_EVIDENCE_PACKAGE.md`
8. `BossCat/TODO.md`
9. `cheatsheets/README.md`
10. `comfort-cat/README.md`
11. `dashboards/live-metrics.html`
12. `index.html`
13. `IONA_ERRORS.md`
14. `observability/snapshots/.gitkeep`
15. `observability/snapshots/nightly-workspace-api-otel-metrics/task-result.json`
16. `observability/snapshots/nightly-workspace-api-signoz-health/task-result.json`
17. `observability/snapshots/nightly-workspace-batch-01/task-result.json`
18. `observability/snapshots/nightly-workspace-export-compliance-trends-24h/task-result.json`
19. `observability/snapshots/nightly-workspace-export-error-analysis-24h/task-result.json`
20. `observability/snapshots/nightly-workspace-export-performance-metrics-24h/task-result.json`
21. `observability/snapshots/nightly-workspace-export-pipeline-health-24h/task-result.json`
22. `observability/snapshots/nightly-workspace-monitor-otel-collector/task-result.json`
23. `observability/snapshots/nightly-workspace-monitor-signoz-ui/task-result.json`
24. `README.md`
25. `status/kpis.json`
26. `status/tests.json`

`git_newer=CHAR` (1):

27. `status.html` — docs 11 227 B (`42393c28`, hub 4-panel redesign) vs CHAR 40 530 B (`0805f677`, later). Diffstat ~+882/−377. **Decision deferred to CHAR disposition:** restore into live hub, keep as archival only, or discard CHAR variant after hub owners confirm.

---

## Clean (actions taken / not taken)

- **Taken:** Hash compare + git-%ct winners; JSON artifact; this briefing; BOSSCAT_LOG line.
- **Not taken:** No deletes, no content merges, no “republish” from CHAR → docs (would regress live docs on 26 paths).

---

## Role / next

| Item | Owner |
|------|--------|
| Close Unblock #2 | Done this review |
| Decide #3 CHAR disposition | Board — evidence: not a mirror; 1 151 CHAR-only; treat as frozen archive / eventual lane or explicit “stays, here’s why” |
| Optional one-file: `status.html` | Hub / CHAR disposition — not blocking |

— Cursor{Implementer} → BossCat OEM / oversight
