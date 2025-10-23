# 🔔 Gate Self-Signal Monitor — Continuous Background Loop (Low-Latency Mode)
# Runs every 2 minutes until platform fix detected (exit 0)
# Then breaks with alert for manual gate advancement execution

param(
    [int]$IntervalSeconds = 120,  # 2 minutes (low-latency mode)
    [switch]$QuietMode = $false
)

$StartTime = Get-Date
$CheckCount = 0

function Log-Status {
    param([string]$Message, [string]$Color = "Gray")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] $Message" -ForegroundColor $Color
}

Log-Status "🔔 GATE SELF-SIGNAL MONITOR STARTED" -Color Cyan
Log-Status "Interval: $($IntervalSeconds/60) minutes" -Color Cyan
Log-Status "Exit loop trigger: exit code 0 (traces detected)" -Color Cyan
Log-Status ""

while ($true) {
    $CheckCount++
    $elapsed = ((Get-Date) - $StartTime).TotalMinutes
    
    Log-Status "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -Color DarkGray
    Log-Status "Check #$CheckCount (elapsed: $([Math]::Round($elapsed, 1)) min)" -Color Yellow
    
    # Run self-signal check
    $result = & pwsh -File .\gate-self-signal-check.ps1 -ErrorAction SilentlyContinue
    $exitCode = $LASTEXITCODE
    
    # Evaluate result
    if ($exitCode -eq 0) {
        Log-Status "" -Color Green
        Log-Status "✅✅✅ PLATFORM FIX DETECTED ✅✅✅" -Color Green
        Log-Status "Exit Code 0: Traces are persisting to ClickHouse" -Color Green
        Log-Status "" -Color Green
        Log-Status "🚀 EXECUTING COMPLETE AUTOMATION..." -Color Cyan
        Log-Status "=====================================" -Color Cyan
        Log-Status "" -Color Green
        
        # Execute complete gate advancement automation
        try {
            Log-Status "🔔 Running V3 complete automation..." -Color Yellow
            & pwsh -File ".\gate-v3-complete.ps1"
            $completeExitCode = $LASTEXITCODE
            
            if ($completeExitCode -eq 0) {
                Log-Status "" -Color Green
                Log-Status "🎯 GATE ADVANCEMENT COMPLETE!" -Color Green
                Log-Status "==============================" -Color Green
                Log-Status "✅ Evidence packaged" -Color Green
                Log-Status "✅ ECRR artifacts generated" -Color Green
                Log-Status "✅ BossCat log updated" -Color Green
                Log-Status "✅ Ready for @cat ready-for-gate" -Color Green
                Log-Status "" -Color Green
                Log-Status "🚦 VERDICT: 🟢 GREEN" -Color Green
                Log-Status "" -Color Green
            } else {
                Log-Status "" -Color Yellow
                Log-Status "⚠️ Gate advancement failed (exit $completeExitCode)" -Color Yellow
                Log-Status "Manual intervention required" -Color Yellow
                Log-Status "" -Color Yellow
            }
        } catch {
            Log-Status "" -Color Red
            Log-Status "❌ Automation execution failed: $_" -Color Red
            Log-Status "Manual gate advancement required" -Color Red
            Log-Status "" -Color Red
        }
        
        # Break the loop
        break
    } elseif ($exitCode -eq 1) {
        Log-Status "⏳ Platform gap persists (count() = 0)" -Color Yellow
        Log-Status "Will retry in $($IntervalSeconds/60) minutes" -Color Yellow
    } elseif ($exitCode -eq 2) {
        Log-Status "⚠️ ClickHouse query failed" -Color Red
        Log-Status "Check: localhost:8123 availability" -Color Red
    }
    
    # Wait for next check
    if ($exitCode -ne 0) {
        Log-Status ""
        for ($i = $IntervalSeconds; $i -gt 0; $i -= 10) {
            if (-not $QuietMode) {
                $remaining = [Math]::Ceiling($i / 60)
                Write-Host -NoNewline "`rNext check in $remaining min...  "
            }
            Start-Sleep -Seconds 10
        }
        Write-Host ""  # Newline after countdown
    }
}

Log-Status ""
Log-Status "🛑 MONITORING LOOP EXITED (platform fix detected)" -Color Green
Log-Status "Total checks: $CheckCount" -Color Cyan
Log-Status "Total elapsed: $([Math]::Round($elapsed, 1)) minutes" -Color Cyan
Log-Status ""
