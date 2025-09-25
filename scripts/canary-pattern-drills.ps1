#Requires -Version 7.0

<#
.SYNOPSIS
    Comprehensive Canary Log Pattern Drills for Observability Pipeline Testing

.DESCRIPTION
    This script executes various log pattern drills to test the observability pipeline's
    ability to handle different log patterns, formats, and scenarios. It includes
    structured drills for different failure modes, performance patterns, and edge cases.

.PARAMETER DrillType
    Type of drill to execute: 'all', 'error-patterns', 'performance-patterns', 
    'format-variations', 'volume-spikes', 'edge-cases', 'multiline-patterns'

.PARAMETER Duration
    Duration of each drill in seconds (default: 60)

.PARAMETER Intensity
    Intensity level: 'low', 'medium', 'high' (default: medium)

.PARAMETER VerifyInSigNoz
    Verify drill results in SigNoz UI (default: true)

.EXAMPLE
    .\canary-pattern-drills.ps1 -DrillType "all" -Duration 120
    .\canary-pattern-drills.ps1 -DrillType "error-patterns" -Intensity "high"
#>

param(
    [ValidateSet("all", "error-patterns", "performance-patterns", "format-variations", "volume-spikes", "edge-cases", "multiline-patterns")]
    [string]$DrillType = "all",
    [int]$Duration = 60,
    [ValidateSet("low", "medium", "high")]
    [string]$Intensity = "medium",
    [switch]$VerifyInSigNoz = $true
)

# Color functions for output
function Write-Success { param($Message) Write-Host "✅ $Message" -ForegroundColor Green }
function Write-Warning { param($Message) Write-Host "⚠️  $Message" -ForegroundColor Yellow }
function Write-Error { param($Message) Write-Host "❌ $Message" -ForegroundColor Red }
function Write-Info { param($Message) Write-Host "ℹ️  $Message" -ForegroundColor Cyan }
function Write-Drill { param($Message) Write-Host "🧨 $Message" -ForegroundColor Magenta }

# Configuration
$LogDir = "C:\logs"
$ArtifactsDir = "artifacts"
$Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$DrillId = "drill-$Timestamp"

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

Write-Drill "Starting Canary Log Pattern Drills - Type: $DrillType, Duration: $Duration s, Intensity: $Intensity"

# Drill execution tracking
$drillResults = @{
    timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    drillType = $DrillType
    duration = $Duration
    intensity = $Intensity
    drillId = $DrillId
    results = @()
}

function Invoke-ErrorPatternDrill {
    Write-Drill "Executing Error Pattern Drill"
    
    $patterns = @(
        @{
            name = "Application Errors"
            pattern = "ERROR: Application failure in module {module} - {error_code}: {message}"
            fields = @("module", "error_code", "message")
        },
        @{
            name = "Database Connection Errors"
            pattern = "CRITICAL: Database connection failed to {host}:{port} - {error_type}: {details}"
            fields = @("host", "port", "error_type", "details")
        },
        @{
            name = "Authentication Failures"
            pattern = "SECURITY: Authentication failed for user {username} from {ip} - {reason}"
            fields = @("username", "ip", "reason")
        },
        @{
            name = "Resource Exhaustion"
            pattern = "WARNING: Resource {resource_type} exhausted - {current_usage}/{max_capacity} - {action_taken}"
            fields = @("resource_type", "current_usage", "max_capacity", "action_taken")
        }
    )
    
    $logFile = Join-Path $LogDir "error-pattern-drill.log"
    $count = 0
    
    for ($i = 0; $i -lt ($Duration * $multiplier); $i++) {
        $pattern = $patterns[$i % $patterns.Count]
        $timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ"
        
        # Generate realistic error data
        $errorData = @{
            timestamp = $timestamp
            level = if ($pattern.name -match "CRITICAL|SECURITY") { "CRITICAL" } else { "ERROR" }
            message = $pattern.pattern -replace "{module}", "auth-service" -replace "{error_code}", "AUTH_001" -replace "{message}", "Invalid credentials" -replace "{host}", "db-prod-01" -replace "{port}", "5432" -replace "{error_type}", "ConnectionTimeout" -replace "{details}", "Connection timeout after 30s" -replace "{username}", "admin" -replace "{ip}", "192.168.1.100" -replace "{reason}", "Invalid password" -replace "{resource_type}", "memory" -replace "{current_usage}", "95%" -replace "{max_capacity}", "100%" -replace "{action_taken}", "throttling enabled"
            service = "error-pattern-drill"
            drill_id = $DrillId
            drill_type = "error-patterns"
            pattern_name = $pattern.name
            severity = if ($pattern.name -match "CRITICAL|SECURITY") { "critical" } else { "error" }
        }
        
        $logEntry = $errorData | ConvertTo-Json -Compress
        Add-Content -Path $logFile -Value $logEntry -Encoding UTF8
        $count++
        
        Start-Sleep -Milliseconds (1000 / $multiplier)
    }
    
    Write-Success "Generated $count error pattern log entries"
    return @{ type = "error-patterns"; count = $count; file = $logFile }
}

