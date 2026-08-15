# BossCat Demo Flow Generator PowerShell Wrapper
# Integrates DFG with existing BossCat gate scripts

param(
    [Parameter(Mandatory=$false)]
    [string]$Profile = "baseline",

    [Parameter(Mandatory=$false)]
    [string]$Duration = "60s",

    [Parameter(Mandatory=$false)]
    [string]$Rules = $null,

    [Parameter(Mandatory=$false)]
    [switch]$DryRun,

    [Parameter(Mandatory=$false)]
    [switch]$Validate,

    [Parameter(Mandatory=$false)]
    [string]$OTLPEndpoint,

    [Parameter(Mandatory=$false)]
    [string]$SigNozUrl = "http://localhost:8080",

    [Parameter(Mandatory=$false)]
    [string]$ServiceName = "bosscat-dfg",

    [Parameter(Mandatory=$false)]
    [string]$DeployEnv = "local"
)

Import-Module (Join-Path $PSScriptRoot 'lib\OtelPorts.psm1') -Force
if (-not $OTLPEndpoint) { $OTLPEndpoint = Get-OtelIngestHttpBase }

$env:OTLP_ENDPOINT = $OTLPEndpoint
$env:SIGNOZ_URL = $SigNozUrl
$env:SERVICE_NAME = $ServiceName
$env:DEPLOY_ENV = $DeployEnv
$env:BUILD_ID = if ($env:BUILD_ID) { $env:BUILD_ID } else { "local-build-$(Get-Date -Format 'yyyyMMdd-HHmmss')" }

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$DFGDir = Join-Path $ScriptDir ".." "tools" "dfg"
$DFGPath = Join-Path $DFGDir "dfg.js"

if (-not (Test-Path $DFGPath)) {
    Write-Error "[DFG] CLI not found at: $DFGPath"
    Write-Error "[DFG] Ensure the DFG tool is installed in tools/dfg/"
    exit 1
}

try {
    $nodeVersion = node --version 2>$null
    Write-Host "[DFG] Using Node.js $nodeVersion" -ForegroundColor Green
} catch {
    Write-Error "[DFG] Node.js not found. Install Node.js to run DFG."
    exit 1
}

Push-Location $DFGDir

try {
    if ((Test-Path "package.json") -and -not (Test-Path "node_modules")) {
        Write-Host "[DFG] Installing dependencies" -ForegroundColor Yellow
        npm install | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw "npm install failed with exit code $LASTEXITCODE"
        }
    }

    $args = @()

    if ($Validate) {
        $args += "validate"
    } else {
        $args += "run", "--profile", $Profile

        if ($Duration) {
            $args += "--duration", $Duration
        }

        if ($Rules) {
            $args += "--rules", $Rules
        }

        if ($DryRun) {
            $args += "--dry-run"
        }
    }

    Write-Host "[DFG] Configuration" -ForegroundColor Cyan
    Write-Host "  Profile       : $Profile" -ForegroundColor White
    Write-Host "  Duration      : $Duration" -ForegroundColor White
    Write-Host "  OTLP Endpoint : $OTLPEndpoint" -ForegroundColor White
    Write-Host "  SigNoz URL    : $SigNozUrl" -ForegroundColor White
    Write-Host "  Service Name  : $ServiceName" -ForegroundColor White
    Write-Host "  Deploy Env    : $DeployEnv" -ForegroundColor White
    Write-Host "  Build ID      : $env:BUILD_ID" -ForegroundColor White

    if ($Rules) {
        Write-Host "  Chaos Rules   : $Rules" -ForegroundColor White
    }

    Write-Host ""
    Write-Host "[DFG] Executing CLI" -ForegroundColor Green
    & node $DFGPath @args

    if ($LASTEXITCODE -eq 0) {
        Write-Host "[DFG] Execution completed successfully" -ForegroundColor Green

        if (-not $DryRun -and -not $Validate) {
            $artifactsDir = Join-Path (Split-Path -Parent $ScriptDir) "artifacts"
            if (Test-Path $artifactsDir) {
                $latestArtifact = Get-ChildItem $artifactsDir -Filter "dfg-run-*.json" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
                if ($latestArtifact) {
                    Write-Host "[DFG] Run summary: $($latestArtifact.FullName)" -ForegroundColor Cyan
                }
            }

            Write-Host "[DFG] Inspect telemetry in SigNoz ($SigNozUrl)" -ForegroundColor Cyan
            Write-Host "  Service : $ServiceName" -ForegroundColor White
            Write-Host "  Profile : $Profile" -ForegroundColor White
        }
        elseif ($DryRun) {
            Write-Host "[DFG] Dry run completed (no telemetry emitted)" -ForegroundColor Cyan
        }
    } else {
        Write-Error "[DFG] CLI exited with code $LASTEXITCODE"
        exit $LASTEXITCODE
    }
}
finally {
    Pop-Location
}

Write-Host ""
Write-Host "[DFG] ECRR Report" -ForegroundColor Magenta
Write-Host "  Actor    : BossCat DFG PowerShell Wrapper" -ForegroundColor White
Write-Host "  Action   : Traffic generation with profile '$Profile'" -ForegroundColor White
Write-Host "  Duration : $Duration" -ForegroundColor White
Write-Host "  Status   : $(if ($LASTEXITCODE -eq 0) { 'SUCCESS' } else { 'FAILED' })" -ForegroundColor $(if ($LASTEXITCODE -eq 0) { 'Green' } else { 'Red' })
Write-Host "  Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor White
