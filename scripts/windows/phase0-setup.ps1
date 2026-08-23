# Clean-host E2E Phase 0 - tooling + pinned collector (excluded from gate clock)
# ASCII-only. Machine-scope winget installs (F6: per-user invisible to other sessions).
# Collector pin: canonical value is scripts/windows/collector-version.txt. This script runs on a
# clean guest BEFORE the repo is cloned, so it is copied over standalone: it reads a sibling
# collector-version.txt if one was copied alongside, else uses the embedded fallback below.
# hygiene-fast (pre-commit) fails if the fallback drifts from the canonical file.
# Writes C:\Phase0\DONE.json on success.
#
# Operator notes (clean-host run 2026-08-23): after a FAILED Phase 0, `docker rm -f` leftovers or
# restore the docker-ready snapshot before retrying; VM Connect / Hyper-V needs host elevation
# under nested virtualization.

$ErrorActionPreference = 'Stop'
$Phase0Root = 'C:\Phase0'
$CollectorVersion = '0.159.0'  # embedded fallback - keep equal to collector-version.txt
$siblingPin = Join-Path $PSScriptRoot 'collector-version.txt'
if (Test-Path $siblingPin) { $CollectorVersion = (Get-Content $siblingPin -Raw).Trim() }
$start = Get-Date

New-Item -ItemType Directory -Path $Phase0Root -Force | Out-Null
Start-Transcript -Path (Join-Path $Phase0Root 'phase0.log') -Force | Out-Null

function Write-Step([string]$msg) {
  Write-Host ""
  Write-Host "=== $msg ===" -ForegroundColor Cyan
}

function Assert-Admin {
  $id = [Security.Principal.WindowsIdentity]::GetCurrent()
  $p = New-Object Security.Principal.WindowsPrincipal($id)
  if (-not $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw 'Phase 0 must run elevated (Run as administrator).'
  }
}

function Install-WingetPkg([string]$id) {
  # Prefer machine scope (F6), but some packages reject it on fresh Win11
  # (-1978334957 = system configuration does not support this package).
  # Fall back to default scope, then continue if already present.
  $ok = @(0, -1978335189)  # success / already installed
  Write-Host "winget install $id (machine scope)..."
  & winget install --id $id -e --accept-source-agreements --accept-package-agreements --scope machine --disable-interactivity
  if ($LASTEXITCODE -in $ok) { return }
  Write-Host ("machine scope failed exit={0}; retrying without --scope..." -f $LASTEXITCODE) -ForegroundColor Yellow
  & winget install --id $id -e --accept-source-agreements --accept-package-agreements --disable-interactivity
  if ($LASTEXITCODE -in $ok) { return }
  if (Get-Command pwsh -ErrorAction SilentlyContinue) {
    Write-Host "winget reported failure but pwsh is on PATH - continuing" -ForegroundColor Yellow
    return
  }
  throw "winget failed for $id exit=$LASTEXITCODE"
}

function Install-PwshMsiFallback {
  if (Get-Command pwsh -ErrorAction SilentlyContinue) { return }
  Write-Host 'Downloading PowerShell 7 MSI fallback...'
  $pwshVer = '7.6.4'
  $msi = "PowerShell-$pwshVer-win-x64.msi"
  $url = "https://github.com/PowerShell/PowerShell/releases/download/v$pwshVer/$msi"
  $path = Join-Path $env:TEMP $msi
  Invoke-WebRequest -Uri $url -OutFile $path
  $arg = '/i "' + $path + '" /quiet ADD_EXPLORER_CONTEXT_MENU_OPENPOWERSHELL=1 ENABLE_PSREMOTING=0 REGISTER_MANIFEST=1'
  $p = Start-Process msiexec.exe -ArgumentList $arg -Wait -PassThru
  if ($p.ExitCode -notin 0, 1641, 3010) {
    throw ("PowerShell MSI fallback failed exit={0}" -f $p.ExitCode)
  }
  $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')
}

