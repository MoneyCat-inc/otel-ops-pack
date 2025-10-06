#Requires -Version 7.0

<#
.SYNOPSIS
  BossCat nightly SigNoz dashboard export with integrated security scanning.
.DESCRIPTION
  Exports configured SigNoz dashboards to PDF, runs Trivy security scans,
  and logs results for ECRR review.
.PARAMETER SignozUrl
  Base URL for the SigNoz UI.
.PARAMETER SignozSession
  Session cookie value for authenticating to SigNoz. If omitted the export
  proceeds without cookie injection.
.PARAMETER DashboardListPath
  Path to the dashboard list JSON file. Defaults to scripts/dashboard-list.json.
.PARAMETER OutputRoot
  Directory where PDFs are written. Defaults to docs/observability/snapshots.
.PARAMETER ReportDir
  Directory where summary reports are written. Defaults to docs/ecrr/ECRR_REPORTS.
.PARAMETER SecurityScanDir
  Directory where security scan reports are written. Defaults to artifacts/security-scans.
.PARAMETER DryRun
  When supplied, performs validation only and skips PDF generation.
#>

[CmdletBinding()]
param(
  [string]$SignozUrl = "http://localhost:8080",
  [string]$SignozSession = "",
  [string]$DashboardListPath = "scripts/dashboard-list.json",
  [string]$OutputRoot = "docs/observability/snapshots",
  [string]$ReportDir = "docs/ecrr/ECRR_REPORTS",
  [string]$SecurityScanDir = "artifacts/security-scans",
  [switch]$DryRun
)

$ErrorActionPreference = "Stop"

function Write-Info([string]$message)  { Write-Host $message -ForegroundColor Cyan }
function Write-Success([string]$message) { Write-Host $message -ForegroundColor Green }
function Write-Warn([string]$message) { Write-Warning $message }

function Invoke-TrivySecurityScan {
  param(
    [string]$OutputDir
  )
  
  Write-Info "🔒 Running Trivy security scans..."
  
  # Ensure Trivy is available
  if (-not (Get-Command "trivy" -ErrorAction SilentlyContinue)) {
    Write-Warn "Trivy not found in PATH. Skipping security scans."
    return $false
  }
  
  # Define images to scan
  $images = @(
    "signoz/signoz-otel-collector:latest",
    "signoz/signoz:latest", 
    "clickhouse/clickhouse-server:25.5.6",
    "signoz/zookeeper:3.9.3"
  )
  
  $scanResults = @()
  $totalCritical = 0
  $totalHigh = 0
  
  foreach ($image in $images) {
    Write-Info "Scanning $image..."
    
    $imageName = $image -replace "[:/]", "_"
    $scanFile = Join-Path $OutputDir "trivy-$imageName-$(Get-Date -Format 'yyyyMMdd').json"
    
    try {
      # Run Trivy scan
      $scanOutput = & trivy image --severity HIGH,CRITICAL --format json --output $scanFile $image 2>&1
      
      if ($LASTEXITCODE -eq 0) {
        # Parse results
        $scanData = Get-Content $scanFile | ConvertFrom-Json
        $critical = ($scanData.Results | Where-Object { $_.Vulnerabilities } | ForEach-Object { $_.Vulnerabilities } | Where-Object { $_.Severity -eq "CRITICAL" }).Count
        $high = ($scanData.Results | Where-Object { $_.Vulnerabilities } | ForEach-Object { $_.Vulnerabilities } | Where-Object { $_.Severity -eq "HIGH" }).Count
        
        $totalCritical += $critical
        $totalHigh += $high
        
        $scanResults += [PSCustomObject]@{
          Image = $image
          Critical = $critical
          High = $high
          ScanFile = $scanFile
          Timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
        }
        
        Write-Success "✅ $image`: $critical critical, $high high vulnerabilities"
      } else {
        Write-Warn "⚠️ Failed to scan $image`: $scanOutput"
      }
    } catch {
      Write-Warn "⚠️ Error scanning $image`: $($_.Exception.Message)"
    }
  }
  
  # Generate summary report
  $summaryFile = Join-Path $OutputDir "trivy-summary-$(Get-Date -Format 'yyyyMMdd').json"
  $summary = [PSCustomObject]@{
    Timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
    TotalImages = $images.Count
    TotalCritical = $totalCritical
    TotalHigh = $totalHigh
    ScanResults = $scanResults
    Status = if ($totalCritical -eq 0) { "PASS" } else { "FAIL" }
  }
  
  $summary | ConvertTo-Json -Depth 3 | Set-Content $summaryFile
  Write-Success "🔒 Security scan summary: $totalCritical critical, $totalHigh high vulnerabilities"
  
  return $true
}

