# ECRR Template Adoption Script
# Deploys enhanced ECRR template and ensures all agents use standardized format

param(
    [string]$TemplatePath = "docs/ECRR_REPORT_TEMPLATE.md",
    [string]$ReportsPath = "CHAR/ECRR/ECRR_REPORTS",
    [switch]$Force = $false,
    [switch]$Validate = $false
)

# ECRR Template Adoption Functions
function Get-AgentDirectories {
    $agentDirs = @()
    
    # Check for agent-specific directories
    $possibleAgentDirs = @(
        "docs/agents",
        "docs/agent-workflows", 
        "docs/roles",
        ".agent"
    )
    
    foreach ($dir in $possibleAgentDirs) {
        if (Test-Path $dir) {
            $agentDirs += $dir
        }
    }
    
    return $agentDirs
}

function Deploy-ECRRTemplate {
    param([string]$TargetPath)
    
    $templateContent = Get-Content $TemplatePath -Raw -ErrorAction SilentlyContinue
    if (-not $templateContent) {
        Write-Error "ECRR template not found: $TemplatePath"
        return $false
    }
    
    $targetFile = Join-Path $TargetPath "ECRR_REPORT_TEMPLATE.md"
    
    # Create directory if it doesn't exist
    $targetDir = Split-Path $targetFile -Parent
    if (-not (Test-Path $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    }
    
    # Deploy template
    $templateContent | Out-File -FilePath $targetFile -Encoding UTF8
    Write-Host "✅ Deployed ECRR template to: $targetFile" -ForegroundColor Green
    
    return $true
}

function Create-AgentSpecificTemplate {
    param(
        [string]$AgentName,
        [string]$AgentRole,
        [string]$TargetPath
    )
    
    $templateContent = Get-Content $TemplatePath -Raw -ErrorAction SilentlyContinue
    if (-not $templateContent) {
        Write-Error "Base ECRR template not found: $TemplatePath"
        return $false
    }
    
    # Customize template for specific agent
    $customizedContent = $templateContent -replace '\*\*Agent\*\*:\s*\[.*\]', "**Agent**: $AgentName"
    $customizedContent = $customizedContent -replace '\*\*Role\*\*:\s*\[.*\]', "**Role**: $AgentRole"
    
    # Add agent-specific examples
    $agentExamples = @"

## 🎭 **$AgentName - Specific Guidelines**

### **Primary Responsibilities**
- [Add agent-specific responsibilities]
- [Add agent-specific tasks]
- [Add agent-specific ECRR focus areas]

### **Common ECRR Patterns for $AgentName**
- [Add common patterns and examples]
- [Add typical artifacts and evidence]
- [Add validation steps specific to this agent]

### **$AgentName ECRR Checklist**
- [ ] Agent-specific requirement 1
- [ ] Agent-specific requirement 2
- [ ] Agent-specific requirement 3

"@
    
    # Insert agent-specific content before the final status section
    $customizedContent = $customizedContent -replace '## 🏆 \*\*Final ECRR Status\*\*', "$agentExamples`n`n## 🏆 **Final ECRR Status**"
    
    $targetFile = Join-Path $TargetPath "ECRR_REPORT_TEMPLATE_$($AgentName -replace '\s+', '_').md"
    $customizedContent | Out-File -FilePath $targetFile -Encoding UTF8
    
    Write-Host "✅ Created agent-specific template: $targetFile" -ForegroundColor Green
    return $true
}

function Validate-TemplateUsage {
    param([string]$ReportsPath)
    
    $reports = Get-ChildItem -Path $ReportsPath -Filter "*.md" -ErrorAction SilentlyContinue
    $validationResults = @{
        TotalReports = $reports.Count
        UsingEnhancedTemplate = 0
        HasECRRGate = 0
        HasMandatoryChecklist = 0
        ComplianceIssues = @()
    }
    
    foreach ($report in $reports) {
        $content = Get-Content $report.FullName -Raw -ErrorAction SilentlyContinue
        if (-not $content) { continue }
        
        # Check for enhanced template markers
        if ($content -match "ECRR Compliance Checklist.*MANDATORY") {
            $validationResults.UsingEnhancedTemplate++
        }
        
        # Check for ECRR Gate
        if ($content -match "## ✅.*ECRR Gate.*MANDATORY VALIDATION") {
            $validationResults.HasECRRGate++
        }
        
        # Check for mandatory checklist
        if ($content -match "Actor Declaration.*Agent and role clearly stated") {
            $validationResults.HasMandatoryChecklist++
        }
        
        # Identify compliance issues
        if ($content -notmatch "ECRR Compliance Checklist.*MANDATORY") {
            $validationResults.ComplianceIssues += "$($report.Name): Missing mandatory compliance checklist"
        }
        
        if ($content -notmatch "## ✅.*ECRR Gate.*MANDATORY VALIDATION") {
            $validationResults.ComplianceIssues += "$($report.Name): Missing mandatory ECRR Gate"
        }
    }
    
    return $validationResults
}

function Create-TemplateAdoptionReport {
    param([hashtable]$ValidationResults)
    
    $report = @{
        GeneratedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss UTC"
        TemplateAdoption = @{
            TotalReports = $ValidationResults.TotalReports
            UsingEnhancedTemplate = $ValidationResults.UsingEnhancedTemplate
            HasECRRGate = $ValidationResults.HasECRRGate
            HasMandatoryChecklist = $ValidationResults.HasMandatoryChecklist
        }
        AdoptionMetrics = @{
            EnhancedTemplateUsage = [math]::Round(($ValidationResults.UsingEnhancedTemplate / $ValidationResults.TotalReports) * 100, 1)
            ECRRGateAdoption = [math]::Round(($ValidationResults.HasECRRGate / $ValidationResults.TotalReports) * 100, 1)
            MandatoryChecklistAdoption = [math]::Round(($ValidationResults.HasMandatoryChecklist / $ValidationResults.TotalReports) * 100, 1)
        }
        ComplianceIssues = $ValidationResults.ComplianceIssues
        Recommendations = @()
    }
    
    # Generate recommendations
    if ($report.AdoptionMetrics.EnhancedTemplateUsage -lt 50) {
        $report.Recommendations += "Enhanced template adoption is below 50%. Deploy template to all agent directories and update existing reports."
    }
    
    if ($report.AdoptionMetrics.ECRRGateAdoption -lt 80) {
        $report.Recommendations += "ECRR Gate adoption is below 80%. Ensure all agents use the enhanced template with mandatory ECRR Gate."
    }
    
    if ($report.AdoptionMetrics.MandatoryChecklistAdoption -lt 90) {
        $report.Recommendations += "Mandatory checklist adoption is below 90%. Update existing reports to include compliance checklist."
    }
    
    return $report
}

# Main execution
Write-Host "🔧 ECRR Template Adoption" -ForegroundColor Cyan
Write-Host "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss UTC')" -ForegroundColor Gray

# Get agent directories
$agentDirs = Get-AgentDirectories
Write-Host "Found $($agentDirs.Count) agent directories" -ForegroundColor Green

# Deploy template to main docs directory
Write-Host "📋 Deploying ECRR template to main docs directory..." -ForegroundColor Yellow
Deploy-ECRRTemplate -TargetPath "docs"

# Deploy template to agent directories
foreach ($agentDir in $agentDirs) {
    Write-Host "📋 Deploying ECRR template to: $agentDir" -ForegroundColor Yellow
    Deploy-ECRRTemplate -TargetPath $agentDir
}

# Create agent-specific templates
$agents = @(
    @{ Name = "Cursor Agent"; Role = "Observability Copilot" },
    @{ Name = "Cursor-Local"; Role = "Local Environment Steward" },
    @{ Name = "ChatGPT Agent"; Role = "Orchestration Coordinator" },
    @{ Name = "Codex Agent"; Role = "CI/CD Coordinator" },
    @{ Name = "BossCat"; Role = "Background Maintenance" },
    @{ Name = "QA Scribe"; Role = "Validation and Documentation" }
)

foreach ($agent in $agents) {
    Write-Host "📋 Creating agent-specific template for: $($agent.Name)" -ForegroundColor Yellow
    Create-AgentSpecificTemplate -AgentName $agent.Name -AgentRole $agent.Role -TargetPath "docs/roles"
}

# Validate template usage if requested
if ($Validate) {
    Write-Host "`n🔍 Validating template usage..." -ForegroundColor Yellow
    $validationResults = Validate-TemplateUsage -ReportsPath $ReportsPath
    
    Write-Host "`n📊 Template Adoption Metrics:" -ForegroundColor Cyan
    Write-Host "Total Reports: $($validationResults.TotalReports)" -ForegroundColor White
    Write-Host "Using Enhanced Template: $($validationResults.UsingEnhancedTemplate) ($([math]::Round(($validationResults.UsingEnhancedTemplate / $validationResults.TotalReports) * 100, 1))%)" -ForegroundColor $(if ($validationResults.UsingEnhancedTemplate / $validationResults.TotalReports -ge 0.5) { "Green" } else { "Red" })
    Write-Host "Has ECRR Gate: $($validationResults.HasECRRGate) ($([math]::Round(($validationResults.HasECRRGate / $validationResults.TotalReports) * 100, 1))%)" -ForegroundColor $(if ($validationResults.HasECRRGate / $validationResults.TotalReports -ge 0.8) { "Green" } else { "Red" })
    Write-Host "Has Mandatory Checklist: $($validationResults.HasMandatoryChecklist) ($([math]::Round(($validationResults.HasMandatoryChecklist / $validationResults.TotalReports) * 100, 1))%)" -ForegroundColor $(if ($validationResults.HasMandatoryChecklist / $validationResults.TotalReports -ge 0.9) { "Green" } else { "Yellow" })
    
    # Generate adoption report
    $adoptionReport = Create-TemplateAdoptionReport -ValidationResults $validationResults
    $adoptionReport | ConvertTo-Json -Depth 10 | Out-File -FilePath "artifacts/ecrr-template-adoption-report.json" -Encoding UTF8
    
    Write-Host "`n💾 Template adoption report saved to: artifacts/ecrr-template-adoption-report.json" -ForegroundColor Green
    
    # Display compliance issues
    if ($validationResults.ComplianceIssues.Count -gt 0) {
        Write-Host "`n⚠️ Compliance Issues Found:" -ForegroundColor Yellow
        foreach ($issue in $validationResults.ComplianceIssues) {
            Write-Host "  • $issue" -ForegroundColor White
        }
    }
}

Write-Host "`n✅ ECRR template adoption complete!" -ForegroundColor Green
Write-Host "📋 Enhanced template deployed to all agent directories" -ForegroundColor Green
Write-Host "🎭 Agent-specific templates created for all agent types" -ForegroundColor Green
if ($Validate) {
    Write-Host "🔍 Template usage validation completed" -ForegroundColor Green
}

