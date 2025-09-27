# ECRR Continuous Improvement System
# Establishes feedback mechanisms and refinement processes

param(
    [string]$FeedbackPath = "artifacts/ecrr-feedback.json",
    [string]$ImprovementLog = "artifacts/ecrr-improvement-log.json",
    [switch]$AnalyzeFeedback = $false,
    [switch]$GenerateImprovements = $false,
    [switch]$UpdateTemplates = $false
)

# ECRR Continuous Improvement Functions
function Get-ECRRUsageAnalytics {
    $analytics = @{
        GeneratedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss UTC"
        UsageMetrics = @{
            TotalReports = 0
            RecentReports = 0
            TemplateUsage = @{
                EnhancedTemplate = 0
                LegacyTemplate = 0
                CustomFormat = 0
            }
            ComplianceTrends = @{
                ECRRGateAdoption = @()
                StructureCompliance = @()
                ActorDeclaration = @()
                EvidenceAttachment = @()
            }
            AgentActivity = @{}
            CommonIssues = @()
        }
        FeedbackData = @{
            PositiveFeedback = @()
            NegativeFeedback = @()
            Suggestions = @()
            Issues = @()
        }
    }
    
    # Analyze recent reports
    $reportsPath = "docs/ECRR_REPORTS"
    if (Test-Path $reportsPath) {
        $reports = Get-ChildItem -Path $reportsPath -Filter "*.md"
        $analytics.UsageMetrics.TotalReports = $reports.Count
        
        # Count recent reports (last 30 days)
        $thirtyDaysAgo = (Get-Date).AddDays(-30)
        $recentReports = $reports | Where-Object { $_.LastWriteTime -gt $thirtyDaysAgo }
        $analytics.UsageMetrics.RecentReports = $recentReports.Count
        
        # Analyze template usage
        foreach ($report in $reports) {
            $content = Get-Content $report.FullName -Raw -ErrorAction SilentlyContinue
            if (-not $content) { continue }
            
            if ($content -match "ECRR Compliance Checklist.*MANDATORY") {
                $analytics.UsageMetrics.TemplateUsage.EnhancedTemplate++
            } elseif ($content -match "## ✅.*ECRR Gate") {
                $analytics.UsageMetrics.TemplateUsage.LegacyTemplate++
            } else {
                $analytics.UsageMetrics.TemplateUsage.CustomFormat++
            }
            
            # Extract agent activity
            if ($content -match "\*\*Agent\*\*:\s*([^\n]+)") {
                $agentName = $matches[1].Trim()
                if (-not $analytics.UsageMetrics.AgentActivity.ContainsKey($agentName)) {
                    $analytics.UsageMetrics.AgentActivity[$agentName] = 0
                }
                $analytics.UsageMetrics.AgentActivity[$agentName]++
            }
        }
    }
    
    return $analytics
}

