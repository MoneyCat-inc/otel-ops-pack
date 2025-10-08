# Auto Bots Deployment Script
# BossCat OEM - Automated Bot Deployment System

param(
    [switch]$HealthMonitor,
    [switch]$AlertManager,
    [switch]$DashboardRefresh,
    [switch]$ReportGenerator,
    [switch]$Cleanup,
    [switch]$All,
    [switch]$Stop,
    [switch]$Status
)

Write-Host "🤖 BossCat OEM - Auto Bots Deployment System" -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green

# Bot configurations
$bots = @{
    'health-monitor' = @{
        script = 'scripts/auto-bots/health-monitor-bot.js'
        name = 'Health Monitor Bot'
        description = 'Monitors SigNoz, OTel Collector, and system health'
        interval = '30 seconds'
    }
    'alert-manager' = @{
        script = 'scripts/auto-bots/alert-manager-bot.js'
        name = 'Alert Manager Bot'
        description = 'Monitors thresholds and triggers alerts'
        interval = '1 minute'
    }
    'dashboard-refresh' = @{
        script = 'scripts/auto-bots/dashboard-refresh-bot.js'
        name = 'Dashboard Refresh Bot'
        description = 'Refreshes dashboard data and generates snapshots'
        interval = '2 minutes'
    }
    'report-generator' = @{
        script = 'scripts/auto-bots/report-generator-bot.js'
        name = 'Report Generator Bot'
        description = 'Generates comprehensive reports'
        interval = '15 minutes'
    }
    'cleanup' = @{
        script = 'scripts/auto-bots/cleanup-bot.js'
        name = 'Cleanup Bot'
        description = 'Maintains system hygiene and optimizes storage'
        interval = '1 hour'
    }
}

# Function to check if Node.js is available
function Test-NodeJS {
    try {
        $null = node --version
        return $true
    } catch {
        Write-Host "❌ Node.js not found. Please install Node.js first." -ForegroundColor Red
        return $false
    }
}

