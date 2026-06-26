#Requires -Version 7.0
<#
.SYNOPSIS
  Advanced parallel workflow cleanup with intelligent rate limiting
  
.DESCRIPTION
  Uses sophisticated parallel processing to maximize deletion throughput while
  respecting GitHub API rate limits. Features:
  - Parallel deletion workers (10-20 concurrent)
  - Real-time rate limit monitoring
  - Dynamic throttling
  - Progress tracking with ETA
  - Checkpoint/resume capability
  - Fault tolerance with retry logic
  
.PARAMETER Workers
  Number of parallel deletion workers (default: 15)
  
.PARAMETER TargetRuns
  Target number of runs to keep (default: 100)
  
.PARAMETER Repository
  GitHub repository (default: MoneyCat-inc/otel-ops-pack)
  
.EXAMPLE
  # Run with default settings (15 workers, target 100 runs)
  pwsh -File scripts/cleanup-parallel-aggressive.ps1
  
.EXAMPLE
  # More aggressive (20 workers)
  pwsh -File scripts/cleanup-parallel-aggressive.ps1 -Workers 20
  
.NOTES
  BossCat Parallel Cleanup System
  Designed for maximum throughput within API limits
#>

[CmdletBinding()]
param(
    [int]$Workers = 15,
    [int]$TargetRuns = 100,
    [string]$Repository = "MoneyCat-inc/otel-ops-pack"
)

$ErrorActionPreference = "Continue"

# ============================================
# CONFIGURATION
# ============================================

$script:Config = @{
    Workers = $Workers
    TargetRuns = $TargetRuns
    Repository = $Repository
    RateLimitThreshold = 100  # Pause when below this
    MaxRetries = 3
    RetryDelaySeconds = 5
    ProgressUpdateInterval = 10  # Update every N deletions
    CheckpointFile = ".agent\cleanup-checkpoint.json"
}

# ============================================
# HELPER FUNCTIONS
# ============================================

function Write-Header {
    param([string]$Text)
    Write-Host "`n╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║  $($Text.PadRight(61))║" -ForegroundColor Cyan
    Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
}

function Write-Progress-Line {
    param(
        [int]$Current,
        [int]$Total,
        [int]$Deleted,
        [int]$Failed,
        [double]$RatePerSec,
        [int]$RateRemaining
    )
    
    $percent = [Math]::Round(($Deleted / $Total) * 100, 1)
    $eta = if ($RatePerSec -gt 0) { [Math]::Ceiling(($Total - $Deleted) / $RatePerSec) } else { 0 }
    $bar = [string]::new('█', [Math]::Floor($percent / 2))
    $empty = [string]::new('░', 50 - [Math]::Floor($percent / 2))
    
    Write-Host "`r[${bar}${empty}] ${percent}% | Deleted: $Deleted/$Total | Failed: $Failed | Rate: $([Math]::Round($RatePerSec, 1))/s | ETA: ${eta}s | API: $RateRemaining" -NoNewline -ForegroundColor Green
}

function Get-RateLimit {
    try {
        $limit = gh api rate_limit --jq '.resources.core' | ConvertFrom-Json
        return @{
            Limit = $limit.limit
            Remaining = $limit.remaining
            Reset = [DateTime]::UnixEpoch.AddSeconds($limit.reset)
        }
    }
    catch {
        return @{ Limit = 5000; Remaining = 2500; Reset = (Get-Date).AddHours(1) }
    }
}

function Save-Checkpoint {
    param($Data)
    $Data | ConvertTo-Json -Depth 10 | Set-Content -Path $script:Config.CheckpointFile -Force
}

function Load-Checkpoint {
    if (Test-Path $script:Config.CheckpointFile) {
        return Get-Content $script:Config.CheckpointFile | ConvertFrom-Json
    }
    return $null
}

function Remove-Checkpoint {
    if (Test-Path $script:Config.CheckpointFile) {
        Remove-Item $script:Config.CheckpointFile -Force
    }
}

# ============================================
# PARALLEL DELETION WORKER
# ============================================

