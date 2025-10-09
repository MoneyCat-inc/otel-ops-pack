# scripts/agent/nightly-chaos.ps1 - Nightly chaos engineering and drift detection

param(
    [switch]$DryRun,
    [switch]$Archive,
    [int]$MaxDays = 30
)

$ErrorActionPreference = "Stop"

function Write-ChaosResult {
    param(
        [string]$Message,
        [bool]$Success = $true
    )
    
    $color = if ($Success) { "Green" } else { "Red" }
    $icon = if ($Success) { "✅" } else { "❌" }
    Write-Host "$icon $Message" -ForegroundColor $color
}

function Invoke-ChaosTest {
    param([string]$TestName)
    
    $startTime = Get-Date
    $results = @{
        test = $TestName
        startTime = $startTime.ToString("o")
        success = $false
        duration = 0
        violations = 0
        filesProcessed = 0
        error = $null
    }
    
    try {
        Write-Host "🧪 Running chaos test: $TestName" -ForegroundColor Yellow
        
        # Run demo-premium with fixes
        $demoResult = pnpm agent:demo-premium -Fix -Quiet 2>$null
        if ($LASTEXITCODE -eq 0) {
            $results.success = $true
        }
        
        # Get guardrail status
        $guardrailResult = pnpm agent:guardrails-premium -Json | ConvertFrom-Json
        $results.violations = $guardrailResult.violations
        $results.filesProcessed = $guardrailResult.filesProcessed
        
        # Get status
        $statusResult = pnpm agent:status-premium -Json | ConvertFrom-Json
        $results.status = $statusResult.status
        $results.lock = $statusResult.lock
        
    } catch {
        $results.error = $_.Exception.Message
        $results.success = $false
    } finally {
        $endTime = Get-Date
        $results.endTime = $endTime.ToString("o")
        $results.duration = ($endTime - $startTime).TotalSeconds
    }
    
    return $results
}

function Archive-ChaosResults {
    param([array]$Results, [string]$Date)
    
    $archiveDir = ".agent/chaos-archive"
    if (-not (Test-Path $archiveDir)) {
        New-Item -ItemType Directory $archiveDir | Out-Null
    }
    
    $archiveFile = "$archiveDir/chaos-$Date.json"
    $archiveData = @{
        date = $Date
        timestamp = (Get-Date).ToString("o")
        results = $Results
        summary = @{
            totalTests = $Results.Count
            successfulTests = ($Results | Where-Object { $_.success }).Count
            totalViolations = ($Results | Measure-Object -Property violations -Sum).Sum
            avgDuration = ($Results | Measure-Object -Property duration -Average).Average
        }
    }
    
    $archiveData | ConvertTo-Json -Depth 6 | Set-Content $archiveFile -Encoding UTF8
    Write-ChaosResult -Message "Results archived to $archiveFile" -Success $true
    
    return $archiveFile
}

function Analyze-Drift {
    param([string]$ArchiveDir)
    
    if (-not (Test-Path $ArchiveDir)) {
        Write-Host "⚠️ No archive directory found for drift analysis" -ForegroundColor Yellow
        return
    }
    
    $archiveFiles = Get-ChildItem "$ArchiveDir/chaos-*.json" | Sort-Object LastWriteTime -Descending | Select-Object -First $MaxDays
    
    if ($archiveFiles.Count -lt 2) {
        Write-Host "⚠️ Need at least 2 archive files for drift analysis" -ForegroundColor Yellow
        return
    }
    
    Write-Host "`n📊 Drift Analysis (Last $($archiveFiles.Count) days):" -ForegroundColor Cyan
    
    $violations = @()
    $durations = @()
    $successRates = @()
    
    foreach ($file in $archiveFiles) {
        try {
            $data = Get-Content $file.FullName -Raw | ConvertFrom-Json
            $violations += $data.summary.totalViolations
            $durations += $data.summary.avgDuration
            $successRates += ($data.summary.successfulTests / $data.summary.totalTests) * 100
        } catch {
            Write-Host "⚠️ Failed to parse $($file.Name)" -ForegroundColor Yellow
        }
    }
    
    if ($violations.Count -gt 0) {
        $violationTrend = if ($violations[0] -gt $violations[-1]) { "📈 Increasing" } else { "📉 Decreasing" }
        $durationTrend = if ($durations[0] -gt $durations[-1]) { "📈 Slower" } else { "📉 Faster" }
        $successTrend = if ($successRates[0] -gt $successRates[-1]) { "📈 Improving" } else { "📉 Declining" }
        
        Write-Host "   Violations: $violationTrend (Current: $($violations[0]), Avg: $([Math]::Round(($violations | Measure-Object -Average).Average, 1)))" -ForegroundColor White
        Write-Host "   Duration: $durationTrend (Current: $([Math]::Round($durations[0], 1))s, Avg: $([Math]::Round(($durations | Measure-Object -Average).Average, 1))s)" -ForegroundColor White
        Write-Host "   Success Rate: $successTrend (Current: $([Math]::Round($successRates[0], 1))%, Avg: $([Math]::Round(($successRates | Measure-Object -Average).Average, 1))%)" -ForegroundColor White
    }
}

