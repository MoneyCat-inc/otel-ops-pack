# Repository Cleanup Script
# ECRR Compliant - Examine → Clean → Report → Role
# Enhanced with progress bars and time estimates

param(
    [switch]$DryRun = $true,
    [switch]$Force = $false
)

# Progress bar functions
function Write-ProgressBar {
    param(
        [int]$Percent,
        [string]$Activity,
        [string]$Status,
        [int]$SecondsRemaining = 0
    )
    
    $barLength = 30
    $filledLength = [math]::Floor($barLength * $Percent / 100)
    $bar = "█" * $filledLength + "░" * ($barLength - $filledLength)
    
    $timeStr = if ($SecondsRemaining -gt 0) { " (ETA: ${SecondsRemaining}s)" } else { "" }
    
    Write-Host "`r[$bar] $Percent% - $Activity - $Status$timeStr" -NoNewline -ForegroundColor Cyan
}

function Start-TimedOperation {
    param(
        [string]$Operation,
        [scriptblock]$ScriptBlock,
        [int]$EstimatedSeconds = 5
    )
    
    $startTime = Get-Date
    Write-Host "`n🔄 Starting: $Operation" -ForegroundColor Yellow
    Write-Host "Estimated time: $EstimatedSeconds seconds" -ForegroundColor Gray
    
    try {
        $result = & $ScriptBlock
        $endTime = Get-Date
        $actualSeconds = ($endTime - $startTime).TotalSeconds
        
        Write-Host "`n✅ Completed: $Operation" -ForegroundColor Green
        Write-Host "Actual time: $([math]::Round($actualSeconds, 1)) seconds" -ForegroundColor Gray
        
        return $result
    }
    catch {
        Write-Host "`n❌ Failed: $Operation" -ForegroundColor Red
        throw
    }
}

Write-Host "🧹 Repository Cleanup Script (Enhanced)" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

if ($DryRun -and !$Force) {
    Write-Host "🔍 DRY RUN MODE - No files will be deleted" -ForegroundColor Yellow
    Write-Host "Use -Force to actually delete files" -ForegroundColor Yellow
    Write-Host ""
}

# Define cleanup categories
$cleanupCategories = @{
    "Backup Files" = @(
        "*.backup-*",
        "*.bak-*",
        "config-backup-*.yaml",
        "config.backup-*.yaml",
        "config.bak-*.yaml"
    )
    
    "Redundant Status Reports" = @(
        "FINAL_*.md",
        "COMPLETE_*.md", 
        "SUMMARY_*.md",
        "STATUS_*.md",
        "REPORT_*.md",
        "HANDOFF_*.md",
        "DEPLOYMENT_*.md",
        "ROLLOUT_*.md",
        "IMPLEMENTATION_*.md",
        "VALIDATION_*.md",
        "VERIFICATION_*.md"
    )
    
    "Test Artifacts" = @(
        "validation-evidence-*",
        "test-*.html",
        "playwright-report*",
        "SigNoz _ Home*"
    )
    
    "Script Backups" = @(
        "scripts\*.backup-*",
        "scripts\*.bak-*"
    )
    
    "ECRR Backup Reports" = @(
        "docs\ECRR_REPORTS\*.backup-*"
    )
}

# Core files to preserve
$preservePatterns = @(
    "config.yaml",
    "package.json", 
    "pnpm-lock.yaml",
    "README.md",
    "docker-compose*.yml",
    "Dockerfile*",
    "lefthook.yml",
    "tsconfig.json",
    "playwright.*.config.ts",
    "requirements*.txt",
    ".cursorrules",
    ".agent\*",
    "scripts\*.ps1" # Keep all active scripts
)

$totalFilesToRemove = 0
$filesToRemove = @()

# Scan for files with progress tracking
Write-Host "📋 Scanning repository for cleanup targets..." -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green

