[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$CollectorPath,

    [Parameter(Mandatory=$true)]
    [string]$Config,

    [string]$ServiceName = 'otelcol-contrib',
    [string]$DisplayName = 'OpenTelemetry Collector'
)

$ErrorActionPreference = 'Stop'

function Resolve-ExistingPath {
    param([string]$Path, [string]$Label)

    if (-not (Test-Path -Path $Path)) {
        throw "$Label not found: $Path"
    }

    return (Resolve-Path -Path $Path).ProviderPath
}

try {
    $resolvedCollector = Resolve-ExistingPath -Path $CollectorPath -Label 'Collector executable'
    $resolvedConfig = Resolve-ExistingPath -Path $Config -Label 'Collector config'
} catch {
    Write-Host "[install-service] $_" -ForegroundColor Red
    exit 1
}

$binaryPath = '"' + $resolvedCollector + '" --config "' + $resolvedConfig + '"'

try {
    $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue

    if ($service) {
        Write-Host "[install-service] Updating existing service '$ServiceName'" -ForegroundColor Yellow

        if ($service.Status -eq 'Running') {
            Write-Host "[install-service] Stopping running service" -ForegroundColor Yellow
            Stop-Service -Name $ServiceName -Force -ErrorAction SilentlyContinue
            $timeout = (Get-Date).AddSeconds(30)
            do {
                Start-Sleep -Milliseconds 500
                $service.Refresh()
                if ((Get-Date) -gt $timeout) {
                    Write-Host "[install-service] Service stop timeout, continuing anyway" -ForegroundColor Yellow
                    break
                }
            } while ($service.Status -eq 'Running')
        }

        & sc.exe config $ServiceName binPath= $binaryPath DisplayName= "$DisplayName" start= auto | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to update service configuration"
        }
    } else {
        Write-Host "[install-service] Creating service '$ServiceName'" -ForegroundColor Green
        New-Service -Name $ServiceName -DisplayName $DisplayName -BinaryPathName $binaryPath -StartupType Automatic | Out-Null
    }

    & sc.exe failure $ServiceName reset= 86400 actions= restart/60000/restart/60000/restart/60000 | Out-Null
    & sc.exe failureflag $ServiceName 1 | Out-Null

    Set-Service -Name $ServiceName -StartupType Automatic

    Write-Host "[install-service] Starting service" -ForegroundColor Green
    Start-Service -Name $ServiceName
    (Get-Service -Name $ServiceName).WaitForStatus('Running', '00:00:10') | Out-Null

    Write-Host "[install-service] Service '$ServiceName' running with config: $resolvedConfig" -ForegroundColor Green
    exit 0
} catch {
    Write-Host "[install-service] $_" -ForegroundColor Red
    exit 1
}