[CmdletBinding()]
param(
    [switch]$Detached
)

$ErrorActionPreference = 'Stop'

$repoRoot = Resolve-Path -Path (Join-Path $PSScriptRoot '..\..')
$agentDir = Join-Path $repoRoot 'third_party\resonai'

if (-not (Test-Path $agentDir)) {
    Write-Error "Resonai workspace not found at $agentDir"
    exit 1
}

if (-not (Get-Command pnpm -ErrorAction SilentlyContinue)) {
    Write-Host "[bringup] pnpm not detected in PATH" -ForegroundColor Yellow
    Write-Host "[bringup] Install pnpm globally: npm install -g pnpm" -ForegroundColor Yellow
    exit 1
}

Push-Location $agentDir
try {
    Write-Host "[bringup] Running pnpm agent:local:doctor" -ForegroundColor Cyan
    pnpm agent:local:doctor
    if ($LASTEXITCODE -ne 0) {
        throw "agent:local:doctor returned exit code $LASTEXITCODE"
    }

    if ($Detached) {
        Write-Host "[bringup] Starting watchdog in new window" -ForegroundColor Cyan
        $pnpmPath = (Get-Command pnpm -ErrorAction SilentlyContinue).Source
        if (-not $pnpmPath) {
            Write-Host "[bringup] ✗ pnpm not found in PATH" -ForegroundColor Red
            exit 1
        }
        $args = '-NoLogo','-NoProfile','-Command',"& '$pnpmPath' agent:start"
        Start-Process -FilePath 'pwsh.exe' -ArgumentList $args -WorkingDirectory $agentDir | Out-Null
        Write-Host "[bringup] Detached agent started" -ForegroundColor Green
    } else {
        Write-Host "[bringup] Starting pnpm agent:start (press Ctrl+C to stop)" -ForegroundColor Cyan
        pnpm agent:start
        exit $LASTEXITCODE
    }
} finally {
    Pop-Location
}

if ($Detached) {
    exit 0
}