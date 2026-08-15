Import-Module (Join-Path $PSScriptRoot '..\..\..\BRAV\SCPT\lib\OtelPorts.psm1') -Force
$script:OtelPorts = Get-OtelPorts

# Simple port checker script

Write-Host "=== Port Status Check ===" -ForegroundColor Green

$ports = @(
    $script:OtelPorts.SignozOtlpGrpc,
    $script:OtelPorts.SignozOtlpHttp,
    $script:OtelPorts.IngestGrpc,
    $script:OtelPorts.IngestHttp,
    $script:OtelPorts.SignozUiHttp,
    8888,
    13134
)

foreach ($port in $ports) {
    $result = Test-NetConnection -ComputerName localhost -Port $port -InformationLevel Quiet -WarningAction SilentlyContinue
    if ($result) {
        Write-Host "OK Port $port is listening" -ForegroundColor Green
    } else {
        Write-Host "ERROR Port $port is not listening" -ForegroundColor Red
    }
}

Write-Host "`n=== Docker Container Status ===" -ForegroundColor Green
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
