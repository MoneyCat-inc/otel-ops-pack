# scripts/agent/status-badge.ps1 - Parse JSON output and generate status badge

param(
    [switch]$Json,
    [switch]$Markdown,
    [string]$OutputFile = ""
)

$ErrorActionPreference = "Stop"

function Get-StatusBadge {
    param([object]$StatusData)
    
    $badge = @{
        color = "red"
        status = "unknown"
        message = "Unknown status"
    }
    
    if ($StatusData.lock) {
        $badge.color = "red"
        $badge.status = "locked"
        $badge.message = "Agent Locked"
    } elseif ($StatusData.status -eq "active") {
        $violations = $StatusData.metrics.violationsFound ?? 0
        
        if ($violations -eq 0) {
            $badge.color = "green"
            $badge.status = "healthy"
            $badge.message = "All Systems Green"
        } elseif ($violations -lt 5) {
            $badge.color = "yellow"
            $badge.status = "warning"
            $badge.message = "$violations violations"
        } else {
            $badge.color = "red"
            $badge.status = "critical"
            $badge.message = "$violations violations"
        }
    } else {
        $badge.color = "red"
        $badge.status = "error"
        $badge.message = "Agent Error"
    }
    
    return $badge
}

function Get-ShieldsBadge {
    param([hashtable]$Badge)
    
    $encodedMessage = [System.Web.HttpUtility]::UrlEncode($Badge.message)
    return "https://img.shields.io/badge/codex--local-$($Badge.status)-$($Badge.color).svg?label=$($Badge.status)&message=$encodedMessage"
}

function Get-MarkdownBadge {
    param([hashtable]$Badge, [string]$ShieldsUrl)
    
    return "![codex-local status]($ShieldsUrl)"
}

# Get status data
try {
    $statusOutput = pnpm agent:status-premium -Json 2>$null
    # Find the JSON part - look for the first { and take everything from there
    $jsonStart = -1
    for ($i = 0; $i -lt $statusOutput.Count; $i++) {
        if ($statusOutput[$i] -match '^\s*\{') {
            $jsonStart = $i
            break
        }
    }
    
    if ($jsonStart -ge 0) {
        $cleanOutput = ($statusOutput | Select-Object -Skip $jsonStart) -join "`n"
    } else {
        $cleanOutput = $statusOutput -join "`n"
    }
    
    $statusJson = $cleanOutput | ConvertFrom-Json
    $badge = Get-StatusBadge -StatusData $statusJson
    $shieldsUrl = Get-ShieldsBadge -Badge $badge
    
    if ($Json) {
        $result = @{
            status = $badge.status
            color = $badge.color
            message = $badge.message
            shields_url = $shieldsUrl
            timestamp = (Get-Date).ToString("o")
        }
        
        if ($OutputFile) {
            $result | ConvertTo-Json -Depth 3 | Set-Content $OutputFile
            Write-Host "Badge JSON written to $OutputFile"
        } else {
            $result | ConvertTo-Json -Depth 3
        }
    } elseif ($Markdown) {
        $markdownBadge = Get-MarkdownBadge -Badge $badge -ShieldsUrl $shieldsUrl
        
        if ($OutputFile) {
            $markdownBadge | Set-Content $OutputFile
            Write-Host "Markdown badge written to $OutputFile"
        } else {
            $markdownBadge
        }
    } else {
        # Default: show badge info
        Write-Host "Status: $($badge.status)" -ForegroundColor $(switch ($badge.color) {
            "green" { "Green" }
            "yellow" { "Yellow" }
            "red" { "Red" }
            default { "White" }
        })
        Write-Host "Message: $($badge.message)"
        Write-Host "Badge URL: $shieldsUrl"
    }
    
} catch {
    Write-Error "Failed to get status: $($_.Exception.Message)"
    exit 1
}
