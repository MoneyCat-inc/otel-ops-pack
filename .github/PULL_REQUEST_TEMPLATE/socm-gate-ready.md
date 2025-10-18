# SOCM: Week-1 Ops — Acceptance & Gate

**Lane**: `SOCM` (single-writer)  
**Signal**: `@cat ready-for-gate`  
**Actors**: A = Writer, B = Monitor (no writes)

---

## ✅ Checklists

### **Governance**

- [ ] Preflight GREEN (`npm run agent:preflight`) — kill-switch clear, git pristine, budgets in range
- [ ] Acceptance Test (FAT) passed locally — paste tail below
- [ ] Evidence appended (`.agent/EVIDENCE.log`) with `who/type/msg` events
- [ ] No silent trunk writes (all via PR + human gate)

### **Artifacts Present**

- [ ] `docs/widgets/bluesky-latest.json` (latest 5 posts)
- [ ] `artifacts/social/follow_suggestions.jsonl` (≥5 suggestions)
- [ ] `artifacts/social/trends.json` (trend metrics)
- [ ] `docs/social/TAGS.suggestions.yaml` (tag proposals)

### **Lane & Budget**

- [ ] All changes in SOCM lane (`docs/social/**`, `scripts/social/**`, `artifacts/social/**`)
- [ ] ≤10 files modified
- [ ] ≤200 LOC delta
- [ ] Single lane only (no cross-lane bleed)

### **A/B Split**

- [ ] Agent A (AUTO-BOTS-SOCM-ALFA): Wrote changes
- [ ] Agent B (IONA-CATS-SOCM-BETA): Will verify (read-only)
- [ ] Human: Final approval required

---

## 📎 Evidence (Paste Tails)

### **Preflight**

<details>
<summary>Click to expand</summary>

```powershell
$ npm run agent:preflight

# (Paste output here)
# Expected: Exit 0 (GREEN)
```

</details>

### **FAT Tail** (`.agent/EVIDENCE.log`)

<details>
<summary>Click to expand - Last 40 SOCM events</summary>

```json
(Paste last 40 lines from .agent/EVIDENCE.log here)
```

</details>

### **Artifact Checksums** (Optional)

<details>
<summary>Click to expand</summary>

```powershell
# Widget JSON
Get-FileHash docs/widgets/bluesky-latest.json

# Follow suggestions
Get-FileHash artifacts/social/follow_suggestions.jsonl

# Trends
Get-FileHash artifacts/social/trends.json
```

</details>

---

## 📊 What Changed

**Files Modified**: [count]

**Summary**:
- [Describe changes: e.g., "Updated widget export with latest 5 posts"]
- [e.g., "Generated 12 follow suggestions from curated list"]
- [e.g., "Analyzed 3 tags from 14-day trend window"]

**Why**:
- [Rationale: e.g., "Week 1 execution requires fresh widget data"]

---

## 🔒 Governance

### **NATO 4-4-4-4 Naming** ✅
- Lane: SOCM
- Writer: AUTO-BOTS-SOCM-ALFA (Agent A)
- Monitor: IONA-CATS-SOCM-BETA (Agent B)

### **Budgets Respected** ✅
- Files: [X] / 10 limit
- LOC: [Y] / 200 limit
- Jobs: [Z] / 2 limit

### **Suggest-Only** ✅
- Follow suggestions: Human approval required (≤5/week)
- Trend proposals: Human approval required
- No auto-follow, no auto-tag, no auto-post from widget

### **Kill-Switch** ✅
- Status: CLEAR (`.agent/LOCK` absent)
- All scripts respect lock (exit 50 if present)
- Emergency halt ready

---

## 🧪 Chaos Drill (Optional, Data Room)

### **If Executed**:

**Scenario**: [e.g., Service Down]  
**Flow**: Laminar → Service Down → Stop → Laminar  
**Result**: [e.g., Error spike → fallback to ledger → recovery in 90s]  
**Evidence**: [Screenshot or log snippet]

**ICF Lesson** (if applicable):
```
ICF_LESSON: [Improvement identified from drill]
ICF_SCOPE: SOCM
ICF_RISK: low
```

---

## 🧭 ICF Lesson Intake (T+48h)

### **After Week 1**:

- [ ] Mini-retro completed (Friday evening)
- [ ] Ran `npm run social:icf-lesson`
- [ ] Extracted suggestion: [paste here]
- [ ] Proposed improvement scoped (≤10 files, ≤200 LOC)
- [ ] Will file follow-up PR if approved

---

## 🎯 Gate Signal

**Ready for review. Approve with**: `@cat ready-for-gate`

### **Agent B (IONA-CATS-SOCM-BETA) - Please Verify**:
- ✅ Evidence complete (all actions logged)
- ✅ Budgets respected (files/LOC within limits)
- ✅ Lane-scoped (SOCM only, no bleed)
- ✅ Suggest-only maintained (no autonomous actions)
- ✅ Artifacts valid (JSON/JSONL properly formatted)

### **BossCat OEM - Final Approval**:
- ✅ Governance compliant (single-writer, kill-switch, gate)
- ✅ Evidence audit trail complete
- ✅ Week 1 execution safe to proceed

---

## 📚 References

**Governance**:
- AUTO-BOTS Registry: NATO 4-4-4-4, A/B split
- Stability Pack: Preflight, lock, retry, exit codes
- BossCat Charter: `AGENTS.md`

**Execution**:
- Quick Reference: `SOCM_WEEK1_QUICK_REFERENCE.md`
- Thread Packs: Days 1-3 ready
- 48H Watch: `docs/BossCat/SOCM_48H_WATCH.md`

**Learning**:
- ICF Acceptance: `SOCM_ICF_LESSON_ACCEPTANCE.md`
- Mini-Retro Template: `SOCM_T48H_MINI_RETRO_TEMPLATE.md`

---

🐾 **BossCat: Gate-ready PR template** 🦋

