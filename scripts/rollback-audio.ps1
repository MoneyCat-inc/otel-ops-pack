# Gate #021 - BOSSCAT-021A - Audio Rollback Script (Rewritten)
# ECRR: BossCat OEM | Executor: Cursor{Implementer}
# Purpose: One-click audio rollback with verification via AudioSwitch
# GATE-020-R1: Multi-replica container discovery for scaled pm-engine

param(
    [string]$BaseUrl = "http://localhost:7020",
    [string]$AdminToken = $env:ADMIN_TOKEN,
    [string]$Service = "",  # Auto-detect if empty
    [int]$VerifyTimeoutSec = 15
)

$ErrorActionPreference = "Stop"

Write-Host "🔄 Audio Rollback Script (BOSSCAT-021A + GATE-020-R1)" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# GATE-020-R1: Detect pm-engine replica containers
if ([string]::IsNullOrEmpty($Service)) {
    Write-Host "[0/4] Detecting pm-engine containers..." -ForegroundColor White
    $containers = docker ps --filter "name=pm-engine" --format "{{.Names}}" | Where-Object { $_ -match "pm-engine" }
    
    if ($containers) {
        if ($containers -is [array]) {
            $Service = $containers[0]  # Use first replica
            Write-Host "  → Found $($containers.Count) replicas, using: $Service" -ForegroundColor Gray
        } else {
            $Service = $containers
            Write-Host "  → Found single container: $Service" -ForegroundColor Gray
        }
    } else {
        Write-Host "  ✗ No pm-engine containers found!" -ForegroundColor Red
        Write-Host "  → Run: docker ps | grep pm-engine" -ForegroundColor Yellow
        exit 1
    }
    Write-Host ""
}

# Step 1: Disable audio via admin API
Write-Host "[1/4] Disabling audio via admin API..." -ForegroundColor White

$headers = @{}
if ($AdminToken) { 
    $headers["X-Admin-Token"] = $AdminToken 
    Write-Host "  → Using admin token for authentication" -ForegroundColor Gray
} else {
    Write-Host "  → No admin token (trusted network mode)" -ForegroundColor Gray
}

$disabled = $false
try {
    $body = @{ enabled = $false; reason = "rollback" } | ConvertTo-Json
    $result = Invoke-RestMethod -Method Post -Uri "$BaseUrl/admin/audio" -Headers $headers -ContentType "application/json" -Body $body -ErrorAction Stop
    Write-Host "  ✓ Audio disabled via API: $($result.reason)" -ForegroundColor Green
    $disabled = $true
} catch {
    Write-Host "  ⚠️  Admin API unavailable: $_" -ForegroundColor Yellow
    Write-Host "  → Falling back to file-based switch inside container..." -ForegroundColor Yellow
}

if (-not $disabled) {
    # Fallback: Write persisted state file inside container (bind-mounted)
    Write-Host "  → Writing audio-state.json directly in container..." -ForegroundColor Gray
    
    # GATE-020-R1: Validate container exists before exec
    $containerExists = docker ps --filter "name=$Service" --format "{{.Names}}" | Select-Object -First 1
    if (-not $containerExists) {
        Write-Host "  ✗ Container '$Service' not found!" -ForegroundColor Red
        Write-Host "  → Available containers:" -ForegroundColor Yellow
        docker ps --filter "name=pm-engine" --format "  - {{.Names}}" | Write-Host
        exit 1
    }
    
    $timestamp = (Get-Date).ToString("o")
    $json = "{`"enabled`":false,`"reason`":`"rollback`",`"changedAt`":`"$timestamp`"}"
    
    try {
        docker exec $Service sh -c "mkdir -p /app/config && printf '%s' '$json' > /app/config/audio-state.json"
        Write-Host "  ✓ Audio state file written directly to $Service" -ForegroundColor Green
        $disabled = $true
    } catch {
        Write-Host "  ✗ Failed to write state file: $_" -ForegroundColor Red
        Write-Host "  → Manual intervention required" -ForegroundColor Red
        exit 1
    }
}

Write-Host ""

# Step 2: Restart pm-engine container
# GATE-020-R1: Use docker restart with detected container name
Write-Host "[2/4] Restarting container $Service..." -ForegroundColor White

