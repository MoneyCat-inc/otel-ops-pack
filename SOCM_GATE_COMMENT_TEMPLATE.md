# 🎯 SOCM Gate Comment Template

**Purpose**: Copy-paste comment for `@cat ready-for-gate` signal  
**Use**: After FAT passes, paste into PR to trigger gate approval

---

## 📋 GATE COMMENT (Copy-Paste)

```
@cat ready-for-gate

Scope: SOCM
Result: FAT ✅ (preflight green; widget/export ok; 12 follow suggestions; trends & tag proposals generated; ICF lesson extracted)
Evidence: See template sections (preflight; FAT tail; artifact listings)
Governance: NATO 4-4-4-4 enforced; suggest-only flows; budgets in range; kill-switch clear

Request: Gate approval to proceed with Week-1 execution playbook.
```

---

## 📊 CUSTOMIZATION GUIDE

### **Scope**
- Always: `SOCM` (for social media operations)
- Or: `ICF` (for meta-improvements to learning loop)
- Or: `DOCS` (if touching documentation only)

### **Result**
Update with actual FAT results:
- `preflight green` (exit 0)
- `widget/export ok` (JSON created, N posts)
- `X follow suggestions` (actual count)
- `Y tags analyzed` (actual count)
- `ICF lesson extracted` (or "no suggestions found")

### **Evidence**
Point to PR template sections:
- Preflight output (collapsed section)
- FAT tail (last 40 evidence events)
- Artifact listings (file hashes optional)

### **Governance**
Confirm all guardrails:
- `NATO 4-4-4-4 enforced` (A/B split verified)
- `suggest-only flows` (no auto-actions)
- `budgets in range` (≤10 files, ≤200 LOC)
- `kill-switch clear` (no `.agent/LOCK`)

---

## 🎯 WHEN TO USE

### **Standard SOCM PRs**
- Widget updates (export refresh)
- Follow suggestions (weekly review)
- Tag proposals (from trend analysis)
- Content updates (thread packs, FAQs)

### **ICF Lesson PRs**
- Small improvements (≤10 files, ≤200 LOC)
- Evidence-based refinements
- Learning loop closure

### **Emergency PRs**
- Kill-switch activation/deactivation
- Incident rollback
- Policy breach resolution

---

## 🛡️ VARIATIONS

### **If FAT Failed**
```
@cat gate-request

Scope: SOCM
Result: FAT ⚠️ PARTIAL (preflight green; widget ok; follows FAILED [reason]; trends ok; ICF ok)
Evidence: See template sections + error logs
Action: Investigating [component], will update when resolved

Request: Gate review on hold pending fix
```

### **If Kill-Switch Active**
```
@cat gate-request

Scope: SOCM
Result: FAT ⛔ BLOCKED (kill-switch ACTIVE - .agent/LOCK present)
Evidence: Kill-switch activated at [timestamp], reason: [description]
Action: Contained, investigating, will remove lock after resolution

Request: Gate review deferred until kill-switch cleared
```

### **If Budget Exceeded**
```
@cat gate-request

Scope: SOCM
Result: FAT ⚠️ BUDGET (preflight green; changes exceed budget: [X files / Y LOC])
Evidence: See file list below
Action: Re-scoping to fit within ≤10 files, ≤200 LOC

Request: Gate review deferred until budget compliance
```

---

## 📝 BOSSCAT LOG ONE-LINER (After Gate Passes)

**Template** (paste into `docs/BossCat/BOSSCAT_LOG.md`):

```markdown
- YYYY-MM-DDThh:mm:ssZ — Lane SOCM — [Operation description]: [outcome]; A/B gate enforced; kill-switch clear; budgets respected; evidence clean. [Reference: PR#XXX or commit SHA]
```

**Example**:
```markdown
- 2025-10-21T16:00:00Z — Lane SOCM — Week 1 Day 2 post (Technical Stack): live, threaded, engaged; A/B gate enforced; kill-switch clear; budgets respected; evidence clean. URI: at://did:plc:xyz/...
```

---

## 🐾 GATE APPROVAL CONFIRMATION

### **After BossCat Approves**

**You'll See** (in PR comments):
```
✅ @cat gate-approved

Agent B verification: PASS
BossCat OEM review: APPROVED
Evidence: Complete
Budgets: Respected
Safe to merge.
```

**Then**:
1. Merge PR (green merge button)
2. Delete branch (cleanup)
3. Log to BossCat log (one-liner)
4. Continue execution

---

🐾 **Gate comment ready - paste when FAT passes!** 🚀

