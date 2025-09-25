# scripts/agent/update-status.ps1
# Shared status updater for codex-local and OTel Steward agents
# Updates .agent/status.json with section-specific health information

param(
    [Parameter(Mandatory=$true)][ValidateSet('env','otel','analytics')][string]$section,
    [Parameter(Mandatory=$true)][object]$ok,
    [Parameter(Mandatory=$true)][string]$detail
)

function Convert-ToBoolean {
    param([object]$Value)

    if ($null -eq $Value) {
        throw 'Boolean value cannot be null.'
    }

    if ($Value -is [bool]) {
        return $Value
    }

    if ($Value -is [int]) {
        return $Value -ne 0
    }

    if ($Value -is [double]) {
        return [math]::Abs($Value) -gt 0
    }

    if ($Value -is [string]) {
        $normalized = $Value.Trim().ToLowerInvariant()
        switch ($normalized) {
            'true' { return $true }
            'false' { return $false }
            '1' { return $true }
            '0' { return $false }
            'ok' { return $true }
            'pass' { return $true }
            'passed' { return $true }
            'success' { return $true }
            'fail' { return $false }
            'failed' { return $false }
            'error' { return $false }
            default { throw "Cannot convert string '$Value' to boolean. Use true/false or 1/0." }
        }
    }

    throw "Cannot convert value of type '$($Value.GetType().FullName)' to boolean."
}

$ErrorActionPreference = 'Stop'

$path = '.agent/status.json'
$now = (Get-Date).ToString('o')
$okValue = Convert-ToBoolean -Value $ok

# Initialize status file if it does not exist
if (-not (Test-Path $path)) {
    Write-Host '[update-status] Creating initial status file...'
    $initial = @{
        version = 1
        updatedAt = $now
        sections = @{}
    }
    ($initial | ConvertTo-Json -Depth 6) | Set-Content $path -Encoding utf8NoBOM
}

# Read current status
try {
    $obj = Get-Content $path -Raw | ConvertFrom-Json
} catch {
    Write-Host '[update-status] Error reading status file, recreating...'
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
    ok = $okValue
    detail = $detail
    ts = $now
}

$obj.sections | Add-Member -Name $section -Value $sectionData -MemberType NoteProperty -Force
$obj.updatedAt = $now

# Write back to file
try {
    ($obj | ConvertTo-Json -Depth 6) | Set-Content $path -Encoding utf8NoBOM
    Write-Host "[update-status] Updated $section section: ok=$okValue, detail='$detail'"
} catch {
    Write-Host "[update-status] Error writing status file: $($_.Exception.Message)"
    exit 1
}

# Optional: Display current status summary
Write-Host '[update-status] Current status summary:'
foreach ($key in $obj.sections.PSObject.Properties.Name) {
    $sec = $obj.sections.$key
    $symbol = if ($sec.ok) { '+' } else { '-' }
    Write-Host ("  {0} {1}: {2}" -f $symbol, $key, $sec.detail)
}

