# OTel Artifacts Cleanup Script
# ECRR Compliant: Examine → Clean → Report → Role

param(
    [int]$RetentionDays = 7,
    [switch]$IncludeLogs,
    [switch]$Force,
    [string]$ReportPath = "artifacts/cleanup-report.json"
)

# ECRR: Examine - Capture current state
$examineStart = Get-Date
$artifactsPath = Join-Path $PSScriptRoot "..\artifacts"
$cleanupReport = @{
    timestamp = $examineStart.ToString("yyyy-MM-dd HH:mm:ss")
    retention_days = $RetentionDays
    artifacts_path = $artifactsPath
    examine = @{}
    clean = @{}
    report = @{}
    role = "OTel Artifacts Cleanup Script"
}

Write-Host "🔍 ECRR Examine: Analyzing artifacts directory..." -ForegroundColor Cyan

if (-not (Test-Path $artifactsPath)) {
    Write-Host "✅ No artifacts directory found - nothing to clean" -ForegroundColor Green
    $cleanupReport.examine.directory_exists = $false
    $cleanupReport.clean.files_removed = 0
    $cleanupReport.clean.space_freed_gb = 0
    $cleanupReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $ReportPath -Encoding UTF8
    exit 0
}

# Analyze current artifacts
$allFiles = Get-ChildItem $artifactsPath -Recurse -File
$cutoff = (Get-Date).AddDays(-$RetentionDays)
$oldFiles = $allFiles | Where-Object { $_.LastWriteTime -lt $cutoff }

$cleanupReport.examine = @{
    total_files = $allFiles.Count
    total_size_gb = [math]::Round(($allFiles | Measure-Object Length -Sum).Sum / 1GB, 2)
    files_to_remove = $oldFiles.Count
    space_to_free_gb = [math]::Round(($oldFiles | Measure-Object Length -Sum).Sum / 1GB, 2)
    cutoff_date = $cutoff.ToString("yyyy-MM-dd HH:mm:ss")
}

Write-Host "📊 Found $($allFiles.Count) files ($($cleanupReport.examine.total_size_gb) GB total)" -ForegroundColor Yellow
Write-Host "🗑️  $($oldFiles.Count) files older than $RetentionDays days ($($cleanupReport.examine.space_to_free_gb) GB)" -ForegroundColor Yellow

if ($oldFiles.Count -eq 0) {
    Write-Host "✅ No files need cleanup" -ForegroundColor Green
    $cleanupReport.clean.files_removed = 0
    $cleanupReport.clean.space_freed_gb = 0
    $cleanupReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $ReportPath -Encoding UTF8
    exit 0
}

# ECRR: Clean - Remove old files
if (-not $Force) {
    Write-Host "⚠️  Use -Force to actually remove files (dry run mode)" -ForegroundColor Yellow
    $cleanupReport.clean.mode = "dry_run"
    $cleanupReport.clean.files_removed = 0
    $cleanupReport.clean.space_freed_gb = 0
} else {
    Write-Host "🧹 ECRR Clean: Removing old artifacts..." -ForegroundColor Cyan
    
    # Create backup archive if significant space will be freed
    if ($cleanupReport.examine.space_to_free_gb -gt 0.1) {
        $backupPath = Join-Path $artifactsPath "..\cleanup-backup"
        New-Item -ItemType Directory -Path $backupPath -Force | Out-Null
        $backupFile = Join-Path $backupPath ("artifacts-backup-" + (Get-Date -Format 'yyyyMMdd-HHmm') + ".zip")
        
        try {
            Compress-Archive -Path $oldFiles.FullName -DestinationPath $backupFile -CompressionLevel Optimal
            Write-Host "📦 Created backup: $backupFile" -ForegroundColor Green
            $cleanupReport.clean.backup_created = $backupFile
        } catch {
            Write-Host "⚠️  Backup creation failed: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
    
    # Remove old files
    $removedCount = 0
    $removedSize = 0
    
    foreach ($file in $oldFiles) {
        try {
            $removedSize += $file.Length
            Remove-Item $file.FullName -Force
            $removedCount++
            
            if ($removedCount % 10 -eq 0) {
                Write-Host "⠋ Removed $removedCount files..." -NoNewline -ForegroundColor Cyan
            }
        } catch {
            Write-Host "⚠️  Failed to remove $($file.FullName): $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
    
    Write-Host "`r✅ Removed $removedCount files" -ForegroundColor Green
    
    $cleanupReport.clean = @{
        mode = "cleanup"
        files_removed = $removedCount
        space_freed_gb = [math]::Round($removedSize / 1GB, 2)
        backup_created = $cleanupReport.clean.backup_created
    }
}

# ECRR: Report - Generate artifacts
$cleanupReport.report = @{
    report_path = $ReportPath
    execution_time_seconds = [math]::Round(((Get-Date) - $examineStart).TotalSeconds, 2)
    success = $true
}

# Ensure artifacts directory exists for report
$reportDir = Split-Path $ReportPath -Parent
if (-not (Test-Path $reportDir)) {
    New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
}

$cleanupReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $ReportPath -Encoding UTF8

Write-Host "📝 ECRR Report: Cleanup report saved to $ReportPath" -ForegroundColor Green
Write-Host "🎭 ECRR Role: $($cleanupReport.role)" -ForegroundColor Magenta

# Summary
Write-Host "`n=== CLEANUP SUMMARY ===" -ForegroundColor Cyan
Write-Host "Files removed: $($cleanupReport.clean.files_removed)" -ForegroundColor White
Write-Host "Space freed: $($cleanupReport.clean.space_freed_gb) GB" -ForegroundColor White
Write-Host "Execution time: $($cleanupReport.report.execution_time_seconds) seconds" -ForegroundColor White