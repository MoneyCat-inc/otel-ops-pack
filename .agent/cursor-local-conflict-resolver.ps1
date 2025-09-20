# Cursor-Local Conflict Resolver
# Assists Codex-Cloud with PR conflict resolution, docs normalization, and maintenance patches

param(
    [Parameter(Mandatory=$false)]
    [string]$PR,
    
    [Parameter(Mandatory=$false)]
    [string]$Repo = "fubumaki/otel-ops-pack",
    
    [Parameter(Mandatory=$false)]
    [string]$Base,
    
    [Parameter(Mandatory=$false)]
    [string]$Head,
    
    [Parameter(Mandatory=$false)]
    [switch]$LocalOnly,
    
    [Parameter(Mandatory=$false)]
    [switch]$CreatePatch
)

# Non-negotiable guardrails
$MAX_FILES = 10
$MAX_LOC = 200

# Safety check function
function Test-SafetyConstraints {
    param([array]$ChangedFiles, [int]$TotalLines)
    
    if ($ChangedFiles.Count -gt $MAX_FILES) {
        Write-Error "Safety violation: $($ChangedFiles.Count) files changed (max: $MAX_FILES)"
        return $false
    }
    
    if ($TotalLines -gt $MAX_LOC) {
        Write-Error "Safety violation: $TotalLines lines changed (max: $MAX_LOC)"
        return $false
    }
    
    return $true
}

# Extract conflict information from git
function Get-ConflictInfo {
    param([string]$PR)
    
    try {
        # Get PR metadata
        $prData = gh pr view $PR --json baseRefName,headRefName,baseRepository,headRepository,title,body
        $baseRef = $prData | ConvertFrom-Json | Select-Object -ExpandProperty baseRefName
        $headRef = $prData | ConvertFrom-Json | Select-Object -ExpandProperty headRefName
        $baseRepo = $prData | ConvertFrom-Json | Select-Object -ExpandProperty baseRepository
        $headRepo = $prData | ConvertFrom-Json | Select-Object -ExpandProperty headRepository
        
        Write-Host "PR #$PR: $baseRepo/$baseRef ← $headRepo/$headRef" -ForegroundColor Green
        
        # Fetch latest refs
        git fetch --all --quiet
        
        # Create temporary branch to reproduce merge
        $tempBranch = "pr-conflict-check-$PR"
        git checkout -B $tempBranch "origin/$headRef" 2>$null
        
        # Attempt merge to surface conflicts
        $mergeResult = git merge --no-commit --no-ff "origin/$baseRef" 2>&1
        $hasConflicts = $LASTEXITCODE -ne 0
        
        if (-not $hasConflicts) {
            Write-Host "No conflicts detected in PR #$PR" -ForegroundColor Yellow
            git checkout - 2>$null
            git branch -D $tempBranch 2>$null
            return $null
        }
        
        # Get conflicted files
        $conflictedFiles = git diff --name-only --diff-filter=U
        
        $conflicts = @()
        foreach ($file in $conflictedFiles) {
            $conflict = @{
                File = $file
                Hunks = @()
            }
            
            # Extract conflict markers with context
            $content = Get-Content $file -Raw
            $lines = $content -split "`n"
            
            for ($i = 0; $i -lt $lines.Length; $i++) {
                if ($lines[$i] -match "^<<<<<<< ") {
                    $hunk = @{
                        StartLine = $i + 1
                        HeadMarker = $lines[$i]
                        HeadContent = @()
                        Separator = ""
                        BaseContent = @()
                        BaseMarker = ""
                    }
                    
                    # Collect head content
                    $i++
                    while ($i -lt $lines.Length -and $lines[$i] -notmatch "^=======") {
                        $hunk.HeadContent += $lines[$i]
                        $i++
                    }
                    
                    if ($i -lt $lines.Length) {
                        $hunk.Separator = $lines[$i]
                        $i++
                    }
                    
                    # Collect base content
                    while ($i -lt $lines.Length -and $lines[$i] -notmatch "^>>>>>>> ") {
                        $hunk.BaseContent += $lines[$i]
                        $i++
                    }
                    
                    if ($i -lt $lines.Length) {
                        $hunk.BaseMarker = $lines[$i]
                    }
                    
                    # Add context lines (before and after)
                    $contextStart = [Math]::Max(0, $hunk.StartLine - 4)
                    $contextEnd = [Math]::Min($lines.Length, $i + 3)
                    $hunk.ContextBefore = $lines[$contextStart..($hunk.StartLine - 2)]
                    $hunk.ContextAfter = $lines[($i + 1)..($contextEnd - 1)]
                    
                    $conflict.Hunks += $hunk
                }
            }
            
            $conflicts += $conflict
        }
        
        # Cleanup
        git checkout - 2>$null
        git branch -D $tempBranch 2>$null
        
        return @{
            PR = $PR
            BaseRef = $baseRef
            HeadRef = $headRef
            BaseRepo = $baseRepo.nameWithOwner
            HeadRepo = $headRepo.nameWithOwner
            Conflicts = $conflicts
        }
        
    } catch {
        Write-Error "Failed to extract conflict info: $($_.Exception.Message)"
        return $null
    }
}