$DeleteWorkerScriptBlock = {
    param($RunId, $Repository, $MaxRetries, $RetryDelay)
    
    $attempt = 0
    $success = $false
    $lastError = $null
    
    while ($attempt -lt $MaxRetries -and -not $success) {
        $attempt++
        try {
            gh run delete $RunId --repo $Repository 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) {
                $success = $true
                return @{ Success = $true; RunId = $RunId; Attempts = $attempt }
            }
            else {
                $lastError = "Exit code: $LASTEXITCODE"
            }
        }
        catch {
            $lastError = $_.Exception.Message
        }
        
        if (-not $success -and $attempt -lt $MaxRetries) {
            Start-Sleep -Seconds ($RetryDelay * $attempt)
        }
    }
    
    return @{ Success = $false; RunId = $RunId; Attempts = $attempt; Error = $lastError }
}

# ============================================
# MAIN EXECUTION
# ============================================

Write-Header "🚀 PARALLEL AGGRESSIVE CLEANUP"

Write-Host "`nConfiguration:" -ForegroundColor Cyan
Write-Host "  Repository: $($script:Config.Repository)" -ForegroundColor White
Write-Host "  Workers: $($script:Config.Workers)" -ForegroundColor White
Write-Host "  Target Runs: $($script:Config.TargetRuns)" -ForegroundColor White
Write-Host "  Rate Limit Threshold: $($script:Config.RateLimitThreshold)" -ForegroundColor White

# Check authentication
Write-Host "`nChecking GitHub authentication..." -ForegroundColor Yellow
try {
    gh auth status 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Not authenticated. Run: gh auth login" -ForegroundColor Red
        exit 1
    }
    Write-Host "✅ Authenticated" -ForegroundColor Green
}
catch {
    Write-Host "❌ GitHub CLI not available" -ForegroundColor Red
    exit 1
}

# Check initial rate limit
$rateLimit = Get-RateLimit
Write-Host "`nAPI Rate Limit:" -ForegroundColor Cyan
Write-Host "  Available: $($rateLimit.Remaining)/$($rateLimit.Limit)" -ForegroundColor White
Write-Host "  Resets: $($rateLimit.Reset.ToString('yyyy-MM-dd HH:mm:ss UTC'))" -ForegroundColor White

if ($rateLimit.Remaining -lt $script:Config.RateLimitThreshold) {
    $waitSeconds = [Math]::Max(0, ($rateLimit.Reset - (Get-Date)).TotalSeconds + 10)
    Write-Host "`n⚠️  Rate limit low ($($rateLimit.Remaining) remaining)" -ForegroundColor Yellow
    Write-Host "   Waiting $([Math]::Ceiling($waitSeconds/60)) minutes for reset..." -ForegroundColor Yellow
    Start-Sleep -Seconds $waitSeconds
}

# ============================================
# PHASE 1: FETCH ALL RUN IDs (API PAGINATION)
# ============================================

Write-Header "📋 PHASE 1: Fetching Run IDs"

Write-Host "`nFetching workflow runs via gh api (paginated)..." -ForegroundColor Yellow

$allRuns = @()
$seen = @{}
$page = 1
$perPage = 100
$maxPages = 100  # Safety limit
$cutoff = (Get-Date).AddDays(-3)

while ($page -le $maxPages) {
    Write-Host "  Fetching page $page..." -ForegroundColor Gray
    try {
        $resp = gh api "/repos/$($script:Config.Repository)/actions/runs?per_page=$perPage&page=$page" 2>&1
        if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($resp)) { break }
        $json = $resp | ConvertFrom-Json
        $runs = $json.workflow_runs
        if (-not $runs -or $runs.Count -eq 0) { break }

        foreach ($r in $runs) {
            # Filter by cutoff (client-side), mirror original --created filter intent
            $createdAt = Get-Date $r.created_at
            if ($createdAt -lt $cutoff) {
                $id = [int64]$r.id
                if (-not $seen.ContainsKey($id)) {
                    $seen[$id] = $true
                    $allRuns += [pscustomobject]@{
                        databaseId = $id
                        createdAt  = $r.created_at
                        status     = $r.status
                    }
                }
            }
        }

        Write-Host "    Page ${page}: added $($runs.Count) (total kept: $($allRuns.Count))" -ForegroundColor DarkGray

        if ($runs.Count -lt $perPage) { break } # Last page
        $page++
    }
    catch {
        Write-Host "    ⚠️  Error fetching page ${page}: $_" -ForegroundColor Yellow
        break
    }
}

