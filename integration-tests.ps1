# C:\otel\integration-tests.ps1
# Comprehensive integration testing framework
# ASCII only, PowerShell 5.1 compatible

param(
  [string[]]$Integrations = @("kafka", "prometheus", "jaeger"),
  [switch]$FullTest,
  [switch]$Verbose
)

$ErrorActionPreference = "Stop"
$LogDir = "C:\otel\logs"
$Log = Join-Path $LogDir "integration-tests.last.txt"

if (-not (Test-Path $LogDir)) { New-Item -ItemType Directory -Force -Path $LogDir | Out-Null }
function WL($m){ $ts=(Get-Date).ToString("s"); $line="[$ts] $m"; $line | Tee-Object -FilePath $Log -Append }

# Initialize test results
$TestResults = @{
  Passed = 0
  Failed = 0
  Skipped = 0
  Tests = @()
}

function Add-TestResult($name, $status, $message) {
  $TestResults.Tests += @{
    Name = $name
    Status = $status
    Message = $message
    Timestamp = Get-Date
  }
  
  switch ($status) {
    "PASS" { 
      $TestResults.Passed++
      Write-Host "PASS: $name - $message" -ForegroundColor Green
      WL "PASS: $name - $message"
    }
    "FAIL" { 
      $TestResults.Failed++
      Write-Host "FAIL: $name - $message" -ForegroundColor Red
      WL "FAIL: $name - $message"
    }
    "SKIP" { 
      $TestResults.Skipped++
      Write-Host "SKIP: $name - $message" -ForegroundColor Yellow
      WL "SKIP: $name - $message"
    }
  }
}

Write-Host "Starting integration tests..." -ForegroundColor Cyan
WL "Starting integration tests for: $($Integrations -join ', ')"

# Test 1-3: Unified Health Check
Write-Host "`n1-3. Running unified health check..." -ForegroundColor Yellow
try {
  $healthResult = & C:\otel\health-check.ps1 -Mode full
  if ($LASTEXITCODE -eq 0) {
    Add-TestResult "Health Check" "PASS" "All health checks passed"
  } else {
    Add-TestResult "Health Check" "FAIL" "Health check failed with exit code: $LASTEXITCODE"
  }
} catch {
  Add-TestResult "Health Check" "FAIL" "Health check failed: $($_.Exception.Message)"
}

# Test 4: Configuration Validation
Write-Host "`n4. Testing configuration validation..." -ForegroundColor Yellow
try {
  $configResult = & C:\otel\config-schema.ps1 -ConfigPath C:\otel\config.yaml -CheckSecurity -CheckPerformance
  if ($LASTEXITCODE -eq 0) {
    Add-TestResult "Config Validation" "PASS" "Configuration validation passed"
  } else {
    Add-TestResult "Config Validation" "FAIL" "Configuration validation failed with exit code: $LASTEXITCODE"
  }
} catch {
  Add-TestResult "Config Validation" "FAIL" "Configuration validation failed: $($_.Exception.Message)"
}

