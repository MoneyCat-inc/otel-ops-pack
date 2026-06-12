#Requires -RunAsAdministrator
# Free drive space: Windows Update cache, optional Docker WSL reset.
# Run: PowerShell -ExecutionPolicy Bypass -File "c:\otel\scripts\free-drive-space-admin.ps1"

$ErrorActionPreference = 'Stop'

# --- 1. Windows Update cache (~5 GB) ---
Write-Host "Stopping Windows Update services..."
$svc = @('wuauserv', 'bits', 'cryptSvc', 'msiserver')
foreach ($s in $svc) {
    try { Stop-Service -Name $s -Force -ErrorAction SilentlyContinue } catch {}
}
Start-Sleep -Seconds 2

$downloadPath = "C:\Windows\SoftwareDistribution\Download"
$dataStorePath = "C:\Windows\SoftwareDistribution\DataStore"
if (Test-Path $downloadPath) {
    $before = (Get-ChildItem $downloadPath -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    Get-ChildItem $downloadPath -Recurse -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "Cleared Windows Update Download cache (freed ~$([math]::Round($before/1GB,2)) GB)"
}
if (Test-Path $dataStorePath) {
    Get-ChildItem $dataStorePath -Exclude "*.edb" -Recurse -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host "Starting Windows Update services..."
foreach ($s in $svc) {
    try { Start-Service -Name $s -ErrorAction SilentlyContinue } catch {}
}

# --- 2. Delivery Optimization cache (if present) ---
$doPath = "$env:SystemRoot\ServiceProfiles\NetworkService\AppData\Local\Microsoft\Windows\DeliveryOptimization\Cache"
if (Test-Path $doPath) {
    $size = (Get-ChildItem $doPath -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    Get-ChildItem $doPath -Recurse -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "Cleared Delivery Optimization cache (freed ~$([math]::Round($size/1MB,2)) MB)"
}

# --- 3. Windows Temp ---
if (Test-Path "C:\Windows\Temp") {
    Get-ChildItem "C:\Windows\Temp" -Recurse -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "Cleared C:\Windows\Temp"
}

Write-Host "Admin cleanup done. For Docker reset (~202 GB), run: .\reset-docker-wsl-free-space.ps1"
Write-Host "Then run Windows Update again to re-download the update."
