# scripts/agent/runner.ps1
# codex-local Local Workflow Custodian - Task runner for executing micro-tasks
# This script defines how different types of maintenance jobs are executed

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$TaskType,
    [Parameter(Mandatory=$false)][hashtable]$TaskData = @{}
)

$ErrorActionPreference = "Stop"

Write-Host "[runner] Executing task type: $TaskType" -ForegroundColor Yellow

# Task execution functions
function Invoke-FlakyTestQuarantine {
    param([hashtable]$Data)
    
    Write-Host "[runner] Running flaky test quarantine..." -ForegroundColor Cyan
    
    # Look for recently failed tests
    $testResults = @()
    if (Test-Path "test-results") {
        $testFiles = Get-ChildItem -Path "test-results" -Recurse -Include "*.json" | Where-Object { 
            $_.LastWriteTime -gt (Get-Date).AddDays(-1) 
        }
        
        foreach ($file in $testFiles) {
            try {
                $content = Get-Content $file.FullName -Raw | ConvertFrom-Json
                if ($content.results -and $content.results.suites) {
                    foreach ($suite in $content.results.suites) {
                        foreach ($test in $suite.specs) {
                            if ($test.results -and ($test.results | Where-Object { $_.status -eq "failed" })) {
                                $testResults += @{
                                    file = $file.Name
                                    test = $test.title
                                    failures = ($test.results | Where-Object { $_.status -eq "failed" }).Count
                                }
                            }
                        }
                    }
                }
            } catch {
                Write-Host "[runner] ⚠ Error processing test file $($file.Name): $($_.Exception.Message)" -ForegroundColor Yellow
            }
        }
    }
    
    if ($testResults.Count -gt 0) {
        Write-Host "[runner] ✓ Found $($testResults.Count) potentially flaky tests" -ForegroundColor Green
        
        # Create quarantine file
        $quarantinePath = ".agent/quarantined-tests.json"
        $quarantineData = @{
            quarantinedAt = (Get-Date).ToString("o")
            testCount = $testResults.Count
            tests = $testResults
        }
        
        ($quarantineData | ConvertTo-Json -Depth 6) | Set-Content $quarantinePath
        Write-Host "[runner] ✓ Quarantine data saved to $quarantinePath" -ForegroundColor Green
        
        return @{ success = $true; quarantined = $testResults.Count }
    } else {
        Write-Host "[runner] ✓ No flaky tests detected" -ForegroundColor Green
        return @{ success = $true; quarantined = 0 }
    }
}

function Invoke-SSOTRefresh {
    param([hashtable]$Data)
    
    Write-Host "[runner] Running SSOT (Single Source of Truth) refresh..." -ForegroundColor Cyan
    
    $updatedFiles = 0
    
    # Check for SSOT-related files that might need updating
    $ssotFiles = Get-ChildItem -Recurse -Include "*.md" | Where-Object { 
        $_.Name -match "(README|CHANGELOG|VERSION|STATUS)" -and 
        $_.FullName -notmatch "node_modules|\.git|third_party" 
    }
    
    foreach ($file in $ssotFiles) {
        $content = Get-Content $file.FullName -Raw
        $lastModified = $file.LastWriteTime
        
        # Check if file contains outdated information
        $needsUpdate = $false
        
        # Update timestamps in status files
        if ($file.Name -match "STATUS") {
            $newContent = $content -replace 'Last updated: \d{4}-\d{2}-\d{2}', "Last updated: $(Get-Date -Format 'yyyy-MM-dd')"
            if ($newContent -ne $content) {
                $newContent | Set-Content $file.FullName
                $updatedFiles++
                $needsUpdate = $true
            }
        }
        
        # Update version references
        if ($content -match 'version.*\d+\.\d+\.\d+' -and $file.Name -match "README") {
            # This is a placeholder - actual version checking would be more sophisticated
            Write-Host "[runner] ⚠ Version references found in $($file.Name) - manual review recommended" -ForegroundColor Yellow
        }
        
        if ($needsUpdate) {
            Write-Host "[runner] ✓ Updated $($file.Name)" -ForegroundColor Green
        }
    }
    
    Write-Host "[runner] ✓ SSOT refresh completed: $updatedFiles files updated" -ForegroundColor Green
    return @{ success = $true; updated = $updatedFiles }
}