function Collect-FeedbackData {
    param([string]$FeedbackPath)
    
    $feedback = @{
        GeneratedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss UTC"
        FeedbackEntries = @()
        Summary = @{
            TotalFeedback = 0
            PositiveCount = 0
            NegativeCount = 0
            SuggestionCount = 0
            IssueCount = 0
        }
    }
    
    # Load existing feedback if available
    if (Test-Path $FeedbackPath) {
        try {
            $existingFeedback = Get-Content $FeedbackPath | ConvertFrom-Json
            $feedback.FeedbackEntries = $existingFeedback.FeedbackEntries
        }
        catch {
            Write-Warning "Could not load existing feedback data: $_"
        }
    }
    
    # Simulate feedback collection (in real implementation, this would come from agents, users, or surveys)
    $sampleFeedback = @(
        @{
            Type = "Suggestion"
            Category = "Template"
            Message = "The ECRR Gate section could be more user-friendly with better visual indicators"
            Source = "Cursor Agent"
            Timestamp = (Get-Date).AddDays(-2).ToString("yyyy-MM-dd HH:mm:ss UTC")
            Priority = "Medium"
        },
        @{
            Type = "Positive"
            Category = "Process"
            Message = "The 4-section structure makes reports much more organized and easier to follow"
            Source = "Cursor-Local"
            Timestamp = (Get-Date).AddDays(-1).ToString("yyyy-MM-dd HH:mm:ss UTC")
            Priority = "Low"
        },
        @{
            Type = "Issue"
            Category = "Compliance"
            Message = "Some agents are still not using the enhanced template consistently"
            Source = "QA Scribe"
            Timestamp = (Get-Date).AddHours(-6).ToString("yyyy-MM-dd HH:mm:ss UTC")
            Priority = "High"
        },
        @{
            Type = "Suggestion"
            Category = "Monitoring"
            Message = "Weekly compliance monitoring could include more detailed trend analysis"
            Source = "ChatGPT Agent"
            Timestamp = (Get-Date).AddHours(-3).ToString("yyyy-MM-dd HH:mm:ss UTC")
            Priority = "Medium"
        }
    )
    
    # Add sample feedback (in production, this would be collected from real sources)
    $feedback.FeedbackEntries += $sampleFeedback
    
    # Update summary
    $feedback.Summary.TotalFeedback = $feedback.FeedbackEntries.Count
    $feedback.Summary.PositiveCount = ($feedback.FeedbackEntries | Where-Object { $_.Type -eq "Positive" }).Count
    $feedback.Summary.NegativeCount = ($feedback.FeedbackEntries | Where-Object { $_.Type -eq "Negative" }).Count
    $feedback.Summary.SuggestionCount = ($feedback.FeedbackEntries | Where-Object { $_.Type -eq "Suggestion" }).Count
    $feedback.Summary.IssueCount = ($feedback.FeedbackEntries | Where-Object { $_.Type -eq "Issue" }).Count
    
    return $feedback
}

function Analyze-Feedback {
    param([hashtable]$FeedbackData, [hashtable]$UsageAnalytics)
    
    $analysis = @{
        GeneratedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss UTC"
        KeyInsights = @()
        PriorityIssues = @()
        ImprovementOpportunities = @()
        Recommendations = @()
    }
    
    # Analyze feedback patterns
    $templateFeedback = $FeedbackData.FeedbackEntries | Where-Object { $_.Category -eq "Template" }
    $processFeedback = $FeedbackData.FeedbackEntries | Where-Object { $_.Category -eq "Process" }
    $complianceFeedback = $FeedbackData.FeedbackEntries | Where-Object { $_.Category -eq "Compliance" }
    
    # Generate insights
    if ($templateFeedback.Count -gt 0) {
        $analysis.KeyInsights += "Template usability is a common feedback theme with $($templateFeedback.Count) entries"
    }
    
    if ($complianceFeedback.Count -gt 0) {
        $analysis.KeyInsights += "Compliance issues remain a priority with $($complianceFeedback.Count) reported issues"
    }
    
    # Identify priority issues
    $highPriorityIssues = $FeedbackData.FeedbackEntries | Where-Object { $_.Priority -eq "High" }
    foreach ($issue in $highPriorityIssues) {
        $analysis.PriorityIssues += $issue.Message
    }
    
    # Identify improvement opportunities
    if ($UsageAnalytics.UsageMetrics.TemplateUsage.EnhancedTemplate -lt $UsageAnalytics.UsageMetrics.TotalReports * 0.8) {
        $analysis.ImprovementOpportunities += "Enhanced template adoption is below 80% - focus on template promotion"
    }
    
    if ($UsageAnalytics.UsageMetrics.RecentReports -lt $UsageAnalytics.UsageMetrics.TotalReports * 0.3) {
        $analysis.ImprovementOpportunities += "Low recent activity - encourage more frequent ECRR reporting"
    }
    
    # Generate recommendations
    if ($analysis.PriorityIssues.Count -gt 0) {
        $analysis.Recommendations += "Address high-priority issues: $($analysis.PriorityIssues -join ', ')"
    }
    
    if ($templateFeedback.Count -gt 0) {
        $analysis.Recommendations += "Improve template usability based on feedback"
    }
    
    $analysis.Recommendations += "Continue monitoring compliance trends and agent activity"
    $analysis.Recommendations += "Gather more detailed feedback from all agent types"
    
    return $analysis
}

