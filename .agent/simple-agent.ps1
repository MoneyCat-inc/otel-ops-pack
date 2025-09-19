param(
    [string]$TaskQueuePath = ".agent\\task_queue",
    [switch]$DryRun
)

Write-Host "== Simple Codex Agent Starting ==" -ForegroundColor Cyan

$pendingPath = Join-Path $TaskQueuePath "pending"
if (-not (Test-Path $pendingPath)) {
    Write-Host "[FAIL] Task queue directory not found: $pendingPath" -ForegroundColor Red
    exit 1
}

$pendingTasks = Get-ChildItem -Path $pendingPath -Filter *.json | Sort-Object LastWriteTime
if ($pendingTasks.Count -eq 0) {
    Write-Host "[OK] No pending tasks found" -ForegroundColor Green
    exit 0
}

foreach ($taskFile in $pendingTasks) {
    Write-Host "-- Processing: $($taskFile.Name) --" -ForegroundColor Yellow
    try {
        $task = Get-Content -Path $taskFile.FullName -Raw | ConvertFrom-Json
    } catch {
        Write-Host "[FAIL] Unable to read task JSON: $($_.Exception.Message)" -ForegroundColor Red
        if (-not $DryRun) {
            $failedPath = Join-Path $TaskQueuePath "failed"
            if (-not (Test-Path $failedPath)) { New-Item -ItemType Directory -Path $failedPath | Out-Null }
            Move-Item -Path $taskFile.FullName -Destination (Join-Path $failedPath $taskFile.Name)
        }
        continue
    }

    Write-Host "  Title : $($task.title)" -ForegroundColor White
    Write-Host "  Recipe: $($task.recipe)" -ForegroundColor Gray
    Write-Host "  Priority: $($task.priority)" -ForegroundColor Gray

    if ($DryRun) {
        Write-Host "  [DRY RUN] No state changes applied" -ForegroundColor Cyan
        continue
    }

    $processingPath = Join-Path $TaskQueuePath "processing"
    $completedPath = Join-Path $TaskQueuePath "completed"
    foreach ($path in @($processingPath, $completedPath)) {
        if (-not (Test-Path $path)) { New-Item -ItemType Directory -Path $path | Out-Null }
    }

    $processingFile = Join-Path $processingPath $taskFile.Name
    Move-Item -Path $taskFile.FullName -Destination $processingFile -Force

    $task.status = "completed"
    $task.completed_at = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    $task.assigned_to = "codex"
    $task.notes = "Processed by simple-agent"

    $updatedJson = $task | ConvertTo-Json -Depth 10
    $completedFile = Join-Path $completedPath $taskFile.Name
    $updatedJson | Out-File -FilePath $completedFile -Encoding ascii

    if (Test-Path $processingFile) {
        Remove-Item $processingFile -Force
    }

    Write-Host "  [OK] Task marked completed" -ForegroundColor Green
}

Write-Host "== Simple Codex Agent complete ==" -ForegroundColor Cyan


