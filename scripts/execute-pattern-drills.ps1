#Requires -Version 7.0

<#
.SYNOPSIS
    Execute comprehensive pattern drills using the canary pattern library

.DESCRIPTION
    This script executes realistic pattern drills using predefined log patterns
    from the canary pattern library. It simulates real-world scenarios and
    tests the observability pipeline's ability to handle various log patterns.

.PARAMETER Scenario
    Scenario to execute: 'all', 'web-application', 'microservices', 'security-incident', 
    'performance-degradation', 'business-transaction', 'mixed-workload'

.PARAMETER Duration
    Duration of the scenario in minutes (default: 5)

.PARAMETER Intensity
    Intensity level: 'low', 'medium', 'high' (default: medium)

.PARAMETER IncludeOTLP
    Include OTLP trace and log generation (default: true)

.PARAMETER VerifyResults
    Verify results in SigNoz after execution (default: true)

.EXAMPLE
    .\execute-pattern-drills.ps1 -Scenario "web-application" -Duration 10
    .\execute-pattern-drills.ps1 -Scenario "all" -Intensity "high" -Duration 15
#>

param(
    [ValidateSet("all", "web-application", "microservices", "security-incident", "performance-degradation", "business-transaction", "mixed-workload")]
    [string]$Scenario = "all",
    [int]$Duration = 5,
    [ValidateSet("low", "medium", "high")]
    [string]$Intensity = "medium",
    [switch]$IncludeOTLP = $true,
    [switch]$VerifyResults = $true
)

# Import pattern library
$PatternLibraryPath = Join-Path $PSScriptRoot "canary-pattern-library.ps1"
if (Test-Path $PatternLibraryPath) {
    . $PatternLibraryPath
} else {
    Write-Error "Pattern library not found at: $PatternLibraryPath"
    exit 1
}

# Color functions for output
function Write-Success { param($Message) Write-Host "✅ $Message" -ForegroundColor Green }
function Write-Warning { param($Message) Write-Host "⚠️  $Message" -ForegroundColor Yellow }
function Write-Error { param($Message) Write-Host "❌ $Message" -ForegroundColor Red }
function Write-Info { param($Message) Write-Host "ℹ️  $Message" -ForegroundColor Cyan }
function Write-Scenario { param($Message) Write-Host "🎭 $Message" -ForegroundColor Magenta }

# Configuration
$LogDir = "C:\logs"
$ArtifactsDir = "artifacts"
$Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$ScenarioId = "scenario-$Timestamp"

# Ensure directories exist
if (-not (Test-Path $LogDir)) { New-Item -Path $LogDir -ItemType Directory -Force | Out-Null }
if (-not (Test-Path $ArtifactsDir)) { New-Item -Path $ArtifactsDir -ItemType Directory -Force | Out-Null }

# Intensity multipliers
$intensityMultipliers = @{
    "low" = 1
    "medium" = 3
    "high" = 5
}
$multiplier = $intensityMultipliers[$Intensity]

Write-Scenario "Starting Pattern Drill Execution - Scenario: $Scenario, Duration: $Duration min, Intensity: $Intensity"

# Scenario execution tracking
$scenarioResults = @{
    timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    scenario = $Scenario
    duration = $Duration
    intensity = $Intensity
    scenarioId = $ScenarioId
    results = @()
}

function Invoke-WebApplicationScenario {
    Write-Scenario "Executing Web Application Scenario"
    
    $logFile = Join-Path $LogDir "web-application-scenario.log"
    $count = 0
    $startTime = Get-Date
    
    # Web application patterns
    $patterns = @(
        @{ Category = "ApplicationLogs"; Subcategory = "WebServer"; PatternName = "AccessLog" },
        @{ Category = "ApplicationLogs"; Subcategory = "WebServer"; PatternName = "ErrorLog" },
        @{ Category = "PerformanceLogs"; Subcategory = "Metrics"; PatternName = "ApplicationMetrics" },
        @{ Category = "PerformanceLogs"; Subcategory = "Profiling"; PatternName = "SlowOperation" }
    )
    
    while ((Get-Date) -lt $startTime.AddMinutes($Duration)) {
        $pattern = $patterns | Get-Random
        $logEntry = Generate-LogEntry -Category $pattern.Category -Subcategory $pattern.Subcategory -PatternName $pattern.PatternName
        
        # Add scenario metadata
        $scenarioData = @{
            timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ"
            level = if ($logEntry -match "ERROR|CRITICAL") { "ERROR" } elseif ($logEntry -match "WARNING") { "WARNING" } else { "INFO" }
            message = $logEntry
            service = "web-application-scenario"
            scenario_id = $ScenarioId
            scenario_type = "web-application"
            pattern_category = $pattern.Category
            pattern_subcategory = $pattern.Subcategory
            pattern_name = $pattern.PatternName
        }
        
        $logLine = $scenarioData | ConvertTo-Json -Compress
        Add-Content -Path $logFile -Value $logLine -Encoding UTF8
        $count++
        
        Start-Sleep -Milliseconds (1000 / $multiplier)
    }
    
    Write-Success "Generated $count web application log entries"
    return @{ type = "web-application"; count = $count; file = $logFile }
}