$scanResult = Start-TimedOperation -Operation "File System Scan" -EstimatedSeconds 3 -ScriptBlock {
    $totalFilesToRemove = 0
    $filesToRemove = @()
    $categoryResults = @{}
    
    foreach ($category in $cleanupCategories.Keys) {
        $categoryFiles = @()
        
        foreach ($pattern in $cleanupCategories[$category]) {
            $matches = Get-ChildItem -Path . -Recurse -Name $pattern -File | Where-Object {
                $file = $_
                $shouldPreserve = $false
                foreach ($preserve in $preservePatterns) {
                    if ($file -like $preserve) {
                        $shouldPreserve = $true
                        break
                    }
                }
                return !$shouldPreserve
            }
            
            $categoryFiles += $matches
        }
        
        $categoryResults[$category] = $categoryFiles
        $totalFilesToRemove += $categoryFiles.Count
        $filesToRemove += $categoryFiles
    }
    
    return @{
        TotalFiles = $totalFilesToRemove
        FilesToRemove = $filesToRemove
        CategoryResults = $categoryResults
    }
}

$totalFilesToRemove = $scanResult.TotalFiles
$filesToRemove = $scanResult.FilesToRemove
$categoryResults = $scanResult.CategoryResults

# Display results
Write-Host "`n📋 Cleanup Plan:" -ForegroundColor Green
Write-Host "================" -ForegroundColor Green

foreach ($category in $categoryResults.Keys) {
    $categoryFiles = $categoryResults[$category]
    Write-Host "`n📁 $category" -ForegroundColor Yellow
    
    if ($categoryFiles.Count -gt 0) {
        Write-Host "  Found $($categoryFiles.Count) files to remove:" -ForegroundColor White
        foreach ($file in $categoryFiles | Sort-Object) {
            Write-Host "    - $file" -ForegroundColor Gray
        }
    } else {
        Write-Host "  No files found" -ForegroundColor Gray
    }
}

Write-Host "`n📊 Summary:" -ForegroundColor Green
Write-Host "===========" -ForegroundColor Green
Write-Host "Total files to remove: $totalFilesToRemove" -ForegroundColor White

if ($totalFilesToRemove -eq 0) {
    Write-Host "✅ No cleanup needed!" -ForegroundColor Green
    exit 0
}

if ($DryRun -and !$Force) {
    Write-Host "`n🔍 This was a DRY RUN. No files were actually removed." -ForegroundColor Yellow
    Write-Host "To execute the cleanup, run:" -ForegroundColor Yellow
    Write-Host "  .\cleanup-repository.ps1 -Force" -ForegroundColor Cyan
    exit 0
}

# Confirm deletion
if (!$Force) {
    $confirm = Read-Host "`n⚠️  Are you sure you want to remove $totalFilesToRemove files? (y/N)"
    if ($confirm -ne 'y' -and $confirm -ne 'Y') {
        Write-Host "❌ Cleanup cancelled" -ForegroundColor Red
        exit 0
    }
}

# Execute cleanup with progress tracking
$cleanupResult = Start-TimedOperation -Operation "File Cleanup" -EstimatedSeconds ([math]::Max(5, $totalFilesToRemove * 0.1)) -ScriptBlock {
    $removedCount = 0
    $errors = @()
    $currentFile = 0
    
    foreach ($file in $filesToRemove) {
        $currentFile++
        $percent = [math]::Floor(($currentFile / $filesToRemove.Count) * 100)
        
        try {
            if (Test-Path $file) {
                Remove-Item $file -Force
                Write-Host "`n  ✅ Removed: $file" -ForegroundColor Green
                $removedCount++
            }
        }
        catch {
            $errors += "Failed to remove $file`: $($_.Exception.Message)"
            Write-Host "`n  ❌ Failed: $file" -ForegroundColor Red
        }
        
        # Update progress
        if ($currentFile % 10 -eq 0 -or $currentFile -eq $filesToRemove.Count) {
            Write-Host "`n  Progress: $currentFile/$($filesToRemove.Count) files processed ($percent%)" -ForegroundColor Cyan
        }
    }
    
    return @{
        RemovedCount = $removedCount
        Errors = $errors
    }
}

