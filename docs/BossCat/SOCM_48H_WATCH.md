# SOCM 48-Hour Watch — Bluesky Launch

## Objectives (T+0 → T+48h)

- Maintain post health, thread Day-1 replies, and approve social suggestions (≤5 follows/week).
- Keep widget current and XSS-safe; re-export if ledger updates.
- Log all actions (copy/paste templates below).

## Checklist

### T+0–2h (Now)

- [ ] Pin launch post; add Replies #1–2 (thread pack Day-1).
- [ ] Follow 3–5 curated accounts (value-add replies).
- [ ] Widget smoke test (open portal/transparency page).

### T+2–24h

- [ ] `npm run social:export` — refresh widget JSON
- [ ] Respond to questions (FAQ macros)
- [ ] Optional chaos drill in **Data Room** (Laminar→Chaos; validate recovery)

### T+24–48h

- [ ] Day-2 post at 16:00 UTC; thread 4 replies
- [ ] `npm run social:trends` — review tag proposals
- [ ] 5-line summary to evidence log (template below)

## Evidence Snippets (copy/paste)

- Action: "Pinned & threaded replies 1–2" — ISO timestamp — link
- Action: "Followed N accounts (list)" — rationale — links
- Widget: "Exported JSON (5 entries)" — file path — hash
- Trends: "Top tags (14d): …" — decision: accept/hold — rationale

## Triggers → Responses

- **Red**: Posting failures or policy breach → create `.agent/LOCK` (pause), open incident ECRR, rollback last step.
- **Yellow**: Widget fetch slow/fails → rely on ledger fallback; verify timeout & abort; re-run export.
- **Green**: Normal ops → proceed per schedule, keep evidence rolling.

## References

- A/B split, kill-switch, budgets, lock/retry: **AUTO-BOTS Stability Pack**, **AUTO-BOTS Registry**.
- Background agents & oversight cadence (if you choose to schedule internal monitors): **Background Agent Delegation Protocol**.
- Chaos drills & canary flows: **Data Room Test Harness**.
- ICF convergence framing (learn-and-improve loop on evidence): **ICF Integration Roadmap**.

