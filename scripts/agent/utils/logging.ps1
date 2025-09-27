# utils/logging.ps1 - Rate-limited logging utilities

$global:lastWriteAt = $null

function Write-RateLimitedLog {
    param(
        [string]$Path,
        [string]$Content,
        [int]$MaxWritesPerSecond = 1
    )
    
    # Check if we should throttle this write
    $now = Get-Date
    if ($global:lastWriteAt -and (($now - $global:lastWriteAt).TotalSeconds -lt (1 / $MaxWritesPerSecond))) {
        return
    }
    
    try {
        Add-Content -Path $Path -Value $Content -Encoding UTF8
        $global:lastWriteAt = $now
    } catch {
        Write-Warning "Failed to write to log: $($_.Exception.Message)"
    }
}

function Write-RateLimitedJson {
    param(
        [string]$Path,
        [object]$Data,
        [int]$MaxWritesPerSecond = 1
    )
    
    # Check if we should throttle this write
    $now = Get-Date
    if ($global:lastWriteAt -and (($now - $global:lastWriteAt).TotalSeconds -lt (1 / $MaxWritesPerSecond))) {
        return
    }
    
    try {
        $json = $Data | ConvertTo-Json -Depth 6
        Set-Content -Path $Path -Value $json -Encoding UTF8
        $global:lastWriteAt = $now
    } catch {
        Write-Warning "Failed to write JSON: $($_.Exception.Message)"
    }
}

function Add-TaskLog {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = "[$timestamp] [$Level] $Message"
    
    Write-RateLimitedLog -Path "TASKS.md" -Content $entry
}

function Update-StatusWithEma {
    param(
        [string]$Section,
        [bool]$Ok,
        [string]$Detail,
        [hashtable]$EmaData = @{}
    )
    
    $statusPath = ".agent/status.json"
    $now = (Get-Date).ToString("o")
    
    # Load existing status
    $status = @{
        version = 1
        updatedAt = $now
        sections = @{}
        ema = @{}
    }
    
    if (Test-Path $statusPath) {
        try {
            $existing = Get-Content $statusPath -Raw | ConvertFrom-Json
            $status.sections = $existing.sections
            $status.ema = $existing.ema
        } catch {
            Write-Warning "Failed to load existing status, creating new"
        }
    }
    
    # Update section
    $status.sections[$Section] = @{
        ok = $Ok
        detail = $Detail
        ts = $now
    }
    
    # Update EMA data
    foreach ($key in $EmaData.Keys) {
        $status.ema[$key] = $EmaData[$key]
    }
    
    $status.updatedAt = $now
    
    # Write with rate limiting
    Write-RateLimitedJson -Path $statusPath -Data $status
}
