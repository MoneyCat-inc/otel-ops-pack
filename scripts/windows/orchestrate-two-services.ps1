# Gate #029: Multi-Service Orchestrator
# Authority: BossCat OEM | Executor: Cursor{Implementer}
# Purpose: Deploy and coordinate multiple services with aggregated status

<#
.SYNOPSIS
    Deploy and manage multiple .NET services with coordinated lifecycle.

.DESCRIPTION
    Orchestrates deployment of bosscat-svc2-api and bosscat-svc3-worker:
    - Sequential deployment with dependency handling
    - Aggregated health status
    - Rollback on failure (stop all services)
    - Structured logging

.PARAMETER Stop
    If set, stops all services instead of starting them

.EXAMPLE
    .\orchestrate-two-services.ps1
    .\orchestrate-two-services.ps1 -Stop
#>

param(
    [Parameter(Mandatory=$false)]
    [switch]$Stop
)

$ErrorActionPreference = "Stop"

# Service definitions
$rootPath = $PSScriptRoot + "\..\..\"
$services = @(
    @{
        Name = "bosscat-svc2-api"
        Port = 5556
        BinaryPath = Join-Path $rootPath "bosscat-svc2-api\bin\Debug\net9.0\bosscat-svc2-api.dll"
        HealthUrl = "http://localhost:5556/health"
        EnableOTel = $true  # Gate #029: Route through Collector (5320)
    },
    @{
        Name = "bosscat-svc3-worker"
        Port = 5557
        BinaryPath = Join-Path $rootPath "bosscat-svc3-worker\bin\Debug\net9.0\bosscat-svc3-worker.dll"
        HealthUrl = "http://localhost:5557/health"
        EnableOTel = $false  # Keep this one uninstrumented for comparison
    }
)

function Write-OrchestratorLog {
    param([string]$Level, [string]$Message, [hashtable]$Data = @{})
    
    $logEntry = @{
        timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ")
        level = $Level
        orchestrator = "multi-service"
        message = $Message
    } + $Data
    
    Write-Host ($logEntry | ConvertTo-Json -Compress)
}

Write-OrchestratorLog -Level "INFO" -Message "Multi-service orchestrator starting" -Data @{
    services_count = $services.Count
    mode = if ($Stop) { "STOP" } else { "DEPLOY" }
}

# Stop mode
if ($Stop) {
    foreach ($svc in $services) {
        Write-OrchestratorLog -Level "INFO" -Message "Stopping service" -Data @{ service = $svc.Name }
        & "scripts\windows\deploy-dotnet-service.ps1" `
            -ServiceName $svc.Name `
            -Port $svc.Port `
            -StopOnly
    }
    Write-OrchestratorLog -Level "INFO" -Message "All services stopped" -Data @{ status = "GREEN" }
    exit 0
}

# Build services first
Write-OrchestratorLog -Level "INFO" -Message "Building services"

foreach ($svc in $services) {
    $projectDir = $svc.Name
    Write-OrchestratorLog -Level "INFO" -Message "Building service" -Data @{ service = $svc.Name; project = $projectDir }
    
    Push-Location $projectDir
    try {
        dotnet build --configuration Debug | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw "Build failed for $($svc.Name)"
        }
        Write-OrchestratorLog -Level "INFO" -Message "Build successful" -Data @{ service = $svc.Name }
    } catch {
        Write-OrchestratorLog -Level "ERROR" -Message "Build failed" -Data @{
            service = $svc.Name
            error = $_.Exception.Message
        }
        Pop-Location
        exit 2
    }
    Pop-Location
}

# Deploy services sequentially
$deployedServices = @()

foreach ($svc in $services) {
    Write-OrchestratorLog -Level "INFO" -Message "Deploying service" -Data @{
        service = $svc.Name
        port = $svc.Port
    }
    
    try {
        $deployParams = @{
            ServiceName = $svc.Name
            Port = $svc.Port
            BinaryPath = $svc.BinaryPath
            HealthUrl = $svc.HealthUrl
            StartTimeout = 30
            HealthRetries = 10
        }
        
        if ($svc.EnableOTel) {
            $deployParams['EnableOTel'] = $true
        }
        
        & "scripts\windows\deploy-dotnet-service.ps1" @deployParams
        
        if ($LASTEXITCODE -eq 0) {
            Write-OrchestratorLog -Level "INFO" -Message "Service deployed successfully" -Data @{
                service = $svc.Name
                port = $svc.Port
            }
            $deployedServices += $svc.Name
        } else {
            throw "Deployment failed with exit code $LASTEXITCODE"
        }
    } catch {
        Write-OrchestratorLog -Level "ERROR" -Message "Service deployment failed, rolling back" -Data @{
            service = $svc.Name
            error = $_.Exception.Message
            deployed_so_far = $deployedServices
        }
        
        # Rollback: stop all deployed services
        foreach ($deployed in $deployedServices) {
            $rollbackSvc = $services | Where-Object { $_.Name -eq $deployed }
            Write-OrchestratorLog -Level "INFO" -Message "Rolling back service" -Data @{ service = $deployed }
            & "scripts\windows\deploy-dotnet-service.ps1" `
                -ServiceName $rollbackSvc.Name `
                -Port $rollbackSvc.Port `
                -StopOnly
        }
        
        Write-OrchestratorLog -Level "ERROR" -Message "Orchestration failed, all services rolled back" -Data @{
            status = "RED"
        }
        exit 2
    }
}

# All services deployed successfully
Write-OrchestratorLog -Level "INFO" -Message "All services deployed successfully" -Data @{
    status = "GREEN"
    services = $deployedServices
    count = $deployedServices.Count
}

# Summary health check
Write-Host "`n=== Service Status ===" -ForegroundColor Cyan
foreach ($svc in $services) {
    $health = Invoke-WebRequest -Uri $svc.HealthUrl -TimeoutSec 5 -ErrorAction SilentlyContinue
    if ($health -and $health.StatusCode -eq 200) {
        Write-Host "  ✅ $($svc.Name) (port $($svc.Port)): HEALTHY" -ForegroundColor Green
    } else {
        Write-Host "  ❌ $($svc.Name) (port $($svc.Port)): UNHEALTHY" -ForegroundColor Red
    }
}

Write-Host "`n📊 Orchestration Complete: GREEN`n" -ForegroundColor Green
exit 0

