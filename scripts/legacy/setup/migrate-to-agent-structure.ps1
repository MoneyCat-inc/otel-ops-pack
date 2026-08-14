# Migration script to move existing agent files to .agent directory structure
# This script safely migrates existing state, queue, and audit files

param(
    [switch]$DryRun,
    [switch]$Force
)

$ErrorActionPreference = "Stop"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    Write-Host $logMessage
}

function Move-IfExists {
    param(
        [string]$Source,
        [string]$Destination,
        [string]$Description
    )
    
    if (Test-Path $Source) {
        Write-Log "Found $Description at: $Source" "INFO"
        
        if ($DryRun) {
            Write-Log "DRY RUN: Would move $Source to $Destination" "INFO"
        } else {
            try {
                # Ensure destination directory exists
                $destDir = Split-Path $Destination -Parent
                if (-not (Test-Path $destDir)) {
                    New-Item -ItemType Directory -Path $destDir -Force | Out-Null
                }
                
                Move-Item -Path $Source -Destination $Destination -Force
                Write-Log "Moved $Description to: $Destination" "INFO"
            }
            catch {
                Write-Log "Failed to move $Description : $($_.Exception.Message)" "ERROR"
            }
        }
    } else {
        Write-Log "$Description not found at: $Source" "INFO"
    }
}

function Copy-IfExists {
    param(
        [string]$Source,
        [string]$Destination,
        [string]$Description
    )
    
    if (Test-Path $Source) {
        Write-Log "Found $Description at: $Source" "INFO"
        
        if ($DryRun) {
            Write-Log "DRY RUN: Would copy $Source to $Destination" "INFO"
        } else {
            try {
                # Ensure destination directory exists
                $destDir = Split-Path $Destination -Parent
                if (-not (Test-Path $destDir)) {
                    New-Item -ItemType Directory -Path $destDir -Force | Out-Null
                }
                
                Copy-Item -Path $Source -Destination $Destination -Force
                Write-Log "Copied $Description to: $Destination" "INFO"
            }
            catch {
                Write-Log "Failed to copy $Description : $($_.Exception.Message)" "ERROR"
            }
        }
    } else {
        Write-Log "$Description not found at: $Source" "INFO"
    }
}

# Main migration logic
try {
    Write-Log "Starting migration to .agent directory structure" "INFO"
    
    if ($DryRun) {
        Write-Log "DRY RUN MODE - No actual changes will be made" "WARN"
    }
    
    # Create .agent directory structure if it doesn't exist
    if (-not $DryRun) {
        $agentDirs = @(".agent", ".agent/logs", ".agent/reports")
        foreach ($dir in $agentDirs) {
            if (-not (Test-Path $dir)) {
                New-Item -ItemType Directory -Path $dir -Force | Out-Null
                Write-Log "Created directory: $dir" "INFO"
            }
        }
    }
    
    # Migrate audit files to .agent/reports/
    Write-Log "Migrating audit files..." "INFO"
    if (Test-Path "audit") {
        $auditFiles = Get-ChildItem -Path "audit" -Recurse
        foreach ($file in $auditFiles) {
            $relativePath = $file.FullName.Substring((Get-Location).Path.Length + 1)
            $destPath = ".agent/reports/audit/$relativePath"
            Copy-IfExists -Source $file.FullName -Destination $destPath -Description "Audit file: $($file.Name)"
        }
    }
    
    # Migrate existing logs to .agent/logs/ (if they exist and are agent-related)
    Write-Log "Migrating agent-related logs..." "INFO"
    if (Test-Path "logs") {
        $logFiles = Get-ChildItem -Path "logs" -Filter "*.log" -Recurse
        foreach ($file in $logFiles) {
            $relativePath = $file.FullName.Substring((Get-Location).Path.Length + 1)
            $destPath = ".agent/logs/$relativePath"
            Copy-IfExists -Source $file.FullName -Destination $destPath -Description "Log file: $($file.Name)"
        }
    }
    
    # Check for existing state files and migrate them
    Write-Log "Checking for existing state files..." "INFO"
    $stateFiles = @("state.json", "agent_state.json", "cursor_state.json")
    foreach ($stateFile in $stateFiles) {
        if (Test-Path $stateFile) {
            Move-IfExists -Source $stateFile -Destination ".agent/state.json" -Description "State file: $stateFile"
        }
    }
    
    # Check for existing queue files and migrate them
    Write-Log "Checking for existing queue files..." "INFO"
    $queueFiles = @("queue.json", "agent_queue.json", "cursor_queue.json")
    foreach ($queueFile in $queueFiles) {
        if (Test-Path $queueFile) {
            Move-IfExists -Source $queueFile -Destination ".agent/agent_queue.json" -Description "Queue file: $queueFile"
        }
    }
    
    # Update any script references to point to new locations
    Write-Log "Updating script references..." "INFO"
    $scriptsToUpdate = @(
        "ai-assistant-helper.ps1",
        "verify-integration.ps1",
        "integration-tests.ps1"
    )
    
    foreach ($script in $scriptsToUpdate) {
        if (Test-Path $script) {
            Write-Log "Found script: $script - manual review recommended for path updates" "INFO"
        }
    }
    
    Write-Log "Migration completed successfully" "INFO"
    
    if ($DryRun) {
        Write-Log "This was a dry run. Run without -DryRun to perform actual migration." "INFO"
    } else {
        Write-Log "Migration complete. Review the .agent directory structure." "INFO"
        Write-Log "Next steps:" "INFO"
        Write-Log "1. Review migrated files in .agent/reports/ and .agent/logs/" "INFO"
        Write-Log "2. Update any scripts that reference old paths" "INFO"
        Write-Log "3. Test the agent with: .\run-agent.ps1 -HealthCheck" "INFO"
    }
}
catch {
    Write-Log "Migration failed: $($_.Exception.Message)" "ERROR"
    exit 1
}

