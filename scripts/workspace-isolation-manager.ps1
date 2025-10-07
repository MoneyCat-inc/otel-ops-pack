#Requires -Version 7.0

<#
.SYNOPSIS
    Workspace Isolation Manager for Bosscat Parallel Agent Framework
    Provides isolated workspaces for concurrent agent execution

.DESCRIPTION
    This module creates and manages isolated workspaces for parallel agents to prevent
    conflicts, file overwrites, and resource contention during concurrent execution.

.PARAMETER AgentId
    Unique identifier for the agent requiring workspace isolation

.PARAMETER WorkspaceType
    Type of workspace (temporary, persistent, shared, sandbox)

.PARAMETER ResourceLimits
    Resource limits for the workspace

.PARAMETER IsolationLevel
    Level of isolation (process, filesystem, network, full)

.EXAMPLE
    .\workspace-isolation-manager.ps1 -AgentId "agent-001" -WorkspaceType "temporary" -IsolationLevel "filesystem"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$AgentId,
    
    [ValidateSet('temporary', 'persistent', 'shared', 'sandbox')]
    [string]$WorkspaceType = 'temporary',
    
    [hashtable]$ResourceLimits = @{
        MaxDiskSpaceMB = 1024
        MaxMemoryMB = 512
        MaxCPUPercent = 50
        MaxProcessCount = 10
    },
    
    [ValidateSet('process', 'filesystem', 'network', 'full')]
    [string]$IsolationLevel = 'filesystem',
    
    [string]$WorkspaceRoot = 'artifacts/agent-workspaces',
    
    [switch]$EnableMonitoring,
    
    [switch]$CleanupOnExit,
    
    [int]$RetentionDays = 7
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Workspace Isolation Classes
class WorkspaceManager {
    [string]$RootPath
    [hashtable]$ActiveWorkspaces
    [hashtable]$ResourceMonitors
    
    WorkspaceManager([string]$rootPath) {
        $this.RootPath = $rootPath
        $this.ActiveWorkspaces = @{}
        $this.ResourceMonitors = @{}
        $this.InitializeRoot()
    }
    
    [void] InitializeRoot() {
        if (-not (Test-Path $this.RootPath)) {
            $null = New-Item -ItemType Directory -Path $this.RootPath -Force
            Write-Host "Created workspace root: $($this.RootPath)" -ForegroundColor Green
        }
        
        # Create subdirectories
        $subdirs = @('active', 'completed', 'failed', 'archived', 'monitoring')
        foreach ($subdir in $subdirs) {
            $path = Join-Path $this.RootPath $subdir
            if (-not (Test-Path $path)) {
                $null = New-Item -ItemType Directory -Path $path -Force
            }
        }
    }
    
    [object] CreateWorkspace([string]$agentId, [string]$type, [hashtable]$limits, [string]$isolationLevel) {
        $workspace = [Workspace]::new($agentId, $type, $limits, $isolationLevel, $this.RootPath)
        $this.ActiveWorkspaces[$agentId] = $workspace
        $workspace.Initialize()
        
        Write-Host "Created workspace for agent $agentId" -ForegroundColor Green
        Write-Host "  Type: $type" -ForegroundColor Gray
        Write-Host "  Isolation: $isolationLevel" -ForegroundColor Gray
        Write-Host "  Path: $($workspace.WorkspacePath)" -ForegroundColor Gray
        
        return $workspace
    }
    
    [void] CleanupWorkspace([string]$agentId) {
        if ($this.ActiveWorkspaces.ContainsKey($agentId)) {
            $workspace = $this.ActiveWorkspaces[$agentId]
            $workspace.Cleanup()
            $this.ActiveWorkspaces.Remove($agentId)
            Write-Host "Cleaned up workspace for agent $agentId" -ForegroundColor Yellow
        }
    }
    
    [void] MonitorResourceUsage([string]$agentId) {
        if ($this.ActiveWorkspaces.ContainsKey($agentId)) {
            $workspace = $this.ActiveWorkspaces[$agentId]
            $monitor = [ResourceMonitor]::new($workspace)
            $this.ResourceMonitors[$agentId] = $monitor
            $monitor.StartMonitoring()
        }
    }
    