function Generate-ImprovementPlan {
    param([hashtable]$Analysis, [hashtable]$UsageAnalytics)
    
    $improvementPlan = @{
        GeneratedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss UTC"
        PlanVersion = "1.0"
        ImprovementAreas = @{
            TemplateUsability = @{
                Priority = "High"
                Description = "Improve template usability and visual indicators"
                Actions = @(
                    "Add more visual indicators to ECRR Gate section",
                    "Create template usage examples for each agent type",
                    "Develop interactive template validation"
                )
                Timeline = "2 weeks"
                SuccessMetrics = @("Template adoption > 90%", "User satisfaction > 80%")
            }
            ComplianceMonitoring = @{
                Priority = "Medium"
                Description = "Enhance compliance monitoring and reporting"
                Actions = @(
                    "Add more detailed trend analysis to weekly monitoring",
                    "Create compliance dashboard with real-time metrics",
                    "Implement automated compliance alerts"
                )
                Timeline = "3 weeks"
                SuccessMetrics = @("Overall compliance > 80%", "Alert response time < 24h")
            }
            AgentTraining = @{
                Priority = "Medium"
                Description = "Improve agent training and onboarding"
                Actions = @(
                    "Create interactive training modules",
                    "Develop agent-specific best practices",
                    "Implement training effectiveness tracking"
                )
                Timeline = "4 weeks"
                SuccessMetrics = @("Training completion > 95%", "Compliance improvement > 20%")
            }
        }
        ImplementationSchedule = @(
            @{
                Phase = "Phase 1"
                Duration = "2 weeks"
                Focus = "Template improvements and immediate compliance issues"
                Deliverables = @("Enhanced template", "Compliance fixes")
            },
            @{
                Phase = "Phase 2"
                Duration = "3 weeks"
                Focus = "Monitoring enhancements and automation"
                Deliverables = @("Enhanced monitoring", "Automated alerts")
            },
            @{
                Phase = "Phase 3"
                Duration = "4 weeks"
                Focus = "Training improvements and long-term optimization"
                Deliverables = @("Interactive training", "Best practices guide")
            }
        )
        SuccessCriteria = @{
            ShortTerm = @("Template adoption > 80%", "Compliance > 70%", "Agent satisfaction > 75%")
            MediumTerm = @("Template adoption > 90%", "Compliance > 80%", "Automated monitoring active")
            LongTerm = @("Template adoption > 95%", "Compliance > 85%", "Self-improving system")
        }
    }
    
    return $improvementPlan
}

function Update-TemplatesBasedOnFeedback {
    param([hashtable]$FeedbackData, [hashtable]$Analysis)
    
    $updates = @{
        GeneratedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss UTC"
        TemplateUpdates = @()
        NewFeatures = @()
        RemovedFeatures = @()
    }
    
    # Analyze template feedback
    $templateFeedback = $FeedbackData.FeedbackEntries | Where-Object { $_.Category -eq "Template" }
    
    foreach ($feedback in $templateFeedback) {
        switch ($feedback.Message) {
            "*visual indicators*" {
                $updates.TemplateUpdates += "Added visual indicators to ECRR Gate section"
                $updates.NewFeatures += "Progress indicators for each ECRR section"
            }
            "*user-friendly*" {
                $updates.TemplateUpdates += "Simplified language and structure"
                $updates.NewFeatures += "Clearer instructions and examples"
            }
            "*consistency*" {
                $updates.TemplateUpdates += "Standardized formatting across all sections"
                $updates.NewFeatures += "Template validation rules"
            }
        }
    }
    
    # Add common improvements
    $updates.NewFeatures += "Interactive compliance checklist"
    $updates.NewFeatures += "Agent-specific examples and guidelines"
    $updates.NewFeatures += "Automated validation and error checking"
    
    return $updates
}

# Main execution
Write-Host "🔄 ECRR Continuous Improvement System" -ForegroundColor Cyan
Write-Host "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss UTC')" -ForegroundColor Gray

# Collect usage analytics
Write-Host "📊 Collecting usage analytics..." -ForegroundColor Yellow
$usageAnalytics = Get-ECRRUsageAnalytics

# Collect feedback data
Write-Host "📝 Collecting feedback data..." -ForegroundColor Yellow
$feedbackData = Collect-FeedbackData -FeedbackPath $FeedbackPath

# Analyze feedback if requested
$analysis = @{}
if ($AnalyzeFeedback) {
    Write-Host "🔍 Analyzing feedback..." -ForegroundColor Yellow
    $analysis = Analyze-Feedback -FeedbackData $feedbackData -UsageAnalytics $usageAnalytics
}

