# Simple Repository Cleanup Script
# ECRR Compliant - Examine → Clean → Report → Role
# Enhanced with progress bars and time estimates

param(
    [switch]$DryRun = $true,
    [switch]$Force = $false
)

# Progress bar and spinner functions
$global:spinnerChars = @('|', '/', '-', '\')
$global:spinnerIndex = 0

function Write-Spinner {
    param(
        [string]$Message,
        [string]$Color = "Cyan"
    )
    
    $global:spinnerIndex = ($global:spinnerIndex + 1) % $global:spinnerChars.Length
    $spinner = $global:spinnerChars[$global:spinnerIndex]
    Write-Host "`r$spinner $Message" -NoNewline -ForegroundColor $Color
}

function Write-ProgressBar {
    param(
        [int]$Percent,
        [string]$Activity,
        [string]$Status,
        [int]$SecondsRemaining = 0,
        [switch]$ShowSpinner = $false
    )
    
    $barLength = 30
    $filledLength = [math]::Floor($barLength * $Percent / 100)
    $bar = "=" * $filledLength + "-" * ($barLength - $filledLength)
    
    $timeStr = if ($SecondsRemaining -gt 0) { " (ETA: ${SecondsRemaining}s)" } else { "" }
    $spinner = if ($ShowSpinner) { " $($global:spinnerChars[$global:spinnerIndex])" } else { "" }
    
    Write-Host "`r[$bar] $Percent% - $Activity - $Status$timeStr$spinner" -NoNewline -ForegroundColor Cyan
}

function Start-SpinnerJob {
    param(
        [string]$Message,
        [scriptblock]$ScriptBlock,
        [int]$UpdateIntervalMs = 100
    )
    
    $job = Start-Job -ScriptBlock {
        param($Message, $UpdateIntervalMs)
        $spinnerChars = @('|', '/', '-', '\')
        $index = 0
        while ($true) {
            $index = ($index + 1) % $spinnerChars.Length
            $spinner = $spinnerChars[$index]
            Write-Host "`r$spinner $Message" -NoNewline -ForegroundColor Cyan
            Start-Sleep -Milliseconds $UpdateIntervalMs
        }
    } -ArgumentList $Message, $UpdateIntervalMs
    
    return $job
}

function Stop-SpinnerJob {
    param([System.Management.Automation.Job]$Job)
    
    if ($Job) {
        Stop-Job $Job -ErrorAction SilentlyContinue
        Remove-Job $Job -ErrorAction SilentlyContinue
        Write-Host "`r" -NoNewline
    }
}

function Start-TimedOperation {
    param(
        [string]$Operation,
        [scriptblock]$ScriptBlock,
        [int]$EstimatedSeconds = 5,
        [switch]$ShowSpinner = $false
    )
    
    $startTime = Get-Date
    Write-Host "`n[START] $Operation" -ForegroundColor Yellow
    Write-Host "Estimated time: $EstimatedSeconds seconds" -ForegroundColor Gray
    
    # Start spinner if requested
    $spinnerJob = $null
    if ($ShowSpinner) {
        $spinnerJob = Start-SpinnerJob -Message "$Operation in progress..." -UpdateIntervalMs 150
    }
    
    try {
        $result = & $ScriptBlock
        $endTime = Get-Date
        $actualSeconds = ($endTime - $startTime).TotalSeconds
        
        # Stop spinner
        Stop-SpinnerJob -Job $spinnerJob
        
        Write-Host "`n[DONE] $Operation" -ForegroundColor Green
        Write-Host "Actual time: $([math]::Round($actualSeconds, 1)) seconds" -ForegroundColor Gray
        
        return $result
    }
    catch {
        # Stop spinner on error
        Stop-SpinnerJob -Job $spinnerJob
        Write-Host "`n[FAIL] $Operation" -ForegroundColor Red
        throw
    }
}

Write-Host "CLEANUP: Simple Repository Cleanup Script (Enhanced)" -ForegroundColor Cyan
Write-Host "=====================================================" -ForegroundColor Cyan

if ($DryRun -and !$Force) {
    Write-Host "DRY RUN MODE - No files will be deleted" -ForegroundColor Yellow
    Write-Host "Use -Force to actually delete files" -ForegroundColor Yellow
    Write-Host ""
}

# Define cleanup patterns
$cleanupPatterns = @(
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
    "VERIFICATION_*.md",
    "*.backup-*",
    "*.bak-*",
    "ACTUAL_*.md",
    "CURRENT_*.md",
    "AGENT_*.md",
    "AUTOMATION_*.md",
    "BACKGROUND_*.md",
    "BASELINE_*.md",
    "CANARY_*.md",
    "CHAOS_*.md",
    "CI_*.md",
    "CLEAN_*.md",
    "CODEX_*.md",
    "COLLECTOR_*.md",
    "COMFORT_*.md",
    "COMPONENTS_*.md",
    "COMPREHENSIVE_*.md",
    "CONFLICT_*.md",
    "COPILOT_*.md",
    "CURSOR_*.md",
    "DECISIONS_*.md",
    "DOCKER_*.md",
    "DOE_*.md",
    "ECRR_*.md",
    "ENHANCED_*.md",
    "EXPERIMENTS_*.md",
    "FILE_*.md",
    "FIXES_*.md",
    "GO_*.md",
    "GPU_*.md",
    "GREEN_*.md",
    "GUARDRAILS_*.md",
    "HARDENED_*.md",
    "HEALTH_*.md",
    "IMPORT_*.md",
    "INLINE_*.md",
    "INTEGRATION_*.md",
    "LATENCY_*.md",
    "LOCAL_*.md",
    "MEMX_*.md",
    "MIC_*.md",
    "MIGRATE_*.md",
    "MONITOR_*.md",
    "MULTI_*.md",
    "OBSERVABILITY_*.md",
    "ON_*.md",
    "OPS_*.md",
    "OPTIMIZATION_*.md",
    "OTEL_*.md",
    "PACKAGE_*.md",
    "PARALLEL_*.md",
    "PHASE_*.md",
    "PIPELINE_*.md",
    "PLAYWRIGHT_*.md",
    "POLISH_*.md",
    "POST_*.md",
    "PRESSURE_*.md",
    "PRIORITY_*.md",
    "PRODUCTION_*.md",
    "PROJECT_*.md",
    "QUEUE_*.md",
    "QUICK_*.md",
    "REPO_*.md",
    "REPOSITORY_*.md",
    "REQUIREMENTS_*.md",
    "RESONAI_*.md",
    "RESTART_*.md",
    "ROLLOUT_*.md",
    "RUN_*.md",
    "SAFE_*.md",
    "SCREENSHOT_*.md",
    "SCRIPTS_*.md",
    "SETUP_*.md",
    "SIDECARS_*.md",
    "SIGNOZ_*.md",
    "STACK_*.md",
    "STARTUP_*.md",
    "SUCCESS_*.md",
    "SYSTEM_*.md",
    "TASK_*.md",
    "TEMPLATES_*.md",
    "TEST_*.md",
    "THIRD_*.md",
    "TOOLS_*.md",
    "TRAP_*.md",
    "VALIDATE_*.md",
    "VISUAL_*.md",
    "WEBHOOK_*.md",
    "WORKFLOW_*.md",
    "YAML_*.md"
)

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
    "scripts\*.ps1"
)

# Scan for files with progress tracking
Write-Host "SCAN: Scanning repository for cleanup targets..." -ForegroundColor Green
Write-Host "=================================================" -ForegroundColor Green

$scanResult = Start-TimedOperation -Operation "File System Scan" -EstimatedSeconds 3 -ShowSpinner -ScriptBlock {
    $filesToRemove = @()
    $patternCount = 0
    $totalPatterns = $cleanupPatterns.Count
    
    foreach ($pattern in $cleanupPatterns) {
        $patternCount++
        $percent = [math]::Floor(($patternCount / $totalPatterns) * 100)
        $remaining = [math]::Max(0, 3 - (($patternCount / $totalPatterns) * 3))
        
        # Update progress with spinner
        Write-ProgressBar -Percent $percent -Activity "Scanning" -Status "Pattern $patternCount/$totalPatterns" -SecondsRemaining $remaining -ShowSpinner
        
        $matches = Get-ChildItem -Path . -Name $pattern -File -ErrorAction SilentlyContinue | Where-Object {
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
        
        if ($matches.Count -gt 0) {
            Write-Host "`n  Found $($matches.Count) files matching: $pattern" -ForegroundColor Yellow
        }
        
        $filesToRemove += $matches
    }
    
    Write-Host "`n  Scan complete: $($filesToRemove.Count) total files found" -ForegroundColor Green
    return $filesToRemove
}

$totalFilesToRemove = $scanResult.Count
$filesToRemove = $scanResult

# Display results
Write-Host "`nPLAN: Cleanup Plan" -ForegroundColor Green
Write-Host "==================" -ForegroundColor Green

if ($totalFilesToRemove -gt 0) {
    Write-Host "Found $totalFilesToRemove files to remove:" -ForegroundColor White
    
    # Group files by pattern for better organization
    $groupedFiles = @{}
    foreach ($file in $filesToRemove) {
        $pattern = $file -replace '_.*', '_*'
        if (!$groupedFiles.ContainsKey($pattern)) {
            $groupedFiles[$pattern] = @()
        }
        $groupedFiles[$pattern] += $file
    }
    
    foreach ($pattern in $groupedFiles.Keys | Sort-Object) {
        $files = $groupedFiles[$pattern] | Sort-Object
        Write-Host "`n  $pattern ($($files.Count) files):" -ForegroundColor Yellow
        foreach ($file in $files) {
            Write-Host "    - $file" -ForegroundColor Gray
        }
    }
} else {
    Write-Host "No files found for cleanup" -ForegroundColor Gray
}

Write-Host "`nSUMMARY:" -ForegroundColor Green
Write-Host "=========" -ForegroundColor Green
Write-Host "Total files to remove: $totalFilesToRemove" -ForegroundColor White

if ($totalFilesToRemove -eq 0) {
    Write-Host "[OK] No cleanup needed!" -ForegroundColor Green
    exit 0
}

if ($DryRun -and !$Force) {
    Write-Host "`n[DRY RUN] This was a DRY RUN. No files were actually removed." -ForegroundColor Yellow
    Write-Host "To execute the cleanup, run:" -ForegroundColor Yellow
    Write-Host "  .\cleanup-simple.ps1 -Force" -ForegroundColor Cyan
    exit 0
}

# Confirm deletion
if (!$Force) {
    $confirm = Read-Host "`n[WARN] Are you sure you want to remove $totalFilesToRemove files? (y/N)"
    if ($confirm -ne 'y' -and $confirm -ne 'Y') {
        Write-Host "[CANCEL] Cleanup cancelled" -ForegroundColor Red
        exit 0
    }
}

# Execute cleanup with progress tracking
$cleanupResult = Start-TimedOperation -Operation "File Cleanup" -EstimatedSeconds ([math]::Max(3, $totalFilesToRemove * 0.2)) -ShowSpinner -ScriptBlock {
    $removedCount = 0
    $errors = @()
    $currentFile = 0
    $totalFiles = $filesToRemove.Count
    $estimatedTime = [math]::Max(3, $totalFiles * 0.2)
    
    foreach ($file in $filesToRemove) {
        $currentFile++
        $percent = [math]::Floor(($currentFile / $totalFiles) * 100)
        $remaining = [math]::Max(0, $estimatedTime - (($currentFile / $totalFiles) * $estimatedTime))
        
        try {
            if (Test-Path $file) {
                Remove-Item $file -Force
                Write-Host "`n  [OK] Removed: $file" -ForegroundColor Green
                $removedCount++
            }
        }
        catch {
            $errors += "Failed to remove $file`: $($_.Exception.Message)"
            Write-Host "`n  [FAIL] Failed: $file" -ForegroundColor Red
        }
        
        # Update progress with spinner
        Write-ProgressBar -Percent $percent -Activity "Cleaning" -Status "File $currentFile/$totalFiles" -SecondsRemaining $remaining -ShowSpinner
    }
    
    return @{
        RemovedCount = $removedCount
        Errors = $errors
    }
}

$removedCount = $cleanupResult.RemovedCount
$errors = $cleanupResult.Errors

# Report results
Write-Host "`nRESULTS: Cleanup Results" -ForegroundColor Green
Write-Host "========================" -ForegroundColor Green
Write-Host "Files removed: $removedCount/$totalFilesToRemove" -ForegroundColor White

if ($errors.Count -gt 0) {
    Write-Host "`n[ERROR] File removal errors:" -ForegroundColor Red
    foreach ($error in $errors) {
        Write-Host "  - $error" -ForegroundColor Red
    }
}

Write-Host "`n[SUCCESS] Repository cleanup completed!" -ForegroundColor Green

# Generate ECRR report
$reportGenerationResult = Start-TimedOperation -Operation "ECRR Report Generation" -EstimatedSeconds 1 -ShowSpinner -ScriptBlock {
    $reportContent = @"
# Simple Repository Cleanup ECRR Report

## Examine
- Analyzed repository structure and identified cleanup targets
- Found $totalFilesToRemove files eligible for removal
- Preserved core configuration and active scripts
- Enhanced script with progress bars and time estimates

## Clean  
- Removed $removedCount files across multiple categories:
  - Redundant status/report files (FINAL_*, COMPLETE_*, etc.)
  - Backup files (*.backup-*, *.bak-*)
- Applied progress tracking with time estimates

## Report
- Cleanup script: cleanup-simple.ps1 (Enhanced)
- Files removed: $removedCount/$totalFilesToRemove
- File errors: $($errors.Count)
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
    
    $reportPath = "$ecrrDir/$(Get-Date -Format 'yyyy-MM-dd')-simple-cleanup-complete.md"
    $reportContent | Out-File -FilePath $reportPath -Encoding UTF8
    
    return $reportPath
}

Write-Host "[REPORT] ECRR report saved: $reportGenerationResult" -ForegroundColor Cyan