    [void] StopResourceMonitoring([string]$agentId) {
        if ($this.ResourceMonitors.ContainsKey($agentId)) {
            $this.ResourceMonitors[$agentId].StopMonitoring()
            $this.ResourceMonitors.Remove($agentId)
        }
    }
    
    [object[]] GetActiveWorkspaces() {
        return $this.ActiveWorkspaces.Values
    }
    
    [void] CleanupOldWorkspaces([int]$retentionDays) {
        $cutoffDate = (Get-Date).AddDays(-$retentionDays)
        $completedPath = Join-Path $this.RootPath 'completed'
        $failedPath = Join-Path $this.RootPath 'failed'
        
        foreach ($path in @($completedPath, $failedPath)) {
            if (Test-Path $path) {
                $oldWorkspaces = Get-ChildItem $path -Directory | Where-Object { $_.CreationTime -lt $cutoffDate }
                foreach ($workspace in $oldWorkspaces) {
                    Remove-Item $workspace.FullName -Recurse -Force
                    Write-Host "Cleaned up old workspace: $($workspace.Name)" -ForegroundColor Gray
                }
            }
        }
    }
}

class Workspace {
    [string]$AgentId
    [string]$Type
    [hashtable]$ResourceLimits
    [string]$IsolationLevel
    [string]$RootPath
    [string]$WorkspacePath
    [hashtable]$Environment
    [datetime]$CreatedAt
    [string]$Status
    
      Workspace([string]$agentId, [string]$type, [hashtable]$limits, [string]$isolationLevel, [string]$rootPath) {
          $this.AgentId = $agentId
          $this.Type = $type
          $this.ResourceLimits = $limits
          $this.IsolationLevel = $isolationLevel
          $this.RootPath = $rootPath
          $this.Environment = @{}
          $this.CreatedAt = Get-Date
          $this.Status = 'initializing'
      }
    
    [void] Initialize() {
        # Create workspace directory
        $timestamp = $this.CreatedAt.ToString('yyyyMMdd-HHmmss')
        $this.WorkspacePath = Join-Path $this.RootPath 'active' "$($this.AgentId)-$timestamp"
        $null = New-Item -ItemType Directory -Path $this.WorkspacePath -Force
        
        # Create subdirectories based on workspace type
        $this.CreateSubdirectories()
        
        # Set up isolation based on level
        $this.SetupIsolation()
        
        # Configure environment
        $this.ConfigureEnvironment()
        
        $this.Status = 'ready'
    }
    
    [void] CreateSubdirectories() {
        $subdirs = switch ($this.Type) {
            'temporary' { @('data', 'logs', 'temp', 'output') }
            'persistent' { @('data', 'logs', 'config', 'cache', 'output', 'backup') }
            'shared' { @('data', 'logs', 'output', 'shared') }
            'sandbox' { @('data', 'logs', 'temp', 'output', 'sandbox') }
        }
        
        foreach ($subdir in $subdirs) {
            $path = Join-Path $this.WorkspacePath $subdir
            $null = New-Item -ItemType Directory -Path $path -Force
        }
        
        # Create workspace metadata
        $metadata = @{
            AgentId = $this.AgentId
            Type = $this.Type
            CreatedAt = $this.CreatedAt.ToString('o')
            IsolationLevel = $this.IsolationLevel
            ResourceLimits = $this.ResourceLimits
            WorkspacePath = $this.WorkspacePath
        }
        
        $metadataPath = Join-Path $this.WorkspacePath 'workspace-metadata.json'
        $metadata | ConvertTo-Json -Depth 5 | Out-File -FilePath $metadataPath -Encoding UTF8
    }
    
    [void] SetupIsolation() {
        switch ($this.IsolationLevel) {
            'filesystem' {
                $this.SetupFilesystemIsolation()
            }
            'process' {
                $this.SetupProcessIsolation()
            }
            'network' {
                $this.SetupNetworkIsolation()
            }
            'full' {
                $this.SetupFilesystemIsolation()
                $this.SetupProcessIsolation()
                $this.SetupNetworkIsolation()
            }
        }
    }
    
