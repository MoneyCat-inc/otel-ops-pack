# Test script for File Storage Directory Validation
# ECRR: Examine → Clean → Report → Role

Set-StrictMode -Version 2
$ErrorActionPreference = "Stop"

Write-Host "=== File Storage Directory Test ===" -ForegroundColor Green

$script:testPassed = $true
$storageDir = "otelcol-storage"
$testArtifacts = @()

function Write-Pass { param([string]$Message) Write-Host "   [OK] $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "   [FAIL] $Message" -ForegroundColor Red; $script:testPassed = $false }
function Write-Detail { param([string]$Message) if ($Message) { Write-Host "      $Message" -ForegroundColor DarkGray } }

Write-Host "`n1. Storage Directory Validation:" -ForegroundColor Yellow

# Check if storage directory exists
if (Test-Path $storageDir) {
    Write-Pass "Storage directory exists: $storageDir"
    
    try {
        $storageItems = @(Get-ChildItem -Path $storageDir -Recurse -ErrorAction Stop)
        $itemCount = $storageItems.Count
        Write-Detail "Directory contains $itemCount items"
        
        if ($itemCount -gt 0) {
            $storageSize = ($storageItems | Measure-Object -Property Length -Sum).Sum
            $storageSizeMB = [math]::Round($storageSize / 1MB, 2)
            Write-Detail "Total size: $storageSizeMB MB"
            
            # Check for common OTel storage files
            $queueFiles = $storageItems | Where-Object { $_.Name -like "*queue*" -or $_.Name -like "*batch*" }
            if ($queueFiles) {
                Write-Pass "Queue persistence files detected: $($queueFiles.Count) files"
                $queueFiles | ForEach-Object { Write-Detail "  - $($_.Name) ($([math]::Round($_.Length / 1KB, 1)) KB)" }
            } else {
                Write-Detail "No queue persistence files found (normal for fresh install)"
            }
        } else {
            Write-Detail "Storage directory is empty (normal for fresh install)"
        }
    } catch {
        Write-Fail "Failed to analyze storage directory: $($_.Exception.Message)"
    }
} else {
    Write-Detail "Storage directory not found: $storageDir"
    
    # Try to create it
    try {
        New-Item -Path $storageDir -ItemType Directory -Force | Out-Null
        Write-Pass "Created storage directory: $storageDir"
    } catch {
        Write-Fail "Failed to create storage directory: $($_.Exception.Message)"
    }
}

Write-Host "`n2. Directory Permissions Test:" -ForegroundColor Yellow
if (Test-Path $storageDir) {
    try {
        # Test write permissions
        $testFile = Join-Path $storageDir "test-write-permissions.tmp"
        "test-content-$(Get-Date -Format 'yyyyMMdd-HHmmss')" | Out-File -FilePath $testFile -Encoding ascii
        if (Test-Path $testFile) {
            Write-Pass "Write permissions verified"
            Remove-Item -Path $testFile -Force
            Write-Detail "Test file cleaned up"
        } else {
            Write-Fail "Write permissions test failed"
        }
        
        # Test subdirectory creation
        $testSubDir = Join-Path $storageDir "test-subdir"
        New-Item -Path $testSubDir -ItemType Directory -Force | Out-Null
        if (Test-Path $testSubDir) {
            Write-Pass "Subdirectory creation verified"
            Remove-Item -Path $testSubDir -Force
            Write-Detail "Test subdirectory cleaned up"
        } else {
            Write-Fail "Subdirectory creation test failed"
        }
    } catch {
        Write-Fail "Permissions test failed: $($_.Exception.Message)"
    }
}

Write-Host "`n3. Queue Persistence Simulation:" -ForegroundColor Yellow
try {
    # Simulate what OTel collector might write
    $simulatedQueueDir = Join-Path $storageDir "queues"
    if (-not (Test-Path $simulatedQueueDir)) {
        New-Item -Path $simulatedQueueDir -ItemType Directory -Force | Out-Null
    }
    
    $simulatedBatchFile = Join-Path $simulatedQueueDir "batch-test-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $simulatedBatch = @{
        timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        batch_id = [Guid]::NewGuid().ToString()
        records = @(
            @{ id = 1; message = "test-log-entry-1" },
            @{ id = 2; message = "test-log-entry-2" }
        )
        size_bytes = 256
    } | ConvertTo-Json -Depth 3
    
    $simulatedBatch | Out-File -FilePath $simulatedBatchFile -Encoding utf8NoBOM
    Write-Pass "Simulated queue persistence file created"
    Write-Detail "File: $simulatedBatchFile"
    
    # Verify we can read it back
    $readBack = Get-Content -Path $simulatedBatchFile -Raw
    if ($readBack -match "test-log-entry-1") {
        Write-Pass "Queue persistence read-back verified"
    } else {
        Write-Fail "Queue persistence read-back failed"
    }
    
    # Clean up simulation
    Remove-Item -Path $simulatedBatchFile -Force
    Remove-Item -Path $simulatedQueueDir -Force -ErrorAction SilentlyContinue
    Write-Detail "Simulation files cleaned up"
    
} catch {
    Write-Fail "Queue persistence simulation failed: $($_.Exception.Message)"
}

Write-Host "`n4. Storage Health Summary:" -ForegroundColor Yellow
if (Test-Path $storageDir) {
    try {
        $storageItems = @(Get-ChildItem -Path $storageDir -Recurse -ErrorAction SilentlyContinue)
        $totalSize = ($storageItems | Measure-Object -Property Length -Sum).Sum
        $totalSizeMB = [math]::Round($totalSize / 1MB, 2)
        
        Write-Pass "Storage directory health: OK"
        Write-Detail "Total items: $($storageItems.Count)"
        Write-Detail "Total size: $totalSizeMB MB"
        Write-Detail "Directory: $storageDir"
        
        # Store results for ECRR report
        $testArtifacts += @{
            timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            test_type = "file_storage_validation"
            storage_directory = $storageDir
            item_count = $storageItems.Count
            total_size_mb = $totalSizeMB
            test_passed = $testPassed
        }
        
    } catch {
        Write-Fail "Storage health summary failed: $($_.Exception.Message)"
    }
}

Write-Host "`n=== Test Complete ===" -ForegroundColor Green
if ($testPassed) {
    Write-Host "✅ File storage validation PASSED" -ForegroundColor Green
    Write-Host "`nStorage directory is ready for OTel collector queue persistence" -ForegroundColor Green
} else {
    Write-Host "❌ File storage validation FAILED" -ForegroundColor Red
    Write-Host "Review errors above and ensure proper permissions" -ForegroundColor Red
}

# Save test artifacts
$artifactsDir = ".artifacts"
if (-not (Test-Path $artifactsDir)) { New-Item -Path $artifactsDir -ItemType Directory -Force | Out-Null }
$artifactsFile = Join-Path $artifactsDir "file-storage-test-results.json"
$testArtifacts | ConvertTo-Json -Depth 3 | Out-File -FilePath $artifactsFile -Encoding utf8NoBOM
Write-Host "`nTest artifacts saved: $artifactsFile" -ForegroundColor Cyan

exit $(if ($testPassed) { 0 } else { 1 })
