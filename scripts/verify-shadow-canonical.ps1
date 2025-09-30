# Shadow vs Canonical Verification Script (PowerShell)
# 
# PR-D Preparation: Establishes baseline for byte-identical verification
# between shadow and canonical artifacts before flipping to canonical writes.
# 
# Usage:
#   pwsh -File scripts/verify-shadow-canonical.ps1
#   
# This script compares the last N shadow artifacts with their canonical
# counterparts to ensure zero drift before the canonical write flip.

param(
    [string]$ShadowBasePath = ".agent/shadow",
    [string]$CanonicalBasePath = ".agent",
    [int]$MaxArtifactsToCheck = 10,
    [string]$ReportPath = ".agent/shadow-canonical-verification.json"
)

function Get-FileHash {
    param([string]$FilePath)
    
    try {
        if (Test-Path $FilePath) {
            $content = Get-Content $FilePath -Raw -Encoding UTF8
            $hash = [System.Security.Cryptography.SHA256]::Create()
            $bytes = [System.Text.Encoding]::UTF8.GetBytes($content)
            $hashBytes = $hash.ComputeHash($bytes)
            return [System.BitConverter]::ToString($hashBytes) -replace '-', ''
        } else {
            return "FILE_NOT_FOUND"
        }
    } catch {
        Write-Warning "Error calculating hash for $FilePath`: $($_.Exception.Message)"
        return "ERROR"
    }
}

