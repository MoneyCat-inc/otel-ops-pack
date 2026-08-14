<!-- GENERATED FILE — do not hand-edit. Source: /AGENTS.md. Regen: pwsh -File BRAV/SCPT/kiro/regen-steering.ps1 -->
# BossCat governance (steering projection)

SOURCE: `/AGENTS.md` (canonical). Generated: 2026-07-26T17:23:13Z

## Actor seats (credential / browser steps)

Four seats during the Kiro pilot (OEM D2, 2026-07-26) — do not route human mint/login work to the wrong one. Provisional tag resolves only at the pilot ECRR (`docs/BossCat/BRIEFING_KIRO_PILOT_CLEAN_HOST_E2E_AUTOMATION.md`).

| Seat | Who | Does | Does **not** |
|------|-----|------|----------------|
| **Chat / review** | Oversight in chat (e.g. Claude review) | Decisions, plan approval, review | Browser, passwords, API-key mint, GitHub Secrets UI |
| **Cursor{Implementer}** | Agent in Cursor | Code, CI, ECRR, `gh` with existing auth, drive the loop; ops/PR mechanics | Invent secrets; mint OpenAI keys without the machine operator; nest under/over Kiro for pilot impl |
| **Kiro{Implementer} (provisional — pilot-scoped)** | Kiro CLI peer seat | Spec-shaped feature work for the approved pilot delivery; log `Actor: Kiro{Implementer}` per commit | Nest with Cursor{Implementer}; mint/auth; open a second (AWS) evidence plane; work before the pilot briefing merges |
| **Machine operator** | Human at the Cursor/IDE tab (`@fubumaki`) | OpenAI mint, GitHub Secrets paste, sudo/browser confirmations; Kiro login if needed | Being asked via the chat seat as if chat can type keys |

**Standing rule (routing):** Any step that needs a keyboard on a password page, mint button, or Secrets UI is **machine-operator only**. Cursor briefs that seat and verifies after; chat never “owns” the mint. Saying “blocked on Fae/chat” for `LUMI_API_KEY` is a routing bug — the handoff is: machine operator mints → tells Cursor → Cursor dry-runs and logs.

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