function Ensure-Directory([string]$Path) {
  if (-not (Test-Path $Path)) {
    New-Item -ItemType Directory -Path $Path -Force | Out-Null
  }
  return (Resolve-Path $Path).Path
}

function Get-EdgePath {
  $candidates = @()

  if ($env:ProgramFiles) {
    $candidates += (Join-Path $env:ProgramFiles "Microsoft/Edge/Application/msedge.exe")
  }

  if (${env:ProgramFiles(x86)}) {
    $candidates += (Join-Path ${env:ProgramFiles(x86)} "Microsoft/Edge/Application/msedge.exe")
  }

  foreach ($candidate in $candidates) {
    if ($candidate -and (Test-Path $candidate)) {
      return $candidate
    }
  }

  throw "Microsoft Edge executable not found. Please install Edge or update the path."
}

function Invoke-EdgeExport {
  param(
    [string]$EdgePath,
    [string]$DashboardUrl,
    [string]$Destination,
    [string]$SessionCookie
  )

  $tempRoot = Ensure-Directory (Join-Path $env:TEMP ("bosscat-edge-" + [guid]::NewGuid().ToString("N")))
  $bootstrapPath = Join-Path $tempRoot "bootstrap.html"

  if ([string]::IsNullOrEmpty($SessionCookie)) {
    $bootstrapHtml = @"
<!doctype html>
<meta charset="utf-8">
<script>
  window.location.replace("$DashboardUrl");
</script>
"@
  } else {
    $encodedSession = [System.Text.Encodings.Web.JavaScriptEncoder]::Default.Encode($SessionCookie)
    $targetHost = ([System.Uri]$DashboardUrl).Host
    $domainSegment = if ([string]::IsNullOrEmpty($targetHost) -or $targetHost -eq 'localhost') { '' } else { "; domain=$targetHost" }
    $bootstrapHtml = @"
<!doctype html>
<meta charset="utf-8">
<script>
  document.cookie = "signoz-session=$encodedSession$domainSegment; path=/; SameSite=Lax";
  window.location.replace("$DashboardUrl");
</script>
"@
  }

  Set-Content -Path $bootstrapPath -Value $bootstrapHtml -Encoding UTF8

  $arguments = @(
    "--headless=new",
    "--no-sandbox",
    "--disable-gpu",
    "--user-data-dir=$tempRoot",
    "--window-size=1920,1080",
    "--virtual-time-budget=20000",
    "--print-to-pdf=$Destination",
    "--print-to-pdf-no-header",
    $bootstrapPath
  )

  $process = Start-Process -FilePath $EdgePath -ArgumentList $arguments -PassThru -Wait -WindowStyle Hidden
  if ($process.ExitCode -ne 0) {
    throw "Edge exited with code $($process.ExitCode)"
  }

  Start-Sleep -Seconds 2

  if (-not (Test-Path $Destination)) {
    throw "PDF was not produced at $Destination"
  }

  Remove-Item $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host "BossCat Nightly Dashboard Export (Edge)"
Write-Host "Signoz URL: $SignozUrl"
Write-Host "Dry Run: $($DryRun.IsPresent)"
Write-Host ""

try {
  $healthUri = "{0}/api/v1/health" -f $SignozUrl.TrimEnd('/')
  $null = Invoke-RestMethod -Uri $healthUri -Method Get -TimeoutSec 10
  Write-Success "SigNoz health check passed."
} catch {
  Write-Warn "SigNoz health check failed: $($_.Exception.Message)"
  if (-not $DryRun) {
    throw
  }
}

if (-not (Test-Path $DashboardListPath)) {
  Write-Warn "Dashboard list not found at $DashboardListPath. Creating defaults."
  $defaultDashboards = @(
    @{ name = "Windows Logs"; slug = "windows-logs" },
    @{ name = "Queue Pressure"; slug = "queue-pressure" }
  )
  $defaultDashboards | ConvertTo-Json -Depth 3 | Set-Content -Path $DashboardListPath -Encoding UTF8
}

$dashboards = Get-Content -Raw -Path $DashboardListPath | ConvertFrom-Json
if (-not $dashboards) {
  throw "Dashboard list is empty."
}
Write-Success "Loaded $($dashboards.Count) dashboards."

$edgePath = Get-EdgePath
Write-Success "Using Edge at $edgePath"

$outputRootResolved = Ensure-Directory $OutputRoot
$reportDirResolved = Ensure-Directory $ReportDir
$timestamp = Get-Date -Format "yyyy-MM-dd-HHmmss"
$runDir = Ensure-Directory (Join-Path $outputRootResolved $timestamp)

if ($DryRun) {
  Write-Info "Dry-run complete. Directories verified at $runDir"
  exit 0
}

$results = @()
$failures = @()

foreach ($dashboard in $dashboards) {
  $name = $dashboard.name
  $slug = $dashboard.slug
  if (-not $slug) {
    Write-Warn "Skipping dashboard with missing slug."
    continue
  }
  $targetUrl = "$SignozUrl/short-url/redirect-to-dashboard/$slug"
  $destination = Join-Path $runDir ("bosscat-{0}-{1}.pdf" -f ($slug -replace "[^A-Za-z0-9-]", "-"), $timestamp)

  Write-Info "Exporting $name ($slug)"
  try {
    Invoke-EdgeExport -EdgePath $edgePath -DashboardUrl $targetUrl -Destination $destination -SessionCookie $SignozSession
    $sizeKb = [Math]::Round((Get-Item $destination).Length / 1KB, 2)
    Write-Success "  PDF created ($sizeKb KB)"
    $results += [pscustomobject]@{
      dashboard = $name
      slug       = $slug
      file       = $destination
      size_kb    = $sizeKb
      status     = "success"
      timestamp  = (Get-Date).ToString("o")
    }
  } catch {
    $msg = "Export failed: $($_.Exception.Message)"
    Write-Warn "  $msg"
    $failures += [pscustomobject]@{
      dashboard = $name
      slug       = $slug
      error      = $msg
      timestamp  = (Get-Date).ToString("o")
    }
  }
}

$summary = [pscustomobject]@{
  run_id      = $timestamp
  started_at  = (Get-Date).ToString("o")
  signoz_url  = $SignozUrl
  outputs_dir = $runDir
  successes   = $results
  failures    = $failures
  security_scan = @{
    enabled = $securityScanSuccess
    scan_dir = $securityScanDirResolved
    timestamp = (Get-Date).ToString("o")
  }
}

$summaryPath = Join-Path $runDir "bosscat-export-summary.json"
$summary | ConvertTo-Json -Depth 6 | Set-Content -Path $summaryPath -Encoding UTF8
Write-Success "Summary written to $summaryPath"

$reportPath = Join-Path $reportDirResolved ("{0}_nightly_dashboard_export.md" -f (Get-Date -Format "yyyy-MM-dd"))
$reportLines = @(
  "# ECRR Nightly Dashboard Export",
  "Run ID: $timestamp",
  "SigNoz URL: $SignozUrl",
  "Outputs: $runDir",
  "",
  "## Security Scan Results",
  $(if ($securityScanSuccess) { "✅ Security scans completed successfully" } else { "⚠️ Security scans skipped or failed" }),
  "Scan directory: $securityScanDirResolved",
  "",
  "## Successful Exports"
)

foreach ($item in $results) {
  $reportLines += "- $($item.dashboard) -> $($item.file) ($($item.size_kb) KB)"
}

if ($failures.Count -gt 0) {
  $reportLines += ""
  $reportLines += "## Failed Exports"
  foreach ($item in $failures) {
    $reportLines += "- $($item.dashboard): $($item.error)"
  }
}

Set-Content -Path $reportPath -Value ($reportLines -join [Environment]::NewLine) -Encoding UTF8
Write-Success "Report written to $reportPath"

if ($failures.Count -gt 0) {
  throw "Completed with $($failures.Count) export failure(s)."
}

Write-Success "All dashboards exported successfully."
















