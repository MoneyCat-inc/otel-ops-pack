# C:\otel\ai-assistant-helper.ps1
# AI Assistant Helper Functions
# ASCII only, PowerShell 5.1 compatible

param(
  [ValidateSet("validate", "test", "template", "help", "status")]
  [string]$Action = "help",
  [string]$Integration = "",
  [string]$ConfigPath = "C:\otel\config.yaml",
  [switch]$Verbose
)

$ErrorActionPreference = "Stop"
$LogDir = "C:\otel\logs"
$Log = Join-Path $LogDir "ai-assistant-helper.last.txt"

if (-not (Test-Path $LogDir)) { New-Item -ItemType Directory -Force -Path $LogDir | Out-Null }
function WL($m){ $ts=(Get-Date).ToString("s"); $line="[$ts] $m"; $line | Tee-Object -FilePath $Log -Append }

Write-Host "AI Assistant Helper" -ForegroundColor Cyan
WL "AI Assistant Helper started with action: $Action"

switch ($Action) {
  "validate" {
    Write-Host "`nValidating configuration..." -ForegroundColor Yellow
    try {
      & C:\otel\config-schema.ps1 -ConfigPath $ConfigPath -CheckSecurity -CheckPerformance -CheckPipelines -CheckMemory
      if ($LASTEXITCODE -eq 0) {
        Write-Host "Configuration validation passed" -ForegroundColor Green
      } else {
        Write-Host "Configuration validation failed" -ForegroundColor Red
      }
    } catch {
      Write-Host "Validation error: $($_.Exception.Message)" -ForegroundColor Red
    }
  }
  
  "test" {
    Write-Host "`nRunning integration tests..." -ForegroundColor Yellow
    try {
      if ($Integration) {
        & C:\otel\integration-tests.ps1 -Integrations @($Integration) -Verbose:$Verbose
      } else {
        & C:\otel\integration-tests.ps1 -Verbose:$Verbose
      }
      if ($LASTEXITCODE -eq 0) {
        Write-Host "Integration tests passed" -ForegroundColor Green
      } else {
        Write-Host "Integration tests failed" -ForegroundColor Red
      }
    } catch {
      Write-Host "Test error: $($_.Exception.Message)" -ForegroundColor Red
    }
  }
  
  "template" {
    Write-Host "`nAvailable templates:" -ForegroundColor Yellow
    $templates = @(
      @{ Name = "kafka-integration.yaml"; Description = "Kafka fan-out configuration" },
      @{ Name = "prometheus-integration.yaml"; Description = "Prometheus metrics scraping" },
      @{ Name = "jaeger-integration.yaml"; Description = "Jaeger distributed tracing" },
      @{ Name = "datadog-integration.yaml"; Description = "Datadog observability platform" },
      @{ Name = "newrelic-integration.yaml"; Description = "New Relic observability platform" },
      @{ Name = "complete-integration.yaml"; Description = "Full-featured configuration" }
    )
    
    foreach ($template in $templates) {
      Write-Host "  $($template.Name) - $($template.Description)" -ForegroundColor White
    }
    
    if ($Integration) {
      $templatePath = "C:\otel\templates\$Integration-integration.yaml"
      if (Test-Path $templatePath) {
        Write-Host "`nTemplate for $($Integration):" -ForegroundColor Green
        Get-Content $templatePath | Select-Object -First 20
        Write-Host "`n... (use Get-Content $templatePath to see full template)" -ForegroundColor Gray
      } else {
        Write-Host "Template not found: $templatePath" -ForegroundColor Red
      }
    }
  }
  
  "status" {
    Write-Host "`nSystem Status:" -ForegroundColor Yellow
    
    # Service status
    try {
      $service = Get-Service otelcol-contrib -ErrorAction Stop
      Write-Host "  Service: $($service.Status)" -ForegroundColor $(if ($service.Status -eq "Running") { "Green" } else { "Red" })
    } catch {
      Write-Host "  Service: Not found" -ForegroundColor Red
    }
    
    # Health endpoint
    try {
      $healthResp = Invoke-WebRequest -Uri http://127.0.0.1:13134 -UseBasicParsing -TimeoutSec 5
      Write-Host "  Health: $($healthResp.StatusCode)" -ForegroundColor $(if ($healthResp.StatusCode -eq 200) { "Green" } else { "Red" })
    } catch {
      Write-Host "  Health: Unavailable" -ForegroundColor Red
    }
    
    # Metrics endpoint
    try {
      $metricsResp = Invoke-WebRequest -Uri http://127.0.0.1:8889/metrics -UseBasicParsing -TimeoutSec 5
      Write-Host "  Metrics: $($metricsResp.StatusCode)" -ForegroundColor $(if ($metricsResp.StatusCode -eq 200) { "Green" } else { "Red" })
    } catch {
      Write-Host "  Metrics: Unavailable" -ForegroundColor Red
    }
    
    # Configuration validation
    try {
      & C:\otel\config-schema.ps1 -ConfigPath $ConfigPath -CheckSecurity -CheckPerformance -CheckPipelines -CheckMemory | Out-Null
      Write-Host "  Config: Valid" -ForegroundColor Green
    } catch {
      Write-Host "  Config: Invalid" -ForegroundColor Red
    }
    
    # Integration tests
    try {
      & C:\otel\integration-tests.ps1 -Integrations @("kafka", "prometheus") | Out-Null
      Write-Host "  Tests: Passed" -ForegroundColor Green
    } catch {
      Write-Host "  Tests: Failed" -ForegroundColor Red
    }
  }
  
  "help" {
    Write-Host "`nAI Assistant Helper Commands:" -ForegroundColor Yellow
    Write-Host "  validate                    - Validate configuration" -ForegroundColor White
    Write-Host "  test                        - Run integration tests" -ForegroundColor White
    Write-Host "  test -Integration kafka     - Test specific integration" -ForegroundColor White
    Write-Host "  template                    - List available templates" -ForegroundColor White
    Write-Host "  template -Integration kafka - Show specific template" -ForegroundColor White
    Write-Host "  status                      - Show system status" -ForegroundColor White
    Write-Host "  help                        - Show this help" -ForegroundColor White
    
    Write-Host "`nAvailable Integrations:" -ForegroundColor Yellow
    Write-Host "  kafka                       - Kafka fan-out" -ForegroundColor White
    Write-Host "  prometheus                  - Prometheus metrics" -ForegroundColor White
    Write-Host "  jaeger                      - Jaeger tracing" -ForegroundColor White
    Write-Host "  datadog                     - Datadog platform" -ForegroundColor White
    Write-Host "  newrelic                    - New Relic platform" -ForegroundColor White
    
    Write-Host "`nKey Files:" -ForegroundColor Yellow
    Write-Host "  C:\otel\ai-context\          - AI context and patterns" -ForegroundColor White
    Write-Host "  C:\otel\templates\           - Integration templates" -ForegroundColor White
    Write-Host "  C:\otel\config-schema.ps1    - Configuration validator" -ForegroundColor White
    Write-Host "  C:\otel\integration-tests.ps1 - Integration tester" -ForegroundColor White
    Write-Host "  C:\otel\ai-assistant-config.yaml - AI configuration" -ForegroundColor White
    
    Write-Host "`nQuick Examples:" -ForegroundColor Yellow
    Write-Host "  .\ai-assistant-helper.ps1 -Action validate" -ForegroundColor Gray
    Write-Host "  .\ai-assistant-helper.ps1 -Action test -Integration kafka" -ForegroundColor Gray
    Write-Host "  .\ai-assistant-helper.ps1 -Action template -Integration prometheus" -ForegroundColor Gray
    Write-Host "  .\ai-assistant-helper.ps1 -Action status" -ForegroundColor Gray
  }
  
  default {
    Write-Host "Unknown action: $Action" -ForegroundColor Red
    Write-Host "Use -Action help to see available commands" -ForegroundColor Yellow
  }
}

WL "AI Assistant Helper completed action: $Action"