#Requires -Version 7.0

param(
    [string]$ReportPath = 'C:/otel/artifacts/signoz-canary-monitor-latest.json',
    [string]$OutputDir = 'C:/otel/artifacts',
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir | Out-Null
}
$remediationLog = Join-Path $OutputDir "signoz-canary-remediation-$timestamp.json"

$status = 'unknown'
$alerts = @()
$reportSnapshot = $null

if (Test-Path $ReportPath) {
    try {
        $report = Get-Content -Raw -Path $ReportPath | ConvertFrom-Json
        if ($report.status) { $status = $report.status }
        if ($report.alerts) { $alerts = @($report.alerts) }
        $reportSnapshot = $report
    } catch {
        $alerts = @("Failed to parse report: $($_.Exception.Message)")
    }
} else {
    $alerts = @("Latest monitor report missing at $ReportPath")
}

$actions = New-Object System.Collections.Generic.List[string]

if ($DryRun) {
    $actions.Add('DryRun enabled; no remediation actions executed')
} else {
    if ($status -in @('critical','error')) {
        try {
            Restart-Service -Name 'otelcol-contrib' -ErrorAction Stop
            $actions.Add('Restarted otelcol-contrib service')
        } catch {
            $actions.Add("Restart-Service otelcol-contrib failed: $($_.Exception.Message)")
        }
    } else {
        $actions.Add('No restart performed (status not critical/error)')
    }
}

$webhookUrl = $env:SIGNOZ_CANARY_WEBHOOK_URL
if ($webhookUrl) {
    $alertText = if ($alerts) { $alerts -join '; ' } else { 'None' }
    $actionSummary = if ($actions) { $actions -join '; ' } else { 'None' }
    $messageText = "SigNoz canary remediation $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`nStatus: $status`nActions: $actionSummary`nAlerts: $alertText`nLog: $remediationLog"

    try {
        $uri = [System.Uri]::new($webhookUrl)
        if ($uri.Scheme -match '^(?i)https?$') {
            $webhookPayload = @{ text = $messageText } | ConvertTo-Json -Depth 4
            Invoke-RestMethod -Uri $webhookUrl -Method Post -Body $webhookPayload -ContentType 'application/json'
            $actions.Add('Webhook notification delivered (HTTP)')
        } elseif ($uri.Scheme -match '^(?i)smtp$') {
            $smtpHost = $uri.Host
            $smtpPort = if ($uri.IsDefaultPort) { 25 } else { $uri.Port }
            $toFromPath = $uri.AbsolutePath.Trim('/').Trim()
            $smtpTo = if ($env:SIGNOZ_CANARY_SMTP_TO) { $env:SIGNOZ_CANARY_SMTP_TO } elseif ($toFromPath -and $toFromPath.Contains('@')) { $toFromPath } else { 'canary@localhost' }
            $smtpFrom = if ($env:SIGNOZ_CANARY_SMTP_FROM) { $env:SIGNOZ_CANARY_SMTP_FROM } else { 'signoz-canary@localhost' }
            $smtpSubject = if ($env:SIGNOZ_CANARY_SMTP_SUBJECT) { $env:SIGNOZ_CANARY_SMTP_SUBJECT } else { 'SigNoz canary remediation' }

            $mail = New-Object System.Net.Mail.MailMessage
            $mail.From = $smtpFrom
            [void]$mail.To.Add($smtpTo)
            $mail.Subject = $smtpSubject
            $mail.Body = $messageText
            $client = New-Object System.Net.Mail.SmtpClient($smtpHost, $smtpPort)
            $client.EnableSsl = $false
            $client.DeliveryMethod = [System.Net.Mail.SmtpDeliveryMethod]::Network
            $client.Send($mail)
            $actions.Add("Webhook notification delivered (SMTP ${smtpHost}:${smtpPort} → ${smtpTo})")
        } else {
            $actions.Add('Unsupported SIGNOZ_CANARY_WEBHOOK_URL scheme; skipped notification')
        }
    } catch {
        $warning = "Webhook notification failed: $($_.Exception.Message)"
        Write-Warning $warning
        $actions.Add($warning)
    }
} else {
    $actions.Add('No SIGNOZ_CANARY_WEBHOOK_URL configured; skipped webhook notification')
}

$logBody = [ordered]@{
    timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    status = $status
    reportPath = $ReportPath
    alerts = $alerts
    actions = $actions
}
if ($reportSnapshot) {
    $logBody['reportSnapshot'] = $reportSnapshot
}

$logJson = $logBody | ConvertTo-Json -Depth 6
$logJson | Out-File -FilePath $remediationLog -Encoding UTF8

$eventSource = 'SigNozCanaryRemediation'
$logName = 'Application'
if (-not [System.Diagnostics.EventLog]::SourceExists($eventSource)) {
    try { New-EventLog -LogName $logName -Source $eventSource } catch { }
}

$eventMessage = "SigNoz canary remediation executed.`nStatus: $status`nActions: $($actions -join '; ')`nAlerts: $([string]::Join('; ', $alerts))`nLog: $remediationLog"
$eventType = if ($status -eq 'healthy') { 'Information' } else { 'Warning' }
$eventId = if ($status -eq 'healthy') { 5100 } else { 5101 }

if ([System.Diagnostics.EventLog]::SourceExists($eventSource)) {
    Write-EventLog -LogName $logName -Source $eventSource -EventId $eventId -EntryType $eventType -Message $eventMessage
}

Write-Host "[INFO] Remediation status: $status" -ForegroundColor Cyan
Write-Host "[INFO] Log written to $remediationLog" -ForegroundColor Cyan

switch ($status) {
    'healthy' { exit 0 }
    'warning' { exit 1 }
    'critical' { exit 2 }
    'error' { exit 3 }
    default { exit 4 }
}
