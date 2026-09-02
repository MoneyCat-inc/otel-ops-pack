# ECRR — Docs Truth Sweep (live docs vs canonical configs, CHARTER and workflow set)

**Date:** 2026-09-02
**Actor:** Claude (chat/review), execution under standing delegation from `@fubumaki`
("go" / "you may" — merge each batch on green)
**Verdict:** **GREEN** — 15 docs-lane PRs + this close-out merged, every touched file lint-clean
and link-clean on the CI pins; no code, config or workflow changed

## 1. Examine

Scope: the 277 live markdown docs (`docs/**` + `README.md`, excluding `docs/archive/**`,
`docs/gate/archive/**`, the `CHAR/DOCS` mirror and ECRR reports). Method: a dead-reference scan
(`deadref_scan.py`, backtick paths + relative links + cited workflow names checked on disk) plus
seven parallel read-audits, each file judged against the canonical sources — root `config.yaml`,
`docker-compose.yml`, `DELT/CONF/otel-ports.json`, `scripts/windows/collector-version.txt`,
`.github/workflows/*` headers (KEEP / RETIRED 2026-08-03), `docs/status/workflows.json`,
`docs/BossCat/CHARTER.md`, `docs/PURPOSE.md`, `.github/dependabot.yml`.

Findings that mattered (full per-file verdicts are in the PR bodies):

