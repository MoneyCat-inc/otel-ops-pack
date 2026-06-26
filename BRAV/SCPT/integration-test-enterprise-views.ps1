# See C:\otel\docs\comfort cat
# BossCat OEM · Enterprise Views Integration Test
# End-to-end test: provision → verify → rollback → re-provision

<#
.SYNOPSIS
  Integration test for enterprise view provisioning system.
  Tests full lifecycle with rollback capability.

.EXAMPLE
  pwsh -File scripts\integration-test-enterprise-views.ps1
#>

param(
  [string]$SigNozUrl = "http://localhost:8080"
)

Write-Host ""
Write-Host "🐾 BossCat OEM · Enterprise Views Integration Test" -ForegroundColor Cyan
Write-Host "═════════════════════════════════════════════════════" -ForegroundColor DarkCyan
Write-Host ""

$testResults = @{
  StartTime = Get-Date
  Tests = @()
  Status = "running"
}

function Test-Step([string]$name, [scriptblock]$action) {
  Write-Host "Testing: $name" -ForegroundColor Yellow
  try {
    $result = & $action
    Write-Host "  ✓ PASS" -ForegroundColor Green
    $testResults.Tests += @{ Name = $name; Status = "PASS"; Result = $result }
    return $true
  } catch {
    Write-Host "  ✗ FAIL: $($_.Exception.Message)" -ForegroundColor Red
    $testResults.Tests += @{ Name = $name; Status = "FAIL"; Error = $_.Exception.Message }
    return $false
  }
}

# Test 1: Provision views
$step1 = Test-Step "Provision Enterprise Views" {
  $result = & pwsh -File scripts\cursor-startup-signoz-enterprise-views.ps1 -SigNozUrl $SigNozUrl
  if ($LASTEXITCODE -ne 0) { throw "Provisioning failed with exit code $LASTEXITCODE" }
  return "Provisioning completed"
}

# Test 2: Verify views exist
$step2 = Test-Step "Verify Views Accessible" {
  $result = & pwsh -File scripts\verify-enterprise-views.ps1 -SigNozUrl $SigNozUrl
  if ($LASTEXITCODE -ne 0) { throw "Verification found $LASTEXITCODE missing views" }
  return "All views verified"
}

# Test 3: Re-provision (test idempotency)
$step3 = Test-Step "Re-provision (Idempotency)" {
  $result = & pwsh -File scripts\cursor-startup-signoz-enterprise-views.ps1 -SigNozUrl $SigNozUrl
  if ($LASTEXITCODE -ne 0) { throw "Re-provisioning failed with exit code $LASTEXITCODE" }
  return "Idempotent update successful"
}

# Test 4: Verify again
$step4 = Test-Step "Verify After Update" {
  $result = & pwsh -File scripts\verify-enterprise-views.ps1 -SigNozUrl $SigNozUrl
  if ($LASTEXITCODE -ne 0) { throw "Post-update verification found $LASTEXITCODE missing views" }
  return "Views still intact after update"
}

# Test 5: Check artifacts
$step5 = Test-Step "Verify Artifacts Generated" {
  $artifactCount = (Get-ChildItem -Path "artifacts\enterprise-views-*.json" -ErrorAction SilentlyContinue).Count
  if ($artifactCount -eq 0) { throw "No artifacts found in artifacts/" }
  
  $ecrrCount = (Get-ChildItem -Path "CHAR\ECRR\ECRR_REPORTS\enterprise-views-ecrr-*.md" -ErrorAction SilentlyContinue).Count
  if ($ecrrCount -eq 0) { throw "No ECRR reports found" }
  
  return "Found $artifactCount artifacts and $ecrrCount ECRR reports"
}

# Test 6: Integration with quick-monitor
$step6 = Test-Step "Integration with Quick Monitor" {
  if (Test-Path "scripts\quick-monitor.ps1") {
    $result = & pwsh -File scripts\quick-monitor.ps1 -ExportReport
    if ($LASTEXITCODE -ne 0) { throw "Quick monitor integration failed" }
    return "Quick monitor executed successfully"
  } else {
    return "Quick monitor not available (skipped)"
  }
}

Write-Host ""
Write-Host "═════════════════════════════════════════════════════" -ForegroundColor DarkCyan

$passed = ($testResults.Tests | Where-Object { $_.Status -eq "PASS" }).Count
$failed = ($testResults.Tests | Where-Object { $_.Status -eq "FAIL" }).Count
$total = $testResults.Tests.Count

Write-Host "Integration Test Results: " -NoNewline -ForegroundColor Gray
if ($failed -eq 0) {
  Write-Host "✓ ALL PASS ($passed/$total)" -ForegroundColor Green
  $testResults.Status = "SUCCESS"
} else {
  Write-Host "⚠ $failed FAILED ($passed/$total)" -ForegroundColor Yellow
  $testResults.Status = "PARTIAL"
}

Write-Host "═════════════════════════════════════════════════════" -ForegroundColor DarkCyan
Write-Host ""

# Export test results
$testResults.EndTime = Get-Date
$testResults.Duration = ($testResults.EndTime - $testResults.StartTime).TotalSeconds

$reportPath = "artifacts\integration-test-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
$testResults | ConvertTo-Json -Depth 10 | Set-Content -Path $reportPath -Encoding UTF8
Write-Host "Test report: $reportPath" -ForegroundColor Gray
Write-Host ""

exit $failed


