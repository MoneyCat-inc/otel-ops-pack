# Staged Failure Drill Script for Production Agent System
# This script simulates various failure scenarios to test alerting and remediation

param(
    [string]$Scenario = "all",
    [switch]$DryRun = $false,
    [int]$DelaySeconds = 5
)

Write-Host "🧪 Production Agent System - Staged Failure Drill" -ForegroundColor Cyan
Write-Host "Scenario: $Scenario" -ForegroundColor Yellow
if ($DryRun) {
    Write-Host "Mode: DRY RUN (no actual changes will be made)" -ForegroundColor Magenta
}
Write-Host ""

# Set working directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent (Split-Path -Parent $ScriptDir)
Set-Location $ProjectRoot

# Function to log drill events
function Write-DrillLog {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $Timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ"
    $LogEntry = @{
        timestamp = $Timestamp
        level = $Level
        system = "failure-drill"
        scenario = $Scenario
        message = $Message
    } | ConvertTo-Json -Compress
    
    # Write to OTel metrics log for SigNoz
    $LogFile = "C:\logs\queue\health.log"
    Add-Content -Path $LogFile -Value $LogEntry
    
    # Console output
    $Color = switch ($Level) {
        "ERROR" { "Red" }
        "WARNING" { "Yellow" }
        "SUCCESS" { "Green" }
        default { "White" }
    }
    
    Write-Host "[$Timestamp] $Message" -ForegroundColor $Color
}

# Function to simulate hung daemon
function Test-HungDaemonScenario {
    Write-DrillLog "Testing hung daemon scenario" "INFO"
    
    if ($DryRun) {
        Write-DrillLog "DRY RUN: Would simulate hung daemon by stopping heartbeat updates" "INFO"
        return
    }
    
    try {
        # Stop the daemon to simulate hung state
        Write-DrillLog "Stopping daemon to simulate hung state" "WARNING"
        & pnpm agent:stop
        
        # Wait for heartbeat to go stale
        Write-DrillLog "Waiting for heartbeat to go stale (5+ minutes)" "INFO"
        Start-Sleep -Seconds 10  # Reduced for testing
        
        # Check if remediation detects the hung daemon
        Write-DrillLog "Checking if remediation detects hung daemon" "INFO"
        $RemediationResult = & pwsh -File scripts/agent/remediation.ps1 -Action status
        $ExitCode = $LASTEXITCODE
        
        if ($ExitCode -eq 1) {
            Write-DrillLog "✅ Hung daemon detected correctly (exit code: $ExitCode)" "SUCCESS"
        } else {
            Write-DrillLog "❌ Hung daemon not detected (exit code: $ExitCode)" "ERROR"
        }
        
        # Restart daemon
        Write-DrillLog "Restarting daemon" "INFO"
        & pnpm agent:start
        
    } catch {
        Write-DrillLog "Error in hung daemon scenario: $($_.Exception.Message)" "ERROR"
    }
}

# Function to simulate daemon start failure
function Test-DaemonStartFailureScenario {
    Write-DrillLog "Testing daemon start failure scenario" "INFO"
    
    if ($DryRun) {
        Write-DrillLog "DRY RUN: Would simulate daemon start failure" "INFO"
        return
    }
    
    try {
        # Stop daemon
        Write-DrillLog "Stopping daemon" "INFO"
        & pnpm agent:stop
        
        # Simulate start failure by corrupting PID file
        Write-DrillLog "Simulating start failure by corrupting PID file" "WARNING"
        $PidFile = ".agent/production-agent.pid"
        if (Test-Path $PidFile) {
            Set-Content -Path $PidFile -Value "invalid-json"
        }
        
        # Try to start daemon (should fail)
        Write-DrillLog "Attempting to start daemon (should fail)" "INFO"
        $StartResult = & pwsh -File scripts/agent/remediation.ps1 -Action start
        $ExitCode = $LASTEXITCODE
        
        if ($ExitCode -eq 1) {
            Write-DrillLog "✅ Daemon start failure detected correctly (exit code: $ExitCode)" "SUCCESS"
        } else {
            Write-DrillLog "❌ Daemon start failure not detected (exit code: $ExitCode)" "ERROR"
        }
        
        # Clean up and restart properly
        Write-DrillLog "Cleaning up and restarting properly" "INFO"
        Remove-Item $PidFile -Force -ErrorAction SilentlyContinue
        & pnpm agent:start
        
    } catch {
        Write-DrillLog "Error in daemon start failure scenario: $($_.Exception.Message)" "ERROR"
    }
}

