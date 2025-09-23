# Comprehensive System Health Check for Monolith-D
# Includes DMA Protection status and SigNoz integration

param(
    [switch]$SendToSigNoz = $true,
    [switch]$GenerateReport = $true
)

$ErrorActionPreference = "Continue"
$StartTime = Get-Date
$Hostname = $env:COMPUTERNAME

Write-Host "🔍 System Health Check for $Hostname" -ForegroundColor Cyan
Write-Host "  Timestamp: $($StartTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Gray

$HealthStatus = @{
    Timestamp = $StartTime
    Hostname = $Hostname
    Checks = @{}
    OverallStatus = "UNKNOWN"
}

# Function to send data to SigNoz
function Send-ToSigNoz {
    param($LogData)
    
    try {
        $Headers = @{
            "Content-Type" = "application/json"
        }
        
        $Payload = @{
            resourceLogs = @(
                @{
                    resource = @{
                        attributes = @(
                            @{
                                key = "host.name"
                                value = @{
                                    stringValue = $Hostname
                                }
                            },
                            @{
                                key = "service.name"
                                value = @{
                                    stringValue = "system-health-check"
                                }
                            },
                            @{
                                key = "dataset"
                                value = @{
                                    stringValue = "system_health"
                                }
                            }
                        )
                    }
                    scopeLogs = @(
                        @{
                            scope = @{
                                name = "system-health-check"
                                version = "1.0.0"
                            }
                            logRecords = @(
                                @{
                                    timeUnixNano = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() * 1000000
                                    severityText = "INFO"
                                    body = @{
                                        stringValue = ($LogData | ConvertTo-Json -Compress)
                                    }
                                    attributes = @(
                                        @{
                                            key = "check_type"
                                            value = @{
                                                stringValue = "system_health"
                                            }
                                        }
                                    )
                                }
                            )
                        }
                    )
                }
            )
        } | ConvertTo-Json -Depth 10
        
        $Response = Invoke-RestMethod -Uri "http://localhost:14318/v1/logs" -Method POST -Body $Payload -Headers $Headers -TimeoutSec 10 -ErrorAction SilentlyContinue
        return $true
    } catch {
        return $false
    }
}

# Check 1: Kernel DMA Protection
Write-Host "`n🔒 Checking Kernel DMA Protection..." -ForegroundColor Yellow
try {
    $DMARegPath = "HKLM:\SYSTEM\CurrentControlSet\Control\DmaSecurity"
    $DMAStatus = "NOT_CONFIGURED"
    $DMADetails = "Registry path not found"
    
    if (Test-Path $DMARegPath) {
        $DMAKey = Get-ItemProperty -Path $DMARegPath -Name "DmaSecurityEnabled" -ErrorAction SilentlyContinue
        if ($DMAKey) {
            $DMAStatus = if ($DMAKey.DmaSecurityEnabled -eq 1) { "ENABLED" } else { "DISABLED" }
            $DMADetails = "Registry value: $($DMAKey.DmaSecurityEnabled)"
        } else {
            $DMAStatus = "KEY_MISSING"
            $DMADetails = "DmaSecurityEnabled key not found"
        }
    }
    
    $HealthStatus.Checks.DMAProtection = @{
        Status = $DMAStatus
        Details = $DMADetails
        Success = $DMAStatus -eq "ENABLED"
        RequiresRestart = $DMAStatus -eq "ENABLED"
    }
    
    Write-Host "   Status: $DMAStatus" -ForegroundColor $(if ($DMAStatus -eq "ENABLED") { "Green" } else { "Red" })
    Write-Host "   Details: $DMADetails" -ForegroundColor Gray
} catch {
    $HealthStatus.Checks.DMAProtection = @{
        Status = "ERROR"
        Details = $_.Exception.Message
        Success = $false
    }
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
}

