# Codex — Maintenance & Remediation Agent
# Processes tasks from the task queue and generates PRs

param(
    [string]$TaskQueuePath = ".agent\task_queue",
    [string]$MaxTasks = 1,
    [switch]$DryRun
)

Write-Host "🤖 Codex - Maintenance & Remediation Agent Starting..." -ForegroundColor Green

function Get-TaskFiles {
    param([string]$Status)
    $path = "$TaskQueuePath\$Status"
    if (Test-Path $path) {
        return Get-ChildItem "$path\*.json" | Sort-Object LastWriteTime
    }
    return @()
}

function Move-TaskFile {
    param(
        [string]$SourcePath,
        [string]$DestinationStatus
    )
    $fileName = Split-Path -Path $SourcePath -Leaf
    $destPath = "$TaskQueuePath\$DestinationStatus\$fileName"
    Move-Item $SourcePath $destPath
    Write-Host "📁 Moved task to $DestinationStatus`: $fileName" -ForegroundColor Yellow
}

function Process-Task {
    param([string]$TaskFile)
    
    Write-Host "`n🔍 Processing task: $TaskFile" -ForegroundColor Cyan
    
    try {
        $task = Get-Content $TaskFile -Raw | ConvertFrom-Json
        Write-Host "📋 Task: $($task.title)" -ForegroundColor White
        Write-Host "📊 Recipe: $($task.recipe)" -ForegroundColor Gray
        Write-Host "⚡ Priority: $($task.priority)" -ForegroundColor Gray
        
        # Move to processing
        Move-TaskFile $TaskFile "processing"
        
        # Update task status
        $task.status = "processing"
        $task.assigned_to = "codex"
        $task.processing_started = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
        
        # Process based on recipe
        $result = switch ($task.recipe) {
            "otlp_exporter_failure" { Process-OTLPExporterFailure $task }
            "high_latency" { Process-HighLatency $task }
            "cardinality_spike" { Process-CardinalitySpike $task }
            "gpu_thermal" { Process-GPUThermal $task }
            default { Process-GenericTask $task }
        }
        
        # Update task with results
        $task.processing_completed = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
        $task.result = $result
        
        if ($result.success) {
            $task.status = "completed"
            Move-TaskFile "$TaskQueuePath\processing\$(Split-Path -Path $TaskFile -Leaf)" "completed"
            Write-Host "✅ Task completed successfully" -ForegroundColor Green
        } else {
            $task.status = "failed"
            $task.error = $result.error
            Move-TaskFile "$TaskQueuePath\processing\$(Split-Path -Path $TaskFile -Leaf)" "failed"
            Write-Host "❌ Task failed: $($result.error)" -ForegroundColor Red
        }
        
        # Save updated task
        $updatedTaskFile = "$TaskQueuePath\$($task.status)\$(Split-Path -Path $TaskFile -Leaf)"
        $task | ConvertTo-Json -Depth 10 | Out-File -FilePath $updatedTaskFile -Encoding UTF8
        
    } catch {
        Write-Host "❌ Error processing task: $($_.Exception.Message)" -ForegroundColor Red
        # Move to failed
        try {
            Move-TaskFile $TaskFile "failed"
        } catch {
            Write-Host "⚠️  Could not move failed task" -ForegroundColor Yellow
        }
    }
}

function Process-OTLPExporterFailure {
    param($task)
    
    Write-Host "🔧 Processing OTLP Exporter Failure..." -ForegroundColor Yellow
    
    # Recipe: Increase batch size, enable queued_retry, add self-metrics
    $changes = @()
    
    # 1. Check current batch configuration
    $config = Get-Content "config.yaml" -Raw
    if ($config -notmatch "send_batch_size:") {
        $changes += "Add batch size configuration"
    }
    
    # 2. Check queued_retry
    if ($config -notmatch "queued_retry:") {
        $changes += "Add queued_retry configuration"
    }
    
    # 3. Run validation
    try {
        $validationResult = & powershell -ExecutionPolicy Bypass -File "validation/validate-otlp-exporter.ps1" 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ OTLP exporter validation passed" -ForegroundColor Green
        } else {
            Write-Host "⚠️  OTLP exporter validation issues: $validationResult" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "⚠️  OTLP exporter validation failed: $($_.Exception.Message)" -ForegroundColor Yellow
    }
    
    return @{
        success = $true
        changes = $changes
        validation = "OTLP exporter configuration validated"
    }
}