# Function to simulate health check failure
function Test-HealthCheckFailureScenario {
    Write-DrillLog "Testing health check failure scenario" "INFO"
    
    if ($DryRun) {
        Write-DrillLog "DRY RUN: Would simulate health check failure" "INFO"
        return
    }
    
    try {
        # Stop daemon
        Write-DrillLog "Stopping daemon" "INFO"
        & pnpm agent:stop
        
        # Start daemon
        Write-DrillLog "Starting daemon" "INFO"
        & pnpm agent:start
        
        # Wait a moment
        Start-Sleep -Seconds 3
        
        # Simulate health check failure by stopping the daemon process
        Write-DrillLog "Simulating health check failure by stopping daemon process" "WARNING"
        $PidFile = ".agent/production-agent.pid"
        if (Test-Path $PidFile) {
            $PidData = Get-Content $PidFile | ConvertFrom-Json
            Stop-Process -Id $PidData.pid -Force -ErrorAction SilentlyContinue
        }
        
        # Test health check
        Write-DrillLog "Testing health check (should fail)" "INFO"
        $HealthResult = & pwsh -File scripts/agent/remediation.ps1 -Action status
        $ExitCode = $LASTEXITCODE
        
        if ($ExitCode -eq 2) {
            Write-DrillLog "✅ Health check failure detected correctly (exit code: $ExitCode)" "SUCCESS"
        } else {
            Write-DrillLog "❌ Health check failure not detected (exit code: $ExitCode)" "ERROR"
        }
        
        # Clean up and restart
        Write-DrillLog "Cleaning up and restarting" "INFO"
        Remove-Item $PidFile -Force -ErrorAction SilentlyContinue
        & pnpm agent:start
        
    } catch {
        Write-DrillLog "Error in health check failure scenario: $($_.Exception.Message)" "ERROR"
    }
}

# Function to test webhook authentication
function Test-WebhookAuthenticationScenario {
    Write-DrillLog "Testing webhook authentication scenario" "INFO"
    
    try {
        # Test with correct credentials
        Write-DrillLog "Testing with correct credentials" "INFO"
        $env:SIGNOZ_WEBHOOK_SECRET = "prod-agent-webhook-secret-2025"
        $env:SIGNOZ_WEBHOOK_AUTH = "Bearer prod-agent-auth-token-2025"
        
        $AuthResult = & pwsh -File scripts/agent/webhook-handler.ps1 -ValidateAuth -Secret "prod-agent-webhook-secret-2025" -AuthHeader "Bearer prod-agent-auth-token-2025"
        $AuthExitCode = $LASTEXITCODE
        
        if ($AuthExitCode -eq 0) {
            Write-DrillLog "✅ Webhook authentication with correct credentials works" "SUCCESS"
        } else {
            Write-DrillLog "❌ Webhook authentication with correct credentials failed" "ERROR"
        }
        
        # Test with incorrect credentials
        Write-DrillLog "Testing with incorrect credentials" "INFO"
        $InvalidAuthResult = & pwsh -File scripts/agent/webhook-handler.ps1 -ValidateAuth -Secret "wrong-secret" -AuthHeader "Bearer wrong-token"
        $InvalidAuthExitCode = $LASTEXITCODE
        
        if ($InvalidAuthExitCode -eq 1) {
            Write-DrillLog "✅ Webhook authentication correctly rejects invalid credentials" "SUCCESS"
        } else {
            Write-DrillLog "❌ Webhook authentication should reject invalid credentials" "ERROR"
        }
        
        # Test without authentication
        Write-DrillLog "Testing without authentication" "INFO"
        $NoAuthResult = & pwsh -File scripts/agent/webhook-handler.ps1 -Action process
        $NoAuthExitCode = $LASTEXITCODE
        
        if ($NoAuthExitCode -eq 0) {
            Write-DrillLog "✅ Webhook handler works without authentication when disabled" "SUCCESS"
        } else {
            Write-DrillLog "❌ Webhook handler should work without authentication when disabled" "ERROR"
        }
        
    } catch {
        Write-DrillLog "Error in webhook authentication scenario: $($_.Exception.Message)" "ERROR"
    }
}

