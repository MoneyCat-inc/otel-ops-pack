#!/usr/bin/env pwsh
# Start OpenTelemetry Development Collector
# Provides local development environment for agent telemetry testing

param(
    [switch]$WithJaeger,
    [switch]$WithZipkin,
    [switch]$WithPrometheus,
    [switch]$WithGrafana,
    [switch]$All,
    [switch]$Stop,
    [switch]$Status
)

$ErrorActionPreference = "Stop"

# Set default behavior
if ($All) {
    $WithJaeger = $true
    $WithZipkin = $true
    $WithPrometheus = $true
    $WithGrafana = $true
}

function Write-Progress-Animation {
    param(
        [string]$Message,
        [int]$Duration = 3000
    )
    
    $spinner = @('⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏')
    $endTime = (Get-Date).AddMilliseconds($Duration)
    
    while ((Get-Date) -lt $endTime) {
        $spinnerIndex = [int]((Get-Date).Ticks % $spinner.Length)
        Write-Host "`r$($spinner[$spinnerIndex]) $Message" -NoNewline -ForegroundColor Cyan
        Start-Sleep -Milliseconds 100
    }
    Write-Host "`r✅ $Message complete" -ForegroundColor Green
}

function Test-DockerAvailable {
    try {
        docker --version | Out-Null
        docker-compose --version | Out-Null
        return $true
    }
    catch {
        Write-Host "❌ Docker or Docker Compose not available. Please install Docker Desktop." -ForegroundColor Red
        return $false
    }
}

function Start-DevCollector {
    Write-Host "🚀 Starting OpenTelemetry Development Collector..." -ForegroundColor Green
    
    if (-not (Test-DockerAvailable)) {
        exit 1
    }
    
    # Check if already running
    $running = docker-compose -f docker-compose.dev.yml ps -q
    if ($running) {
        Write-Host "⚠️  Collector already running. Use -Stop to stop it first." -ForegroundColor Yellow
        return
    }
    
    # Build compose command based on selected services
    $composeCmd = "docker-compose -f docker-compose.dev.yml up -d otel-collector"
    
    if ($WithJaeger) {
        $composeCmd += " jaeger"
        Write-Host "📊 Including Jaeger for distributed tracing" -ForegroundColor Blue
    }
    
    if ($WithZipkin) {
        $composeCmd += " zipkin"
        Write-Host "📊 Including Zipkin for distributed tracing" -ForegroundColor Blue
    }
    
    if ($WithPrometheus) {
        $composeCmd += " prometheus"
        Write-Host "📊 Including Prometheus for metrics" -ForegroundColor Blue
    }
    
    if ($WithGrafana) {
        $composeCmd += " grafana"
        Write-Host "📊 Including Grafana for dashboards" -ForegroundColor Blue
    }
    
    # Start services
    Write-Progress-Animation "Starting OTel collector services" 2000
    
    try {
        Invoke-Expression $composeCmd
        
        Write-Host "`n🎉 OpenTelemetry Development Collector started successfully!" -ForegroundColor Green
        Write-Host ""
        Write-Host "📍 Available endpoints:" -ForegroundColor Cyan
        Write-Host "   • OTLP gRPC:     localhost:4317" -ForegroundColor White
        Write-Host "   • OTLP HTTP:     localhost:4318" -ForegroundColor White
        Write-Host "   • Health Check:  localhost:13133" -ForegroundColor White
        Write-Host "   • Prometheus:    localhost:8889" -ForegroundColor White
        Write-Host "   • pprof:         localhost:1777" -ForegroundColor White
        Write-Host "   • zpages:        localhost:55679" -ForegroundColor White
        
        if ($WithJaeger) {
            Write-Host "   • Jaeger UI:     http://localhost:16686" -ForegroundColor White
        }
        
        if ($WithZipkin) {
            Write-Host "   • Zipkin UI:     http://localhost:9411" -ForegroundColor White
        }
        
        if ($WithPrometheus) {
            Write-Host "   • Prometheus UI: http://localhost:9090" -ForegroundColor White
        }
        
        if ($WithGrafana) {
            Write-Host "   • Grafana UI:    http://localhost:3000 (admin/admin)" -ForegroundColor White
        }
        
        Write-Host ""
        Write-Host "🔧 Environment variables for agent:" -ForegroundColor Cyan
        Write-Host "   • OTEL_ENABLED=1" -ForegroundColor White
        Write-Host "   • OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4318" -ForegroundColor White
        Write-Host "   • OTEL_SERVICE_NAME=resonai-agent" -ForegroundColor White
        
    }
    catch {
        Write-Host "❌ Failed to start collector: $_" -ForegroundColor Red
        exit 1
    }
}

function Stop-DevCollector {
    Write-Host "🛑 Stopping OpenTelemetry Development Collector..." -ForegroundColor Yellow
    
    try {
        docker-compose -f docker-compose.dev.yml down
        Write-Host "✅ Collector stopped successfully" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Failed to stop collector: $_" -ForegroundColor Red
        exit 1
    }
}

function Show-Status {
    Write-Host "📊 OpenTelemetry Development Collector Status" -ForegroundColor Cyan
    
    try {
        docker-compose -f docker-compose.dev.yml ps
    }
    catch {
        Write-Host "❌ Failed to get status: $_" -ForegroundColor Red
        exit 1
    }
}

# Main execution
if ($Stop) {
    Stop-DevCollector
}
elseif ($Status) {
    Show-Status
}
else {
    Start-DevCollector
}
