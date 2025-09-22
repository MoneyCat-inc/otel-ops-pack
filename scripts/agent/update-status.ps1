# scripts/agent/update-status.ps1
# Shared status updater for codex-local and OTel Steward agents
# Updates .agent/status.json with section-specific health information

param(
    [Parameter(Mandatory=$true)][ValidateSet("env","otel","analytics")]$section,
    [Parameter(Mandatory=$true)][bool]$ok,
    [Parameter(Mandatory=$true)][string]$detail
)

$ErrorActionPreference = "Stop"

$path = ".agent/status.json"
$now = (Get-Date).ToString("o")

# Initialize status file if it doesn't exist
if (-not (Test-Path $path)) {
    Write-Host "[update-status] Creating initial status file..."
    $initial = @{
        version = 1
        updatedAt = $now
        sections = @{}
    }
    ($initial | ConvertTo-Json -Depth 6) | Set-Content $path
}

# Read current status
try {
    $obj = Get-Content $path -Raw | ConvertFrom-Json
} catch {
    Write-Host "[update-status] Error reading status file, recreating..."
    $obj = @{
        version = 1
        updatedAt = $now
        sections = @{}
    }
}

# Ensure sections object exists
if (-not $obj.sections) { 
    $obj | Add-Member -NotePropertyName sections -NotePropertyValue (@{}) -Force
}

# Update the specific section
$sectionData = @{
    ok = $ok
    detail = $detail
    ts = $now
}

$obj.sections | Add-Member -Name $section -Value $sectionData -MemberType NoteProperty -Force
$obj.updatedAt = $now

# Write back to file
try {
    ($obj | ConvertTo-Json -Depth 6) | Set-Content $path
    Write-Host "[update-status] Updated $section section: ok=$ok, detail='$detail'"
} catch {
    Write-Host "[update-status] Error writing status file: $($_.Exception.Message)"
    exit 1
}

# Optional: Display current status summary
Write-Host "[update-status] Current status summary:"
foreach ($key in $obj.sections.PSObject.Properties.Name) {
    $sec = $obj.sections.$key
    $status = if ($sec.ok) { "✓" } else { "✗" }
    Write-Host "  $status $key`: $($sec.detail)"
}
