# Investor Demo: Load Aesthetic Preset for Milkdrop
# Authority: BossCat OEM | Executor: Cursor{Implementer}
# Purpose: Load visually appealing preset for demo

param(
    [string]$PresetName = "Geiss - Blur Experiment - Vertical Waves",
    [int]$BlendSeconds = 3,
    [string]$EngineUrl = "http://localhost:7001"
)

Write-Host "=== Loading Demo Preset ===" -ForegroundColor Cyan
Write-Host "Engine: $EngineUrl" -ForegroundColor Gray
Write-Host "Preset: $PresetName" -ForegroundColor Gray
Write-Host ""

# Try loading preset by name (built-in Butterchurn)
$body = @{
    name = $PresetName
    blend = $BlendSeconds
} | ConvertTo-Json

try {
    $result = Invoke-RestMethod -Uri "$EngineUrl/preset" -Method Post -Body $body -ContentType "application/json"
    
    if ($result.ok) {
        Write-Host "✅ Preset loaded successfully" -ForegroundColor Green
        Write-Host "   Preset: $PresetName" -ForegroundColor White
        exit 0
    } else {
        Write-Host "⚠️  Preset load failed: $($result.error)" -ForegroundColor Yellow
        Write-Host "   Details: $($result.details)" -ForegroundColor Gray
        
        # List alternatives
        Write-Host ""
        Write-Host "Available presets:" -ForegroundColor Cyan
        $presets = Invoke-RestMethod -Uri "$EngineUrl/presets"
        $presets.presets | Select-Object -First 10 | ForEach-Object { Write-Host "  - $_" -ForegroundColor Gray }
        exit 1
    }
} catch {
    Write-Host "❌ Failed to load preset: $_" -ForegroundColor Red
    exit 1
}