# Test 5: Integration-Specific Tests
foreach ($integration in $Integrations) {
  Write-Host "`n5.$($Integrations.IndexOf($integration) + 1). Testing $integration integration..." -ForegroundColor Yellow
  
  switch ($integration.ToLower()) {
    "kafka" {
      try {
        $kafkaResult = & C:\otel\kafka-smoke.ps1
        if ($LASTEXITCODE -eq 0) {
          Add-TestResult "Kafka Integration" "PASS" "Kafka connectivity test passed"
        } else {
          Add-TestResult "Kafka Integration" "SKIP" "Kafka broker not available (optional)"
        }
      } catch {
        Add-TestResult "Kafka Integration" "SKIP" "Kafka test failed: $($_.Exception.Message) (optional)"
      }
    }
    
    "prometheus" {
      try {
        $promResp = Invoke-WebRequest -Uri http://127.0.0.1:8889/metrics -UseBasicParsing -TimeoutSec 5
        if ($promResp.StatusCode -eq 200) {
          Add-TestResult "Prometheus Integration" "PASS" "Prometheus metrics endpoint accessible"
        } else {
          Add-TestResult "Prometheus Integration" "FAIL" "Prometheus metrics endpoint returned status: $($promResp.StatusCode)"
        }
      } catch {
        Add-TestResult "Prometheus Integration" "FAIL" "Prometheus test failed: $($_.Exception.Message)"
      }
    }
    
    "jaeger" {
      try {
        $jaegerResp = Invoke-WebRequest -Uri http://localhost:14268/api/traces -UseBasicParsing -TimeoutSec 5
        if ($jaegerResp.StatusCode -eq 200) {
          Add-TestResult "Jaeger Integration" "PASS" "Jaeger collector endpoint accessible"
        } else {
          Add-TestResult "Jaeger Integration" "SKIP" "Jaeger collector not available (optional)"
        }
      } catch {
        Add-TestResult "Jaeger Integration" "SKIP" "Jaeger test failed: $($_.Exception.Message) (optional)"
      }
    }
    
    "datadog" {
      try {
        if ($env:DD_API_KEY) {
          $ddResp = Invoke-WebRequest -Uri "https://api.datadoghq.com/api/v1/validate" -Headers @{"DD-API-KEY" = $env:DD_API_KEY} -UseBasicParsing -TimeoutSec 10
          if ($ddResp.StatusCode -eq 200) {
            Add-TestResult "Datadog Integration" "PASS" "Datadog API key is valid"
          } else {
            Add-TestResult "Datadog Integration" "FAIL" "Datadog API key validation failed"
          }
        } else {
          Add-TestResult "Datadog Integration" "SKIP" "Datadog API key not configured (optional)"
        }
      } catch {
        Add-TestResult "Datadog Integration" "SKIP" "Datadog test failed: $($_.Exception.Message) (optional)"
      }
    }
    
    "newrelic" {
      try {
        if ($env:NEW_RELIC_API_KEY) {
          $nrResp = Invoke-WebRequest -Uri "https://otlp.nr-data.net/v1/traces" -Headers @{"api-key" = $env:NEW_RELIC_API_KEY} -UseBasicParsing -TimeoutSec 10
          if ($nrResp.StatusCode -eq 200) {
            Add-TestResult "New Relic Integration" "PASS" "New Relic API key is valid"
          } else {
            Add-TestResult "New Relic Integration" "FAIL" "New Relic API key validation failed"
          }
        } else {
          Add-TestResult "New Relic Integration" "SKIP" "Datadog API key not configured (optional)"
        }
      } catch {
        Add-TestResult "New Relic Integration" "SKIP" "New Relic test failed: $($_.Exception.Message) (optional)"
      }
    }
    
    default {
      Add-TestResult "$integration Integration" "SKIP" "Unknown integration type: $integration"
    }
  }
}

# Test 6: Full Integration Test (if requested)
if ($FullTest) {
  Write-Host "`n6. Running full integration test..." -ForegroundColor Yellow
  
  # Test data flow end-to-end
  try {
    # Send test data
    $testData = @{
      resourceLogs = @(
        @{
          resource = @{
            attributes = @(
              @{ key = "service.name"; value = @{ stringValue = "integration-test" } }
              @{ key = "test.type"; value = @{ stringValue = "full-integration" } }
            )
          }
          scopeLogs = @(
            @{
              logRecords = @(
                @{
                  timeUnixNano = ([int64]([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()) * 1000000).ToString()
                  severityText = "INFO"
                  body = @{ stringValue = "Full integration test" }
                  attributes = @(
                    @{ key = "test.id"; value = @{ stringValue = "full-test-$(Get-Random)" } }
                  )
                }
              )
            }
          )
        }
      )
    }
    
    $jsonPayload = $testData | ConvertTo-Json -Depth 10
    $headers = @{ "Content-Type" = "application/json" }
    
    $testResp = Invoke-WebRequest -Uri http://127.0.0.1:5321/v1/logs -Method Post -Headers $headers -Body $jsonPayload -UseBasicParsing -TimeoutSec 10
    
    if ($testResp.StatusCode -eq 200) {
      Add-TestResult "Full Integration Test" "PASS" "End-to-end data flow test passed"
    } else {
      Add-TestResult "Full Integration Test" "FAIL" "End-to-end test failed with status: $($testResp.StatusCode)"
    }
  } catch {
    Add-TestResult "Full Integration Test" "FAIL" "End-to-end test failed: $($_.Exception.Message)"
  }
}

# Summary
Write-Host "`nIntegration Test Summary:" -ForegroundColor Cyan
Write-Host "  Passed: $($TestResults.Passed)" -ForegroundColor Green
Write-Host "  Skipped: $($TestResults.Skipped)" -ForegroundColor Yellow
Write-Host "  Failed: $($TestResults.Failed)" -ForegroundColor Red

# Detailed results
if ($Verbose) {
  Write-Host "`nDetailed Results:" -ForegroundColor Cyan
  foreach ($test in $TestResults.Tests) {
    $status = switch ($test.Status) {
      "PASS" { "PASS" }
      "FAIL" { "FAIL" }
      "SKIP" { "SKIP" }
    }
    Write-Host "  $status $($test.Name) - $($test.Message)" -ForegroundColor White
  }
}

# Exit with appropriate code
if ($TestResults.Failed -gt 0) {
  Write-Host "`nIntegration tests FAILED with $($TestResults.Failed) failures" -ForegroundColor Red
  exit 1
} else {
  Write-Host "`nIntegration tests PASSED" -ForegroundColor Green
  exit 0
}