function Invoke-PerformancePatternDrill {
    Write-Drill "Executing Performance Pattern Drill"
    
    $logFile = Join-Path $LogDir "performance-pattern-drill.log"
    $count = 0
    
    for ($i = 0; $i -lt ($Duration * $multiplier); $i++) {
        $timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ"
        
        # Simulate performance metrics with realistic patterns
        $responseTime = Get-Random -Minimum 50 -Maximum 2000
        $cpuUsage = Get-Random -Minimum 10 -Maximum 95
        $memoryUsage = Get-Random -Minimum 20 -Maximum 90
        $diskUsage = Get-Random -Minimum 5 -Maximum 85
        
        $perfData = @{
            timestamp = $timestamp
            level = if ($responseTime -gt 1000 -or $cpuUsage -gt 80) { "WARNING" } else { "INFO" }
            message = "Performance metrics: response_time={response_time}ms, cpu={cpu}%, memory={memory}%, disk={disk}%"
            service = "performance-pattern-drill"
            drill_id = $DrillId
            drill_type = "performance-patterns"
            metrics = @{
                response_time_ms = $responseTime
                cpu_usage_percent = $cpuUsage
                memory_usage_percent = $memoryUsage
                disk_usage_percent = $diskUsage
                throughput_rps = Get-Random -Minimum 100 -Maximum 1000
                error_rate_percent = Get-Random -Minimum 0 -Maximum 5
            }
        }
        
        $logEntry = $perfData | ConvertTo-Json -Compress
        Add-Content -Path $logFile -Value $logEntry -Encoding UTF8
        $count++
        
        Start-Sleep -Milliseconds (500 / $multiplier)
    }
    
    Write-Success "Generated $count performance pattern log entries"
    return @{ type = "performance-patterns"; count = $count; file = $logFile }
}

function Invoke-FormatVariationDrill {
    Write-Drill "Executing Format Variation Drill"
    
    $logFile = Join-Path $LogDir "format-variation-drill.log"
    $count = 0
    
    $formats = @(
        @{
            name = "JSON Structured"
            template = @{
                timestamp = "{timestamp}"
                level = "INFO"
                message = "Structured JSON log entry"
                service = "format-drill"
                drill_id = "{drill_id}"
                structured_data = @{
                    user_id = "12345"
                    session_id = "sess_abc123"
                    action = "login"
                    metadata = @{
                        ip_address = "192.168.1.100"
                        user_agent = "Mozilla/5.0"
                    }
                }
            }
        },
        @{
            name = "Plain Text"
            template = "{timestamp} [INFO] Plain text log entry - service=format-drill drill_id={drill_id} user_id=12345"
        },
        @{
            name = "Key-Value Pairs"
            template = "timestamp={timestamp} level=INFO message='Key-value log entry' service=format-drill drill_id={drill_id} key1=value1 key2=value2"
        },
        @{
            name = "CSV Format"
            template = "{timestamp},INFO,CSV log entry,format-drill,{drill_id},field1,field2,field3"
        }
    )
    
    for ($i = 0; $i -lt ($Duration * $multiplier); $i++) {
        $timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ"
        $format = $formats[$i % $formats.Count]
        
        if ($format.name -eq "JSON Structured") {
            $logData = $format.template.Clone()
            $logData.timestamp = $timestamp
            $logData.drill_id = $DrillId
            $logEntry = $logData | ConvertTo-Json -Depth 3 -Compress
        } else {
            $logEntry = $format.template -replace "{timestamp}", $timestamp -replace "{drill_id}", $DrillId
        }
        
        Add-Content -Path $logFile -Value $logEntry -Encoding UTF8
        $count++
        
        Start-Sleep -Milliseconds (800 / $multiplier)
    }
    
    Write-Success "Generated $count format variation log entries"
    return @{ type = "format-variations"; count = $count; file = $logFile }
}

