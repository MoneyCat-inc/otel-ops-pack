<#
.SYNOPSIS
  BossCat Alert Cleanup - Remove duplicates and test alerts
.DESCRIPTION
  Identifies and removes duplicate BossCat alerts and test alerts via API.
  Keeps the newest version of each unique alert name and preserves the sentinel.
.USAGE
  # Dry run (safe, shows what would be deleted)
  pwsh -File scripts/bosscat-cleanup-alerts.ps1 -ApiKey $env:WYZWOZ_SIGNOZ

  # Execute deletions
  pwsh -File scripts/bosscat-cleanup-alerts.ps1 -ApiKey $env:WYZWOZ_SIGNOZ -Apply
#>

[CmdletBinding()]
param(
  [string]$SigNozUrl = "http://localhost:8080",
  [Parameter(Mandatory=$true)]
  [string]$ApiKey,
  [switch]$Apply
)

Write-Host "🐾 BossCat Alert Cleanup" -ForegroundColor Cyan
Write-Host "Authority: BossCat OEM" -ForegroundColor Cyan
Write-Host ("Mode: {0}" -f $(if ($Apply) { "APPLY (will delete)" } else { "DRY-RUN (safe preview)" })) -ForegroundColor $(if ($Apply) { "Red" } else { "Green" })
Write-Host ""

$headers = @{
  "SIGNOZ-API-KEY" = $ApiKey
  "Content-Type" = "application/json"
}

# Fetch all alerts
Write-Host "📋 Fetching current alerts..." -ForegroundColor Yellow
try {
  $response = Invoke-RestMethod -Method GET -Uri ($SigNozUrl + "/api/v1/rules") -Headers $headers
  $allRules = $response.data?.rules ?? $response.rules ?? $response
  Write-Host "✅ Found $($allRules.Count) total alerts" -ForegroundColor Green
} catch {
  Write-Host "❌ Failed to fetch alerts: $($_.Exception.Message)" -ForegroundColor Red
  exit 1
}

# Categorize alerts
$bosscatAlerts = @{}
$testAlerts = @()
$sentinelAlert = $null
$otherAlerts = @()

foreach ($rule in $allRules) {
  $name = $rule.alert ?? $rule.name ?? $rule.alertName ?? "Unknown"
  $id = $rule.id ?? $rule.ruleId ?? $rule._id
  
  if ($name -like "*BossCat*") {
    if ($name -eq "BossCat Sentinel Alert (API)") {
      $sentinelAlert = $rule
    } else {
      # Group by name for duplicate detection
      if (-not $bosscatAlerts.ContainsKey($name)) {
        $bosscatAlerts[$name] = @()
      }
      $bosscatAlerts[$name] += $rule
    }
  } elseif ($name -like "Test Alert*") {
    $testAlerts += $rule
  } else {
    $otherAlerts += $rule
  }
}

# Identify duplicates and items to delete
$toDelete = @()
$toKeep = @()

Write-Host "`n🔍 Analysis:" -ForegroundColor Cyan
Write-Host ""

# Process BossCat alerts (keep newest of each name)
foreach ($name in $bosscatAlerts.Keys) {
  $duplicates = $bosscatAlerts[$name]
  
  if ($duplicates.Count -gt 1) {
    Write-Host "⚠️  Duplicate: $name (found $($duplicates.Count) copies)" -ForegroundColor Yellow
    
    # Sort by ID (assuming higher ID = newer) and keep the last one
    $sorted = $duplicates | Sort-Object { $_.id ?? $_.ruleId ?? $_._id }
    $keep = $sorted[-1]
    $delete = $sorted[0..($sorted.Count-2)]
    
    $toKeep += $keep
    $toDelete += $delete
    
    Write-Host "   ✅ Keep: ID $($keep.id ?? $keep.ruleId ?? $keep._id)" -ForegroundColor Green
    foreach ($d in $delete) {
      Write-Host "   ❌ Delete: ID $($d.id ?? $d.ruleId ?? $d._id)" -ForegroundColor Red
    }
  } else {
    Write-Host "✅ Unique: $name" -ForegroundColor Green
    $toKeep += $duplicates[0]
  }
}

# Process test alerts (delete all)
if ($testAlerts.Count -gt 0) {
  Write-Host "`n🧪 Test Alerts (will delete):" -ForegroundColor Yellow
  foreach ($test in $testAlerts) {
    $name = $test.alert ?? $test.name ?? $test.alertName
    $id = $test.id ?? $test.ruleId ?? $test._id
    Write-Host "   ❌ Delete: $name (ID: $id)" -ForegroundColor Red
    $toDelete += $test
  }
}