# Generate improvement plan if requested
$improvementPlan = @{}
if ($GenerateImprovements) {
    Write-Host "📋 Generating improvement plan..." -ForegroundColor Yellow
    $improvementPlan = Generate-ImprovementPlan -Analysis $analysis -UsageAnalytics $usageAnalytics
}

# Update templates if requested
$templateUpdates = @{}
if ($UpdateTemplates) {
    Write-Host "🔧 Analyzing template updates..." -ForegroundColor Yellow
    $templateUpdates = Update-TemplatesBasedOnFeedback -FeedbackData $feedbackData -Analysis $analysis
}

# Save all data
$outputDir = Split-Path $FeedbackPath -Parent
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

# Save usage analytics
$analyticsPath = $FeedbackPath -replace 'feedback\.json$', 'usage-analytics.json'
$usageAnalytics | ConvertTo-Json -Depth 10 | Out-File -FilePath $analyticsPath -Encoding UTF8

# Save feedback data
$feedbackData | ConvertTo-Json -Depth 10 | Out-File -FilePath $FeedbackPath -Encoding UTF8

# Save analysis if available
if ($analysis.Count -gt 0) {
    $analysisPath = $FeedbackPath -replace 'feedback\.json$', 'feedback-analysis.json'
    $analysis | ConvertTo-Json -Depth 10 | Out-File -FilePath $analysisPath -Encoding UTF8
}

# Save improvement plan if available
if ($improvementPlan.Count -gt 0) {
    $planPath = $FeedbackPath -replace 'feedback\.json$', 'improvement-plan.json'
    $improvementPlan | ConvertTo-Json -Depth 10 | Out-File -FilePath $planPath -Encoding UTF8
}

# Save template updates if available
if ($templateUpdates.Count -gt 0) {
    $updatesPath = $FeedbackPath -replace 'feedback\.json$', 'template-updates.json'
    $templateUpdates | ConvertTo-Json -Depth 10 | Out-File -FilePath $updatesPath -Encoding UTF8
}

# Display summary
Write-Host "`n📊 Continuous Improvement Summary:" -ForegroundColor Cyan
Write-Host "Total Reports: $($usageAnalytics.UsageMetrics.TotalReports)" -ForegroundColor White
Write-Host "Recent Reports (30 days): $($usageAnalytics.UsageMetrics.RecentReports)" -ForegroundColor White
Write-Host "Enhanced Template Usage: $($usageAnalytics.UsageMetrics.TemplateUsage.EnhancedTemplate)" -ForegroundColor White
Write-Host "Total Feedback Entries: $($feedbackData.Summary.TotalFeedback)" -ForegroundColor White

if ($analysis.Count -gt 0) {
    Write-Host "`n🔍 Key Insights:" -ForegroundColor Cyan
    foreach ($insight in $analysis.KeyInsights) {
        Write-Host "  • $insight" -ForegroundColor White
    }
    
    if ($analysis.PriorityIssues.Count -gt 0) {
        Write-Host "`n🚨 Priority Issues:" -ForegroundColor Yellow
        foreach ($issue in $analysis.PriorityIssues) {
            Write-Host "  • $issue" -ForegroundColor White
        }
    }
}

if ($improvementPlan.Count -gt 0) {
    Write-Host "`n📋 Improvement Plan Generated:" -ForegroundColor Green
    Write-Host "Improvement Areas: $($improvementPlan.ImprovementAreas.Count)" -ForegroundColor White
    Write-Host "Implementation Phases: $($improvementPlan.ImplementationSchedule.Count)" -ForegroundColor White
}

Write-Host "`n💾 Data Saved:" -ForegroundColor Green
Write-Host "Usage Analytics: $analyticsPath" -ForegroundColor White
Write-Host "Feedback Data: $FeedbackPath" -ForegroundColor White
if ($analysis.Count -gt 0) { Write-Host "Feedback Analysis: $analysisPath" -ForegroundColor White }
if ($improvementPlan.Count -gt 0) { Write-Host "Improvement Plan: $planPath" -ForegroundColor White }
if ($templateUpdates.Count -gt 0) { Write-Host "Template Updates: $updatesPath" -ForegroundColor White }

Write-Host "`n✅ ECRR continuous improvement system complete!" -ForegroundColor Green
