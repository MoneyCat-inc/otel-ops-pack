#!/usr/bin/env pwsh
# auto-resolve-conflicts.ps1 - Reusable merge conflict detector and resolver
# 
# Modes:
#   detect  - Scan for conflict markers, report findings
#   ours    - Resolve conflicts by keeping "ours" version
#   theirs  - Resolve conflicts by keeping "theirs" version  
#   union   - Merge both versions (our changes + their changes)
#
# Usage:
#   pwsh -File scripts/auto-resolve-conflicts.ps1 -Mode detect -ReportPath artifacts/conflict-scan.txt
#   pwsh -File scripts/auto-resolve-conflicts.ps1 -Mode ours -Stage -Exclude @('*.template.md')
#
# ECRR Compliance: Examine (scan state) → Clean (resolve conflicts) → Report (artifact) → Role (automation)

[CmdletBinding()]
param(
    [ValidateSet("detect", "ours", "theirs", "union")]
    [string]$Mode = "detect",
    
    [switch]$Stage,
    
    [string[]]$Exclude,
    
    [string]$ReportPath,
    
    [switch]$Quiet
)

$script:RepoRoot = (Get-Location).ProviderPath

# Common conflict markers to detect
$CONFLICT_MARKERS = @(
    '^<<<<<<< ',
    '^=======$',
    '^>>>>>>> '
)

function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    if ($Quiet -and $Level -eq "INFO") { return }
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $prefix = switch ($Level) {
        "ERROR" { "🔴" }
        "WARN"  { "🟡" }
        "INFO"  { "ℹ️" }
        "SUCCESS" { "✅" }
        default { "📝" }
    }
    
    Write-Host "[$timestamp] $prefix $Message" -ForegroundColor $(
        switch ($Level) {
            "ERROR" { "Red" }
            "WARN"  { "Yellow" }
            "SUCCESS" { "Green" }
            default { "White" }
        }
    )
}