# Check 2: Virtual Desktop Monitor
Write-Host "`n🖥️  Checking Virtual Desktop Monitor..." -ForegroundColor Yellow
try {
    $VDDevice = Get-PnpDevice -FriendlyName "*Virtual Desktop Monitor*" -ErrorAction SilentlyContinue
    if ($VDDevice) {
        $VDStatus = $VDDevice.Status
        $VDDetails = "InstanceId: $($VDDevice.InstanceId)"
    } else {
        $VDStatus = "NOT_FOUND"
        $VDDetails = "Device not found in system"
    }
    
    $HealthStatus.Checks.VirtualDesktopMonitor = @{
        Status = $VDStatus
        Details = $VDDetails
        Success = $VDStatus -eq "OK"
    }
    
    Write-Host "   Status: $VDStatus" -ForegroundColor $(if ($VDStatus -eq "OK") { "Green" } else { "Yellow" })
    Write-Host "   Details: $VDDetails" -ForegroundColor Gray
} catch {
    $HealthStatus.Checks.VirtualDesktopMonitor = @{
        Status = "ERROR"
        Details = $_.Exception.Message
        Success = $false
    }
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
}

# Check 3: Phone App Status
Write-Host "`n📱 Checking Phone App..." -ForegroundColor Yellow
try {
    $PhonePackage = Get-AppxPackage -Name "Microsoft.YourPhone" -ErrorAction SilentlyContinue
    $PhoneProcess = Get-Process -Name "PhoneExperienceHost" -ErrorAction SilentlyContinue
    
    $PhoneStatus = if ($PhonePackage) {
        if ($PhoneProcess) { "RUNNING" } else { "INSTALLED_NOT_RUNNING" }
    } else { "NOT_INSTALLED" }
    
    $PhoneDetails = "Package: $(if ($PhonePackage) { 'Installed' } else { 'Not Found' }), Process: $(if ($PhoneProcess) { 'Running' } else { 'Not Running' })"
    
    $HealthStatus.Checks.PhoneApp = @{
        Status = $PhoneStatus
        Details = $PhoneDetails
        Success = $PhoneStatus -in @("RUNNING", "INSTALLED_NOT_RUNNING")
    }
    
    Write-Host "   Status: $PhoneStatus" -ForegroundColor $(if ($PhoneStatus -in @("RUNNING", "INSTALLED_NOT_RUNNING")) { "Green" } else { "Yellow" })
    Write-Host "   Details: $PhoneDetails" -ForegroundColor Gray
} catch {
    $HealthStatus.Checks.PhoneApp = @{
        Status = "ERROR"
        Details = $_.Exception.Message
        Success = $false
    }
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
}

# Check 4: Crash Dump Status
Write-Host "`n💥 Checking crash dump status..." -ForegroundColor Yellow
try {
    $WERPath = "C:\ProgramData\Microsoft\Windows\WER\Temp"
    $CrashFiles = if (Test-Path $WERPath) {
        Get-ChildItem -Path $WERPath -Filter "*.mdmp" -Recurse -ErrorAction SilentlyContinue | 
            Measure-Object | Select-Object -ExpandProperty Count
    } else { 0 }
    
    $CrashStatus = if ($CrashFiles -eq 0) { "CLEAN" } else { "HAS_FILES" }
    $CrashDetails = "Total crash files: $CrashFiles"
    
    $HealthStatus.Checks.CrashDumps = @{
        Status = $CrashStatus
        Details = $CrashDetails
        Count = $CrashFiles
        Success = $CrashFiles -eq 0
    }
    
    Write-Host "   Status: $CrashStatus" -ForegroundColor $(if ($CrashFiles -eq 0) { "Green" } else { "Yellow" })
    Write-Host "   Details: $CrashDetails" -ForegroundColor Gray
} catch {
    $HealthStatus.Checks.CrashDumps = @{
        Status = "ERROR"
        Details = $_.Exception.Message
        Success = $false
    }
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
}

