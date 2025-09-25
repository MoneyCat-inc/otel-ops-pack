# Task Migration Script - Convert existing tasks to unified schema
# Migrates tasks from current format to ECRR-Agent compatible format

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("pending", "completed", "failed", "all")]
    [string]$Source = "pending",
    
    [Parameter(Mandatory=$false)]
    [string]$Target = "unified",
    
    [Parameter(Mandatory=$false)]
    [switch]$DryRun,
    
    [Parameter(Mandatory=$false)]
    [switch]$Validate
)

$TaskQueueDir = ".agent\task_queue"
$UnifiedDir = ".agent\task_queue\$Target"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] [$Level] $Message"
}

function Convert-TaskToUnified {
    param([object]$Task, [string]$SourceFile)
    
    # Generate new ID in T-YYYY-MM-DD-XXX format
    $date = Get-Date -Format "yyyy-MM-dd"
    $random = Get-Random -Minimum 100 -Maximum 999
    $newId = "T-$date-$random"
    
    # Map priority values
    $priorityMap = @{
        "critical" = "C"
        "high" = "H" 
        "medium" = "M"
        "low" = "L"
    }
    
    # Map type values
    $typeMap = @{
        "alert" = "alert"
        "maintenance" = "maintenance"
        "remediation" = "remediation"
    }
    
    # Create unified task structure
    $unifiedTask = @{
        id = $newId
        title = $Task.title
        goal = if ($Task.description) { $Task.description } else { $Task.title }
        description = $Task.description
        acceptance = @()
        scope = @{
            paths = @()
            excluded = @()
        }
        priority = if ($priorityMap.ContainsKey($Task.priority)) { $priorityMap[$Task.priority] } else { "M" }
        deadline = (Get-Date).AddDays(7).ToString("yyyy-MM-dd")
        tests = @()
        validation_commands = if ($Task.validation_commands) { $Task.validation_commands } else { @() }
        rollback_commands = if ($Task.rollback_commands) { $Task.rollback_commands } else { @() }
        expected_output = if ($Task.expected_output) { $Task.expected_output } else { "Task completed successfully" }
        type = if ($typeMap.ContainsKey($Task.type)) { $typeMap[$Task.type] } else { "task" }
        source = if ($Task.source) { $Task.source } else { "manual" }
        recipe = if ($Task.recipe) { $Task.recipe } else { $null }
        metrics = if ($Task.metrics) { $Task.metrics } else { @{} }
        assigned_to = if ($Task.assigned_to) { $Task.assigned_to } else { "codex" }
        status = "pending"
        created_at = if ($Task.created_at) { $Task.created_at } else { (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ") }
        original_id = $Task.id
        migration_source = $SourceFile
    }
    
    # Generate acceptance criteria from validation commands
    if ($Task.validation_commands) {
        foreach ($cmd in $Task.validation_commands) {
            if ($cmd -match "verify-pipeline") {
                $unifiedTask.acceptance += "Pipeline verification passes"
            } elseif ($cmd -match "verify-integration") {
                $unifiedTask.acceptance += "Integration verification passes"
            } elseif ($cmd -match "otelcol.*dry-run") {
                $unifiedTask.acceptance += "Collector configuration validates"
            } elseif ($cmd -match "curl.*13134") {
                $unifiedTask.acceptance += "Collector health endpoint responds"
            } else {
                $unifiedTask.acceptance += "Command '$cmd' executes successfully"
            }
        }
    } else {
        $unifiedTask.acceptance += "Task completed without errors"
    }
    
    # Generate scope paths from recipe and type
    if ($Task.recipe -eq "otlp_exporter_failure") {
        $unifiedTask.scope.paths += @("config.yaml", "scripts/verify-pipeline.ps1", "scripts/verify-integration.ps1")
    } elseif ($Task.recipe -eq "gpu_thermal") {
        $unifiedTask.scope.paths += @("scripts/gpu-monitor.ps1", "validation/validate-gpu-thermal.ps1")
    } elseif ($Task.source -eq "canary") {
        $unifiedTask.scope.paths += @("scripts/canary-check.ps1", "scripts/verify-pipeline.ps1")
    } else {
        $unifiedTask.scope.paths += @("config.yaml")
    }
    
    # Generate tests from validation commands
    if ($Task.validation_commands) {
        $unifiedTask.tests = $Task.validation_commands
    }
    
    return $unifiedTask
}

function Migrate-Tasks {
    Write-Log "Starting task migration (Source: $Source, Target: $Target, DryRun: $DryRun)"
    
    # Create target directory
    if (-not $DryRun) {
        New-Item -ItemType Directory -Path $UnifiedDir -Force | Out-Null
    }
    
    # Get source files
    $sourceDir = Join-Path $TaskQueueDir $Source
    if (-not (Test-Path $sourceDir)) {
        Write-Log "Source directory does not exist: $sourceDir" "ERROR"
        return
    }
    
    $sourceFiles = Get-ChildItem $sourceDir -Filter "*.json"
    if ($sourceFiles.Count -eq 0) {
        Write-Log "No tasks found in source directory: $sourceDir"
        return
    }
    
    Write-Log "Found $($sourceFiles.Count) tasks to migrate"
    
    $migratedCount = 0
    $failedCount = 0
    
    foreach ($file in $sourceFiles) {
        try {
            Write-Log "Processing task: $($file.Name)"
            
            # Read and parse task
            $taskJson = Get-Content $file.FullName -Raw
            $task = $taskJson | ConvertFrom-Json
            
            # Convert to unified format
            $unifiedTask = Convert-TaskToUnified -Task $task -SourceFile $file.Name
            
            # Generate output filename
            $outputFile = Join-Path $UnifiedDir "$($unifiedTask.id).json"
            
            if ($DryRun) {
                Write-Log "DRY RUN: Would create $outputFile"
                Write-Log "DRY RUN: Original ID: $($task.id) → New ID: $($unifiedTask.id)"
                Write-Log "DRY RUN: Acceptance criteria: $($unifiedTask.acceptance.Count) items"
                Write-Log "DRY RUN: Scope paths: $($unifiedTask.scope.paths.Count) items"
            } else {
                # Write unified task
                $unifiedTask | ConvertTo-Json -Depth 10 | Out-File $outputFile -Encoding utf8
                Write-Log "Migrated task: $($task.id) → $($unifiedTask.id)"
            }
            
            $migratedCount++
            
        } catch {
            Write-Log "Failed to migrate $($file.Name): $($_.Exception.Message)" "ERROR"
            $failedCount++
        }
    }
    
    Write-Log "Migration completed: $migratedCount successful, $failedCount failed"
}

function Validate-UnifiedTasks {
    Write-Log "Validating unified tasks"
    
    if (-not (Test-Path $UnifiedDir)) {
        Write-Log "Unified directory does not exist: $UnifiedDir" "ERROR"
        return
    }
    
    $unifiedFiles = Get-ChildItem $UnifiedDir -Filter "*.json"
    $validCount = 0
    $invalidCount = 0
    
    foreach ($file in $unifiedFiles) {
        try {
            $taskJson = Get-Content $file.FullName -Raw
            $task = $taskJson | ConvertFrom-Json
            
            # Validate required fields
            $requiredFields = @("id", "title", "goal", "acceptance", "scope", "priority", "type")
            $missingFields = @()
            
            foreach ($field in $requiredFields) {
                if (-not $task.PSObject.Properties.Name -contains $field) {
                    $missingFields += $field
                }
            }
            
            if ($missingFields.Count -eq 0) {
                Write-Log "✅ Valid: $($file.Name)"
                $validCount++
            } else {
                Write-Log "❌ Invalid: $($file.Name) - Missing: $($missingFields -join ', ')" "ERROR"
                $invalidCount++
            }
            
        } catch {
            Write-Log "❌ Parse error: $($file.Name) - $($_.Exception.Message)" "ERROR"
            $invalidCount++
        }
    }
    
    Write-Log "Validation completed: $validCount valid, $invalidCount invalid"
}

function Show-MigrationSummary {
    Write-Log "Migration Summary:"
    
    # Count tasks in each directory
    $pendingCount = (Get-ChildItem (Join-Path $TaskQueueDir "pending") -Filter "*.json" -ErrorAction SilentlyContinue).Count
    $unifiedCount = (Get-ChildItem $UnifiedDir -Filter "*.json" -ErrorAction SilentlyContinue).Count
    
    Write-Log "  Source (pending): $pendingCount tasks"
    Write-Log "  Target (unified): $unifiedCount tasks"
    
    if ($unifiedCount -gt 0) {
        Write-Log "  Migration ratio: $([math]::Round($unifiedCount / $pendingCount * 100, 1))%"
    }
}

# Main execution
if ($Validate) {
    Validate-UnifiedTasks
} else {
    Migrate-Tasks
    Show-MigrationSummary
}

Write-Log "Task migration completed"
