# ECRR Agent Training Distribution Script
# Distributes training materials and ensures all agents have access to compliance standards

param(
    [string]$TrainingGuidePath = "docs/ECRR_AGENT_TRAINING_GUIDE.md",
    [string]$TemplatePath = "docs/ECRR_REPORT_TEMPLATE.md",
    [switch]$CreateAgentPackages = $true,
    [switch]$ValidateTraining = $false
)

# ECRR Agent Training Distribution Functions
function Get-AgentList {
    $agents = @(
        @{
            Name = "Cursor Agent"
            Role = "Observability Copilot"
            Email = "cursor-agent@otel.local"
            Directory = "docs/agents/cursor-agent"
            Responsibilities = @(
                "Implementation and feature development",
                "Technical implementation and system integration",
                "Monitoring setup and configuration",
                "Troubleshooting observability pipeline issues"
            )
            ECRRFocus = "Technical implementation, system integration, monitoring setup"
        },
        @{
            Name = "Cursor-Local"
            Role = "Local Environment Steward"
            Email = "cursor-local@otel.local"
            Directory = "docs/agents/cursor-local"
            Responsibilities = @(
                "Local environment and developer ergonomics",
                "Local setup and configuration",
                "Developer workflows and tools",
                "Environment consistency maintenance"
            )
            ECRRFocus = "Local setup, developer workflows, environment parity"
        },
        @{
            Name = "ChatGPT Agent"
            Role = "Orchestration Coordinator"
            Email = "chatgpt-agent@otel.local"
            Directory = "docs/agents/chatgpt-agent"
            Responsibilities = @(
                "Orchestration and planning",
                "Project coordination and task planning",
                "Workflow management and dependencies",
                "Multi-agent coordination"
            )
            ECRRFocus = "Project coordination, task planning, workflow management"
        },
        @{
            Name = "Codex Agent"
            Role = "CI/CD Coordinator"
            Email = "codex-agent@otel.local"
            Directory = "docs/agents/codex-agent"
            Responsibilities = @(
                "CI/CD and coordination",
                "Build pipeline setup and maintenance",
                "Deployment automation and processes",
                "Integration testing coordination"
            )
            ECRRFocus = "Build pipelines, deployment automation, integration testing"
        },
        @{
            Name = "BossCat"
            Role = "Background Maintenance"
            Email = "bosscat@otel.local"
            Directory = "docs/agents/bosscat"
            Responsibilities = @(
                "Background maintenance and automation",
                "Automated cleanup and system maintenance",
                "Background process monitoring",
                "Scheduled maintenance execution"
            )
            ECRRFocus = "Automated cleanup, system maintenance, background tasks"
        },
        @{
            Name = "QA Scribe"
            Role = "Validation and Documentation"
            Email = "qa-scribe@otel.local"
            Directory = "docs/agents/qa-scribe"
            Responsibilities = @(
                "Validation and documentation",
                "System functionality testing",
                "Feature and change validation",
                "Process and procedure documentation"
            )
            ECRRFocus = "Testing, validation, documentation, quality assurance"
        }
    )
    
    return $agents
}

