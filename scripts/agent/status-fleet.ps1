# scripts/agent/status-fleet.ps1 - Fleet status aggregation across repositories

param(
    [string]$RootPath = "..",
    [switch]$Json,
    [switch]$Verbose,
    [int]$MaxDepth = 3
)

$ErrorActionPreference = "Stop"

function Write-FleetResult {
    param(
        [string]$Message,
        [bool]$Success = $true
    )
    
    $color = if ($Success) { "Green" } else { "Red" }
    $icon = if ($Success) { "✅" } else { "❌" }
    Write-Host "$icon $Message" -ForegroundColor $color
}

function Get-RepositoryStatus {
    param(
        [string]$RepoPath
    )
    
    try {
        $statusFile = Join-Path $RepoPath ".agent\status.json"
        if (-not (Test-Path $statusFile)) {
            return $null
        }
        
        $statusContent = Get-Content $statusFile -Raw
        $status = $statusContent | ConvertFrom-Json
        
        # Extract repository name from path
        $repoName = Split-Path $RepoPath -Leaf
        
        return @{
            name = $repoName
            path = $RepoPath
            state = $status.state ?? "unknown"
            lock = $status.lock ?? $false
            lastUpdate = $status.lastUpdate ?? $status.timestamp ?? "unknown"
            sections = $status.sections ?? @{}
            queue = $status.queue ?? @{}
            health = if ($status.sections) {
                $healthySections = ($status.sections.PSObject.Properties | Where-Object { $_.Value.ok -eq $true }).Count
                $totalSections = $status.sections.PSObject.Properties.Count
                if ($totalSections -gt 0) { [Math]::Round(($healthySections / $totalSections) * 100) } else { 0 }
            } else { 0 }
            errors = $status.errors ?? @()
        }
    } catch {
        return @{
            name = Split-Path $RepoPath -Leaf
            path = $RepoPath
            state = "error"
            lock = $false
            lastUpdate = "unknown"
            sections = @{}
            queue = @{}
            health = 0
            errors = @($_.Exception.Message)
        }
    }
}

function Get-FleetHealth {
    param(
        [array]$Repositories
    )
    
    $total = $Repositories.Count
    $running = ($Repositories | Where-Object { $_.state -eq "running" }).Count
    $locked = ($Repositories | Where-Object { $_.state -eq "locked" -or $_.lock -eq $true }).Count
    $error = ($Repositories | Where-Object { $_.state -eq "error" }).Count
    $unknown = ($Repositories | Where-Object { $_.state -eq "unknown" }).Count
    
    $avgHealth = if ($total -gt 0) { 
        [Math]::Round(($Repositories | Measure-Object -Property health -Average).Average, 1) 
    } else { 0 }
    
    return @{
        total = $total
        running = $running
        locked = $locked
        error = $error
        unknown = $unknown
        average_health = $avgHealth
        overall_status = if ($error -gt 0) { "degraded" } 
                       elseif ($locked -gt ($total * 0.5)) { "maintenance" }
                       elseif ($running -eq $total) { "healthy" }
                       else { "partial" }
    }
}

# Import hardening utilities
. "$PSScriptRoot\utils\output-guard.ps1" -Json:$Json

if (-not $Json) {
    Write-Host "🌍 codex-local Fleet Status" -ForegroundColor Cyan
    Write-Host "============================" -ForegroundColor Cyan
}

# Discover repositories
if (-not $Json) {
    Write-Host "`n🔍 Discovering repositories..." -ForegroundColor Yellow
}

$repositories = @()
$searchPaths = @($RootPath)

# Search for repositories with .agent directories
for ($depth = 0; $depth -lt $MaxDepth; $depth++) {
    $currentPaths = @()
    foreach ($path in $searchPaths) {
        if (Test-Path $path) {
            $agentDirs = Get-ChildItem -Path $path -Directory -Name ".agent" -ErrorAction SilentlyContinue
            foreach ($agentDir in $agentDirs) {
                $repoPath = Join-Path $path (Split-Path $agentDir -Parent)
                if ($repoPath -notin $repositories.path) {
                    $status = Get-RepositoryStatus -RepoPath $repoPath
                    if ($status) {
                        $repositories += $status
                        if (-not $Json) {
                            Write-FleetResult -Message "Found repository: $($status.name) ($($status.state))"
                        }
                    }
                }
            }
            
            # Add subdirectories for next iteration
            $subdirs = Get-ChildItem -Path $path -Directory -ErrorAction SilentlyContinue
            foreach ($subdir in $subdirs) {
                if ($subdir.Name -ne ".agent" -and $subdir.Name -notlike ".*") {
                    $currentPaths += $subdir.FullName
                }
            }
        }
    }
    $searchPaths = $currentPaths
}

