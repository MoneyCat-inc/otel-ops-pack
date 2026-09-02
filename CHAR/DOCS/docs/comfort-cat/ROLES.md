# 🐾 Agent Roles & Authority Hierarchy

**Authority:** BossCat OEM  
**Last Updated:** 2025-10-20; seats rewritten to the charter 2026-09-02  
**Status:** ACTIVE (restates `docs/BossCat/CHARTER.md`)

---

## 🎭 Seats (aligned to `docs/BossCat/CHARTER.md`, 2026-09-02)

> **Rewritten 2026-09-02.** Until this date the section below listed IONA, Investigator, Gap-Closer
> and QA Scribe as active roles and routed delegation through them. Those roles were retired
> (charter, 2026-08-13). The authority of record is **`docs/BossCat/CHARTER.md`**; this file only
> restates it for the creative/ops context and must not diverge from it.

### 1. BossCat OEM — authority

The oversight function, not a person or a tool: sets milestones, approves gates, holds veto over
production changes. Exercised in practice by the machine operator.

### 2. Machine operator — `@fubumaki`

**The only seat with hands.** Elevated PowerShell, Hyper-V and the clean-host E2E clock, every
credential (mint, paste, rotate), and **merging pull requests** — none of it delegable.

### 3. Cursor{Implementer} — permanent

Repository implementation seat: writes code and docs, opens PRs, files ECRRs, operates under lane
discipline, **never merges its own work**.

### 4. Kiro{Implementer} — permanent (since 2026-08-14)

Peer of Cursor{Implementer}, not nested under it. Same rules; `Actor: Kiro{Implementer}` per commit.

### Chat/review seat

Drafts memos, audits and analysis; **proposes, never decides**; no keyboard — cannot elevate, mint or
merge.

---

## ⚡ Authority Delegation Chain

```text
Machine operator @fubumaki  (authority of BossCat OEM, exercised by the operator)
    ↓ delegates scoped work to
Cursor{Implementer}  ⇄  Kiro{Implementer}   (peers; lane discipline; never self-merge)
    ↑ proposals, audits, drafts from
Chat/review seat  (proposes, never decides)
```

Retired: IONA, Investigator, Gap-Closer, QA Scribe, Codex Cloud/Local (2025 arrangement).

---

## 🔐 Authorization Protocol *(historical — 2025 command protocol)*

> The `@cat …` command vocabulary below drove workflows that have been `workflow_dispatch`-only
> since 2026-08-03 (e.g. `boss-gate-signal-and-merge.yml`). Kept for provenance; today's operating
> model is the charter's lane discipline plus one lean ECRR per change.

### Cursor{Implementer} Activation

**Command Format:**

```text
@cat <command> : You Are Cursor{Implementer}, <role>. Acting under authority of <delegator>.
```

**Example:**

```text
@cat ready-for-gate : You Are Cursor{Implementer}, Code Writer-Executioner. Acting under authority of Fubumaki.
```

**When activated:**

1. Acknowledge role and delegator
2. Verify canonical reference exists (`docs/comfort-cat/`)
3. Check gate status and current state
4. Execute assigned command with full authority
5. Generate ECRR evidence and artifacts
6. Report completion back to delegator

---

## 📋 Command Vocabulary

### Gate Commands

- `@cat ready-for-gate` - Verify gate readiness and report status
- `@cat approve-gate` - Approve gate transition (BossCat OEM only)
- `@cat gate-status` - Report current gate status

### Execution Commands

- `@cat examine` - Run ECRR Examine phase
- `@cat clean` - Run ECRR Clean phase
- `@cat report` - Generate ECRR Report
- `@cat ecrr-cycle` - Run full ECRR cycle

### Operational Commands

- `@cat health-check` - Run quick health verification
- `@cat canary-test` - Generate and verify canary tests
- `@cat pipeline-verify` - End-to-end pipeline validation

---

## 🛡️ Guardrails

### Cursor{Implementer} Operating Constraints

- **Must** operate under explicit delegation
- **Must** follow ECRR methodology for all changes
- **Must** generate evidence artifacts
- **Must** reference comfort-cat canonical docs when uncertain
- **Must** fail closed if required specs are missing
- **Cannot** approve own work (requires BossCat OEM approval)
- **Cannot** bypass security or compliance checks
- **Cannot** make production changes without gate approval

### BossCat OEM Exclusive Powers

- Production deployment approval
- Gate transition approval
- Veto authority over any decision
- Emergency override capability
- Compliance framework modifications

### Fubumaki Supreme Powers

- Grant/revoke agent authority
- Override all decisions
- Repository-level configuration changes
- Strategic direction setting

---

## 📊 Role Performance Metrics

### Cursor{Implementer} Success Criteria

- [ ] One lean ECRR per change (the 2025 compliance scorer was retired 2026-08-03)
- [ ] Zero unauthorized production changes
- [ ] Complete evidence trail for all actions
- [ ] Artifacts generated within SLA (<5 min for reports)
- [ ] Gate criteria met before approval requests

### BossCat OEM Oversight Metrics

- [ ] ≥95% gate success rate
- [ ] <24hr incident response time
- [ ] Clean-host E2E gate stays green (the one standing proof, per `docs/PURPOSE.md`)

---

## 🎯 Escalation Paths

### Standard Issues

1. Cursor{Implementer} detects issue
2. Run ECRR cycle to remediate
3. Generate evidence and report
4. Submit for BossCat OEM review

### Critical Issues

1. Immediate escalation to BossCat OEM
2. Log one line in `docs/BossCat/BOSSCAT_LOG.md` (the IONA error ledger is closed)
3. Execute emergency runbook
4. Notify Fubumaki if production-impacting

### Security Issues

1. **STOP** - Cease all operations
2. Immediate escalation to Fubumaki
3. Document in security ledger
4. Execute security remediation playbook
5. Generate incident report

---

🐾 **Agent Roles & Authority Hierarchy**  
*This document defines the canonical authority structure for all agent operations*


