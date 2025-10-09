#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Fix path filters in IONA gate workflow
    
.DESCRIPTION
    Updates .github/workflows/iona-gate-verify.yml to use correct path filters
    that match the actual file locations in the repository.
    
.EXAMPLE
    .\scripts\fix-iona-workflow-paths.ps1
    
.NOTES
    Part of: IONA-GATE-001 - Final Path Fixes
#>

$ErrorActionPreference = "Stop"

Write-Host @"

╔═══════════════════════════════════════════╗
║   IONA Workflow Path Filter Fix          ║
║   Updating .github/workflows/            ║
╚═══════════════════════════════════════════╝

"@ -ForegroundColor Cyan

$workflowPath = ".github/workflows/iona-gate-verify.yml"

# Check file exists
if (-not (Test-Path $workflowPath)) {
    Write-Host "✗ Workflow file not found: $workflowPath" -ForegroundColor Red
    exit 1
}

Write-Host "✓ Found workflow file" -ForegroundColor Green

# Read content
$content = Get-Content $workflowPath -Raw

# Replace old path with new path
$oldPath = "workflows/iona-gate-verify.yml"
$newPath = ".github/workflows/iona-gate-verify.yml"

if ($content -match [regex]::Escape($oldPath)) {
    Write-Host "Updating path filter from '$oldPath' to '$newPath'..." -ForegroundColor Yellow
    $content = $content -replace [regex]::Escape($oldPath), $newPath
    
    # Also add additional paths
    $pushPathsSection = @"
    paths:
      - app/**
      - scripts/iona-snapshot.spec.ts
      - synthetic/send_iona_boot_span.py
      - docs/BossCat/IONA_ECRR_REPORT.md
      - .github/workflows/iona-gate-verify.yml
      - playwright.config.ts
      - lib/telemetry/**
"@

    $pullRequestPathsSection = @"
    paths:
      - app/**
      - scripts/iona-snapshot.spec.ts
      - synthetic/send_iona_boot_span.py
      - docs/BossCat/IONA_ECRR_REPORT.md
      - .github/workflows/iona-gate-verify.yml
      - playwright.config.ts
      - lib/telemetry/**
"@
    
    # Update push paths
    $content = $content -replace "(?s)push:\s*paths:\s*- app/\*\*\s*- scripts/iona-snapshot\.spec\.ts\s*- synthetic/send_iona_boot_span\.py\s*- docs/BossCat/IONA_ECRR_REPORT\.md\s*- \.github/workflows/iona-gate-verify\.yml", @"
push:
    paths:
      - app/**
      - scripts/iona-snapshot.spec.ts
      - synthetic/send_iona_boot_span.py
      - docs/BossCat/IONA_ECRR_REPORT.md
      - .github/workflows/iona-gate-verify.yml
      - playwright.config.ts
      - lib/telemetry/**
"@
    
    # Update pull_request paths
    $content = $content -replace "(?s)pull_request:\s*paths:\s*- app/\*\*\s*- scripts/iona-snapshot\.spec\.ts\s*- synthetic/send_iona_boot_span\.py\s*- docs/BossCat/IONA_ECRR_REPORT\.md(?!\s*-)", @"
pull_request:
    paths:
      - app/**
      - scripts/iona-snapshot.spec.ts
      - synthetic/send_iona_boot_span.py
      - docs/BossCat/IONA_ECRR_REPORT.md
      - .github/workflows/iona-gate-verify.yml
      - playwright.config.ts
      - lib/telemetry/**
"@
    
    # Write back
    $content | Set-Content $workflowPath -NoNewline
    
    Write-Host "✓ Workflow file updated" -ForegroundColor Green
} else {
    Write-Host "✓ Path filter already correct" -ForegroundColor Green
}

# Verify the change
Write-Host "`nVerifying updated paths..." -ForegroundColor Yellow
$updatedContent = Get-Content $workflowPath -Raw

if ($updatedContent -match [regex]::Escape(".github/workflows/iona-gate-verify.yml")) {
    Write-Host "✓ Correct path found: .github/workflows/iona-gate-verify.yml" -ForegroundColor Green
} else {
    Write-Host "✗ Path still incorrect" -ForegroundColor Red
    exit 1
}

if ($updatedContent -match [regex]::Escape("playwright.config.ts")) {
    Write-Host "✓ Additional path found: playwright.config.ts" -ForegroundColor Green
} else {
    Write-Host "⚠ Missing path: playwright.config.ts" -ForegroundColor Yellow
}

if ($updatedContent -match [regex]::Escape("lib/telemetry/")) {
    Write-Host "✓ Additional path found: lib/telemetry/**" -ForegroundColor Green
} else {
    Write-Host "⚠ Missing path: lib/telemetry/**" -ForegroundColor Yellow
}

Write-Host @"

╔═══════════════════════════════════════════╗
║   ✓ Path Filter Fix Complete             ║
╚═══════════════════════════════════════════╝

The workflow will now trigger on changes to:
  - app/**
  - scripts/iona-snapshot.spec.ts
  - synthetic/send_iona_boot_span.py
  - docs/BossCat/IONA_ECRR_REPORT.md
  - .github/workflows/iona-gate-verify.yml
  - playwright.config.ts
  - lib/telemetry/**

Next steps:
  1. Commit the updated workflow
  2. Run verification: pwsh scripts/verify-iona-gate.ps1
  3. Push and verify in GitHub Actions

"@ -ForegroundColor Green



