[CmdletBinding()]
param(
    [string]$AlertDirectory = "config",
    [string]$Pattern = "signoz-alert-*.json",
    [string]$Endpoint = "http://localhost:8080/api/v1/alerts",
    [string]$ApiToken,
    [switch]$DryRun
)

# Import progress indicators module
. .\scripts\progress-indicators.ps1

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-PropertyValue {
    param(
        $Object,
        [string]$Name
    )

    if ($null -eq $Object) { return $null }
    $prop = $Object.PSObject.Properties[$Name]
    if ($prop) { return $prop.Value }
    return $null
}

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

Write-Host "[INFO] SigNoz alert setup" -ForegroundColor Cyan

if (-not (Test-Path -LiteralPath $AlertDirectory)) {
    throw "Alert directory not found: $AlertDirectory"
}

$alertFiles = Get-ChildItem -Path $AlertDirectory -Filter $Pattern -File | Sort-Object Name
if (-not $alertFiles) {
    throw "No alert definition files matching $Pattern were found in $AlertDirectory"
}

Write-Host "[INFO] Found $($alertFiles.Count) alert definitions" -ForegroundColor Green

$headerInfo = Get-SigNozHeaders -Token $ApiToken
if ($headerInfo.Token) {
    Write-Host "[INFO] Authentication token detected" -ForegroundColor Green
} else {
    Write-Host "[WARN] No authentication token found; API calls may fail" -ForegroundColor Yellow
}

$apiHealthy = Test-SigNozEndpoint -Url $Endpoint -Headers $headerInfo.Headers
if ($apiHealthy) {
    Write-Host "[INFO] SigNoz endpoint reachable: $Endpoint" -ForegroundColor Green
} else {
    Write-Host "[WARN] Unable to reach SigNoz endpoint" -ForegroundColor Yellow
}

$timestamp = (Get-Date).ToString("yyyyMMdd-HHmmss")
$reportPath = "artifacts/alerts-setup-$timestamp.json"
$results = @()

foreach ($file in $alertFiles) {
    $raw = Get-Content -LiteralPath $file.FullName -Raw
    $obj = $null
    try {
        $obj = $raw | ConvertFrom-Json -ErrorAction Stop
    } catch {
        throw "Alert JSON is invalid in $($file.Name): $($_.Exception.Message)"
    }

    $alertName = Get-PropertyValue -Object $obj -Name 'name'
    if (-not $alertName) {
        $alertName = Get-PropertyValue -Object (Get-PropertyValue -Object $obj -Name 'spec') -Name 'name'
    }
    if (-not $alertName) { $alertName = $file.BaseName }

    $severity = Get-PropertyValue -Object $obj -Name 'severity'
    if (-not $severity) {
        $severity = Get-PropertyValue -Object (Get-PropertyValue -Object $obj -Name 'spec') -Name 'severity'
    }
    if (-not $severity) {
        $severity = Get-PropertyValue -Object (Get-PropertyValue -Object $obj -Name 'condition') -Name 'severity'
    }

    Write-Host "[INFO] Alert: $alertName ($severity) from $($file.Name)" -ForegroundColor White

    $entry = [pscustomobject]@{
        file = $file.FullName
        name = $alertName
        severity = $severity
        dryRun = [bool]$DryRun
        imported = $false
    }

    if ($DryRun) {
        Write-Host "[INFO] Dry run - skipping import for $alertName" -ForegroundColor Cyan
    } else {
        try {
            Invoke-RestMethod -Uri $Endpoint -Method Post -Headers $headerInfo.Headers -Body $raw | Out-Null
            Write-Host "[INFO] Created or updated alert $alertName" -ForegroundColor Green
            $entry.imported = $true
        } catch {
            Write-Host ("[ERROR] Failed to create alert {0}: {1}" -f $alertName, $_.Exception.Message) -ForegroundColor Red
            throw
        }
    }

    $results += $entry
}

$results | ConvertTo-Json -Depth 5 | Out-File -FilePath $reportPath -Encoding utf8NoBOM
Write-Host "[INFO] Report saved to $reportPath" -ForegroundColor Green

Write-Host "[NEXT] Review alerts in SigNoz UI at http://localhost:8080/alerts" -ForegroundColor White
Write-Host "[NEXT] Use scripts/simple-optimization-test.ps1 to trigger sample data" -ForegroundColor White