# Generate canonical resolution for common patterns
function Get-CanonicalResolution {
    param([hashtable]$ConflictHunk)
    
    $headText = $ConflictHunk.HeadContent -join "`n"
    $baseText = $ConflictHunk.BaseContent -join "`n"
    
    # Pattern matching for common conflict types
    if ($headText -match "Weekly.*setup-weekly-audit\.ps1.*hands-off" -and 
        $baseText -match "Weekly.*setup-weekly-audit\.ps1") {
        
        return "- **Weekly:** `setup-weekly-audit.ps1` → automated evidence trail (hands-off). Run `make-audit-pack.ps1` on demand for a manual capture."
    }
    
    # Default: prefer the more complete version
    if ($headText.Length -gt $baseText.Length) {
        return $headText
    } else {
        return $baseText
    }
}

# Generate Codex-Cloud brief comment
function New-CodexBrief {
    param([hashtable]$ConflictInfo)
    
    $comment = @"
@codex please resolve this conflict set with the canonical wording below

PR: #$($ConflictInfo.PR) — $($ConflictInfo.BaseRepo)
Base: ``$($ConflictInfo.BaseRef)``  
Head: ``$($ConflictInfo.HeadRef)``

## Context
We're normalizing wording in documentation sections. Preserve automation policy and concise style.

"@

    foreach ($conflict in $ConflictInfo.Conflicts) {
        $comment += @"

### ``$($conflict.File)``

#### Conflict hunks
````diff
"@

        foreach ($hunk in $conflict.Hunks) {
            $comment += "`n$($hunk.HeadMarker)"
            foreach ($line in $hunk.HeadContent) {
                $comment += "`n-$line"
            }
            $comment += "`n$($hunk.Separator)"
            foreach ($line in $hunk.BaseContent) {
                $comment += "`n+$line"
            }
            $comment += "`n$($hunk.BaseMarker)"
        }
        
        $comment += @"
````

#### Canonical resolution (apply exactly)
````markdown
"@

        foreach ($hunk in $conflict.Hunks) {
            $canonical = Get-CanonicalResolution $hunk
            $comment += "`n$canonical"
        }
        
        $comment += @"
````

#### Style/intent rules
- Keep **"(hands-off)"** parenthetical (automation policy)
- Prefer concise, declarative style  
- Use **"on demand"** (no hyphen)
- Preserve the arrow **→** for action/result mapping

#### Where to patch
- File: ``$($conflict.File)``
- Replace conflict markers with canonical resolution

#### Idempotent awk fixer (optional)
````bash
awk '
  BEGIN{h=0}
  /^##[[:space:]]+🔄[[:space:]]+Periodic[[:space:]]+Maintenance/{h=1}
  h==1 && /^- \*\*Weekly:\*\* `setup-weekly-audit\.ps1`/{
    print "- **Weekly:** `setup-weekly-audit.ps1` → automated evidence trail (hands-off). Run `make-audit-pack.ps1` on demand for a manual capture."
    next
  }
  {print}
' "$($conflict.File)" > "$($conflict.File).tmp" && mv "$($conflict.File).tmp" "$($conflict.File)"
````

"@
    }
    
    $comment += @"

### Acceptance criteria
- No merge markers remain (``<<<<<<<``, ``=======``, ``>>>>>>>``)
- Canonical resolution applied exactly as specified
- No unrelated lines changed
- Style rules followed consistently

"@

    return $comment
}