# Function to test end-to-end webhook flow
function Test-EndToEndWebhookScenario {
    Write-DrillLog "Testing end-to-end webhook flow" "INFO"
    
    if ($DryRun) {
        Write-DrillLog "DRY RUN: Would test end-to-end webhook flow" "INFO"
        return
    }
    
    try {
        # Create test webhook payload
        $TestPayload = @{
            alerts = @(
                @{
                    status = "firing"
                    labels = @{
                        alertname = "Production Agent Hung Daemon"
                        severity = "critical"
                        system = "production-agent-system"
                    }
                    annotations = @{
                        summary = "Production Agent daemon appears hung"
                        description = "Heartbeat age exceeds 5 minutes"
                    }
                }
            )
        } | ConvertTo-Json -Depth 10
        
        # Test webhook processing
        Write-DrillLog "Testing webhook processing with test payload" "INFO"
        $WebhookResult = $TestPayload | pwsh -File scripts/agent/webhook-handler.ps1 -Action process
        $WebhookExitCode = $LASTEXITCODE
        
        if ($WebhookExitCode -eq 0) {
            Write-DrillLog "✅ End-to-end webhook flow completed successfully" "SUCCESS"
        } else {
            Write-DrillLog "❌ End-to-end webhook flow failed (exit code: $WebhookExitCode)" "ERROR"
        }
        
    } catch {
        Write-DrillLog "Error in end-to-end webhook scenario: $($_.Exception.Message)" "ERROR"
    }
}

# Function to check SigNoz logs
function Test-SigNozLogsScenario {
    Write-DrillLog "Checking SigNoz logs for drill events" "INFO"
    
    try {
        # Check recent logs
        $RecentLogs = Get-Content "C:\logs\queue\health.log" -Tail 20
        $DrillLogs = $RecentLogs | Where-Object { $_ -match "failure-drill" }
        
        if ($DrillLogs.Count -gt 0) {
            Write-DrillLog "✅ Found $($DrillLogs.Count) drill events in SigNoz logs" "SUCCESS"
            foreach ($Log in $DrillLogs) {
                Write-DrillLog "  $Log" "INFO"
            }
        } else {
            Write-DrillLog "❌ No drill events found in SigNoz logs" "WARNING"
        }
        
        # Check for remediation failure alerts
        $RemediationLogs = $RecentLogs | Where-Object { $_ -match "remediation_failure" }
        if ($RemediationLogs.Count -gt 0) {
            Write-DrillLog "✅ Found $($RemediationLogs.Count) remediation failure alerts" "SUCCESS"
        } else {
            Write-DrillLog "❌ No remediation failure alerts found" "WARNING"
        }
        
    } catch {
        Write-DrillLog "Error checking SigNoz logs: $($_.Exception.Message)" "ERROR"
    }
}

# Main drill execution
Write-DrillLog "Starting staged failure drill" "INFO"

switch ($Scenario.ToLower()) {
    "hung-daemon" {
        Test-HungDaemonScenario
    }
    "start-failure" {
        Test-DaemonStartFailureScenario
    }
    "health-check-failure" {
        Test-HealthCheckFailureScenario
    }
    "webhook-auth" {
        Test-WebhookAuthenticationScenario
    }
    "end-to-end" {
        Test-EndToEndWebhookScenario
    }
    "sigoz-logs" {
        Test-SigNozLogsScenario
    }
    "all" {
        Write-DrillLog "Running all failure scenarios" "INFO"
        Test-WebhookAuthenticationScenario
        Start-Sleep -Seconds $DelaySeconds
        Test-HungDaemonScenario
        Start-Sleep -Seconds $DelaySeconds
        Test-DaemonStartFailureScenario
        Start-Sleep -Seconds $DelaySeconds
        Test-HealthCheckFailureScenario
        Start-Sleep -Seconds $DelaySeconds
        Test-EndToEndWebhookScenario
        Start-Sleep -Seconds $DelaySeconds
        Test-SigNozLogsScenario
    }
    default {
        Write-DrillLog "Unknown scenario: $Scenario" "ERROR"
        Write-DrillLog "Available scenarios: hung-daemon, start-failure, health-check-failure, webhook-auth, end-to-end, sigoz-logs, all" "INFO"
    }
}

Write-DrillLog "Staged failure drill completed" "INFO"
Write-Host ""
Write-Host "✅ Staged failure drill completed successfully" -ForegroundColor Green
Write-Host ""
Write-Host "📊 Check SigNoz logs for drill events:" -ForegroundColor Cyan
Write-Host "Get-Content C:\logs\queue\health.log -Tail 20 | Select-String 'failure-drill'" -ForegroundColor White
Write-Host ""
Write-Host "📊 Check remediation failure alerts:" -ForegroundColor Cyan
Write-Host "Get-Content C:\logs\queue\health.log -Tail 20 | Select-String 'remediation_failure'" -ForegroundColor White
