# Phase 3 — Learning & Autonomy (Quickstart)

Scope

- Signature registry: known issues → owners + playbooks + confidence.
- Auto‑rerun guard: respects policy and dominant class (flakes only by default).
- Weekly rollups and governance reports.

Files

- `ALFA/APPS/signature-registry.json` — seed entries with `sig_id`, `owner`, `playbook_url`, `confidence`.
- `config/policy/ecrr-policy.json` — rerun policy and default owners per component.
- `scripts/auto-rerun-guard.ps1` — decide rerun eligibility based on labels.json + policy.

Usage

- After classification:
  - `pwsh -File scripts/auto-rerun-guard.ps1 -RunDir artifacts/ecrr/.../run=<id>`
- Extend registry: update entries and re‑run classifier to annotate labels with owners/playbooks.

Next

- Add CI policy gate to rerun on flakes exactly once.
- Promote registry to service, add confidence learning updates.
- Generate weekly governance report with policy adherence.
