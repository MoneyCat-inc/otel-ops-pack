# Enable Windows Collector - One-Shot Configuration Script
# Requires: Elevated PowerShell session (Run as Administrator)
# Purpose: Configure and start OpenTelemetry Collector service with minimal safe config

param(
    [Parameter(Mandatory=$true)]
    [string]$OtlpEndpoint = "http://localhost:4317",
    
    [string]$ServiceName = "otelcol-contrib",
    [string]$ConfigPath = "C:\ProgramData\otelcol-contrib\config.yaml",
    [switch]$Force = $false
)

# Check if running as Administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "This script must be run as Administrator. Please restart PowerShell as Administrator and try again."
    exit 1
}

Write-Host "🐾 BossCat Windows Collector Setup" -ForegroundColor Cyan
Write-Host "Configuring OpenTelemetry Collector service..." -ForegroundColor Gray
Write-Host ""

$ErrorActionPreference = "Stop"

try {
    # Step 1: Discover the service
    Write-Host "🔍 Discovering collector service..." -ForegroundColor Yellow
    $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
    
    if (-not $service) {
        # Try alternative service names
        $alternatives = @("otelcol", "opentelemetry-collector", "otel-collector")
        foreach ($alt in $alternatives) {
            $service = Get-Service -Name $alt -ErrorAction SilentlyContinue
            if ($service) {
                $ServiceName = $alt
                Write-Host "   Found service: $ServiceName" -ForegroundColor Green
                break
            }
        }
        
        if (-not $service) {
            Write-Error "OpenTelemetry Collector service not found. Please install the OpenTelemetry Collector Contrib MSI first."
            exit 1
        }
    } else {
        Write-Host "   Found service: $ServiceName" -ForegroundColor Green
    }
    
    # Step 2: Create config directory and backup existing config
    Write-Host "📁 Setting up configuration..." -ForegroundColor Yellow
    $configDir = Split-Path $ConfigPath -Parent
    if (-not (Test-Path $configDir)) {
        New-Item -ItemType Directory -Path $configDir -Force | Out-Null
        Write-Host "   Created directory: $configDir" -ForegroundColor Green
    }
    
    # Backup existing config if it exists
    if (Test-Path $ConfigPath) {
        $backupPath = "$ConfigPath.backup.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        Copy-Item $ConfigPath $backupPath
        Write-Host "   Backed up existing config to: $backupPath" -ForegroundColor Yellow
    }
    
    # Step 3: Write minimal safe config
    Write-Host "📝 Writing minimal safe configuration..." -ForegroundColor Yellow
    $configContent = @"
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318
  hostmetrics:
    collection_interval: 60s
    scrapers:
      cpu: {}
      memory: {}
      disk: {}
      filesystem: {}
      network: {}

processors:
  batch: {}
  memory_limiter:
    check_interval: 5s
    limit_mib: 512
    spike_limit_mib: 256
  resource:
    attributes:
      - action: upsert
        key: service.name
        value: windows-collector
      - action: upsert
        key: deployment.environment
        value: production

exporters:
  otlp:
    endpoint: "$OtlpEndpoint"
    tls:
      insecure: true
  logging:
    loglevel: info

extensions:
  health_check:
    endpoint: 0.0.0.0:13133
  zpages:
    endpoint: 0.0.0.0:55679

service:
  telemetry:
    logs:
      level: info
    metrics:
      address: 0.0.0.0:8888
  extensions: [health_check, zpages]
  pipelines:
    metrics:
      receivers: [hostmetrics, otlp]
      processors: [memory_limiter, batch, resource]
      exporters: [otlp, logging]
    traces:
      receivers: [otlp]
      processors: [memory_limiter, batch, resource]
      exporters: [otlp, logging]
    logs:
      receivers: [otlp]
      processors: [batch, resource]
      exporters: [otlp, logging]
"@
    
    Set-Content -Path $ConfigPath -Value $configContent -Encoding UTF8
    Write-Host "   Configuration written to: $ConfigPath" -ForegroundColor Green
    
    # Step 4: Configure service startup and recovery
    Write-Host "⚙️ Configuring service startup..." -ForegroundColor Yellow
    Set-Service -Name $ServiceName -StartupType Automatic
    sc.exe config $ServiceName start= delayed-auto
    sc.exe failure $ServiceName reset= 86400 actions= restart/5000/restart/5000/restart/5000
    Write-Host "   Set to Automatic (Delayed Start) with restart-on-failure" -ForegroundColor Green
    
    # Step 5: Configure firewall rules
    Write-Host "🔥 Configuring firewall rules..." -ForegroundColor Yellow
    $ports = @(
        @{Port=4317; Name="OTLP gRPC"; Desc="OpenTelemetry OTLP gRPC endpoint"},
        @{Port=4318; Name="OTLP HTTP"; Desc="OpenTelemetry OTLP HTTP endpoint"},
        @{Port=13133; Name="OTel Health"; Desc="OpenTelemetry Collector health check"},
        @{Port=8888; Name="OTel Metrics"; Desc="OpenTelemetry Collector metrics"}
    )
    
    foreach ($port in $ports) {
        try {
            New-NetFirewallRule -DisplayName $port.Name -Direction Inbound -Protocol TCP -LocalPort $port.Port -Action Allow -ErrorAction SilentlyContinue
            Write-Host "   Opened port $($port.Port) ($($port.Name))" -ForegroundColor Green
        } catch {
            Write-Host "   Port $($port.Port) rule may already exist" -ForegroundColor Yellow
        }
    }
    
    # Step 6: Start the service
    Write-Host "🚀 Starting collector service..." -ForegroundColor Yellow
    Start-Service -Name $ServiceName
    Start-Sleep -Seconds 3
    
    $serviceStatus = Get-Service -Name $ServiceName
    if ($serviceStatus.Status -eq "Running") {
        Write-Host "   Service started successfully" -ForegroundColor Green
    } else {
        Write-Error "Service failed to start. Status: $($serviceStatus.Status)"
        exit 1
    }
    
    # Step 7: Verify health
    Write-Host "🏥 Verifying service health..." -ForegroundColor Yellow
    Start-Sleep -Seconds 5  # Give service time to initialize
    
    try {
        $healthResponse = Invoke-WebRequest -Uri "http://localhost:13133/healthz" -UseBasicParsing -TimeoutSec 10
        if ($healthResponse.StatusCode -eq 200) {
            Write-Host "   Health check: ✅ 200 OK" -ForegroundColor Green
        } else {
            Write-Host "   Health check: ⚠️ Status $($healthResponse.StatusCode)" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "   Health check: ❌ $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # Step 8: Verify port connectivity
    Write-Host "🔌 Verifying port connectivity..." -ForegroundColor Yellow
    foreach ($port in $ports) {
        $connection = Test-NetConnection -ComputerName localhost -Port $port.Port -WarningAction SilentlyContinue
        if ($connection.TcpTestSucceeded) {
            Write-Host "   Port $($port.Port): ✅ Reachable" -ForegroundColor Green
        } else {
            Write-Host "   Port $($port.Port): ❌ Not reachable" -ForegroundColor Red
        }
    }
    
    Write-Host ""
    Write-Host "✅ Windows Collector setup complete!" -ForegroundColor Green
    Write-Host "   Service: $ServiceName (Running)" -ForegroundColor White
    Write-Host "   Config: $ConfigPath" -ForegroundColor White
    Write-Host "   Health: http://localhost:13133/healthz" -ForegroundColor White
    Write-Host "   OTLP Endpoint: $OtlpEndpoint" -ForegroundColor White
    
} catch {
    Write-Error "Setup failed: $($_.Exception.Message)"
    exit 1
}

Write-Host ""
Write-Host "🎯 Ready for gate signal: @cat ready-for-gate" -ForegroundColor Cyan