    [void] SetupFilesystemIsolation() {
        # Create isolated file system structure
        $isolatedPaths = @{
            'TEMP' = Join-Path $this.WorkspacePath 'temp'
            'TMP' = Join-Path $this.WorkspacePath 'temp'
            'LOCALAPPDATA' = Join-Path $this.WorkspacePath 'data'
            'APPDATA' = Join-Path $this.WorkspacePath 'data'
        }
        
        foreach ($key in $isolatedPaths.Keys) {
            $path = $isolatedPaths[$key]
            $null = New-Item -ItemType Directory -Path $path -Force
            $this.Environment[$key] = $path
        }
        
        # Create access control restrictions
        $this.CreateAccessControl()
    }
    
    [void] SetupProcessIsolation() {
        # Create process isolation configuration
        $processConfig = @{
            MaxProcessCount = $this.ResourceLimits.MaxProcessCount
            MaxMemoryMB = $this.ResourceLimits.MaxMemoryMB
            MaxCPUPercent = $this.ResourceLimits.MaxCPUPercent
            AllowedProcesses = @('pwsh.exe', 'node.exe', 'python.exe')
            BlockedProcesses = @('cmd.exe', 'powershell.exe', 'regedit.exe')
        }
        
        $configPath = Join-Path $this.WorkspacePath 'process-config.json'
        $processConfig | ConvertTo-Json -Depth 5 | Out-File -FilePath $configPath -Encoding UTF8
    }
    
    [void] SetupNetworkIsolation() {
        # Create network isolation configuration
        $networkConfig = @{
            AllowedHosts = @('localhost', '127.0.0.1', '::1')
            AllowedPorts = @(8080, 5317, 5318)  # SigNoz and OTLP ports
            BlockedProtocols = @('tcp/22', 'tcp/3389')  # SSH, RDP
            DNSResolution = 'local-only'
        }
        
        $configPath = Join-Path $this.WorkspacePath 'network-config.json'
        $networkConfig | ConvertTo-Json -Depth 5 | Out-File -FilePath $configPath -Encoding UTF8
    }
    
    [void] CreateAccessControl() {
        # Create access control configuration
        $accessControl = @{
            ReadOnlyPaths = @(
                Join-Path $this.WorkspacePath 'config'
            )
            RestrictedPaths = @(
                Join-Path $this.WorkspacePath 'backup'
            )
            AllowedExtensions = @('.ps1', '.json', '.md', '.txt', '.log', '.csv')
            BlockedExtensions = @('.exe', '.dll', '.bat', '.cmd', '.vbs')
        }
        
        $configPath = Join-Path $this.WorkspacePath 'access-control.json'
        $accessControl | ConvertTo-Json -Depth 5 | Out-File -FilePath $configPath -Encoding UTF8
    }
    
    [void] ConfigureEnvironment() {
        $this.Environment = @{
            'AGENT_ID' = $this.AgentId
            'WORKSPACE_PATH' = $this.WorkspacePath
            'WORKSPACE_TYPE' = $this.Type
            'ISOLATION_LEVEL' = $this.IsolationLevel
            'RESOURCE_LIMITS' = ($this.ResourceLimits | ConvertTo-Json -Compress)
        }
        
        # Set environment variables for the workspace
        $envPath = Join-Path $this.WorkspacePath 'environment.json'
        $this.Environment | ConvertTo-Json -Depth 5 | Out-File -FilePath $envPath -Encoding UTF8
    }
    
    [object] GetWorkspaceInfo() {
        return @{
            AgentId = $this.AgentId
            Type = $this.Type
            IsolationLevel = $this.IsolationLevel
            WorkspacePath = $this.WorkspacePath
            CreatedAt = $this.CreatedAt.ToString('o')
            Status = $this.Status
            ResourceLimits = $this.ResourceLimits
            Environment = $this.Environment
        }
    }
    
    [void] MoveToCompleted() {
        $this.MoveToStatus('completed')
    }
    
    [void] MoveToFailed() {
        $this.MoveToStatus('failed')
    }
    
    [void] MoveToArchived() {
        $this.MoveToStatus('archived')
    }
    
