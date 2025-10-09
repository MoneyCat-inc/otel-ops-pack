# ECRR Archive Manager - Intelligent Report Archiving
param(
    [string]$ReportsPath = "docs/ECRR_REPORTS",
    [string]$ArchivePath = "docs/ECRR_REPORTS/archive",
    [switch]$DryRun = $false,
    [switch]$Force = $false,
    [int]$TargetActiveReports = 50,
    [switch]$Verbose = $false
)

# Configuration
$Config = @{
    ReportsPath = $ReportsPath
    ArchivePath = $ArchivePath
    TargetActiveReports = $TargetActiveReports
    DryRun = $DryRun
    Force = $Force
    Timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
}

Write-Host "🗂️  ECRR Archive Manager" -ForegroundColor Cyan
Write-Host "========================" -ForegroundColor Cyan
Write-Host "📅 Timestamp: $($Config.Timestamp)" -ForegroundColor Gray
Write-Host "📁 Reports Path: $($Config.ReportsPath)" -ForegroundColor Gray
Write-Host "📦 Archive Path: $($Config.ArchivePath)" -ForegroundColor Gray
Write-Host "🎯 Target Active Reports: $($Config.TargetActiveReports)" -ForegroundColor Gray
Write-Host "🧪 Dry Run: $($Config.DryRun)" -ForegroundColor Gray
Write-Host ""

# Ensure archive directory exists
if (-not (Test-Path $Config.ArchivePath)) {
    New-Item -Path $Config.ArchivePath -ItemType Directory -Force | Out-Null
    Write-Host "📦 Created archive directory: $($Config.ArchivePath)" -ForegroundColor Green
}

# Get all ECRR report files (exclude backups and duplicates)
$allReports = Get-ChildItem -Path $Config.ReportsPath -Filter "*.md" | Where-Object { 
    $_.Name -notmatch 'backup' -and 
    $_.Name -notmatch '20250929-200755-' -and
    $_.FullName -notmatch '\\archive\\'
}

$totalReports = $allReports.Count
Write-Host "📊 Total Active Reports: $totalReports" -ForegroundColor Yellow

# Define archiving criteria
$archiveCriteria = @{
    # Completed/Deprecated patterns
    CompletedPatterns = @(
        'complete\.md$',
        'final.*complete\.md$',
        'implementation.*complete\.md$',
        'deployment.*complete\.md$',
        'rollout.*complete\.md$',
        'verification.*complete\.md$',
        'consolidated\.md$',
        'final.*consolidated\.md$',
        'processing.*complete\.md$',
        'processing.*final\.md$',
        'processing.*summary\.md$',
        'cleanup.*complete\.md$',
        'optimization.*complete\.md$'
    )
    
    # Old dates (before 2025-09-01)
    OldDatePatterns = @(
        '^2024-',
        '^2025-01-',
        '^2025-02-',
        '^2025-03-',
        '^2025-04-',
        '^2025-05-',
        '^2025-06-',
        '^2025-07-',
        '^2025-08-'
    )
    
    # Duplicate/Redundant patterns
    DuplicatePatterns = @(
        'rollout-merge.*ecrr.*complete\.md$',
        'ecrr-processing.*complete\.md$',
        'ecrr-processing.*summary\.md$',
        'ecrr-processing.*final\.md$',
        'ecrr-processing.*analysis\.md$',
        'task-.*-complete\.md$',
        'task-.*-001-.*\.md$'
    )
    
    # Workshop/Example files
    ExamplePatterns = @(
        'workshop-.*-example-ecrr\.md$',
        'example-ecrr\.md$'
    )
    
    # System/Processing files
    SystemPatterns = @(
        'ECRR_PROCESSING_.*\.md$',
        'ECRR_ENHANCEMENT_.*\.md$',
        'ECRR_COMPLIANCE_.*\.md$'
    )
}

# Function to check if file matches archiving criteria
function Test-ShouldArchive {
    param([string]$FileName)
    
    $criteria = @()
    
    # Check completed patterns
    foreach ($pattern in $archiveCriteria.CompletedPatterns) {
        if ($FileName -match $pattern) {
            $criteria += "Completed: $pattern"
        }
    }
    
    # Check old date patterns
    foreach ($pattern in $archiveCriteria.OldDatePatterns) {
        if ($FileName -match $pattern) {
            $criteria += "Old Date: $pattern"
        }
    }
    
    # Check duplicate patterns
    foreach ($pattern in $archiveCriteria.DuplicatePatterns) {
        if ($FileName -match $pattern) {
            $criteria += "Duplicate: $pattern"
        }
    }
    
    # Check example patterns
    foreach ($pattern in $archiveCriteria.ExamplePatterns) {
        if ($FileName -match $pattern) {
            $criteria += "Example: $pattern"
        }
    }
    
    # Check system patterns
    foreach ($pattern in $archiveCriteria.SystemPatterns) {
        if ($FileName -match $pattern) {
            $criteria += "System: $pattern"
        }
    }
    
    return $criteria
}

# Analyze reports for archiving
$archiveCandidates = @()
$keepActive = @()

foreach ($report in $allReports) {
    $archiveReasons = Test-ShouldArchive -FileName $report.Name
    
    if ($archiveReasons.Count -gt 0) {
        $archiveCandidates += @{
            File = $report
            Reasons = $archiveReasons
            Priority = $archiveReasons.Count
        }
    } else {
        $keepActive += $report
    }
}

# Sort by priority (more reasons = higher priority)
$archiveCandidates = $archiveCandidates | Sort-Object Priority -Descending

