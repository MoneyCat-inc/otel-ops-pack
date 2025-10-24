# Reload Milkdrop Preset (Cursor Hot-Reload)
# ECRR: BossCat Mission - Visual authoring loop
# Authority: BossCat OEM | Executor: Cursor{Implementer}

param(
    [Parameter(Mandatory=$true)]
    [string]$PresetFile,
    
    [Parameter(Mandatory=$false)]
    [double]$Blend = 2.5,
    
    [Parameter(Mandatory=$false)]
    [string]$VizEngineUrl = "http://localhost:7001"
)

$ErrorActionPreference = "Stop"

# Validate preset file exists
if (-not (Test-Path $PresetFile)) {
    Write-Error "Preset file not found: $PresetFile"
    exit 1
}

# Read preset content
$presetName = [System.IO.Path]::GetFileNameWithoutExtension($PresetFile)
$presetBody = Get-Content $PresetFile -Raw

# Determine format (assume .milk for now; could add .json detection)
$extension = [System.IO.Path]::GetExtension($PresetFile).ToLower()

if ($extension -eq ".json") {
    # Already JSON, parse it
    $presetData = $presetBody | ConvertFrom-Json
} else {
    # .milk format - send as-is (server will handle)
    $presetData = $presetBody
}

# Build request payload
$payload = @{
    name = $presetName
    body = $presetData
    blend = $Blend
} | ConvertTo-Json -Depth 10

# Send reload request
Write-Host "🎨 Reloading preset: $presetName (blend: ${Blend}s)..." -ForegroundColor Cyan

try {
    $response = Invoke-RestMethod `
        -Uri "$VizEngineUrl/preset" `
        -Method Post `
        -ContentType "application/json" `
        -Body $payload `
        -TimeoutSec 10

    if ($response.ok) {
        Write-Host "✅ Preset loaded successfully" -ForegroundColor Green
        Write-Host "   Name:  $($response.preset)" -ForegroundColor Gray
        Write-Host "   Blend: $($response.blend)s" -ForegroundColor Gray
        
        # Optional: Trigger scorebot check after blend completes
        Start-Sleep -Seconds ($Blend + 1)
        
        $stats = Invoke-RestMethod `
            -Uri "$VizEngineUrl/stats" `
            -Method Get `
            -TimeoutSec 5
        
        Write-Host "📊 Stats: FPS=$($stats.fps) | FrameTime=$($stats.frameTimeMs)ms" -ForegroundColor Gray
    } else {
        Write-Error "Failed to load preset: $($response.error)"
        exit 1
    }
} catch {
    Write-Error "Failed to connect to viz-engine: $_"
    exit 1
}

# ECRR artifact (lightweight)
$artifact = @{
    timestamp = Get-Date -Format "o"
    action = "preset_reload"
    preset = $presetName
    blend = $Blend
    file = $PresetFile
    result = "success"
} | ConvertTo-Json -Depth 5

$artifactDir = "artifacts/viz-engine"
if (-not (Test-Path $artifactDir)) {
    New-Item -ItemType Directory -Path $artifactDir -Force | Out-Null
}

$artifactPath = "$artifactDir/preset-reload-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
$artifact | Set-Content $artifactPath -Encoding UTF8

Write-Host "📝 ECRR artifact: $artifactPath" -ForegroundColor Gray

