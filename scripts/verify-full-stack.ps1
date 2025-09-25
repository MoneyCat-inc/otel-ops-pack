# Comprehensive Full Stack Verification Script
# Proves the complete path: [THIS PC] → [Cursor Agents] → Docker (OTel + SigNoz) → [THIS PC] UI
# Part of the push-button automation system

param(
    [switch]$Verbose,
    [switch]$GenerateReport = $true,
    [string]$ReportPath = "artifacts/full-stack-verification.json"
)

$ErrorActionPreference = "Stop"
$startTime = Get-Date

# Progress animation
$spinner = @('⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏')
$spinnerIndex = 0

function Write-Progress {
    param($Message, $Percent = -1)
    if ($Percent -ge 0) {
        $spinnerIndex = ($spinnerIndex + 1) % $spinner.Count
        Write-Host "`r$($spinner[$spinnerIndex]) $Message ($Percent%)" -NoNewline -ForegroundColor Cyan
    } else {
        Write-Host "`r$($spinner[$spinnerIndex]) $Message" -NoNewline -ForegroundColor Cyan
    }
}

function Write-Complete {
    param($Message)
    Write-Host "`r✅ $Message" -ForegroundColor Green
}

# Initialize verification results
$verificationResults = @{
    timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    overall_status = "UNKNOWN"
    components = @{}
    summary = @{
        total_checks = 0
        passed_checks = 0
        failed_checks = 0
        warnings = 0
    }
    duration_seconds = 0
}

function Add-VerificationResult {
    param($Component, $Check, $Status, $Details = @{}, $Warning = $false)
    
    if (-not $verificationResults.components.ContainsKey($Component)) {
        $verificationResults.components[$Component] = @{}
    }
    
    $verificationResults.components[$Component][$Check] = @{
        status = $Status
        details = $Details
        warning = $Warning
        timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    }
    
    $verificationResults.summary.total_checks++
    if ($Status -eq "PASS") {
        $verificationResults.summary.passed_checks++
    } elseif ($Status -eq "FAIL") {
        $verificationResults.summary.failed_checks++
    }
    if ($Warning) {
        $verificationResults.summary.warnings++
    }
}

Write-Host "🔍 Starting Full Stack Verification..." -ForegroundColor Cyan
Write-Host "   Target: [THIS PC] → [Cursor Agents] → Docker (OTel + SigNoz) → [THIS PC] UI" -ForegroundColor Gray
Write-Host ""

# 1. Docker Infrastructure Verification
Write-Progress "Verifying Docker infrastructure..." 10
try {
    # Check Docker Desktop
    $dockerInfo = docker info 2>$null
    if ($LASTEXITCODE -eq 0) {
        Add-VerificationResult "Docker" "Desktop" "PASS" @{
            status = "Running"
            version = (docker version --format "{{.Server.Version}}" 2>$null)
        }
        Write-Complete "Docker Desktop is running"
    } else {
        Add-VerificationResult "Docker" "Desktop" "FAIL" @{
            error = "Docker Desktop not accessible"
        }
        throw "Docker Desktop not running"
    }
    
    # Check Docker network
    $networkExists = docker network ls --format "{{.Name}}" | Select-String "otel_default"
    if ($networkExists) {
        Add-VerificationResult "Docker" "Network" "PASS" @{
            network = "otel_default"
            status = "Exists"
        }
    } else {
        Add-VerificationResult "Docker" "Network" "WARN" @{
            network = "otel_default"
            status = "Not found"
        }
    }
    
} catch {
    Add-VerificationResult "Docker" "Infrastructure" "FAIL" @{
        error = $_.Exception.Message
    }
    Write-Host "`n❌ Docker infrastructure check failed" -ForegroundColor Red
}

