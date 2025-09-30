# Nightly Queue Steward Diagnostics with Canary Integration
# Purpose: Automated nightly collection of Queue Steward diagnostics including canary test
# Usage: Run via scheduled task or cron job for proactive monitoring

param(
    [string]$OutputDir = "artifacts",
    [int]$HealthLogLines = 100,
    [int]$RetentionDays = 7,
    [switch]$CleanOldArtifacts = $true,
    [switch]$Verbose = $false
)

# Create output directory if it doesn't exist
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

# Generate timestamp for file naming
$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$timestampIso = Get-Date -Format 'yyyy-MM-ddTHH:mm:ss.fffZ'

Write-Host "Nightly Queue Steward Diagnostics Collection" -ForegroundColor Cyan
Write-Host "Timestamp: $timestampIso" -ForegroundColor Gray
Write-Host "Output Directory: $OutputDir" -ForegroundColor Gray
Write-Host "Retention: $RetentionDays days" -ForegroundColor Gray
Write-Host ""

# Initialize nightly diagnostic summary
$nightlyDiagnostics = @{
    timestamp = $timestampIso
    collection_type = "nightly_with_canary"
    collection_info = @{
        script_version = "1.0"
        output_dir = $OutputDir
        health_log_lines = $HealthLogLines
        retention_days = $RetentionDays
        canary_test_run = $true
    }
    results = @{}
    summary = @{}
    retention = @{}
}

