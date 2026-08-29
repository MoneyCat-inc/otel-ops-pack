# RSI Auto-Promotion System

**Authority**: BossCat OEM Governance Framework  
**Status**: ✅ Operational (Nightly Automation)

---

## Overview

The RSI (Research-driven Self-Improvement) system includes **automated baseline promotion** when statistical thresholds
are met. This ensures performance improvements are captured systematically while maintaining BossCat governance
oversight.

---

## How It Works

### 1. Nightly Statistical Analysis

**Workflow**: `.github/workflows/rsi-sweep-nightly.yml`  
**Schedule**: Daily at 02:30 UTC

**Process**:

1. Runs 3-repeat BatchSize sweep (500, 800, 1000, 1200, 1500)
2. Calculates statistical metrics:
   - Median (robust central tendency)
   - Standard deviation & CV%
   - 95% confidence intervals
   - Statistical significance (CI overlap test)
3. Generates `ECRR_RSI_NIGHTLY_STATS_LATEST.md` with recommendation

---

### 2. Auto-Promotion Thresholds

**Criteria** (all must be met):

- ✅ **Statistical significance**: 95% CIs do not overlap
- ✅ **Recommendation**: Report explicitly recommends "Consider BatchSize=XXXX"
- ✅ **Pattern**: "statistically significant" appears in recommendation

**Example Passing Report**:

```markdown
## Conclusion

**Best configuration**: BatchSize=1500
- Median improvement: **5.2%** vs baseline
- Consistency: CV=0.8% (vs baseline CV=2.5%)
- **Recommendation**: ✅ **Consider BatchSize=1500** (statistically significant improvement)
- Confidence intervals do not overlap, indicating real performance difference
```

**Example Failing Report** (keeps baseline):

```markdown
## Conclusion

**Best configuration**: BatchSize=1200
- Median improvement: **2.93%** vs baseline
- **Recommendation**: ⚠️ **Keep BatchSize=1000** (improvement not statistically significant)
- Confidence intervals overlap, indicating difference may be due to variance
```

---

### 3. Automated PR Creation

**When threshold met**:

1. **Branch created**: `rsi/auto-baseline-bsXXXX`
2. **File updated**: `BRAV/SCPT/rsi-bench/bench-index.ps1` (default BatchSize)
3. **Commit message**: ECRR-compliant with evidence
4. **PR created**: With labels:
   - `rsi` (RSI optimization)
   - `auto-promotion` (automated)
   - `needs-bosscat-approval` (governance gate)

**PR Body**: Complete statistical analysis report attached

---

### 4. BossCat Governance Gate

**Human Oversight**: Required for all auto-generated PRs

**BossCat Review**:

- ✅ Review statistical evidence
- ✅ Verify longitudinal consistency (7-14 days data)
- ✅ Check for anomalies or measurement issues
- ✅ Approve or request changes

**Merge Process**:

- Auto-generated PR requires explicit BossCat approval
- No auto-merge (human decision required)
- Complete audit trail preserved

---

## Auto-Comments on RSI PRs

**Workflow**: Posts nightly stats to open PRs with `rsi` label

**Comment Contents**:

- Latest statistical analysis (collapsible)
- Timestamp of analysis
- Link to workflow run

**Purpose**:

- Keep PR authors informed of performance trends
- Provide context for RSI-related changes
- Enable data-driven discussions

---

## Safety Mechanisms

### 1. Statistical Rigor ✅

- 3-repeat sweeps (median, not mean)
- 95% confidence intervals
- CI overlap test (conservative)
- Multi-night data collection

### 2. Human Oversight ✅

- Auto-generated PRs require approval
- BossCat can reject if suspicious
- Complete evidence for review
- Reversible changes (parameter only)

### 3. Kill-Switch ✅

- `.agent/LOCK` pauses all RSI automation
- Manual intervention capability
- Workflow can be disabled
- Branch protection enforced

### 4. Audit Trail ✅

- All PRs tagged and traceable
- Statistical reports archived (90 days)
- METRICS.jsonl append-only log
- Git history preserved

---

## Configuration

### Promotion Thresholds

**Current Settings** (embedded in `rsi-sweep-nightly.yml`):

```regex
# Pattern match in ECRR_RSI_NIGHTLY_STATS_LATEST.md:
Consider BatchSize=(\d+).*[Ss]tatistically significant
```

**To Adjust**:

1. Edit `.github/workflows/rsi-sweep-nightly.yml`
2. Modify regex pattern in "Check if baseline should be promoted" step
3. Add additional constraints (e.g., minimum improvement %)

**Example Stricter Threshold**:

```pwsh
# Require both significance AND minimum 3% improvement
if ($report -match 'Consider BatchSize=(\d+)' -and 
    $report -match 'Median improvement: \*\*(\d+\.\d+)%' -and 
    [double]$Matches[1] -ge 3.0 -and
    $report -match '[Ss]tatistically significant') {
    # Promote
}
```

