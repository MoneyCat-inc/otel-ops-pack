# Test File Storage Script
# Tests file storage directory functionality and queue persistence

param(
    [int]$TestDurationMinutes = 2,
    [switch]$TestWritePermissions,
    [switch]$TestQueuePersistence,
    [switch]$TestLockFiles,
    [switch]$TestAll
)

Write-Host "=== File Storage Testing ===" -ForegroundColor Green
Write-Host "Test duration: $TestDurationMinutes minutes" -ForegroundColor Yellow

# Ensure artifacts directory exists
if (-not (Test-Path "artifacts")) {
    New-Item -ItemType Directory -Path "artifacts" -Force
}

$testStartTime = Get-Date
$testResults = @{
    test_id = "file-storage-test"
    start_time = $testStartTime.ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    duration_minutes = $TestDurationMinutes
    tests_run = @()
    summary = @{}
}

# Test 1: Write Permissions
if ($TestWritePermissions -or $TestAll) {
    Write-Host "`n=== Testing Write Permissions ===" -ForegroundColor Yellow
    
    $writeTest = @{
        name = "Write Permissions"
        status = "running"
        description = "Test file storage directory write permissions"
    }
    
    $fileStorageDir = "otelcol-storage"
    if (-not (Test-Path $fileStorageDir)) {
        try {
            New-Item -Path $fileStorageDir -ItemType Directory -Force | Out-Null
            Write-Host "Created file storage directory: $fileStorageDir" -ForegroundColor Green
        } catch {
            $writeTest.status = "failed"
            $writeTest.error = "Failed to create directory: $($_.Exception.Message)"
            $testResults.tests_run += $writeTest
            continue
        }
    }
    
    try {
        $testFile = Join-Path $fileStorageDir "test-write-$(Get-Date -Format 'yyyyMMdd-HHmmss').tmp"
        $testContent = "File storage test - $(Get-Date)"
        $testContent | Out-File -FilePath $testFile -Encoding UTF8 -Force
        
        if (Test-Path $testFile) {
            $fileSize = (Get-Item $testFile).Length
            Write-Host "✓ Write test successful: $testFile ($fileSize bytes)" -ForegroundColor Green
            
            # Clean up test file
            Remove-Item -Path $testFile -Force
            Write-Host "✓ Test file cleaned up" -ForegroundColor Green
            
            $writeTest.status = "passed"
            $writeTest.result = "Write permissions working correctly"
        } else {
            $writeTest.status = "failed"
            $writeTest.error = "Test file not created"
        }
    } catch {
        $writeTest.status = "failed"
        $writeTest.error = "Write test failed: $($_.Exception.Message)"
    }
    
    $testResults.tests_run += $writeTest
}

# Test 2: Queue Persistence
if ($TestQueuePersistence -or $TestAll) {
    Write-Host "`n=== Testing Queue Persistence ===" -ForegroundColor Yellow
    
    $queueTest = @{
        name = "Queue Persistence"
        status = "running"
        description = "Test queue persistence file creation and access"
    }
    
    $fileStorageDir = "otelcol-storage"
    $queueDir = Join-Path $fileStorageDir "queues"
    
    try {
        if (-not (Test-Path $queueDir)) {
            New-Item -Path $queueDir -ItemType Directory -Force | Out-Null
            Write-Host "Created queue directory: $queueDir" -ForegroundColor Green
        }
        
        # Create mock queue persistence file
        $queueFile = Join-Path $queueDir "otelcol-queue-persistence.dat"
        $queueData = @{
            timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            queue_size = 0
            queue_capacity = 1000
            test_data = "Queue persistence test"
        } | ConvertTo-Json -Depth 2
        
        $queueData | Out-File -FilePath $queueFile -Encoding UTF8 -Force
        
        if (Test-Path $queueFile) {
            $fileSize = (Get-Item $queueFile).Length
            Write-Host "✓ Queue persistence file created: $queueFile ($fileSize bytes)" -ForegroundColor Green
            
            # Test file access
            $readData = Get-Content -Path $queueFile -Raw | ConvertFrom-Json
            if ($readData.test_data -eq "Queue persistence test") {
                Write-Host "✓ Queue persistence file readable" -ForegroundColor Green
                $queueTest.status = "passed"
                $queueTest.result = "Queue persistence working correctly"
            } else {
                $queueTest.status = "failed"
                $queueTest.error = "Queue persistence file not readable"
            }
        } else {
            $queueTest.status = "failed"
            $queueTest.error = "Queue persistence file not created"
        }
    } catch {
        $queueTest.status = "failed"
        $queueTest.error = "Queue persistence test failed: $($_.Exception.Message)"
    }
    
    $testResults.tests_run += $queueTest
}

