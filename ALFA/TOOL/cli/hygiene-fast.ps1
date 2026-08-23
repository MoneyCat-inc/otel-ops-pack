#requires -Version 7
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Host "[Hygiene:fast] Running quick local checks..." -ForegroundColor Cyan

if (-not (Get-Module -ListAvailable -Name PSScriptAnalyzer)) {
    Install-Module -Name PSScriptAnalyzer -Scope CurrentUser -Force | Out-Null
}

if (Test-Path 'scripts') {
    Invoke-ScriptAnalyzer -Path 'scripts' -Recurse -Severity Error -EnableExit
} else {
    Write-Host "  (skipped: scripts directory not found)" -ForegroundColor Yellow
}

$canParseYaml = ($PSVersionTable.PSVersion.Major -ge 7 -and (Get-Command -Name ConvertFrom-Yaml -ErrorAction SilentlyContinue))
if (-not $canParseYaml) {
    Write-Warning "ConvertFrom-Yaml unavailable; skipping YAML parse check."
} else {
    $yamlFiles = Get-ChildItem -Recurse -Include *.yml,*.yaml -File -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -notmatch '[\\/](\.git|node_modules)[\\/]' }
    foreach ($file in $yamlFiles) {
        try {
            $null = ConvertFrom-Yaml -Yaml (Get-Content $file.FullName -Raw)
        } catch {
            Write-Error "YAML parse failed: $($file.FullName) :: $($_.Exception.Message)"
            exit 1
        }
    }
}

# Collector pin consistency: the Phase 0 clean-host installer carries an embedded fallback because
# it runs before the clone. It must equal the canonical pin or the clean-host gate tests a
# different version than the one startup-observability.ps1 installs.
$pinFile = 'scripts/windows/collector-version.txt'
$phase0 = 'scripts/windows/phase0-setup.ps1'
if ((Test-Path $pinFile) -and (Test-Path $phase0)) {
    $canonical = (Get-Content $pinFile -Raw).Trim()
    $m = [regex]::Match((Get-Content $phase0 -Raw), "\`$CollectorVersion = '([0-9.]+)'")
    if (-not $m.Success) { Write-Error "No embedded collector pin found in $phase0"; exit 1 }
    if ($m.Groups[1].Value -ne $canonical) {
        Write-Error "Collector pin drift: $pinFile=$canonical but $phase0 fallback=$($m.Groups[1].Value)"
        exit 1
    }
    Write-Host "  collector pin $canonical consistent" -ForegroundColor DarkGray
}

Write-Host "[Hygiene:fast] OK" -ForegroundColor Green