try {
    docker restart $Service | Out-Null
    Write-Host "  → Container restarting..." -ForegroundColor Gray
    Start-Sleep -Seconds 5
    Write-Host "  ✓ Container restarted" -ForegroundColor Green
} catch {
    Write-Host "  ✗ Failed to restart container: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Step 3: Verify audio is OFF
Write-Host "[3/4] Verifying audio is OFF..." -ForegroundColor White

$deadline = (Get-Date).AddSeconds($VerifyTimeoutSec)
$ok = $false

do {
    Start-Sleep -Seconds 1
    try {
        $st = Invoke-RestMethod -Method Get -Uri "$BaseUrl/health" -ErrorAction Stop
        if ($st.audio -and $st.audio.enabled -eq $false) {
            Write-Host "  ✓ Audio verified OFF" -ForegroundColor Green
            Write-Host "    - Reason: $($st.audio.reason)" -ForegroundColor Gray
            Write-Host "    - Changed at: $($st.audio.changedAt)" -ForegroundColor Gray
            $ok = $true
            break
        } else {
            Write-Host "  → Audio still enabled, retrying..." -ForegroundColor Yellow
        }
    } catch {
        Write-Host "  → Health endpoint not ready yet, retrying..." -ForegroundColor Gray
    }
} while ((Get-Date) -lt $deadline)

if (-not $ok) {
    Write-Host "  ✗ Rollback verification FAILED: audio still enabled or health endpoint unreachable." -ForegroundColor Red
    Write-Host "  → Check container logs: docker logs $Service" -ForegroundColor Yellow
    exit 1
}

Write-Host ""

# Step 4: Test audio ingestion blocked
Write-Host "[4/4] Testing audio ingestion blocked..." -ForegroundColor White

try {
    # Send a test audio request (should return 503)
    $testData = @{ base64 = "AAAA" }  # Minimal test payload
    $response = Invoke-RestMethod -Uri "$BaseUrl/audio" -Method Post -Body ($testData | ConvertTo-Json) -ContentType "application/json" -SkipHttpErrorCheck
    
    # Check for proper rejection
    if ($response.error -eq "audio-disabled" -and $response.enabled -eq $false) {
        Write-Host "  ✓ Audio ingestion properly blocked (HTTP 503)" -ForegroundColor Green
        Write-Host "    - Reason: $($response.reason)" -ForegroundColor Gray
    } else {
        Write-Host "  ⚠️  Warning: Unexpected response from /audio endpoint" -ForegroundColor Yellow
        Write-Host "    - Response: $($response | ConvertTo-Json -Compress)" -ForegroundColor Gray
    }
} catch {
    # HTTP 503 expected for PowerShell < 7.0 (no -SkipHttpErrorCheck)
    if ($_.Exception.Response.StatusCode -eq 503) {
        Write-Host "  ✓ Audio ingestion properly blocked (HTTP 503)" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️  Unexpected error: $_" -ForegroundColor Yellow
    }
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "✅ Rollback Complete" -ForegroundColor Green
Write-Host "`nAudio Status: DISABLED" -ForegroundColor White
Write-Host "Container: $Service (restarted)" -ForegroundColor White
Write-Host "Verification: PASS" -ForegroundColor Green
Write-Host "`nTo re-enable audio:" -ForegroundColor White
Write-Host "  1. Via API:" -ForegroundColor Gray
Write-Host "     curl -X POST $BaseUrl/admin/audio \" -ForegroundColor Gray
Write-Host "       -H 'Content-Type: application/json' \" -ForegroundColor Gray
if ($AdminToken) {
    Write-Host "       -H 'X-Admin-Token: $AdminToken' \" -ForegroundColor Gray
}
Write-Host "       -d '{`"enabled`":true,`"reason`":`"manual-enable`"}'" -ForegroundColor Gray
Write-Host "  2. Via canary reset:" -ForegroundColor Gray
Write-Host "     curl -X POST $BaseUrl/canary/reset" -ForegroundColor Gray
Write-Host "  3. Verify: curl $BaseUrl/health" -ForegroundColor Gray
Write-Host ""
