# 🌙 Nightly Dashboard Export Guide

> **UNBUILT (2026-09-02 truth pass).** `.github/workflows/nightly-dashboard-export.yml` never shipped —
> no such file and no such schedule exists anywhere in the repo, although many 2025 docs cite it.
> Dashboard exports are manual: `pnpm dashboard:export` / `pnpm export:signoz:playwright`. The compose
> file is the root `docker-compose.yml`. Kept as the design record.

**BossCat OEM Framework** - Automated SigNoz Dashboard Capture & Archival

---

## Overview

The nightly dashboard export system automatically captures SigNoz dashboards at **2:00 AM UTC daily** and commits them
to the repository. This provides:

✅ **Historical tracking** - View dashboard states over time  
✅ **Compliance evidence** - Automated audit trail for BossCat  
✅ **Incident response** - Compare "before" and "after" states  
✅ **Trend analysis** - Track metrics evolution  
✅ **Disaster recovery** - Restore dashboard configurations

---

## Workflow Configuration

### File Location

`.github/workflows/nightly-dashboard-export.yml`

### Trigger Schedule

- **Scheduled**: Daily at 2:00 AM UTC (`cron: '0 2 * * *'`)
- **Manual**: Via "Run workflow" button (optional `export_all` parameter)

### Workflow Steps

1. **Checkout repository** - Get latest code
2. **Setup tooling** - Node.js, PNPM, PowerShell, Playwright
3. **Install dependencies** - `pnpm install --frozen-lockfile`
4. **Start SigNoz stack** - `docker compose up -d   # root docker-compose.yml`
5. **Wait for health** - Poll `http://localhost:8080/api/v1/health` (max 60 attempts)
6. **Run export script** - Execute `scripts/nightly-dashboard-export.ps1` or Playwright
7. **Collect snapshots** - Copy artifacts to `docs/observability/snapshots/YYYY-MM-DD/`
8. **Generate index** - Create README with snapshot listing
9. **Upload artifacts** - GitHub Actions artifacts (90-day retention)
10. **Commit to repo** - Auto-commit snapshots with BossCat OEM Bot identity
11. **Stop SigNoz** - Clean teardown with `docker compose down -v`
12. **Generate summary** - Add results to workflow summary

---

## Output Locations

### 1. Repository Snapshots (Permanent)

**Path**: `docs/observability/snapshots/YYYY-MM-DD/`

**Contents**:

```text
docs/observability/snapshots/
├── 2025-10-07/
│   ├── README.md                     # Auto-generated index
│   ├── executive-dashboard.png       # Executive summary view
│   ├── pipeline-metrics.png          # OTel collector metrics
│   ├── queue-pressure.png            # Queue health dashboard
│   ├── error-rates.png               # Error tracking
│   └── compliance-score.json         # Metrics extract
├── 2025-10-08/
│   └── ...
```

**Retention**: Permanent (committed to Git)

### 2. GitHub Actions Artifacts (Temporary)

**Name**: `dashboard-snapshots-<run-number>`

**Contents**: Same as repository snapshots plus raw artifacts

**Retention**: 90 days

### 3. Workflow Summary

**Location**: Actions run page → Summary tab

**Contents**: Snapshot listing, file sizes, run metadata

---

## Verification Process

### Daily Verification (Automated)

The workflow includes self-verification:

```yaml
- name: Generate summary
  if: always()
  run: |
    echo "## 📊 Nightly Dashboard Export Summary" >> $GITHUB_STEP_SUMMARY
    echo "**Date**: $(date +%Y-%m-%d)" >> $GITHUB_STEP_SUMMARY
    ls -lh docs/observability/snapshots/$(date +%Y-%m-%d)/
```

### Manual Verification Steps

#### Step 1: Check Workflow Status

```bash
# Via GitHub CLI
gh workflow list
gh run list --workflow=nightly-dashboard-export.yml --limit 7

# Expected: All runs "completed" with green checkmark
```

**Or** visit: `https://github.com/<owner>/<repo>/actions/workflows/nightly-dashboard-export.yml`

#### Step 2: Verify Latest Snapshot

