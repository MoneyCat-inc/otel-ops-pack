# Status Update Script for Autopilot Agent
# Updates .agent/status.json with section-specific information
# Part of the push-button automation system

param(
    [Parameter(Mandatory=$true)]
    [string]$Section,
    
    [Parameter(Mandatory=$true)]
    [bool]$Ok,
    
    [string]$Detail = "",
    
    [string]$StatusFile = ".agent/status.json"
)

$ErrorActionPreference = "Stop"

# Create status update object
$statusUpdate = @{
    timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    section = $Section
    status = if ($Ok) { "ok" } else { "fail" }
    details = $Detail
}

# Load existing status data
$statusData = @{}
if (Test-Path $StatusFile) {
    try {
        $statusData = Get-Content $StatusFile -Raw | ConvertFrom-Json
    } catch {
        Write-Warning "Could not parse existing status file, creating new one"
        $statusData = @{}
    }
}

# Update the specific section
$statusData | Add-Member -NotePropertyName $Section -NotePropertyValue $statusUpdate -Force

# Ensure .agent directory exists
$agentDir = Split-Path $StatusFile -Parent
if (-not (Test-Path $agentDir)) {
    New-Item -ItemType Directory -Path $agentDir -Force | Out-Null
}

# Save updated status
$statusData | ConvertTo-Json -Depth 10 | Set-Content $StatusFile

# Output confirmation
$statusText = if ($Ok) { "✅ OK" } else { "❌ FAIL" }
Write-Host "Updated $Section status: $statusText" -ForegroundColor $(if($Ok){"Green"}else{"Red"})
if ($Detail) {
    Write-Host "  Detail: $Detail" -ForegroundColor Gray
}