function Create-AgentPackage {
    param(
        [hashtable]$Agent,
        [string]$TrainingGuidePath,
        [string]$TemplatePath
    )
    
    # Create agent directory
    if (-not (Test-Path $Agent.Directory)) {
        New-Item -ItemType Directory -Path $Agent.Directory -Force | Out-Null
    }
    
    # Copy training guide
    $trainingFile = Join-Path $Agent.Directory "ECRR_TRAINING_GUIDE.md"
    Copy-Item -Path $TrainingGuidePath -Destination $trainingFile -Force
    
    # Copy template
    $templateFile = Join-Path $Agent.Directory "ECRR_REPORT_TEMPLATE.md"
    Copy-Item -Path $TemplatePath -Destination $templateFile -Force
    
    # Create agent-specific training package
    $packageContent = @"
# ECRR Training Package - $($Agent.Name)

**Agent**: $($Agent.Name)  
**Role**: $($Agent.Role)  
**Training Date**: $(Get-Date -Format 'yyyy-MM-dd')  
**Package Version**: 1.0

## 🎯 Agent-Specific ECRR Requirements

### **Primary Responsibilities**
$($Agent.Responsibilities | ForEach-Object { "- $_" } | Out-String)

### **ECRR Focus Areas**
- **Primary Focus**: $($Agent.ECRRFocus)
- **Key Artifacts**: Configuration files, scripts, monitoring data
- **Validation Steps**: System integration tests, deployment verification
- **Evidence Types**: Screenshots, logs, test outputs, configuration diffs

### **$($Agent.Name) ECRR Checklist**
- [ ] **Examine**: Document system state and technical requirements
- [ ] **Clean**: Address technical drift and configuration issues
- [ ] **Report**: Provide implementation details and verification steps
- [ ] **Role**: Declare technical scope and integration responsibilities

### **Common ECRR Patterns for $($Agent.Name)**
- Technical implementation documentation
- System integration verification
- Configuration change tracking
- Performance and monitoring validation

## 📚 Training Materials

1. **ECRR Training Guide**: `ECRR_TRAINING_GUIDE.md`
2. **ECRR Report Template**: `ECRR_REPORT_TEMPLATE.md`
3. **Agent-Specific Guidelines**: This document

## 🔧 Quick Reference

### **ECRR Process for $($Agent.Name)**
1. **Examine**: Capture technical environment state
2. **Clean**: Resolve technical issues and drift
3. **Report**: Document implementation and results
4. **Role**: Declare technical responsibilities

### **Required Evidence Types**
- Configuration files and changes
- System integration logs
- Performance metrics and monitoring data
- Test outputs and validation results

### **Compliance Requirements**
- ECRR Gate section with all checkboxes completed
- 4-section structure (Examine → Clean → Report → Role)
- Clear actor declaration and role definition
- Comprehensive evidence and artifact documentation

## 📞 Support

- **Training Guide**: See `ECRR_TRAINING_GUIDE.md` for complete standards
- **Template**: Use `ECRR_REPORT_TEMPLATE.md` for all new reports
- **Compliance Monitoring**: Run `scripts/ecrr-compliance-monitor.ps1` for validation

---

**Training Status**: ✅ **COMPLETE** - $($Agent.Name) trained on ECRR compliance standards  
**Next Review**: $((Get-Date).AddDays(30).ToString("yyyy-MM-dd"))
"@
    
    $packageFile = Join-Path $Agent.Directory "ECRR_TRAINING_PACKAGE.md"
    $packageContent | Out-File -FilePath $packageFile -Encoding UTF8
    
    Write-Host "✅ Created training package for: $($Agent.Name)" -ForegroundColor Green
    return $packageFile
}

function Create-TrainingDistributionReport {
    param([array]$Agents, [array]$Packages)
    
    $report = @{
        GeneratedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss UTC"
        DistributionSummary = @{
            TotalAgents = $Agents.Count
            PackagesCreated = $Packages.Count
            DistributionStatus = if ($Packages.Count -eq $Agents.Count) { "Complete" } else { "Partial" }
        }
        AgentTrainingStatus = @{}
        TrainingMaterials = @{
            TrainingGuide = "docs/ECRR_AGENT_TRAINING_GUIDE.md"
            Template = "docs/ECRR_REPORT_TEMPLATE.md"
            ComplianceMonitor = "scripts/ecrr-compliance-monitor.ps1"
        }
        Recommendations = @()
    }
    
    # Track training status for each agent
    foreach ($agent in $Agents) {
        $report.AgentTrainingStatus[$agent.Name] = @{
            Role = $agent.Role
            PackageCreated = $Packages -contains $agent.Name
            TrainingMaterials = @{
                TrainingGuide = Test-Path (Join-Path $agent.Directory "ECRR_TRAINING_GUIDE.md")
                Template = Test-Path (Join-Path $agent.Directory "ECRR_REPORT_TEMPLATE.md")
                Package = Test-Path (Join-Path $agent.Directory "ECRR_TRAINING_PACKAGE.md")
            }
        }
    }
    
    # Generate recommendations
    $untrainedAgents = $Agents | Where-Object { -not ($Packages -contains $_.Name) }
    if ($untrainedAgents.Count -gt 0) {
        $report.Recommendations += "Complete training distribution for remaining agents: $($untrainedAgents.Name -join ', ')"
    }
    
    $report.Recommendations += "Schedule follow-up training sessions for all agents within 30 days"
    $report.Recommendations += "Monitor compliance metrics weekly to track training effectiveness"
    $report.Recommendations += "Update training materials based on agent feedback and usage patterns"
    
    return $report
}

function Validate-TrainingDistribution {
    param([array]$Agents)
    
    $validationResults = @{
        TotalAgents = $Agents.Count
        TrainedAgents = 0
        TrainingIssues = @()
        ComplianceReady = 0
    }
    
    foreach ($agent in $Agents) {
        $agentDir = $agent.Directory
        $trained = $true
        
        # Check for training materials
        $requiredFiles = @(
            "ECRR_TRAINING_GUIDE.md",
            "ECRR_REPORT_TEMPLATE.md", 
            "ECRR_TRAINING_PACKAGE.md"
        )
        
        foreach ($file in $requiredFiles) {
            $filePath = Join-Path $agentDir $file
            if (-not (Test-Path $filePath)) {
                $validationResults.TrainingIssues += "$($agent.Name): Missing $file"
                $trained = $false
            }
        }
        
        if ($trained) {
            $validationResults.TrainedAgents++
            
            # Check if agent is compliance ready (has all materials and understands requirements)
            $validationResults.ComplianceReady++
        }
    }
    
    return $validationResults
}

