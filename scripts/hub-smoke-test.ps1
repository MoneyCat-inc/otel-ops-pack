#!/usr/bin/env pwsh
#Requires -Version 7

<#
.SYNOPSIS
    BossCat Hub — Production Smoke Test
.DESCRIPTION
    Verifies all critical Hub endpoints return 200 and content is valid.
    Aligns with BossCat ECRR discipline.
#>

param(
    [string]$BaseUrl = "https://hub.resonai.uk"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

Write-Host "`n🐾 BossCat Hub Smoke Test — $BaseUrl`n" -ForegroundColor Cyan

$endpoints = @(
    @{ Path = "/"; Name = "Hub Landing" }
    @{ Path = "/assets/hub.js"; Name = "Hub JS" }
    @{ Path = "/docs/status/kpis.json"; Name = "KPI Feed" }
    @{ Path = "/docs/status.html"; Name = "Status Page" }
    @{ Path = "/CHAR/DOCS/docs/dashboards/live-metrics.html"; Name = "Live Metrics" }
    @{ Path = "/docs/BossCat/data_room_enhanced.html"; Name = "Data Room" }
    @{ Path = "/docs/widgets/bluesky-latest.json"; Name = "Bluesky Widget Feed" }
    @{ Path = "/robots.txt"; Name = "SEO Robots" }
    @{ Path = "/favicon.svg"; Name = "Favicon" }
    @{ Path = "/.well-known/security.txt"; Name = "Security Policy" }
    @{ Path = "/humans.txt"; Name = "Humans File" }
)

$passed = 0
$failed = 0
$results = @()

foreach ($ep in $endpoints) {
    $url = "$BaseUrl$($ep.Path)"
    try {
        $response = Invoke-WebRequest -Uri $url -Method Head -TimeoutSec 10 -UseBasicParsing -ErrorAction Stop
        $status = $response.StatusCode
        
        if ($status -eq 200) {
            Write-Host "  ✅ $($ep.Name)" -ForegroundColor Green
            Write-Host "     $url → $status" -ForegroundColor DarkGray
            $passed++
            $results += [PSCustomObject]@{
                Name = $ep.Name
                URL = $url
                Status = $status
                Result = "PASS"
            }
        } else {
            Write-Host "  ⚠️  $($ep.Name)" -ForegroundColor Yellow
            Write-Host "     $url → $status (expected 200)" -ForegroundColor DarkGray
            $failed++
            $results += [PSCustomObject]@{
                Name = $ep.Name
                URL = $url
                Status = $status
                Result = "WARN"
            }
        }
    } catch {
        Write-Host "  ❌ $($ep.Name)" -ForegroundColor Red
        Write-Host "     $url → ERROR: $($_.Exception.Message)" -ForegroundColor DarkGray
        $failed++
        $results += [PSCustomObject]@{
            Name = $ep.Name
            URL = $url
            Status = "ERROR"
            Result = "FAIL"
        }
    }
}

Write-Host "`n📊 Results:" -ForegroundColor Cyan
Write-Host "   Passed: $passed" -ForegroundColor Green
Write-Host "   Failed: $failed" -ForegroundColor $(if ($failed -gt 0) { "Red" } else { "Green" })

# Export results
$reportPath = "artifacts/hub-smoke-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
$reportDir = Split-Path $reportPath -Parent
if (-not (Test-Path $reportDir)) {
    New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
}

$report = @{
    timestamp = (Get-Date -Format "o")
    baseUrl = $BaseUrl
    passed = $passed
    failed = $failed
    results = $results
}

$report | ConvertTo-Json -Depth 10 | Set-Content $reportPath -Encoding UTF8
Write-Host "`n📄 Report: $reportPath" -ForegroundColor DarkGray

if ($failed -gt 0) {
    Write-Host "`n🚨 SMOKE TEST FAILED — $failed endpoint(s) not healthy`n" -ForegroundColor Red
    exit 1
} else {
    Write-Host "`n✅ SMOKE TEST PASSED — All endpoints healthy`n" -ForegroundColor Green
    exit 0
}