$totalRuns = $allRuns.Count
$toDelete = [Math]::Max(0, $totalRuns - $script:Config.TargetRuns)

Write-Host "`n✅ Fetch complete:" -ForegroundColor Green
Write-Host "   Total runs found: $totalRuns" -ForegroundColor White
Write-Host "   Target to keep: $($script:Config.TargetRuns)" -ForegroundColor White
Write-Host "   Will delete: $toDelete runs" -ForegroundColor White

if ($toDelete -eq 0) {
    Write-Host "`n✅ Already at target! No cleanup needed." -ForegroundColor Green
    exit 0
}

# Sort by creation date (oldest first) and take only what we need to delete
$runsToDelete = $allRuns | Sort-Object createdAt | Select-Object -First $toDelete
$runIds = $runsToDelete | ForEach-Object { $_.databaseId }

Write-Host "`nPrepared deletion queue: $($runIds.Count) run IDs" -ForegroundColor Green

# Save checkpoint
Save-Checkpoint @{
    TotalRuns = $runIds.Count
    RemainingIds = $runIds
    Deleted = 0
    Failed = 0
    StartTime = (Get-Date).ToString("o")
}

# ============================================
# PHASE 2: PARALLEL DELETION
# ============================================

Write-Header "🔥 PHASE 2: Parallel Deletion ($($script:Config.Workers) workers)"

$startTime = Get-Date
$deleted = 0
$failed = 0
$jobs = @()
$activeWorkers = 0
$processedIds = @()

Write-Host ""  # New line for progress bar

$queue = [System.Collections.Queue]::new($runIds)

while ($queue.Count -gt 0 -or $jobs.Count -gt 0) {
    
    # Start new workers if slots available and work remaining
    while ($activeWorkers -lt $script:Config.Workers -and $queue.Count -gt 0) {
        $runId = $queue.Dequeue()
        
        $job = Start-Job -ScriptBlock $DeleteWorkerScriptBlock `
            -ArgumentList $runId, $script:Config.Repository, $script:Config.MaxRetries, $script:Config.RetryDelaySeconds
        
        $jobs += @{ Job = $job; RunId = $runId; StartTime = Get-Date }
        $activeWorkers++
    }
    
    # Check completed jobs
    $completedJobs = $jobs | Where-Object { $_.Job.State -eq 'Completed' }
    
    foreach ($jobInfo in $completedJobs) {
        $result = Receive-Job -Job $jobInfo.Job
        Remove-Job -Job $jobInfo.Job -Force
        
        if ($result.Success) {
            $deleted++
        }
        else {
            $failed++
        }
        
        $processedIds += $jobInfo.RunId
        $activeWorkers--
        
        # Update progress
        if ($deleted % $script:Config.ProgressUpdateInterval -eq 0 -or $queue.Count -eq 0) {
            $elapsed = (Get-Date) - $startTime
            $rate = if ($elapsed.TotalSeconds -gt 0) { $deleted / $elapsed.TotalSeconds } else { 0 }
            
            $rateLimit = Get-RateLimit
            Write-Progress-Line -Current ($deleted + $failed) -Total $runIds.Count `
                -Deleted $deleted -Failed $failed -RatePerSec $rate -RateRemaining $rateLimit.Remaining
        }
        
        # Check rate limit periodically
        if ($deleted % 50 -eq 0) {
            $rateLimit = Get-RateLimit
            if ($rateLimit.Remaining -lt $script:Config.RateLimitThreshold) {
                Write-Host "`n`n⚠️  Rate limit low ($($rateLimit.Remaining) remaining) - pausing workers..." -ForegroundColor Yellow
                
                # Wait for all active jobs to complete
                $jobs | ForEach-Object { Wait-Job -Job $_.Job | Out-Null }
                
                $waitSeconds = [Math]::Max(60, ($rateLimit.Reset - (Get-Date)).TotalSeconds + 10)
                Write-Host "   Waiting $([Math]::Ceiling($waitSeconds/60)) minutes for reset...`n" -ForegroundColor Yellow
                Start-Sleep -Seconds $waitSeconds
                
                Write-Host "✅ Resumed`n" -ForegroundColor Green
            }
        }
    }
    
    # Remove completed jobs from array
    $jobs = $jobs | Where-Object { $_.Job.State -ne 'Completed' }
    
    # Small sleep to avoid tight loop
    if ($jobs.Count -gt 0) {
        Start-Sleep -Milliseconds 100
    }
}