# Create minimal patch
function New-MinimalPatch {
    param([hashtable]$ConflictInfo)
    
    if (-not $CreatePatch) {
        return $null
    }
    
    # Create patch branch
    $patchBranch = "cursor-local/conflict-resolve-$($ConflictInfo.PR)"
    git checkout -B $patchBranch "origin/$($ConflictInfo.HeadRef)" 2>$null
    
    $changedFiles = @()
    $totalLines = 0
    
    foreach ($conflict in $ConflictInfo.Conflicts) {
        $file = $conflict.File
        $content = Get-Content $file -Raw
        $lines = $content -split "`n"
        $newLines = @()
        
        for ($i = 0; $i -lt $lines.Length; $i++) {
            if ($lines[$i] -match "^<<<<<<< ") {
                # Skip conflict markers and content, apply canonical resolution
                $canonical = Get-CanonicalResolution @{
                    HeadContent = @()
                    BaseContent = @()
                }
                $newLines += $canonical
                
                # Skip to end of conflict
                while ($i -lt $lines.Length -and $lines[$i] -notmatch "^>>>>>>> ") {
                    $i++
                }
                # Skip the >>>>>>> marker too
                $i++
            } else {
                $newLines += $lines[$i]
            }
        }
        
        $newContent = $newLines -join "`n"
        Set-Content $file $newContent -NoNewline
        
        $changedFiles += $file
        $totalLines += ($newLines.Length - $lines.Length)
    }
    
    if (-not (Test-SafetyConstraints $changedFiles $totalLines)) {
        git checkout - 2>$null
        git branch -D $patchBranch 2>$null
        return $null
    }
    
    # Commit the patch
    git add $changedFiles
    $commitMessage = "docs(maintenance): resolve conflicts in PR #$($ConflictInfo.PR); normalize wording"
    git commit -m $commitMessage
    
    # Push patch branch
    git push -u origin $patchBranch
    
    git checkout - 2>$null
    
    return @{
        Branch = $patchBranch
        ChangedFiles = $changedFiles
        TotalLines = $totalLines
        CommitMessage = $commitMessage
    }
}

# Main execution
function Main {
    if (-not $PR -and -not $LocalOnly) {
        Write-Host "Usage: .\cursor-local-conflict-resolver.ps1 -PR <number> [-Repo <repo>] [-CreatePatch]" -ForegroundColor Yellow
        Write-Host "   or: .\cursor-local-conflict-resolver.ps1 -LocalOnly" -ForegroundColor Yellow
        return
    }
    
    if ($LocalOnly) {
        # Check for local conflicts
        $conflictedFiles = git diff --name-only --diff-filter=U
        if ($conflictedFiles) {
            Write-Host "Local conflicts detected:" -ForegroundColor Red
            $conflictedFiles | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
            Write-Host "`nRun 'git status' for details" -ForegroundColor Yellow
        } else {
            Write-Host "No local conflicts detected" -ForegroundColor Green
        }
        return
    }
    
    # Extract conflict information
    $conflictInfo = Get-ConflictInfo $PR
    if (-not $conflictInfo) {
        return
    }
    
    Write-Host "Found $($conflictInfo.Conflicts.Count) conflicted files" -ForegroundColor Yellow
    
    # Generate Codex-Cloud brief
    $brief = New-CodexBrief $conflictInfo
    
    # Post comment to PR
    try {
        $commentFile = [System.IO.Path]::GetTempFileName()
        Set-Content $commentFile $brief
        gh pr comment $PR --body-file $commentFile
        Remove-Item $commentFile
        Write-Host "Posted conflict resolution brief to PR #$PR" -ForegroundColor Green
    } catch {
        Write-Host "Failed to post comment: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "`nBrief content:" -ForegroundColor Yellow
        Write-Host $brief
    }
    
    # Create patch if requested
    if ($CreatePatch) {
        $patch = New-MinimalPatch $conflictInfo
        if ($patch) {
            Write-Host "Created patch branch: $($patch.Branch)" -ForegroundColor Green
            Write-Host "Changed files: $($patch.ChangedFiles -join ', ')" -ForegroundColor Green
            Write-Host "Total lines: $($patch.TotalLines)" -ForegroundColor Green
        } else {
            Write-Host "Patch creation failed or skipped due to safety constraints" -ForegroundColor Yellow
        }
    }
}

# Execute main function
Main
