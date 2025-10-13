# BRAV/SCPT/run-archiver/preflight.ps1
# BossCat Run Archiver — Preflight inventory
# Generates KeepSet (newest 100) and TrimSet (older completed runs)

param(
  [string]$Repo = "MoneyCat-inc/otel-ops-pack",
  [int]$Keep = 100
)

$ErrorActionPreference = "Stop"

Write-Host "🐾 BossCat Run Archiver — Preflight Inventory"
Write-Host "Repository: $Repo"
Write-Host "Keep: $Keep newest runs"

# Create working directory
New-Item -ItemType Directory -Path ".agent/tmp" -Force -ea 0 | Out-Null

# Check auth
Write-Host "`nVerifying gh CLI authentication..."
gh auth status 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
  Write-Error "gh CLI not authenticated. Run: gh auth login"
  exit 1
}

# Get total run count
Write-Host "`nFetching total run count..."
$total = gh api "repos/$Repo/actions/runs?per_page=1" -q '.total_count'
Write-Host "Total runs in Actions: $total"

# Fetch all runs (limit to reasonable number)
Write-Host "`nFetching run inventory (this may take 1-2 minutes)..."
$limit = [Math]::Min(20000, [int]$total + 100)

gh run list --repo $Repo --limit $limit --json databaseId,createdAt,status,conclusion `
  | ConvertFrom-Json `
  | Sort-Object createdAt -Descending `
  | ConvertTo-Json -Depth 5 `
  | Set-Content ".agent/tmp/runs.json"

$allRuns = Get-Content ".agent/tmp/runs.json" | ConvertFrom-Json

Write-Host "Fetched $($allRuns.Count) runs"

# KeepSet: Newest 100 + any non-completed
$keepSet = $allRuns | Select-Object -First $Keep
$keepIds = $keepSet | ForEach-Object { $_.databaseId }
$keepIds | Set-Content ".agent/tmp/KEEPSET.txt"

Write-Host "`nKeepSet: $($keepIds.Count) runs (newest $Keep)"

# TrimSet: Older completed runs only
$trimSet = $allRuns | 
  Select-Object -Skip $Keep | 
  Where-Object { $_.status -eq "completed" }

$trimIds = $trimSet | ForEach-Object { $_.databaseId }
$trimIds | Set-Content ".agent/tmp/TRIMSET.txt"

Write-Host "TrimSet: $($trimIds.Count) runs to archive+delete"

# Summary
$summary = @{
  timestamp = (Get-Date).ToString("o")
  repo = $Repo
  total_runs = $total
  fetched_runs = $allRuns.Count
  keep_count = $keepIds.Count
  trim_count = $trimIds.Count
  target_final = $Keep
  estimated_reduction = $trimIds.Count
} | ConvertTo-Json -Depth 5

$summary | Set-Content ".agent/tmp/preflight-summary.json"

Write-Host "`n✅ Preflight complete"
Write-Host "  KeepSet: .agent/tmp/KEEPSET.txt ($($keepIds.Count) IDs)"
Write-Host "  TrimSet: .agent/tmp/TRIMSET.txt ($($trimIds.Count) IDs)"
Write-Host "  Summary: .agent/tmp/preflight-summary.json"
Write-Host "`nNext: Run sharded backfill (1-$Shards)"
Write-Host "  Example: pwsh BRAV/SCPT/run-archiver/backfill.ps1 -Shard 0 -Shards 8 -DryRun"