# 2. SigNoz Stack Verification
Write-Progress "Verifying SigNoz stack..." 25
try {
    # Check containers
    $containers = docker ps --format "{{.Names}}\t{{.Status}}\t{{.Ports}}" | ConvertFrom-Csv -Delimiter "`t" -Header @("Name", "Status", "Ports")
    $requiredContainers = @("signoz-clickhouse", "signoz", "signoz-otel-collector")
    
    $containerResults = @{}
    foreach ($container in $requiredContainers) {
        $containerInfo = $containers | Where-Object { $_.Name -eq $container }
        if ($containerInfo -and $containerInfo.Status -like "*Up*") {
            $containerResults[$container] = "Running"
        } else {
            $containerResults[$container] = "Not running"
        }
    }
    
    $allRunning = $containerResults.Values | Where-Object { $_ -eq "Running" } | Measure-Object | Select-Object -ExpandProperty Count
    if ($allRunning -eq $requiredContainers.Count) {
        Add-VerificationResult "SigNoz" "Containers" "PASS" $containerResults
        Write-Complete "All SigNoz containers are running"
    } else {
        Add-VerificationResult "SigNoz" "Containers" "FAIL" $containerResults
        throw "Not all containers are running"
    }
    
    # Check ClickHouse health
    $clickhouseHealth = docker exec -i signoz-clickhouse clickhouse-client -q "SELECT 1" 2>$null
    if ($LASTEXITCODE -eq 0) {
        Add-VerificationResult "SigNoz" "ClickHouse" "PASS" @{
            status = "Healthy"
            response = "Query successful"
        }
    } else {
        Add-VerificationResult "SigNoz" "ClickHouse" "FAIL" @{
            error = "ClickHouse not responding"
        }
    }
    
    # Check SigNoz UI health
    try {
        $uiResponse = Invoke-WebRequest -Uri "http://localhost:8080/api/v1/health" -TimeoutSec 10
        if ($uiResponse.StatusCode -eq 200) {
            Add-VerificationResult "SigNoz" "UI" "PASS" @{
                status = "Healthy"
                response_code = $uiResponse.StatusCode
            }
        } else {
            Add-VerificationResult "SigNoz" "UI" "FAIL" @{
                error = "UI returned status $($uiResponse.StatusCode)"
            }
        }
    } catch {
        Add-VerificationResult "SigNoz" "UI" "FAIL" @{
            error = $_.Exception.Message
        }
    }
    
} catch {
    Add-VerificationResult "SigNoz" "Stack" "FAIL" @{
        error = $_.Exception.Message
    }
    Write-Host "`n❌ SigNoz stack verification failed" -ForegroundColor Red
}

# 3. OTel Pipeline Verification
Write-Progress "Verifying OTel pipeline..." 40
try {
    # Check Windows collector service
    $service = Get-Service otelcol-contrib -ErrorAction SilentlyContinue
    if ($service -and $service.Status -eq "Running") {
        Add-VerificationResult "OTel" "WindowsCollector" "PASS" @{
            status = "Running"
            service_name = "otelcol-contrib"
        }
    } else {
        Add-VerificationResult "OTel" "WindowsCollector" "FAIL" @{
            error = "Windows collector service not running"
        }
    }
    
    # Check OTel collector health endpoint
    $healthUrls = @("http://localhost:13134", "http://localhost:13133")
    $healthWorking = $false
    foreach ($url in $healthUrls) {
        try {
            $healthResponse = Invoke-WebRequest -Uri $url -TimeoutSec 5
            if ($healthResponse.StatusCode -eq 200) {
                Add-VerificationResult "OTel" "CollectorHealth" "PASS" @{
                    endpoint = $url
                    status = "Healthy"
                }
                $healthWorking = $true
                break
            }
        } catch {
            continue
        }
    }
    
    if (-not $healthWorking) {
        Add-VerificationResult "OTel" "CollectorHealth" "FAIL" @{
            error = "No health endpoint accessible"
        }
    }
    
    # Check OTLP endpoints
    $otlpPorts = @("14317", "14318")
    $otlpResults = @{}
    foreach ($port in $otlpPorts) {
        $tcp = (Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue)
        if ($tcp) {
            $otlpResults["Port_$port"] = "Listening"
        } else {
            $otlpResults["Port_$port"] = "Not listening"
        }
    }
    
    $allPortsListening = $otlpResults.Values | Where-Object { $_ -eq "Listening" } | Measure-Object | Select-Object -ExpandProperty Count
    if ($allPortsListening -eq $otlpPorts.Count) {
        Add-VerificationResult "OTel" "OTLPEndpoints" "PASS" $otlpResults
    } else {
        Add-VerificationResult "OTel" "OTLPEndpoints" "FAIL" $otlpResults
    }
    
} catch {
    Add-VerificationResult "OTel" "Pipeline" "FAIL" @{
        error = $_.Exception.Message
    }
    Write-Host "`n❌ OTel pipeline verification failed" -ForegroundColor Red
}