function New-ExclusionRegexes {
    param([string[]]$ExcludePatterns)
    
    $regexes = @()
    foreach ($pattern in $ExcludePatterns) {
        try {
            # Convert glob patterns to regex
            $regex = $pattern -replace '\.', '\.' -replace '\*', '.*' -replace '\?', '.'
            $regexes += [regex]::new("^$regex$", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
            Write-Log "Added exclusion pattern: $pattern -> $regex" "INFO"
        }
        catch {
            Write-Log "Invalid exclusion pattern '$pattern': $($_.Exception.Message)" "WARN"
        }
    }
    return $regexes
}

function Test-IsExcluded {
    param(
        [string]$FilePath,
        [regex[]]$ExclusionRegexes
    )

    if (-not $ExclusionRegexes -or $ExclusionRegexes.Count -eq 0) {
        return $false
    }

    $relativePath = $FilePath
    if ($script:RepoRoot) {
        try {
            $relativePath = [System.IO.Path]::GetRelativePath($script:RepoRoot, $FilePath)
        } catch {
            $relativePath = $FilePath
        }
    }

    $relativePath = $relativePath -replace '^\.\\', '' -replace '^\./', ''
    $normalizedPath = ($relativePath -replace '\\', '/').TrimStart('/')

    foreach ($regex in $ExclusionRegexes) {
        if ($regex.IsMatch($normalizedPath)) {
            Write-Log "Excluding file: $normalizedPath (matches $($regex.ToString()))" "INFO"
            return $true
        }
    }
    return $false
}

function Get-ConflictSummary {
    param([regex[]]$ExcludeRegexes)

    Write-Log "Scanning repository for merge conflict markers..." "INFO"

    $markerCounts = @{}
    foreach ($marker in $CONFLICT_MARKERS) {
        $markerCounts[$marker] = 0
    }

    $conflictedFiles = @()
    $totalMarkers = 0

    $startMatches = @()
    $endMatches = @()
    try {
        $startMatches = (& git grep -l '<<<<<<< ' 2>$null)
        $endMatches = (& git grep -l '>>>>>>>' 2>$null)
    } catch {
        Write-Log "git grep unavailable: $($_.Exception.Message)" "WARN"
    }

    if (-not $startMatches) { $startMatches = @() }
    if (-not $endMatches) { $endMatches = @() }

    $endSet = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
    foreach ($file in $endMatches) {
        $trimmed = $file.Trim()
        if ($trimmed) { [void]$endSet.Add($trimmed) }
    }

    $candidates = @()
    foreach ($file in $startMatches) {
        $trimmed = $file.Trim()
        if (-not $trimmed) { continue }
        if ($endSet.Contains($trimmed)) {
            $candidates += $trimmed
        }
    }

    if ($candidates.Count -eq 0) {
        Write-Log "No merge conflict markers detected in tracked files." "INFO"
        return [PSCustomObject]@{
            ConflictedFiles = @()
            TotalMarkers = 0
            MarkerCounts = $markerCounts
        }
    }

    $spinner = @('⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏')
    $spinnerIndex = 0
    $lastUpdate = Get-Date
    $processed = 0
    $totalCandidates = $candidates.Count

    foreach ($relativePath in $candidates) {
        $processed++
        $now = Get-Date
        if (($now - $lastUpdate).TotalMilliseconds -gt 50) {
            $spinnerIndex = ($spinnerIndex + 1) % $spinner.Count
            $progress = [math]::Round(($processed / $totalCandidates) * 100)
            Write-Host "`r$($spinner[$spinnerIndex]) Reviewing conflicts... $processed/$totalCandidates ($progress%)" -NoNewline -ForegroundColor Cyan
            $lastUpdate = $now
        }

        $fullPath = Join-Path $script:RepoRoot $relativePath
        if (Test-IsExcluded -FilePath $fullPath -ExclusionRegexes $ExcludeRegexes) { continue }
        if (-not (Test-Path $fullPath)) { continue }

        try {
            $content = Get-Content -Path $fullPath -Raw -ErrorAction Stop
        } catch {
            Write-Log "Error reading file ${relativePath}: $($_.Exception.Message)" "WARN"
            continue
        }

        if (-not $content) { continue }

        $fileMarkers = @{}
        foreach ($marker in $CONFLICT_MARKERS) {
            $matches = [regex]::Matches($content, $marker, [System.Text.RegularExpressions.RegexOptions]::Multiline)
            if ($matches.Count -gt 0) {
                $markerCounts[$marker] += $matches.Count
                $fileMarkers[$marker] = $matches.Count
            }
        }

        $hasStartMarker = $fileMarkers.ContainsKey($CONFLICT_MARKERS[0]) -and $fileMarkers[$CONFLICT_MARKERS[0]] -gt 0
        $hasEndMarker = $fileMarkers.ContainsKey($CONFLICT_MARKERS[2]) -and $fileMarkers[$CONFLICT_MARKERS[2]] -gt 0

        if ($hasStartMarker -and $hasEndMarker) {
            $totalMarkers += ($fileMarkers.Values | Measure-Object -Sum).Sum
            $conflictedFiles += [PSCustomObject]@{
                Path = ($relativePath -replace '\\', '/')
                Markers = $fileMarkers
                TotalMarkers = ($fileMarkers.Values | Measure-Object -Sum).Sum
            }
        }
    }

    Write-Host "`r✅ Scan complete! Processed $totalCandidates files. Found $($conflictedFiles.Count) files with conflicts." -ForegroundColor Green

    return [PSCustomObject]@{
        ConflictedFiles = $conflictedFiles
        TotalMarkers = $totalMarkers
        MarkerCounts = $markerCounts
    }
}

function Resolve-ConflictsInFile {
    param(
        [string]$FilePath,
        [string]$ResolutionMode
    )
    
    Write-Log "Resolving conflicts in: $FilePath using mode: $ResolutionMode" "INFO"
    
    try {
        $content = Get-Content -Path $FilePath -Raw
        $originalContent = $content
        
        switch ($ResolutionMode) {
            "ours" {
                # Remove conflict markers and keep our version (between <<<<<<< and =======)
                $content = $content -replace '(?s)<<<<<<< .*?=======.*?>>>>>>> .*?(?=\n|$)', ''
                # Also remove any remaining ======= lines that might be orphaned
                $content = $content -replace '^=======.*$', ''
            }
            "theirs" {
                # Remove conflict markers and keep their version (between ======= and >>>>>>>)
                $content = $content -replace '(?s)<<<<<<< .*?=======.*?>>>>>>> .*?(?=\n|$)', ''
                # Remove our version lines (between <<<<<<< and =======)
                $content = $content -replace '(?s)<<<<<<< .*?=======', ''
            }
            "union" {
                # Merge both versions: remove conflict markers but keep both content blocks
                $content = $content -replace '(?s)<<<<<<< .*?=======', ''
                $content = $content -replace '(?s)>>>>>>> .*?(?=\n|$)', ''
                $content = $content -replace '^=======.*$', ''
            }
        }
        
        # Clean up any remaining empty lines or artifacts
        $content = $content -replace '\r?\n\s*\r?\n\s*\r?\n', "`r`n`r`n"
        
        # Only write if content changed
        if ($content -ne $originalContent) {
            Set-Content -Path $FilePath -Value $content -NoNewline
            Write-Log "Successfully resolved conflicts in: $FilePath" "SUCCESS"
            return $true
        } else {
            Write-Log "No changes needed for: $FilePath" "INFO"
            return $false
        }
    }
    catch {
        Write-Log "Error resolving conflicts in $FilePath : $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Write-Report {
    param(
        [PSCustomObject]$Summary,
        [string]$ReportPath
    )
    
    $reportContent = @"
# Merge Conflict Scan Report
Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss UTC")
Mode: detect
Repository: $(Get-Location)

## Summary
- Conflicted files: $(if ($Summary.ConflictedFiles.Count -eq 0) { "none" } else { $Summary.ConflictedFiles.Count })
- Total conflict markers: $($Summary.TotalMarkers)

## Marker Breakdown
"@

    foreach ($marker in $CONFLICT_MARKERS) {
        $count = $Summary.MarkerCounts[$marker]
        $reportContent += "`n- $marker : $count"
    }

    if ($Summary.ConflictedFiles.Count -gt 0) {
        $reportContent += "`n`n## Conflicted Files`n"
        foreach ($file in $Summary.ConflictedFiles) {
            $reportContent += "`n### $($file.Path)`n"
            $reportContent += "- Total markers: $($file.TotalMarkers)`n"
            foreach ($marker in $CONFLICT_MARKERS) {
                if ($file.Markers.ContainsKey($marker)) {
                    $reportContent += "- $marker : $($file.Markers[$marker])`n"
                }
            }
        }
    } else {
        $reportContent += "`n`n## Conflicted Files`n- none`n"
    }

    $reportContent += "`n`n## Marker Hits`n- none`n"

    if ($ReportPath) {
        try {
            # Ensure directory exists
            $reportDir = Split-Path -Parent $ReportPath
            if (-not (Test-Path $reportDir)) {
                New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
            }
            
            Set-Content -Path $ReportPath -Value $reportContent
            Write-Log "Report written to: $ReportPath" "SUCCESS"
        }
        catch {
            Write-Log "Error writing report to $ReportPath : $($_.Exception.Message)" "ERROR"
            Write-Host $reportContent
        }
    } else {
        Write-Host $reportContent
    }
}

# Main execution
try {
    Write-Log "Starting merge conflict detection/resolution..." "INFO"
    Write-Log "Mode: $Mode" "INFO"
    Write-Log "Report path: $(if ($ReportPath) { $ReportPath } else { 'console only' })" "INFO"
    
    # Default exclusions for common template/test files
    $defaultExclude = @(
        '.agent/*',
        'docs/ECRR_REPORTS/*',
        '*.prompt.md',
        '*.template.md',
        'test-conflict-resolution.md',
        'node_modules/*',
        'archive/*',
        'third_party/*',
        '.git/*',
        'artifacts/*',
        'logs/*',
        '*.log'
    )
    
    $allExclusions = if ($Exclude) { $defaultExclude + $Exclude } else { $defaultExclude }
    $excludeRegexes = New-ExclusionRegexes -ExcludePatterns $allExclusions
    
    $summary = Get-ConflictSummary -Regexes $excludeRegexes
    
    if ($Mode -eq "detect") {
        Write-Report -Summary $summary -ReportPath $ReportPath
        
        if ($summary.ConflictedFiles.Count -eq 0) {
            Write-Log "No merge conflicts detected!" "SUCCESS"
            exit 0
        } else {
            Write-Log "Found $($summary.ConflictedFiles.Count) files with merge conflicts" "ERROR"
            exit 1
        }
    }
    else {
        # Resolution modes
        if ($summary.ConflictedFiles.Count -eq 0) {
            Write-Log "No conflicts to resolve" "INFO"
            exit 0
        }
        
        $resolvedCount = 0
        foreach ($file in $summary.ConflictedFiles) {
            $resolved = Resolve-ConflictsInFile -FilePath $file.Path -ResolutionMode $Mode
            if ($resolved) { $resolvedCount++ }
            
            if ($Stage) {
                try {
                    git add $file.Path
                    Write-Log "Staged resolved file: $($file.Path)" "INFO"
                }
                catch {
                    Write-Log "Error staging file $($file.Path): $($_.Exception.Message)" "WARN"
                }
            }
        }
        
        Write-Log "Resolved conflicts in $resolvedCount of $($summary.ConflictedFiles.Count) files" "SUCCESS"
        exit 0
    }
}
catch {
    Write-Log "Unexpected error: $($_.Exception.Message)" "ERROR"
    Write-Log "Stack trace: $($_.ScriptStackTrace)" "ERROR"
    exit 1
}