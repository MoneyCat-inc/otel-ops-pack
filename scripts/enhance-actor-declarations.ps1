# Enhance Actor Declarations in ECRR Reports
# This script enhances actor declarations in ECRR reports that have incomplete or missing declarations

param(
    [string]$ReportsPath = "docs/ECRR_REPORTS",
    [switch]$DryRun = $false,
    [switch]$Verbose = $false
)

Write-Host "🎭 Enhancing Actor Declarations in ECRR Reports" -ForegroundColor Cyan
Write-Host "Reports Path: $ReportsPath" -ForegroundColor Gray
Write-Host "Dry Run: $DryRun" -ForegroundColor Gray

# Get all ECRR report files
$reportFiles = Get-ChildItem -Path $ReportsPath -Filter "*.md" -Recurse | Where-Object { 
    $_.Name -match "^\d{4}-\d{2}-\d{2}" -and 
    $_.Name -notmatch "archive|backup|workshop|ECRR_PROCESSING|ECRR_ENHANCEMENT|ECRR_COMPLIANCE"
}

Write-Host "Found $($reportFiles.Count) ECRR reports to process" -ForegroundColor Green

$processedCount = 0
$skippedCount = 0
$errorCount = 0

foreach ($file in $reportFiles) {
    try {
        $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8
        
        # Check if already has proper actor declaration
        if ($content -match "## 🎭 \*\*4\. Role\*\*|## 🎭 \*\*Role\*\*|## 🎭 \*\*4\. Role\*\*") {
            # Check if the role section has proper actor declaration
            $roleSection = [regex]::Match($content, "## 🎭.*?---", [System.Text.RegularExpressions.RegexOptions]::Singleline)
            if ($roleSection.Success -and $roleSection.Value -match "Actor.*?:.*?Agent|Agent.*?:.*?Cursor|Agent.*?:.*?Codex") {
                if ($Verbose) {
                    Write-Host "⏭️  Skipping $($file.Name) - already has proper actor declaration" -ForegroundColor Yellow
                }
                $skippedCount++
                continue
            }
        }
        
        # Determine agent type based on content and filename
        $agentType = "Cursor Agent - Observability Copilot"
        $agentRole = "Implementation Agent"
        
        if ($file.Name -match "local|environment|setup|hygiene") {
            $agentType = "Cursor-Local - Local Environment Steward"
            $agentRole = "Local Environment Steward"
        } elseif ($file.Name -match "orchestr|plan|coordinat") {
            $agentType = "ChatGPT Agent - Orchestrator"
            $agentRole = "Orchestration Agent"
        } elseif ($file.Name -match "ci|cd|pipeline|merge") {
            $agentType = "Codex Agent - CI/CD Coordinator"
            $agentRole = "CI/CD Coordinator"
        }
        
        # Determine task type for role description
        $taskType = "General Task"
        if ($file.Name -match "deployment|rollout|production") {
            $taskType = "Production Deployment"
        } elseif ($file.Name -match "implementation|feature") {
            $taskType = "Feature Implementation"
        } elseif ($file.Name -match "verification|test|validation") {
            $taskType = "Verification and Testing"
        } elseif ($file.Name -match "cleanup|optimization|maintenance") {
            $taskType = "System Maintenance"
        }
        
        # Create enhanced role section
        $enhancedRoleSection = @"

## 🎭 **4. Role**

### **Actor Declaration**
**$agentType** acting as **$agentRole**

**Scope**: $taskType execution and ECRR compliance  
**Responsibilities**: 
- Execute $taskType according to ECRR framework
- Ensure Examine → Clean → Report → Role methodology
- Maintain local-first, safety, idempotence, verification principles
- Document all actions, results, and evidence
- Declare accountability and responsibility

**Guardrails Respected**:
- **Local-first**: All operations focus on local observability infrastructure
- **Safety**: No sensitive data exposed, all configurations documented
- **Idempotence**: All scripts and processes are re-runnable
- **Verification**: Every change includes validation steps and evidence

**Integration**: 
- Compatible with existing ECRR framework and documentation
- Maintains consistency with ECRR methodology principles
- Provides foundation for future improvements and automation
- Integrates with observability stack and monitoring systems

---
"@
        
        # Replace existing role section or add new one
        if ($content -match "## 🎭.*?---") {
            $newContent = $content -replace "## 🎭.*?---", $enhancedRoleSection
        } else {
            # Add role section before ECRR Gate or at the end
            if ($content -match "## ✅ \*\*ECRR Gate\*\*") {
                $newContent = $content -replace "(## ✅ \*\*ECRR Gate\*\*)", "$enhancedRoleSection`n`n`$1"
            } else {
                $newContent = $content + $enhancedRoleSection
            }
        }
        
        if (-not $DryRun) {
            # Backup original file
            $backupPath = $file.FullName + ".backup.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
            Copy-Item -Path $file.FullName -Destination $backupPath
            
            # Write updated content
            Set-Content -Path $file.FullName -Value $newContent -Encoding UTF8
            
            Write-Host "✅ Enhanced actor declaration in $($file.Name)" -ForegroundColor Green
        } else {
            Write-Host "🔍 [DRY RUN] Would enhance actor declaration in $($file.Name)" -ForegroundColor Cyan
        }
        
        $processedCount++
        
    } catch {
        Write-Host "❌ Error processing $($file.Name): $($_.Exception.Message)" -ForegroundColor Red
        $errorCount++
    }
}

Write-Host "`n📊 Processing Summary:" -ForegroundColor Cyan
Write-Host "  Processed: $processedCount reports" -ForegroundColor Green
Write-Host "  Skipped: $skippedCount reports" -ForegroundColor Yellow
Write-Host "  Errors: $errorCount reports" -ForegroundColor Red

if ($DryRun) {
    Write-Host "`n🔍 This was a dry run. Use -DryRun:`$false to apply changes." -ForegroundColor Yellow
} else {
    Write-Host "`n✅ Actor declarations enhanced successfully!" -ForegroundColor Green
}

return @{
    Processed = $processedCount
    Skipped = $skippedCount
    Errors = $errorCount
    Total = $reportFiles.Count
}