    [void] MoveToStatus([string]$status) {
        $targetPath = Join-Path $this.RootPath $status
        $newPath = Join-Path $targetPath (Split-Path $this.WorkspacePath -Leaf)
        
        if (Test-Path $this.WorkspacePath) {
            Move-Item -Path $this.WorkspacePath -Destination $newPath -Force
            $this.WorkspacePath = $newPath
        }
        
        $this.Status = $status
        
        # Update metadata
        $metadataPath = Join-Path $this.WorkspacePath 'workspace-metadata.json'
        if (Test-Path $metadataPath) {
            $metadata = Get-Content $metadataPath -Raw | ConvertFrom-Json
            $metadata.Status = $status
            $metadata.CompletedAt = (Get-Date).ToString('o')
            $metadata | ConvertTo-Json -Depth 5 | Out-File -FilePath $metadataPath -Encoding UTF8
        }
    }
    
    [void] Cleanup() {
        if ($this.Type -eq 'temporary') {
            if (Test-Path $this.WorkspacePath) {
                Remove-Item -Path $this.WorkspacePath -Recurse -Force
                Write-Host "Cleaned up temporary workspace: $($this.WorkspacePath)" -ForegroundColor Gray
            }
        } else {
            # Archive persistent workspaces
            $this.MoveToArchived()
        }
    }
}

class ResourceMonitor {
    [Workspace]$Workspace
    [System.Management.Automation.Job]$MonitorJob
    [bool]$IsMonitoring
    
    ResourceMonitor([Workspace]$workspace) {
        $this.Workspace = $workspace
        $this.IsMonitoring = $false
    }
    
    [void] StartMonitoring() {
        if ($this.IsMonitoring) { return }
        
        $monitorScript = {
            param($WorkspacePath, $ResourceLimits, $AgentId)
            
            while ($true) {
                try {
                    $usage = @{
                        Timestamp = (Get-Date).ToString('o')
                        AgentId = $AgentId
                        WorkspacePath = $WorkspacePath
                        DiskUsageMB = 0
                        MemoryUsageMB = 0
                        CPUUsagePercent = 0
                        ProcessCount = 0
                    }
                    
                    # Monitor disk usage
                    if (Test-Path $WorkspacePath) {
                        $diskUsage = (Get-ChildItem $WorkspacePath -Recurse -File | Measure-Object -Property Length -Sum).Sum / 1MB
                        $usage.DiskUsageMB = [Math]::Round($diskUsage, 2)
                    }
                    
                    # Monitor memory and CPU usage for agent processes
                    $processes = Get-Process | Where-Object { $_.ProcessName -like "*$AgentId*" -or $_.MainWindowTitle -like "*$AgentId*" }
                    if ($processes) {
                        $memoryUsage = ($processes | Measure-Object -Property WorkingSet64 -Sum).Sum / 1MB
                        $usage.MemoryUsageMB = [Math]::Round($memoryUsage, 2)
                        $usage.ProcessCount = $processes.Count
                        
                        # Estimate CPU usage (simplified)
                        $usage.CPUUsagePercent = [Math]::Min(100, ($processes.Count * 10))
                    }
                    
                    # Save usage data
                    $usagePath = Join-Path $WorkspacePath 'resource-usage.json'
                    $usage | ConvertTo-Json -Depth 5 | Out-File -FilePath $usagePath -Encoding UTF8
                    
                    # Check resource limits
                    if ($usage.DiskUsageMB -gt $ResourceLimits.MaxDiskSpaceMB) {
                        Write-Warning "Disk usage limit exceeded for agent ${AgentId}: $($usage.DiskUsageMB) MB > $($ResourceLimits.MaxDiskSpaceMB) MB"
                    }
                    
                    if ($usage.MemoryUsageMB -gt $ResourceLimits.MaxMemoryMB) {
                        Write-Warning "Memory usage limit exceeded for agent ${AgentId}: $($usage.MemoryUsageMB) MB > $($ResourceLimits.MaxMemoryMB) MB"
                    }
                    
                    if ($usage.CPUUsagePercent -gt $ResourceLimits.MaxCPUPercent) {
                        Write-Warning "CPU usage limit exceeded for agent ${AgentId}: $($usage.CPUUsagePercent)% > $($ResourceLimits.MaxCPUPercent)%"
                    }
                    
                    Start-Sleep -Seconds 30
                    
                } catch {
                    Write-Error "Resource monitoring error for agent ${AgentId}: $($_.Exception.Message)"
                    Start-Sleep -Seconds 60
                }
            }
        }
        
        $this.MonitorJob = Start-Job -ScriptBlock $monitorScript -ArgumentList $this.Workspace.WorkspacePath, $this.Workspace.ResourceLimits, $this.Workspace.AgentId
        $this.IsMonitoring = $true
        
        Write-Host "Started resource monitoring for agent $($this.Workspace.AgentId)" -ForegroundColor Green
    }
    
