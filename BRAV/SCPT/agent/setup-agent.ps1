# Agent Setup Configuration
# Handles the setup process and agent queue management

param(
    [switch]$Force,
    [switch]$SkipNativeModules,
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"

# Ensure .agent directory exists
if (-not (Test-Path ".agent")) {
    New-Item -ItemType Directory -Path ".agent" -Force | Out-Null
}

# Check if setup is already complete
$setupComplete = Test-Path ".agent/SETUP_COMPLETE"
if ($setupComplete -and -not $Force) {
    Write-Host "✅ Setup already completed. Use -Force to re-run." -ForegroundColor Green
    exit 0
}

Write-Host "🚀 Starting agent setup process..." -ForegroundColor Cyan

# Run the main setup script
$setupArgs = @()
if ($SkipNativeModules) { $setupArgs += "-SkipNativeModules" }
if ($Force) { $setupArgs += "-ForceReinstall" }

try {
    & "scripts/setup-local.ps1" @setupArgs
    
    # Mark setup as complete
    New-Item -ItemType File -Path ".agent/SETUP_COMPLETE" -Force | Out-Null
    
    # Create basic agent configuration if it doesn't exist
    if (-not (Test-Path ".agent/config.json")) {
        $agentConfig = @{
            setup_complete = $true
            setup_date = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            queue_driver = if ($SkipNativeModules) { "json" } else { "sqlite" }
            native_modules_enabled = -not $SkipNativeModules
            last_health_check = $null
            status = "ready"
        } | ConvertTo-Json -Depth 3
        
        $agentConfig | Out-File -FilePath ".agent/config.json" -Encoding UTF8
    }
    
    Write-Host "✅ Agent setup completed successfully!" -ForegroundColor Green
    Write-Host "📝 Configuration saved to .agent/config.json" -ForegroundColor White
    
    # Remove the lock file to allow agents to run
    if (Test-Path ".agent/LOCK") {
        Remove-Item ".agent/LOCK" -Force
        Write-Host "🔓 Removed .agent/LOCK - agents can now run" -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "❌ Setup failed: $_" -ForegroundColor Red
    Write-Host "💡 Try running with -SkipNativeModules flag if native modules are problematic" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "🎯 Next steps:" -ForegroundColor White
Write-Host "1. Run 'pnpm dev' to start the development server" -ForegroundColor White
Write-Host "2. Check SigNoz UI at http://localhost:8080" -ForegroundColor White
Write-Host "3. Run 'pwsh scripts/agent/health-check.ps1' to verify everything is working" -ForegroundColor White