function Invoke-VolumeSpikeDrill {
    Write-Drill "Executing Volume Spike Drill"
    
    $logFile = Join-Path $LogDir "volume-spike-drill.log"
    $count = 0
    
    # Simulate volume spikes with burst patterns
    $burstPatterns = @(
        @{ duration = 10; rate = 100 },  # High burst
        @{ duration = 20; rate = 20 },   # Normal
        @{ duration = 5; rate = 200 },    # Extreme burst
        @{ duration = 15; rate = 30 },    # Elevated
        @{ duration = 8; rate = 150 }     # Medium burst
    )
    
    foreach ($burst in $burstPatterns) {
        Write-Info "Burst: $($burst.rate) logs/sec for $($burst.duration) seconds"
        
        for ($i = 0; $i -lt $burst.duration; $i++) {
            for ($j = 0; $j -lt $burst.rate; $j++) {
                $timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ"
                
                $spikeData = @{
                    timestamp = $timestamp
                    level = "INFO"
                    message = "Volume spike test log entry #$count"
                    service = "volume-spike-drill"
                    drill_id = $DrillId
                    drill_type = "volume-spikes"
                    burst_id = $burstPatterns.IndexOf($burst)
                    log_number = $count
                    burst_rate = $burst.rate
                }
                
                $logEntry = $spikeData | ConvertTo-Json -Compress
                Add-Content -Path $logFile -Value $logEntry -Encoding UTF8
                $count++
            }
            Start-Sleep -Seconds 1
        }
        
        Start-Sleep -Seconds 2  # Brief pause between bursts
    }
    
    Write-Success "Generated $count volume spike log entries"
    return @{ type = "volume-spikes"; count = $count; file = $logFile }
}

function Invoke-EdgeCaseDrill {
    Write-Drill "Executing Edge Case Drill"
    
    $logFile = Join-Path $LogDir "edge-case-drill.log"
    $count = 0
    
    $edgeCases = @(
        @{
            name = "Unicode Characters"
            message = "Unicode test: 你好世界 🌍 émojis 🚀 special chars: àáâãäåæçèéêë"
        },
        @{
            name = "Very Long Message"
            message = "Very long message: " + ("x" * 1000) + " - This is a test of very long log messages that might cause parsing issues or truncation"
        },
        @{
            name = "Empty Fields"
            message = ""
        },
        @{
            name = "Special Characters"
            message = "Special chars: \n\r\t`"`'`~!@#$%^&*()_+-=[]{}|;':`",./<>?"
        },
        @{
            name = "Nested JSON"
            message = '{"nested":{"deep":{"very":{"deep":{"data":"value"}}}}}'
        },
        @{
            name = "SQL Injection Attempt"
            message = "SELECT * FROM users WHERE id = 1; DROP TABLE users; --"
        },
        @{
            name = "XML Content"
            message = "<xml><data><value>test</value></data></xml>"
        }
    )
    
    for ($i = 0; $i -lt ($Duration * $multiplier); $i++) {
        $timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ"
        $edgeCase = $edgeCases[$i % $edgeCases.Count]
        
        $edgeData = @{
            timestamp = $timestamp
            level = "INFO"
            message = $edgeCase.message
            service = "edge-case-drill"
            drill_id = $DrillId
            drill_type = "edge-cases"
            edge_case_name = $edgeCase.name
            test_id = $i
        }
        
        $logEntry = $edgeData | ConvertTo-Json -Compress
        Add-Content -Path $logFile -Value $logEntry -Encoding UTF8
        $count++
        
        Start-Sleep -Milliseconds (1200 / $multiplier)
    }
    
    Write-Success "Generated $count edge case log entries"
    return @{ type = "edge-cases"; count = $count; file = $logFile }
}

function Invoke-MultilinePatternDrill {
    Write-Drill "Executing Multiline Pattern Drill"
    
    $logFile = Join-Path $LogDir "multiline-pattern-drill.log"
    $count = 0
    
    $multilinePatterns = @(
        @{
            name = "Stack Trace"
            content = @"
Exception: System.NullReferenceException
   at MyApp.Services.UserService.GetUser(Int32 userId)
   at MyApp.Controllers.UserController.GetUser(Int32 id)
   at System.Web.Mvc.ControllerActionInvoker.InvokeActionMethod
   at System.Web.Mvc.ControllerActionInvoker.InvokeAction
"@
        },
        @{
            name = "JSON Multiline"
            content = @"
{
  "timestamp": "{timestamp}",
  "level": "ERROR",
  "message": "Multiline JSON log entry",
  "service": "multiline-drill",
  "drill_id": "{drill_id}",
  "details": {
    "error": "Something went wrong",
    "stack_trace": [
      "line 1 of stack",
      "line 2 of stack",
      "line 3 of stack"
    ]
  }
}
"@
        },
        @{
            name = "Log with Continuation"
            content = @"
2024-01-01 10:00:00 [INFO] Starting transaction processing
    -> Processing user: 12345
    -> Validating permissions
    -> Executing query: SELECT * FROM users
    -> Transaction completed successfully
"@
        },
        @{
            name = "XML Multiline"
            content = @"
<log>
  <timestamp>{timestamp}</timestamp>
  <level>INFO</level>
  <message>Multiline XML log entry</message>
  <service>multiline-drill</service>
  <drill_id>{drill_id}</drill_id>
</log>
"@
        }
    )
    
    for ($i = 0; $i -lt ($Duration * $multiplier); $i++) {
        $timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ"
        $pattern = $multilinePatterns[$i % $multilinePatterns.Count]
        
        $content = $pattern.content -replace "{timestamp}", $timestamp -replace "{drill_id}", $DrillId
        
        Add-Content -Path $logFile -Value $content -Encoding UTF8
        $count++
        
        Start-Sleep -Milliseconds (1500 / $multiplier)
    }
    
    Write-Success "Generated $count multiline pattern log entries"
    return @{ type = "multiline-patterns"; count = $count; file = $logFile }
}

