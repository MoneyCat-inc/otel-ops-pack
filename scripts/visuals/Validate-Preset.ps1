#!/usr/bin/env pwsh
<#
.SYNOPSIS
  Validate MilkDrop preset for safety and compatibility
.DESCRIPTION
  Lints .milk files for BossCat safety guardrails:
  - No shaders (for ProjectM compat)
  - fDecay ≤ 0.99
  - wave_a ≤ 0.9
  - zoom/rot motion bounds
  - Spectrum smoothing ≥ 0.4
  
  Lane: MILK | Budget: ≤200 LOC | Authority: BossCat OEM
#>

Param(
  [Parameter(Mandatory=$true)][string]$PresetPath,
  [string]$OutputJson = '',
  [switch]$AutoFix
)

$ErrorActionPreference = 'Stop'

function Test-PresetSafety {
  param([string]$Path)
  
  if (-not (Test-Path $Path)) {
    throw "Preset not found: $Path"
  }
  
  $content = Get-Content $Path -Raw
  $lines = Get-Content $Path
  $issues = @()
  $warnings = @()
  $info = @()
  
  # Check 1: Shader blocks (should not exist for v1)
  if ($content -match '(?i)^(warp|comp)_shader' -or $content -match '(?i)^shader_') {
    $issues += @{
      severity = 'fail'
      rule = 'no-shaders'
      message = 'GPU shaders not allowed in v1 pack (ProjectM compatibility)'
      line = ($lines | Select-String '(?i)(warp|comp)_shader|shader_' | Select-Object -First 1).LineNumber
    }
  }
  
  # Check 2: fDecay bounds
  if ($content -match 'fDecay\s*=\s*([\d\.]+)') {
    $decay = [double]$matches[1]
    if ($decay -gt 0.99) {
      $issues += @{
        severity = 'fail'
        rule = 'decay-limit'
        message = "fDecay=$decay exceeds 0.99 (trail flash risk)"
        suggestedFix = 'fDecay=0.99'
      }
    } elseif ($decay -lt 0.90) {
      $warnings += @{
        severity = 'warn'
        rule = 'decay-low'
        message = "fDecay=$decay very low (< 0.90); intentional fade?"
      }
    }
  }
  
  # Check 3: wave_a bounds (check direct assignments)
  $waveAlphaLines = $lines | Select-String 'wave_a\s*=\s*([\d\.]+)' -AllMatches
  foreach ($match in $waveAlphaLines) {
    $alpha = [double]$match.Matches[0].Groups[1].Value
    if ($alpha -gt 0.9) {
      $issues += @{
        severity = 'fail'
        rule = 'wave-alpha'
        message = "wave_a=$alpha exceeds 0.9 at line $($match.LineNumber) (strobe risk)"
        line = $match.LineNumber
        suggestedFix = 'wave_a=0.9'
      }
    }
  }
  
  # Check 4: zoom bounds (direct assignments)
  $zoomLines = $lines | Select-String '^\s*zoom\s*=\s*([\d\.]+)' -AllMatches
  foreach ($match in $zoomLines) {
    $z = [double]$match.Matches[0].Groups[1].Value
    if ($z -lt 0.5 -or $z -gt 2.0) {
      $warnings += @{
        severity = 'warn'
        rule = 'zoom-extreme'
        message = "zoom=$z outside typical range [0.5, 2.0] at line $($match.LineNumber)"
        line = $match.LineNumber
      }
    }
  }
  
  # Check 5: Spectrum smoothing
  $smoothingLines = $lines | Select-String 'smoothing\s*=\s*([\d\.]+)' -AllMatches
  foreach ($match in $smoothingLines) {
    $smooth = [double]$match.Matches[0].Groups[1].Value
    if ($smooth -lt 0.4) {
      $warnings += @{
        severity = 'warn'
        rule = 'smoothing-low'
        message = "smoothing=$smooth < 0.4 at line $($match.LineNumber) (jitter risk); recommend ≥ 0.6"
        line = $match.LineNumber
      }
    }
  }
  
  # Check 6: Additive brightness risk
  if ($content -match 'bAdditive\s*=\s*1' -or $content -match 'additive\s*=\s*1') {
    $info += @{
      severity = 'info'
      rule = 'additive-mode'
      message = 'Additive blending enabled; ensure alpha ≤ 0.6 to prevent brightness blowout'
    }
  }
  
  # Check 7: Rate of motion (rot delta per frame)
  $rotDeltas = $lines | Select-String 'rot\s*=\s*rot\s*\+\s*([\d\.]+)' -AllMatches
  foreach ($match in $rotDeltas) {
    $delta = [double]$match.Matches[0].Groups[1].Value
    if ($delta -gt 0.05) {
      $warnings += @{
        severity = 'warn'
        rule = 'rot-delta'
        message = "rot delta $delta > 0.05 at line $($match.LineNumber) (rapid spin)"
        line = $match.LineNumber
      }
    }
  }
  
  # Summary
  $result = @{
    file = Split-Path $Path -Leaf
    path = $Path
    timestamp = Get-Date -Format 'o'
    issues = $issues
    warnings = $warnings
    info = $info
    verdict = if ($issues.Count -eq 0) { 'PASS' } else { 'FAIL' }
    score = if ($issues.Count -eq 0 -and $warnings.Count -eq 0) { 100 } 
            elseif ($issues.Count -eq 0) { 80 - ($warnings.Count * 5) }
            else { 0 }
  }
  
  return $result
}

# Main
$result = Test-PresetSafety -Path $PresetPath

# Output
$severity = if ($result.verdict -eq 'PASS') { 'Green' } else { 'Red' }
Write-Host "[$severity] Preset: $($result.file)" -ForegroundColor $(if ($result.verdict -eq 'PASS') { 'Green' } else { 'Red' })
Write-Host "  Verdict: $($result.verdict)" -ForegroundColor $(if ($result.verdict -eq 'PASS') { 'Green' } else { 'Yellow' })
Write-Host "  Score:   $($result.score)/100"

if ($result.issues.Count -gt 0) {
  Write-Host "`n  Issues ($($result.issues.Count)):" -ForegroundColor Red
  $result.issues | ForEach-Object {
    Write-Host "    [$($_.rule)] $($_.message)" -ForegroundColor Red
    if ($_.suggestedFix) {
      Write-Host "      Fix: $($_.suggestedFix)" -ForegroundColor Yellow
    }
  }
}

if ($result.warnings.Count -gt 0) {
  Write-Host "`n  Warnings ($($result.warnings.Count)):" -ForegroundColor Yellow
  $result.warnings | ForEach-Object {
    Write-Host "    [$($_.rule)] $($_.message)" -ForegroundColor Yellow
  }
}

if ($result.info.Count -gt 0) {
  Write-Host "`n  Info ($($result.info.Count)):" -ForegroundColor Cyan
  $result.info | ForEach-Object {
    Write-Host "    [$($_.rule)] $($_.message)" -ForegroundColor Cyan
  }
}

# JSON output
if ($OutputJson) {
  $dir = Split-Path $OutputJson -Parent
  if ($dir -and -not (Test-Path $dir)) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
  }
  $result | ConvertTo-Json -Depth 4 | Out-File $OutputJson -Encoding utf8
  Write-Host "`nJSON report: $OutputJson" -ForegroundColor Green
}

# Exit code
if ($result.verdict -eq 'PASS') { exit 0 } else { exit 1 }