# Function to start a bot
function Start-Bot {
    param($botKey, $botConfig)
    
    Write-Host "🚀 Starting $($botConfig.name)..." -ForegroundColor Cyan
    
    if (-not (Test-Path $botConfig.script)) {
        Write-Host "❌ Script not found: $($botConfig.script)" -ForegroundColor Red
        return $false
    }
    
    try {
        # Start bot in background
        $process = Start-Process -FilePath "node" -ArgumentList $botConfig.script -PassThru -WindowStyle Hidden
        
        # Save process info
        $processInfo = @{
            id = $process.Id
            name = $botConfig.name
            script = $botConfig.script
            startTime = Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ"
            description = $botConfig.description
            interval = $botConfig.interval
        }
        
        $processFile = "artifacts/auto-bots/$botKey-process.json"
        if (-not (Test-Path "artifacts/auto-bots")) {
            New-Item -ItemType Directory -Path "artifacts/auto-bots" -Force | Out-Null
        }
        
        $processInfo | ConvertTo-Json | Out-File -FilePath $processFile -Encoding UTF8
        
        Write-Host "✅ $($botConfig.name) started (PID: $($process.Id))" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "❌ Failed to start $($botConfig.name): $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Function to stop a bot
function Stop-Bot {
    param($botKey)
    
    $processFile = "artifacts/auto-bots/$botKey-process.json"
    
    if (Test-Path $processFile) {
        try {
            $processInfo = Get-Content $processFile | ConvertFrom-Json
            
            $process = Get-Process -Id $processInfo.id -ErrorAction SilentlyContinue
            if ($process) {
                $process.Kill()
                Write-Host "🛑 Stopped $($processInfo.name) (PID: $($processInfo.id))" -ForegroundColor Yellow
            } else {
                Write-Host "⚠️  Process $($processInfo.id) not found for $($processInfo.name)" -ForegroundColor Yellow
            }
            
            Remove-Item $processFile -Force
            return $true
        } catch {
            Write-Host "❌ Failed to stop bot: $($_.Exception.Message)" -ForegroundColor Red
            return $false
        }
    } else {
        Write-Host "⚠️  No process file found for $botKey" -ForegroundColor Yellow
        return $false
    }
}

# Function to show bot status
function Show-BotStatus {
    Write-Host "`n📊 Auto Bots Status:" -ForegroundColor Cyan
    Write-Host "===================" -ForegroundColor Cyan
    
    $anyRunning = $false
    
    foreach ($botKey in $bots.Keys) {
        $processFile = "artifacts/auto-bots/$botKey-process.json"
        
        if (Test-Path $processFile) {
            try {
                $processInfo = Get-Content $processFile | ConvertFrom-Json
                $process = Get-Process -Id $processInfo.id -ErrorAction SilentlyContinue
                
                if ($process) {
                    $status = "🟢 Running"
                    $color = "Green"
                    $anyRunning = $true
                } else {
                    $status = "🔴 Stopped"
                    $color = "Red"
                }
                
                Write-Host "$status $($processInfo.name) (PID: $($processInfo.id))" -ForegroundColor $color
                Write-Host "   📝 $($processInfo.description)" -ForegroundColor Gray
                Write-Host "   ⏱️  Interval: $($processInfo.interval)" -ForegroundColor Gray
                Write-Host "   🕐 Started: $($processInfo.startTime)" -ForegroundColor Gray
                Write-Host ""
            } catch {
                Write-Host "❌ Error reading process info for $botKey" -ForegroundColor Red
            }
        } else {
            Write-Host "⚪ Not Running - $($bots[$botKey].name)" -ForegroundColor Gray
        }
    }
    
    if (-not $anyRunning) {
        Write-Host "No bots are currently running." -ForegroundColor Yellow
    }
}

# Function to stop all bots
function Stop-AllBots {
    Write-Host "🛑 Stopping all Auto Bots..." -ForegroundColor Yellow
    
    $stopped = 0
    foreach ($botKey in $bots.Keys) {
        if (Stop-Bot $botKey) {
            $stopped++
        }
    }
    
    Write-Host "✅ Stopped $stopped bots" -ForegroundColor Green
}

# Main execution
if (-not (Test-NodeJS)) {
    exit 1
}

if ($Stop) {
    Stop-AllBots
    exit 0
}

if ($Status) {
    Show-BotStatus
    exit 0
}

# Determine which bots to start
$botsToStart = @()

if ($All) {
    $botsToStart = $bots.Keys
} else {
    if ($HealthMonitor) { $botsToStart += 'health-monitor' }
    if ($AlertManager) { $botsToStart += 'alert-manager' }
    if ($DashboardRefresh) { $botsToStart += 'dashboard-refresh' }
    if ($ReportGenerator) { $botsToStart += 'report-generator' }
    if ($Cleanup) { $botsToStart += 'cleanup' }
}

# If no specific bots selected, start all
if ($botsToStart.Count -eq 0) {
    Write-Host "No specific bots selected. Starting all bots..." -ForegroundColor Yellow
    $botsToStart = $bots.Keys
}

# Start selected bots
$started = 0
foreach ($botKey in $botsToStart) {
    if (Start-Bot $botKey $bots[$botKey]) {
        $started++
    }
}

Write-Host "`n📋 Deployment Summary:" -ForegroundColor Cyan
Write-Host "=====================" -ForegroundColor Cyan
Write-Host "✅ Started: $started bots" -ForegroundColor Green
Write-Host "📊 Total bots available: $($bots.Count)" -ForegroundColor White

Write-Host "`n🎯 Next Steps:" -ForegroundColor Yellow
Write-Host "1. Check bot status: .\deploy-auto-bots.ps1 -Status" -ForegroundColor White
Write-Host "2. Stop all bots: .\deploy-auto-bots.ps1 -Stop" -ForegroundColor White
Write-Host "3. Monitor logs in: artifacts/auto-bots/" -ForegroundColor White
Write-Host "4. Check SigNoz UI: http://localhost:8080" -ForegroundColor White

Write-Host "`n🤖 Auto Bots Deployment Complete!" -ForegroundColor Green