# Test 3: Lock Files
if ($TestLockFiles -or $TestAll) {
    Write-Host "`n=== Testing Lock Files ===" -ForegroundColor Yellow
    
    $lockTest = @{
        name = "Lock Files"
        status = "running"
        description = "Test lock file creation and cleanup"
    }
    
    $fileStorageDir = "otelcol-storage"
    $lockFile = Join-Path $fileStorageDir ".lock"
    
    try {
        # Create lock file
        $lockContent = @{
            pid = $PID
            timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            process_name = "test-file-storage"
        } | ConvertTo-Json -Depth 2
        
        $lockContent | Out-File -FilePath $lockFile -Encoding UTF8 -Force
        
        if (Test-Path $lockFile) {
            Write-Host "✓ Lock file created: $lockFile" -ForegroundColor Green
            
            # Test lock file age
            $lockAge = (Get-Date) - (Get-Item $lockFile).LastWriteTime
            Write-Host "✓ Lock file age: $([Math]::Round($lockAge.TotalSeconds, 2)) seconds" -ForegroundColor Green
            
            # Clean up lock file
            Remove-Item -Path $lockFile -Force
            Write-Host "✓ Lock file cleaned up" -ForegroundColor Green
            
            $lockTest.status = "passed"
            $lockTest.result = "Lock file functionality working correctly"
        } else {
            $lockTest.status = "failed"
            $lockTest.error = "Lock file not created"
        }
    } catch {
        $lockTest.status = "failed"
        $lockTest.error = "Lock file test failed: $($_.Exception.Message)"
    }
    
    $testResults.tests_run += $lockTest
}

# Calculate summary
$passedTests = ($testResults.tests_run | Where-Object { $_.status -eq "passed" }).Count
$failedTests = ($testResults.tests_run | Where-Object { $_.status -eq "failed" }).Count
$totalTests = $testResults.tests_run.Count

$testResults.summary = @{
    total_tests = $totalTests
    passed_tests = $passedTests
    failed_tests = $failedTests
    success_rate = if ($totalTests -gt 0) { [Math]::Round(($passedTests / $totalTests) * 100, 1) } else { 0 }
}

$testResults.end_time = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")

# Save test results
$reportFile = "artifacts/file-storage-test-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
$testResults | ConvertTo-Json -Depth 4 | Set-Content -Path $reportFile -Encoding UTF8

# Display summary
Write-Host "`n=== File Storage Test Summary ===" -ForegroundColor Green
Write-Host "Total tests: $totalTests" -ForegroundColor White
Write-Host "Passed: $passedTests" -ForegroundColor Green
Write-Host "Failed: $failedTests" -ForegroundColor Red
Write-Host "Success rate: $($testResults.summary.success_rate)%" -ForegroundColor $(if ($testResults.summary.success_rate -eq 100) { "Green" } elseif ($testResults.summary.success_rate -ge 80) { "Yellow" } else { "Red" })

Write-Host "`nFile Storage Features Tested:" -ForegroundColor Cyan
Write-Host "1. Write Permissions: File storage directory writable" -ForegroundColor White
Write-Host "2. Queue Persistence: Queue files can be created and accessed" -ForegroundColor White
Write-Host "3. Lock Files: Lock file creation and cleanup" -ForegroundColor White

Write-Host "`nVerification steps:" -ForegroundColor Cyan
Write-Host "1. Run verify-integration.ps1 to check file storage" -ForegroundColor White
Write-Host "2. Check otelcol-storage directory exists and is writable" -ForegroundColor White
Write-Host "3. Verify queue persistence files are created" -ForegroundColor White
Write-Host "4. Monitor for stale lock files" -ForegroundColor White

Write-Host "`nTest report saved to: $reportFile" -ForegroundColor Blue
Write-Host "`nFile storage testing completed!" -ForegroundColor Green