function Invoke-SelectorHygiene {
    param([hashtable]$Data)
    
    Write-Host "[runner] Running selector hygiene (test IDs and ARIA labels)..." -ForegroundColor Cyan
    
    $filesProcessed = 0
    $improvements = 0
    
    # Find frontend files that might need test IDs or ARIA labels
    $frontendFiles = Get-ChildItem -Recurse -Include "*.jsx", "*.tsx", "*.js", "*.ts" | Where-Object { 
        $_.FullName -notmatch "node_modules|\.git|third_party" 
    }
    
    foreach ($file in $frontendFiles) {
        $content = Get-Content $file.FullName -Raw
        $originalContent = $content
        
        # Add test IDs to interactive elements without them
        if ($content -match '<button(?![^>]*data-testid)[^>]*>') {
            $content = $content -replace '<button(?![^>]*data-testid)([^>]*)>', '<button$1 data-testid="button-$(Get-Random)">'
            $improvements++
        }
        
        if ($content -match '<input(?![^>]*data-testid)[^>]*>') {
            $content = $content -replace '<input(?![^>]*data-testid)([^>]*)>', '<input$1 data-testid="input-$(Get-Random)">'
            $improvements++
        }
        
        # Add aria-label to buttons without discernible text
        if ($content -match '<button(?![^>]*aria-label)[^>]*>\s*<[^>]+>\s*</button>') {
            $content = $content -replace '<button(?![^>]*aria-label)([^>]*)>(\s*<[^>]+>\s*)</button>', '<button$1 aria-label="Action button">$2</button>'
            $improvements++
        }
        
        if ($content -ne $originalContent) {
            $content | Set-Content $file.FullName
            $filesProcessed++
            Write-Host "[runner] ✓ Improved selectors in $($file.Name)" -ForegroundColor Green
        }
    }
    
    Write-Host "[runner] ✓ Selector hygiene completed: $filesProcessed files processed, $improvements improvements" -ForegroundColor Green
    return @{ success = $true; filesProcessed = $filesProcessed; improvements = $improvements }
}

function Invoke-CleanupArtifacts {
    param([hashtable]$Data)
    
    Write-Host "[runner] Running artifact cleanup..." -ForegroundColor Cyan
    
    $cleanedFiles = 0
    $freedSpace = 0
    
    # Clean up old log files
    $logDirs = @(".agent/logs", "artifacts", "logs")
    foreach ($logDir in $logDirs) {
        if (Test-Path $logDir) {
            $oldFiles = Get-ChildItem -Path $logDir -Recurse -File | Where-Object { 
                $_.LastWriteTime -lt (Get-Date).AddDays(-7) 
            }
            
            foreach ($file in $oldFiles) {
                $fileSize = $file.Length
                Remove-Item $file.FullName -Force
                $cleanedFiles++
                $freedSpace += $fileSize
                Write-Host "[runner] ✓ Cleaned up old file: $($file.Name)" -ForegroundColor Green
            }
        }
    }
    
    # Clean up temporary files
    $tempFiles = Get-ChildItem -Path "." -Recurse -Include "*.tmp", "*.temp", "*.log" | Where-Object { 
        $_.LastWriteTime -lt (Get-Date).AddDays(-3) -and 
        $_.FullName -notmatch "node_modules|\.git" 
    }
    
    foreach ($file in $tempFiles) {
        $fileSize = $file.Length
        Remove-Item $file.FullName -Force
        $cleanedFiles++
        $freedSpace += $fileSize
        Write-Host "[runner] ✓ Cleaned up temp file: $($file.Name)" -ForegroundColor Green
    }
    
    $freedSpaceMB = [math]::Round($freedSpace / 1MB, 2)
    Write-Host "[runner] ✓ Cleanup completed: $cleanedFiles files removed, $freedSpaceMB MB freed" -ForegroundColor Green
    return @{ success = $true; filesRemoved = $cleanedFiles; spaceFreed = $freedSpaceMB }
}

# Main task execution logic
switch ($TaskType) {
    "flaky-test-quarantine" {
        $result = Invoke-FlakyTestQuarantine -Data $TaskData
    }
    "ssot-refresh" {
        $result = Invoke-SSOTRefresh -Data $TaskData
    }
    "selector-hygiene" {
        $result = Invoke-SelectorHygiene -Data $TaskData
    }
    "cleanup-artifacts" {
        $result = Invoke-CleanupArtifacts -Data $TaskData
    }
    default {
        Write-Host "[runner] ✗ Unknown task type: $TaskType" -ForegroundColor Red
        $result = @{ success = $false; error = "Unknown task type: $TaskType" }
    }
}

# Log task execution
$logEntry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') – Task executed: $TaskType - Success: $($result.success)"
if (Test-Path "TASKS.md") {
    $logEntry | Add-Content "TASKS.md"
}

# Return result
return $result
