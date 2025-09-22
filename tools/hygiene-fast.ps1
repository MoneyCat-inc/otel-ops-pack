#requires -Version 7
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Host "[Hygiene:fast] Running quick local checks..." -ForegroundColor Cyan

if (-not (Get-Module -ListAvailable -Name PSScriptAnalyzer)) {
    Install-Module -Name PSScriptAnalyzer -Scope CurrentUser -Force | Out-Null
}

if (Test-Path 'scripts') {
    Invoke-ScriptAnalyzer -Path 'scripts' -Recurse -EnableExit
} else {
    Write-Host "  (skipped: scripts directory not found)" -ForegroundColor Yellow
}

$canParseYaml = ($PSVersionTable.PSVersion.Major -ge 7 -and (Get-Command -Name ConvertFrom-Yaml -ErrorAction SilentlyContinue))
if (-not $canParseYaml) {
    Write-Warning "ConvertFrom-Yaml unavailable; skipping YAML parse check."
} else {
    $yamlFiles = Get-ChildItem -Recurse -Include *.yml,*.yaml -File -ErrorAction SilentlyContinue
    foreach ($file in $yamlFiles) {
        try {
            $null = ConvertFrom-Yaml -Yaml (Get-Content $file.FullName -Raw)
        } catch {
            Write-Error "YAML parse failed: $($file.FullName) :: $($_.Exception.Message)"
            exit 1
        }
    }
}

Write-Host "[Hygiene:fast] OK" -ForegroundColor Green
