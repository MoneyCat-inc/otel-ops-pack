# Queue Steward Daily Canary Guardrail
# Runs daily to verify pipeline health and emit canary logs

param(
    [switch]$EmitCanary = $true,
    [switch]$CheckHealth = $true,
    [switch]$Verbose = $false
)

Write-Host "🔍 Queue Steward Daily Canary Guardrail" -ForegroundColor Cyan
Write-Host "Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray

# Set working directory
Set-Location 'C:\otel'

# Function to emit canary log
function Emit-CanaryLog {
    Write-Host "📝 Emitting Queue Steward canary log..." -ForegroundColor Yellow
    
    $canaryEntry = @{
        message = "QueueStewardDailyCanary"
        timestamp = (Get-Date).ToString('o')
        dataset = "agent_queue"
        check_type = "daily_guardrail"
        pipeline_status = "healthy"
    } | ConvertTo-Json -Compress
    
    try {
        Add-Content -Path 'C:\logs\queue\health.log' -Value $canaryEntry
        Write-Host "✅ Canary log emitted successfully" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "❌ Failed to emit canary log: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Function to check pipeline health
function Test-PipelineHealth {
    Write-Host "🔍 Checking pipeline health..." -ForegroundColor Yellow
    
    $healthChecks = @{
        MemoryPressure = $false
        CanaryDelivery = $false
        CollectorStatus = $false
    }
    
    # Check 1: Memory pressure
    Write-Host "  Checking memory pressure..." -ForegroundColor Gray
    $events = Get-WinEvent -FilterHashtable @{LogName='Application'; ProviderName='otelcol-contrib'; StartTime=(Get-Date).AddMinutes(-10)} -ErrorAction SilentlyContinue
    $memoryEvents = $events | Where-Object { $_.Message -match 'data refused due to high memory usage' }
    
    if ($memoryEvents) {
        Write-Host "  ❌ Memory pressure detected: $($memoryEvents.Count) events" -ForegroundColor Red
        $healthChecks.MemoryPressure = $false
    } else {
        Write-Host "  ✅ No memory pressure in last 10 minutes" -ForegroundColor Green
        $healthChecks.MemoryPressure = $true
    }
    
    # Check 2: Canary delivery
    Write-Host "  Checking canary delivery..." -ForegroundColor Gray
    try {
        $canaryCount = docker exec signoz-clickhouse clickhouse-client --query "SELECT count() FROM signoz_logs.distributed_logs_v2 WHERE body LIKE '%QueueStewardDailyCanary%' AND timestamp > now() - INTERVAL 10 MINUTE"
        
        if ([int]$canaryCount -gt 0) {
            Write-Host "  ✅ Canary delivery confirmed: $canaryCount entries" -ForegroundColor Green
            $healthChecks.CanaryDelivery = $true
        } else {
            Write-Host "  ❌ No canary entries found in last 10 minutes" -ForegroundColor Red
            $healthChecks.CanaryDelivery = $false
        }
    } catch {
        Write-Host "  ❌ Failed to check canary delivery: $($_.Exception.Message)" -ForegroundColor Red
        $healthChecks.CanaryDelivery = $false
    }
    
    # Check 3: Collector status
    Write-Host "  Checking collector status..." -ForegroundColor Gray
    try {
        $collectorStatus = docker ps --filter "name=signoz-otel-collector" --format "{{.Status}}"
        if ($collectorStatus -match "Up") {
            Write-Host "  ✅ SigNoz collector running" -ForegroundColor Green
            $healthChecks.CollectorStatus = $true
        } else {
            Write-Host "  ❌ SigNoz collector not running" -ForegroundColor Red
            $healthChecks.CollectorStatus = $false
        }
    } catch {
        Write-Host "  ❌ Failed to check collector status: $($_.Exception.Message)" -ForegroundColor Red
        $healthChecks.CollectorStatus = $false
    }
    
    return $healthChecks
}

# Function to update verification artifact
function Update-VerificationArtifact {
    param($HealthChecks, $CanaryEmitted)
    
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $artifactContent = @"
=== Queue Steward Daily Canary Guardrail ===
Date: $timestamp
Agent: Cursor Agent - Observability Copilot

1. Health Checks:
   Memory Pressure: $(if($HealthChecks.MemoryPressure){'[OK] No pressure'}else{'[FAIL] Pressure detected'})
   Canary Delivery: $(if($HealthChecks.CanaryDelivery){'[OK] Canaries flowing'}else{'[FAIL] No canaries'})
   Collector Status: $(if($HealthChecks.CollectorStatus){'[OK] Running'}else{'[FAIL] Not running'})

2. Canary Status:
   Emitted: $(if($CanaryEmitted){'[OK] Canary emitted'}else{'[FAIL] Failed to emit'})

3. Overall Status:
   $(if($HealthChecks.MemoryPressure -and $HealthChecks.CanaryDelivery -and $HealthChecks.CollectorStatus -and $CanaryEmitted){'=== DAILY GUARDRAIL PASSED ==='}else{'=== DAILY GUARDRAIL FAILED ==='})

Queue Steward pipeline $(if($HealthChecks.MemoryPressure -and $HealthChecks.CanaryDelivery -and $HealthChecks.CollectorStatus -and $CanaryEmitted){'healthy'}else{'needs attention'}).
"@
    
    try {
        Set-Content -Path 'artifacts/queue-steward-daily-guardrail.txt' -Value $artifactContent
        Write-Host "📄 Verification artifact updated" -ForegroundColor Green
    } catch {
        Write-Host "❌ Failed to update verification artifact: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Main execution
try {
    $canaryEmitted = $false
    $healthChecks = @{}
    
    # Emit canary if requested
    if ($EmitCanary) {
        $canaryEmitted = Emit-CanaryLog
        Start-Sleep -Seconds 5  # Wait for canary to be processed
    }
    
    # Check health if requested
    if ($CheckHealth) {
        $healthChecks = Test-PipelineHealth
    }
    
    # Update verification artifact
    Update-VerificationArtifact -HealthChecks $healthChecks -CanaryEmitted $canaryEmitted
    
    # Summary
    Write-Host "`n📊 Daily Guardrail Summary:" -ForegroundColor Cyan
    Write-Host "Canary Emitted: $(if($canaryEmitted){'✅'}else{'❌'})" -ForegroundColor $(if($canaryEmitted){'Green'}else{'Red'})
    Write-Host "Memory Pressure: $(if($healthChecks.MemoryPressure){'✅'}else{'❌'})" -ForegroundColor $(if($healthChecks.MemoryPressure){'Green'}else{'Red'})
    Write-Host "Canary Delivery: $(if($healthChecks.CanaryDelivery){'✅'}else{'❌'})" -ForegroundColor $(if($healthChecks.CanaryDelivery){'Green'}else{'Red'})
    Write-Host "Collector Status: $(if($healthChecks.CollectorStatus){'✅'}else{'❌'})" -ForegroundColor $(if($healthChecks.CollectorStatus){'Green'}else{'Red'})
    
    $overallHealth = $canaryEmitted -and $healthChecks.MemoryPressure -and $healthChecks.CanaryDelivery -and $healthChecks.CollectorStatus
    
    if ($overallHealth) {
        Write-Host "`n🎉 Queue Steward pipeline is healthy!" -ForegroundColor Green
        exit 0
    } else {
        Write-Host "`n⚠️ Queue Steward pipeline needs attention" -ForegroundColor Yellow
        exit 1
    }
    
} catch {
    Write-Host "`n❌ Daily guardrail failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