```bash
# From repository root
$today = Get-Date -Format "yyyy-MM-dd"
$snapshotDir = "docs/observability/snapshots/$today"

if (Test-Path $snapshotDir) {
    Write-Host "✅ Today's snapshot exists" -ForegroundColor Green
    Get-ChildItem $snapshotDir | Format-Table Name, Length, LastWriteTime
} else {
    Write-Host "❌ No snapshot for $today" -ForegroundColor Red
}
```

#### Step 3: Check Snapshot Contents

Minimum expected files:

- [ ] `README.md` - Auto-generated index
- [ ] `*.png` - At least 3-5 dashboard screenshots
- [ ] `*.json` - Optional metrics extracts

**Quality checks**:

```bash
# Check PNG files are valid (not corrupted)
Get-ChildItem $snapshotDir -Filter "*.png" | ForEach-Object {
    $size = $_.Length
    if ($size -lt 10KB) {
        Write-Host "⚠️ $($_.Name) is suspiciously small ($size bytes)" -ForegroundColor Yellow
    } else {
        Write-Host "✅ $($_.Name) ($size bytes)" -ForegroundColor Green
    }
}
```

#### Step 4: Review Commit History

```bash
# Check recent commits from BossCat OEM Bot
git log --author="BossCat OEM Bot" --oneline -10

# Expected pattern:
# docs(observability): nightly dashboard export 2025-10-07
# docs(observability): nightly dashboard export 2025-10-06
# ...
```

#### Step 5: Test Snapshot Access

```bash
# Verify snapshots can be opened
$latestPng = Get-ChildItem $snapshotDir -Filter "*.png" | Select-Object -First 1
if ($latestPng) {
    Start-Process $latestPng.FullName  # Opens in default viewer
}
```

---

## Troubleshooting

### Issue: Workflow Fails at "Start SigNoz stack"

**Symptoms**:

- Workflow logs show timeout waiting for SigNoz health check
- Error: "Failed to connect to <http://localhost:8080/api/v1/health>"

**Diagnosis**:

```bash
# Check if SigNoz is running
docker ps | grep signoz

# Check SigNoz logs
docker logs signoz-query-service
docker logs signoz-otel-collector
```

**Solutions**:

1. **Docker resource limits**: Increase memory in GitHub-hosted runner settings
2. **Port conflicts**: Ensure ports 8080, 4317, 4318 are available
3. **Health check timeout**: Increase wait time in workflow (current: 600s)
4. **Networking issues**: Check if containers can communicate

**Workflow Fix**:

```yaml
# Increase health check timeout
for i in {1..60}; do  # Currently 60 attempts × 10s = 600s
  # Increase to 90 for slower environments
  for i in {1..90}; do
```

### Issue: No Snapshots Generated

**Symptoms**:

- Workflow completes but `docs/observability/snapshots/` is empty
- No commit from BossCat OEM Bot

**Diagnosis**:

```bash
# Check workflow artifacts
gh run view <run-id> --log

# Look for:
# - "Run dashboard export" step failures
# - Playwright errors
# - File copy issues
```

**Solutions**:

1. **Script missing**: Verify `scripts/nightly-dashboard-export.ps1` exists
2. **Playwright browser issues**: Check browser installation logs
3. **Permission issues**: Ensure workflow has `contents: write` permission
4. **SigNoz not ready**: Health check passes but dashboard not accessible

**Manual Test**:

```bash
# Run export locally
pwsh -File scripts/nightly-dashboard-export.ps1

# Check if artifacts are created
ls artifacts/*.png
```

### Issue: Commit Fails with "Nothing to commit"

**Symptoms**:

- Export succeeds but no commit created
- Workflow logs: "No changes to commit"

**Diagnosis**:
This is **expected behavior** if snapshots are identical to previous day.

**Verification**:

```bash
# Check if files changed
git diff --name-only docs/observability/snapshots/

# If no diff, no commit needed
```

**Solution**: No action needed. This prevents duplicate commits when dashboards are static.

### Issue: Snapshots are Corrupted/Blank

**Symptoms**:

