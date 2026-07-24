# HISTORICAL (Gate-era): ports 5317/5318 predate the 5320/5321 move. Do not use as reference. See windows/otelcol/README.md.
# scripts/agent/health-gate.ps1
# Inline health validation for agent:start integration
# Runs local env doctor + OTel wiring check, enqueues daily job if both pass

$ErrorActionPreference = "Stop"

Write-Host "[health-gate] Starting integrated health validation..."

# 1) Your local env doctor
Write-Host "[health-gate] Running local environment doctor..."
try {
    pnpm agent:doctor | Write-Host
    Write-Host "[health-gate] Local environment: OK"
} catch {
    Write-Host "[health-gate] Local environment: FAILED - $($_.Exception.Message)"
    exit 1
}

# 2) OTel wiring health
Write-Host "[health-gate] Running OTel wiring verification..."
try {
    pwsh -File scripts/verify-wiring.ps1 | Tee-Object -FilePath artifacts/wiring-verify.log
    Write-Host "[health-gate] OTel wiring: OK"
} catch {
    Write-Host "[health-gate] OTel wiring: FAILED - $($_.Exception.Message)"
    exit 1
}

# 3) Verify OTel check actually passed
if (-not (Test-Path "artifacts/wiring-verify.txt")) {
    Write-Host "[health-gate] OTel verification artifacts missing"
    exit 1
}

$verifyContent = Get-Content "artifacts/wiring-verify.txt" -Raw
if ($verifyContent -notmatch "== Wiring verification (PASSED|PARTIAL) ==") {
    Write-Host "[health-gate] OTel wiring verification failed; not enqueuing monitoring job."
    Write-Host "[health-gate] Last 10 lines of verification:"
    $verifyContent -split "`n" | Select-Object -Last 10 | ForEach-Object { Write-Host "  $_" }
    exit 1
}

# 4) Enqueue daily otel job if not present
$queuePath = ".agent/agent_queue.json"
if (-not (Test-Path $queuePath)) { 
    Write-Host "[health-gate] Creating agent queue..."
    '{"version":1,"lastRun":null,"jobs":[]}' | Set-Content $queuePath 
}

$queue = Get-Content $queuePath -Raw | ConvertFrom-Json
if (-not ($queue.jobs | Where-Object { $_.id -eq "otel-wiring-check" })) {
    Write-Host "[health-gate] Enqueuing daily otel-wiring-check job..."
    $job = [pscustomobject]@{
        id = "otel-wiring-check"
        type = "health-check"
        command = "pwsh -File scripts/verify-wiring.ps1"
        schedule = "RRULE:FREQ=DAILY;BYHOUR=9;BYMINUTE=0;BYSECOND=0"
        deps = @("env-ready")
        ttlMs = 86400000
        attempts = 0
        maxAttempts = 3
        backoffMs = 900000
        status = "queued"
        lastResult = $null
    }
    $queue.jobs += $job
    ($queue | ConvertTo-Json -Depth 6) | Set-Content $queuePath
    Write-Host "[health-gate] Daily otel-wiring-check job enqueued."
} else {
    Write-Host "[health-gate] Daily otel-wiring-check job already exists."
}

# 5) Update shared status
Write-Host "[health-gate] Updating shared status..."
try {
    pwsh -File scripts/agent/update-status.ps1 -section env -ok $true -detail "pnpm, node, playwright: OK"
    pwsh -File scripts/agent/update-status.ps1 -section otel -ok $true -detail "OTLP/HTTP 5318 reachable; dataset logs present"
    Write-Host "[health-gate] Status updated successfully."
} catch {
    Write-Host "[health-gate] Status update failed: $($_.Exception.Message)"
    # Don't fail the whole process for status update issues
}

Write-Host "[health-gate] Health validation completed successfully."
Write-Host "[health-gate] Ready for agent:start watchdog process."
