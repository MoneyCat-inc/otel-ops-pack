# Persona Activation Guide

**Status**: 🟡 Ready for Activation  
**Last Updated**: 2025-11-01

---

## Overview

This guide walks through activating **Quil** (DOCS lane) and **Lumi** (VIZR lane) for automated remediation work.

---

## Step 1: Add API Credentials to GitHub Secrets

### For GitHub Actions (Recommended)

1. Navigate to repository **Settings** → **Secrets and variables** → **Actions**
2. Click **New repository secret**
3. Add the following secrets:

| Secret Name | Value | Purpose |
|-------------|-------|---------|
| `QUIL_API_KEY` | `sk-proj-...` | OpenAI API key for Quil (DOCS lane) |
| `LUMI_API_KEY` | `sk-proj-...` | OpenAI API key for Lumi (VIZR lane) |

**Notes**:
- You can use the same OpenAI key for both, or separate keys for cost tracking
- Model: `gpt-4o` (recommended for technical accuracy)
- Estimated cost: ~$0.50-2.00 per ticket (depending on context size)

### For Local Testing

```powershell
# Set temporarily in current session
$env:OPENAI_API_KEY = "sk-proj-..."

# Or add to PowerShell profile for persistence
# C:\Users\<you>\Documents\PowerShell\Microsoft.PowerShell_profile.ps1
$env:OPENAI_API_KEY = "sk-proj-..."
```

---

## Step 2: Test Locally (Dry-Run)

Before activating workflows, test locally to validate persona voice and output quality.

### Test Quil (DOCS Lane)

```powershell
# Dry-run Ticket 1: Architecture Documentation Cleanup
$env:OPENAI_API_KEY = "sk-proj-..."
.\scripts\invoke-quil.ps1 -Ticket 1 -DryRun

# Review outputs
code artifacts\codex\workplan.json
code artifacts\codex\cursor-instructions.md

# Check ECRR report
$report = Get-ChildItem CHAR\ECRR\ECRR_REPORTS -Filter "ECRR_DOCS_*.md" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
code $report.FullName
```

**Validation Checklist**:
- [ ] Workplan contains unified diff patches
- [ ] PR body includes all 4 ECRR phases (Examine, Clean, Report, Role)
- [ ] Voice is "velvet, calm, meticulous" (check for clarity, consistency language)
- [ ] Budget respected (≤10 files, ≤200 LOC)
- [ ] Gate phrase present: `@cat ready-for-gate`

### Test Lumi (VIZR Lane)

```powershell
# Dry-run Ticket 4: Visualization Documentation
$env:OPENAI_API_KEY = "sk-proj-..."
.\scripts\invoke-lumi.ps1 -Ticket 4 -DryRun

# Review outputs
code artifacts\codex\workplan.json
code artifacts\codex\cursor-instructions.md
```

**Validation Checklist**:
- [ ] Documentation is technically precise (GPU, rendering, pipeline terminology)
- [ ] PR body includes all 4 ECRR phases
- [ ] Voice is "luminous, technical, pulse-like" (check for visual/technical clarity)
- [ ] Troubleshooting runbooks included
- [ ] Budget respected

---

## Step 3: Run First Live Ticket (Quil)

Once dry-run validates, run live for Ticket 1.

### Option A: Manual (Local)

```powershell
# Remove -DryRun flag
$env:OPENAI_API_KEY = "sk-proj-..."
.\scripts\invoke-quil.ps1 -Ticket 1

# Review and apply patches manually
code artifacts\codex\cursor-instructions.md

# Human backup (Maya Singh) reviews
# Commit when approved
git add .
$commitMsg = @"
[DOCS] Architecture docs cleanup (Quil/Ticket 1)

@cat ready-for-gate

Co-authored-by: VelvetQuill-42 <quil@catnap.local>
Reviewed-by: Maya Singh <maya@example.com>
"@
git commit -m $commitMsg
```

### Option B: GitHub Actions Workflow

```bash
# Navigate to Actions tab in GitHub
# Select "Quil (DOCS Lane) - Automated Documentation"
# Click "Run workflow"
# Select:
#   - Ticket: 1
#   - Dry run: false
# Click "Run workflow"

# Monitor run in Actions tab
# Review artifacts when complete
# Human backup (Maya Singh) approves PR
```

---

## Step 4: Validate Persona Voice & Quality

After first live run, perform thorough validation:

### Voice Quality (Quil)

**Expected markers**:
- "Clarity" / "consistency" / "accessible"
- Smooth, flowing prose
- Meticulous attention to detail
- Gentle, velvet tone (no aggressive language)

**Red flags**:
- Generic/robotic language
- Missing ECRR phases
- Budget violations
- Technical imprecision

### Voice Quality (Lumi)

**Expected markers**:
- "Render" / "pipeline" / "sync" / "latency"
- Technical precision
- Visual/luminous metaphors
- Pulse-like rhythm (short, precise sentences)

**Red flags**:
- Vague technical descriptions
- Missing diagrams/visual aids
- Incomplete troubleshooting steps

### Feedback Loop

If voice drifts or quality drops:
1. Review `docs/personas/{quil|lumi}-persona.md`
2. Enhance persona documentation with examples
3. Adjust system prompt in workflow
4. Re-run with updated persona

---