---

## Manual Override

### Skip Auto-Promotion

**Temporarily disable**:

1. Add `.agent/LOCK` file (pauses all RSI)
2. Or disable workflow in GitHub Actions settings
3. Or close auto-generated PR with comment

**Permanently disable auto-promotion**:

1. Remove "Create baseline update PR" step from workflow
2. Keep auto-comments (optional)

### Force Promotion

**Manual baseline update**:

```bash
# Update default in bench-index.ps1
sed -i 's/\[int\]$BatchSize = 1000/[int]$BatchSize = 1500/' BRAV/SCPT/rsi-bench/bench-index.ps1

# Commit with evidence
git add BRAV/SCPT/rsi-bench/bench-index.ps1
git commit -m "feat(rsi): Manual baseline update to BatchSize=1500

BossCat Decision: Override auto-promotion thresholds
Evidence: [attach relevant reports]
Rationale: [explain decision]"
```

---

## Monitoring

### Check Auto-Promotion Status

**View latest nightly run**:

- GitHub Actions → `rsi-sweep-nightly` → Latest run
- Check "Check if baseline should be promoted" step output

**Review open auto-promotion PRs**:

```bash
gh pr list --label auto-promotion
```

**View statistical trends**:

```bash
# Last 7 days of stats reports
ls -lt CHAR/ECRR/ECRR_REPORTS/ECRR_RSI_NIGHTLY_STATS_*.md | head -7
```

### Alerts

### No alerts configured by default

**Optional**: Add GitHub Actions notifications

- Slack webhook on promotion PR creation
- Email to BossCat on threshold met
- GitHub Issues for anomalies

---

## Examples

### Successful Auto-Promotion Flow

1. **Day 1-6**: Nightly sweeps show inconsistent results (CIs overlap)
   - No PR created ✅
   - Auto-comments posted to open RSI PRs

2. **Day 7**: Consistent pattern emerges (BatchSize=1500, +4.2%, CIs separate)
   - Threshold met ✅
   - PR auto-created: `rsi/auto-baseline-bs1500`
   - BossCat notified via GitHub

3. **Day 7-8**: BossCat reviews evidence
   - Checks longitudinal data
   - Approves PR

4. **Day 8**: PR merged
   - New baseline: BatchSize=1500
   - Future sweeps use 1500 as baseline

### Rejected Auto-Promotion

1. **Day 3**: Single night shows +5% improvement
   - Threshold met (temporarily)
   - PR auto-created: `rsi/auto-baseline-bs1200`

2. **Day 4-5**: Follow-up nights show regression
   - CIs now overlap
   - New stats posted as PR comment

3. **Day 5**: BossCat reviews conflicting evidence
   - Closes PR with comment: "Wait for consistent 7-day trend"
   - No merge ✅

4. **Day 6+**: Nightly continues monitoring
   - Will re-create PR if consistent pattern emerges

---

## Troubleshooting

### Auto-Promotion Not Triggering

**Check**:

1. Review latest `ECRR_RSI_NIGHTLY_STATS_LATEST.md`
   - Does it recommend baseline update?
   - Is "statistically significant" mentioned?
2. Check workflow logs for "Check if baseline should be promoted"
   - Does regex match?
3. Verify `.agent/LOCK` doesn't exist (kill-switch)

### Duplicate PRs Created

**Cause**: Promotion threshold met on consecutive nights

**Solution**: 

- Close duplicate PRs
- Merge first PR to update baseline
- Future PRs will use new baseline

### PR Creation Fails

**Check**:

- GitHub token permissions (needs `contents: write`, `pull-requests: write`)
- Branch protection rules
- Git configuration in workflow

---

## Future Enhancements

**Potential Additions**:

1. **Trend plots**: Visualize median-of-3 over time
2. **Multi-parameter**: Extend to Concurrency, ARCH_QPS, etc.
3. **Rollback detection**: Auto-revert if new baseline regresses
4. **Confidence decay**: Require fresh validation after X days
5. **A/B testing**: Run dual baselines before committing

---

## References

- **Nightly Workflow**: `.github/workflows/rsi-sweep-nightly.yml`
- **Statistical Analysis**: `BRAV/SCPT/rsi-bench/analyze-sweep-stats.ps1`
- **Sweep Tool**: `BRAV/SCPT/rsi-bench/sweep-batchsize.ps1`
- **Evidence Pipeline**: `CHAR/EVID/artifacts/ecrr/index/METRICS.jsonl`
- **BossCat Charter**: `AGENTS.md`

---

🐾 **Auto-Promotion System: Operational & BossCat-Approved** 🐾

**Status**: Production-ready with human oversight  
**Safety**: Statistical rigor + governance gates  
**Audit**: Complete evidence trail maintained


