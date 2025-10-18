# Trends Playbook (SOCM Lane)

**Objective:** Use data to pick 2–4 high-yield tags per post. No auto-tagging.

## Inputs
- Local ledger: `artifacts/social/posted.jsonl`
- Trends metrics: `artifacts/social/trends.json`
- Proposals: `docs/social/TAGS.suggestions.yaml`

## Thresholds
- Local frequency ≥ 2 mentions in last 14 days
- Thematic fit: aligns with mission (Windows + OTel + evidence-first)

## Process
1) Run: `npm run social:trends`
2) Reviewer checks `TAGS.suggestions.yaml`
3) If approved, manually update `docs/social/TAGS.yaml`
4) Log decision (ECRR) and apply in next posts

