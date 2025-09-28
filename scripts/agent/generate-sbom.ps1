# scripts/agent/generate-sbom.ps1 - Generate SBOM for codex-local agent

param(
    [string]$OutputDir = "docs/sbom",
    [string]$OutputFile = "codex-local.cdx.json",
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"

function Write-SbomResult {
    param(
        [string]$Message,
        [bool]$Success = $true
    )
    
    $color = if ($Success) { "Green" } else { "Red" }
    $icon = if ($Success) { "✅" } else { "❌" }
    Write-Host "$icon $Message" -ForegroundColor $color
}

Write-Host "📦 codex-local SBOM Generation" -ForegroundColor Cyan
Write-Host "==============================" -ForegroundColor Cyan

# Ensure output directory exists
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
    Write-SbomResult -Message "Created output directory: $OutputDir"
}

$outputPath = Join-Path $OutputDir $OutputFile

# Check if CycloneDX is available
Write-Host "`n🔍 Checking CycloneDX availability..." -ForegroundColor Yellow
try {
    $cyclonedxVersion = pnpm dlx @cyclonedx/cyclonedx-npm --version 2>$null
    if ($Verbose) {
        Write-SbomResult -Message "CycloneDX version: $cyclonedxVersion"
    }
} catch {
    Write-SbomResult -Message "CycloneDX not found, installing..." -Success $false
    pnpm dlx @cyclonedx/cyclonedx-npm@latest
}

# Generate SBOM
Write-Host "`n📋 Generating SBOM..." -ForegroundColor Yellow
try {
    $sbomCommand = "pnpm dlx @cyclonedx/cyclonedx-npm --output-format=json --output-file=`"$outputPath`""
    if ($Verbose) {
        $sbomCommand += " --verbose"
    }
    
    Invoke-Expression $sbomCommand
    
    if (Test-Path $outputPath) {
        $fileSize = (Get-Item $outputPath).Length
        $fileSizeKB = [Math]::Round($fileSize / 1KB, 2)
        
        Write-SbomResult -Message "SBOM generated successfully: $outputPath"
        Write-SbomResult -Message "File size: $fileSizeKB KB"
        
        # Validate SBOM size (should be <5MB)
        if ($fileSize -lt 5MB) {
            Write-SbomResult -Message "SBOM size within limits (<5MB)"
        } else {
            Write-SbomResult -Message "WARNING: SBOM size exceeds 5MB limit" -Success $false
        }
        
        # Basic JSON validation
        try {
            $sbomContent = Get-Content $outputPath -Raw | ConvertFrom-Json
            Write-SbomResult -Message "SBOM JSON validation passed"
            Write-SbomResult -Message "Components found: $($sbomContent.components.Count)"
        } catch {
            Write-SbomResult -Message "SBOM JSON validation failed: $($_.Exception.Message)" -Success $false
            exit 1
        }
        
    } else {
        Write-SbomResult -Message "SBOM file not created" -Success $false
        exit 1
    }
} catch {
    Write-SbomResult -Message "SBOM generation failed: $($_.Exception.Message)" -Success $false
    exit 1
}

# Generate metadata
$metadata = @{
    generated = (Get-Date).ToString("o")
    generator = "codex-local-sbom"
    version = "1.0.0"
    outputFile = $outputPath
    fileSize = $fileSizeKB
    components = $sbomContent.components.Count
} | ConvertTo-Json -Depth 3

$metadataPath = Join-Path $OutputDir "sbom-metadata.json"
$metadata | Set-Content $metadataPath -Encoding UTF8
Write-SbomResult -Message "Metadata generated: $metadataPath"

Write-Host "`n🎉 SBOM Generation Complete" -ForegroundColor Green
Write-Host "Output: $outputPath" -ForegroundColor Gray
Write-Host "Size: $fileSizeKB KB" -ForegroundColor Gray
Write-Host "Components: $($sbomContent.components.Count)" -ForegroundColor Gray
