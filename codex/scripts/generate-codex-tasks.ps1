# generate-codex-tasks.ps1
# Reads the most recent health_alerts_*.json file, generates a codex task description 
# for each breach, and writes it into .agent/task_queue/codex_tasks.json

Write-Host "=== Generating codex tasks from alerts ===" -ForegroundColor Cyan

$alertsDir   = "gpu\monitoring\alerts"
$queueDir    = ".agent\task_queue"
$queueFile   = Join-Path $queueDir "codex_tasks.json"

if (-not (Test-Path $alertsDir)) {
    Write-Host "Alerts directory not found: $alertsDir" -ForegroundColor Yellow
    return
}

# Find the latest alerts file
$latestAlert = Get-ChildItem $alertsDir -Filter "health_alerts_*.json" |
                Sort-Object LastWriteTime -Descending |
                Select-Object -First 1

if (-not $latestAlert) {
    Write-Host "No alert files found. Nothing to enqueue." -ForegroundColor Yellow
    return
}

# Load alerts
try {
    $alertPayload = Get-Content $latestAlert.FullName -Raw | ConvertFrom-Json
} catch {
    Write-Warning "Failed to read alerts file: $($_.Exception.Message)"
    return
}

$alertItems = @()
if ($null -ne $alertPayload.alerts) {
    $alertItems = @($alertPayload.alerts) | ForEach-Object { $_ }
} elseif ($alertPayload -is [System.Collections.IEnumerable]) {
    $alertItems = @($alertPayload) | ForEach-Object { $_ }
} elseif ($alertPayload) {
    $alertItems = @($alertPayload)
}

if (-not $alertItems -or $alertItems.Count -eq 0) {
    Write-Host "No alerts detected. System healthy." -ForegroundColor Green
    return
}

# Prepare codex tasks
$codexTasks = @()
foreach ($alert in $alertItems) {
    $component = if ($alert.component) { $alert.component } else { 'overall-health' }
    $metric    = if ($alert.metric)    { $alert.metric }    else { 'health_score' }
    $message   = if ($alert.message)   { $alert.message }   else { 'Health alert generated.' }
    $severity  = if ($alert.severity)  { $alert.severity }  else { 'WARNING' }

    $description = ("Alert '{0}' triggered for {1}/{2}: {3}`nPlease investigate and propose remediation steps." -f $severity, $component, $metric, $message)

    $task = [ordered]@{
        id            = [guid]::NewGuid().ToString()
        name          = "remediate-$component-$metric"
        severity      = $severity
        description   = $description
        source_alert  = $latestAlert.Name
        files_to_edit = @()
    }

    if ($alert.details) {
        $task.details = $alert.details
    }

    $codexTasks += $task
}

# Ensure queue directory exists
[System.IO.Directory]::CreateDirectory($queueDir) | Out-Null

# Write to queue
$codexTasks | ConvertTo-Json -Depth 5 | Out-File -FilePath $queueFile -Encoding UTF8
Write-Host "Enqueued $($codexTasks.Count) task(s) to $queueFile" -ForegroundColor Green