try {
    # Run comprehensive diagnostics with canary test
    Write-Host "Running comprehensive diagnostics with canary test..." -ForegroundColor Yellow
    
    $diagnosticsResult = & pwsh -File "scripts/collect-queue-diagnostics.ps1" -OutputDir $OutputDir -HealthLogLines $HealthLogLines -IncludeCanaryTest
    
    $nightlyDiagnostics.results.diagnostics_collection = @{
        exit_code = $LASTEXITCODE
        success = $LASTEXITCODE -eq 0
        timestamp = $timestampIso
    }
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   Diagnostics collection: HEALTHY" -ForegroundColor Green
    }
    elseif ($LASTEXITCODE -eq 1) {
        Write-Host "   Diagnostics collection: DEGRADED" -ForegroundColor Yellow
    }
    elseif ($LASTEXITCODE -eq 2) {
        Write-Host "   Diagnostics collection: CRITICAL" -ForegroundColor Red
    }
    else {
        Write-Host "   Diagnostics collection: SCRIPT ERROR (exit code $LASTEXITCODE)" -ForegroundColor Red
    }

    # Load the diagnostics summary for additional analysis
    $diagnosticsSummaryFile = Join-Path $OutputDir "diagnostics-summary-$timestamp.json"
    if (Test-Path $diagnosticsSummaryFile) {
        try {
            $diagnosticsSummary = Get-Content $diagnosticsSummaryFile | ConvertFrom-Json
            $nightlyDiagnostics.results.detailed_summary = $diagnosticsSummary.summary
            
            # Analyze trends (compare with previous night if available)
            $previousNightly = Get-ChildItem -Path $OutputDir | 
                               Where-Object { $_.Name -match '^nightly-diagnostics-summary-\d{8}-\d{6}\.json$' } |
                               Sort-Object LastWriteTime -Descending | 
                               Select-Object -Skip 1 -First 1
            
            if ($previousNightly) {
                try {
                    $previousSummary = Get-Content $previousNightly.FullName | ConvertFrom-Json
                    $nightlyDiagnostics.results.trend_analysis = @{
                        previous_timestamp = $previousSummary.timestamp
                        status_change = $diagnosticsSummary.summary.overall_status -ne $previousSummary.summary.overall_status
                        previous_status = $previousSummary.summary.overall_status
                        current_status = $diagnosticsSummary.summary.overall_status
                    }
                    Write-Host "   Trend analysis: Previous status was $($previousSummary.summary.overall_status)" -ForegroundColor Gray
                }
                catch {
                    Write-Host "   Trend analysis: Failed to parse previous summary" -ForegroundColor Yellow
                }
            }
            else {
                Write-Host "   Trend analysis: No previous nightly run found for comparison" -ForegroundColor Gray
            }
        }
        catch {
            Write-Host "   Failed to load diagnostics summary: $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    # Clean up old artifacts if requested
    if ($CleanOldArtifacts) {
        Write-Host "Cleaning up old artifacts (older than $RetentionDays days)..." -ForegroundColor Yellow
        
        $cutoffDate = (Get-Date).AddDays(-$RetentionDays)
        $oldArtifacts = Get-ChildItem -Path $OutputDir | 
                       Where-Object { ($_.Name -match '-\d{8}-\d{6}-' -and ($_.Extension -eq '.txt' -or $_.Extension -eq '.log' -or $_.Extension -eq '.json')) -and $_.LastWriteTime -lt $cutoffDate }
        
        $cleanedCount = 0
        foreach ($artifact in $oldArtifacts) {
            try {
                Remove-Item $artifact.FullName -Force
                $cleanedCount++
            }
            catch {
                Write-Host "   Failed to remove $($artifact.Name): $($_.Exception.Message)" -ForegroundColor Red
            }
        }
        
        $nightlyDiagnostics.retention = @{
            cleanup_performed = $true
            retention_days = $RetentionDays
            artifacts_removed = $cleanedCount
            cutoff_date = $cutoffDate.ToString("yyyy-MM-dd")
        }
        
        Write-Host "   Removed $cleanedCount old artifacts" -ForegroundColor Green
    }
    else {
        $nightlyDiagnostics.retention = @{
            cleanup_performed = $false
            retention_days = $RetentionDays
        }
        Write-Host "   Artifact cleanup skipped" -ForegroundColor Gray
    }

    # Generate nightly summary
    $nightlyDiagnostics.summary = @{
        collection_completed = $true
        diagnostics_exit_code = $LASTEXITCODE
        overall_health = switch ($LASTEXITCODE) {
            0 { "HEALTHY" }
            1 { "DEGRADED" }
            2 { "CRITICAL" }
            default { "SCRIPT_ERROR" }
        }
        canary_included = $true
        artifacts_cleaned = if ($CleanOldArtifacts) { $cleanedCount } else { 0 }
        timestamp = $timestampIso
    }

    # Save nightly diagnostic summary
    $nightlySummaryFile = Join-Path $OutputDir "nightly-diagnostics-summary-$timestamp.json"
    $nightlyDiagnostics | ConvertTo-Json -Depth 4 | Out-File -FilePath $nightlySummaryFile -Encoding UTF8

    # Display Summary
    Write-Host ""
    Write-Host "Nightly Diagnostics Summary" -ForegroundColor Cyan
    Write-Host "===========================" -ForegroundColor Cyan
    Write-Host "Collection Status: $(if ($LASTEXITCODE -eq 0) { 'HEALTHY' } elseif ($LASTEXITCODE -eq 1) { 'DEGRADED' } elseif ($LASTEXITCODE -eq 2) { 'CRITICAL' } else { 'SCRIPT_ERROR' })" -ForegroundColor $(if ($LASTEXITCODE -eq 0) { 'Green' } elseif ($LASTEXITCODE -eq 1) { 'Yellow' } else { 'Red' })
    Write-Host "Canary Test: INCLUDED" -ForegroundColor Green
    Write-Host "Artifact Cleanup: $(if ($CleanOldArtifacts) { "$cleanedCount files removed" } else { 'SKIPPED' })" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Summary File: $nightlySummaryFile" -ForegroundColor Cyan

    # Log to system event log for monitoring
    try {
        $eventMessage = "Queue Steward nightly diagnostics completed. Status: $($nightlyDiagnostics.summary.overall_health). Exit code: $LASTEXITCODE"
        Write-EventLog -LogName Application -Source "Queue Steward" -EventId 1001 -EntryType Information -Message $eventMessage -ErrorAction SilentlyContinue
        Write-Host "   Logged to Windows Event Log" -ForegroundColor Gray
    }
    catch {
        Write-Host "   Failed to log to Event Log: $($_.Exception.Message)" -ForegroundColor Yellow
    }

    # Return the same exit code as the diagnostics script
    exit $LASTEXITCODE
}
catch {
    Write-Host "Critical error during nightly diagnostics: $($_.Exception.Message)" -ForegroundColor Red
    
    $nightlyDiagnostics.summary = @{
        collection_completed = $false
        error = $_.Exception.Message
        timestamp = $timestampIso
    }
    
    $nightlySummaryFile = Join-Path $OutputDir "nightly-diagnostics-summary-$timestamp.json"
    $nightlyDiagnostics | ConvertTo-Json -Depth 4 | Out-File -FilePath $nightlySummaryFile -Encoding UTF8
    
    exit 3
}
