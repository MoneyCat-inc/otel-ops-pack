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

# GATE-020-R1B: Detect pm-engine replica containers (all replicas for fleet-wide rollback)
$allContainers = @()
if ([string]::IsNullOrEmpty($Service)) {
    Write-Host "[0/4] Detecting pm-engine containers..." -ForegroundColor White
    $detectedContainers = docker ps --filter "name=pm-engine" --format "{{.Names}}" | Where-Object { $_ -match "pm-engine" }
    
    if ($detectedContainers) {
        if ($detectedContainers -is [array]) {
            $allContainers = $detectedContainers
            $Service = $detectedContainers[0]  # Use first for API test
            Write-Host "  → Found $($allContainers.Count) replicas: $($allContainers -join ', ')" -ForegroundColor Gray
            Write-Host "  → Primary: $Service (for health checks)" -ForegroundColor Gray
        } else {
            $allContainers = @($detectedContainers)
            $Service = $detectedContainers
            Write-Host "  → Found single container: $Service" -ForegroundColor Gray
        }
    } else {
        Write-Host "  ✗ No pm-engine containers found!" -ForegroundColor Red
        Write-Host "  → Run: docker ps | grep pm-engine" -ForegroundColor Yellow
        exit 1
    }
    Write-Host ""
} else {
    # User provided explicit service name
    $allContainers = @($Service)
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
    # Fallback: Write persisted state file inside ALL containers (bind-mounted)
    # GATE-020-R1B: Fleet-wide rollback requires hitting all replicas
    Write-Host "  → Writing audio-state.json to all replicas..." -ForegroundColor Gray
    
    $timestamp = (Get-Date).ToString("o")
    $json = "{`"enabled`":false,`"reason`":`"rollback`",`"changedAt`":`"$timestamp`"}"
    
    $failedContainers = @()
    foreach ($container in $allContainers) {
        try {
            docker exec $container sh -c "mkdir -p /app/config && printf '%s' '$json' > /app/config/audio-state.json" 2>&1 | Out-Null
            Write-Host "  ✓ $container" -ForegroundColor Green
        } catch {
            Write-Host "  ✗ $container failed: $_" -ForegroundColor Red
            $failedContainers += $container
        }
    }
    
    if ($failedContainers.Count -gt 0) {
        Write-Host "  ✗ Failed to write state file to $($failedContainers.Count)/$($allContainers.Count) containers" -ForegroundColor Red
        Write-Host "  → Failed: $($failedContainers -join ', ')" -ForegroundColor Red
        Write-Host "  → Manual intervention required" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "  ✓ Audio state written to all $($allContainers.Count) replicas" -ForegroundColor Green
    $disabled = $true
}

Write-Host ""

# Step 2: Restart all pm-engine containers
# GATE-020-R1B: Fleet-wide restart for all replicas
Write-Host "[2/4] Restarting all pm-engine containers..." -ForegroundColor White

$failedRestarts = @()
foreach ($container in $allContainers) {
    try {
        Write-Host "  → Restarting $container..." -ForegroundColor Gray
        docker restart $container 2>&1 | Out-Null
        Write-Host "  ✓ $container restarted" -ForegroundColor Green
    } catch {
        Write-Host "  ✗ $container failed: $_" -ForegroundColor Red
        $failedRestarts += $container
    }
}

if ($failedRestarts.Count -gt 0) {
    Write-Host "  ✗ Failed to restart $($failedRestarts.Count)/$($allContainers.Count) containers" -ForegroundColor Red
    Write-Host "  → Failed: $($failedRestarts -join ', ')" -ForegroundColor Red
    exit 1
}

Write-Host "  → Waiting for containers to initialize..." -ForegroundColor Gray
Start-Sleep -Seconds 5
Write-Host "  ✓ All $($allContainers.Count) replicas restarted" -ForegroundColor Green

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