function Invoke-MicroservicesScenario {
    Write-Scenario "Executing Microservices Scenario"
    
    $logFile = Join-Path $LogDir "microservices-scenario.log"
    $count = 0
    $startTime = Get-Date
    
    # Microservices patterns
    $patterns = @(
        @{ Category = "ApplicationLogs"; Subcategory = "Microservices"; PatternName = "ServiceCall" },
        @{ Category = "ApplicationLogs"; Subcategory = "Microservices"; PatternName = "CircuitBreaker" },
        @{ Category = "ApplicationLogs"; Subcategory = "Database"; PatternName = "QueryLog" },
        @{ Category = "ApplicationLogs"; Subcategory = "Database"; PatternName = "ConnectionLog" }
    )
    
    while ((Get-Date) -lt $startTime.AddMinutes($Duration)) {
        $pattern = $patterns | Get-Random
        $logEntry = Generate-LogEntry -Category $pattern.Category -Subcategory $pattern.Subcategory -PatternName $pattern.PatternName
        
        $scenarioData = @{
            timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ"
            level = if ($logEntry -match "ERROR|CRITICAL") { "ERROR" } elseif ($logEntry -match "WARNING") { "WARNING" } else { "INFO" }
            message = $logEntry
            service = "microservices-scenario"
            scenario_id = $ScenarioId
            scenario_type = "microservices"
            pattern_category = $pattern.Category
            pattern_subcategory = $pattern.Subcategory
            pattern_name = $pattern.PatternName
        }
        
        $logLine = $scenarioData | ConvertTo-Json -Compress
        Add-Content -Path $logFile -Value $logLine -Encoding UTF8
        $count++
        
        Start-Sleep -Milliseconds (800 / $multiplier)
    }
    
    Write-Success "Generated $count microservices log entries"
    return @{ type = "microservices"; count = $count; file = $logFile }
}

function Invoke-SecurityIncidentScenario {
    Write-Scenario "Executing Security Incident Scenario"
    
    $logFile = Join-Path $LogDir "security-incident-scenario.log"
    $count = 0
    $startTime = Get-Date
    
    # Security patterns
    $patterns = @(
        @{ Category = "SecurityLogs"; Subcategory = "Authentication"; PatternName = "LoginAttempt" },
        @{ Category = "SecurityLogs"; Subcategory = "Authentication"; PatternName = "Authorization" },
        @{ Category = "SecurityLogs"; Subcategory = "IntrusionDetection"; PatternName = "SuspiciousActivity" }
    )
    
    while ((Get-Date) -lt $startTime.AddMinutes($Duration)) {
        $pattern = $patterns | Get-Random
        $logEntry = Generate-LogEntry -Category $pattern.Category -Subcategory $pattern.Subcategory -PatternName $pattern.PatternName
        
        $scenarioData = @{
            timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ"
            level = if ($logEntry -match "CRITICAL") { "CRITICAL" } elseif ($logEntry -match "WARNING") { "WARNING" } else { "INFO" }
            message = $logEntry
            service = "security-incident-scenario"
            scenario_id = $ScenarioId
            scenario_type = "security-incident"
            pattern_category = $pattern.Category
            pattern_subcategory = $pattern.Subcategory
            pattern_name = $pattern.PatternName
            security_event = $true
        }
        
        $logLine = $scenarioData | ConvertTo-Json -Compress
        Add-Content -Path $logFile -Value $logLine -Encoding UTF8
        $count++
        
        Start-Sleep -Milliseconds (1200 / $multiplier)
    }
    
    Write-Success "Generated $count security incident log entries"
    return @{ type = "security-incident"; count = $count; file = $logFile }
}

