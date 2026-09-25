<!-- markdownlint-disable MD013 MD034 -->
# BRIEFING — Kiro{Implementer}: Amazon Bedrock alignment (Shape E + A′)

**Authority:** OEM seat — operator decision 2026-09-25 ("accepted") on the research memo and its v1.1 addendum  
**Owner (brief):** Claude (chat/review seat)  
**Owner (implementer):** Kiro{Implementer} — code lane and Kiro tooling; peer of the Claude Code local seat, no nesting  
**Owner (CI-ops, ECRR):** Claude Code (local seat)  
**Owner (AWS reads, SSO, model access, `kiro-cli` launch):** Machine operator `@fubumaki`  
**Status:** **OEM-APPROVED 2026-09-25 — awaiting docs-lane merge; Kiro idle until then**  
**Sources:** research options memo "aligning Kiro{Implementer} to Amazon Bedrock" (2026-09-25) + v1.1 addendum, and the
chat-seat review of both; the operator holds all three. This briefing is canonical; the memo is the costing record.

---

## Decisions (locked 2026-09-25)

| ID | Decision | Binding detail |
|----|----------|----------------|
| **D1** | **Shape: E + A′** | Re-spec the seat; repair the one Bedrock invoke path the repo has; one model pin; one OTel span into the pack's own SigNoz. Shapes B (AgentCore hosting), C (Bedrock PR reviewer) and D (telemetry export to AWS) rejected: each conflicts with `docs/PURPOSE.md` or the Kiro standing rule. |
| **D2** | **No AWS resources, nothing recurring** | Bedrock is pay-per-call under the operator's short-lived credentials. No IAM role for CI, no S3, no AgentCore, no schedule. Kill switch: detach the policy from the SSO permission set. |
| **D3** | **Client path: Converse on `bedrock-runtime`** | `@aws-sdk/client-bedrock-runtime` (already a dependency), `ConverseCommand`. The Anthropic SDK's Mantle endpoint is the vendor-documented path for new code and may be revisited; it changes the pin and the IAM action and adds a dependency, nothing else. |
| **D4** | **One pin: `DELT/CONF/bedrock.json`** | `{ "endpoint": "bedrock-runtime", "region": "eu-west-2", "modelId": "eu.anthropic.claude-sonnet-5" }`. One reader in TypeScript, one in PowerShell; `BEDROCK_MODEL_ID` / `AWS_REGION` are env overrides only. No other file repeats the model string. |
| **D5** | **Plain script, not MCP** | Kiro runs the script through `shell`, which stays un-pre-approved, so every call is operator-approved. No `mcpServers` entry unless a stdio wrapper is written and approved separately. |
| **D6** | **Launches stay operator-only** | Kiro headless mode exists but needs a long-lived Kiro API key; not adopted. The `AGENTS.md` routing rule is unchanged. |
| **D7** | **No rule change** | The Kiro standing rule (no governance plane, no AWS-side CI/CD, no second evidence plane) is unaffected. AWS's own CloudTrail/CloudWatch entries from a call are AWS's audit log, read by no seat; they are not a pack evidence plane. |

---

## Standing rules (this delivery)

| Use Kiro for | Do **not** |
|--------------|------------|
| Code-lane edits to the files in scope below | `.github/workflows/**`, `CHAR/ECRR/**`, `docs/BossCat/BOSSCAT_LOG.md` (governance plane) |
| `.kiro/agents/bosscat.json`, `.kiro/specs/**`, steering regen | Mint, read or print a credential; touch `~/.aws/**`; store a key in any config |
| Spec **projected from** this briefing | A second canonical spec beside this briefing |
| Log `Actor: Kiro{Implementer}` per commit | Merge its own work; open an AWS resource |

**Fail closed:** any Kiro `requirements.md` / `design.md` / `tasks.md` header cites this file's path + SHA and states
`projection — not canonical`. The credit abort line in `bosscat.json` stays.

---

## Why this item