- **Five P0s.** `SIGNOZ_BEST_PRACTICES.md` told the Windows collector to export to its own HTTP
  receiver (`localhost:5321`, a self-loop) and reinstated a `max_elapsed_time: 300s` retry cap — the
  cap class that lost ~7.4k log records on 2026-08-18. `IMMUTABLE_PERSONA_v1.1.md` granted agent
  self-merge; `SECURITY_MAINTENANCE_MASTER_GUIDE.md` routed merges and credential rotation to a
  "security team" — both contradict the CHARTER (operator-only). `RUNBOOK_CHUNK_1_EXECUTION.md` is a
  destructive one-shot run-deletion runbook that read as live. `PERFORMANCE_GATE_SPEC.md` still
  carried the banned 77× claim (the guard's glob `docs/*.md` is non-recursive).
- **A live agent prompt with wrong ports** (`docs/notes/misc/.cursor-prompt.md`: 14317/14318,
  5317/5318, a GPU pipeline that does not exist).
- **Phantom automation cited as ACTIVE:** `status-auto-update.yml` (deleted in `31423808`),
  `nightly-dashboard-export.yml` (never shipped, cited 16×), `rsi-sweep-nightly.yml`,
  `lumi-vizr-lane.yml`, hub-smoke / link-check / update-kpis (RETIRED 2026-08-03) described as
  running on schedule.
- **Stale advertised surfaces:** `REFERENCES_MAP.md` (v1.2: registries "pending", 2025 domain counts,
  a non-existent `docs/evidence/`), `status/misc/STATUS.md`, `status/README.md` (registry total 76 vs
  61), `docs/README.md` and `docs/BossCat/README.md`.
- **Legacy port scheme** (14317/14318, 5317/5318, 13133, UI 3301) across runbooks, cheatsheets,
  comfort-cat and BossCat guides; **retired roster** (IONA, Investigator/Gap-Closer/QA Scribe,
  Reviewer B/codex, 48 agents, Tetragram) presented as current in ROLES.md and a dozen guides.
- **Extracted lanes** (Pack 3B, 2026-07-24: `moneycat-site`, `socm`, `viz-engine`) still documented
  here as if in scope.

## 2. Clean

Rules applied throughout: fix live guidance in place; banner dated records after the H1 and leave
bodies as the record (precedent #468); scoped `markdownlint-disable` headers for frozen files with
2025 formatting debt; every touched file must pass the CI pins on the **whole** file
(`markdownlint-cli2@0.14.0`, `lychee 0.20.1` with `.lychee.toml`) — lesson from #705, where 30
pre-existing links failed GR-04; move only what nothing live points at, and fix inbound references
in the same PR.

| PR | Batch | Files / LOC | Lane note |
| --- | --- | --- | --- |
| #704 | 1 — CURRENT_ARCHITECTURE rewrite, WINDOWS_COLLECTOR_DEPRECATION rescinded, docs/README, BossCat/README | 4 / >200 | lane:cleanup |
| #705 | 2 — HISTORICAL banners (ARCHITECTURE_MAP, GOVERNANCE_VIEW, QUICK_START_CARD, CURSOR_IMPLEMENTER_*), ecrr/INDEX relinks, AGENTS.md truth pass, status/README | 9 | — |
| #706 | 4 — runbooks (windows-collector ports/memory/batch/pin, clean-host-e2e, signoz-*-proofs, misc banners) | 9 / 170 | — |
| #707 | 5 — cheatsheets (gate runner, watchdog 13134, cursor-implementer, archiver) + ADOT UNBUILT | 7 / 144 | — |
| #708 | 6 — comfort-cat (ROLES rewritten to the four seats, framework, gate protocol, aesthetic port) | 6 / 239 | lane:cleanup |
| #709 | 7 — docs/ecrr (flow direction, 4317 clarifier, template, two banners) | 5 / 66 | — |
| #710 | 8 — status surfaces (REFERENCES_MAP v1.3, STATUS snapshot notice, registry counts, README count) | 4 / 86 | — |
| #711 | 9 — phantom status-auto-update docs, JSON_SCHEMA_VALIDATION, MONITORING_SCHEDULE, IONA_ERRORS, portal | 7 / 77 | — |
| #712 | 10 — top-level HISTORICAL/record banners incl. DRIVE_CLEANUP do-not-run | 10 / 66 | — |
| #713 | 11a — .cursor-prompt ports/paths, QUICKSTART, RSI, PORT_8889, snapshots, personas + split-lane banners | 13 / 132 | lane:cleanup |
| #714 | 12a — BossCat P0 set + BOSSCAT_LOG entry | 7 / 128 | — |
| #715 | 12b — BossCat A–M fixes (gate criteria, Dependabot, credentials, App consumers) | 9 / 99 | — |
| #716 | 12c — BossCat HISTORICAL / split-lane banners | 9 / 35 | — |
| #717 | 12d — BossCat N–Z fixes and banners | 12 / 69 | lane:cleanup |
| #718 | 11b — archive moves (gate/self-signal, gate/misc, BossCat/schema, pr/misc, 8 BossCat/misc records, 3 notes/misc rolling files) + notes/misc directory notice + GATE_009_PREREAD path note | 47 (45 renames) | lane:cleanup |
| #719 | 3 — CHANGELOG.md frozen-at-1.0.0 banner + this ECRR (close-out) | 2 | outside docs lane |

Not done, deliberately (operator decisions, listed for the record):

- `docs/vr/` (SlimeVR notes, 3 files) — unrelated to the pack; needs a home decision.
- `docs/BossCat/Research/markdown` — three byte-identical `-best` / `-from-docx` pairs; left because
  `research-conversion-verify.yml` consumes the directory.
- `docs/BossCat/misc/BOSSCAT_LOG.md` (211 lines, last touched 2026-08-28) is a stale copy of
  `docs/BossCat/BOSSCAT_LOG.md` (427 lines); `GATE_STATUS_DASHBOARD.md` still links the copy.
- `docs/GATE_STATUS_DASHBOARD.md` L1003 links an approval already in `docs/archive/` — frozen file
  with a disable header, left alone.

## 3. Report

Dead-reference scan, same script on both commits (live docs only):

| | pre-sweep (`e91fbad`) | post-sweep (after #718) |
| --- | --- | --- |
| live docs scanned | 277 | 233 (45 records archived) |
| docs with ≥1 dead reference | 114 | 88 |
| total dead references | 338 | 225 (−33%) |

Residual dead references are concentrated in bannered historical records, where the body is kept
verbatim by design; the live surfaces (`docs/README.md`, `REFERENCES_MAP.md`, runbooks, cheatsheets,
comfort-cat, `.cursor-prompt.md`, CHARTER-adjacent guides) are clean.

Code-lane follow-ups surfaced, **not** fixed in docs PRs:

1. `DELT/CONF/config/otelcol-windows.yaml` still carries `localhost:14317/14318` exporter endpoints
   (legacy config that can mislead an operator).
2. `scripts/guard-inflated-metrics.ps1` production glob is `docs/*.md` (non-recursive) — it never
   reached `docs/BossCat/` where the 77× claim survived.
3. `scripts/auto-rerun-guard.ps1` default policy path is `config/policy/ecrr-policy.json`; the file is
   at `DELT/CONF/policy/ecrr-policy.json`.
4. `signoz-collector-config.yaml` still upserts `service.name = resonai-backend` (the
   OPTIONAL_ENHANCEMENT doc remains unapplied — decision, not a bug).
5. `docs/status/*.json` static fields and the `docs/BossCat/AGENTS.md` generator (`pnpm agent:setup`,
   gone) — registry hygiene.
6. `docs/BossCat/misc/BOSSCAT_LOG.md` duplicate (above).

## 4. Role

Claude (chat/review) audited, drafted and verified every batch locally on the CI pins, opened the PRs
and — under the operator's explicit standing authorization for this sweep — squash-merged each on
green. No credentials, no elevation, no code or workflow changes. Cursor{Implementer} next step:
republish the `CHAR/DOCS` mirror (`BRAV/SCPT/publish-docs-mirror.ps1`, tree-level, manual by design)
and verify local `main` at the final squash SHA (handoff brief accompanies this ECRR).

**Status:** COMPLETE — measurement checkpoint: re-run `deadref_scan` at the 2026-10-01 rollup
alongside the CI demand-shaping ECRRs; expect the live-surface count to hold near zero and the
residual to sit in bannered records only.