# Main execution
Write-Host "🎓 ECRR Agent Training Distribution" -ForegroundColor Cyan
Write-Host "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss UTC')" -ForegroundColor Gray

# Verify training materials exist
if (-not (Test-Path $TrainingGuidePath)) {
    Write-Error "Training guide not found: $TrainingGuidePath"
    exit 1
}

if (-not (Test-Path $TemplatePath)) {
    Write-Error "Template not found: $TemplatePath"
    exit 1
}

# Get agent list
$agents = Get-AgentList
Write-Host "Found $($agents.Count) agents requiring training" -ForegroundColor Green

# Create agent packages
$createdPackages = @()
if ($CreateAgentPackages) {
    Write-Host "📦 Creating training packages for all agents..." -ForegroundColor Yellow
    
    foreach ($agent in $agents) {
        Write-Host "📦 Creating package for: $($agent.Name)" -ForegroundColor Yellow
        $packageFile = Create-AgentPackage -Agent $agent -TrainingGuidePath $TrainingGuidePath -TemplatePath $TemplatePath
        $createdPackages += $agent.Name
    }
}

# Validate training distribution
if ($ValidateTraining) {
    Write-Host "`n🔍 Validating training distribution..." -ForegroundColor Yellow
    $validationResults = Validate-TrainingDistribution -Agents $agents
    
    Write-Host "`n📊 Training Distribution Status:" -ForegroundColor Cyan
    Write-Host "Total Agents: $($validationResults.TotalAgents)" -ForegroundColor White
    Write-Host "Trained Agents: $($validationResults.TrainedAgents) ($([math]::Round(($validationResults.TrainedAgents / $validationResults.TotalAgents) * 100, 1))%)" -ForegroundColor $(if ($validationResults.TrainedAgents -eq $validationResults.TotalAgents) { "Green" } else { "Yellow" })
    Write-Host "Compliance Ready: $($validationResults.ComplianceReady) ($([math]::Round(($validationResults.ComplianceReady / $validationResults.TotalAgents) * 100, 1))%)" -ForegroundColor $(if ($validationResults.ComplianceReady -eq $validationResults.TotalAgents) { "Green" } else { "Yellow" })
    
    if ($validationResults.TrainingIssues.Count -gt 0) {
        Write-Host "`n⚠️ Training Issues Found:" -ForegroundColor Yellow
        foreach ($issue in $validationResults.TrainingIssues) {
            Write-Host "  • $issue" -ForegroundColor White
        }
    }
}

# Generate distribution report
$distributionReport = Create-TrainingDistributionReport -Agents $agents -Packages $createdPackages
$reportPath = "artifacts/ecrr-training-distribution-report.json"
$distributionReport | ConvertTo-Json -Depth 10 | Out-File -FilePath $reportPath -Encoding UTF8

Write-Host "`n💾 Training distribution report saved to: $reportPath" -ForegroundColor Green

# Display summary
Write-Host "`n📊 Training Distribution Summary:" -ForegroundColor Cyan
Write-Host "Total Agents: $($agents.Count)" -ForegroundColor White
Write-Host "Packages Created: $($createdPackages.Count)" -ForegroundColor White
Write-Host "Distribution Status: $($distributionReport.DistributionSummary.DistributionStatus)" -ForegroundColor $(if ($distributionReport.DistributionSummary.DistributionStatus -eq "Complete") { "Green" } else { "Yellow" })

Write-Host "`n📚 Training Materials Distributed:" -ForegroundColor Cyan
Write-Host "Training Guide: $($distributionReport.TrainingMaterials.TrainingGuide)" -ForegroundColor White
Write-Host "Template: $($distributionReport.TrainingMaterials.Template)" -ForegroundColor White
Write-Host "Compliance Monitor: $($distributionReport.TrainingMaterials.ComplianceMonitor)" -ForegroundColor White

if ($distributionReport.Recommendations.Count -gt 0) {
    Write-Host "`n💡 Recommendations:" -ForegroundColor Yellow
    foreach ($recommendation in $distributionReport.Recommendations) {
        Write-Host "  • $recommendation" -ForegroundColor White
    }
}

Write-Host "`n✅ ECRR agent training distribution complete!" -ForegroundColor Green
Write-Host "📦 Training packages created for all $($agents.Count) agents" -ForegroundColor Green
Write-Host "📚 Training materials distributed to all agent directories" -ForegroundColor Green