# Sentinel alert (always keep)
if ($sentinelAlert) {
  Write-Host "`n🎯 Sentinel Alert (keeping):" -ForegroundColor Green
  $id = $sentinelAlert.id ?? $sentinelAlert.ruleId ?? $sentinelAlert._id
  Write-Host "   ✅ Keep: BossCat Sentinel Alert (API) (ID: $id)" -ForegroundColor Green
  $toKeep += $sentinelAlert
}

# Summary
Write-Host "`n📊 Summary:" -ForegroundColor Cyan
Write-Host "   Total alerts: $($allRules.Count)" -ForegroundColor White
Write-Host "   To keep: $($toKeep.Count + $otherAlerts.Count) (including $($otherAlerts.Count) non-BossCat)" -ForegroundColor Green
Write-Host "   To delete: $($toDelete.Count)" -ForegroundColor Red

# Expected final state
$expectedBossCat = 8  # 8 unique BossCat alerts
$expectedSentinel = 1
$expectedFinal = $expectedBossCat + $expectedSentinel + $otherAlerts.Count

Write-Host "`n🎯 Expected Final State:" -ForegroundColor Cyan
Write-Host "   BossCat alerts: $expectedBossCat" -ForegroundColor White
Write-Host "   Sentinel: $expectedSentinel" -ForegroundColor White
Write-Host "   Other alerts: $($otherAlerts.Count)" -ForegroundColor White
Write-Host "   Total: $expectedFinal" -ForegroundColor Green

# Execute deletions if -Apply
if ($Apply) {
  Write-Host "`n🚨 APPLYING DELETIONS..." -ForegroundColor Red
  
  $deleted = 0
  $failed = 0
  
  foreach ($rule in $toDelete) {
    $id = $rule.id ?? $rule.ruleId ?? $rule._id
    $name = $rule.alert ?? $rule.name ?? $rule.alertName
    
    try {
      $deleteUrl = "$SigNozUrl/api/v1/rules/$id"
      Invoke-RestMethod -Method DELETE -Uri $deleteUrl -Headers $headers | Out-Null
      Write-Host "   ✅ Deleted: $name (ID: $id)" -ForegroundColor Green
      $deleted++
    } catch {
      Write-Host "   ❌ Failed to delete: $name (ID: $id) - $($_.Exception.Message)" -ForegroundColor Red
      $failed++
    }
  }
  
  Write-Host "`n📊 Deletion Results:" -ForegroundColor Cyan
  Write-Host "   Deleted: $deleted" -ForegroundColor Green
  Write-Host "   Failed: $failed" -ForegroundColor $(if ($failed -gt 0) { "Red" } else { "Green" })
  
  if ($deleted -gt 0) {
    Write-Host "`n✅ Cleanup complete! Verifying final state..." -ForegroundColor Green
    
    # Re-fetch to verify
    try {
      $verifyResponse = Invoke-RestMethod -Method GET -Uri ($SigNozUrl + "/api/v1/rules") -Headers $headers
      $finalRules = $verifyResponse.data?.rules ?? $verifyResponse.rules ?? $verifyResponse
      $finalBossCat = ($finalRules | Where-Object { ($_.alert ?? $_.name ?? $_.alertName) -like "*BossCat*" }).Count
      
      Write-Host "`n🎯 Final State:" -ForegroundColor Cyan
      Write-Host "   Total alerts: $($finalRules.Count)" -ForegroundColor White
      Write-Host "   BossCat alerts: $finalBossCat" -ForegroundColor $(if ($finalBossCat -eq 9) { "Green" } else { "Yellow" })
      
      if ($finalBossCat -eq 9) {
        Write-Host "`n✅ SUCCESS: Clean state achieved (8 BossCat + 1 Sentinel)" -ForegroundColor Green
      } else {
        Write-Host "`n⚠️  Warning: Expected 9 BossCat alerts, found $finalBossCat" -ForegroundColor Yellow
      }
    } catch {
      Write-Host "`n⚠️  Could not verify final state" -ForegroundColor Yellow
    }
  }
} else {
  Write-Host "`n💡 DRY-RUN MODE: No changes made" -ForegroundColor Yellow
  Write-Host "   Run with -Apply to execute deletions" -ForegroundColor Cyan
}

Write-Host "`n🐾 BossCat Cleanup Complete" -ForegroundColor Green

if (-not $Apply) {
  exit 0
} elseif ($failed -gt 0) {
  exit 2
} else {
  exit 0
}