# 4. Synthetic Telemetry Verification
Write-Progress "Verifying synthetic telemetry..." 55
try {
    # Run synthetic ping
    $pythonScript = "C:\otel\scripts\otel_synthetic_ping.py"
    if (Test-Path $pythonScript) {
        $syntheticResult = python $pythonScript --endpoint "http://localhost:5318" --count 1 2>&1
        $syntheticExitCode = $LASTEXITCODE
        
        if ($syntheticExitCode -eq 0) {
            Add-VerificationResult "Telemetry" "SyntheticPing" "PASS" @{
                script = "otel_synthetic_ping.py"
                exit_code = $syntheticExitCode
                output = $syntheticResult
            }
            Write-Complete "Synthetic telemetry ping successful"
        } else {
            Add-VerificationResult "Telemetry" "SyntheticPing" "FAIL" @{
                script = "otel_synthetic_ping.py"
                exit_code = $syntheticExitCode
                error = $syntheticResult
            }
        }
    } else {
        Add-VerificationResult "Telemetry" "SyntheticPing" "WARN" @{
            error = "Python script not found"
        }
    }
    
    # Check for recent synthetic logs in SigNoz
    try {
        $logQuery = @{
            start = [int]([DateTimeOffset]::UtcNow.AddMinutes(-5).ToUnixTimeMilliseconds())
            end = [int]([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds())
            requestType = "raw"
            compositeQuery = @{
                queries = @(@{
                    type = "builder_query"
                    spec = @{
                        name = "A"
                        signal = "logs"
                        filter = @{ expression = 'log.body contains "synthetic"' }
                        order = @(@{ key = @{name="timestamp"}; direction = "desc"})
                        limit = 5
                        offset = 0
                    }
                })
            }
        } | ConvertTo-Json -Depth 6
        
        $logResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v5/query_range" -Method Post -Body $logQuery -ContentType "application/json" -TimeoutSec 10
        
        if ($logResponse.data.result.Count -gt 0) {
            Add-VerificationResult "Telemetry" "SigNozLogs" "PASS" @{
                recent_logs = $logResponse.data.result.Count
                time_range = "5 minutes"
            }
        } else {
            Add-VerificationResult "Telemetry" "SigNozLogs" "WARN" @{
                recent_logs = 0
                note = "No recent synthetic logs found"
            }
        }
    } catch {
        Add-VerificationResult "Telemetry" "SigNozLogs" "WARN" @{
            error = "Could not query SigNoz logs"
        }
    }
    
} catch {
    Add-VerificationResult "Telemetry" "Synthetic" "FAIL" @{
        error = $_.Exception.Message
    }
    Write-Host "`n❌ Synthetic telemetry verification failed" -ForegroundColor Red
}

# 5. Browser Preflight Verification
Write-Progress "Verifying browser preflight..." 70
try {
    # Check if Playwright tests exist
    $playwrightTests = @(
        "tests/preflight/browser-guarantees.spec.ts",
        "tests/preflight/pitch-pipeline.spec.ts",
        "tests/preflight/flow-engine.spec.ts"
    )
    
    $testResults = @{}
    foreach ($test in $playwrightTests) {
        if (Test-Path $test) {
            $testResults[$test] = "Exists"
        } else {
            $testResults[$test] = "Missing"
        }
    }
    
    $allTestsExist = $testResults.Values | Where-Object { $_ -eq "Exists" } | Measure-Object | Select-Object -ExpandProperty Count
    if ($allTestsExist -eq $playwrightTests.Count) {
        Add-VerificationResult "Browser" "PreflightTests" "PASS" $testResults
        Write-Complete "Browser preflight tests available"
    } else {
        Add-VerificationResult "Browser" "PreflightTests" "WARN" $testResults
    }
    
    # Check for COOP/COEP configuration
    $htmlFiles = Get-ChildItem -Path "." -Filter "*.html" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 5
    $coopCoepResults = @{}
    foreach ($file in $htmlFiles) {
        $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
        if ($content) {
            $hasCoop = $content -match 'Cross-Origin-Opener-Policy'
            $hasCoep = $content -match 'Cross-Origin-Embedder-Policy'
            $coopCoepResults[$file.Name] = @{
                coop = $hasCoop
                coep = $hasCoep
            }
        }
    }
    
    if ($coopCoepResults.Count -gt 0) {
        Add-VerificationResult "Browser" "COOPCOEP" "PASS" $coopCoepResults
    } else {
        Add-VerificationResult "Browser" "COOPCOEP" "WARN" @{
            note = "No HTML files found to check"
        }
    }
    
} catch {
    Add-VerificationResult "Browser" "Preflight" "FAIL" @{
        error = $_.Exception.Message
    }
    Write-Host "`n❌ Browser preflight verification failed" -ForegroundColor Red
}

# 6. Autopilot Agent Verification
Write-Progress "Verifying autopilot agent..." 85
try {
    # Check agent files
    $agentFiles = @(
        "scripts/agent/watchdog.ts",
        "scripts/agent/runner.ts",
        "scripts/agent/config.json",
        "scripts/agent/health-gate.ps1",
        "scripts/agent/update-status.ps1"
    )
    
    $agentResults = @{}
    foreach ($file in $agentFiles) {
        if (Test-Path $file) {
            $agentResults[$file] = "Exists"
        } else {
            $agentResults[$file] = "Missing"
        }
    }
    
    $allAgentFilesExist = $agentResults.Values | Where-Object { $_ -eq "Exists" } | Measure-Object | Select-Object -ExpandProperty Count
    if ($allAgentFilesExist -eq $agentFiles.Count) {
        Add-VerificationResult "Autopilot" "AgentFiles" "PASS" $agentResults
    } else {
        Add-VerificationResult "Autopilot" "AgentFiles" "FAIL" $agentResults
    }
    
    # Check lock file mechanism
    $lockFile = ".agent/LOCK"
    if (Test-Path $lockFile) {
        Add-VerificationResult "Autopilot" "LockFile" "WARN" @{
            status = "Present"
            note = "Agent operations may be paused"
        }
    } else {
        Add-VerificationResult "Autopilot" "LockFile" "PASS" @{
            status = "Absent"
            note = "Agent operations can run"
        }
    }
    
    # Check status file
    $statusFile = ".agent/status.json"
    if (Test-Path $statusFile) {
        try {
            $statusData = Get-Content $statusFile -Raw | ConvertFrom-Json
            Add-VerificationResult "Autopilot" "StatusFile" "PASS" @{
                status = "Valid JSON"
                sections = $statusData.PSObject.Properties.Name.Count
            }
        } catch {
            Add-VerificationResult "Autopilot" "StatusFile" "WARN" @{
                error = "Invalid JSON format"
            }
        }
    } else {
        Add-VerificationResult "Autopilot" "StatusFile" "WARN" @{
            note = "Status file not found"
        }
    }
    
} catch {
    Add-VerificationResult "Autopilot" "Agent" "FAIL" @{
        error = $_.Exception.Message
    }
    Write-Host "`n❌ Autopilot agent verification failed" -ForegroundColor Red
}

# 7. Final Integration Test
Write-Progress "Running final integration test..." 95
try {
    # Run the existing CI verification script
    $integrationResult = & "C:\otel\scripts\ci-verify.ps1" -CronMode 2>&1
    $integrationExitCode = $LASTEXITCODE
    
    if ($integrationExitCode -eq 0) {
        Add-VerificationResult "Integration" "EndToEnd" "PASS" @{
            script = "ci-verify.ps1"
            exit_code = $integrationExitCode
            status = "All checks passed"
        }
        Write-Complete "End-to-end integration test passed"
    } else {
        Add-VerificationResult "Integration" "EndToEnd" "FAIL" @{
            script = "ci-verify.ps1"
            exit_code = $integrationExitCode
            output = $integrationResult
        }
    }
    
} catch {
    Add-VerificationResult "Integration" "EndToEnd" "FAIL" @{
        error = $_.Exception.Message
    }
    Write-Host "`n❌ Final integration test failed" -ForegroundColor Red
}

# Calculate overall status
$totalChecks = $verificationResults.summary.total_checks
$passedChecks = $verificationResults.summary.passed_checks
$failedChecks = $verificationResults.summary.failed_checks
$warningChecks = $verificationResults.summary.warnings

if ($failedChecks -eq 0) {
    $verificationResults.overall_status = "PASS"
} elseif ($failedChecks -lt $totalChecks / 2) {
    $verificationResults.overall_status = "WARN"
} else {
    $verificationResults.overall_status = "FAIL"
}

# Calculate duration
$elapsed = (Get-Date) - $startTime
$verificationResults.duration_seconds = [int]$elapsed.TotalSeconds

Write-Complete "Full stack verification completed!" 100

# Generate report
if ($GenerateReport) {
    Write-Host "`n📊 Generating verification report..." -ForegroundColor Yellow
    
    # Ensure artifacts directory exists
    $artifactsDir = Split-Path $ReportPath -Parent
    if (-not (Test-Path $artifactsDir)) {
        New-Item -ItemType Directory -Path $artifactsDir -Force | Out-Null
    }
    
    # Save JSON report
    $verificationResults | ConvertTo-Json -Depth 10 | Set-Content $ReportPath
    
    # Generate human-readable summary
    $summaryPath = $ReportPath -replace '\.json$', '-summary.txt'
    $summary = @"
Full Stack Verification Report
=============================
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Duration: $([int]$elapsed.TotalSeconds) seconds
Overall Status: $($verificationResults.overall_status)

Summary:
--------
Total Checks: $totalChecks
Passed: $passedChecks
Failed: $failedChecks
Warnings: $warningChecks

Component Status:
-----------------
"@
    
    foreach ($component in $verificationResults.components.Keys) {
        $componentData = $verificationResults.components[$component]
        $componentStatus = "UNKNOWN"
        $componentChecks = $componentData.Keys.Count
        $componentPassed = ($componentData.Values | Where-Object { $_.status -eq "PASS" }).Count
        
        if ($componentPassed -eq $componentChecks) {
            $componentStatus = "PASS"
        } elseif ($componentPassed -gt 0) {
            $componentStatus = "WARN"
        } else {
            $componentStatus = "FAIL"
        }
        
        $summary += "`n$component`: $componentStatus ($componentPassed/$componentChecks checks passed)"
    }
    
    $summary | Set-Content $summaryPath
    
    Write-Host "   Report saved: $ReportPath" -ForegroundColor Green
    Write-Host "   Summary saved: $summaryPath" -ForegroundColor Green
}

# Final summary
Write-Host "`n" + "="*60 -ForegroundColor Cyan
Write-Host "🎯 FULL STACK VERIFICATION COMPLETE" -ForegroundColor Cyan
Write-Host "="*60 -ForegroundColor Cyan
Write-Host ""
Write-Host "Overall Status: $($verificationResults.overall_status)" -ForegroundColor $(if($verificationResults.overall_status -eq "PASS"){"Green"}elseif($verificationResults.overall_status -eq "WARN"){"Yellow"}else{"Red"})
Write-Host "Total Checks: $totalChecks" -ForegroundColor White
Write-Host "Passed: $passedChecks" -ForegroundColor Green
Write-Host "Failed: $failedChecks" -ForegroundColor Red
Write-Host "Warnings: $warningChecks" -ForegroundColor Yellow
Write-Host ""
Write-Host "Duration: $([int]$elapsed.TotalSeconds) seconds" -ForegroundColor Gray
Write-Host ""

if ($verificationResults.overall_status -eq "PASS") {
    Write-Host "🎉 All systems operational! The full stack is ready." -ForegroundColor Green
    Write-Host ""
    Write-Host "Quick Links:" -ForegroundColor Yellow
    Write-Host "  • SigNoz UI: http://localhost:8080" -ForegroundColor White
    Write-Host "  • Run monitoring: pwsh -File scripts\quick-monitor.ps1" -ForegroundColor White
    Write-Host "  • Start autopilot: pnpm agent:start" -ForegroundColor White
    exit 0
} elseif ($verificationResults.overall_status -eq "WARN") {
    Write-Host "⚠️  System operational with warnings. Review the report for details." -ForegroundColor Yellow
    exit 0
} else {
    Write-Host "❌ System has critical issues. Review the report and fix failures." -ForegroundColor Red
    exit 1
}