- PNG files exist but are blank/corrupted
- File sizes are unusually small (<1 KB)

**Diagnosis**:

```bash
# Check file sizes
Get-ChildItem docs/observability/snapshots/$(Get-Date -Format "yyyy-MM-dd")/*.png | 
    Where-Object { $_.Length -lt 10KB }
```

**Solutions**:

1. **Playwright timing**: Add delays before screenshots
2. **Authentication issues**: SigNoz requires login
3. **Dashboard loading**: Increase wait time for data rendering

**Workflow Fix** (in Playwright script):

```typescript
// Wait for dashboard to fully load
await page.goto('http://localhost:8080/dashboard');
await page.waitForLoadState('networkidle');
await page.waitForTimeout(5000); // Wait 5s for data to render
await page.screenshot({ path: 'dashboard.png', fullPage: true });
```

### Issue: Repository Growing Too Large

**Symptoms**:

- Repository size increasing rapidly
- Clone times becoming slow

**Diagnosis**:

```bash
# Check repository size
git count-objects -vH

# Check snapshot directory size
du -sh docs/observability/snapshots/
```

**Solutions**:

1. **Reduce snapshot frequency**: Change to weekly
2. **Compress images**: Optimize PNG files
3. **Archive old snapshots**: Move to separate archive repo
4. **Use Git LFS**: Store large files externally

**Compression Script**:

```bash
# Optimize PNG files (lossless)
find docs/observability/snapshots/ -name "*.png" -exec optipng -o7 {} \;

# Or use pngquant (lossy but better compression)
find docs/observability/snapshots/ -name "*.png" -exec pngquant --ext .png --force {} \;
```

---

## Maintenance Tasks

### Weekly Review

**Every Monday**:

1. **Verify last 7 days** of snapshots exist
2. **Check workflow success rate** (should be 100%)
3. **Review snapshot file sizes** (trend analysis)
4. **Test manual export** to ensure script works

**Quick Check Script**:

```powershell
# Check last 7 days of snapshots
$last7Days = 0..6 | ForEach-Object {
    (Get-Date).AddDays(-$_).ToString("yyyy-MM-dd")
}

foreach ($date in $last7Days) {
    $dir = "docs/observability/snapshots/$date"
    if (Test-Path $dir) {
        $fileCount = (Get-ChildItem $dir -File).Count
        Write-Host "✅ $date : $fileCount files" -ForegroundColor Green
    } else {
        Write-Host "❌ $date : MISSING" -ForegroundColor Red
    }
}
```

### Monthly Maintenance

**First of every month**:

1. **Archive old snapshots** (>90 days)

   ```bash
   # Move to archive
   mkdir -p archive/observability-snapshots
   mv docs/observability/snapshots/2024-* archive/observability-snapshots/
   ```

2. **Verify disk usage** is acceptable

   ```bash
   du -sh docs/observability/snapshots/
   # Should be < 500 MB
   ```

3. **Test restore process** - Ensure snapshots can be used
4. **Review workflow performance** - Check execution time trends
5. **Update documentation** if process changed

### Quarterly Audit

**Every 3 months**:

1. **Compliance review** - Verify snapshots meet audit requirements
2. **Incident response drill** - Use snapshots to investigate mock incident
3. **Retention policy review** - Adjust based on storage/compliance needs
4. **Workflow optimization** - Identify and implement improvements
5. **Tool updates** - Upgrade Playwright, Docker, SigNoz

---

## Manual Export

### On-Demand Export

Trigger manual export for immediate needs:

#### Via GitHub UI

1. Go to Actions → "Nightly Dashboard Export"
2. Click "Run workflow"
3. Select branch (usually `main`)
4. Check "Export all dashboards" if needed (default: executive only)
5. Click "Run workflow"

#### Via GitHub CLI

```bash
# Trigger workflow
gh workflow run nightly-dashboard-export.yml

# With parameters
gh workflow run nightly-dashboard-export.yml -f export_all=true

# Check status
gh run list --workflow=nightly-dashboard-export.yml --limit 1
```

#### Via Local Script