function Find-Artifacts {
    param(
        [string]$BasePath,
        [string[]]$Patterns
    )
    
    $artifacts = @()
    
    foreach ($pattern in $Patterns) {
        try {
            if ($pattern -like "*/*") {
                $searchPath = Join-Path $BasePath $pattern
                if (Test-Path $searchPath) {
                    $relativePath = $pattern
                    $artifacts += $relativePath
                }
            } elseif ($pattern -like "*.json") {
                $searchPath = Join-Path $BasePath $pattern
                if (Test-Path $searchPath) {
                    $relativePath = $pattern
                    $artifacts += $relativePath
                }
            } elseif ($pattern -like "*/*.md") {
                $dirPattern = $pattern -replace "/.*", ""
                $filePattern = $pattern -replace ".*/", ""
                $searchDir = Join-Path $BasePath $dirPattern
                if (Test-Path $searchDir) {
                    $files = Get-ChildItem $searchDir -Filter $filePattern -Recurse
                    foreach ($file in $files) {
                        $relativePath = $file.FullName.Replace((Resolve-Path $BasePath).Path + "\", "").Replace("\", "/")
                        $artifacts += $relativePath
                    }
                }
            } else {
                $searchPath = Join-Path $BasePath $pattern
                if (Test-Path $searchPath) {
                    $relativePath = $pattern
                    $artifacts += $relativePath
                }
            }
        } catch {
            Write-Warning "Error processing pattern $pattern`: $($_.Exception.Message)"
        }
    }
    
    return $artifacts | Sort-Object | Get-Unique
}

function Verify-ShadowVsCanonical {
    Write-Host "🔍 Starting Shadow vs Canonical Verification..." -ForegroundColor Cyan
    Write-Host "📁 Shadow base path: $ShadowBasePath" -ForegroundColor Gray
    Write-Host "📁 Canonical base path: $CanonicalBasePath" -ForegroundColor Gray
    
    # Define artifact patterns to check
    $artifactPatterns = @(
        "status.json",
        "agent_queue.json", 
        "queue.db",
        "*.json"
    )
    
    # Find all artifacts
    $shadowArtifacts = Find-Artifacts -BasePath $ShadowBasePath -Patterns $artifactPatterns
    $canonicalArtifacts = Find-Artifacts -BasePath $CanonicalBasePath -Patterns $artifactPatterns
    
    Write-Host "📋 Found $($shadowArtifacts.Count) shadow artifacts" -ForegroundColor Gray
    Write-Host "📋 Found $($canonicalArtifacts.Count) canonical artifacts" -ForegroundColor Gray
    
    # Compare artifacts
    $matches = @()
    $identicalCount = 0
    $driftCount = 0
    
    # Limit to most recent artifacts
    $artifactsToCheck = $shadowArtifacts | Select-Object -First $MaxArtifactsToCheck
    
    foreach ($artifactPath in $artifactsToCheck) {
        $shadowPath = Join-Path $ShadowBasePath $artifactPath
        $canonicalPath = Join-Path $CanonicalBasePath $artifactPath
        
        $shadowHash = Get-FileHash -FilePath $shadowPath
        $canonicalHash = Get-FileHash -FilePath $canonicalPath
        
        $identical = ($shadowHash -eq $canonicalHash) -and ($shadowHash -ne "FILE_NOT_FOUND")
        
        $match = [PSCustomObject]@{
            Path = $artifactPath
            ShadowHash = $shadowHash
            CanonicalHash = $canonicalHash
            Identical = $identical
        }
        
        $matches += $match
        
        if ($identical) {
            $identicalCount++
            Write-Host "✅ $artifactPath - IDENTICAL" -ForegroundColor Green
        } else {
            $driftCount++
            Write-Host "❌ $artifactPath - DRIFT DETECTED" -ForegroundColor Red
            Write-Host "   Shadow hash:    $shadowHash" -ForegroundColor Gray
            Write-Host "   Canonical hash: $canonicalHash" -ForegroundColor Gray
        }
    }
    
    $verificationPassed = $driftCount -eq 0
    
    # Create verification result
    $result = [PSCustomObject]@{
        Timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        ShadowArtifacts = $shadowArtifacts
        CanonicalArtifacts = $canonicalArtifacts
        Matches = $matches
        Summary = [PSCustomObject]@{
            TotalArtifacts = $artifactsToCheck.Count
            IdenticalCount = $identicalCount
            DriftCount = $driftCount
            VerificationPassed = $verificationPassed
        }
    }
    
    # Save verification report
    $resultJson = $result | ConvertTo-Json -Depth 10
    $resultJson | Out-File -FilePath $ReportPath -Encoding UTF8
    
    # Print summary
    Write-Host ""
    Write-Host "📊 Verification Summary:" -ForegroundColor Cyan
    Write-Host "   Total artifacts checked: $($result.Summary.TotalArtifacts)" -ForegroundColor Gray
    Write-Host "   Identical: $($result.Summary.IdenticalCount)" -ForegroundColor Gray
    Write-Host "   Drift detected: $($result.Summary.DriftCount)" -ForegroundColor Gray
    Write-Host "   Verification $($verificationPassed ? '✅ PASSED' : '❌ FAILED')" -ForegroundColor $(if ($verificationPassed) { "Green" } else { "Red" })
    Write-Host "   Report saved: $ReportPath" -ForegroundColor Gray
    
    if (-not $verificationPassed) {
        Write-Host ""
        Write-Host "⚠️  WARNING: Drift detected between shadow and canonical artifacts!" -ForegroundColor Yellow
        Write-Host "   This may indicate issues with the shadow write implementation." -ForegroundColor Gray
        Write-Host "   Review the artifacts above before proceeding with canonical flip." -ForegroundColor Gray
    } else {
        Write-Host ""
        Write-Host "🎯 All artifacts are byte-identical - ready for canonical flip!" -ForegroundColor Green
    }
    
    return $result
}

# Main execution
try {
    $result = Verify-ShadowVsCanonical
    
    # Exit with appropriate code
    if ($result.Summary.VerificationPassed) {
        Write-Host "✅ Verification completed successfully" -ForegroundColor Green
        exit 0
    } else {
        Write-Host "❌ Verification failed - drift detected" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Error "❌ Verification failed: $($_.Exception.Message)"
    exit 1
}
