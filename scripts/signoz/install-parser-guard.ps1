[CmdletBinding()]
param(
    [string]$SigNozUrl = 'http://localhost:8080',
    [switch]$SkipView,
    [switch]$SkipAlert,
    [switch]$SkipLaunch,
    [switch]$SkipClipboard
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

try {
    $baseUri = [System.Uri]::new($SigNozUrl)
}
catch {
    throw "Invalid SigNozUrl: $SigNozUrl"
}

function Resolve-Uri {
    param([string]$Relative)
    return [System.Uri]::new($baseUri, $Relative).AbsoluteUri
}

$root = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$viewPath = Join-Path $root 'signoz-parser-error-view.json'
$alertPath = Join-Path $root 'signoz-parser-error-alert.json'

function Get-JsonAsset {
    param(
        [string]$Path,
        [string]$Kind
    )

    if (-not (Test-Path $Path)) {
        throw "Missing $Kind asset: $Path"
    }

    $raw = Get-Content -Path $Path -Raw -Encoding UTF8
    try {
        $parsed = $raw | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        throw "Invalid $Kind JSON at ${Path}: $($_.Exception.Message)"
    }

    return [pscustomobject]@{
        Path = $Path
        Raw = $raw
        Parsed = $parsed
    }
}

Write-Host '=== SigNoz Parser Guard Import Prep ===' -ForegroundColor Cyan
Write-Host "Base URL: $SigNozUrl" -ForegroundColor Gray

try {
    $health = Invoke-RestMethod -Uri (Resolve-Uri 'api/v1/health') -Method Get -TimeoutSec 5
    Write-Host "SigNoz health: $($health.status)" -ForegroundColor Green
}
catch {
    Write-Host "SigNoz health check failed: $($_.Exception.Message)" -ForegroundColor Red
    throw
}

if (-not $SkipView) {
    $view = Get-JsonAsset -Path $viewPath -Kind 'saved view'
    Write-Host "`nSaved view ready: $($view.Parsed.name)" -ForegroundColor Yellow
    Write-Host "  Description: $($view.Parsed.description)" -ForegroundColor Gray
    if ($view.Parsed.query.filters) {
        foreach ($filter in $view.Parsed.query.filters) {
            Write-Host "  Filter: $($filter.key) $($filter.operator) '$($filter.value)'" -ForegroundColor Gray
        }
    }

    if (-not $SkipClipboard) {
        Set-Clipboard -Value $view.Raw
        Write-Host '  -> JSON copied to clipboard' -ForegroundColor Green
    }
    else {
        Write-Host '  -> Clipboard copy skipped' -ForegroundColor DarkYellow
    }

    Write-Host '  Steps: SigNoz UI -> Logs -> Saved Views -> New -> JSON tab -> paste -> Save' -ForegroundColor White
    if (-not $SkipLaunch) {
        Start-Process (Resolve-Uri 'logs') | Out-Null
    }
}
else {
    Write-Host 'Skipping saved view staging (--SkipView).' -ForegroundColor DarkYellow
}

if (-not $SkipAlert) {
    $alert = Get-JsonAsset -Path $alertPath -Kind 'alert'
    Write-Host "`nAlert ready: $($alert.Parsed.name)" -ForegroundColor Yellow
    Write-Host "  Description: $($alert.Parsed.description)" -ForegroundColor Gray
    if ($alert.Parsed.query.filters) {
        foreach ($filter in $alert.Parsed.query.filters) {
            Write-Host "  Filter: $($filter.key) $($filter.operator) '$($filter.value)'" -ForegroundColor Gray
        }
    }
    elseif ($alert.Parsed.compositeQuery) {
        $builder = $alert.Parsed.compositeQuery.builderQueries.A
        foreach ($item in $builder.filters.items) {
            Write-Host "  Filter: $($item.key) $($item.op) '$($item.value)'" -ForegroundColor Gray
        }
    }

    if (-not $SkipClipboard) {
        Set-Clipboard -Value $alert.Raw
        Write-Host '  -> JSON copied to clipboard' -ForegroundColor Green
    }
    else {
        Write-Host '  -> Clipboard copy skipped' -ForegroundColor DarkYellow
    }

    Write-Host '  Steps: SigNoz UI -> Alerts -> Create Alert Rule -> JSON mode -> paste -> Save' -ForegroundColor White
    if (-not $SkipLaunch) {
        Start-Process (Resolve-Uri 'alerts') | Out-Null
    }
}
else {
    Write-Host 'Skipping alert staging (--SkipAlert).' -ForegroundColor DarkYellow
}

Write-Host '`nVerification tips:' -ForegroundColor Cyan
Write-Host '  Logs filter: body contains "expected { character for map value"' -ForegroundColor Gray
Write-Host '  Alert expectation: fires when parser errors > 0 in 5m' -ForegroundColor Gray
Write-Host '  Saved view target: columns include timestamp, severity_text, body, log.file.path' -ForegroundColor Gray

Write-Host '`nImport prep complete.' -ForegroundColor Cyan
