#!/usr/bin/env pwsh
<#
.SYNOPSIS
  Install Resonai Preset Pack to MilkDrop3
.DESCRIPTION
  Copies all .milk presets from Resonai Pack v1 to MilkDrop3 presets folder.
  Optionally launches MilkDrop3 after install.
  
  Lane: MILK | Budget: ≤200 LOC | Authority: BossCat OEM
.PARAMETER MilkDropDir
  Path to MilkDrop3 folder (auto-detected if not provided)
.PARAMETER Launch
  Launch MilkDrop3 after installation
.PARAMETER Validate
  Run Validate-Preset.ps1 on each preset before installing
#>

Param(
  [string]$MilkDropDir,
  [switch]$Launch,
  [switch]$Validate
)

$ErrorActionPreference = 'Stop'

function Resolve-MilkDropDir {
  param([string]$Hint)
  
  if ($Hint -and (Test-Path $Hint)) {
    return (Resolve-Path $Hint).Path
  }
  
  # Auto-detect candidates
  $candidates = @(
    "$env:ProgramFiles\MilkDrop3",
    "$env:ProgramFiles(x86)\MilkDrop3",
    (Join-Path $PSScriptRoot '..' '..' 'tools' 'MilkDrop3')
  )
  
  foreach ($c in $candidates) {
    if (Test-Path $c) {
      Write-Host "[OK] Found MilkDrop3 at: $c" -ForegroundColor Green
      return (Resolve-Path $c).Path
    }
  }
  
  # Prompt user
  try {
    Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
    $fbd = New-Object System.Windows.Forms.FolderBrowserDialog
    $fbd.Description = 'Select MilkDrop3 folder (contains MilkDrop3.exe)'
    $null = $fbd.ShowDialog()
    if ($fbd.SelectedPath) { return $fbd.SelectedPath }
  } catch {
    # Fallback to console prompt
  }
  
  $manual = Read-Host 'Enter path to MilkDrop3 folder'
  if (-not (Test-Path $manual)) {
    throw "Invalid path: $manual"
  }
  return (Resolve-Path $manual).Path
}

function Install-PresetPack {
  param([string]$TargetDir, [bool]$RunValidation)
  
  $packDir = Join-Path $PSScriptRoot '..' '..' 'docs' 'BossCat' 'visuals' 'presets' 'Resonai Pack v1'
  
  if (-not (Test-Path $packDir)) {
    Write-Warning "Pack directory not found: $packDir"
    Write-Host "Creating pack directory structure..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $packDir -Force | Out-Null
    return 0
  }
  
  $presets = Get-ChildItem $packDir -Filter '*.milk'
  if ($presets.Count -eq 0) {
    Write-Warning "No .milk files found in $packDir"
    return 0
  }
  
  $presetsDir = Join-Path $TargetDir 'presets'
  if (-not (Test-Path $presetsDir)) {
    New-Item -ItemType Directory -Path $presetsDir -Force | Out-Null
  }
  
  $installed = 0
  $validated = 0
  $failed = 0
  
  foreach ($preset in $presets) {
    # Validate if requested
    if ($RunValidation) {
      $validatorPath = Join-Path $PSScriptRoot 'Validate-Preset.ps1'
      if (Test-Path $validatorPath) {
        try {
          & $validatorPath -PresetPath $preset.FullName -ErrorAction Stop | Out-Null
          $validated++
          Write-Host "  [✓] Validated: $($preset.Name)" -ForegroundColor Green
        } catch {
          Write-Warning "  [!] Validation failed: $($preset.Name)"
          $failed++
          continue
        }
      }
    }
    
    # Copy preset
    $dst = Join-Path $presetsDir $preset.Name
    Copy-Item $preset.FullName -Destination $dst -Force
    $installed++
    Write-Host "  [+] Installed: $($preset.Name)" -ForegroundColor Cyan
  }
  
  Write-Host "`n[OK] Installed $installed presets to: $presetsDir" -ForegroundColor Green
  if ($RunValidation) {
    Write-Host "[OK] Validated: $validated | Failed: $failed" -ForegroundColor $(if ($failed -eq 0) { 'Green' } else { 'Yellow' })
  }
  
  return $installed
}

function Start-MilkDropIfPresent {
  param([string]$Dir)
  
  $exe = Join-Path $Dir 'MilkDrop3.exe'
  if (Test-Path $exe) {
    Write-Host "[OK] Launching MilkDrop3..." -ForegroundColor Green
    Start-Process -FilePath $exe -WorkingDirectory $Dir | Out-Null
    Write-Host "     Press 'L' to load preset list" -ForegroundColor Cyan
  } else {
    Write-Warning "MilkDrop3.exe not found in $Dir"
    Write-Host "Install from: https://github.com/milkdrop2077/MilkDrop3/releases" -ForegroundColor Yellow
  }
}

# Main
try {
  Write-Host "`n🎨 Resonai Preset Pack Installer" -ForegroundColor Magenta
  Write-Host "   Lane: MILK | BossCat OEM`n" -ForegroundColor Gray
  
  $target = Resolve-MilkDropDir -Hint $MilkDropDir
  $count = Install-PresetPack -TargetDir $target -RunValidation $Validate.IsPresent
  
  if ($count -gt 0 -and $Launch.IsPresent) {
    Start-MilkDropIfPresent -Dir $target
  }
  
  Write-Host "`n✅ Installation complete!" -ForegroundColor Green
  Write-Host "   Load presets in MilkDrop3 via 'L' key`n" -ForegroundColor Cyan
} catch {
  Write-Error $_
  exit 1
}

