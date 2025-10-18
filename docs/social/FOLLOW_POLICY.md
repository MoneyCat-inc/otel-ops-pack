# Follow Policy (SOCM Lane)

**Goal:** Grow a high-signal network for Windows + OpenTelemetry + observability.

## Acceptance Rules
- Content relevance: ≥80% posts overlap with `TAGS.yaml` approved topics.
- Activity: ≥1 post in last 30 days; not a link-only account.
- Safety: No harassment, politics, or misinformation patterns.
- Diversity: Prefer variety across roles (eng, SRE, docs, OSS maintainers).

## Process
1) Run `npm run social:recommend-follows` → review JSONL.
2) Human reviewer approves **at most 5/week**.
3) Agent A applies follows (manual or existing follow script).
4) Log decision & rationale in `.agent/EVIDENCE.log`.