if ($repositories.Count -eq 0) {
    Write-FleetResult -Message "No repositories with .agent directories found" -Success $false
    exit 1
}

# Calculate fleet health
$fleetHealth = Get-FleetHealth -Repositories $repositories

# JSON output mode
if ($Json) {
    $jsonOutput = @{
        fleet_health = $fleetHealth
        repositories = $repositories
        discovered_at = (Get-Date).ToString("o")
        search_root = $RootPath
        max_depth = $MaxDepth
    }
    
    $jsonOutput | ConvertTo-Json -Depth 5
    exit $(if ($fleetHealth.overall_status -eq "healthy") { 0 } else { 1 })
}

# Display fleet summary
Write-Host "`n📊 Fleet Summary:" -ForegroundColor White
Write-Host "   Total Repositories: $($fleetHealth.total)" -ForegroundColor Gray
Write-Host "   Running: $($fleetHealth.running)" -ForegroundColor Green
Write-Host "   Locked: $($fleetHealth.locked)" -ForegroundColor Yellow
Write-Host "   Errors: $($fleetHealth.error)" -ForegroundColor Red
Write-Host "   Unknown: $($fleetHealth.unknown)" -ForegroundColor Gray
Write-Host "   Average Health: $($fleetHealth.average_health)%" -ForegroundColor Cyan

# Overall status
$statusColor = switch ($fleetHealth.overall_status) {
    "healthy" { "Green" }
    "partial" { "Yellow" }
    "maintenance" { "Cyan" }
    "degraded" { "Red" }
    default { "Gray" }
}

Write-Host "`n🎯 Overall Fleet Status: " -NoNewline
Write-Host $fleetHealth.overall_status.ToUpper() -ForegroundColor $statusColor

# Repository details
Write-Host "`n📋 Repository Details:" -ForegroundColor White
foreach ($repo in $repositories | Sort-Object name) {
    $stateColor = switch ($repo.state) {
        "running" { "Green" }
        "locked" { "Yellow" }
        "error" { "Red" }
        default { "Gray" }
    }
    
    Write-Host "   $($repo.name): " -NoNewline
    Write-Host $repo.state -ForegroundColor $stateColor -NoNewline
    Write-Host " (Health: $($repo.health)%)" -ForegroundColor Gray
    
    if ($repo.errors.Count -gt 0 -and $Verbose) {
        foreach ($error in $repo.errors) {
            Write-Host "     Error: $error" -ForegroundColor Red
        }
    }
}

# Health distribution
Write-Host "`n📈 Health Distribution:" -ForegroundColor White
$healthRanges = @(
    @{ min = 90; max = 100; label = "Excellent (90-100%)"; color = "Green" },
    @{ min = 70; max = 89; label = "Good (70-89%)"; color = "Yellow" },
    @{ min = 50; max = 69; label = "Fair (50-69%)"; color = "Magenta" },
    @{ min = 0; max = 49; label = "Poor (0-49%)"; color = "Red" }
)

foreach ($range in $healthRanges) {
    $count = ($repositories | Where-Object { $_.health -ge $range.min -and $_.health -le $range.max }).Count
    Write-Host "   $($range.label): $count" -ForegroundColor $range.color
}

# Recommendations
Write-Host "`n💡 Recommendations:" -ForegroundColor Cyan
if ($fleetHealth.error -gt 0) {
    Write-Host "   • Investigate repositories with errors" -ForegroundColor Red
}
if ($fleetHealth.locked -gt ($fleetHealth.total * 0.3)) {
    Write-Host "   • Consider unlocking repositories for maintenance" -ForegroundColor Yellow
}
if ($fleetHealth.average_health -lt 80) {
    Write-Host "   • Review overall fleet health and configuration" -ForegroundColor Yellow
}
if ($fleetHealth.overall_status -eq "healthy") {
    Write-Host "   • Fleet is healthy - continue monitoring" -ForegroundColor Green
}

Write-Host "`n🎉 Fleet Status Check Complete" -ForegroundColor Green
exit $(if ($fleetHealth.overall_status -eq "healthy") { 0 } else { 1 })
