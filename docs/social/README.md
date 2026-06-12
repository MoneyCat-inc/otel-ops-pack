# 🦋 Social Communications Lane (SOCM)

**Lane**: SOCM (Social Communications)  
**Authority**: AUTO-BOTS-SOCM-ALFA (Writer) | IONA-CATS-SOCM-BETA (Monitor)  
**Gate Signal**: `@cat ready-for-gate`  
**Kill-Switch**: `.agent/LOCK`

---

## 🎯 Purpose

Evidence-first social media integration for Resonai [OTel] project on Bluesky.

**Principles**:
- ✅ **ECRR-compliant**: Every action logged, reviewed, reversible
- ✅ **Single-writer**: Agent A composes/posts; Agent B reviews only
- ✅ **Gate-controlled**: No auto-posting; human approval required
- ✅ **Budget-enforced**: ≤10 files, ≤200 LOC per change
- ✅ **Kill-switch ready**: `.agent/LOCK` stops all automation

---

## 📁 Contents

### Policy & Guidelines

- **`POLICY.md`** - Tone, safety, accessibility, tag rules
- **`TEMPLATES.md`** - Post templates (verdicts, releases, tips)
- **`TAGS.yaml`** - Approved hashtags + usage guidelines
- **`FOLLOW_LIST.yaml`** - Declarative follows (reviewable, version-controlled)

### Draft Queue & Ledger

- **`artifacts/social/queue.jsonl`** - Append-only draft queue
- **`artifacts/social/posted.jsonl`** - Append-only post ledger

### Automation Scripts

- **`scripts/social/compose.ts`** - Draft builder with ECRR logging
- **`scripts/social/post.ts`** - ATProto poster with preflight checks
- **`scripts/social/follow.ts`** - Declarative follow applier

---

## 🚀 Usage (Milestone A - DRY-RUN)

### 1. Compose a Draft

```bash
npx tsx scripts/social/compose.ts \
  --text "New investigation: short verdict + link" \
  --tags "OSINT,FactCheck" \
  --links "https://github.com/MoneyCat-inc/otel-ops-pack"
```

**Output**:
- Appends draft to `artifacts/social/queue.jsonl`
- Logs to `.agent/EVIDENCE.log` (plan → edit → report → exit)

### 2. Review & Gate

- **Agent B** reviews the draft (PR diff or queue inspection)
- Human comments `@cat ready-for-gate` on PR/Issue
- CI job sets `approved:true` on draft (Milestone B)

### 3. Post (DRY-RUN for Milestone A)

```bash
npx tsx scripts/social/post.ts
```

**Behavior**:
- ✅ Checks for `.agent/LOCK` (kill-switch)
- ✅ Requires `approved:true` on latest draft
- ✅ DRY-RUN mode (no network call)
- ✅ Logs to `.agent/EVIDENCE.log`
- ✅ Appends ledger entry to `artifacts/social/posted.jsonl`

### 4. Declarative Follows

```bash
npx tsx scripts/social/follow.ts
```

**Behavior**:
- Reads `FOLLOW_LIST.yaml`
- Shows diff (who would be followed)
- DRY-RUN (no network call)
- Milestone B adds `--apply` flag

---

## 🔒 Budgets & Guardrails

**Lane Configuration** (`.agent/config-socm.json`):
```json
{
  "lanes": {
    "socm": {
      "allow": ["docs/social/**", "artifacts/social/**", "scripts/social/**"],
      "budgets": {"maxFiles": 10, "maxLoc": 200, "maxJobs": 2},
      "runner": {
        "writer": "AUTO-BOTS-SOCM-ALFA",
        "monitor": "IONA-CATS-SOCM-BETA"
      }
    }
  }
}
```

**Agent Roles** (NATO 4-4-4-4):
- `AUTO-BOTS-SOCM-ALFA` - Writer (compose, post, follow)
- `IONA-CATS-SOCM-BETA` - Monitor (review, validate, gate)

---

## 🛑 Kill-Switch

If `.agent/LOCK` exists:
- ✅ All `post.ts` runs refuse to execute
- ✅ CI jobs short-circuit with exit code 50
- ✅ ECRR incident logged
- ✅ Human intervention required

**Activate**:
```bash
touch .agent/LOCK
```

**Deactivate**:
```bash
rm .agent/LOCK
```

---

## 📊 ECRR Evidence

All scripts emit JSONL events to `.agent/EVIDENCE.log`:

```json
{
  "t": "2025-10-18T02:15:00.000Z",
  "who": "A",
  "type": "plan|preflight|edit|report|exit",
  "lane": "SOCM",
  "files_touched": 1,
  "loc_delta": 1,
  "msg": "queued draft d_1729217700000"
}
```

---

## 🎯 Milestones

### ✅ Milestone A (Foundation - CURRENT)

- [x] Lane config (`SOCM`)
- [x] Policy & templates
- [x] Draft queue system
- [x] ECRR logging
- [x] Kill-switch integration
- [x] DRY-RUN posting

### 🔜 Milestone B (Real Posting + Gate)

- [ ] CI gate workflow (`social_post.yml`)
- [ ] `@cat ready-for-gate` approval automation
- [ ] Real ATProto posting (sandbox first)
- [ ] Secrets management (`BSKY_HANDLE`, `BSKY_APP_PASSWORD`)
- [ ] Rollback on failure

### 🔜 Milestone C (Site Integration)

- [ ] Add Bluesky link to header/footer
- [ ] "Latest posts" widget on status page
- [ ] Accessibility validation

### 🔜 Milestone D (Follow & Feeds)

- [ ] `FOLLOW_LIST.yaml` enforcement
- [ ] Dry-run → approval → apply workflow
- [ ] Follow ledger integration

### 🔜 Milestone E (Tags & Trends)

- [ ] Tag suggestions from trends
- [ ] Engagement analytics
- [ ] Suggest-only mode (no auto-post)

---

## 📋 File Count (Budget Check)

**Milestone A**: 10 files
```
docs/social/
  - POLICY.md
  - TEMPLATES.md
  - FOLLOW_LIST.yaml
  - TAGS.yaml
  - README.md (this file)
artifacts/social/
  - queue.jsonl
  - posted.jsonl
scripts/social/
  - compose.ts
  - follow.ts
  - post.ts
.agent/
  - config-socm.json
```

**Total LOC**: ~180 (within ≤200 budget) ✅

---

## 🔗 Related Docs

- **BossCat Charter**: `docs/BossCat/CHARTER.md`
- **ECRR Methodology**: `docs/BossCat/CHARTER.md`
- **Stability Pack**: `docs/BossCat/WORKFLOW_IMMEDIATE_WINS_PATTERN.md`
- **Bluesky Platform Guide**: `BLUESKY_PLATFORM_GUIDE.md`
- **Integration Plan**: See implementation plan docs

---

**Status**: ✅ Milestone A COMPLETE - Ready for review  
**Next**: PR → `@cat ready-for-gate` → Milestone B implementation

🐾 **BossCat-Approved Pattern**

