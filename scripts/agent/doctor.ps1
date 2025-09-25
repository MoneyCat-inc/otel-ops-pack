# scripts/agent/doctor.ps1
# Simple environment readiness doctor for codex-local watchdog
Set-StrictMode -Version 2
$ErrorActionPreference = 'Stop'

Write-Host '=== codex-local Environment Doctor ==='

$artifactsDir = Join-Path (Get-Location) 'artifacts'
if (-not (Test-Path $artifactsDir)) {
    New-Item -Path $artifactsDir -ItemType Directory -Force | Out-Null
}

$reportPath = Join-Path $artifactsDir 'env-ready-report.txt'
$results = @()
$overallOk = $true

function Add-Result {
    param(
        [string]$Name,
        [bool]$Ok,
        [string]$Detail
    )

    $global:overallOk = $global:overallOk -and $Ok
    $global:results += [pscustomobject]@{ Name = $Name; Ok = $Ok; Detail = $Detail }

    if ($Ok) {
        Write-Host ("   [OK] {0} - {1}" -f $Name, $Detail) -ForegroundColor Green
    } else {
        Write-Host ("   [FAIL] {0} - {1}" -f $Name, $Detail) -ForegroundColor Red
    }
}

# 1. Check for agent lock
if (Test-Path '.agent/LOCK') {
    Add-Result -Name 'Agent lock' -Ok $false -Detail '.agent/LOCK present; remove lock before running env-ready'
} else {
    Add-Result -Name 'Agent lock' -Ok $true -Detail 'No lock detected'
}

# 2. Verify pnpm is available
try {
    $pnpmVersion = (& pnpm --version 2>$null).Trim()
    if ($pnpmVersion) {
        Add-Result -Name 'pnpm' -Ok $true -Detail "pnpm $pnpmVersion"
    } else {
        Add-Result -Name 'pnpm' -Ok $false -Detail 'pnpm returned no version information'
    }
} catch {
    Add-Result -Name 'pnpm' -Ok $false -Detail "pnpm command failed: $($_.Exception.Message)"
}

# 3. Verify Node.js meets minimum version
try {
    $nodeVersionRaw = (& node --version 2>$null).Trim()
    if ($nodeVersionRaw) {
        $nodeVersion = $nodeVersionRaw.TrimStart('v')
        $major = [int]($nodeVersion.Split('.')[0])
        if ($major -ge 18) {
            Add-Result -Name 'node' -Ok $true -Detail "node $nodeVersionRaw"
        } else {
            Add-Result -Name 'node' -Ok $false -Detail "node $nodeVersionRaw (need >= v18)"
        }
    } else {
        Add-Result -Name 'node' -Ok $false -Detail 'node returned no version information'
    }
} catch {
    Add-Result -Name 'node' -Ok $false -Detail "node command failed: $($_.Exception.Message)"
}

# 4. Confirm dependencies installed
if (Test-Path 'node_modules') {
    Add-Result -Name 'node_modules' -Ok $true -Detail 'Dependencies directory present'
} else {
    Add-Result -Name 'node_modules' -Ok $false -Detail 'node_modules missing; run pnpm install'
}

# 5. Optional: Resonai dev API readiness (port 3003) - skip if not available
try {
    $apiResponse = Invoke-RestMethod -Method Get -Uri 'http://localhost:3003/api/events' -TimeoutSec 2
    if ($apiResponse) {
        $buffer = if ($apiResponse.total) { $apiResponse.total } else { 'unknown' }
        Add-Result -Name 'Resonai API' -Ok $true -Detail "GET /api/events OK (buffer: $buffer)"
    } else {
        Add-Result -Name 'Resonai API' -Ok $false -Detail 'Response empty from /api/events'
    }
} catch {
    # Skip Resonai API check if service not available - this is optional for OTel-only setups
    Add-Result -Name 'Resonai API' -Ok $true -Detail 'Service not running (optional for OTel-only setup)'
}

# 6. Docker availability (optional but helpful)
try {
    $dockerVersion = (& docker --version 2>$null).Trim()
    if ($dockerVersion) {
        Add-Result -Name 'docker' -Ok $true -Detail $dockerVersion
    } else {
        Add-Result -Name 'docker' -Ok $false -Detail 'docker returned no version information'
    }
} catch {
    Add-Result -Name 'docker' -Ok $false -Detail "docker command failed: $($_.Exception.Message)"
}

# Write artifact report
$header = @()
$header += '== codex-local Environment Doctor =='
$header += "Timestamp: $(Get-Date -Format 'yyyy-MM-ddTHH:mm:ss.fffK')"
$header += ''
foreach ($item in $results) {
    $status = if ($item.Ok) { 'OK' } else { 'FAIL' }
    $header += "- [$status] $($item.Name): $($item.Detail)"
}
$header += ''
$header += if ($overallOk) { 'Overall: PASSED' } else { 'Overall: FAILED' }

$header | Out-File -FilePath $reportPath -Encoding utf8NoBOM
Write-Host "Report saved to $reportPath"

if ($overallOk) {
    Write-Host 'Environment doctor passed.' -ForegroundColor Green
    exit 0
} else {
    Write-Host 'Environment doctor failed. See report for details.' -ForegroundColor Red
    exit 2
}