## Step 5: Enable Weekly Automation (Optional)

Once validated, enable scheduled runs for continuous remediation.

### Enable Schedule (GitHub Actions)

Edit workflow files:

**.github/workflows/quil-docs-lane.yml**:
```yaml
schedule:
  # Uncomment to enable weekly runs
  - cron: '0 9 * * 1'  # Monday 9am UTC
```

**.github/workflows/lumi-vizr-lane.yml**:
```yaml
schedule:
  # Uncomment to enable weekly runs
  - cron: '0 9 * * 2'  # Tuesday 9am UTC
```

**Recommendation**: Start with manual triggers, enable schedule after 2-3 successful runs.

---

## Step 6: Monitor Weekly Metrics

Track remediation progress with ECRR analytics.

```powershell
# Weekly metrics refresh
pwsh -File scripts\extract-ecrr-metrics.ps1

# View dashboard
Start-Process artifacts\ecrr-analytics\ecrr-dashboard.html

# Check compliance trend
$metrics = Get-Content artifacts\ecrr-analytics\ecrr-metrics.json | ConvertFrom-Json
$complianceRate = [math]::Round(($metrics.byPhase.complete / $metrics.totalReports) * 100, 1)
Write-Host "ECRR Compliance: $complianceRate% (target: ≥80%)"
```

**Success Criteria** (30 days):
- ECRR compliance: 37.7% → ≥80%
- Clean phase: 13% → ≥80%
- Role phase: 15% → ≥80%
- DOCS reports: 2 → ≥5
- VIZR reports: 0 → ≥2

---

## Troubleshooting

### Issue: "OPENAI_API_KEY not set"

```powershell
# For local scripts
$env:OPENAI_API_KEY = "sk-proj-..."

# For GitHub Actions
# Add secret in repo Settings → Secrets → Actions → QUIL_API_KEY
```

### Issue: "Persona voice validation failed"

Check `artifacts/codex/workplan.json` for:
- Missing ECRR phases (Examine, Clean, Report, Role)
- Generic language (not matching persona voice)
- Budget violations

**Fix**: Enhance persona documentation, adjust system prompt.

### Issue: "Rate limit exceeded"

OpenAI has rate limits (e.g., 500 requests/day for free tier).

**Solutions**:
- Upgrade to paid tier
- Space out runs (manual triggers instead of daily schedule)
- Use different API keys for Quil and Lumi

### Issue: "Patches fail to apply"

If generated patches don't apply cleanly:
1. Check if code changed since manifest was generated
2. Review `artifacts/codex/cursor-instructions.md` manually
3. Apply changes by hand
4. Provide feedback to improve future patches

---

## Rollback

If personas produce low-quality output or cause issues:

### Disable Workflows

```bash
# Navigate to .github/workflows/
# Comment out 'schedule:' sections
# Disable workflow in GitHub Actions UI
```

### Revert to Manual Process

```powershell
# Use new-ecrr-report.ps1 without personas
.\scripts\new-ecrr-report.ps1 -Lane DOCS -Status READY -Author "Maya Singh"

# Follow manual remediation plan
code docs\ecrr\REMEDIATION_PLAN.md
```

---

## Cost Estimate

| Item | Estimated Cost |
|------|----------------|
| **Per Ticket** | $0.50 - $2.00 |
| **6 Tickets** | $3.00 - $12.00 |
| **Weekly Runs** (maintenance) | $2.00 - $4.00/week |
| **Monthly** | ~$10.00 - $25.00 |

**Notes**:
- Based on gpt-4o pricing (~$0.005/1K input, ~$0.015/1K output)
- Larger codebases = higher cost
- Dry-runs are ~half the cost (no PR generation)

---

## Summary Checklist

- [ ] Step 1: API keys added to GitHub Secrets (QUIL_API_KEY, LUMI_API_KEY)
- [ ] Step 2: Local dry-run successful (Quil Ticket 1, Lumi Ticket 4)
- [ ] Step 3: First live ticket completed (Quil Ticket 1)
- [ ] Step 4: Persona voice validated (velvet/luminous tone confirmed)
- [ ] Step 5: Weekly automation enabled (optional, after 2-3 successful runs)
- [ ] Step 6: Weekly metrics monitoring in place

---

## Next Actions

1. **Immediate**:
   - Add API keys to GitHub Secrets
   - Run local dry-run: `.\scripts\invoke-quil.ps1 -Ticket 1 -DryRun`
   
2. **This Week**:
   - Execute Ticket 1 (Quil, Architecture docs)
   - Validate voice and quality
   - Human backup (Maya Singh) reviews
   
3. **Next 30 Days**:
   - Complete all 6 tickets (3 DOCS, 2 VIZR, 1 COMP)
   - Track compliance improvement weekly
   - Adjust personas based on feedback

---

## Support

- **Persona Issues**: Review `docs/personas/{quil|lumi}-persona.md`
- **Workflow Issues**: Check `.github/workflows/{quil|lumi}-*.yml`
- **ECRR Questions**: See `docs/ecrr/ECRR_PROCESSING_COMPLETE.md`
- **Human Backups**:
  - DOCS lane: Maya Singh
  - VIZR lane: Alex Romero

---

**Version**: 1.0  
**Status**: 🟡 Ready for Activation  
**Last Updated**: 2025-11-01