try {
  Assert-Admin
  Write-Step '1/5 Git + PowerShell 7 + Python (machine scope)'
  Install-WingetPkg 'Git.Git'
  try {
    Install-WingetPkg 'Microsoft.PowerShell'
  } catch {
    Write-Host ("winget PowerShell failed: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
    Install-PwshMsiFallback
  }
  Install-PwshMsiFallback
  Install-WingetPkg 'Python.Python.3.12'

  Write-Step '2/5 Docker Desktop'
  Install-WingetPkg 'Docker.DockerDesktop'
  Write-Host 'NOTE: Start Docker Desktop from the Start menu after Phase 0 if the engine is not up yet.' -ForegroundColor Yellow

  Write-Step '3/5 OTel Python packages'
  $py = @(
    "${env:ProgramFiles}\Python312\python.exe",
    "${env:ProgramFiles}\Python3\python.exe"
  ) | Where-Object { Test-Path $_ } | Select-Object -First 1
  if (-not $py) { $py = (Get-Command python -ErrorAction SilentlyContinue).Source }
  if (-not $py) { throw 'python.exe not found after install' }
  & $py -m pip install --upgrade pip
  & $py -m pip install 'opentelemetry-api' 'opentelemetry-sdk' 'opentelemetry-exporter-otlp'

  Write-Step "4/5 otelcol-contrib MSI v$CollectorVersion (pinned path under test)"
  $arch = if ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64') { 'arm64' } else { 'x64' }
  $msiName = "otelcol-contrib_${CollectorVersion}_windows_${arch}.msi"
  $url = "https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v${CollectorVersion}/$msiName"
  $msiPath = Join-Path $env:TEMP $msiName
  $shaPath = "$msiPath.sha256"

  Write-Host "Downloading $msiName ..."
  Invoke-WebRequest -Uri $url -OutFile $msiPath
  Invoke-WebRequest -Uri "$url.sha256" -OutFile $shaPath
  $expected = ((Get-Content $shaPath -Raw) -split '\s+')[0].Trim().ToLower()
  $actual = (Get-FileHash -Path $msiPath -Algorithm SHA256).Hash.ToLower()
  if ($expected -ne $actual) { throw "Checksum mismatch expected=$expected actual=$actual" }
  Write-Host 'Checksum OK'

  # Stage a minimal config so MSI Error 1920 (service start) is less likely
  $installDir = 'C:\Program Files\OpenTelemetry Collector'
  New-Item -ItemType Directory -Path $installDir -Force | Out-Null
  $bootstrap = @"
extensions:
  health_check:
    endpoint: 127.0.0.1:13134
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 127.0.0.1:5320
exporters:
  debug:
    verbosity: basic
service:
  extensions: [health_check]
  pipelines:
    traces:
      receivers: [otlp]
      exporters: [debug]
"@
  Set-Content -Path (Join-Path $installDir 'config.yaml') -Value $bootstrap -Encoding ascii

  $logPath = Join-Path $Phase0Root 'msi-install.log'
  $argList = '/i "' + $msiPath + '" /quiet /norestart /l*v "' + $logPath + '"'
  $p = Start-Process msiexec.exe -ArgumentList $argList -Wait -PassThru
  $msiOk = $p.ExitCode -in 0, 1641, 3010
  $msiMethod = 'msi'
  if (-not $msiOk) {
    Write-Host ("MSI exit {0} - falling back to tarball + sc create" -f $p.ExitCode) -ForegroundColor Yellow
    $msiMethod = 'tarball_fallback'
    $tarName = "otelcol-contrib_${CollectorVersion}_windows_amd64.tar.gz"
    $tarUrl = "https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v${CollectorVersion}/$tarName"
    $tarPath = Join-Path $env:TEMP $tarName
    Invoke-WebRequest -Uri $tarUrl -OutFile $tarPath
    $extract = Join-Path $env:TEMP 'otelcol-extract'
    New-Item -ItemType Directory -Path $extract -Force | Out-Null
    tar -xzf $tarPath -C $extract
    Copy-Item (Join-Path $extract 'otelcol-contrib.exe') (Join-Path $installDir 'otelcol-contrib.exe') -Force
    $cfg = 'C:\ProgramData\otelcol-contrib\config.yaml'
    New-Item -ItemType Directory -Path (Split-Path $cfg) -Force | Out-Null
    Copy-Item (Join-Path $installDir 'config.yaml') $cfg -Force
    sc.exe stop otelcol-contrib 2>$null | Out-Null
    sc.exe delete otelcol-contrib 2>$null | Out-Null
    Start-Sleep 2
    $binPath = '"' + $installDir + '\otelcol-contrib.exe" --config "' + $cfg + '"'
    sc.exe create otelcol-contrib binPath= $binPath start= demand DisplayName= 'OpenTelemetry Collector' | Out-Null
  }

  $exe = Join-Path $installDir 'otelcol-contrib.exe'
  if (-not (Test-Path $exe)) { throw "Collector exe missing: $exe" }
  $verOut = & $exe --version 2>&1 | Out-String
  Write-Host $verOut.Trim()

  Write-Step '5/5 Stop + Disable collector (checkpoint state)'
  Stop-Service otelcol-contrib -Force -ErrorAction SilentlyContinue
  Set-Service otelcol-contrib -StartupType Disabled
  $svc = Get-Service otelcol-contrib

  $elapsed = [math]::Round(((Get-Date) - $start).TotalMinutes, 2)
  $done = [ordered]@{
    phase0_minutes     = $elapsed
    collector_version  = $CollectorVersion
    collector_method   = $msiMethod
    msi_exit_code      = $p.ExitCode
    service_status     = [string]$svc.Status
    service_start_type = [string]$svc.StartType
    version_output     = $verOut.Trim()
    completed_utc      = (Get-Date).ToUniversalTime().ToString('o')
  }
  $done | ConvertTo-Json | Set-Content -Path (Join-Path $Phase0Root 'DONE.json') -Encoding ascii

  Write-Host ""
  Write-Host ("PHASE 0 COMPLETE in {0} min" -f $elapsed) -ForegroundColor Green
  Write-Host ("Method={0} Status={1} StartType={2}" -f $msiMethod, $svc.Status, $svc.StartType) -ForegroundColor Green
  Write-Host ("Ping Cursor: Phase 0 done, {0} minutes" -f $elapsed) -ForegroundColor Yellow
  exit 0
}
catch {
  Write-Host ("PHASE 0 FAILED: {0}" -f $_.Exception.Message) -ForegroundColor Red
  $_ | Format-List * -Force | Out-String | Set-Content (Join-Path $Phase0Root 'FAILED.txt') -Encoding ascii
  exit 1
}
finally {
  Stop-Transcript | Out-Null
}
