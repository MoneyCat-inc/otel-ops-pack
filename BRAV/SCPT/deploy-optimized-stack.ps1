# Deploy Optimized SigNoz/OTel Stack
# Handles graceful deployment with proper startup ordering and monitoring

param(
    [switch]$SkipGPU,
    [switch]$Force,
    [int]$TimeoutMinutes = 10,
    [string]$LogLevel = "INFO"
)

# Set error action preference
$ErrorActionPreference = "Stop"

# Color functions for output
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

function Write-Info { param([string]$msg) Write-ColorOutput "ℹ️  $msg" "Cyan" }
function Write-Success { param([string]$msg) Write-ColorOutput "✅ $msg" "Green" }
function Write-Warning { param([string]$msg) Write-ColorOutput "⚠️  $msg" "Yellow" }
function Write-Error { param([string]$msg) Write-ColorOutput "❌ $msg" "Red" }

# Initialize deployment
Write-Info "Starting optimized SigNoz/OTel stack deployment..."
Write-Info "Timeout: $TimeoutMinutes minutes, GPU Services: $(-not $SkipGPU)"

try {
    # Step 1: Clean shutdown if Force is specified
    if ($Force) {
        Write-Info "Force mode: Cleaning up existing stack..."
        docker compose -f docker-compose.yml down -v --remove-orphans
        Start-Sleep -Seconds 5
    }

    # Step 2: Check for required configuration files
    $requiredFiles = @(
        "docker-compose.yml",
        "signoz-collector-config.yaml",
        "clickhouse-cluster-config.xml",
        "clickhouse-zookeeper-config.xml"
    )
    
    foreach ($file in $requiredFiles) {
        if (-not (Test-Path $file)) {
            Write-Warning "Missing required file: $file"
            if ($file -eq "signoz-collector-config.yaml") {
                Write-Info "Creating basic collector config..."
                @"
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318

processors:
  batch:

exporters:
  clickhousetraces:
    dsn: tcp://signoz-clickhouse:9000
  clickhousemetrics:
    dsn: tcp://signoz-clickhouse:9000
  clickhouselogs:
    dsn: tcp://signoz-clickhouse:9000

service:
  pipelines:
    traces:
      receivers: [otlp]
      processors: [batch]
      exporters: [clickhousetraces]
    metrics:
      receivers: [otlp]
      processors: [batch]
      exporters: [clickhousemetrics]
    logs:
      receivers: [otlp]
      processors: [batch]
      exporters: [clickhouselogs]
"@ | Out-File -FilePath $file -Encoding UTF8
                Write-Success "Created $file"
            }
        }
    }

    # Step 3: Create data directories
    $dataDirs = @("data/clickhouse", "data/signoz", "data/zookeeper")
    foreach ($dir in $dataDirs) {
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
            Write-Info "Created data directory: $dir"
        }
    }

    # Step 4: Determine compose command
    $composeCmd = "docker compose -f docker-compose.yml"
    if ($SkipGPU) {
        $composeCmd += " --profile gpu"
    }

    # Step 5: Start foundation services first
    Write-Info "Starting foundation services (Zookeeper, ClickHouse)..."
    Invoke-Expression "$composeCmd up -d signoz-zookeeper signoz-clickhouse"
    
    # Wait for foundation services to be healthy
    Write-Info "Waiting for foundation services to be healthy..."
    $timeout = [DateTime]::Now.AddMinutes(5)
    while ([DateTime]::Now -lt $timeout) {
        $zookeeperStatus = docker compose -f docker-compose.yml ps signoz-zookeeper --format "{{.State}}"
        $clickhouseStatus = docker compose -f docker-compose.yml ps signoz-clickhouse --format "{{.State}}"
        
        if ($zookeeperStatus -eq "running" -and $clickhouseStatus -eq "running") {
            Write-Success "Foundation services are healthy"
            break
        }
        
        Start-Sleep -Seconds 10
    }

    # Step 6: Start SigNoz core
    Write-Info "Starting SigNoz core service..."
    Invoke-Expression "$composeCmd up -d signoz"
    
    # Wait for SigNoz to be healthy
    Write-Info "Waiting for SigNoz to be healthy..."
    $timeout = [DateTime]::Now.AddMinutes(3)
    while ([DateTime]::Now -lt $timeout) {
        $signozStatus = docker compose -f docker-compose.yml ps signoz --format "{{.State}}"
        if ($signozStatus -eq "running") {
            Write-Success "SigNoz core is healthy"
            break
        }
        Start-Sleep -Seconds 10
    }

    # Step 7: Start schema migrators (critical step)
    Write-Info "Starting schema migrators (critical for database setup)..."
    Invoke-Expression "$composeCmd up signoz-schema-migrator-sync"
    
    # Wait for sync migrator to complete
    $migratorExitCode = docker compose -f docker-compose.yml ps signoz-schema-migrator-sync --format "{{.ExitCode}}"
    if ($migratorExitCode -eq "0") {
        Write-Success "Schema migrator sync completed successfully"
    } else {
        Write-Warning "Schema migrator sync had issues (exit code: $migratorExitCode)"
    }

    # Step 8: Start OTel collector
    Write-Info "Starting OTel collector..."
    Invoke-Expression "$composeCmd up -d signoz-otel-collector"
    
    # Wait for collector to be healthy
    Write-Info "Waiting for OTel collector to be healthy..."
    $timeout = [DateTime]::Now.AddMinutes(3)
    while ([DateTime]::Now -lt $timeout) {
        $collectorStatus = docker compose -f docker-compose.yml ps signoz-otel-collector --format "{{.State}}"
        if ($collectorStatus -eq "running") {
            Write-Success "OTel collector is healthy"
            break
        }
        Start-Sleep -Seconds 10
    }

    # Step 9: Start demo app
    Write-Info "Starting demo application..."
    Invoke-Expression "$composeCmd up -d demo-app"

    # Step 10: Start GPU services if not skipped
    if (-not $SkipGPU) {
        Write-Info "Starting GPU services..."
        try {
            Invoke-Expression "$composeCmd --profile gpu up -d"
            Write-Success "GPU services started"
        } catch {
            Write-Warning "GPU services failed to start (images may not exist)"
        }
    }

    # Step 11: Final status check
    Write-Info "Performing final status check..."
    Start-Sleep -Seconds 30
    
    $services = @("signoz-zookeeper", "signoz-clickhouse", "signoz", "signoz-otel-collector", "demo-app")
    $healthyServices = 0
    
    foreach ($service in $services) {
        $status = docker compose -f docker-compose.yml ps $service --format "{{.State}}"
        if ($status -eq "running") {
            $healthyServices++
            Write-Success "$service is running"
        } else {
            Write-Warning "$service status: $status"
        }
    }

    # Step 12: Generate deployment report
    $report = @{
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        ServicesHealthy = $healthyServices
        TotalServices = $services.Count
        GPUEnabled = -not $SkipGPU
        DeploymentTime = [DateTime]::Now
    }

    $reportPath = "artifacts/deployment-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    if (-not (Test-Path "artifacts")) {
        New-Item -ItemType Directory -Path "artifacts" -Force | Out-Null
    }
    
    $report | ConvertTo-Json -Depth 3 | Out-File -FilePath $reportPath -Encoding UTF8
    Write-Success "Deployment report saved to: $reportPath"

    # Final summary
    Write-Success "Deployment completed!"
    Write-Info "SigNoz UI: http://localhost:8080"
    Write-Info "OTel Collector: http://localhost:4317 (gRPC), http://localhost:4318 (HTTP)"
    Write-Info "Demo App: http://localhost:3001"
    
    if ($healthyServices -eq $services.Count) {
        Write-Success "All core services are healthy!"
        exit 0
    } else {
        Write-Warning "Some services may need attention. Check logs with: docker compose -f docker-compose.yml logs"
        exit 1
    }

} catch {
    Write-Error "Deployment failed: $($_.Exception.Message)"
    Write-Info "Check logs with: docker compose -f docker-compose.yml logs"
    exit 1
}
