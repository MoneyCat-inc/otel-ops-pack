$ErrorActionPreference = 'Stop'
Write-Host "== OTel Collector Auto-Restart Verification =="

function Get-ServicePid {
    param([string]$serviceName)
    $svc = Get-CimInstance -ClassName Win32_Service -Filter "Name='$serviceName'"
    return [int]$svc.ProcessId
}

$serviceName = 'otelcol-contrib'

Write-Host "1) Capturing current service state..."
$svc = Get-Service -Name $serviceName
if ($svc.Status -ne 'Running') {
    Write-Host "Service not running; starting..."
    Start-Service -Name $serviceName
    Start-Sleep -Seconds 2
}
$pidBefore = Get-ServicePid -serviceName $serviceName
Write-Host "   PID before: $pidBefore"

Write-Host "2) Simulating crash (stopping process $pidBefore)..."
try {
    Stop-Process -Id $pidBefore -Force
} catch {
    Write-Warning "Failed to stop process: $_"
}

Write-Host "3) Waiting for service to recover..."
$deadline = (Get-Date).AddSeconds(20)
do {
    Start-Sleep -Milliseconds 500
    $svc = Get-Service -Name $serviceName
} while ($svc.Status -ne 'Running' -and (Get-Date) -lt $deadline)

if ($svc.Status -ne 'Running') {
    Write-Error "Service did not recover to Running state within timeout"
    exit 2
}

$pidAfter = Get-ServicePid -serviceName $serviceName
Write-Host "   PID after:  $pidAfter"

if ($pidAfter -eq 0 -or $pidAfter -eq $pidBefore) {
    Write-Error "Unexpected PID after restart; auto-restart may not be configured"
    exit 3
}

Write-Host "4) Validating OTLP ports listening..."
$ports = @(5317, 5318)
$listening = foreach ($p in $ports) {
    (Get-NetTCPConnection -State Listen -LocalPort $p -ErrorAction SilentlyContinue) -ne $null
}
if ($listening -contains $false) {
    Write-Error "One or more OTLP ports not listening after restart"
    exit 4
}

Write-Host "5) Emitting canary to confirm end-to-end..."
pwsh -NoProfile -File "$PSScriptRoot\canary-test.ps1" | Out-Null

Write-Host "== Auto-restart verification PASSED =="
exit 0