```powershell
# Run locally (requires SigNoz running)
pwsh -File scripts/nightly-dashboard-export.ps1

# Or with Playwright
pnpm run export:signoz:playwright
```

---

## Integration with BossCat Framework

### ECRR Compliance

Dashboard snapshots serve as **evidence artifacts** for ECRR reports:

- **Examine**: Captures current system state
- **Clean**: Baseline for comparing improvements
- **Report**: Visual evidence of metrics
- **Role**: BossCat OEM Bot maintains automated capture

### Incident Response

Use snapshots to:

1. **Establish baseline** - Normal state before incident
2. **Compare states** - Before/during/after incident
3. **Root cause analysis** - Visual timeline of metrics
4. **Post-mortem** - Evidence for incident reports

### Audit Trail

Snapshots provide **immutable audit trail**:

- Git commit history preserves snapshot timeline
- Cannot be retroactively modified (Git immutability)
- Timestamp and authorship tracked
- Accessible for compliance reviews

---

## Advanced Configuration

### Custom Dashboard Selection

Edit `scripts/nightly-dashboard-export.ps1`:

```powershell
# Default: Executive dashboard only
$dashboards = @(
    @{ Name = "Executive"; Url = "http://localhost:8080/dashboard/exec" }
)

# Extended: Multiple dashboards
$dashboards = @(
    @{ Name = "Executive"; Url = "http://localhost:8080/dashboard/exec" }
    @{ Name = "Pipeline"; Url = "http://localhost:8080/dashboard/pipeline" }
    @{ Name = "Queue"; Url = "http://localhost:8080/dashboard/queue" }
    @{ Name = "Errors"; Url = "http://localhost:8080/dashboard/errors" }
)
```

### Export JSON Metrics

Add metrics export alongside screenshots:

```typescript
// In Playwright script
const metrics = await page.evaluate(() => {
    // Extract metrics from SigNoz dashboard
    return {
        timestamp: new Date().toISOString(),
        logVolume: document.querySelector('.log-volume')?.textContent,
        errorRate: document.querySelector('.error-rate')?.textContent,
        latencyP99: document.querySelector('.latency-p99')?.textContent
    };
});

await fs.writeFile('compliance-score.json', JSON.stringify(metrics, null, 2));
```

### Change Retention Period

Modify workflow:

```yaml
- name: Upload artifacts
  uses: actions/upload-artifact@v4
  with:
    retention-days: 90  # Change to 30, 60, 180, etc.
```

### Notification on Failure

Add notification step:

```yaml
- name: Notify on failure
  if: failure()
  uses: actions/github-script@v7
  with:
    script: |
      github.rest.issues.create({
        owner: context.repo.owner,
        repo: context.repo.repo,
        title: '🚨 Nightly Dashboard Export Failed',
        body: `Dashboard export failed on ${new Date().toISOString()}.\n\n[View workflow run](${context.payload.repository.html_url}/actions/runs/${context.runId})`,
        labels: ['automation', 'incident', 'bosscat']
      });
```

---

## Performance Metrics

### Target SLOs

| Metric | Target | Current |
|--------|--------|---------|
| **Success Rate** | > 99% | TBD |
| **Execution Time** | < 15 min | ~10-12 min |
| **Snapshot Size** | < 10 MB | ~5-7 MB |
| **Storage Growth** | < 5 GB/year | TBD |

### Monitoring

Add metrics to SigNoz:

```powershell
# In nightly-dashboard-export.ps1
$duration = Measure-Command { # export logic }

# Emit OTLP metric
Send-OtlpMetric -Name "dashboard_export_duration_seconds" -Value $duration.TotalSeconds
Send-OtlpMetric -Name "dashboard_export_size_bytes" -Value $totalSize
```

---

## References

- **Workflow**: `.github/workflows/nightly-dashboard-export.yml`
- **Script**: `scripts/nightly-dashboard-export.ps1`
- **Playwright Config**: `playwright.signoz.config.ts`
- **Output Directory**: `docs/observability/snapshots/`

---

**Last Updated**: 2025-10-07  
**Next Review**: Weekly  
**Maintained By**: BossCat OEM Framework  
**Status**: ✅ Production Ready

