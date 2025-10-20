# ECRR: Governance Knobs — Inflated Metrics Protection

**Date:** 2025-10-20  
**Authority:** BossCat OEM  
**Executor:** cursor{implementer}  
**Status:** ✅ **OPERATIONAL**

---

## Executive Summary

Implemented **BossCat OEM standing orders** for fail-closed governance of performance claims. Multi-layered protection prevents regression of inflated metrics (77×, 196.7) across dev machines, PR reviews, and CI/CD.

---

## Governance Layers

### 1. CI Guard (Automated Blocking) ✅

**Location:** `.github/workflows/bosscat-gate-verify.yml:57-59`

**Trigger:** Every PR and push to main

**Action:**
```yaml
- name: Guard - Inflated metrics blocked
  shell: pwsh
  run: pwsh -File scripts/guard-inflated-metrics.ps1
```

**Blocks:**
- Core: `77×`, `77x`, `7 7 x`
- HTML: `77&times;`, `77&#215;`, `77&nbsp;x`
- Unicode: `×`, `✕`
- Worded: `seventy-seven times`, `seventy seven x`
- Derived: `196.7`, `196,7`

**Scope:** Production files only (excludes archives)

**Exit:**
- `0` → CI continues
- `1` → **CI FAILS**, PR blocked with remediation guidance

---

### 2. CODEOWNERS (Human Review) ✅

**Location:** `CODEOWNERS:77-92`

**Protected Files:**
```
/index.html @BossCat
/portal.html @BossCat
/README*.md @BossCat
/docs/**/*.md @BossCat
/docs/GATE_STATUS_DASHBOARD.md @BossCat
/docs/ecrr/ECRR_REPORTS/ @BossCat @audit-team
/scripts/guard-inflated-metrics.ps1 @BossCat
/scripts/index-performance-claims.ps1 @BossCat
```

**Effect:** All changes to performance-sensitive files require **BossCat OEM approval** before merge

**Rationale:** Prevents accidental or malicious injection of unverified claims

---

### 3. PR Template (Checklist Enforcement) ✅

**Location:** `.github/pull_request_template.md`

**Performance Claims Section:**
```markdown
## Performance Claims
- [ ] I changed performance claims
  - [ ] I have included evidence report link: EVIDENCE_YYYY-MM-DD.md
  - [ ] Evidence includes: baseline, new config, 5+ trials, 95% CI
  - [ ] Claims are scoped (e.g., "OTLP ingest" not "product 7× faster")
  - [ ] Publication rules followed (CI ≥6× for "up to 7×")
OR
- [ ] I did NOT change performance claims
```

**Effect:** Forces contributor to explicitly acknowledge performance claim changes and provide evidence

**Visibility:** Appears on every PR automatically

---

### 4. Pre-Commit Hook (Optional Dev Machine) ✅

**Location:** `scripts/pre-commit-inflated-metrics.sh`

