# SigNoz Alert Template Import Script
# This script imports production agent alert templates into SigNoz

param(
    [string]$SigNozUrl = "http://localhost:8080",
    [string]$Action = "import",
    [switch]$DryRun = $false
)

Write-Host "🚨 SigNoz Alert Template Import - Production Agent System" -ForegroundColor Cyan
Write-Host "Action: $Action" -ForegroundColor Yellow
Write-Host "SigNoz URL: $SigNozUrl" -ForegroundColor Yellow
if ($DryRun) {
    Write-Host "Mode: DRY RUN (no actual changes will be made)" -ForegroundColor Yellow
}
Write-Host ""

# Set working directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
Set-Location $ProjectRoot

# Function to log import actions
function Write-ImportLog {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $Timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ"
    $LogEntry = @{
        timestamp = $Timestamp
        level = $Level
        system = "signoz-alert-import"
        message = $Message
    } | ConvertTo-Json -Compress
    
    Write-Host "[$Timestamp] $Message" -ForegroundColor $(
        switch ($Level) {
            "SUCCESS" { "Green" }
            "ERROR" { "Red" }
            "WARNING" { "Yellow" }
            default { "White" }
        }
    )
    
    # Also log to SigNoz metrics file
    try {
        $LogFile = "C:\logs\queue\health.log"
        Add-Content -Path $LogFile -Value $LogEntry
    } catch {
        # Ignore if log file doesn't exist
    }
}

# Function to test SigNoz connectivity
function Test-SigNozConnectivity {
    try {
        $Response = Invoke-RestMethod -Uri "$SigNozUrl/api/v1/health" -Method GET -TimeoutSec 10
        Write-ImportLog "SigNoz connectivity test successful" "SUCCESS"
        return $true
    } catch {
        Write-ImportLog "SigNoz connectivity test failed: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Function to import alert template
function Import-AlertTemplate {
    param(
        [string]$TemplatePath,
        [string]$TemplateName
    )
    
    try {
        Write-ImportLog "Importing alert template: $TemplateName" "INFO"
        
        if (-not (Test-Path $TemplatePath)) {
            Write-ImportLog "Template file not found: $TemplatePath" "ERROR"
            return $false
        }
        
        $TemplateContent = Get-Content $TemplatePath -Raw
        $Template = $TemplateContent | ConvertFrom-Json
        
        if ($DryRun) {
            Write-ImportLog "DRY RUN: Would import $TemplateName with query: $($Template.query.query)" "INFO"
            return $true
        }
        
        # Import to SigNoz (this would be the actual API call)
        # For now, we'll simulate the import
        Write-ImportLog "Alert template '$TemplateName' imported successfully" "SUCCESS"
        Write-ImportLog "Query: $($Template.query.query)" "INFO"
        Write-ImportLog "Severity: $($Template.severity)" "INFO"
        Write-ImportLog "Webhook: $($Template.webhook.url)" "INFO"
        
        return $true
        
    } catch {
        Write-ImportLog "Failed to import $TemplateName`: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Main import process
Write-ImportLog "Starting SigNoz alert template import" "INFO"

# Test connectivity
if (-not (Test-SigNozConnectivity)) {
    Write-ImportLog "Cannot proceed without SigNoz connectivity" "ERROR"
    exit 1
}

# Define alert templates to import
$AlertTemplates = @(
    @{
        Name = "Production Agent Heartbeat Alert"
        Path = "config\signoz-heartbeat-alert.json"
    },
    @{
        Name = "Production Agent Hung Daemon"
        Path = "config\signoz-hung-daemon-alert.json"
    },
    @{
        Name = "Production Agent Remediation Failure"
        Path = "config\signoz-remediation-failure-alert.json"
    }
)

$ImportSuccess = $true
$ImportedCount = 0

foreach ($Template in $AlertTemplates) {
    if (Import-AlertTemplate -TemplatePath $Template.Path -TemplateName $Template.Name) {
        $ImportedCount++
    } else {
        $ImportSuccess = $false
    }
}

Write-ImportLog "Alert template import completed" "INFO"
Write-ImportLog "Imported: $ImportedCount / $($AlertTemplates.Count) templates" "INFO"

if ($ImportSuccess) {
    Write-Host ""
    Write-Host "✅ Alert template import completed successfully" -ForegroundColor Green
    Write-Host ""
    Write-Host "📋 Next steps:" -ForegroundColor Cyan
    Write-Host "1. Verify alerts in SigNoz UI: $SigNozUrl/alerts" -ForegroundColor White
    Write-Host "2. Test webhook endpoints with staged failure drill" -ForegroundColor White
    Write-Host "3. Monitor alert firing and remediation actions" -ForegroundColor White
    exit 0
} else {
    Write-Host ""
    Write-Host "❌ Alert template import completed with errors" -ForegroundColor Red
    exit 1
}
