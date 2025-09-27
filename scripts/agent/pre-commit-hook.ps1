# scripts/agent/pre-commit-hook.ps1 - Pre-commit hook for guardrail validation

param(
    [switch]$Staged,
    [switch]$All
)

$ErrorActionPreference = "Stop"

function Write-HookResult {
    param(
        [string]$Message,
        [bool]$Success = $true
    )
    
    $color = if ($Success) { "Green" } else { "Red" }
    $icon = if ($Success) { "✅" } else { "❌" }
    Write-Host "$icon $Message" -ForegroundColor $color
}

function Test-StagedFiles {
    param([array]$StagedFiles)
    
    $relevantFiles = $StagedFiles | Where-Object { 
        $_ -match '\.(html|htm|js|jsx|ts|tsx)$' -and 
        $_ -notmatch 'node_modules|\.git|third_party'
    }
    
    return $relevantFiles
}

Write-Host "🔍 codex-local Pre-commit Hook" -ForegroundColor Cyan
Write-Host "===============================" -ForegroundColor Cyan

# Get staged files if requested
$filesToCheck = @()
if ($Staged) {
    try {
        $stagedFiles = git diff --cached --name-only
        $filesToCheck = Test-StagedFiles -StagedFiles $stagedFiles
        
        if ($filesToCheck.Count -eq 0) {
            Write-HookResult -Message "No relevant files staged for guardrail check" -Success $true
            exit 0
        }
        
        Write-Host "Checking $($filesToCheck.Count) staged files for guardrail violations..." -ForegroundColor Yellow
    } catch {
        Write-HookResult -Message "Failed to get staged files: $($_.Exception.Message)" -Success $false
        exit 1
    }
} elseif ($All) {
    Write-Host "Checking all files for guardrail violations..." -ForegroundColor Yellow
} else {
    Write-Host "Checking all files for guardrail violations..." -ForegroundColor Yellow
}

# Run guardrail check
try {
    $guardrailResult = pnpm agent:guardrails-premium -Json | ConvertFrom-Json
    
    if ($guardrailResult.violations -eq 0) {
        Write-HookResult -Message "No guardrail violations found" -Success $true
        Write-HookResult -Message "Files processed: $($guardrailResult.filesProcessed)" -Success $true
        exit 0
    } else {
        Write-HookResult -Message "Found $($guardrailResult.violations) guardrail violations" -Success $false
        
        # Show violations
        Write-Host "`nViolations found:" -ForegroundColor Red
        foreach ($violation in $guardrailResult.items | Select-Object -First 10) {
            Write-Host "  - $($violation.file):$($violation.line) - $($violation.desc)" -ForegroundColor Yellow
        }
        
        if ($guardrailResult.items.Count -gt 10) {
            Write-Host "  ... and $($guardrailResult.items.Count - 10) more violations" -ForegroundColor Yellow
        }
        
        # Show autofix suggestion
        Write-Host "`n💡 To fix violations automatically:" -ForegroundColor Cyan
        Write-Host "   pnpm agent:guardrails-premium -Fix" -ForegroundColor White
        
        # Show specific file fixes if staged files
        if ($filesToCheck.Count -gt 0) {
            $fileViolations = $guardrailResult.items | Where-Object { $filesToCheck -contains $_.file }
            if ($fileViolations.Count -gt 0) {
                Write-Host "`n📁 Violations in staged files:" -ForegroundColor Yellow
                foreach ($violation in $fileViolations) {
                    Write-Host "  - $($violation.file):$($violation.line) - $($violation.desc)" -ForegroundColor Red
                }
            }
        }
        
        Write-Host "`n🚫 Commit blocked due to guardrail violations" -ForegroundColor Red
        exit 1
    }
    
} catch {
    Write-HookResult -Message "Guardrail check failed: $($_.Exception.Message)" -Success $false
    exit 1
}
