# Deploy SigNoz/OTel Stack with Schema Migration Fix
# Handles schema migrator issues and ensures proper database initialization

param(
    [switch]$SkipGPU,
    [switch]$ForceClean,
    [int]$TimeoutMinutes = 15,
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
Write-Info "Starting SigNoz/OTel stack deployment with schema migration fix..."
Write-Info "Timeout: $TimeoutMinutes minutes, GPU Services: $(-not $SkipGPU), Force Clean: $ForceClean"

try {
    # Step 1: Clean deployment if requested
    if ($ForceClean) {
        Write-Info "Force clean mode: Removing all containers, volumes, and networks..."
        docker compose -f docker-compose-optimized.yml down -v --remove-orphans
        docker system prune -f
        Start-Sleep -Seconds 5
    }

    # Step 2: Verify configuration files exist
    $requiredFiles = @(
        "docker-compose-optimized.yml",
        "clickhouse-cluster-config.xml",
        "clickhouse-zookeeper-config.xml"
    )
    
    foreach ($file in $requiredFiles) {
        if (-not (Test-Path $file)) {
            Write-Error "Missing required file: $file"
            exit 1
        }
    }

    # Step 3: Create basic collector config if missing
    if (-not (Test-Path "signoz-collector-config.yaml")) {
        Write-Info "Creating basic SigNoz collector configuration..."
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
    timeout: 1s
    send_batch_size: 1024

exporters:
  clickhousetraces:
    dsn: tcp://signoz-clickhouse:9000
    timeout_settings:
      timeout: 5s
  clickhousemetrics:
    dsn: tcp://signoz-clickhouse:9000
    timeout_settings:
      timeout: 5s
  clickhouselogs:
    dsn: tcp://signoz-clickhouse:9000
    timeout_settings:
      timeout: 5s

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
"@ | Out-File -FilePath "signoz-collector-config.yaml" -Encoding UTF8
        Write-Success "Created signoz-collector-config.yaml"
    }

    # Step 4: Start foundation services
    Write-Info "Starting foundation services (Zookeeper, ClickHouse)..."
    docker compose -f docker-compose-optimized.yml up -d signoz-zookeeper signoz-clickhouse
    
    # Wait for foundation services with extended timeout
    Write-Info "Waiting for foundation services to be healthy..."
    $timeout = [DateTime]::Now.AddMinutes(5)
    while ([DateTime]::Now -lt $timeout) {
        $zookeeperStatus = docker compose -f docker-compose-optimized.yml ps signoz-zookeeper --format "{{.State}}" 2>$null
        $clickhouseStatus = docker compose -f docker-compose-optimized.yml ps signoz-clickhouse --format "{{.State}}" 2>$null
        
        if ($zookeeperStatus -eq "running" -and $clickhouseStatus -eq "running") {
            Write-Success "Foundation services are healthy"
            break
        }
        
        Write-Info "Waiting for services... Zookeeper: $zookeeperStatus, ClickHouse: $clickhouseStatus"
        Start-Sleep -Seconds 15
    }

    # Step 5: Start SigNoz core
    Write-Info "Starting SigNoz core service..."
    docker compose -f docker-compose-optimized.yml up -d signoz
    
    # Wait for SigNoz to be healthy
    Write-Info "Waiting for SigNoz to be healthy..."
    $timeout = [DateTime]::Now.AddMinutes(3)
    while ([DateTime]::Now -lt $timeout) {
        $signozStatus = docker compose -f docker-compose-optimized.yml ps signoz --format "{{.State}}" 2>$null
        if ($signozStatus -eq "running") {
            Write-Success "SigNoz core is healthy"
            break
        }
        Write-Info "Waiting for SigNoz... Status: $signozStatus"
        Start-Sleep -Seconds 10
    }

    # Step 6: Run schema migrators with retry logic
    Write-Info "Running schema migrators (with retry logic)..."
    
    # Try sync migrator first
    $maxRetries = 3
    $retryCount = 0
    $migratorSuccess = $false
    
    while ($retryCount -lt $maxRetries -and -not $migratorSuccess) {
        $retryCount++
        Write-Info "Schema migrator attempt $retryCount/$maxRetries..."
        
        try {
            # Run sync migrator
            docker compose -f docker-compose-optimized.yml up signoz-schema-migrator-sync
            
            # Check exit code
            $exitCode = docker compose -f docker-compose-optimized.yml ps signoz-schema-migrator-sync --format "{{.ExitCode}}" 2>$null
            if ($exitCode -eq "0") {
                Write-Success "Schema migrator sync completed successfully"
                $migratorSuccess = $true
            } else {
                Write-Warning "Schema migrator sync failed with exit code: $exitCode"
                
                # Show logs for debugging
                Write-Info "Schema migrator logs:"
                docker compose -f docker-compose-optimized.yml logs signoz-schema-migrator-sync --tail=20
                
                if ($retryCount -lt $maxRetries) {
                    Write-Info "Retrying in 30 seconds..."
                    Start-Sleep -Seconds 30
                }
            }
        } catch {
            Write-Warning "Schema migrator attempt $retryCount failed: $($_.Exception.Message)"
            if ($retryCount -lt $maxRetries) {
                Write-Info "Retrying in 30 seconds..."
                Start-Sleep -Seconds 30
            }
        }
    }
    
    if (-not $migratorSuccess) {
        Write-Warning "Schema migrator failed after $maxRetries attempts, but continuing with deployment..."
        Write-Info "This may cause issues with the OTel collector, but SigNoz UI should still work"
    }

    # Step 7: Start OTel collector (even if migrator failed)
    Write-Info "Starting OTel collector..."
    docker compose -f docker-compose-optimized.yml up -d signoz-otel-collector
    
    # Wait for collector with extended timeout
    Write-Info "Waiting for OTel collector to be healthy..."
    $timeout = [DateTime]::Now.AddMinutes(5)
    while ([DateTime]::Now -lt $timeout) {
        $collectorStatus = docker compose -f docker-compose-optimized.yml ps signoz-otel-collector --format "{{.State}}" 2>$null
        if ($collectorStatus -eq "running") {
            Write-Success "OTel collector is running"
            break
        }
        Write-Info "Waiting for OTel collector... Status: $collectorStatus"
        Start-Sleep -Seconds 15
    }

    # Step 8: Start demo app
    Write-Info "Starting demo application..."
    docker compose -f docker-compose-optimized.yml up -d demo-app

    # Step 9: Start GPU services if not skipped
    if (-not $SkipGPU) {
        Write-Info "Starting GPU services..."
        try {
            docker compose -f docker-compose-optimized.yml --profile gpu up -d
            Write-Success "GPU services started"
        } catch {
            Write-Warning "GPU services failed to start (images may not exist): $($_.Exception.Message)"
        }
    }

    # Step 10: Final status check and report
    Write-Info "Performing final status check..."
    Start-Sleep -Seconds 30
    
    $services = @("signoz-zookeeper", "signoz-clickhouse", "signoz", "signoz-otel-collector", "demo-app")
    $healthyServices = 0
    $serviceStatus = @{}
    
    foreach ($service in $services) {
        $status = docker compose -f docker-compose-optimized.yml ps $service --format "{{.State}}" 2>$null
        $serviceStatus[$service] = $status
        
        if ($status -eq "running") {
            $healthyServices++
            Write-Success "$service is running"
        } else {
            Write-Warning "$service status: $status"
        }
    }

    # Generate comprehensive deployment report
    $report = @{
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        ServicesHealthy = $healthyServices
        TotalServices = $services.Count
        ServiceStatus = $serviceStatus
        GPUEnabled = -not $SkipGPU
        SchemaMigratorSuccess = $migratorSuccess
        MigrationRetries = $retryCount
        DeploymentTime = [DateTime]::Now
        Recommendations = @()
    }

    # Add recommendations based on status
    if ($migratorSuccess) {
        $report.Recommendations += "Schema migration completed successfully - full functionality available"
    } else {
        $report.Recommendations += "Schema migration failed - check logs and consider manual database setup"
        $report.Recommendations += "SigNoz UI should still be accessible for basic functionality"
    }
    
    if ($healthyServices -eq $services.Count) {
        $report.Recommendations += "All core services are healthy - stack is fully operational"
    } else {
        $report.Recommendations += "Some services need attention - check logs for troubleshooting"
    }

    # Save report
    if (-not (Test-Path "artifacts")) {
        New-Item -ItemType Directory -Path "artifacts" -Force | Out-Null
    }
    
    $reportPath = "artifacts/deployment-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $report | ConvertTo-Json -Depth 3 | Out-File -FilePath $reportPath -Encoding UTF8
    Write-Success "Deployment report saved to: $reportPath"

    # Final summary
    Write-Info "=== Deployment Summary ==="
    Write-Info "Healthy Services: $healthyServices/$($services.Count)"
    Write-Info "Schema Migration: $(if($migratorSuccess) {'Success'} else {'Failed'})"
    Write-Info "SigNoz UI: http://localhost:8080"
    Write-Info "OTel Collector: http://localhost:4317 (gRPC), http://localhost:4318 (HTTP)"
    Write-Info "Demo App: http://localhost:3001"
    
    if ($healthyServices -eq $services.Count -and $migratorSuccess) {
        Write-Success "🎉 Full deployment successful! All services are operational."
        exit 0
    } elseif ($healthyServices -ge 3) {
        Write-Warning "⚠️  Partial deployment success. Core services are running, but some issues remain."
        Write-Info "Check the deployment report for detailed status and recommendations."
        exit 1
    } else {
        Write-Error "❌ Deployment failed. Multiple services are not running."
        Write-Info "Check logs with: docker compose -f docker-compose-optimized.yml logs"
        exit 2
    }

} catch {
    Write-Error "Deployment failed with exception: $($_.Exception.Message)"
    Write-Info "Check logs with: docker compose -f docker-compose-optimized.yml logs"
    exit 3
}