# Check 5: SigNoz Connectivity
Write-Host "`n📡 Checking SigNoz connectivity..." -ForegroundColor Yellow
try {
    $SigNozHealth = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/health" -Method GET -TimeoutSec 10 -ErrorAction SilentlyContinue
    $SigNozStatus = if ($SigNozHealth -and $SigNozHealth.status -eq "ok") { "HEALTHY" } else { "UNHEALTHY" }
    $SigNozDetails = "Health endpoint: $($SigNozHealth.status)"
    
    $HealthStatus.Checks.SigNoz = @{
        Status = $SigNozStatus
        Details = $SigNozDetails
        Success = $SigNozStatus -eq "HEALTHY"
    }
    
    Write-Host "   Status: $SigNozStatus" -ForegroundColor $(if ($SigNozStatus -eq "HEALTHY") { "Green" } else { "Red" })
    Write-Host "   Details: $SigNozDetails" -ForegroundColor Gray
} catch {
    $HealthStatus.Checks.SigNoz = @{
        Status = "ERROR"
        Details = $_.Exception.Message
        Success = $false
    }
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
}

# Calculate overall status
$TotalChecks = $HealthStatus.Checks.Count
$SuccessfulChecks = ($HealthStatus.Checks.Values | Where-Object { $_.Success }).Count
$SuccessRate = [math]::Round(($SuccessfulChecks / $TotalChecks) * 100, 1)

$HealthStatus.OverallStatus = if ($SuccessRate -ge 80) { "HEALTHY" } elseif ($SuccessRate -ge 60) { "WARNING" } else { "CRITICAL" }
$HealthStatus.Summary = @{
    TotalChecks = $TotalChecks
    SuccessfulChecks = $SuccessfulChecks
    SuccessRate = $SuccessRate
    EndTime = Get-Date
    Duration = (Get-Date - $StartTime).TotalSeconds
}

# Send to SigNoz if requested
if ($SendToSigNoz) {
    Write-Host "`n📡 Sending health data to SigNoz..." -ForegroundColor Cyan
    $SigNozSuccess = Send-ToSigNoz -LogData $HealthStatus
    Write-Host "   Status: $(if ($SigNozSuccess) { 'SENT ✅' } else { 'FAILED ❌' })" -ForegroundColor $(if ($SigNozSuccess) { 'Green' } else { 'Red' })
}

# Generate report if requested
if ($GenerateReport) {
    Write-Host "`n📋 Generating health report..." -ForegroundColor Cyan
    
    # Create artifacts directory
    if (!(Test-Path "artifacts")) {
        New-Item -ItemType Directory -Path "artifacts" -Force | Out-Null
    }
    
    $ReportPath = "artifacts/system-health-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $HealthStatus | ConvertTo-Json -Depth 4 | Out-File -FilePath $ReportPath -Encoding UTF8
    
    Write-Host "   Report saved: $ReportPath" -ForegroundColor Blue
}

# Display summary
Write-Host "`n✅ Health Check Complete!" -ForegroundColor Green
Write-Host "   Overall Status: $($HealthStatus.OverallStatus)" -ForegroundColor $(if ($HealthStatus.OverallStatus -eq "HEALTHY") { "Green" } elseif ($HealthStatus.OverallStatus -eq "WARNING") { "Yellow" } else { "Red" })
Write-Host "   Success Rate: $SuccessRate% ($SuccessfulChecks/$TotalChecks)" -ForegroundColor $(if ($SuccessRate -ge 80) { "Green" } elseif ($SuccessRate -ge 60) { "Yellow" } else { "Red" })
Write-Host "   Duration: $([math]::Round($HealthStatus.Summary.Duration, 2)) seconds" -ForegroundColor Gray

# Display next steps
Write-Host "`n🚀 Next Steps:" -ForegroundColor Cyan
if ($HealthStatus.Checks.DMAProtection.Status -ne "ENABLED") {
    Write-Host "   • Enable DMA Protection: Start-Process pwsh -Verb RunAs -ArgumentList '-File scripts\enable-dma-protection.ps1'" -ForegroundColor Yellow
}
if ($HealthStatus.Checks.SigNoz.Status -ne "HEALTHY") {
    Write-Host "   • Check SigNoz: http://localhost:8080" -ForegroundColor Yellow
}
if ($HealthStatus.OverallStatus -eq "HEALTHY") {
    Write-Host "   • System is healthy! Monitor via SigNoz dashboard" -ForegroundColor Green
}

return $HealthStatus
