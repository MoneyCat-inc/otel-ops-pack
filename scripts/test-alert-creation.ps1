<#
.SYNOPSIS
  Test Alert Creation - Debug 400 Bad Request
.DESCRIPTION
  Creates a simple test alert to debug the 400 Bad Request issue
#>

[CmdletBinding()]
param(
  [string]$SigNozUrl = "http://localhost:8080",
  [string]$ApiKey
)

Write-Host "🧪 Test Alert Creation - Debug 400 Bad Request" -ForegroundColor Yellow

if (-not $ApiKey) {
  Write-Host "❌ ERROR: -ApiKey parameter required" -ForegroundColor Red
  exit 1
}

$headers = @{
  "SIGNOZ-API-KEY" = $ApiKey
  "Content-Type" = "application/json"
}

# Test 1: Minimal metric alert (like sentinel)
Write-Host "`n🔬 Test 1: Minimal Metric Alert" -ForegroundColor Cyan
$test1 = @{
  alert = "Test Alert 1"
  description = "Minimal test alert"
  alertType = "METRIC_BASED_ALERT"
  ruleType = "threshold_rule"
  severity = "warning"
  evalWindow = "5m"
  frequency = "1m"
  condition = @{
    compositeQuery = @{
      promQueries = @{
        A = @{
          query = "rate(otelcol_*_spans_received_total[5m]) > 0"
          disabled = $false
        }
      }
      queryType = "promql"
    }
    target = 0
    op = ">"
    matchType = "greater_than"
  }
  disabled = $false
}

try {
  $response1 = Invoke-RestMethod -Method POST -Uri ($SigNozUrl + "/api/v1/rules") -Headers $headers -Body ($test1 | ConvertTo-Json -Depth 20)
  Write-Host "✅ Test 1 SUCCESS: $($response1.id)" -ForegroundColor Green
} catch {
  Write-Host "❌ Test 1 FAILED: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 2: Alert with labels
Write-Host "`n🔬 Test 2: Alert with Labels" -ForegroundColor Cyan
$test2 = @{
  alert = "Test Alert 2"
  description = "Test alert with labels"
  alertType = "METRIC_BASED_ALERT"
  ruleType = "threshold_rule"
  severity = "warning"
  evalWindow = "5m"
  frequency = "1m"
  condition = @{
    compositeQuery = @{
      promQueries = @{
        A = @{
          query = "rate(otelcol_*_spans_received_total[5m]) > 0"
          disabled = $false
        }
      }
      queryType = "promql"
    }
    target = 0
    op = ">"
    matchType = "greater_than"
  }
  disabled = $false
  labels = @("test", "bosscat")
}

try {
  $response2 = Invoke-RestMethod -Method POST -Uri ($SigNozUrl + "/api/v1/rules") -Headers $headers -Body ($test2 | ConvertTo-Json -Depth 20)
  Write-Host "✅ Test 2 SUCCESS: $($response2.id)" -ForegroundColor Green
} catch {
  Write-Host "❌ Test 2 FAILED: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 3: Different query format
Write-Host "`n🔬 Test 3: Different Query Format" -ForegroundColor Cyan
$test3 = @{
  alert = "Test Alert 3"
  description = "Test with different query"
  alertType = "METRIC_BASED_ALERT"
  ruleType = "threshold_rule"
  severity = "warning"
  evalWindow = "5m"
  frequency = "1m"
  condition = @{
    compositeQuery = @{
      promQueries = @{
        A = @{
          query = "rate(otelcol_*_spans_received_total[5m]) == 0"
          disabled = $false
        }
      }
      queryType = "promql"
    }
    target = 0
    op = "=="
    matchType = "equal"
  }
  disabled = $false
}

try {
  $response3 = Invoke-RestMethod -Method POST -Uri ($SigNozUrl + "/api/v1/rules") -Headers $headers -Body ($test3 | ConvertTo-Json -Depth 20)
  Write-Host "✅ Test 3 SUCCESS: $($response3.id)" -ForegroundColor Green
} catch {
  Write-Host "❌ Test 3 FAILED: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n🎯 Test Complete - Check results above" -ForegroundColor Green
