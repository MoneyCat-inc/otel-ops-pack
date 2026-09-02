# Guard: Block Inflated Metrics (77×, 196.7)
# Fails CI if inflated performance claims are detected in production files.
# Enhanced with Unicode, HTML entities, and worded variants.
#
# 2026-09-02 repair (ECRR_DOCS_TRUTH_SWEEP_20260902 follow-up #2). The guard had been a silent
# no-op since 2025-10-20:
#   1. It shelled out to ripgrep, which the GitHub-hosted runner does not have; the
#      CommandNotFound error went to the discarded error stream, zero lines came back, and the
#      guard passed on every run. (With rg present the exclude globs were splatted as bare
#      positional arguments, which rg treats as PATHS -> exit 2, also discarded.)
#      docs/status.html carried "77× throughput uplift" from 2026-08-28 through sixteen green
#      Gate Verify runs. The scan is now pure PowerShell over git-tracked files — no external
#      search tool to be missing, and the same file set CI checks out.
#   2. `docs/*.md` was non-recursive, so docs/BossCat/** was never scanned. Now docs/**/*.md.
#   3. The 196.7 pattern used a look-ahead that rg's default regex engine rejects (parse error,
#      again swallowed). Rewritten without look-around.
#   4. Any scan error now fails closed instead of passing.
#   5. Retraction records legitimately name the banned figures. A line whose wording shows it
#      documents the ban (retracted / banned / inflated / unverified / unsubstantiated / zombie /
#      "-> 7×" / ❌) is allowed, and a file carrying the token `inflated-metrics:allow-file`
#      (policy records that quote the patterns verbatim) is skipped. Both are visible in the
#      summary so an allowance can never hide silently.
#   6. A self-test runs first so a broken pattern set or filter fails the guard, never passes it.

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

Write-Host "🛡️ Guarding against inflated metrics..." -ForegroundColor Cyan

# Banned patterns (hardened with BossCat OEM guidance). .NET and rg syntax-compatible: no look-around.
$bannedPatterns = @(
    # Core patterns
    '77\s*[x×✕]',
    '7\s*7\s*[x×✕]',
    # HTML entities
    '77\s*&times;',
    '77\s*&#215;',
    '77&nbsp;[x×✕]',
    '77&nbsp;&times;',
    # Worded forms
    'seventy[-\s]?seven\s*(times|x|×|✕)',
    # Derived value (196.7 / 196,7 not followed by another digit)
    '196[.,]7([^0-9]|$)'
)

# Production file globs (rg -g). docs is recursive; archives are excluded below.
$productionGlobs = @(
    'docs/**/*.md',
    'CHAR/ECRR/ECRR_REPORTS/*.md',
    'DELT/ARTF/*.json',
    '*.html',
    'README*.md'
)

# Archived / historical / mirrored content is out of scope.
$excludeGlobs = @(
    '!**/archive/**',
    '!**/history/**',
    '!**/deprecated/**',
    '!**/legacy/**',
    '!CHAR/PRSV/**',
    '!CHAR/DOCS/**',
    '!**/node_modules/**',
    '!.git/**'
)

# A matching line is allowed when its own wording shows it documents the ban rather than making the claim.
$retractionContext = '(?i)retract|banned|inflated|unverified|unsubstantiated|zombie|-> ?7×|→ ?7×|❌'
# A file containing this token (policy records quoting the patterns verbatim) is skipped entirely.
$allowFileToken = 'inflated-metrics:allow-file'

# --- Self-test: the pattern set and the context filter must behave before the tree is trusted ---
$mustCatch = @(
    'Throughput: 77× maintained', '77x faster', '7 7 x uplift', '77&times; faster',
    '77&#215;', '77&nbsp;x', 'seventy-seven times', 'seventy seven x', '196.7 logs/sec', '196,7 logs/sec'
)
$mustAllow = @(
    'Performance thresholds met (see test evidence)', 'p95 1.92ms', '1967 records', '196.75 is not derived', '7× uplift'
)
foreach ($sample in $mustCatch) {
    $caught = $false
    foreach ($pattern in $bannedPatterns) { if ($sample -match $pattern) { $caught = $true; break } }
    if (-not $caught) { Write-Host "❌ SELF-TEST FAILED: pattern set missed '$sample'" -ForegroundColor Red; exit 1 }
}
foreach ($sample in $mustAllow) {
    foreach ($pattern in $bannedPatterns) {
        if ($sample -match $pattern) { Write-Host "❌ SELF-TEST FAILED: false positive '$sample' on '$pattern'" -ForegroundColor Red; exit 1 }
    }
}
if (-not ('the 77× figure was retracted on 2025-10-20' -match $retractionContext)) {
    Write-Host "❌ SELF-TEST FAILED: retraction-context filter does not match a retraction line" -ForegroundColor Red; exit 1
}
if ('Throughput: 77× maintained' -match $retractionContext) {
    Write-Host "❌ SELF-TEST FAILED: retraction-context filter allows a bare claim" -ForegroundColor Red; exit 1
}

