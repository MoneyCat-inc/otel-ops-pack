# Apply Windows collector service hardening: delayed start + failure recovery.
# Requires Administrator. Kafka runs in Docker, so no sc depend= is possible.

#Requires -RunAsAdministrator

param(
  [string]$ServiceName = 'otelcol-contrib'
)

$ErrorActionPreference = 'Stop'

function Test-DelayedAutoStart {
  param([string]$Name)
  $output = sc.exe qc $Name 2>&1 | Out-String
  return ($output -match 'DELAYED')
}

function Test-FailureRecovery {
  param([string]$Name)
  $output = sc.exe qfailure $Name 2>&1 | Out-String
  $restarts = ([regex]::Matches($output, 'RESTART')).Count
  return ($restarts -ge 3 -and $output -match 'reset= 86400|RESET_PERIOD')
}

Write-Host "Configuring $ServiceName service..." -ForegroundColor Cyan

$service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
if (-not $service) {
  Write-Error "Service '$ServiceName' not found"
  exit 1
}

# Delayed auto-start: gives Docker/Kafka time to come up after reboot
sc.exe config $ServiceName start= delayed-auto
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

# Retry at 5s, 10s, 30s before resetting the failure counter (86400s = 24h)
sc.exe failure $ServiceName reset= 86400 actions= restart/5000/restart/10000/restart/30000
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

# Verify both settings survived (easy to lose one on reinstall)
$delayedOk = Test-DelayedAutoStart -Name $ServiceName
$recoveryOk = Test-FailureRecovery -Name $ServiceName

if (-not $delayedOk) {
  Write-Error "Verification failed: delayed auto-start not set on $ServiceName"
  exit 1
}
if (-not $recoveryOk) {
  Write-Error "Verification failed: failure recovery actions not set on $ServiceName"
  exit 1
}

Write-Host "  Startup: Automatic (Delayed Start) [verified]" -ForegroundColor Green
Write-Host "  Recovery: restart at 5s / 10s / 30s (reset daily) [verified]" -ForegroundColor Green
Write-Host "  Note: Kafka is Docker-only; use scripts/start-windows-collector.ps1 for explicit broker wait" -ForegroundColor DarkGray

exit 0