    [void] StopMonitoring() {
        if ($this.IsMonitoring -and $this.MonitorJob) {
            Stop-Job $this.MonitorJob
            Remove-Job $this.MonitorJob
            $this.IsMonitoring = $false
            Write-Host "Stopped resource monitoring for agent $($this.Workspace.AgentId)" -ForegroundColor Yellow
        }
    }
    
    [object] GetResourceUsage() {
        $usagePath = Join-Path $this.Workspace.WorkspacePath 'resource-usage.json'
        if (Test-Path $usagePath) {
            return Get-Content $usagePath -Raw | ConvertFrom-Json
        }
        return $null
    }
}

# Main execution
try {
    # Initialize workspace manager
    $manager = [WorkspaceManager]::new($WorkspaceRoot)
    
    # Create workspace for agent
    $workspace = $manager.CreateWorkspace($AgentId, $WorkspaceType, $ResourceLimits, $IsolationLevel)
    
    # Start resource monitoring if enabled
    if ($EnableMonitoring) {
        $manager.MonitorResourceUsage($AgentId)
    }
    
    # Output workspace information
    $workspaceInfo = $workspace.GetWorkspaceInfo()
    
    Write-Host "`n🎯 Workspace Isolation Complete" -ForegroundColor Green
    Write-Host "Agent ID: $AgentId" -ForegroundColor Cyan
    Write-Host "Workspace Type: $WorkspaceType" -ForegroundColor Cyan
    Write-Host "Isolation Level: $IsolationLevel" -ForegroundColor Cyan
    Write-Host "Workspace Path: $($workspace.WorkspacePath)" -ForegroundColor Gray
    Write-Host "Status: $($workspace.Status)" -ForegroundColor Green
    
    # Output environment variables for agent
    Write-Host "`n?? Environment Variables:" -ForegroundColor Yellow
    if ($workspaceInfo.Environment) {
        foreach ($entry in $workspaceInfo.Environment.GetEnumerator()) {
            Write-Host "  $($entry.Key) = $($entry.Value)" -ForegroundColor Gray
        }
    } else {
        Write-Host "  (Environment metadata unavailable)" -ForegroundColor Gray
    }
    
    # Output resource limits
    Write-Host "`n?? Resource Limits:" -ForegroundColor Yellow
    if ($ResourceLimits) {
        foreach ($entry in $ResourceLimits.GetEnumerator()) {
            Write-Host "  $($entry.Key) = $($entry.Value)" -ForegroundColor Gray
        }
    } else {
        Write-Host "  (No resource limits configured)" -ForegroundColor Gray
    }
    
    # Cleanup on exit if requested
    if ($CleanupOnExit) {
        Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action {
            param($workspace, $manager, $agentId)
            Write-Host "Cleaning up workspace on exit..." -ForegroundColor Yellow
            $manager.CleanupWorkspace($agentId)
        } -MaxTriggerCount 1
        
        # Store references for cleanup
        $global:WorkspaceCleanup = @{
            Workspace = $workspace
            Manager = $manager
            AgentId = $AgentId
        }
    }
    
    # Cleanup old workspaces
    $manager.CleanupOldWorkspaces($RetentionDays)
    
    # Return workspace information for use by calling scripts
    return $workspaceInfo
    
} catch {
    Write-Error "Workspace isolation failed: $($_.Exception.Message)"
    Write-Error $_.ScriptStackTrace
    exit 1
}