function Invoke-PerformanceDegradationScenario {
    Write-Scenario "Executing Performance Degradation Scenario"
    
    $logFile = Join-Path $LogDir "performance-degradation-scenario.log"
    $count = 0
    $startTime = Get-Date
    
    # Performance patterns with degradation simulation
    $patterns = @(
        @{ Category = "PerformanceLogs"; Subcategory = "Metrics"; PatternName = "SystemMetrics" },
        @{ Category = "PerformanceLogs"; Subcategory = "Metrics"; PatternName = "ApplicationMetrics" },
        @{ Category = "PerformanceLogs"; Subcategory = "Profiling"; PatternName = "SlowOperation" }
    )
    
    while ((Get-Date) -lt $startTime.AddMinutes($Duration)) {
        $pattern = $patterns | Get-Random
        
        # Simulate performance degradation over time
        $elapsedMinutes = ((Get-Date) - $startTime).TotalMinutes
        $degradationFactor = 1 + ($elapsedMinutes / $Duration) * 2  # Increase degradation over time
        
        $customValues = @{}
        if ($pattern.PatternName -eq "SystemMetrics") {
            $customValues["{cpu}"] = [Math]::Min(95, 30 + ($elapsedMinutes * 10))
            $customValues["{memory}"] = [Math]::Min(95, 40 + ($elapsedMinutes * 8))
            $customValues["{disk}"] = [Math]::Min(90, 20 + ($elapsedMinutes * 5))
        } elseif ($pattern.PatternName -eq "ApplicationMetrics") {
            $customValues["{response_time}"] = [Math]::Min(5000, 50 + ($elapsedMinutes * 200))
            $customValues["{errors}"] = [Math]::Min(100, 2 + ($elapsedMinutes * 5))
        } elseif ($pattern.PatternName -eq "SlowOperation") {
            $customValues["{duration}"] = [Math]::Min(10000, 100 + ($elapsedMinutes * 500))
        }
        
        $logEntry = Generate-LogEntry -Category $pattern.Category -Subcategory $pattern.Subcategory -PatternName $pattern.PatternName -CustomValues $customValues
        
        $scenarioData = @{
            timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ"
            level = if ($logEntry -match "CRITICAL") { "CRITICAL" } elseif ($logEntry -match "WARNING") { "WARNING" } else { "INFO" }
            message = $logEntry
            service = "performance-degradation-scenario"
            scenario_id = $ScenarioId
            scenario_type = "performance-degradation"
            pattern_category = $pattern.Category
            pattern_subcategory = $pattern.Subcategory
            pattern_name = $pattern.PatternName
            degradation_factor = $degradationFactor
        }
        
        $logLine = $scenarioData | ConvertTo-Json -Compress
        Add-Content -Path $logFile -Value $logLine -Encoding UTF8
        $count++
        
        Start-Sleep -Milliseconds (600 / $multiplier)
    }
    
    Write-Success "Generated $count performance degradation log entries"
    return @{ type = "performance-degradation"; count = $count; file = $logFile }
}

function Invoke-BusinessTransactionScenario {
    Write-Scenario "Executing Business Transaction Scenario"
    
    $logFile = Join-Path $LogDir "business-transaction-scenario.log"
    $count = 0
    $startTime = Get-Date
    
    # Business patterns
    $patterns = @(
        @{ Category = "BusinessLogs"; Subcategory = "Transactions"; PatternName = "Payment" },
        @{ Category = "BusinessLogs"; Subcategory = "Transactions"; PatternName = "Order" },
        @{ Category = "BusinessLogs"; Subcategory = "UserActivity"; PatternName = "UserAction" }
    )
    
    while ((Get-Date) -lt $startTime.AddMinutes($Duration)) {
        $pattern = $patterns | Get-Random
        $logEntry = Generate-LogEntry -Category $pattern.Category -Subcategory $pattern.Subcategory -PatternName $pattern.PatternName
        
        $scenarioData = @{
            timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ"
            level = if ($logEntry -match "ERROR") { "ERROR" } else { "INFO" }
            message = $logEntry
            service = "business-transaction-scenario"
            scenario_id = $ScenarioId
            scenario_type = "business-transaction"
            pattern_category = $pattern.Category
            pattern_subcategory = $pattern.Subcategory
            pattern_name = $pattern.PatternName
            business_event = $true
        }
        
        $logLine = $scenarioData | ConvertTo-Json -Compress
        Add-Content -Path $logFile -Value $logLine -Encoding UTF8
        $count++
        
        Start-Sleep -Milliseconds (1500 / $multiplier)
    }
    
    Write-Success "Generated $count business transaction log entries"
    return @{ type = "business-transaction"; count = $count; file = $logFile }
}