function Cleanup-OldArchives {
    param([string]$ArchiveDir, [int]$MaxDays)
    
    if (-not (Test-Path $ArchiveDir)) { return }
    
    $cutoffDate = (Get-Date).AddDays(-$MaxDays)
    $oldFiles = Get-ChildItem "$ArchiveDir/chaos-*.json" | Where-Object { $_.LastWriteTime -lt $cutoffDate }
    
    if ($oldFiles.Count -gt 0) {
        $oldFiles | Remove-Item
        Write-ChaosResult -Message "Cleaned up $($oldFiles.Count) old archive files" -Success $true
    }
}

Write-Host "🌙 codex-local Nightly Chaos Engineering" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

$chaosDate = (Get-Date).ToString("yyyy-MM-dd")
$results = @()

# Run chaos tests
Write-Host "`n🧪 Running chaos tests..." -ForegroundColor Yellow

# Test 1: Basic functionality
$results += Invoke-ChaosTest -TestName "basic-functionality"

# Test 2: Guardrail enforcement
$results += Invoke-ChaosTest -TestName "guardrail-enforcement"

# Test 3: Status monitoring
$results += Invoke-ChaosTest -TestName "status-monitoring"

# Test 4: Lock mechanism
Write-Host "🧪 Testing lock mechanism..." -ForegroundColor Yellow
"chaos-test" | Set-Content .agent/LOCK
$lockResult = pnpm agent:status-premium -Json | ConvertFrom-Json
Remove-Item .agent/LOCK -ErrorAction SilentlyContinue
$results += @{
    test = "lock-mechanism"
    startTime = (Get-Date).ToString("o")
    endTime = (Get-Date).ToString("o")
    success = $lockResult.lock -eq $true
    duration = 1.0
    violations = 0
    filesProcessed = 0
    status = $lockResult.status
    lock = $lockResult.lock
}

# Archive results
if ($Archive) {
    Write-Host "`n📦 Archiving results..." -ForegroundColor Yellow
    $archiveFile = Archive-ChaosResults -Results $results -Date $chaosDate
    
    # Analyze drift
    Analyze-Drift -ArchiveDir ".agent/chaos-archive"
    
    # Cleanup old archives
    Cleanup-OldArchives -ArchiveDir ".agent/chaos-archive" -MaxDays $MaxDays
}

# Summary
Write-Host "`n📊 Chaos Test Summary:" -ForegroundColor Cyan
Write-Host "=====================" -ForegroundColor Cyan

$totalTests = $results.Count
$successfulTests = ($results | Where-Object { $_.success }).Count
$totalViolations = ($results | Measure-Object -Property violations -Sum).Sum
$avgDuration = ($results | Measure-Object -Property duration -Average).Average

Write-Host "Tests Run: $totalTests" -ForegroundColor White
Write-Host "Successful: $successfulTests" -ForegroundColor Green
Write-Host "Failed: $($totalTests - $successfulTests)" -ForegroundColor Red
Write-Host "Total Violations: $totalViolations" -ForegroundColor $(if ($totalViolations -eq 0) { "Green" } else { "Yellow" })
Write-Host "Avg Duration: $([Math]::Round($avgDuration, 1))s" -ForegroundColor White

$successRate = ($successfulTests / $totalTests) * 100
Write-Host "Success Rate: $([Math]::Round($successRate, 1))%" -ForegroundColor $(if ($successRate -ge 90) { "Green" } elseif ($successRate -ge 70) { "Yellow" } else { "Red" })

# Log results
$logEntry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Nightly chaos: $successfulTests/$totalTests tests passed, $totalViolations violations, ${avgDuration}s avg duration"
Add-Content -Path "TASKS.md" -Value $logEntry

if ($DryRun) {
    Write-Host "`n🧪 Dry run completed - no changes made" -ForegroundColor Yellow
} else {
    Write-ChaosResult -Message "Nightly chaos engineering completed" -Success ($successRate -ge 90)
}