# --- Scan (pure PowerShell; no external tools) ---
$repoRoot = (Get-Location).Path
# Production set = git-tracked files only. That is what CI checks out, and it is what the
# original rg-based scan effectively saw (rg skips .gitignore'd trees). Enumerating the working
# tree instead pulled untracked local artifact and third_party trees into the scan (887 vs 739
# files, false positives in minified report HTML) — reported by the Cursor seat, 2026-09-02.
$tracked = @(& git ls-files -z 2>$null)
if ($LASTEXITCODE -ne 0 -or $tracked.Count -eq 0) {
    Write-Host "❌ 'git ls-files' failed or returned nothing — the guard cannot enumerate the tree; failing closed" -ForegroundColor Red
    exit 1
}
$tracked = ($tracked -join "`n") -split "`0" | Where-Object { $_ -ne '' }

$productionRegex = '^(docs/.+\.md|CHAR/ECRR/ECRR_REPORTS/[^/]+\.md|DELT/ARTF/[^/]+\.json|(.+/)?[^/]+\.html|(.+/)?README[^/]*\.md)$'
$excludeRegex = '(^|/)(archive|history|deprecated|legacy|node_modules|\.git)(/|$)|^CHAR/PRSV/|^CHAR/DOCS/'

$files = @{}
foreach ($rel in $tracked) {
    if ($rel -notmatch $productionRegex) { continue }
    if ($rel -match $excludeRegex) { continue }
    $files[$rel] = Join-Path $repoRoot $rel
}
if ($files.Count -eq 0) {
    Write-Host "❌ scan found no production files to check — failing closed (wrong working directory?)" -ForegroundColor Red
    exit 1
}

$rawLines = @()
foreach ($rel in ($files.Keys | Sort-Object)) {
    $found = Select-String -Path $files[$rel] -Pattern $bannedPatterns -AllMatches -ErrorAction Stop
    foreach ($hit in $found) {
        $rawLines += ('{0}:{1}:{2}' -f $rel, $hit.LineNumber, $hit.Line)
    }
}

$allowedByContext = @()
$allowedByFile = @()
$violations = @()
$allowFileCache = @{}

foreach ($line in $rawLines) {
    if ([string]::IsNullOrWhiteSpace($line)) { continue }
    $parts = $line -split ':', 3           # path:line:content (relative POSIX paths carry no colon)
    if ($parts.Count -lt 3) { $violations += $line; continue }
    $file = $parts[0]
    $text = $parts[2]
    if ($text -match $retractionContext) { $allowedByContext += $line; continue }
    if (-not $allowFileCache.ContainsKey($file)) {
        $allowFileCache[$file] = [bool](Select-String -Path $files[$file] -Pattern $allowFileToken -SimpleMatch -Quiet)
    }
    if ($allowFileCache[$file]) { $allowedByFile += $line; continue }
    $violations += $line
}

Write-Host ("  scanned {0} files; raw matches {1}; allowed as retraction context {2}; allowed by file token {3}" -f `
    $files.Count, $rawLines.Count, $allowedByContext.Count, $allowedByFile.Count) -ForegroundColor DarkGray
if ($allowedByFile.Count -gt 0) {
    $allowFiles = ($allowedByFile | ForEach-Object { ($_ -split ':', 2)[0] } | Sort-Object -Unique) -join ', '
    Write-Host "  allow-file records: $allowFiles" -ForegroundColor DarkGray
}

if ($violations.Count -gt 0) {
    Write-Host ""
    Write-Host "❌ INFLATED METRICS DETECTED" -ForegroundColor Red
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Red
    Write-Host ""
    Write-Host "Found $($violations.Count) occurrences of inflated performance claims:" -ForegroundColor Yellow
    Write-Host ""
    foreach ($violation in $violations | Select-Object -First 20) {
        Write-Host "  $violation" -ForegroundColor Yellow
    }
    Write-Host ""
    Write-Host "POLICY:" -ForegroundColor Red
    Write-Host "  • 77× claim is BANNED (unverified)" -ForegroundColor Red
    Write-Host "  • 196.7 logs/sec is BANNED (derived from 77×)" -ForegroundColor Red
    Write-Host ""
    Write-Host "ALLOWED:" -ForegroundColor Green
    Write-Host "  • 'Performance thresholds met (see test evidence)'" -ForegroundColor Green
    Write-Host "  • Link to reproducible benchmark results" -ForegroundColor Green
    Write-Host "  • Measured values with test report links" -ForegroundColor Green
    Write-Host "  • A retraction record: the line must say so (retracted / banned / unverified …)" -ForegroundColor Green
    Write-Host ""
    Write-Host "FIX:" -ForegroundColor Cyan
    Write-Host "  1. Remove inflated claims from production files" -ForegroundColor Cyan
    Write-Host "  2. Replace with verifiable statements" -ForegroundColor Cyan
    Write-Host "  3. Link to repeatable test evidence" -ForegroundColor Cyan
    Write-Host ""
    exit 1
}

Write-Host "✅ No inflated metrics detected in production files" -ForegroundColor Green
Write-Host ""
exit 0
