# Patch Validator for Conflict Resolution
# Validates patches before applying and provides safety checks

param(
    [Parameter(Mandatory=$false)]
    [string]$PatchFile,
    
    [Parameter(Mandatory=$false)]
    [string]$Branch,
    
    [Parameter(Mandatory=$false)]
    [switch]$DryRun,
    
    [Parameter(Mandatory=$false)]
    [switch]$Validate,
    
    [Parameter(Mandatory=$false)]
    [switch]$Apply
)

# Safety constraints
$MAX_FILES = 10
$MAX_LOC = 200
$FORBIDDEN_PATTERNS = @(
    'password\s*=\s*["\''][^"\'\']+["\'\']',
    'token\s*=\s*["\''][^"\'\']+["\'\']',
    'secret\s*=\s*["\''][^"\'\']+["\'\']',
    'key\s*=\s*["\''][^"\'\']+["\'\']',
    'api[_-]?key\s*=\s*["\''][^"\'\']+["\'\']',
    'auth[_-]?token\s*=\s*["\''][^"\'\']+["\'\']'
)

# Validate patch safety
function Test-PatchSafety {
    param([string]$PatchContent)
    
    $lines = $PatchContent -split "`n"
    $addedLines = 0
    $removedLines = 0
    $changedFiles = @()
    
    foreach ($line in $lines) {
        if ($line.StartsWith("+++ ") -or $line.StartsWith("--- ")) {
            $file = $line.Substring(4).Split("`t")[0]
            if ($file -and $file -ne "/dev/null") {
                $changedFiles += $file
            }
        }
        elseif ($line.StartsWith("+")) {
            $addedLines++
            # Check for secrets in added lines
            foreach ($pattern in $FORBIDDEN_PATTERNS) {
                if ($line -match $pattern) {
                    Write-Error "Potential secret detected in added line: $line"
                    return $false
                }
            }
        }
        elseif ($line.StartsWith("-")) {
            $removedLines++
        }
    }
    
    $totalChanges = $addedLines + $removedLines
    $uniqueFiles = $changedFiles | Sort-Object -Unique
    
    Write-Host "Patch analysis:" -ForegroundColor Green
    Write-Host "  Changed files: $($uniqueFiles.Count)" -ForegroundColor White
    Write-Host "  Added lines: $addedLines" -ForegroundColor White
    Write-Host "  Removed lines: $removedLines" -ForegroundColor White
    Write-Host "  Total changes: $totalChanges" -ForegroundColor White
    
    if ($uniqueFiles.Count -gt $MAX_FILES) {
        Write-Error "Safety violation: $($uniqueFiles.Count) files changed (max: $MAX_FILES)"
        return $false
    }
    
    if ($totalChanges -gt $MAX_LOC) {
        Write-Error "Safety violation: $totalChanges lines changed (max: $MAX_LOC)"
        return $false
    }
    
    return $true
}

# Validate file syntax
function Test-FileSyntax {
    param([string]$FilePath, [string]$Content)
    
    $extension = [System.IO.Path]::GetExtension($FilePath).ToLower()
    
    switch ($extension) {
        ".ps1" {
            try {
                $ast = [System.Management.Automation.Parser]::ParseFile($FilePath, [ref]$null, [ref]$null)
                if ($null -eq $ast) {
                    Write-Error "PowerShell syntax error in $FilePath"
                    return $false
                }
            } catch {
                Write-Error "PowerShell syntax error in $FilePath`: $($_.Exception.Message)"
                return $false
            }
        }
        ".yaml" {
            try {
                # Basic YAML validation
                if ($Content -match "^\s*:") {
                    Write-Warning "Potential YAML syntax issue in $FilePath (colon at start of line)"
                }
                # Check for balanced quotes
                $singleQuotes = ($Content.ToCharArray() | Where-Object { $_ -eq "'" }).Count
                $doubleQuotes = ($Content.ToCharArray() | Where-Object { $_ -eq '"' }).Count
                if ($singleQuotes % 2 -ne 0 -or $doubleQuotes % 2 -ne 0) {
                    Write-Warning "Unbalanced quotes in $FilePath"
                }
            } catch {
                Write-Warning "Could not validate YAML syntax for $FilePath"
            }
        }
        ".json" {
            try {
                $Content | ConvertFrom-Json | Out-Null
            } catch {
                Write-Error "JSON syntax error in $FilePath`: $($_.Exception.Message)"
                return $false
            }
        }
    }
    
    return $true
}

