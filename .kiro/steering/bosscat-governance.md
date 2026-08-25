<!-- GENERATED FILE — do not hand-edit. Source: /AGENTS.md. Regen: pwsh -File BRAV/SCPT/kiro/regen-steering.ps1 -->
# BossCat governance (steering projection)

SOURCE: `/AGENTS.md` (canonical). Generated: 2026-08-25T12:55:01Z

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

## Standing rules (projection)

- Credential/mint/login steps are **machine-operator only**
- Credentials that transit automation are **rotated — no deliberation**
- CI keys: least privilege / scoped — never classic repo-wide PAT class
- Governance trail is **GitHub-native** (Actions, PR evidence, BOSSCAT_LOG, ECRR)
- Do **not** open a second evidence plane on AWS
- Cursor and Kiro are **peers**, not a nested chain
- Briefings are canonical; Kiro specs are **projections** (header: `projection — not canonical`)
- Lane discipline: `docs_gate` owns `docs/**` + `README.md`; split code/docs/evidence when mixed scope would fail GR-02

## Pilot abort (Examine ECRR 2026-07-26)

- KIRO PRO · Y=1000 · reset 2026-08-01
- Examine open X=0.69 consumed
- **Hard abort at consumed >= 500.69**
- D4: same Pro pool for hooks (conservative); H1–H3 session-adjacent