function Invoke-SigNozVerification {
    param($Results)
    
    if (-not $VerifyInSigNoz) { return }
    
    Write-Info "Verifying drill results in SigNoz..."
    
    $verificationQueries = @{
        "error-patterns" = "message contains 'error-pattern-drill'"
        "performance-patterns" = "message contains 'performance-pattern-drill'"
        "format-variations" = "message contains 'format-drill'"
        "volume-spikes" = "message contains 'volume-spike-drill'"
        "edge-cases" = "message contains 'edge-case-drill'"
        "multiline-patterns" = "message contains 'multiline-drill'"
    }
    
    Write-Info "SigNoz Verification Queries:"
    foreach ($result in $Results) {
        if ($verificationQueries.ContainsKey($result.type)) {
            Write-Host "  $($result.type): $($verificationQueries[$result.type])" -ForegroundColor Cyan
        }
    }
    
    Write-Info "Navigate to: http://localhost:8080/logs"
    Write-Info "Use the queries above to verify drill results"
}

# Execute drills based on type
$drillFunctions = @{
    "error-patterns" = { Invoke-ErrorPatternDrill }
    "performance-patterns" = { Invoke-PerformancePatternDrill }
    "format-variations" = { Invoke-FormatVariationDrill }
    "volume-spikes" = { Invoke-VolumeSpikeDrill }
    "edge-cases" = { Invoke-EdgeCaseDrill }
    "multiline-patterns" = { Invoke-MultilinePatternDrill }
}

$executedDrills = @()

if ($DrillType -eq "all") {
    foreach ($drillName in $drillFunctions.Keys) {
        Write-Info "Executing $drillName drill..."
        $result = & $drillFunctions[$drillName]
        $executedDrills += $result
        $drillResults.results += $result
        Start-Sleep -Seconds 5  # Brief pause between drills
    }
} else {
    if ($drillFunctions.ContainsKey($DrillType)) {
        Write-Info "Executing $DrillType drill..."
        $result = & $drillFunctions[$DrillType]
        $executedDrills += $result
        $drillResults.results += $result
    } else {
        Write-Error "Unknown drill type: $DrillType"
        exit 1
    }
}

# Generate summary report
$totalLogs = ($executedDrills | Measure-Object -Property count -Sum).Sum
$drillResults.totalLogsGenerated = $totalLogs
$drillResults.executedDrills = $executedDrills.Count

# Save drill results
$resultsFile = Join-Path $ArtifactsDir "canary-pattern-drill-results-$Timestamp.json"
$drillResults | ConvertTo-Json -Depth 4 | Out-File -FilePath $resultsFile -Encoding UTF8

# Verify in SigNoz
Invoke-SigNozVerification -Results $executedDrills

# Summary
Write-Success "Canary Pattern Drills Completed!"
Write-Info "Total logs generated: $totalLogs"
Write-Info "Drills executed: $($executedDrills.Count)"
Write-Info "Results saved to: $resultsFile"
Write-Info "Log files created in: $LogDir"

# Display verification instructions
Write-Host ""
Write-Host "🔍 Verification Instructions:" -ForegroundColor Yellow
Write-Host "1. Check SigNoz UI: http://localhost:8080/logs" -ForegroundColor White
Write-Host "2. Use drill-specific queries to verify ingestion" -ForegroundColor White
Write-Host "3. Check log files in: $LogDir" -ForegroundColor White
Write-Host "4. Review drill results: $resultsFile" -ForegroundColor White

exit 0
