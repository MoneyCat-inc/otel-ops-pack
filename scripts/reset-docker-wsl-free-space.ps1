#Requires -RunAsAdministrator
# Resets Docker WSL data to free ~202 GB. All images, containers, volumes are DELETED.
# Run only if you need space and are OK losing all Docker data.
# Run: PowerShell -ExecutionPolicy Bypass -File "c:\otel\scripts\reset-docker-wsl-free-space.ps1"
# Optional: .\reset-docker-wsl-free-space.ps1 -Force  (skip confirmation)

param([switch]$Force)

$ErrorActionPreference = 'Stop'

if (-not $Force) {
    Write-Host "This will DELETE all Docker images, containers, and volumes and free ~202 GB."
    Write-Host "Docker Desktop will create a fresh small disk on next start."
    $confirm = Read-Host "Type YES to continue"
    if ($confirm -ne 'YES') {
        Write-Host "Aborted."
        exit 0
    }
}

# Quit Docker Desktop if running
Get-Process -Name "Docker Desktop" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 3

Write-Host "Shutting down WSL..."
wsl --shutdown
Start-Sleep -Seconds 5

Write-Host "Unregistering docker-desktop..."
wsl --unregister docker-desktop 2>$null

Write-Host "Unregistering docker-desktop-data (this deletes the ~202 GB VHDX)..."
wsl --unregister docker-desktop-data 2>$null

Write-Host "Done. ~202 GB freed. Start Docker Desktop to create a new small data disk."
