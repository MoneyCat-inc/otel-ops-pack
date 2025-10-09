# scripts/agent/doc-auto-refresh-fixed.ps1 - Auto-refresh documentation with latest status

param(
    [string]$ReadmePath = "README.md",
    [string]$OutputPath = "",
    [switch]$Backup,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

function Write-RefreshResult {
    param(
        [string]$Message,
        [bool]$Success = $true
    )
    
    $color = if ($Success) { "Green" } else { "Red" }
    $icon = if ($Success) { "✅" } else { "❌" }
    Write-Host "$icon $Message" -ForegroundColor $color
}

function Get-StatusSummary {
    try {
        # Get status data with proper JSON parsing
        $statusOutput = pnpm agent:status-premium -Json 2>$null
        $jsonStart = -1
        for ($i = 0; $i -lt $statusOutput.Count; $i++) {
            if ($statusOutput[$i] -match '^\s*\{') {
                $jsonStart = $i
                break
            }
        }
        
        if ($jsonStart -ge 0) {
            $statusClean = ($statusOutput | Select-Object -Skip $jsonStart) -join "`n"
        } else {
            $statusClean = $statusOutput -join "`n"
        }
        $status = $statusClean | ConvertFrom-Json
        
        # Get guardrails data with proper JSON parsing
        $guardrailsOutput = pnpm agent:guardrails-premium -Json 2>$null
        $jsonStart = -1
        for ($i = 0; $i -lt $guardrailsOutput.Count; $i++) {
            if ($guardrailsOutput[$i] -match '^\s*\{') {
                $jsonStart = $i
                break
            }
        }
        
        if ($jsonStart -ge 0) {
            $guardrailsClean = ($guardrailsOutput | Select-Object -Skip $jsonStart) -join "`n"
        } else {
            $guardrailsClean = $guardrailsOutput -join "`n"
        }
        $guardrails = $guardrailsClean | ConvertFrom-Json
        
        return @{
            timestamp = (Get-Date).ToString("o")
            agentStatus = $status.status
            lockStatus = $status.lock
            envStatus = $status.sections.env.ok
            otelStatus = $status.sections.otel.ok
            violations = $guardrails.violations
            filesProcessed = $guardrails.filesProcessed
            queueTotal = $status.queue.total
            queueQueued = $status.queue.queued
            queueCompleted = $status.queue.completed
            queueFailed = $status.queue.failed
            lastActivity = $status.lastActivity
            ema = $status.ema
        }
    } catch {
        return @{
            timestamp = (Get-Date).ToString("o")
            error = $_.Exception.Message
            agentStatus = "error"
            lockStatus = $false
            envStatus = $false
            otelStatus = $false
            violations = -1
            filesProcessed = 0
            queueTotal = 0
            queueQueued = 0
            queueCompleted = 0
            queueFailed = 0
            lastActivity = "Error retrieving status"
            ema = @{}
        }
    }
}

function Generate-StatusSection {
    param([hashtable]$StatusSummary)
    
    $statusIcon = switch ($StatusSummary.agentStatus) {
        "active" { "🟢" }
        "locked" { "🔒" }
        "error" { "❌" }
        default { "⚠️" }
    }
    
    $violationIcon = if ($StatusSummary.violations -eq 0) { "✅" } elseif ($StatusSummary.violations -gt 0) { "⚠️" } else { "❓" }
    
    $envIcon = if ($StatusSummary.envStatus) { "✅" } else { "❌" }
    $otelIcon = if ($StatusSummary.otelStatus) { "✅" } else { "❌" }
    
    $emaInfo = ""
    if ($StatusSummary.ema.Count -gt 0) {
        $emaLines = @()
        foreach ($key in $StatusSummary.ema.Keys) {
            $value = $StatusSummary.ema[$key]
            $formattedKey = $key -replace "Secs", " (seconds)"
            $emaLines += "- **$formattedKey**: $([Math]::Round($value, 1))s"
        }
        $emaInfo = "`n`n### 📊 Performance Metrics`n$($emaLines -join "`n")"
    }
    
    return @"
## 🤖 codex-local Agent Status

> **Last Updated**: $((Get-Date $StatusSummary.timestamp).ToString("yyyy-MM-dd HH:mm:ss UTC"))

### 🔍 Current Status
- **Agent**: $statusIcon $($StatusSummary.agentStatus)
- **Environment**: $envIcon $(if ($StatusSummary.envStatus) { "Healthy" } else { "Not Initialized" })
- **OTel Pipeline**: $otelIcon $(if ($StatusSummary.otelStatus) { "Connected" } else { "Disconnected" })
- **Guardrails**: $violationIcon $($StatusSummary.violations) violations (from $($StatusSummary.filesProcessed) files)

### 📋 Task Queue
- **Total Tasks**: $($StatusSummary.queueTotal)
- **Queued**: $($StatusSummary.queueQueued)
- **Completed**: $($StatusSummary.queueCompleted)
- **Failed**: $($StatusSummary.queueFailed)

### 📝 Recent Activity
``````
$($StatusSummary.lastActivity)
``````

### 🚀 Quick Commands
``````bash
# Check current status
pnpm agent:status-premium -Detailed

# Run guardrails check
pnpm agent:guardrails-premium

# Generate status badge
pnpm agent:status-badge -Markdown
``````$emaInfo

---
*This section is automatically updated by the codex-local agent*
"@
}

Write-Host "📚 codex-local Documentation Auto-Refresh" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

# Get current status
Write-Host "`n📊 Retrieving current status..." -ForegroundColor Yellow
$statusSummary = Get-StatusSummary

if ($statusSummary.error) {
    Write-RefreshResult -Message "Failed to retrieve status: $($statusSummary.error)" -Success $false
    exit 1
}

# Generate status section
Write-Host "`n📝 Generating status section..." -ForegroundColor Yellow
$statusSection = Generate-StatusSection -StatusSummary $statusSummary

# Update README
if ($ReadmePath -and (Test-Path $ReadmePath)) {
    Write-Host "`n📖 Updating README..." -ForegroundColor Yellow
    
    # Backup original if requested
    if ($Backup) {
        $backupPath = "$ReadmePath.backup.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        Copy-Item $ReadmePath $backupPath
        Write-RefreshResult -Message "Backup created: $backupPath" -Success $true
    }
    
    $content = Get-Content $ReadmePath -Raw
    
    # Look for existing status section
    $statusPattern = '(?s)## 🤖 codex-local Agent Status.*?(?=\n##|\Z)'
    
    if ($content -match $statusPattern) {
        # Replace existing section
        $newContent = $content -replace $statusPattern, $statusSection
        Write-RefreshResult -Message "Found existing status section, replacing..." -Success $true
    } else {
        # Add new section at the end
        $newContent = $content + "`n`n" + $statusSection
        Write-RefreshResult -Message "No existing status section found, appending..." -Success $true
    }
    
    if (-not $DryRun) {
        $newContent | Set-Content $ReadmePath -Encoding UTF8
        Write-RefreshResult -Message "README updated successfully" -Success $true
    } else {
        Write-RefreshResult -Message "Dry run - no changes made" -Success $true
    }
}

# Generate standalone report if requested
if ($OutputPath) {
    Write-Host "`n📄 Generating standalone report..." -ForegroundColor Yellow
    
    $reportContent = @"
# codex-local Agent Status Report

$statusSection

## 📊 Historical Data

This report is generated automatically by the codex-local agent.
For more information, see the main README.md file.

---
*Generated on $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss UTC')*
"@
    
    $reportContent | Set-Content $OutputPath -Encoding UTF8
    Write-RefreshResult -Message "Standalone report generated: $OutputPath" -Success $true
}

# Log the refresh
$logEntry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Documentation refreshed: Status=$($statusSummary.agentStatus), Violations=$($statusSummary.violations), Queue=$($statusSummary.queueTotal)"
Add-Content -Path "TASKS.md" -Value $logEntry

Write-Host "`n📊 Status Summary:" -ForegroundColor Cyan
Write-Host "=================" -ForegroundColor Cyan
Write-Host "Agent Status: $($statusSummary.agentStatus)" -ForegroundColor $(if ($statusSummary.agentStatus -eq "active") { "Green" } else { "Red" })
Write-Host "Violations: $($statusSummary.violations)" -ForegroundColor $(if ($statusSummary.violations -eq 0) { "Green" } else { "Yellow" })
Write-Host "Queue: $($statusSummary.queueTotal) total, $($statusSummary.queueQueued) queued" -ForegroundColor White
Write-Host "EMA Metrics: $($statusSummary.ema.Count) available" -ForegroundColor Gray

Write-RefreshResult -Message "Documentation auto-refresh completed" -Success $true
