# See C:\otel\docs\comfort cat
#Requires -Version 7
<#
.SYNOPSIS
  Scaffolds Comfort Cat creative guidelines and mirrors them to Windows path.
.PARAMETER RepoDir
  In-repo canonical docs dir (default: docs/comfort-cat)
.PARAMETER WinDir
  Windows mirror path for local teams (default: C:\otel\docs\comfort cat)
.PARAMETER Force
  Overwrite existing files
#>
param(
  [string]$RepoDir = (Join-Path $PSScriptRoot '..\docs\comfort-cat'),
  [string]$WinDir = 'C:\otel\docs\comfort cat',
  [switch]$Force
)

$files = @(
  'README.md','palette.md','type.md','motion.md','copy.md',
  'storyboard.md','proofpoints.md','accessibility.md','success-criteria.md'
)

function Ensure-Dir($p){
  New-Item -ItemType Directory -Force -Path $p | Out-Null
}

function Write-Stub($path, $content){
  if((Test-Path $path) -and -not $Force){ return }
  $content | Set-Content -Path $path -Encoding UTF8
}

$today = (Get-Date).ToString('yyyy-MM-dd')

$stubs = @{
  'README.md' = @"
# Comfort Cat Creative Guidelines
Authoritative source. Updated: $today

Start here. Each section governs creative assets across this repo.
- palette.md, type.md, motion.md, copy.md, storyboard.md, proofpoints.md, accessibility.md, success-criteria.md
- Windows mirror: C:\otel\docs\comfort cat

Implementation rule: creative-facing files include a header comment:
See C:\otel\docs\comfort cat
"@
  'palette.md' = @"
# Palette
Status: Draft | Owner: Design

- Tokens: charcoal #1B1E22, slate #2A2F36, fog #A7B0B7, neon accent #37FFC4 or #FF3DBE
- Contrast: Body >= 4.5:1, Headings >= 3:1
- Usage: Neon accents only for live signals; avoid alarmist reds.
"@
  'type.md' = @"
# Typography
Status: Draft | Owner: Design

- Headlines: Söhne / Inter Tight / SF Pro Display (semibold)
- Supporting: Inter / Source Sans, 1.25x line-height
- Data: JetBrains Mono / IBM Plex Mono for metrics
"@
  'motion.md' = @"
# Motion
Status: Draft | Owner: Design

- WARN ticker cadence ~15s for calm status
- Batch pulse: 200ms glow, maintain gentle easing
- Always expose reduce-motion friendly fallback
"@
  'copy.md' = @"
# Voice & Copy
Status: Draft | Owner: Editorial

Primary CTA: "Sleep easy. We've got the signal."
Tone: Warm, concise, lightly clever. Keep copy sparse; rely on visuals.
"@
  'storyboard.md' = @"
# Storyboard
Status: Draft | Owner: Editorial/Design

Key beats:
1. Comfort Cat title over calm gradient
2. Logs zoom with tooltip flare
3. Metrics glide into view with neon accent
4. Trace ribbons animate through control room
5. CTA plate fades in with promised outcome
"@
  'proofpoints.md' = @"
# Proof Points
Status: Draft | Owner: Engineering

- 200 ms batch windows / 256-record bursts
- ~50% log volume reduction via filters
- 7-day log retention with daily audit
Update when pipeline or demos change.
"@
  'accessibility.md' = @"
# Accessibility & Inclusivity
Status: Draft | Owner: QA/Design

- Adhere to WCAG AA contrast
- Provide captions and transcripts for motion assets
- Offer motion-sensitive alt version (fade/pulse only)
"@
  'success-criteria.md' = @"
# Success Criteria (Pre-Release)
Status: Draft | Owner: PM

- Visual treatments match palette and type specs
- Motion reads calm, not sluggish; reduce-motion path works
- Proof points visible and accurate
- Accessibility checks documented and passing
"@
}

Ensure-Dir $RepoDir
Ensure-Dir (Join-Path $RepoDir 'assets')

foreach($f in $files){
  if($stubs.ContainsKey($f)){
    Write-Stub (Join-Path $RepoDir $f) $stubs[$f]
  }
}

Ensure-Dir $WinDir
Copy-Item -Path (Join-Path $RepoDir '*') -Destination $WinDir -Recurse -Force

Write-Host "`n[comfort] Scaffolded" -ForegroundColor Green
Get-ChildItem $RepoDir | Select-Object Name, Length, LastWriteTime | Format-Table
Write-Host "`n[comfort] Mirrored -> $WinDir" -ForegroundColor Green