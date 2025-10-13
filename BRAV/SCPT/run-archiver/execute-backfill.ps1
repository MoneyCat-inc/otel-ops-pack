# BRAV/SCPT/run-archiver/execute-backfill.ps1
# BossCat Run Archiver — Execute all shards
# Wrapper for parallel shard execution

param(
  [string]$Repo = "MoneyCat-inc/otel-ops-pack",
  [int]$Shards = 8,
  [int]$MaxParallel = 12,
  [switch]$DeleteAfterArchive = $false,
  [switch]$DryRun = $true
)

$ErrorActionPreference = "Stop"

Write-Host "🐾 BossCat Run Archiver — Execute All Shards"
Write-Host "Shards: $Shards"
Write-Host "MaxParallel per shard: $MaxParallel"
Write-Host "DeleteAfterArchive: $DeleteAfterArchive"
Write-Host "DryRun: $DryRun"

# Verify preflight completed
if (-not (Test-Path ".agent/tmp/TRIMSET.txt")) {
  Write-Error "Preflight not run. Execute: pwsh BRAV/SCPT/run-archiver/preflight.ps1"
  exit 1
}

# Load summary
$summary = Get-Content ".agent/tmp/preflight-summary.json" | ConvertFrom-Json
Write-Host "`nPreflight summary:"
Write-Host "  Total runs: $($summary.total_runs)"
Write-Host "  To archive: $($summary.trim_count)"
Write-Host "  To keep: $($summary.keep_count)"

# Execute shards sequentially (for simplicity and safety)
$startTime = Get-Date

for ($i = 0; $i -lt $Shards; $i++) {
  Write-Host "`n--- Executing Shard $i of $Shards ---"
  
  & pwsh BRAV/SCPT/run-archiver/backfill.ps1 `
    -Repo $Repo `
    -Shard $i `
    -Shards $Shards `
    -MaxParallel $MaxParallel `
    -DeleteAfterArchive:$DeleteAfterArchive `
    -DryRun:$DryRun
  
  if ($LASTEXITCODE -ne 0) {
    Write-Warning "Shard $i failed with exit code $LASTEXITCODE (continuing...)"
  }
  
  # Pause between shards
  Start-Sleep -Seconds 5
}

$duration = (Get-Date) - $startTime

Write-Host "`n✅ All shards complete"
Write-Host "Duration: $($duration.ToString('hh\:mm\:ss'))"

# Final verification
$finalCount = gh api "repos/$Repo/actions/runs?per_page=1" -q '.total_count'
Write-Host "`nFinal run count: $finalCount"
Write-Host "Target: $($summary.keep_count)"

if ($finalCount -le ($summary.keep_count + 50)) {
  Write-Host "✅ SUCCESS: Run count within acceptable range" -ForegroundColor Green
} else {
  Write-Host "⚠️ WARNING: Run count higher than expected (may need another pass)" -ForegroundColor Yellow
}

# Evidence summary
Write-Host "`nEvidence trail:"
Write-Host "  Archived runs: CHAR/EVID/artifacts/ecrr/arch/"
Write-Host "  Evidence JSONL: CHAR/EVID/artifacts/ecrr/arch/EVIDENCE.jsonl"
Write-Host "  Execution log: This output"

