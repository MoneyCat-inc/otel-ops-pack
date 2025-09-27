[CmdletBinding()]
param(
    [Parameter()]
    [string]$DashboardPath = "config/signoz-optimization-dashboard.json",

    [Parameter()]
    [string]$Endpoint = "http://localhost:8080/api/v1/dashboards",

    [Parameter()]
    [string]$ApiToken,

    [switch]$DryRun
)

# Import progress indicators module
. .\scripts\progress-indicators.ps1

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-SigNozHeaders {
    param([string]$Token)

    $resolved = if ($Token) { $Token } elseif ($env:SIGNOZ_API_TOKEN) { $env:SIGNOZ_API_TOKEN } elseif ($env:SIGNOZ_API_BEARER) { $env:SIGNOZ_API_BEARER } elseif ($env:SIGNOZ_JWT) { $env:SIGNOZ_JWT } else { $null }

    $headers = @{ "Content-Type" = "application/json" }
    if ($resolved) {
        $headers["Authorization"] = "Bearer $resolved"
    }
    return @{ Token = $resolved; Headers = $headers }
}

function Test-SigNozEndpoint {
    param(
        [string]$Url,
        [hashtable]$Headers
    )

    $spinnerJob = Start-SpinnerJob -Message "Testing SigNoz endpoint..." -UpdateIntervalMs 150
    try {
        Invoke-WebRequest -Uri $Url -Method Head -Headers $Headers -TimeoutSec 5 | Out-Null
        Stop-SpinnerJob -Job $spinnerJob
        return $true
    } catch {
        Stop-SpinnerJob -Job $spinnerJob
        return $false
    }
}

Write-Host "[INFO] SigNoz dashboard import" -ForegroundColor Cyan

if (-not (Test-Path -LiteralPath $DashboardPath)) {
    Write-Host "[ERROR] Dashboard file not found: $DashboardPath" -ForegroundColor Red
    throw "Missing dashboard file"
}

$dashboardFullPath = (Resolve-Path -LiteralPath $DashboardPath).Path
$dashboardJson = Get-Content -LiteralPath $dashboardFullPath -Raw
$dashboardObject = $null
try {
    $dashboardObject = $dashboardJson | ConvertFrom-Json -ErrorAction Stop
} catch {
    throw "Dashboard JSON is not valid: $($_.Exception.Message)"
}

$title = $dashboardObject.title
$panelCount = 0
if ($dashboardObject.panels -is [System.Collections.IEnumerable]) {
    $panelCount = ($dashboardObject.panels | Measure-Object).Count
}

Write-Host "[INFO] Using file: $dashboardFullPath" -ForegroundColor Green
Write-Host "[INFO] Dashboard title: $title" -ForegroundColor Green
Write-Host "[INFO] Panel count: $panelCount" -ForegroundColor Green

$headerInfo = Get-SigNozHeaders -Token $ApiToken
if ($headerInfo.Token) {
    Write-Host "[INFO] Authentication token detected" -ForegroundColor Green
} else {
    Write-Host "[WARN] No authentication token found; import may require manual confirmation" -ForegroundColor Yellow
}

$apiHealthy = Test-SigNozEndpoint -Url $Endpoint -Headers $headerInfo.Headers
if ($apiHealthy) {
    Write-Host "[INFO] SigNoz endpoint reachable: $Endpoint" -ForegroundColor Green
} else {
    Write-Host "[WARN] Unable to reach SigNoz endpoint. Verify SigNoz UI is running." -ForegroundColor Yellow
}

$timestamp = (Get-Date).ToString("yyyyMMdd-HHmmss")
$reportPath = "artifacts/dashboard-import-$timestamp.json"

if ($DryRun) {
    Write-Host "[INFO] Dry run enabled. Skipping API call." -ForegroundColor Cyan
} else {
    Write-Host "[INFO] Importing dashboard via POST $Endpoint" -ForegroundColor Cyan
    try {
        $response = Invoke-RestMethod -Uri $Endpoint -Method Post -Headers $headerInfo.Headers -Body $dashboardJson
        Write-Host "[INFO] Dashboard import request accepted" -ForegroundColor Green
    } catch {
        Write-Host "[ERROR] Dashboard import failed: $($_.Exception.Message)" -ForegroundColor Red
        throw
    }
}

$report = [pscustomobject]@{
    timestamp = (Get-Date).ToString("o")
    dashboardPath = $dashboardFullPath
    endpoint = $Endpoint
    panelCount = $panelCount
    dryRun = [bool]$DryRun
    apiReachable = $apiHealthy
}

$report | ConvertTo-Json -Depth 5 | Out-File -FilePath $reportPath -Encoding utf8NoBOM
Write-Host "[INFO] Report saved to $reportPath" -ForegroundColor Green

Write-Host "[NEXT] Open SigNoz UI at http://localhost:8080/dashboards to confirm the dashboard" -ForegroundColor White
Write-Host "[NEXT] If dry run, rerun without -DryRun to import" -ForegroundColor White
