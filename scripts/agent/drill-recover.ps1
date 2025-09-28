# scripts/agent/drill-recover.ps1 - Recovery drill for testing lock mechanisms

$ErrorActionPreference = "Stop"

function Write-DrillResult {
    param(
        [string]$Message,
        [bool]$Success = $true
    )
    
    $color = if ($Success) { "Green" } else { "Red" }
    $icon = if ($Success) { "✅" } else { "❌" }
    Write-Host "$icon $Message" -ForegroundColor $color
}

function Get-StatusState {
    try {
        $output = pnpm agent:status-premium -Json 2>$null
        $jsonStart = -1
        for ($i = 0; $i -lt $output.Count; $i++) {
            if ($output[$i] -match '^\s*\{') {
                $jsonStart = $i
                break
            }
        }
        
        if ($jsonStart -ge 0) {
            $cleanOutput = ($output | Select-Object -Skip $jsonStart) -join "`n"
        } else {
            $cleanOutput = $output -join "`n"
        }
        
        return $cleanOutput | ConvertFrom-Json
    } catch {
        return @{
            status = "error"
            lock = $false
            error = $_.Exception.Message
        }
    }
}

Write-Host "🚨 codex-local Recovery Drill" -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan

$when = Get-Date
Write-DrillResult -Message "Starting recovery drill at $when"

# Step 1: Pre-lock status
Write-Host "`n📊 Step 1: Capturing pre-lock status" -ForegroundColor Yellow
"DRILL: pre-lock status" | Add-Content TASKS.md
$preStatus = Get-StatusState
$preStatus | ConvertTo-Json -Depth 6 | Set-Content ".agent/_pre.json"

Write-DrillResult -Message "Pre-lock status: $($preStatus.status), locked: $($preStatus.lock)"

# Step 2: Apply lock
Write-Host "`n🔒 Step 2: Applying agent lock" -ForegroundColor Yellow
"DRILL: apply LOCK" | Add-Content TASKS.md
$lockReason = "drill $(Get-Date -Format o)"
$lockReason | Set-Content .agent/LOCK

Start-Sleep 3

# Step 3: Check locked status
Write-Host "`n🔍 Step 3: Verifying locked status" -ForegroundColor Yellow
$lockStatus = Get-StatusState
$lockStatus | ConvertTo-Json -Depth 6 | Set-Content ".agent/_lock.json"

$lockValid = $lockStatus.status -eq "locked" -and $lockStatus.lock -eq $true
Write-DrillResult -Message "Lock status: $($lockStatus.status), locked: $($lockStatus.lock)" -Success $lockValid

# Step 4: Remove lock
Write-Host "`n🔓 Step 4: Removing agent lock" -ForegroundColor Yellow
Remove-Item .agent/LOCK -ErrorAction SilentlyContinue
Start-Sleep 3

# Step 5: Check post-lock status
Write-Host "`n📊 Step 5: Verifying post-lock status" -ForegroundColor Yellow
$postStatus = Get-StatusState
$postStatus | ConvertTo-Json -Depth 6 | Set-Content ".agent/_post.json"

$postValid = $postStatus.status -ne "locked" -and $postStatus.lock -eq $false
Write-DrillResult -Message "Post-lock status: $($postStatus.status), locked: $($postStatus.lock)" -Success $postValid

# Step 6: Analysis
Write-Host "`n📈 Step 6: Drill Analysis" -ForegroundColor Yellow

$analysis = @{
    preLockStatus = $preStatus.status
    lockApplied = $lockValid
    postLockStatus = $postStatus.status
    transitionClean = $postValid
    drillSuccess = $lockValid -and $postValid
}

Write-Host "Pre-lock: $($analysis.preLockStatus)" -ForegroundColor Gray
Write-Host "Lock applied: $($analysis.lockApplied)" -ForegroundColor $(if ($analysis.lockApplied) { "Green" } else { "Red" })
Write-Host "Post-lock: $($analysis.postLockStatus)" -ForegroundColor Gray
Write-Host "Transition clean: $($analysis.transitionClean)" -ForegroundColor $(if ($analysis.transitionClean) { "Green" } else { "Red" })

# Final result
$overallSuccess = $analysis.drillSuccess
Write-Host "`n🎯 Drill Result: " -NoNewline
Write-Host $(if ($overallSuccess) { "PASS" } else { "FAIL" }) -ForegroundColor $(if ($overallSuccess) { "Green" } else { "Red" })

# Log completion
"DRILL completed at $when - Result: $(if ($overallSuccess) { 'PASS' } else { 'FAIL' })" | Add-Content TASKS.md

# Cleanup
Write-Host "`n🧹 Cleanup: Removing temporary files" -ForegroundColor Yellow
Remove-Item ".agent/_pre.json" -ErrorAction SilentlyContinue
Remove-Item ".agent/_lock.json" -ErrorAction SilentlyContinue
Remove-Item ".agent/_post.json" -ErrorAction SilentlyContinue

Write-DrillResult -Message "Recovery drill completed" -Success $overallSuccess

exit $(if ($overallSuccess) { 0 } else { 1 })