Write-Host ""
Write-Host "📋 Archive Analysis:" -ForegroundColor Cyan
Write-Host "  🗂️  Archive Candidates: $($archiveCandidates.Count)" -ForegroundColor Yellow
Write-Host "  📄 Keep Active: $($keepActive.Count)" -ForegroundColor Green
Write-Host "  🎯 Target: $($Config.TargetActiveReports)" -ForegroundColor Gray

# Calculate how many to archive to reach target
$reportsToArchive = [Math]::Max(0, $totalReports - $Config.TargetActiveReports)
$actualArchiveCount = [Math]::Min($reportsToArchive, $archiveCandidates.Count)

Write-Host ""
Write-Host "📊 Archive Plan:" -ForegroundColor Cyan
Write-Host "  📦 Reports to Archive: $actualArchiveCount" -ForegroundColor Yellow
Write-Host "  📄 Remaining Active: $($totalReports - $actualArchiveCount)" -ForegroundColor Green

if ($actualArchiveCount -eq 0) {
    Write-Host ""
    Write-Host "✅ No archiving needed! Already at or below target." -ForegroundColor Green
    exit 0
}

# Show top candidates for archiving
Write-Host ""
Write-Host "🔍 Top Archive Candidates:" -ForegroundColor Cyan
$topCandidates = $archiveCandidates | Select-Object -First 10
foreach ($candidate in $topCandidates) {
    Write-Host "  📦 $($candidate.File.Name)" -ForegroundColor Yellow
    foreach ($reason in $candidate.Reasons) {
        Write-Host "     - $reason" -ForegroundColor DarkYellow
    }
}

# Perform archiving
if (-not $Config.DryRun) {
    Write-Host ""
    Write-Host "🚀 Starting Archive Process..." -ForegroundColor Cyan
    
    $archivedCount = 0
    $errors = @()
    
    foreach ($candidate in $archiveCandidates | Select-Object -First $actualArchiveCount) {
        try {
            $sourcePath = $candidate.File.FullName
            $archiveFileName = "$($candidate.File.BaseName).archived-$($Config.Timestamp)$($candidate.File.Extension)"
            $archivePath = Join-Path $Config.ArchivePath $archiveFileName
            
            if ($Config.Force -or (Test-Path $sourcePath)) {
                Move-Item -Path $sourcePath -Destination $archivePath -ErrorAction Stop
                $archivedCount++
                
                if ($Verbose) {
                    Write-Host "  ✅ Archived: $($candidate.File.Name)" -ForegroundColor Green
                }
            }
        } catch {
            $errors += "Failed to archive $($candidate.File.Name): $($_.Exception.Message)"
            Write-Host "  ❌ Error archiving $($candidate.File.Name): $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    Write-Host ""
    Write-Host "📊 Archive Results:" -ForegroundColor Cyan
    Write-Host "  ✅ Successfully Archived: $archivedCount" -ForegroundColor Green
    Write-Host "  ❌ Errors: $($errors.Count)" -ForegroundColor Red
    
    if ($errors.Count -gt 0) {
        Write-Host ""
        Write-Host "❌ Archive Errors:" -ForegroundColor Red
        foreach ($error in $errors) {
            Write-Host "  - $error" -ForegroundColor DarkRed
        }
    }
    
    # Verify final count
    $remainingReports = (Get-ChildItem -Path $Config.ReportsPath -Filter "*.md" | Where-Object { 
        $_.Name -notmatch 'backup' -and 
        $_.Name -notmatch '20250929-200755-' -and
        $_.FullName -notmatch '\\archive\\'
    }).Count
    
    Write-Host ""
    Write-Host "📈 Final Status:" -ForegroundColor Cyan
    Write-Host "  📄 Remaining Active Reports: $remainingReports" -ForegroundColor Green
    Write-Host "  🎯 Target: $($Config.TargetActiveReports)" -ForegroundColor Gray
    Write-Host "  📦 Archived Reports: $archivedCount" -ForegroundColor Yellow
    
    if ($remainingReports -le $Config.TargetActiveReports) {
        Write-Host ""
        Write-Host "🎉 ARCHIVE TARGET ACHIEVED!" -ForegroundColor Green
        Write-Host "   Active reports reduced to manageable number" -ForegroundColor Green
    } else {
        Write-Host ""
        Write-Host "⚠️  Target not fully achieved. Consider additional archiving criteria." -ForegroundColor Yellow
    }
    
} else {
    Write-Host ""
    Write-Host "🧪 DRY RUN - No files were actually moved" -ForegroundColor Yellow
    Write-Host "   Use -Force to perform actual archiving" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "✅ ECRR Archive Manager completed" -ForegroundColor Green

# Generate summary report
$summaryPath = Join-Path $Config.ReportsPath "archive-summary-$($Config.Timestamp).json"
$summary = @{
    Timestamp = $Config.Timestamp
    DryRun = $Config.DryRun
    TargetActiveReports = $Config.TargetActiveReports
    InitialReportCount = $totalReports
    ArchiveCandidates = $archiveCandidates.Count
    PlannedArchiveCount = $actualArchiveCount
    ActualArchiveCount = if ($Config.DryRun) { 0 } else { $archivedCount }
    RemainingReports = if ($Config.DryRun) { $totalReports } else { $remainingReports }
    ArchiveCriteria = $archiveCriteria
}

$summary | ConvertTo-Json -Depth 10 | Set-Content -Path $summaryPath -Encoding UTF8
Write-Host "📄 Summary report: $summaryPath" -ForegroundColor Gray
