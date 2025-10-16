Param(
  [Parameter(Mandatory=$false)][string]$MilkDropDir,
  [switch]$Launch
)

$ErrorActionPreference = 'Stop'

function Resolve-MilkDropDir {
  param([string]$Hint)
  if ($Hint -and (Test-Path -LiteralPath $Hint)) { return (Resolve-Path -LiteralPath $Hint).Path }

  $candidates = @(
    "$env:ProgramFiles\\MilkDrop3",
    "$env:ProgramFiles(x86)\\MilkDrop3",
    (Join-Path $PSScriptRoot '..' '..' 'tools' 'MilkDrop3')
  )
  foreach ($c in $candidates) {
    if (Test-Path -LiteralPath $c -PathType Container) { return (Resolve-Path -LiteralPath $c).Path }
  }

  try {
    Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
    $fbd = New-Object System.Windows.Forms.FolderBrowserDialog
    $fbd.Description = 'Select your MilkDrop3 folder (contains MilkDrop3.exe)'
    $null = $fbd.ShowDialog()
    if ($fbd.SelectedPath) { return $fbd.SelectedPath }
  } catch {
    # Fallback to prompt
  }

  $manual = Read-Host 'Enter path to MilkDrop3 folder (contains MilkDrop3.exe)'
  if (-not (Test-Path -LiteralPath $manual -PathType Container)) {
    throw "Invalid MilkDrop path: $manual"
  }
  return (Resolve-Path -LiteralPath $manual).Path
}

function Copy-Preset {
  param([string]$TargetDir)
  $srcPreset = Join-Path $PSScriptRoot '..' '..' 'docs' 'BossCat' 'visuals' 'Resonai - Default (Neon Pulse).milk'
  if (-not (Test-Path -LiteralPath $srcPreset)) {
    throw "Preset not found at $srcPreset"
  }
  $presetsDir = Join-Path $TargetDir 'presets'
  if (-not (Test-Path -LiteralPath $presetsDir)) {
    New-Item -ItemType Directory -Path $presetsDir -Force | Out-Null
  }
  $dst = Join-Path $presetsDir (Split-Path $srcPreset -Leaf)
  Copy-Item -LiteralPath $srcPreset -Destination $dst -Force
  Write-Host "[OK] Installed preset to: $dst"
}

function Start-MilkDropIfPresent {
  param([string]$Dir)
  $exe = Join-Path $Dir 'MilkDrop3.exe'
  if (Test-Path -LiteralPath $exe) {
    Write-Host "Launching MilkDrop3 ..."
    Start-Process -FilePath $exe -WorkingDirectory $Dir | Out-Null
  } else {
    Write-Warning "MilkDrop3.exe not found in $Dir. Launch manually after install."
  }
}

try {
  $target = Resolve-MilkDropDir -Hint $MilkDropDir
  Copy-Preset -TargetDir $target
  if ($Launch.IsPresent) { Start-MilkDropIfPresent -Dir $target }
  Write-Host "Resonai Default installed. Load it via 'L' → 'Resonai - Default (Neon Pulse)'."
} catch {
  Write-Error $_
  exit 1
}

