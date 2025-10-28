# Gate #031: Visualizer Proof Adapter
# Authority: BossCat OEM | Executor: Cursor{Implementer}
# Purpose: Bridge Visualizer UI to existing proof scripts

<#
.SYNOPSIS
    Generate proof artifacts for Visualizer UI display

.DESCRIPTION
    Thin adapter that calls existing proof-of-telemetry.ps1 and health-check-otlp.ps1
    scripts and consolidates results into a Visualizer-friendly JSON format.

.PARAMETER ServiceName
    Service name to query (default: iona-app)

.PARAMETER LookbackMinutes
    Minutes to look back for telemetry (default: 15)

.PARAMETER OutputPath
    Output path for proof artifact (default: artifacts/visualizer/)

.PARAMETER ApiToken
    SigNoz API token (or use SIGNOZ_API_KEY env var)

.EXAMPLE
    .\proof-adapter.ps1 -ServiceName "iona-app"

.EXAMPLE
    $env:SIGNOZ_API_KEY = "<key>"
    .\proof-adapter.ps1 -ServiceName "bosscat-svc2-api" -LookbackMinutes 60
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$ServiceName = "iona-app",
    
    [Parameter(Mandatory=$false)]
    [int]$LookbackMinutes = 15,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = "artifacts/visualizer/",
    
    [Parameter(Mandatory=$false)]
    [string]$ApiToken = $env:SIGNOZ_API_KEY
)

$ErrorActionPreference = "Stop"

# Paths to existing scripts
$ProofScript = "scripts/windows/proof-of-telemetry.ps1"
$HealthScript = "scripts/windows/health-check-otlp.ps1"

Write-Host "[Visualizer] Starting proof generation for service: $ServiceName" -ForegroundColor Cyan
Write-Host "[Visualizer] Lookback: $LookbackMinutes minutes" -ForegroundColor Cyan

# Ensure output directory exists
if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
    Write-Host "[Visualizer] Created output directory: $OutputPath" -ForegroundColor Green
}

# Generate timestamp
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$outputFile = Join-Path $OutputPath "proof-$timestamp.json"

# Exit codes
$exitCode = 0  # GREEN
$status = "GREEN"
$errors = @()

