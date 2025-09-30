# Queue Steward Diagnostics Collection Script
# Purpose: Automated collection of Queue Steward diagnostic information for troubleshooting and escalation

param(
    [string]$OutputDir = "artifacts",
    [int]$HealthLogLines = 50,
    [switch]$IncludeCanaryTest = $false,
    [switch]$Verbose = $false
)

# Create output directory if it doesn't exist
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

# Generate timestamp for file naming
$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$timestampIso = Get-Date -Format 'yyyy-MM-ddTHH:mm:ss.fffZ'

Write-Host "Queue Steward Diagnostics Collection" -ForegroundColor Cyan
Write-Host "Timestamp: $timestampIso" -ForegroundColor Gray
Write-Host "Output Directory: $OutputDir" -ForegroundColor Gray
Write-Host ""

# Initialize diagnostic summary
$diagnostics = @{
    timestamp = $timestampIso
    collection_info = @{
        script_version = "1.0"
        output_dir = $OutputDir
        health_log_lines = $HealthLogLines
        canary_test_run = $IncludeCanaryTest
    }
    results = @{}
    summary = @{}
}

try {
    # 1. Queue Status Check
    Write-Host "1. Collecting Queue Status..." -ForegroundColor Yellow
    $queueStatusFile = Join-Path $OutputDir "queue-status-$timestamp.txt"
    
    try {
        $queueStatus = & pnpm agent:status 2>&1
        $queueStatus | Out-File -FilePath $queueStatusFile -Encoding UTF8
        
        # Parse key metrics from status output
        $queueDepth = if ($queueStatus -match 'Queue Depth: (\d+)') { [int]$matches[1] } else { $null }
        $runningJobs = if ($queueStatus -match 'Running: (\d+)') { [int]$matches[1] } else { $null }
        $lockPresent = if ($queueStatus -match 'Lock Present: (YES|NO)') { $matches[1] -eq 'YES' } else { $null }
        $shadowMode = if ($queueStatus -match 'Shadow Mode: (ON|OFF)') { $matches[1] -eq 'ON' } else { $null }
        
        $diagnostics.results.queue_status = @{
            file = $queueStatusFile
            success = $true
            metrics = @{
                queue_depth = $queueDepth
                running_jobs = $runningJobs
                lock_present = $lockPresent
                shadow_mode = $shadowMode
            }
        }
        
        Write-Host "   Queue Depth: $queueDepth, Running: $runningJobs, Lock: $lockPresent" -ForegroundColor Green
    }
    catch {
        $diagnostics.results.queue_status = @{
            file = $queueStatusFile
            success = $false
            error = $_.Exception.Message
        }
        Write-Host "   Failed: $($_.Exception.Message)" -ForegroundColor Red
    }

    # 2. Health Log Collection
    Write-Host "2. Collecting Health Logs..." -ForegroundColor Yellow
    $healthLogFile = Join-Path $OutputDir "queue-health-$timestamp.log"
    
    try {
        if (Test-Path "C:\logs\queue\health.log") {
            Get-Content -Path "C:\logs\queue\health.log" -Tail $HealthLogLines | Out-File -FilePath $healthLogFile -Encoding UTF8
            
            # Parse latest health log entry
            $latestHealth = Get-Content -Path "C:\logs\queue\health.log" -Tail 1 | ConvertFrom-Json -ErrorAction SilentlyContinue
            $lastUpdate = if ($latestHealth.timestamp) { $latestHealth.timestamp } else { $null }
            $killSwitch = if ($latestHealth.killSwitch) { $latestHealth.killSwitch } else { $null }
            
            $diagnostics.results.health_log = @{
                file = $healthLogFile
                success = $true
                metrics = @{
                    last_update = $lastUpdate
                    kill_switch = $killSwitch
                    lines_collected = $HealthLogLines
                }
            }
            
            Write-Host "   Latest Update: $lastUpdate, Kill Switch: $killSwitch" -ForegroundColor Green
        }
        else {
            $diagnostics.results.health_log = @{
                file = $healthLogFile
                success = $false
                error = "Health log file not found at C:\logs\queue\health.log"
            }
            Write-Host "   Health log file not found" -ForegroundColor Red
        }
    }
    catch {
        $diagnostics.results.health_log = @{
            file = $healthLogFile
            success = $false
            error = $_.Exception.Message
        }
        Write-Host "   Failed: $($_.Exception.Message)" -ForegroundColor Red
    }

    # 3. Collector Service Status
    Write-Host "3. Checking Collector Service..." -ForegroundColor Yellow
    $collectorServiceFile = Join-Path $OutputDir "collector-service-$timestamp.txt"
    
    try {
        $collectorService = Get-Service -Name "opentelemetry-collector" -ErrorAction SilentlyContinue
        if ($collectorService) {
            $serviceInfo = @{
                name = $collectorService.Name
                status = $collectorService.Status.ToString()
                start_type = $collectorService.StartType.ToString()
                display_name = $collectorService.DisplayName
            }
            
            $serviceInfo | ConvertTo-Json -Depth 2 | Out-File -FilePath $collectorServiceFile -Encoding UTF8
            
            $diagnostics.results.collector_service = @{
                file = $collectorServiceFile
                success = $true
                status = $collectorService.Status.ToString()
            }
            
            Write-Host "   Status: $($collectorService.Status)" -ForegroundColor Green
        }
        else {
            $diagnostics.results.collector_service = @{
                file = $collectorServiceFile
                success = $false
                error = "OpenTelemetry Collector service not found"
            }
            Write-Host "   Service not found" -ForegroundColor Red
        }
    }
    catch {
        $diagnostics.results.collector_service = @{
            file = $collectorServiceFile
            success = $false
            error = $_.Exception.Message
        }
        Write-Host "   Failed: $($_.Exception.Message)" -ForegroundColor Red
    }

    # 4. SigNoz Health Check
    Write-Host "4. Checking SigNoz Health..." -ForegroundColor Yellow
    $signozHealthFile = Join-Path $OutputDir "signoz-health-$timestamp.txt"
    
    try {
        $signozHealth = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/health" -Method Get -TimeoutSec 10 -ErrorAction Stop
        
        $signozHealth | ConvertTo-Json -Depth 2 | Out-File -FilePath $signozHealthFile -Encoding UTF8
        
        $diagnostics.results.signoz_health = @{
            file = $signozHealthFile
            success = $true
            status = $signozHealth.status
        }
        
        Write-Host "   Status: $($signozHealth.status)" -ForegroundColor Green
    }
    catch {
        $diagnostics.results.signoz_health = @{
            file = $signozHealthFile
            success = $false
            error = $_.Exception.Message
        }
        Write-Host "   Failed: $($_.Exception.Message)" -ForegroundColor Red
    }

    # 5. Optional Canary Test
    if ($IncludeCanaryTest) {
        Write-Host "5. Running Canary Test..." -ForegroundColor Yellow
        $canaryResultFile = Join-Path $OutputDir "canary-result-$timestamp.txt"
        
        try {
            $canaryOutput = & pwsh -File "scripts/canary-test.ps1" 2>&1
            $canaryOutput | Out-File -FilePath $canaryResultFile -Encoding UTF8
            
            $canarySuccess = $canaryOutput -match "== Canary PASSED =="
            
            $diagnostics.results.canary_test = @{
                file = $canaryResultFile
                success = $canarySuccess
                output = $canaryOutput -join "`n"
            }
            
            Write-Host "   Result: $(if ($canarySuccess) { 'PASSED' } else { 'FAILED' })" -ForegroundColor $(if ($canarySuccess) { 'Green' } else { 'Red' })
        }
        catch {
            $diagnostics.results.canary_test = @{
                file = $canaryResultFile
                success = $false
                error = $_.Exception.Message
            }
            Write-Host "   Failed: $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    # 6. Environment Information
    Write-Host "6. Collecting Environment Info..." -ForegroundColor Yellow
    $envInfoFile = Join-Path $OutputDir "environment-info-$timestamp.txt"
    
    try {
        $envInfo = @{
            timestamp = $timestampIso
            machine_name = $env:COMPUTERNAME
            user_name = $env:USERNAME
            powershell_version = $PSVersionTable.PSVersion.ToString()
            working_directory = Get-Location
            environment_variables = @{
                QUEUE_DRIVER = $env:QUEUE_DRIVER
                QUEUE_SHADOW = $env:QUEUE_SHADOW
                QUEUE_ADMISSION_CAP = $env:QUEUE_ADMISSION_CAP
                QUEUE_METRICS = $env:QUEUE_METRICS
            }
        }
        
        $envInfo | ConvertTo-Json -Depth 3 | Out-File -FilePath $envInfoFile -Encoding UTF8
        
        $diagnostics.results.environment_info = @{
            file = $envInfoFile
            success = $true
        }
        
        Write-Host "   Environment info collected" -ForegroundColor Green
    }
    catch {
        $diagnostics.results.environment_info = @{
            file = $envInfoFile
            success = $false
            error = $_.Exception.Message
        }
        Write-Host "   Failed: $($_.Exception.Message)" -ForegroundColor Red
    }

    # Generate Summary
    $successCount = ($diagnostics.results.Values | Where-Object { $_.success -eq $true }).Count
    $totalCount = $diagnostics.results.Count
    
    $diagnostics.summary = @{
        total_checks = $totalCount
        successful_checks = $successCount
        failed_checks = $totalCount - $successCount
        overall_status = if ($successCount -eq $totalCount) { "HEALTHY" } elseif ($successCount -gt $totalCount / 2) { "DEGRADED" } else { "CRITICAL" }
        collection_completed = $true
    }

    # Save diagnostic summary
    $summaryFile = Join-Path $OutputDir "diagnostics-summary-$timestamp.json"
    $diagnostics | ConvertTo-Json -Depth 4 | Out-File -FilePath $summaryFile -Encoding UTF8

    # Display Summary
    Write-Host ""
    Write-Host "Diagnostics Collection Summary" -ForegroundColor Cyan
    Write-Host "==============================" -ForegroundColor Cyan
    Write-Host "Total Checks: $totalCount" -ForegroundColor White
    Write-Host "Successful: $successCount" -ForegroundColor Green
    Write-Host "Failed: $($totalCount - $successCount)" -ForegroundColor Red
    Write-Host "Overall Status: $($diagnostics.summary.overall_status)" -ForegroundColor $(if ($diagnostics.summary.overall_status -eq "HEALTHY") { 'Green' } elseif ($diagnostics.summary.overall_status -eq "DEGRADED") { 'Yellow' } else { 'Red' })
    Write-Host ""
    Write-Host "Files Generated:" -ForegroundColor Gray
    Get-ChildItem -Path $OutputDir -Filter "*$timestamp*" | ForEach-Object {
        Write-Host "  $($_.Name)" -ForegroundColor Gray
    }
    Write-Host ""
    Write-Host "Summary File: $summaryFile" -ForegroundColor Cyan

    # Return exit code based on overall status
    if ($diagnostics.summary.overall_status -eq "CRITICAL") {
        exit 2
    }
    elseif ($diagnostics.summary.overall_status -eq "DEGRADED") {
        exit 1
    }
    else {
        exit 0
    }
}
catch {
    Write-Host "Critical error during diagnostics collection: $($_.Exception.Message)" -ForegroundColor Red
    exit 3
}