function Invoke-MixedWorkloadScenario {
    Write-Scenario "Executing Mixed Workload Scenario"
    
    $logFile = Join-Path $LogDir "mixed-workload-scenario.log"
    $count = 0
    $startTime = Get-Date
    
    # Mixed patterns from all categories
    $allPatterns = @()
    foreach ($category in $Script:PatternCategories.Keys) {
        foreach ($subcategory in $Script:PatternCategories[$category].Keys) {
            foreach ($patternName in $Script:PatternCategories[$category][$subcategory].Keys) {
                $allPatterns += @{ Category = $category; Subcategory = $subcategory; PatternName = $patternName }
            }
        }
    }
    
    while ((Get-Date) -lt $startTime.AddMinutes($Duration)) {
        $pattern = $allPatterns | Get-Random
        $logEntry = Generate-LogEntry -Category $pattern.Category -Subcategory $pattern.Subcategory -PatternName $pattern.PatternName
        
        $scenarioData = @{
            timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ"
            level = if ($logEntry -match "CRITICAL") { "CRITICAL" } elseif ($logEntry -match "ERROR") { "ERROR" } elseif ($logEntry -match "WARNING") { "WARNING" } else { "INFO" }
            message = $logEntry
            service = "mixed-workload-scenario"
            scenario_id = $ScenarioId
            scenario_type = "mixed-workload"
            pattern_category = $pattern.Category
            pattern_subcategory = $pattern.Subcategory
            pattern_name = $pattern.PatternName
        }
        
        $logLine = $scenarioData | ConvertTo-Json -Compress
        Add-Content -Path $logFile -Value $logLine -Encoding UTF8
        $count++
        
        Start-Sleep -Milliseconds (700 / $multiplier)
    }
    
    Write-Success "Generated $count mixed workload log entries"
    return @{ type = "mixed-workload"; count = $count; file = $logFile }
}