$removedCount = $cleanupResult.RemovedCount
$errors = $cleanupResult.Errors

# Clean up empty directories with progress tracking
$directoryCleanupResult = Start-TimedOperation -Operation "Directory Cleanup" -EstimatedSeconds 2 -ScriptBlock {
    $emptyDirs = Get-ChildItem -Path . -Recurse -Directory | Where-Object { 
        $_.GetFiles().Count -eq 0 -and $_.GetDirectories().Count -eq 0 
    }
    
    $removedDirs = 0
    $dirErrors = @()
    
    foreach ($dir in $emptyDirs) {
        try {
            Remove-Item $dir.FullName -Force
            Write-Host "  ✅ Removed empty directory: $($dir.Name)" -ForegroundColor Green
            $removedDirs++
        }
        catch {
            $dirErrors += "Could not remove directory: $($dir.Name)"
            Write-Host "  ⚠️  Could not remove directory: $($dir.Name)" -ForegroundColor Yellow
        }
    }
    
    return @{
        RemovedDirs = $removedDirs
        DirErrors = $dirErrors
    }
}

# Report results
Write-Host "`n📊 Cleanup Results:" -ForegroundColor Green
Write-Host "===================" -ForegroundColor Green
Write-Host "Files removed: $removedCount/$totalFilesToRemove" -ForegroundColor White
Write-Host "Empty directories removed: $($directoryCleanupResult.RemovedDirs)" -ForegroundColor White

if ($errors.Count -gt 0) {
    Write-Host "`n❌ File removal errors:" -ForegroundColor Red
    foreach ($error in $errors) {
        Write-Host "  - $error" -ForegroundColor Red
    }
}

if ($directoryCleanupResult.DirErrors.Count -gt 0) {
    Write-Host "`n⚠️  Directory cleanup warnings:" -ForegroundColor Yellow
    foreach ($error in $directoryCleanupResult.DirErrors) {
        Write-Host "  - $error" -ForegroundColor Yellow
    }
}

Write-Host "`n✅ Repository cleanup completed!" -ForegroundColor Green

# Generate ECRR report with progress tracking
$reportGenerationResult = Start-TimedOperation -Operation "ECRR Report Generation" -EstimatedSeconds 1 -ScriptBlock {
    $reportContent = @"
# Repository Cleanup ECRR Report

## Examine
- Analyzed repository structure and identified cleanup targets
- Found $totalFilesToRemove files eligible for removal
- Preserved core configuration and active scripts
- Enhanced script with progress bars and time estimates

## Clean  
- Removed $removedCount files across multiple categories:
  - Backup files (*.backup-*, *.bak-*)
  - Redundant status/report files
  - Test artifacts and evidence
  - ECRR backup reports
- Cleaned up $($directoryCleanupResult.RemovedDirs) empty directories
- Applied progress tracking with time estimates

## Report
- Cleanup script: cleanup-repository.ps1 (Enhanced)
- Files removed: $removedCount/$totalFilesToRemove
- Empty directories removed: $($directoryCleanupResult.RemovedDirs)
- File errors: $($errors.Count)
- Directory warnings: $($directoryCleanupResult.DirErrors.Count)
- Timestamp: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## Role
- **Cursor Agent - Observability Copilot**: Repository maintenance and cleanup with enhanced UX
- **ECRR Framework**: Applied Examine → Clean → Report → Role methodology
- **Progress Enhancement**: Added progress bars and time estimates for better user experience
"@

    # Ensure ECRR_REPORTS directory exists
    $ecrrDir = "docs/ECRR_REPORTS"
    if (!(Test-Path $ecrrDir)) {
        New-Item -ItemType Directory -Path $ecrrDir -Force | Out-Null
    }
    
    $reportPath = "$ecrrDir/$(Get-Date -Format 'yyyy-MM-dd')-repository-cleanup-complete.md"
    $reportContent | Out-File -FilePath $reportPath -Encoding UTF8
    
    return $reportPath
}

Write-Host "📝 ECRR report saved: $reportGenerationResult" -ForegroundColor Cyan