The repo ships five scripts pinned to `anthropic.claude-3-5-sonnet-20241022-v2:0` (or Claude 3 Haiku), models AWS
has retired or is retiring in the US Regions; `docs/status/scripts.json` lists two of them as live. That is a
truthfulness defect under `docs/PURPOSE.md`, and the seat that should repair it has had no spec since the pilot closed
on 2026-08-14. The Cursor-era Bedrock guides lost their tool on 2026-09-24 and are bannered HISTORICAL (#833).

---

## Scope

| # | Item | Seat | Lane |
|---|------|------|------|
| S1 | Migrate `scripts/demo/explain-trace.ts` to Converse, reading the pin file; add `--input <path>` for an artefact that exists as a file (else the span is the artefact); no `temperature`/`top_p`/`top_k` (Sonnet 5 rejects non-default values) | Kiro | code |
| S2 | Emit one OTel span per call (`gen_ai.request.model`, token usage) to the pack's collector (OTLP 5320/5321 → SigNoz) using the `@opentelemetry/*` packages already in `package.json` | Kiro | code |
| S3 | Migrate `BRAV/SCPT/test-bedrock-connection.ps1` to read the pin file and use `aws bedrock-runtime converse`; three states `GREEN` / `RED` / `NOT_RUN` (credential chain resolves nothing → `NOT_RUN`, own exit code, caught before any call) | Kiro | code |
| S4 | Retire `scripts/bedrock-coauthor.ts`, `scripts/test-bedrock-direct.ts`, `scripts/test-bedrock-connection.ts`; regenerate `docs/status/scripts.json` | Kiro | code |
| S5 | Add `DELT/CONF/bedrock.json` (D4) | Kiro | code |
| S6 | Re-spec `.kiro/agents/bosscat.json`: drop "provisional — pilot-scoped" and every Cursor reference; peer = Claude Code (local seat); `resources` → this briefing, steering, the pin file; keep tools `read`/`write`/`shell` with only `read` pre-allowed; keep the credit abort and the no-AWS-plane line; add `permissions` denying writes to the governance-plane paths above and credential-printing shell patterns; migrate hooks to CLI 3.0 form (`/upgrade-agent`, no `.json.bak` committed) | Kiro | Kiro tooling |
| S7 | `pwsh -File BRAV/SCPT/kiro/regen-steering.ps1` after S6 (root `AGENTS.md` and `CHARTER.md` already reflect the 2026-09-24/25 seats) | Kiro | Kiro tooling |
| S8 | `.kiro/specs/bedrock-alignment/{requirements,design,tasks}.md` as projections of this briefing | Kiro | Kiro tooling |
| S9 | Delete the dead OIDC/S3 step and `AWS_*`/`S3_*` env lines from `.github/workflows/run-archiver.yml` (the archiver reads none of them); regenerate `docs/status/workflows.json` | Local seat | CI-ops |
| S10 | ECRR `CHAR/ECRR/ECRR_REPORTS/ECRR_KIRO_BEDROCK_ALIGNMENT_<date>.md` per the evidence table | Local seat | evidence |
| S11 | `[KIRO BEDROCK ALIGNMENT]` log line, then the mirror | Cascade driver | docs, mirror |

Out of scope: new summarisation targets (ECRR summaries, run-card prose); any write to `CHAR/ECRR/**` by the call itself;
an MCP wrapper; AgentCore; the Cursor-era guides (already bannered).

---

## Identity and credentials (operator)

- IAM Identity Center profile (`aws configure sso`), no static access key. If one exists from the 2025 guide, deactivate
  and delete it first.
- Permission set carries only: `bedrock:InvokeModel` (+ `InvokeModelWithResponseStream` only if streaming is used) on
  `arn:aws:bedrock:eu-west-2:<ACCOUNT_ID>:inference-profile/eu.anthropic.claude-sonnet-5` with
  `aws:RequestedRegion = eu-west-2`, and on `arn:aws:bedrock:eu-*::foundation-model/anthropic.claude-sonnet-5`
  conditioned on `bedrock:InferenceProfileArn` = that profile. Enumerate destination Regions with
  `aws bedrock get-inference-profile` rather than assuming them.
- Agent and script env carry `AWS_PROFILE` and `AWS_REGION` only. Never key material.
- Blast radius: any `AKIA`/`ASIA` string or SSO token in a Kiro transcript or artefact → `aws sso logout`, revoke the
  role sessions, ECRR records RED. Sessions are short-lived; the rule still applies.
- Rotation register: one row, type "SSO permission set", no expiry, review date 2027-03-25, owner `@fubumaki`,
  kill switch "detach policy". This is a docs-lane change to `CREDENTIAL_ROTATION_CALENDAR.md`, not a new reminder.

---

## Evidence (ECRR, quantified before / after)

| Measure | Before | After (pass) | How it fails |
|---|---|---|---|
| Model-ID literals in code outside the pin file | 5 files | 0 (`grep -rn "anthropic\.claude" --include=*.ts --include=*.ps1` finds only `DELT/CONF/bedrock.json`) | any literal remains |
| Invoke with the old pin | `get-foundation-model` output for both retired IDs (operator, before any edit) | — | — |
| Invoke with the new pin | — | HTTP 200, `stopReason=end_turn`, usage recorded, region eu-west-2 in response metadata | non-200 or wrong region |
| Negative control | — | pin set to the retired ID → check reports `RED` | check stays GREEN (invalid check) |
| Abstain | — | no credentials → `NOT_RUN`, own exit code; clean-host E2E never invokes the check | `NOT_RUN` counted as pass anywhere |
| Span in SigNoz | none | one span with `gen_ai.request.model=eu.anthropic.claude-sonnet-5` within 60 s of the call | span absent or attribute wrong |
| Credential hygiene | unknown | zero `AKIA`/`ASIA` matches in the Kiro transcript and artefacts | any match → rotate, RED |
| Seat activity | 1 commit (edcdd931) | ≥1 merged commit with `Actor: Kiro{Implementer}`, merged by another seat | self-merge or missing actor line |
| Kiro credits | 7.69 (pilot) | recorded; below the abort threshold | threshold crossed → abort |

A check must be able to pass, fail and abstain; the clean-host gate must not depend on AWS.

---

## Order of work

1. **Operator, before Kiro starts:** run and paste (no credentials appear in the output)
   `aws bedrock get-foundation-model` for `anthropic.claude-3-5-sonnet-20241022-v2:0` and
   `anthropic.claude-3-haiku-20240307-v1:0` (us-east-1), and `aws bedrock get-inference-profile` for
   `eu.anthropic.claude-sonnet-5` (eu-west-2); report static-key state and `kiro-cli --version`; create the permission
   set; confirm Sonnet 5 model access in eu-west-2; launch `kiro-cli` in the operator's checkout.
2. PR A (Kiro tooling): S6, S7, S8. Merge on the operator's go.
3. PR B (code): S1–S5, ≤10 files. Merge on the operator's go.
4. PR C (CI-ops, local seat): S9. Independent; any time after step 1.
5. PR D (evidence, local seat): S10. Then S11 by whichever seat is told to drive (`Driving:` comment on the head PR).
6. Docs follow-up: rotation-register row; this briefing's status line updated to the ECRR verdict.

---

## What reopens this

- Kiro ships bring-your-own-Bedrock (in-account inference): re-cost "alignment" as a config change.
- AWS lets AgentCore route platform telemetry away from CloudWatch: Shape B's evidence-plane objection weakens.
- Sonnet 5 enters Legacy (EOL no sooner than 2027-06-30), or London gains In-Region Sonnet-class on `bedrock-runtime`.
- Either `docs/PURPOSE.md` reopen trigger fires.
- Kiro credit use per task materially exceeds the pilot baseline: revisit which seat owns Bedrock work.

Review date: **2027-03-25**.