try {
    # Call unified proof script
    Write-Host "[Visualizer] Calling proof-of-telemetry.ps1..." -ForegroundColor Yellow
    
    if ($ApiToken) {
        $env:SIGNOZ_API_KEY = $ApiToken
    }
    
    $proofResult = & $PSScriptRoot/../windows/proof-of-telemetry.ps1 `
        -ServiceName $ServiceName `
        -LookbackMinutes $LookbackMinutes `
        -ErrorAction SilentlyContinue
    
    $proofExitCode = $LASTEXITCODE
    
    # Check proof script exit code
    if ($proofExitCode -eq 1) {
        $status = "AMBER"
        $exitCode = 1
        $errors += "Some signals missing (AMBER)"
    } elseif ($proofExitCode -eq 2) {
        $status = "RED"
        $exitCode = 2
        $errors += "Proof generation failed (RED)"
    }
    
    Write-Host "[Visualizer] Proof script exit code: $proofExitCode" -ForegroundColor $(if ($proofExitCode -eq 0) { "Green" } else { "Yellow" })
    
    # Call health check script
    Write-Host "[Visualizer] Calling health-check-otlp.ps1..." -ForegroundColor Yellow
    
    $healthResult = & $PSScriptRoot/../windows/health-check-otlp.ps1 `
        -ServiceName $ServiceName `
        -ErrorAction SilentlyContinue
    
    $healthExitCode = $LASTEXITCODE
    
    Write-Host "[Visualizer] Health check exit code: $healthExitCode" -ForegroundColor $(if ($healthExitCode -eq 0) { "Green" } else { "Yellow" })
    
    # Look for most recent proof artifact from unified script
    $unifiedProofPattern = "artifacts/proofs/unified-proof-*.json"
    $latestUnifiedProof = Get-ChildItem $unifiedProofPattern -ErrorAction SilentlyContinue | 
        Sort-Object LastWriteTime -Descending | 
        Select-Object -First 1
    
    # Build consolidated proof object
    $proof = @{
        meta = @{
            timestamp = (Get-Date -Format "o")
            service_name = $ServiceName
            lookback_minutes = $LookbackMinutes
            generator = "visualizer-proof-adapter"
            gate = "#031"
        }
        status = $status
        exit_code = $exitCode
        errors = $errors
        signals = @{
            traces = @{
                count = 0
                status = "UNKNOWN"
                last_seen = $null
            }
            logs = @{
                count = 0
                status = "UNKNOWN"
                last_seen = $null
            }
            metrics = @{
                status = "PHASE_2"
                note = "Metrics panel coming in Gate #032"
            }
        }
        health = @{
            pipeline_status = "UNKNOWN"
            collector_status = "UNKNOWN"
        }
        source_artifacts = @()
    }
    
    # Parse unified proof if available
    if ($latestUnifiedProof) {
        Write-Host "[Visualizer] Found unified proof: $($latestUnifiedProof.Name)" -ForegroundColor Green
        $unifiedData = Get-Content $latestUnifiedProof.FullName | ConvertFrom-Json
        
        # Extract traces
        if ($unifiedData.signals.traces) {
            $proof.signals.traces = @{
                count = $unifiedData.signals.traces.result_count
                status = $unifiedData.signals.traces.status
                last_seen = $unifiedData.signals.traces.query_time
            }
        }
        
        # Extract logs
        if ($unifiedData.signals.logs) {
            $proof.signals.logs = @{
                count = $unifiedData.signals.logs.result_count
                status = $unifiedData.signals.logs.status
                last_seen = $unifiedData.signals.logs.query_time
            }
        }
        
        # Extract metrics (if present)
        if ($unifiedData.signals.metrics) {
            $proof.signals.metrics = @{
                count = $unifiedData.signals.metrics.result_count
                status = $unifiedData.signals.metrics.status
                last_seen = $unifiedData.signals.metrics.query_time
            }
        }
        
        $proof.source_artifacts += $latestUnifiedProof.FullName
    }
    
    # Add health data
    $proof.health = @{
        pipeline_status = if ($healthExitCode -eq 0) { "OK" } else { "DEGRADED" }
        collector_status = if ($healthExitCode -le 1) { "OK" } else { "ERROR" }
        health_check_exit = $healthExitCode
    }
    
    # Write proof artifact
    $proof | ConvertTo-Json -Depth 10 | Set-Content $outputFile -Encoding UTF8
    Write-Host "[Visualizer] Proof artifact written: $outputFile" -ForegroundColor Green
    
    # Also create a "latest" symlink (copy on Windows)
    $latestFile = Join-Path $OutputPath "proof-latest.json"
    Copy-Item $outputFile $latestFile -Force
    Write-Host "[Visualizer] Updated proof-latest.json" -ForegroundColor Green
    
    # Log ICF contribution
    Write-Host "[ICF] Visualizer proof generated - icf.contribution=visualizer.mvp" -ForegroundColor Magenta
    
    # Summary
    Write-Host "`n[Visualizer] Proof Summary:" -ForegroundColor Cyan
    Write-Host "  Status: $status" -ForegroundColor $(if ($status -eq "GREEN") { "Green" } elseif ($status -eq "AMBER") { "Yellow" } else { "Red" })
    Write-Host "  Traces: $($proof.signals.traces.count)" -ForegroundColor White
    Write-Host "  Logs: $($proof.signals.logs.count)" -ForegroundColor White
    Write-Host "  Health: $($proof.health.pipeline_status)" -ForegroundColor White
    Write-Host "  Artifact: $outputFile" -ForegroundColor White
    
} catch {
    Write-Host "[Visualizer] ERROR: $_" -ForegroundColor Red
    $exitCode = 2
    $status = "RED"
    
    # Write error proof
    $errorProof = @{
        meta = @{
            timestamp = (Get-Date -Format "o")
            service_name = $ServiceName
            generator = "visualizer-proof-adapter"
            gate = "#031"
        }
        status = "RED"
        exit_code = 2
        error = $_.Exception.Message
    }
    
    $errorProof | ConvertTo-Json | Set-Content $outputFile -Encoding UTF8
}

Write-Host "`n[Visualizer] Proof adapter complete (exit $exitCode)" -ForegroundColor Cyan
exit $exitCode

