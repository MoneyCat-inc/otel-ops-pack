# Simple config backup script
$configPath = "C:\otel\config.yaml"
$backupPath = "C:\otel\artifacts\config-backup-$(Get-Date -Format 'yyyyMMdd-HHmm').yaml"
if (Test-Path $configPath) {
    Copy-Item $configPath $backupPath
    Write-Host "Config backed up to: $backupPath"
} else {
    Write-Host "Config file not found: $configPath"
}
