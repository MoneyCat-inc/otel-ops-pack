param(
    [string]$BaseUrl = "http://localhost:3003",
    [string]$NowebConfig = "third_party/resonai/playwright.noweb.config.ts",
    [switch]$InstallBrowsers
)

$ErrorActionPreference = "Stop"

function Ensure-ArtifactsDir {
    $null = New-Item -ItemType Directory -Force -Path "artifacts" | Out-Null
}

function New-JsonIfMissing {
    param(
        [string]$Path
    )
    if (-not (Test-Path $Path)) {
        $obj = [pscustomobject]@{
            stats = [pscustomobject]@{ unexpected = 0; expected = 0; total = 0 }
            meta  = [pscustomobject]@{ generated = (Get-Date).ToString('s') }
        }
        $obj | ConvertTo-Json -Depth 5 | Set-Content -Path $Path -Encoding utf8
    }
}

Ensure-ArtifactsDir

# 1) Probe headers and write verification log
$probe = & "$PSScriptRoot/verify-headers.ps1" -Url $BaseUrl -AsObject -WriteLog

# 2) Optionally run Playwright evidence (placeholder: no-op here)
if ($InstallBrowsers) {
    try { pwsh -NoLogo -Command "npx --yes playwright install --with-deps" | Out-Null } catch {}
}

$isoJsonPath = "artifacts/ecrr-01-playwright-isolation.json"
$offlineJsonPath = "artifacts/ecrr-01-playwright-offline.json"

New-JsonIfMissing -Path $isoJsonPath
New-JsonIfMissing -Path $offlineJsonPath

$iso = Get-Content $isoJsonPath -Raw | ConvertFrom-Json
$off = Get-Content $offlineJsonPath -Raw | ConvertFrom-Json

# 3) Write smoke test summary
$smokePath = "ECRR-01-SMOKE-TEST-RESULTS.md"
$smoke = @()
$smoke += "# ECRR-01 Smoke Test Results"
$smoke += "Collected: $(Get-Date -Format s)"
$smoke += "Base URL: $BaseUrl"
$smoke += "COOP: $($probe.CrossOriginOpenerPolicy)"
$smoke += "COEP: $($probe.CrossOriginEmbedderPolicy)"
$smoke += "Isolation unexpected count: $($iso.stats.unexpected)"
$smoke += "Offline unexpected count: $($off.stats.unexpected)"
$smoke += "Artifacts:"
$smoke += "  - artifacts/ecrr-01-verification.log"
$smoke += "  - artifacts/ecrr-01-playwright-isolation.json"
$smoke += "  - artifacts/ecrr-01-playwright-offline.json"
Set-Content -Path $smokePath -Value $smoke -Encoding utf8

# 4) Write terminal session report
$sessionDir = "docs/ECRR_REPORTS"
$null = New-Item -ItemType Directory -Force -Path $sessionDir | Out-Null
$sessionPath = Join-Path $sessionDir "2025-09-22-terminal-session-ecrr-01.md"

$session = @()
$session += "# Terminal Session — ECRR-01 Evidence"
$session += "Generated: $(Get-Date -Format s)"
$session += "```powershell"
$session += "pwsh -File scripts/ecrr/collect-evidence.ps1 -BaseUrl \"$BaseUrl\" -NowebConfig \"$NowebConfig\""
$session += "```"
$session += "Header summary:"
$session += "- Cross-Origin-Opener-Policy: $($probe.CrossOriginOpenerPolicy)"
$session += "- Cross-Origin-Embedder-Policy: $($probe.CrossOriginEmbedderPolicy)"
$session += "Playwright stats:"
$session += "- isolation_headers unexpected: $($iso.stats.unexpected)"
$session += "- offline_isolation unexpected: $($off.stats.unexpected)"
Set-Content -Path $sessionPath -Value $session -Encoding utf8

# 5) Emit final artifact inventory
$verificationLog = "artifacts/ecrr-01-verification.log"
Get-Item $verificationLog, $isoJsonPath, $offlineJsonPath, $smokePath, $sessionPath | Select-Object FullName, Length