# Apply patch with validation
function Apply-Patch {
    param([string]$PatchFile)
    
    if (-not (Test-Path $PatchFile)) {
        Write-Error "Patch file not found: $PatchFile"
        return $false
    }
    
    $patchContent = Get-Content $PatchFile -Raw
    
    # Validate patch safety
    if (-not (Test-PatchSafety $patchContent)) {
        return $false
    }
    
    # Create backup branch
    $backupBranch = "backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    git checkout -B $backupBranch
    git add -A
    git commit -m "Backup before applying conflict resolution patch"
    
    try {
        # Apply patch
        git apply --check $PatchFile
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Patch check failed"
            return $false
        }
        
        git apply $PatchFile
        
        # Validate changed files
        $changedFiles = git diff --name-only HEAD
        $allValid = $true
        
        foreach ($file in $changedFiles) {
            if (Test-Path $file) {
                $content = Get-Content $file -Raw
                if (-not (Test-FileSyntax $file $content)) {
                    $allValid = $false
                }
            }
        }
        
        if (-not $allValid) {
            Write-Error "File validation failed"
            git reset --hard HEAD
            return $false
        }
        
        Write-Host "Patch applied successfully" -ForegroundColor Green
        return $true
        
    } catch {
        Write-Error "Failed to apply patch: $($_.Exception.Message)"
        git reset --hard HEAD
        return $false
    }
}

# Create patch from branch
function New-PatchFromBranch {
    param([string]$Branch)
    
    if (-not $Branch) {
        Write-Error "Branch name required"
        return $null
    }
    
    $currentBranch = git branch --show-current
    $patchFile = "patch-$Branch-$(Get-Date -Format 'yyyyMMdd-HHmmss').patch"
    
    try {
        # Create patch
        git format-patch $currentBranch..$Branch --stdout | Out-File $patchFile -Encoding UTF8
        
        Write-Host "Created patch: $patchFile" -ForegroundColor Green
        return $patchFile
        
    } catch {
        Write-Error "Failed to create patch: $($_.Exception.Message)"
        return $null
    }
}

# Validate existing patch
function Test-ExistingPatch {
    param([string]$PatchFile)
    
    if (-not (Test-Path $PatchFile)) {
        Write-Error "Patch file not found: $PatchFile"
        return $false
    }
    
    $patchContent = Get-Content $PatchFile -Raw
    
    Write-Host "Validating patch: $PatchFile" -ForegroundColor Yellow
    
    # Safety validation
    $safe = Test-PatchSafety $patchContent
    
    # Syntax validation (simulate apply)
    try {
        git apply --check $PatchFile
        $syntaxValid = $LASTEXITCODE -eq 0
    } catch {
        $syntaxValid = $false
        Write-Error "Syntax validation failed: $($_.Exception.Message)"
    }
    
    $isValid = $safe -and $syntaxValid
    
    Write-Host "Patch validation result: $(if ($isValid) { 'VALID' } else { 'INVALID' })" -ForegroundColor $(if ($isValid) { 'Green' } else { 'Red' })
    
    return $isValid
}

# Main execution
function Main {
    switch ($true) {
        $Validate {
            if (-not $PatchFile) {
                Write-Error "Patch file required for validation"
                return
            }
            Test-ExistingPatch $PatchFile
        }
        $Apply {
            if (-not $PatchFile) {
                Write-Error "Patch file required for application"
                return
            }
            if ($DryRun) {
                git apply --check $PatchFile
                Write-Host "Dry run completed - patch would apply successfully" -ForegroundColor Green
            } else {
                Apply-Patch $PatchFile
            }
        }
        $Branch {
            New-PatchFromBranch $Branch
        }
        default {
            Write-Host "Patch Validator for Conflict Resolution" -ForegroundColor Green
            Write-Host ""
            Write-Host "Usage:" -ForegroundColor Yellow
            Write-Host "  .\patch-validator.ps1 -Validate -PatchFile <file>     # Validate existing patch"
            Write-Host "  .\patch-validator.ps1 -Apply -PatchFile <file>        # Apply patch with validation"
            Write-Host "  .\patch-validator.ps1 -Apply -PatchFile <file> -DryRun # Dry run patch application"
            Write-Host "  .\patch-validator.ps1 -Branch <branch>                # Create patch from branch"
            Write-Host ""
            Write-Host "Examples:" -ForegroundColor Cyan
            Write-Host "  .\patch-validator.ps1 -Validate -PatchFile conflict-fix.patch"
            Write-Host "  .\patch-validator.ps1 -Apply -PatchFile conflict-fix.patch -DryRun"
            Write-Host "  .\patch-validator.ps1 -Branch cursor-local/conflict-resolve-123"
        }
    }
}

# Execute main function
Main