function Invoke-OTLPGeneration {
    param($ScenarioType, $ScenarioId)
    
    if (-not $IncludeOTLP) { return }
    
    Write-Info "Generating OTLP traces and logs for scenario: $ScenarioType"
    
    # Generate OTLP trace
    $tracePayload = @{
        resourceSpans = @(
            @{
                resource = @{
                    attributes = @(
                        @{ key = "service.name"; value = @{ stringValue = "pattern-drill-scenario" } },
                        @{ key = "service.namespace"; value = @{ stringValue = "observability" } },
                        @{ key = "deployment.environment"; value = @{ stringValue = "test" } },
                        @{ key = "scenario.type"; value = @{ stringValue = $ScenarioType } },
                        @{ key = "scenario.id"; value = @{ stringValue = $ScenarioId } }
                    )
                }
                scopeSpans = @(
                    @{
                        spans = @(
                            @{
                                traceId = [System.Guid]::NewGuid().ToString("N")
                                spanId = [System.Guid]::NewGuid().ToString("N").Substring(0, 16)
                                name = "pattern-drill-execution"
                                kind = 1
                                startTimeUnixNano = ([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() * 1000000)
                                endTimeUnixNano = (([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() + 100) * 1000000)
                                attributes = @(
                                    @{ key = "scenario.type"; value = @{ stringValue = $ScenarioType } },
                                    @{ key = "scenario.id"; value = @{ stringValue = $ScenarioId } },
                                    @{ key = "test.type"; value = @{ stringValue = "pattern-drill" } }
                                )
                            }
                        )
                    }
                )
            }
        )
    } | ConvertTo-Json -Depth 10
    
    # Generate OTLP log
    $logPayload = @{
        resourceLogs = @(
            @{
                resource = @{
                    attributes = @(
                        @{ key = "service.name"; value = @{ stringValue = "pattern-drill-scenario" } },
                        @{ key = "scenario.type"; value = @{ stringValue = $ScenarioType } },
                        @{ key = "scenario.id"; value = @{ stringValue = $ScenarioId } }
                    )
                }
                scopeLogs = @(
                    @{
                        logRecords = @(
                            @{
                                timeUnixNano = ([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() * 1000000)
                                severityNumber = 17
                                severityText = "INFO"
                                body = @{ stringValue = "Pattern drill scenario execution: $ScenarioType" }
                                attributes = @(
                                    @{ key = "scenario.type"; value = @{ stringValue = $ScenarioType } },
                                    @{ key = "scenario.id"; value = @{ stringValue = $ScenarioId } },
                                    @{ key = "test.type"; value = @{ stringValue = "pattern-drill" } }
                                )
                            }
                        )
                    }
                )
            }
        )
    } | ConvertTo-Json -Depth 10
    
    # Send OTLP data
    $endpoints = @(
        "http://localhost:5318/v1/traces",
        "http://localhost:5318/v1/logs"
    )
    
    try {
        $traceResponse = Invoke-RestMethod -Uri $endpoints[0] -Method Post -Body $tracePayload -ContentType "application/json" -TimeoutSec 5
        Write-Success "OTLP trace sent successfully"
    } catch {
        Write-Warning "Failed to send OTLP trace: $($_.Exception.Message)"
    }
    
    try {
        $logResponse = Invoke-RestMethod -Uri $endpoints[1] -Method Post -Body $logPayload -ContentType "application/json" -TimeoutSec 5
        Write-Success "OTLP log sent successfully"
    } catch {
        Write-Warning "Failed to send OTLP log: $($_.Exception.Message)"
    }
}

function Invoke-SigNozVerification {
    param($Results)
    
    if (-not $VerifyResults) { return }
    
    Write-Info "Verifying scenario results in SigNoz..."
    
    $verificationQueries = @{
        "web-application" = "message contains 'web-application-scenario'"
        "microservices" = "message contains 'microservices-scenario'"
        "security-incident" = "message contains 'security-incident-scenario'"
        "performance-degradation" = "message contains 'performance-degradation-scenario'"
        "business-transaction" = "message contains 'business-transaction-scenario'"
        "mixed-workload" = "message contains 'mixed-workload-scenario'"
    }
    
    Write-Info "SigNoz Verification Queries:"
    foreach ($result in $Results) {
        if ($verificationQueries.ContainsKey($result.type)) {
            Write-Host "  $($result.type): $($verificationQueries[$result.type])" -ForegroundColor Cyan
        }
    }
    
    Write-Info "Navigate to: http://localhost:8080/logs"
    Write-Info "Use the queries above to verify scenario results"
}

# Execute scenarios based on type
$scenarioFunctions = @{
    "web-application" = { Invoke-WebApplicationScenario }
    "microservices" = { Invoke-MicroservicesScenario }
    "security-incident" = { Invoke-SecurityIncidentScenario }
    "performance-degradation" = { Invoke-PerformanceDegradationScenario }
    "business-transaction" = { Invoke-BusinessTransactionScenario }
    "mixed-workload" = { Invoke-MixedWorkloadScenario }
}

$executedScenarios = @()

if ($Scenario -eq "all") {
    foreach ($scenarioName in $scenarioFunctions.Keys) {
        Write-Info "Executing $scenarioName scenario..."
        $result = & $scenarioFunctions[$scenarioName]
        $executedScenarios += $result
        $scenarioResults.results += $result
        
        # Generate OTLP data for each scenario
        Invoke-OTLPGeneration -ScenarioType $scenarioName -ScenarioId $ScenarioId
        
        Start-Sleep -Seconds 10  # Brief pause between scenarios
    }
} else {
    if ($scenarioFunctions.ContainsKey($Scenario)) {
        Write-Info "Executing $Scenario scenario..."
        $result = & $scenarioFunctions[$Scenario]
        $executedScenarios += $result
        $scenarioResults.results += $result
        
        # Generate OTLP data
        Invoke-OTLPGeneration -ScenarioType $Scenario -ScenarioId $ScenarioId
    } else {
        Write-Error "Unknown scenario: $Scenario"
        exit 1
    }
}

# Generate summary report
$totalLogs = ($executedScenarios | Measure-Object -Property count -Sum).Sum
$scenarioResults.totalLogsGenerated = $totalLogs
$scenarioResults.executedScenarios = $executedScenarios.Count

# Save scenario results
$resultsFile = Join-Path $ArtifactsDir "pattern-drill-scenario-results-$Timestamp.json"
$scenarioResults | ConvertTo-Json -Depth 4 | Out-File -FilePath $resultsFile -Encoding UTF8

# Verify in SigNoz
Invoke-SigNozVerification -Results $executedScenarios

# Summary
Write-Success "Pattern Drill Scenario Execution Completed!"
Write-Info "Total logs generated: $totalLogs"
Write-Info "Scenarios executed: $($executedScenarios.Count)"
Write-Info "Results saved to: $resultsFile"
Write-Info "Log files created in: $LogDir"

# Display verification instructions
Write-Host ""
Write-Host "🔍 Verification Instructions:" -ForegroundColor Yellow
Write-Host "1. Check SigNoz UI: http://localhost:8080/logs" -ForegroundColor White
Write-Host "2. Use scenario-specific queries to verify ingestion" -ForegroundColor White
Write-Host "3. Check log files in: $LogDir" -ForegroundColor White
Write-Host "4. Review scenario results: $resultsFile" -ForegroundColor White
Write-Host "5. Check traces: http://localhost:8080/traces" -ForegroundColor White

exit 0
