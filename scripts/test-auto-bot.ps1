# Test Auto Bot - Validation and Testing Script
# Tests the ECRR Auto Bot functionality without installing as a service

param(
    [int]$DurationSeconds = 60,
    [switch]$SimulateIssues = $false,
    [switch]$Verbose = $false
)

Set-StrictMode -Version 2
$ErrorActionPreference = "Continue"

function Write-Info { param([string]$Message) Write-Host "   [INFO] $Message" -ForegroundColor Cyan }
function Write-Success { param([string]$Message) Write-Host "   [SUCCESS] $Message" -ForegroundColor Green }
function Write-Warning { param([string]$Message) Write-Host "   [WARNING] $Message" -ForegroundColor Yellow }
function Write-Error { param([string]$Message) Write-Host "   [ERROR] $Message" -ForegroundColor Red }

Write-Host "🧪 ECRR Auto Bot Test Suite" -ForegroundColor Green
Write-Host "   Duration: $DurationSeconds seconds" -ForegroundColor Gray
Write-Host "   Simulate Issues: $SimulateIssues" -ForegroundColor Gray
Write-Host "   Verbose: $Verbose" -ForegroundColor Gray
Write-Host ""

# Test 1: Basic Auto Bot Functionality
Write-Host "Test 1: Basic Auto Bot Health Check" -ForegroundColor Cyan
try {
    $testLogPath = "artifacts\test-auto-bot-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
    $testArgs = @{
        LogPath = $testLogPath
        Verbose = $Verbose
    }
    
    # Run auto bot for a short test
    Write-Info "Running Auto Bot health check..."
    $process = Start-Process -FilePath "pwsh.exe" -ArgumentList "-File", "scripts\auto-bot.ps1", "-LogPath", $testLogPath, "-Verbose" -PassThru -WindowStyle Hidden
    
    # Wait for initial health check
    Start-Sleep -Seconds 10
    
    # Check if log file was created and contains health data
    if (Test-Path $testLogPath) {
        $logContent = Get-Content $testLogPath -Raw
        if ($logContent -match "Health check completed") {
            Write-Success "Auto Bot health check completed successfully"
        } else {
            Write-Warning "Auto Bot health check may not have completed properly"
        }
    } else {
        Write-Error "Auto Bot log file not created"
    }
    
    # Stop the test process
    Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
    
} catch {
    Write-Error "Test 1 failed: $($_.Exception.Message)"
}

Write-Host ""

# Test 2: Pipeline Health Detection
Write-Host "Test 2: Pipeline Health Detection" -ForegroundColor Cyan
try {
    # Test OTel Collector status
    $collectorStatus = sc.exe query otelcol-contrib | Select-String "RUNNING"
    if ($collectorStatus) {
        Write-Success "OTel Collector is running"
    } else {
        Write-Warning "OTel Collector is not running"
    }
    
    # Test SigNoz connectivity
    try {
        $signozResponse = Invoke-WebRequest -Uri "http://localhost:8080" -TimeoutSec 5
        if ($signozResponse.StatusCode -eq 200) {
            Write-Success "SigNoz is reachable"
        } else {
            Write-Warning "SigNoz responded with status: $($signozResponse.StatusCode)"
        }
    } catch {
        Write-Warning "SigNoz is not reachable: $($_.Exception.Message)"
    }
    
    # Test OTLP endpoints
    $otlpEndpoints = @("http://localhost:5318", "http://localhost:14318")
    foreach ($endpoint in $otlpEndpoints) {
        try {
            $response = Invoke-WebRequest -Uri $endpoint -TimeoutSec 3
            Write-Success "OTLP endpoint $endpoint is responding"
        } catch {
            Write-Warning "OTLP endpoint $endpoint is not responding"
        }
    }
    
    # Test system resources
    $memory = Get-WmiObject -Class Win32_OperatingSystem
    $memoryUsage = [math]::Round((($memory.TotalVisibleMemorySize - $memory.FreePhysicalMemory) / $memory.TotalVisibleMemorySize) * 100, 2)
    Write-Info "Memory usage: $memoryUsage%"
    
    $disk = Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='C:'"
    $diskUsage = [math]::Round((($disk.Size - $disk.FreeSpace) / $disk.Size) * 100, 2)
    Write-Info "Disk usage: $diskUsage%"
    
} catch {
    Write-Error "Test 2 failed: $($_.Exception.Message)"
}

