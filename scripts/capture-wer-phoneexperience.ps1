# WER PhoneExperienceHost Crash Capture for SigNoz
# Captures Windows Error Reporting crashes and writes structured JSON for OTel ingestion
# Usage: .\capture-wer-phoneexperience.ps1 [-EmitTestRecord]

param(
    [switch]$EmitTestRecord
)

# Ensure logs directory exists
$LogDir = "C:\logs"
if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}

$LogFile = "$LogDir\wer-phoneexperience.log"
$Timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ"

function Write-WERRecord {
    param(
        [string]$ApplicationName,
        [string]$FaultingModule,
        [string]$ExceptionCode,
        [string]$FaultOffset,
        [string]$ProcessId,
        [string]$ThreadId,
        [string]$EventTime,
        [string]$EventId,
        [string]$Source,
        [string]$Message,
        [switch]$IsTest
    )
    
    $Record = @{
        timestamp = $EventTime
        dataset = "windows-wer"
        event_id = $EventId
        source = $Source
        faulting_application = $ApplicationName
        faulting_module = $FaultingModule
        exception_code = $ExceptionCode
        fault_offset = $FaultOffset
        process_id = $ProcessId
        thread_id = $ThreadId
        message = $Message
        synthetic = if ($IsTest) { "true" } else { "false" }
        severity = "ERROR"
        service_name = "windows-wer-capture"
        deployment_environment = "local"
    } | ConvertTo-Json -Compress
    
    Add-Content -Path $LogFile -Value $Record -Encoding UTF8
    Write-Host "WER record written: $ApplicationName crash" -ForegroundColor Yellow
}

# Capture real WER events for PhoneExperienceHost
try {
    Write-Host "🔍 Scanning Windows Event Log for PhoneExperienceHost crashes..." -ForegroundColor Cyan
    
    # Query Application Event Log for WER crashes (EventID 1001)
    $WEREvents = Get-WinEvent -FilterHashtable @{
        LogName = 'Application'
        ID = 1001
        StartTime = (Get-Date).AddHours(-24)
    } -ErrorAction SilentlyContinue | Where-Object {
        $_.Message -match 'PhoneExperienceHost\.exe'
    }
    
    $CapturedCount = 0
    foreach ($Event in $WEREvents) {
        # Parse WER crash details from event message
        $Message = $Event.Message
        
        # Extract faulting application
        if ($Message -match 'Faulting application name: ([^\r\n]+)') {
            $AppName = $Matches[1].Trim()
        } else {
            $AppName = "PhoneExperienceHost.exe"
        }
        
        # Extract faulting module
        if ($Message -match 'Faulting module name: ([^\r\n]+)') {
            $ModuleName = $Matches[1].Trim()
        } else {
            $ModuleName = "unknown"
        }
        
        # Extract exception code
        if ($Message -match 'Exception code: ([^\r\n]+)') {
            $ExceptionCode = $Matches[1].Trim()
        } else {
            $ExceptionCode = "0x00000000"
        }
        
        # Extract fault offset
        if ($Message -match 'Fault offset: ([^\r\n]+)') {
            $FaultOffset = $Matches[1].Trim()
        } else {
            $FaultOffset = "0x00000000"
        }
        
        # Extract process/thread IDs
        if ($Message -match 'Faulting process id: ([^\r\n]+)') {
            $ProcessId = $Matches[1].Trim()
        } else {
            $ProcessId = "0"
        }
        
        if ($Message -match 'Faulting thread id: ([^\r\n]+)') {
            $ThreadId = $Matches[1].Trim()
        } else {
            $ThreadId = "0"
        }
        
        Write-WERRecord -ApplicationName $AppName -FaultingModule $ModuleName -ExceptionCode $ExceptionCode -FaultOffset $FaultOffset -ProcessId $ProcessId -ThreadId $ThreadId -EventTime ($Event.TimeCreated.ToString("yyyy-MM-ddTHH:mm:ss.fffZ")) -EventId $Event.Id -Source $Event.ProviderName -Message $Message
        
        $CapturedCount++
    }
    
    Write-Host "✅ Captured $CapturedCount PhoneExperienceHost WER events from last 24h" -ForegroundColor Green
    
} catch {
    Write-Host "⚠️  Error querying WER events: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Emit synthetic test record if requested
if ($EmitTestRecord) {
    Write-Host "🧪 Emitting synthetic WER test record..." -ForegroundColor Cyan
    
    $TestMessage = @"
Faulting application name: PhoneExperienceHost.exe, version: 10.0.22621.3527, time stamp: 0x12345678
Faulting module name: ntdll.dll, version: 10.0.22621.3527, time stamp: 0x12345678
Exception code: 0xc0000005
Fault offset: 0x0000000000123456
Faulting process id: 0x1234
Faulting thread id: 0x5678
"@
    
    Write-WERRecord -ApplicationName "PhoneExperienceHost.exe" -FaultingModule "ntdll.dll" -ExceptionCode "0xc0000005" -FaultOffset "0x0000000000123456" -ProcessId "0x1234" -ThreadId "0x5678" -EventTime $Timestamp -EventId 1001 -Source "Application Error" -Message $TestMessage -IsTest
    
    Write-Host "✅ Synthetic WER test record written to $LogFile" -ForegroundColor Green
}

Write-Host "📊 WER capture complete. Check SigNoz with filter: dataset = 'windows-wer' AND faulting_application = 'PhoneExperienceHost.exe'" -ForegroundColor Magenta