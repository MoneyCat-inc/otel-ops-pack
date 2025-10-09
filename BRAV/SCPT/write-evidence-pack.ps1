# BossCat OEM - Evidence Pack Generator
# Collects verification artifacts, service state, and logs into timestamped zip for audits

param(
  [string]$CollectorName = "signoz-otel-collector",
  [string]$OutDir = "out"
)

function Write-EvidencePack {
  param(
    [string]$CollectorName = "signoz-otel-collector",
    [string]$OutDir = "out"
  )
  
  $ts = (Get-Date).ToUniversalTime().ToString("yyyyMMdd-HHmmssZ")
  $caseDir = Join-Path $OutDir "evidence-$ts"
  
  Write-Host "📦 [evidence] Creating evidence pack..." -ForegroundColor Cyan
  New-Item -ItemType Directory -Force -Path $caseDir | Out-Null

  # Copy core verification artifacts
  $src = @(
    "out\gate_verification.json",
    "docs\ecrr\gate_decision.json",
    "docs\ecrr\GATE_STATUS.md",
    "docs\IONA_ERRORS.md"
  )
  
  foreach ($p in $src) { 
    if (Test-Path $p) { 
      Copy-Item $p $caseDir -Force 
      Write-Host "   ✓ Copied: $p" -ForegroundColor Gray
    } else {
      Write-Host "   ⚠ Missing: $p" -ForegroundColor Yellow
    }
  }

  # Capture Windows OTel Collector service state
  try {
    Get-Service otelcol-contrib -ErrorAction SilentlyContinue | 
      Format-List * > (Join-Path $caseDir "service_otelcol.txt") 2>$null
    Write-Host "   ✓ Captured: Windows collector service state" -ForegroundColor Gray
  } catch {
    Write-Host "   ⚠ Could not capture Windows collector state" -ForegroundColor Yellow
  }
  
  # Capture Docker container state
  try {
    docker ps --all --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" > (Join-Path $caseDir "docker_ps.txt") 2>$null
    Write-Host "   ✓ Captured: Docker container state" -ForegroundColor Gray
  } catch {
    Write-Host "   ⚠ Docker not available" -ForegroundColor Yellow
  }
  
  # Capture collector logs (last 10 minutes)
  try {
    docker logs --since 10m $CollectorName > (Join-Path $caseDir "collector_logs_10m.txt") 2>$null
    Write-Host "   ✓ Captured: Collector logs (10min)" -ForegroundColor Gray
  } catch {
    Write-Host "   ⚠ Could not capture collector logs" -ForegroundColor Yellow
  }
  
  # Add timestamp and metadata
  $metadata = @"
BossCat Evidence Pack
=====================
Generated: $ts
Collector: $CollectorName
Gate ID: GATE-2025-10-08-234500

Contents:
- gate_verification.json: Latest verification results
- gate_decision.json: Gate decision document
- GATE_STATUS.md: Current gate status
- IONA_ERRORS.md: Error ledger
- service_otelcol.txt: Windows collector service state
- docker_ps.txt: Docker container state
- collector_logs_10m.txt: Collector logs (last 10 minutes)

This evidence pack can be provided to auditors or incident responders.
"@
  $metadata | Out-File -Encoding UTF8 (Join-Path $caseDir "README.txt")

  # Create zip archive
  $zip = Join-Path $OutDir "evidence-$ts.zip"
  if (Test-Path $zip) { Remove-Item $zip -Force }
  
  try {
    Compress-Archive -Path (Join-Path $caseDir "*") -DestinationPath $zip -Force
    Write-Host "✅ Evidence pack created: $zip" -ForegroundColor Green
    
    # Show file size
    $fileSize = (Get-Item $zip).Length
    $fileSizeKB = [math]::Round($fileSize / 1KB, 2)
    Write-Host "   Size: $fileSizeKB KB" -ForegroundColor Gray
    
    # Clean up temp directory
    Remove-Item $caseDir -Recurse -Force
    
    return $zip
  } catch {
    Write-Error "Failed to create evidence pack: $_"
    return $null
  }
}

# Execute if run directly
if ($MyInvocation.InvocationName -ne '.') {
  Write-EvidencePack -CollectorName $CollectorName -OutDir $OutDir
}