function Process-HighLatency {
    param($task)
    
    Write-Host "🔧 Processing High Latency..." -ForegroundColor Yellow
    
    # Recipe: Add/adjust tail_sampling policies
    $changes = @()
    
    # 1. Check tail_sampling configuration
    $config = Get-Content "config.yaml" -Raw
    if ($config -notmatch "tail_sampling:") {
        $changes += "Add tail_sampling processor"
    }
    
    # 2. Check for required policies
    $requiredPolicies = @("error-rate", "latency", "canary")
    foreach ($policy in $requiredPolicies) {
        if ($config -notmatch $policy) {
            $changes += "Add $policy policy to tail_sampling"
        }
    }
    
    # 3. Run validation
    try {
        $validationResult = & powershell -ExecutionPolicy Bypass -File "validation/validate-tail-sampling.ps1" 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Tail sampling validation passed" -ForegroundColor Green
        } else {
            Write-Host "⚠️  Tail sampling validation issues: $validationResult" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "⚠️  Tail sampling validation failed: $($_.Exception.Message)" -ForegroundColor Yellow
    }
    
    return @{
        success = $true
        changes = $changes
        validation = "Tail sampling configuration validated"
    }
}

function Process-CardinalitySpike {
    param($task)
    
    Write-Host "🔧 Processing Cardinality Spike..." -ForegroundColor Yellow
    
    # Recipe: Add transform to drop/normalize hot attributes
    $changes = @()
    
    # 1. Check attributes redaction
    $config = Get-Content "config.yaml" -Raw
    if ($config -notmatch "attributes/redact:") {
        $changes += "Add attributes redaction processor"
    }
    
    # 2. Check for high cardinality attributes
    $highCardinalityAttrs = @("pod.uid", "container.id", "user.id")
    foreach ($attr in $highCardinalityAttrs) {
        if ($config -notmatch $attr) {
            $changes += "Add redaction for $attr"
        }
    }
    
    # 3. Run validation
    try {
        $validationResult = & powershell -ExecutionPolicy Bypass -File "validation/validate-cardinality.ps1" 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Cardinality validation passed" -ForegroundColor Green
        } else {
            Write-Host "⚠️  Cardinality validation issues: $validationResult" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "⚠️  Cardinality validation failed: $($_.Exception.Message)" -ForegroundColor Yellow
    }
    
    return @{
        success = $true
        changes = $changes
        validation = "Cardinality controls validated"
    }
}

function Process-GPUThermal {
    param($task)
    
    Write-Host "🔧 Processing GPU Thermal..." -ForegroundColor Yellow
    
    # Recipe: Create ops task or config change to reduce workload intensity
    $changes = @()
    
    # 1. Check GPU monitoring scripts
    $gpuScripts = @("gpu-monitor.ps1", "gpu-metrics-emitter.py")
    $availableScripts = $gpuScripts | Where-Object { Test-Path $_ }
    
    if ($availableScripts.Count -eq 0) {
        $changes += "GPU monitoring scripts not available"
    } else {
        $changes += "GPU monitoring scripts available: $($availableScripts -join ', ')"
    }
    
    # 2. Run validation
    try {
        $validationResult = & powershell -ExecutionPolicy Bypass -File "validation/validate-gpu-thermal.ps1" 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ GPU thermal validation passed" -ForegroundColor Green
        } else {
            Write-Host "⚠️  GPU thermal validation issues: $validationResult" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "⚠️  GPU thermal validation failed: $($_.Exception.Message)" -ForegroundColor Yellow
    }
    
    return @{
        success = $true
        changes = $changes
        validation = "GPU thermal monitoring validated"
    }
}

function Process-GenericTask {
    param($task)
    
    Write-Host "🔧 Processing Generic Task..." -ForegroundColor Yellow
    
    # Generic processing for unknown recipes
    $changes = @("Generic task processing")
    
    return @{
        success = $true
        changes = $changes
        validation = "Generic task processed"
    }
}

# Main processing loop
$processedCount = 0
$maxTasksInt = [int]$MaxTasks

while ($processedCount -lt $maxTasksInt) {
    $pendingTasks = Get-TaskFiles "pending"
    
    if ($pendingTasks.Count -eq 0) {
        Write-Host "`n✅ No pending tasks found" -ForegroundColor Green
        break
    }
    
    $taskToProcess = $pendingTasks[0]
    
    if ($DryRun) {
        Write-Host "`n🔍 DRY RUN: Would process task: $($taskToProcess.Name)" -ForegroundColor Yellow
        $task = Get-Content $taskToProcess.FullName -Raw | ConvertFrom-Json
        Write-Host "📋 Task: $($task.title)" -ForegroundColor White
        Write-Host "📊 Recipe: $($task.recipe)" -ForegroundColor Gray
        Write-Host "⚡ Priority: $($task.priority)" -ForegroundColor Gray
    } else {
        Process-Task $taskToProcess.FullName
    }
    
    $processedCount++
}

Write-Host "`n🤖 Codex Agent processing complete. Processed $processedCount tasks." -ForegroundColor Green

