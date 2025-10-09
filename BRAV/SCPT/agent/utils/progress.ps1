# utils/progress.ps1 - Enhanced progress utilities with EMA-based ETAs

. "$PSScriptRoot\terminal.ps1"
. "$PSScriptRoot\eta.ps1"
. "$PSScriptRoot\logging.ps1"

function Show-EnhancedProgress {
    param(
        [string]$Activity,
        [string]$Status,
        [int]$Current,
        [int]$Total,
        [string]$EmaKey = "",
        [int]$Id = 1,
        [string]$SubStatus = ""
    )
    
    if ($Total -le 0) {
        # Show spinner when total is unknown
        Write-Spinner -Message "$Activity - $Status" -Index $Current
        return
    }
    
    $percent = [Math]::Min(100, [Math]::Round(($Current / $Total) * 100))
    
    # Get EMA-based ETA if key provided
    $eta = 0
    if ($EmaKey) {
        $statusData = Get-StatusEmaData
        $emaValue = $statusData.ema[$EmaKey]
        if ($emaValue -and $emaValue -gt 0) {
            $remainingItems = $Total - $Current
            $eta = $emaValue * $remainingItems
        }
    }
    
    # Fallback to linear estimation
    if ($eta -eq 0 -and $Current -gt 0) {
        $elapsed = $Current
        $remaining = $Total - $Current
        $eta = ($elapsed / $Current) * $remaining
    }
    
    Write-ProgressBar -Title $Activity -Percent $percent -EtaSecs $eta -Status $SubStatus
}

function Update-EmaOnCompletion {
    param(
        [string]$EmaKey,
        [double]$ObservedSeconds
    )
    
    $statusPath = ".agent/status.json"
    if (-not (Test-Path $statusPath)) { return }
    
    try {
        $status = Get-Content $statusPath -Raw | ConvertFrom-Json
        if (-not $status.ema) { $status.ema = @{} }
        
        $prevEma = $status.ema[$EmaKey] ?? 0
        $newEma = & "$PSScriptRoot\eta.ps1" -ObservedSecs $ObservedSeconds -PrevEmaSecs $prevEma
        
        $status.ema[$EmaKey] = $newEma
        $status.updatedAt = (Get-Date).ToString("o")
        
        Write-RateLimitedJson -Path $statusPath -Data $status
    } catch {
        Write-Warning "Failed to update EMA: $($_.Exception.Message)"
    }
}

function Get-StatusEmaData {
    $statusPath = ".agent/status.json"
    if (-not (Test-Path $statusPath)) { 
        return @{ ema = @{} } 
    }
    
    try {
        return Get-Content $statusPath -Raw | ConvertFrom-Json
    } catch {
        return @{ ema = @{} }
    }
}

function Show-AdaptiveSleep {
    param(
        [int]$TargetSeconds,
        [datetime]$CycleStart,
        [string]$Reason = "Next cycle"
    )
    
    $elapsed = (Get-Date) - $CycleStart
    $sleepSeconds = [Math]::Max(5, $TargetSeconds - [int]$elapsed.TotalSeconds)
    
    if ($sleepSeconds -le 0) { return }
    
    Write-Colored -Message "[SLEEP] $Reason in $sleepSeconds seconds" -Color "yellow"
    
    for ($i = 0; $i -le ($sleepSeconds * 2); $i++) {
        $percent = ($i / ($sleepSeconds * 2)) * 100
        $remaining = [Math]::Max(0, $sleepSeconds - ($i * 0.5))
        
        $status = "$Reason in $([Math]::Round($remaining, 1))s"
        Write-ProgressBar -Title "Sleep" -Percent $percent -EtaSecs $remaining -Status $status
        Start-Sleep -Milliseconds 500
    }
    
    Write-Host ""
}

function Show-BudgetWarning {
    param(
        [int]$Current,
        [int]$Limit,
        [string]$Type = "files"
    )
    
    $percent = ($Current / $Limit) * 100
    
    if ($percent -ge 90) {
        Write-Colored -Message "⚠️  Approaching $Type budget: $Current/$Limit ($([Math]::Round($percent, 1))%)" -Color "red"
    } elseif ($percent -ge 75) {
        Write-Colored -Message "⚠️  Approaching $Type budget: $Current/$Limit ($([Math]::Round($percent, 1))%)" -Color "yellow"
    }
}

function Test-BudgetLimit {
    param(
        [int]$Current,
        [int]$Limit,
        [string]$Type = "files"
    )
    
    if ($Current -ge $Limit) {
        Write-Colored -Message "❌ $Type budget exceeded: $Current/$Limit" -Color "red"
        return $false
    }
    
    return $true
}
