#!/usr/bin/env pwsh
# GPU Sidecar Log Rotation Script

$logDir = "C:\otel\logs"
$maxLogAge = 30 # days
$maxLogSize = 100MB

if (Test-Path $logDir) {
    # Remove old log files
    Get-ChildItem -Path $logDir -Filter "*.log" | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$maxLogAge) } | Remove-Item -Force
    
    # Compress large log files
    Get-ChildItem -Path $logDir -Filter "*.log" | Where-Object { $_.Length -gt $maxLogSize } | ForEach-Object {
        $compressedName = $_.FullName + ".gz"
        if (-not (Test-Path $compressedName)) {
            Compress-Archive -Path $_.FullName -DestinationPath $compressedName -Force
            Remove-Item $_.FullName -Force
        }
    }
}
