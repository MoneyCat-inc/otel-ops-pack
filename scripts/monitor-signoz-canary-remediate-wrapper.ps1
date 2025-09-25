#Requires -Version 7.0

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$webhookFile = 'C:/otel/config/signoz-canary-webhook.txt'
if (Test-Path $webhookFile) {
    # Read the first non-empty, non-comment line
    $lines = Get-Content -Path $webhookFile -ErrorAction SilentlyContinue
    $firstLine = $null
    foreach ($line in $lines) {
        $trimmed = ($line | ForEach-Object { $_.ToString().Trim() })
        if (-not [string]::IsNullOrWhiteSpace($trimmed) -and -not $trimmed.StartsWith('#')) {
            $firstLine = $trimmed
            break
        }
    }
    if ($firstLine) {
        # Basic validation: allow http/https/smtp schemes only
        $isHttp = $firstLine -match '^(?i)https?://'
        $isSmtp = $firstLine -match '^(?i)smtp://'
        if ($isHttp -or $isSmtp) {
            $env:SIGNOZ_CANARY_WEBHOOK_URL = $firstLine
        } else {
            Write-Warning "SIGNOZ_CANARY_WEBHOOK_URL not set: unsupported or invalid URI scheme in $webhookFile"
        }
    }
}

& 'C:/otel/scripts/monitor-signoz-canary-remediate.ps1'