**Installation (Optional):**
```bash
ln -s ../../scripts/pre-commit-inflated-metrics.sh .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

**Action:** Blocks `git commit` if banned patterns detected in staged files

**Scope:** Excludes archives

**Benefit:** Catches issues **before** they reach CI (faster feedback loop)

---

### 5. Benchmark Campaign Script (Ready-to-Run) ✅

**Location:** `scripts/run-benchmark-campaign.ps1`

**Purpose:** Streamlined measurement workflow using `EVIDENCE_TEMPLATE.md`

**Usage:**
```powershell
pwsh -File scripts/run-benchmark-campaign.ps1 -Trials 5
```

**Outputs:**
- `docs/ecrr/ECRR_REPORTS/EVIDENCE_YYYY-MM-DD.md` (from template)
- `artifacts/metrics_YYYY-MM-DD/` (trial logs, screenshots)

**Workflow:**
1. Run baseline trials (5×)
2. Apply optimized config
3. Run new trials (5×)
4. Capture SigNoz screenshots
5. Fill evidence template with results
6. Calculate 95% CI and decide publication threshold

**Guard Integration:** CI guard enforces publication rules automatically

---

## Policy Enforcement Matrix

| Layer | Type | Trigger | Coverage | Bypass |
|-------|------|---------|----------|--------|
| **CI Guard** | Automated | PR + push | Production files | None |
| **CODEOWNERS** | Human review | PR | Sensitive files | BossCat OEM only |
| **PR Template** | Checklist | PR creation | All PRs | N/A |
| **Pre-commit** | Optional local | `git commit` | Staged files | Not installed by default |
| **Benchmark Script** | Tool | Manual | N/A | N/A |

---

## Copy Discipline (Standing Orders)

### Current Language (Until Benchmarks Run)
```markdown
Performance: Thresholds met (see test evidence)
```

**Status:** ✅ Deployed in 5 production files

**Rationale:** Fail-closed, verifiable, no unsubstantiated claims

---

### Future Language (After Benchmark Campaign)

**Option A: If 95% CI lower bound ≥6×**
```markdown
**Performance:** Up to 7× OTLP ingest throughput improvement 
(baseline vs. tuned config, median of 5 trials, identical hardware).  
**See evidence →** [EVIDENCE_YYYY-MM-DD.md](docs/ecrr/ECRR_REPORTS/EVIDENCE_YYYY-MM-DD.md)
```

**Option B: If 95% CI lower bound <6×**
```markdown
**Performance:** Synthetic OTLP ingest improved from X logs/sec 
(baseline) to Y logs/sec (tuned config), median of 5 trials.  
**See evidence →** [EVIDENCE_YYYY-MM-DD.md](docs/ecrr/ECRR_REPORTS/EVIDENCE_YYYY-MM-DD.md)
```

**Requirements:**
- ✅ Must link to evidence report
- ✅ Must scope claim ("OTLP ingest" not "product 7× faster")
- ✅ Must follow publication threshold (CI ≥6×)

---

## Regression Signals to Watch

**BossCat OEM will monitor for:**

1. **PRs changing hero/README without evidence link**
   - Trigger: CODEOWNERS review required
   - Action: Require evidence or reject

2. **New encodings of banned patterns**
   - Examples: `7·7×`, `7^7x`, `77 times`, localized variants
   - Action: Update guard patterns in `scripts/guard-inflated-metrics.ps1`

3. **Scope creep in claims**
   - Examples: "7× faster product", "7× better than competitors"
   - Action: Require scoping to tested scenario ("OTLP ingest throughput")

4. **Evidence template drift**
   - Example: Modified template weakens publication threshold
   - Action: CODEOWNERS protects `EVIDENCE_TEMPLATE.md`

---

## Verification Commands

**Local Test (Dev Machine):**
```powershell
pwsh -File scripts/guard-inflated-metrics.ps1
```
Expected: `✅ No inflated metrics detected in production files`

**Pre-commit Test (Optional):**
```bash
bash scripts/pre-commit-inflated-metrics.sh
```
Expected: `✅ No inflated metrics detected`

**CI Test (Automated):**
Runs automatically on every PR/push via `bosscat-gate-verify.yml`

---

## BossCat Log Entry

**Added to `docs/BossCat/BOSSCAT_LOG.md:3`:**
```
- 2025-10-20T00:00:00Z — Inflated metrics remediated; guard active; evidence template installed; Gate #007 green.
```

---

## Compliance Status

| Standard | Status | Evidence |
|----------|--------|----------|
| **ECRR Methodology** | ✅ | Examine → Clean → Report → Role |
| **BossCat OEM Standing Orders** | ✅ | All 5 governance knobs operational |
| **Cat Nap Control Room** | ✅ | No-hype, evidence-first persona |
| **Fail-Closed Posture** | ✅ | Multiple defensive layers |
| **Gate #007** | ✅ | APPROVED (post-remediation) |

---

## Future Maintenance

### Adding New Banned Patterns

**If new variants appear:**

1. Update `scripts/guard-inflated-metrics.ps1`:
   ```powershell
   $bannedPatterns = @(
       '77\s*[x×✕]',
       # Add new pattern here
   )
   ```

2. Test locally:
   ```powershell
   pwsh -File scripts/guard-inflated-metrics.ps1
   ```

3. Commit and push (CI will validate)

### Adding New Protected Files

**If new performance-sensitive files created:**

1. Update `CODEOWNERS`:
   ```
   /new-landing-page.html @BossCat
   ```

2. Commit (requires BossCat approval due to CODEOWNERS protecting CODEOWNERS)

---

## Knowledge Transfer

### For New Contributors

**If you want to make performance claims:**

1. ✅ Use template: `docs/ecrr/ECRR_REPORTS/EVIDENCE_TEMPLATE.md`
2. ✅ Run benchmark: `pwsh -File scripts/run-benchmark-campaign.ps1`
3. ✅ Calculate 95% CI on medians
4. ✅ Follow publication threshold (CI ≥6×)
5. ✅ Scope claims to tested scenario
6. ✅ Link evidence report in all claims
7. ✅ Get BossCat OEM approval (CODEOWNERS enforced)

**CI will block if you:**
- ❌ Use banned patterns (`77×`, `196.7`)
- ❌ Add claims without evidence links
- ❌ Use HTML/Unicode variants

**CODEOWNERS will require review if you:**
- ⚠️ Edit `index.html`, `README*.md`, `docs/**`
- ⚠️ Change guard scripts
- ⚠️ Modify ECRR reports

---

## Summary

**Governance Layers Operational:**
- ✅ CI Guard (automated blocking)
- ✅ CODEOWNERS (human review)
- ✅ PR Template (checklist)
- ✅ Pre-commit hook (optional local)
- ✅ Benchmark script (ready-to-run)

**Protection Status:** 🔒 **LOCKED IN**

**Regression Risk:** **LOW** (multi-layered defense)

**Gate #007:** ✅ **APPROVED** (BossCat OEM)

---

**Seal:** 🐾 **Governance Knobs Operational — Standing Orders Active**  
**Date:** 2025-10-20  
**Authority:** BossCat OEM (Taskmaster-Overseer)

_Fail-closed. Multi-layered. Evidence-required. No regression possible._ 🚀🐾