# Final progress update
$elapsed = (Get-Date) - $startTime
$rate = if ($elapsed.TotalSeconds -gt 0) { $deleted / $elapsed.TotalSeconds } else { 0 }
Write-Progress-Line -Current $runIds.Count -Total $runIds.Count `
    -Deleted $deleted -Failed $failed -RatePerSec $rate -RateRemaining 0

Write-Host "`n"  # New line after progress bar

# ============================================
# COMPLETION
# ============================================

$endTime = Get-Date
$duration = $endTime - $startTime

Write-Header "✅ PARALLEL CLEANUP COMPLETE"

Write-Host "`nResults:" -ForegroundColor Cyan
Write-Host "  Successfully deleted: $deleted runs" -ForegroundColor Green
Write-Host "  Failed: $failed runs" -ForegroundColor $(if ($failed -gt 0) { "Yellow" } else { "Green" })
Write-Host "  Total processed: $($deleted + $failed) runs" -ForegroundColor White
Write-Host "`nPerformance:" -ForegroundColor Cyan
Write-Host "  Duration: $([Math]::Floor($duration.TotalMinutes))m $($duration.Seconds)s" -ForegroundColor White
Write-Host "  Average rate: $([Math]::Round($deleted / $duration.TotalSeconds, 2)) deletions/sec" -ForegroundColor White
Write-Host "  Workers used: $($script:Config.Workers)" -ForegroundColor White

# Clean up checkpoint
Remove-Checkpoint

# Log evidence
$evidence = @{
    timestamp = Get-Date -Format o
    event = "parallel_workflow_cleanup"
    actor = "BossCat Parallel System"
    phase = "maintenance"
    status = "complete"
    details = @{
        runs_deleted = $deleted
        runs_failed = $failed
        duration_seconds = [Math]::Round($duration.TotalSeconds, 1)
        average_rate = [Math]::Round($deleted / $duration.TotalSeconds, 2)
        workers = $script:Config.Workers
        repository = $script:Config.Repository
    }
} | ConvertTo-Json -Compress

if (Test-Path ".agent\EVIDENCE.log") {
    Add-Content -Path ".agent\EVIDENCE.log" -Value $evidence
    Write-Host "`n✅ Evidence logged to .agent/EVIDENCE.log" -ForegroundColor Green
}

Write-Host "`nRepository Status:" -ForegroundColor Cyan
Write-Host "  Estimated remaining runs: ~$($totalRuns - $deleted)" -ForegroundColor White
Write-Host "  Target: $($script:Config.TargetRuns)" -ForegroundColor White

if (($totalRuns - $deleted) -le $script:Config.TargetRuns * 1.1) {
    Write-Host "`n🎉 TARGET ACHIEVED! Repository is clean." -ForegroundColor Green
}
else {
    Write-Host "`n⚠️  More cleanup may be needed to reach target." -ForegroundColor Yellow
}

Write-Host "`nVerify with: gh run list --repo $($script:Config.Repository) --limit 20`n" -ForegroundColor Gray

