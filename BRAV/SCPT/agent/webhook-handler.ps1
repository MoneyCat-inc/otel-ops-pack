# SigNoz Webhook Handler for Production Agent System
# This script receives webhook calls from SigNoz alerts and triggers remediation

param(
    [string]$WebhookPayload = "",
    [string]$Action = "process",
    [string]$Secret = "",
    [string]$AuthHeader = "",
    [switch]$ValidateAuth = $false
)

Write-Host "🔗 SigNoz Webhook Handler - Production Agent System" -ForegroundColor Cyan
Write-Host "Action: $Action" -ForegroundColor Yellow
Write-Host ""

# Set working directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent (Split-Path -Parent $ScriptDir)
Set-Location $ProjectRoot

# Function to validate webhook authentication
function Test-WebhookAuth {
    param(
        [string]$Secret,
        [string]$AuthHeader,
        [hashtable]$Headers = @{}
    )
    
    try {
        # Check if authentication is required
        if (-not $ValidateAuth) {
            Write-WebhookLog "Authentication validation disabled" "INFO"
            return $true
        }
        
        # Validate secret if provided
        if (-not [string]::IsNullOrEmpty($Secret)) {
            $ExpectedSecret = $env:SIGNOZ_WEBHOOK_SECRET
            if ([string]::IsNullOrEmpty($ExpectedSecret)) {
                Write-WebhookLog "SIGNOZ_WEBHOOK_SECRET environment variable not set" "ERROR"
                return $false
            }
            
            if ($Secret -ne $ExpectedSecret) {
                Write-WebhookLog "Invalid webhook secret provided" "ERROR"
                return $false
            }
            
            Write-WebhookLog "Webhook secret validated successfully" "SUCCESS"
        }
        
        # Validate auth header if provided
        if (-not [string]::IsNullOrEmpty($AuthHeader)) {
            $ExpectedAuth = $env:SIGNOZ_WEBHOOK_AUTH
            if ([string]::IsNullOrEmpty($ExpectedAuth)) {
                Write-WebhookLog "SIGNOZ_WEBHOOK_AUTH environment variable not set" "ERROR"
                return $false
            }
            
            if ($AuthHeader -ne $ExpectedAuth) {
                Write-WebhookLog "Invalid auth header provided" "ERROR"
                return $false
            }
            
            Write-WebhookLog "Auth header validated successfully" "SUCCESS"
        }
        
        # If no auth provided but validation is required
        if ($ValidateAuth -and [string]::IsNullOrEmpty($Secret) -and [string]::IsNullOrEmpty($AuthHeader)) {
            Write-WebhookLog "Authentication required but no credentials provided" "ERROR"
            return $false
        }
        
        return $true
        
    } catch {
        Write-WebhookLog "Error validating authentication: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Function to log webhook events
function Write-WebhookLog {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $Timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ"
    $LogEntry = @{
        timestamp = $Timestamp
        level = $Level
        system = "signoz-webhook-handler"
        action = $Action
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

# Function to parse webhook payload
function Parse-WebhookPayload {
    param([string]$Payload)
    
    try {
        if ([string]::IsNullOrEmpty($Payload)) {
            # Try to read from stdin if no payload provided
            $Payload = [Console]::In.ReadToEnd()
        }
        
        if ([string]::IsNullOrEmpty($Payload)) {
            Write-WebhookLog "No webhook payload provided" "ERROR"
            return $null
        }
        
        $WebhookData = $Payload | ConvertFrom-Json
        Write-WebhookLog "Webhook payload parsed successfully" "SUCCESS"
        return $WebhookData
        
    } catch {
        Write-WebhookLog "Failed to parse webhook payload: $($_.Exception.Message)" "ERROR"
        return $null
    }
}

# Function to process heartbeat alerts
function Process-HeartbeatAlert {
    param($Alert)
    
    $AlertName = $Alert.labels.alertname
    $Severity = $Alert.labels.severity
    $System = $Alert.labels.system
    
    Write-WebhookLog "Processing heartbeat alert: $AlertName (Severity: $Severity)" "INFO"
    
    # Check if this is a production agent system alert
    if ($System -ne "production-agent-system") {
        Write-WebhookLog "Alert not for production agent system, ignoring" "WARNING"
        return
    }
    
    # Determine remediation action based on severity
    $RemediationAction = switch ($Severity.ToLower()) {
        "critical" { "restart" }
        "warning" { "status" }
        default { "status" }
    }
    
    Write-WebhookLog "Triggering remediation action: $RemediationAction" "INFO"
    
    # Execute remediation script
    try {
        $RemediationScript = Join-Path $ScriptDir "remediation.ps1"
        $RemediationResult = & $RemediationScript -Action $RemediationAction -Reason "signoz_webhook_alert"
        
        if ($LASTEXITCODE -eq 0) {
            Write-WebhookLog "Remediation completed successfully" "SUCCESS"
        } else {
            Write-WebhookLog "Remediation failed with exit code: $LASTEXITCODE" "ERROR"
        }
    } catch {
        Write-WebhookLog "Error executing remediation script: $($_.Exception.Message)" "ERROR"
    }
}

# Function to process general alerts
function Process-GeneralAlert {
    param($Alert)
    
    $AlertName = $Alert.labels.alertname
    $Severity = $Alert.labels.severity
    
    Write-WebhookLog "Processing general alert: $AlertName (Severity: $Severity)" "INFO"
    
    # Log the alert for monitoring
    $AlertLog = @{
        timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ"
        level = $Severity.ToUpper()
        system = "signoz-webhook-handler"
        type = "alert_received"
        message = "Alert received from SigNoz: $AlertName"
        details = @{
            alertname = $AlertName
            severity = $Severity
            status = $Alert.status
            annotations = $Alert.annotations
        }
    } | ConvertTo-Json -Compress
    
    $LogFile = "C:\logs\queue\health.log"
    Add-Content -Path $LogFile -Value $AlertLog
    
    Write-WebhookLog "Alert logged for monitoring" "SUCCESS"
}

# Main webhook processing logic
Write-WebhookLog "Starting webhook processing" "INFO"

# Validate authentication if required
if (-not (Test-WebhookAuth -Secret $Secret -AuthHeader $AuthHeader)) {
    Write-WebhookLog "Authentication validation failed, rejecting webhook" "ERROR"
    exit 1
}

# Parse webhook payload
$WebhookData = Parse-WebhookPayload -Payload $WebhookPayload
if ($WebhookData -eq $null) {
    Write-WebhookLog "Failed to parse webhook data, exiting" "ERROR"
    exit 1
}

# Process alerts
if ($WebhookData.alerts -and $WebhookData.alerts.Count -gt 0) {
    Write-WebhookLog "Processing $($WebhookData.alerts.Count) alerts" "INFO"
    
    foreach ($Alert in $WebhookData.alerts) {
        $AlertName = $Alert.labels.alertname
        
        # Route alerts based on type
        switch ($AlertName) {
            { $_ -match "Heartbeat" -or $_ -match "Hung Daemon" } {
                Process-HeartbeatAlert -Alert $Alert
            }
            default {
                Process-GeneralAlert -Alert $Alert
            }
        }
    }
} else {
    Write-WebhookLog "No alerts found in webhook payload" "WARNING"
}

Write-WebhookLog "Webhook processing completed" "SUCCESS"
Write-Host ""
Write-Host "✅ Webhook processing completed successfully" -ForegroundColor Green
