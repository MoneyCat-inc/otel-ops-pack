# Shared Progress Indicators Module
# Project-wide standard for progress bars, spinners, and time estimates

# Global variables for spinner
$global:spinnerChars = @('|', '/', '-', '\')
$global:spinnerIndex = 0

function Write-ProgressBar {
    param(
        [int]$Percent,
        [string]$Activity,
        [string]$Status,
        [int]$SecondsRemaining = 0,
        [switch]$ShowSpinner = $false
    )
    
    $barLength = 30
    $filledLength = [math]::Floor($barLength * $Percent / 100)
    $bar = "=" * $filledLength + "-" * ($barLength - $filledLength)
    
    $timeStr = if ($SecondsRemaining -gt 0) { " (ETA: ${SecondsRemaining}s)" } else { "" }
    $spinner = if ($ShowSpinner) { " $($global:spinnerChars[$global:spinnerIndex])" } else { "" }
    
    Write-Host "`r[$bar] $Percent% - $Activity - $Status$timeStr$spinner" -NoNewline -ForegroundColor Cyan
}

function Write-Spinner {
    param(
        [string]$Message,
        [string]$Color = "Cyan"
    )
    
    $global:spinnerIndex = ($global:spinnerIndex + 1) % $global:spinnerChars.Length
    $spinner = $global:spinnerChars[$global:spinnerIndex]
    Write-Host "`r$spinner $Message" -NoNewline -ForegroundColor $Color
}

function Start-SpinnerJob {
    param(
        [string]$Message,
        [int]$UpdateIntervalMs = 100
    )
    
    $job = Start-Job -ScriptBlock {
        param($Message, $UpdateIntervalMs)
        $spinnerChars = @('|', '/', '-', '\')
        $index = 0
        while ($true) {
            $index = ($index + 1) % $spinnerChars.Length
            $spinner = $spinnerChars[$index]
            Write-Host "`r$spinner $Message" -NoNewline -ForegroundColor Cyan
            Start-Sleep -Milliseconds $UpdateIntervalMs
        }
    } -ArgumentList $Message, $UpdateIntervalMs
    
    return $job
}

function Stop-SpinnerJob {
    param([System.Management.Automation.Job]$Job)
    
    if ($Job) {
        Stop-Job $Job -ErrorAction SilentlyContinue
        Remove-Job $Job -ErrorAction SilentlyContinue
        Write-Host "`r" -NoNewline
    }
}

function Start-TimedOperation {
    param(
        [string]$Operation,
        [scriptblock]$ScriptBlock,
        [int]$EstimatedSeconds = 5,
        [switch]$ShowSpinner = $false
    )
    
    $startTime = Get-Date
    Write-Host "`n[START] $Operation" -ForegroundColor Yellow
    Write-Host "Estimated time: $EstimatedSeconds seconds" -ForegroundColor Gray
    
    # Start spinner if requested
    $spinnerJob = $null
    if ($ShowSpinner) {
        $spinnerJob = Start-SpinnerJob -Message "$Operation in progress..." -UpdateIntervalMs 150
    }
    
    try {
        $result = & $ScriptBlock
        $endTime = Get-Date
        $actualSeconds = ($endTime - $startTime).TotalSeconds
        
        # Stop spinner
        Stop-SpinnerJob -Job $spinnerJob
        
        Write-Host "`n[DONE] $Operation" -ForegroundColor Green
        Write-Host "Actual time: $([math]::Round($actualSeconds, 1)) seconds" -ForegroundColor Gray
        
        return $result
    }
    catch {
        # Stop spinner on error
        Stop-SpinnerJob -Job $spinnerJob
        Write-Host "`n[FAIL] $Operation" -ForegroundColor Red
        throw
    }
}

function Start-FileOperation {
    param(
        [string]$Operation,
        [array]$Items,
        [scriptblock]$ProcessItem,
        [int]$EstimatedSecondsPerItem = 1
    )
    
    $totalItems = $Items.Count
    $estimatedSeconds = [math]::Max(3, $totalItems * $EstimatedSecondsPerItem)
    
    Write-Host "`n[START] $Operation" -ForegroundColor Yellow
    Write-Host "Processing $totalItems items, estimated time: $estimatedSeconds seconds" -ForegroundColor Gray
    
    $results = @()
    $errors = @()
    
    for ($i = 0; $i -lt $totalItems; $i++) {
        $item = $Items[$i]
        $percent = [math]::Floor((($i + 1) / $totalItems) * 100)
        $remaining = [math]::Max(0, $estimatedSeconds - (($i / $totalItems) * $estimatedSeconds))
        
        try {
            $result = & $ProcessItem $item $i
            $results += $result
            Write-Host "`n  [OK] Processed: $item" -ForegroundColor Green
        }
        catch {
            $errors += "Failed to process $item`: $($_.Exception.Message)"
            Write-Host "`n  [FAIL] Failed: $item" -ForegroundColor Red
        }
        
        # Update progress
        Write-ProgressBar -Percent $percent -Activity $Operation -Status "Item $($i + 1)/$totalItems" -SecondsRemaining $remaining -ShowSpinner
    }
    
    Write-Host "`n[DONE] $Operation" -ForegroundColor Green
    Write-Host "Processed: $($results.Count)/$totalItems items" -ForegroundColor Gray
    if ($errors.Count -gt 0) {
        Write-Host "Errors: $($errors.Count)" -ForegroundColor Red
    }
    
    return @{
        Results = $results
        Errors = $errors
    }
}

function Start-NetworkOperation {
    param(
        [string]$Operation,
        [string]$Url,
        [scriptblock]$NetworkCall,
        [int]$EstimatedSeconds = 10
    )
    
    Write-Host "`n[START] $Operation" -ForegroundColor Yellow
    Write-Host "URL: $Url" -ForegroundColor Gray
    Write-Host "Estimated time: $EstimatedSeconds seconds" -ForegroundColor Gray
    
    $spinnerJob = Start-SpinnerJob -Message "$Operation in progress..." -UpdateIntervalMs 150
    
    try {
        $result = & $NetworkCall
        Stop-SpinnerJob -Job $spinnerJob
        Write-Host "`n[OK] $Operation completed" -ForegroundColor Green
        return $result
    }
    catch {
        Stop-SpinnerJob -Job $spinnerJob
        Write-Host "`n[FAIL] $Operation failed" -ForegroundColor Red
        throw
    }
}

# Export functions for use in other scripts
if ($null -ne $MyInvocation.MyCommand.Module) {
    Export-ModuleMember -Function Write-ProgressBar, Write-Spinner, Start-SpinnerJob, Stop-SpinnerJob, Start-TimedOperation, Start-FileOperation, Start-NetworkOperation
}

