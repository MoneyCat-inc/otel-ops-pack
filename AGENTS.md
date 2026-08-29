# AGENTS - Repository Index (Canonical Entry Point)

This file is the canonical index for all AGENTS guidance in this repo.
Other AGENTS.md files are scoped; do not treat them as repo-wide rules unless noted.

## Canonical Governance (BossCat)
- BossCat Charter (canonical): docs/BossCat/CHARTER.md
- Workflow standards (CI/GitHub Actions patterns): docs/AGENTS.md
- ECRR reports (canonical audit trail): CHAR/ECRR/ECRR_REPORTS/ (410+ reports; hardcoded counts here went stale — count the directory instead)

## Actor seats (credential / browser steps)

Four seats (OEM D2, 2026-07-26) — do not route human mint/login work to the wrong one. The Kiro provisional tag **resolved to permanent on 2026-08-14**: all three criteria frozen before the report was read (`docs/BossCat/KIRO_VERDICT_CRITERIA_20260813.md`) passed on independent scoring, recorded in `CHAR/ECRR/ECRR_REPORTS/ECRR_KIRO_PILOT_20260814.md`.

| Seat | Who | Does | Does **not** |
|------|-----|------|----------------|
| **Chat / review** | Oversight in chat (e.g. Claude review) | Decisions, plan approval, review | Browser, passwords, API-key mint, GitHub Secrets UI |
| **Cursor{Implementer}** | Agent in Cursor | Code, CI, ECRR, `gh` with existing auth, drive the loop; ops/PR mechanics | Invent secrets; mint OpenAI keys without the machine operator; nest under/over Kiro for pilot impl |
| **Kiro{Implementer}** (permanent, 2026-08-14) | Kiro CLI peer seat | Spec-shaped feature work; log `Actor: Kiro{Implementer}` per commit | Nest with Cursor{Implementer}; mint/auth; open a second (AWS) evidence plane; self-merge |
| **Machine operator: `@fubumaki` (human — the only seat with hands)** | The person at the keyboard — not a process, not chat, not an agent | OpenAI mint, GitHub Secrets paste, sudo/browser confirmations; Kiro login; **launching `kiro-cli` sessions**; any keystroke on a password/mint/Secrets page | Being asked via the chat seat as if chat can type keys; being treated as a fourth remote party to “brief” |

**Standing rule (routing):** Any step that needs a keyboard — password page, mint button, Secrets UI, or **starting an interactive agent session** — is **machine-operator only**. That seat is `@fubumaki`, the only human in the system. Cursor may open a visible terminal window to the right cwd, but the operator owns the session. Chat never “owns” the mint or the launch. Saying “blocked on Fae/chat” for `LUMI_API_KEY` (or for `kiro-cli chat`) is a routing bug — the handoff is: machine operator acts → tells Cursor → Cursor verifies and logs.

**Standing rule (implementer seats):** Cursor and Kiro are **peers**, not a nested chain. No Cursor→Kiro→model telephone game for pilot implementation. Scoped credentials only; machine operator handles auth; actor logged per commit.

**Standing rule (blast radius, post FG-r2):** Any credential whose value transited automation (browser a11y snapshots, agent logs, chat tooling) is **rotated — no per-case deliberation**. CI-bound keys are minted **least privilege** (scoped / Restricted to the job), never “Permissions: All” / classic `repo`-wide PAT class.

## Generated Registries (Do Not Edit)
- Auto-Bots registry (generated): docs/BossCat/AGENTS.md
  - Generated file (the `pnpm agent:setup` script this line once named no longer exists in package.json — audit P3, 2026-08-29)
  - Mirror copy: CHAR/DOCS/docs/BossCat/AGENTS.md

## Component-Scoped Rules
- Resonai subtree playbook (scope: third_party/resonai only): third_party/resonai/AGENTS.md

## Published/Mirror Trees
- Static docs mirror (read-only output): CHAR/DOCS/
  - Source of truth lives under docs/
  - See CHAR/DOCS/README.md

## Recurring maintenance

Social/monetization upkeep (Patreon, Ko-fi, Bluesky) belongs to the split-out **socm** repo
(Pack 3B, 2026-07-24) and is out of scope here per `docs/PURPOSE.md` and Roadmap 2026 H2
Phase 2. The weekly reminder scripts and `Resonai-*-Weekly-Maintenance` scheduled tasks that
remain on the host are legacy (exiting rc=2 since 2026-08); their disposition is operator
work tracked in `CHAR/ECRR/ECRR_REPORTS/ECRR_SCHEDULED_TASK_SECOND_WAVE_20260813.md`.

This repo's own cadence (quarterly upgrade check, monthly evidence rollup, per-change ECRR,
clean-host gate) is defined in `docs/PURPOSE.md`.

## Archives
- Archived historical copy (not canonical): docs/BossCat/misc/AGENTS.md
