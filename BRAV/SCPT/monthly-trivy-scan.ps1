# Monthly Trivy Security Scan
# Part of 30-day remediation plan
# BossCat OEM - Post-Gate Monitoring

param(
    [switch]$ExportReport,
    [string]$OutputDir = "artifacts/security-scans"
)

$ErrorActionPreference = "Stop"

Write-Host "🐾 BossCat Monthly Security Scan" -ForegroundColor Cyan
Write-Host "Scanner: Trivy v0.67.0" -ForegroundColor Gray
Write-Host ""

# Ensure output directory exists
if ($ExportReport -and -not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

$timestamp = Get-Date -Format "yyyy-MM-dd-HHmmss"
$images = @(
    @{ Name = "SigNoz"; Image = "signoz/signoz:v0.96.1" }
    @{ Name = "OTel Collector"; Image = "signoz/signoz-otel-collector:v0.129.6" }
    @{ Name = "ClickHouse"; Image = "clickhouse/clickhouse-server:25.5.6" }
    @{ Name = "Zookeeper"; Image = "signoz/zookeeper:3.9.3" }
)

$results = @()

Write-Host "🔍 Scanning Docker images..." -ForegroundColor Yellow
Write-Host ""

foreach ($img in $images) {
    Write-Host "  Scanning $($img.Name)..." -ForegroundColor Cyan
    
    if ($ExportReport) {
        $jsonFile = Join-Path $OutputDir "$($img.Name.ToLower().Replace(' ','-'))-$timestamp.json"
        trivy image --severity CRITICAL,HIGH --format json $img.Image > $jsonFile
        $scanData = Get-Content $jsonFile | ConvertFrom-Json
    } else {
        $scanOutput = trivy image --severity CRITICAL,HIGH --format json $img.Image | ConvertFrom-Json
        $scanData = $scanOutput
    }
    
    # Count vulnerabilities
    $critical = 0
    $high = 0
    
    if ($scanData.Results) {
        foreach ($result in $scanData.Results) {
            if ($result.Vulnerabilities) {
                foreach ($vuln in $result.Vulnerabilities) {
                    if ($vuln.Severity -eq "CRITICAL") { $critical++ }
                    if ($vuln.Severity -eq "HIGH") { $high++ }
                }
            }
        }
    }
    
    $total = $critical + $high
    
    $results += [PSCustomObject]@{
        Image = $img.Name
        Critical = $critical
        High = $high
        Total = $total
        Status = if ($total -eq 0) { "✅ CLEAN" } elseif ($critical -eq 0) { "⚠️  HIGH only" } else { "🔴 CRITICAL" }
    }
    
    Write-Host "    CRITICAL: $critical, HIGH: $high, Total: $total" -ForegroundColor $(if ($total -eq 0) { "Green" } elseif ($critical -eq 0) { "Yellow" } else { "Red" })
}

Write-Host ""
Write-Host "📊 Scan Results Summary:" -ForegroundColor Cyan
Write-Host ""

$results | Format-Table -AutoSize

$totalCritical = ($results | Measure-Object -Property Critical -Sum).Sum
$totalHigh = ($results | Measure-Object -Property High -Sum).Sum
$totalVulns = ($results | Measure-Object -Property Total -Sum).Sum

Write-Host ""
Write-Host "🎯 Aggregate Statistics:" -ForegroundColor Cyan
Write-Host "  Total CRITICAL: $totalCritical" -ForegroundColor $(if ($totalCritical -eq 0) { "Green" } else { "Red" })
Write-Host "  Total HIGH: $totalHigh" -ForegroundColor $(if ($totalHigh -eq 0) { "Green" } else { "Yellow" })
Write-Host "  Grand Total: $totalVulns" -ForegroundColor $(if ($totalVulns -eq 0) { "Green" } elseif ($totalVulns -le 15) { "Yellow" } else { "Red" })
Write-Host ""

# Compare with baseline
$baseline = 31
$improvement = $baseline - $totalVulns
$percentChange = [math]::Round(($improvement / $baseline) * 100, 1)

Write-Host "📈 Progress vs Baseline (2025-10-09):" -ForegroundColor Cyan
Write-Host "  Baseline: $baseline vulnerabilities" -ForegroundColor Gray
Write-Host "  Current: $totalVulns vulnerabilities" -ForegroundColor $(if ($totalVulns -lt $baseline) { "Green" } elseif ($totalVulns -eq $baseline) { "Yellow" } else { "Red" })
Write-Host "  Change: $improvement vulnerabilities ($percentChange%)" -ForegroundColor $(if ($improvement -gt 0) { "Green" } elseif ($improvement -eq 0) { "Yellow" } else { "Red" })
Write-Host ""

# Goal tracking (target: <15 within 30 days)
$goal = 15
$remaining = $totalVulns - $goal
Write-Host "🎯 30-Day Goal Progress:" -ForegroundColor Cyan
Write-Host "  Goal: <$goal vulnerabilities" -ForegroundColor Gray
Write-Host "  Current: $totalVulns" -ForegroundColor $(if ($totalVulns -le $goal) { "Green" } else { "Yellow" })
Write-Host "  Remaining: $remaining to reach goal" -ForegroundColor $(if ($remaining -le 0) { "Green" } else { "Yellow" })
Write-Host ""

if ($ExportReport) {
    # Generate summary JSON
    $summaryFile = Join-Path $OutputDir "scan-summary-$timestamp.json"
    $summary = @{
        timestamp = $timestamp
        scanner = "Trivy v0.67.0"
        total_critical = $totalCritical
        total_high = $totalHigh
        total_vulnerabilities = $totalVulns
        baseline = $baseline
        improvement = $improvement
        percent_change = $percentChange
        goal = $goal
        remaining_to_goal = $remaining
        images = $results
    }
    $summary | ConvertTo-Json -Depth 10 | Out-File $summaryFile -Encoding UTF8
    
    Write-Host "💾 Reports exported to: $OutputDir" -ForegroundColor Green
    Write-Host "  Summary: $summaryFile" -ForegroundColor Gray
    Write-Host ""
}

Write-Host "✅ Monthly security scan complete" -ForegroundColor Green
Write-Host "🐾 BossCat: Monitoring vulnerability remediation progress" -ForegroundColor Cyan

