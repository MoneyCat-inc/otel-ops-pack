# Nightly ECRR validation — exclusions guard + index/ledger refresh + status write
# Usage (Windows Task Scheduler):
#   pwsh -NoLogo -NoProfile -File C:\otel\scripts\nightly-ecrr-validation.ps1

$ErrorActionPreference = 'Stop'

function Write-Status {
    param(
        [bool]$Ok,
        [string]$Detail
    )
    $statusFile = Join-Path $PSScriptRoot '..' | Join-Path -ChildPath '.agent/status.json'
    $status = $null
    if (Test-Path $statusFile) {
        try { $status = Get-Content $statusFile -Raw | ConvertFrom-Json } catch { $status = $null }
    }
    if ($null -eq $status) { $status = [pscustomobject]@{} }
    $otelObj = [pscustomobject]@{
        ok     = $Ok
        detail = $Detail
        stamp  = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    }
    if ($status.PSObject.Properties['otel']) { $status.otel = $otelObj } else { $status | Add-Member -NotePropertyName 'otel' -NotePropertyValue $otelObj -Force }
    ($status | ConvertTo-Json -Depth 6) | Set-Content -Path $statusFile -Encoding UTF8
}

try {
    & pwsh -NoLogo -NoProfile -File (Join-Path $PSScriptRoot 'ecrr-exclusions.ps1') -Action Restore
} catch {
    Write-Host "[WARN] exclusions restore failed: $($_.Exception.Message)" -ForegroundColor Yellow
}

try {
    & pwsh -NoLogo -NoProfile -File (Join-Path $PSScriptRoot 'ecrr-manage.ps1') -Action RegenerateAll
    # Optional: port check
    $portSummary = try { & pwsh -NoLogo -NoProfile -File (Join-Path $PSScriptRoot 'port-conflict-check.ps1') } catch { $null }
    $detail = 'Nightly ECRR validation OK: exclusions restored, index/ledger regenerated'
    if ($portSummary -and $portSummary.ok -ne $true) { $detail += '; port conflicts detected' }
    Write-Status -Ok $true -Detail $detail
    Write-Host 'Nightly ECRR validation completed successfully' -ForegroundColor Green
} catch {
    Write-Status -Ok $false -Detail ("Nightly ECRR validation failed: {0}" -f $_.Exception.Message)
    Write-Error $_
    exit 1
}


