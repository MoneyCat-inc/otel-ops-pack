# Audio Feeder - Simulated Audio Input for md3-engine
# ECRR: BossCat Gate #010 - Audio reactivity testing
# Authority: BossCat OEM | Executor: Cursor{Implementer}

param(
    [Parameter(Mandatory=$false)]
    [int]$DurationSeconds = 60,
    
    [Parameter(Mandatory=$false)]
    [double]$BPM = 120,
    
    [Parameter(Mandatory=$false)]
    [string]$VizEngineUrl = "http://localhost:7001"
)

$ErrorActionPreference = "Stop"

Write-Host "Audio Feeder - Simulated Bass/Mid/Treb" -ForegroundColor Cyan
Write-Host "Duration: ${DurationSeconds}s | BPM: $BPM | Target: $VizEngineUrl" -ForegroundColor Gray
Write-Host ""

$fps = 60
$totalFrames = $DurationSeconds * $fps
$beatInterval = 60.0 / $BPM  # Seconds per beat

$startTime = [DateTimeOffset]::UtcNow

for ($i = 0; $i -lt $totalFrames; $i++) {
    $t = $i / $fps
    $beatPhase = ($t % $beatInterval) / $beatInterval
    
    # Simulate bass kick (sharp attack, exponential decay)
    if ($beatPhase -lt 0.1) {
        $bass = 1.0 - ($beatPhase / 0.1)
    } else {
        $bass = [Math]::Exp(-5 * ($beatPhase - 0.1))
    }
    
    # Mid frequencies (smoother)
    $mid = 0.3 + 0.2 * [Math]::Sin(2 * [Math]::PI * 2 * $t)
    
    # Treble (higher frequency variation)
    $treb = 0.15 + 0.1 * [Math]::Sin(2 * [Math]::PI * 8 * $t)
    
    # Clamp to [0, 1]
    $bass = [Math]::Max(0, [Math]::Min(1, $bass))
    $mid = [Math]::Max(0, [Math]::Min(1, $mid))
    $treb = [Math]::Max(0, [Math]::Min(1, $treb))
    
    # Compute RMS
    $rms = [Math]::Sqrt(($bass * $bass + $mid * $mid + $treb * $treb) / 3.0)
    
    # Generate simple FFT (bass in lower bins, mid/treb in higher)
    $fft = @()
    for ($j = 0; $j -lt 64; $j++) {
        if ($j -lt 8) {
            $fft += $bass * 0.9
        } elseif ($j -lt 24) {
            $fft += $mid * 0.7
        } else {
            $fft += $treb * 0.5
        }
    }
    
    # Build payload
    $payload = @{
        sr = 44100
        rms = $rms
        fft = $fft
        bands = @{
            bass = $bass
            mid = $mid
            treb = $treb
        }
        ts = ([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() / 1000.0)
    } | ConvertTo-Json -Depth 5 -Compress
    
    # Post to engine
    try {
        Invoke-RestMethod `
            -Uri "$VizEngineUrl/audio" `
            -Method Post `
            -ContentType "application/json" `
            -Body $payload `
            -TimeoutSec 1 `
            -ErrorAction SilentlyContinue | Out-Null
    } catch {
        # Silently continue on errors (don't flood console)
    }
    
    # Progress indicator every 60 frames
    if ($i % 60 -eq 0) {
        $elapsed = ([DateTimeOffset]::UtcNow - $startTime).TotalSeconds
        $remaining = $DurationSeconds - $elapsed
        Write-Host "Frame: $i/$totalFrames | Bass: $($bass.ToString('F2')) | Elapsed: $($elapsed.ToString('F1'))s | Remaining: $($remaining.ToString('F1'))s" -ForegroundColor Gray
    }
    
    # Sleep to maintain 60fps
    Start-Sleep -Milliseconds 16
}

Write-Host ""
Write-Host "Audio feed complete: $totalFrames frames sent" -ForegroundColor Green

# Final stats
$audioStats = Invoke-RestMethod -Uri "$VizEngineUrl/audio/stats" -Method Get
Write-Host ""
Write-Host "Audio Stats:" -ForegroundColor Cyan
Write-Host "  Bass Avg: $($audioStats.bass_avg.ToString('F3'))" -ForegroundColor Gray
Write-Host "  Mid Avg:  $($audioStats.mid_avg.ToString('F3'))" -ForegroundColor Gray
Write-Host "  Treb Avg: $($audioStats.treb_avg.ToString('F3'))" -ForegroundColor Gray
Write-Host "  Samples:  $($audioStats.samples)" -ForegroundColor Gray

