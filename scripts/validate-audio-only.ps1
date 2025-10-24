# Gate #010 AMBER Validator - Audio-Only
# ECRR: BossCat Mission - Audio bridge validation
# Authority: BossCat OEM | Executor: Cursor{Implementer}
#
# Validates ONLY audio reactivity requirements (visual rendering deferred to Gate #011)

param(
    [int]$MinSamples = 300,
    [double]$MinReactivity = 0.35,
    [string]$MetricsUrl = "http://localhost:7010/metrics"
)

Write-Host "`n🎯 GATE #010 AMBER VALIDATOR (Audio-Only)`n" -ForegroundColor Cyan

try {
    $metrics = Invoke-RestMethod -Uri $MetricsUrl -TimeoutSec 5
    
    Write-Host "METRICS:" -ForegroundColor White
    Write-Host "  reactivity_r: $([math]::Round($metrics.reactivity_r, 4))" -ForegroundColor Cyan
    Write-Host "  Threshold: >= $MinReactivity" -ForegroundColor Yellow
    
    $reactivityPass = $metrics.reactivity_r -ge $MinReactivity
    Write-Host "  Status: $(if ($reactivityPass) { 'PASS' } else { 'FAIL' })" -ForegroundColor $(if ($reactivityPass) { 'Green' } else { 'Red' })
    
    Write-Host "`n  aspect_ok: $($metrics.aspect_ok)" -ForegroundColor Cyan
    
    # Build result
    $result = @{
        gate = "GATE_010_AMBER"
        timestamp = Get-Date -Format "o"
        verdict = if ($reactivityPass) { "PASS" } else { "FAIL" }
        metrics = @{
            reactivity_r = $metrics.reactivity_r
            threshold = $MinReactivity
            aspect_ok = $metrics.aspect_ok
            score = $metrics.score
        }
        requirements = @{
            audio_reactivity = $reactivityPass
            visual_rendering = "DEFERRED_TO_GATE_011"
        }
    }
    
    # Export result
    $outputPath = "artifacts/viz-engine/gate010_audio_only.json"
    $result | ConvertTo-Json -Depth 5 | Set-Content $outputPath
    
    Write-Host "`nVERDICT: $($result.verdict)" -ForegroundColor $(if ($reactivityPass) { 'Green' } else { 'Red' })
    Write-Host "Exported to: $outputPath`n" -ForegroundColor Cyan
    
    exit $(if ($reactivityPass) { 0 } else { 1 })
    
} catch {
    Write-Host "`nERROR: $($_.Exception.Message)" -ForegroundColor Red
    exit 2
}