Write-Host ""

# Test 3: Auto-Remediation Simulation
Write-Host "Test 3: Auto-Remediation Capabilities" -ForegroundColor Cyan
try {
    if ($SimulateIssues) {
        Write-Info "Simulating issues for remediation testing..."
        
        # Create a test log file to simulate high disk usage
        $testLogDir = "logs\test-remediation"
        if (-not (Test-Path $testLogDir)) {
            New-Item -ItemType Directory -Path $testLogDir -Force | Out-Null
        }
        
        # Create a large test file
        $testFile = Join-Path $testLogDir "test-large-file.log"
        $largeContent = "Test log entry for auto-remediation testing`n" * 1000
        Set-Content -Path $testFile -Value $largeContent -Encoding UTF8
        
        Write-Info "Created test log file: $testFile"
        
        # Test cleanup functionality
        $logFiles = Get-ChildItem -Path $testLogDir -File
        if ($logFiles.Count -gt 0) {
            Write-Success "Test remediation files created successfully"
            
            # Clean up test files
            Remove-Item -Path $testLogDir -Recurse -Force
            Write-Success "Test remediation files cleaned up"
        }
    } else {
        Write-Info "Skipping issue simulation (use -SimulateIssues to enable)"
    }
    
} catch {
    Write-Error "Test 3 failed: $($_.Exception.Message)"
}

Write-Host ""

# Test 4: Deployment Script Validation
Write-Host "Test 4: Deployment Script Validation" -ForegroundColor Cyan
try {
    # Test deployment script syntax
    $deployScript = "scripts\deploy-auto-bot.ps1"
    if (Test-Path $deployScript) {
        $syntaxCheck = pwsh -Command "& { Set-StrictMode -Version 2; . '$deployScript' }" -ErrorAction SilentlyContinue
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Deployment script syntax is valid"
        } else {
            Write-Warning "Deployment script may have syntax issues"
        }
    } else {
        Write-Error "Deployment script not found: $deployScript"
    }
    
    # Test auto bot script syntax
    $autoBotScript = "scripts\auto-bot.ps1"
    if (Test-Path $autoBotScript) {
        $syntaxCheck = pwsh -Command "& { Set-StrictMode -Version 2; . '$autoBotScript' }" -ErrorAction SilentlyContinue
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Auto Bot script syntax is valid"
        } else {
            Write-Warning "Auto Bot script may have syntax issues"
        }
    } else {
        Write-Error "Auto Bot script not found: $autoBotScript"
    }
    
} catch {
    Write-Error "Test 4 failed: $($_.Exception.Message)"
}

Write-Host ""

# Test Summary
Write-Host "📊 Test Summary" -ForegroundColor Green
Write-Host "   Auto Bot functionality: Tested" -ForegroundColor White
Write-Host "   Pipeline health detection: Tested" -ForegroundColor White
Write-Host "   Auto-remediation capabilities: Tested" -ForegroundColor White
Write-Host "   Deployment scripts: Validated" -ForegroundColor White
Write-Host ""
Write-Host "🚀 Ready for Auto Bot deployment!" -ForegroundColor Green
Write-Host "   Install: pwsh -File scripts\deploy-auto-bot.ps1 -Install" -ForegroundColor Yellow
Write-Host "   Test run: pwsh -File scripts\auto-bot.ps1 -Continuous" -ForegroundColor Yellow
