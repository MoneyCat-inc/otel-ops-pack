# Reviewer B (codex‑cloud) — Read‑Only Playbook

Authority: BossCat OEM  
Scope: Reviewer B (read‑only) gate reviews for docs and code

---

## Role & Posture

- B is strictly read‑only. No pushes, rebases, merges, or file writes.  
- Operate in pairs: A (writer) + B (reviewer). “Two make the strike.”
- Respect kill‑switch: if `.agent/LOCK` exists → BLACK (abort review).

## Budgets & Lane

- Hard budgets per PR: ≤ 2 jobs, ≤ 10 files, ≤ 200 LOC touched.  
- Verify budgets via CI summary or `git diff` against base SHA.  
- Lane discipline: review only changed paths. For docs‑only PRs, run docs lane checks.

## Evidence (ECRR) Bundle

- `.agent/PLAN.md` (≤150 words): goal, scope, files, tests.  
- `.agent/EVIDENCE.log` (JSONL excerpt) covering: `preflight | lock | edit | test | exit`.  
- `.agent/JOB.lock` heartbeat present and advancing during A’s work.

## Gate Protocol

- Color states: GREEN / AMBER / RED / BLACK.  
- Standard signal: post `@cat ready-for-gate` when GREEN.  
- B status (paste‑ready):

```
IONA/BALANCER STATUS
Lane: DOCS  TTL: n/a  Budget: <files>/<loc>
State: GREEN | AMBER | RED | BLACK
Last event: <ISO8601> report "docs checks <passed/failed>; evidence <ok/missing>"
Action: continue | hold | ECRR
```

## Docs Lane — Changed‑Paths Checks (Rule #7)

Run and confirm:

- Budgets within limits (≤10 files, ≤200 LOC).  
- Markdown lint (markdownlint) passes for changed `.md` files.  
- Link + anchor check (lychee) passes for docs and READMEs.  
- ECRR evidence artifact uploaded by CI for B to review.

Reference CI: `.github/workflows/docs-lane-checks.yml` (budgets, lint, links, evidence).

## Reviewer B Procedure

1) Confirm `.agent/LOCK` absent; if present → BLACK.  
2) Verify budgets via CI summary or `git diff` vs base (`files <=10`, `loc <=200`, `jobs <=2`).  
3) Review ECRR bundle (`.agent/PLAN.md`, `.agent/EVIDENCE.log`, JOB heartbeat). Missing → RED.  
4) Confirm docs lane checks passed. Missing or failing → AMBER (hold).  
5) Render verdict; if GREEN, post `@cat ready-for-gate`.

## READY‑FOR‑GATE (Docs)

All must be true:

- Budgets within limits.  
- Evidence present (PLAN, EVIDENCE.log excerpt, JOB heartbeat).  
- Docs changed‑paths checks passed (lint + links).  
- No policy breaches (B read‑only; A didn’t merge).  
- B posts GREEN verdict with gate signal.

