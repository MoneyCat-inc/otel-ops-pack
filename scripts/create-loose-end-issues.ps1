# Create Loose-End Issues Script
# Creates GitHub issues with stable IDs and proper formatting

param(
    [Parameter(Mandatory=$true)]
    [string]$Repo,
    
    [Parameter(Mandatory=$false)]
    [string]$Token = $env:GITHUB_TOKEN,
    
    [Parameter(Mandatory=$false)]
    [switch]$DryRun
)

if (-not $Token) {
    Write-Error "GitHub token required. Set GITHUB_TOKEN env var or use -Token parameter"
    exit 1
}

$issues = @(
    @{
        ID = "LE-01"
        Title = "Privacy & Terms pages"
        Body = @"
Implement privacy policy and terms of service pages for legal compliance.

**Acceptance Criteria:**
- [ ] Privacy policy page with data collection details
- [ ] Terms of service with usage guidelines  
- [ ] Legal review and approval
- [ ] Mobile-responsive design

**Labels:** `Loose-End`, `governance`
**Priority:** High
"@
        Labels = @("Loose-End", "governance")
    },
    @{
        ID = "LE-02" 
        Title = "Mobile responsive design"
        Body = @"
Ensure mobile compatibility and responsive design across all devices.

**Acceptance Criteria:**
- [ ] Mobile-first design approach
- [ ] Touch-friendly interactions
- [ ] Cross-device testing
- [ ] Performance optimization for mobile

**Labels:** `Loose-End`, `mobile`
**Priority:** Medium
"@
        Labels = @("Loose-End", "mobile")
    },
    @{
        ID = "LE-03"
        Title = "DSP integration testing"
        Body = @"
Validate DSP (Digital Signal Processing) integration and audio processing.

**Acceptance Criteria:**
- [ ] Audio processing pipeline testing
- [ ] Latency benchmarks
- [ ] Error handling validation
- [ ] Performance metrics

**Labels:** `Loose-End`, `dsp`
**Priority:** High
"@
        Labels = @("Loose-End", "dsp")
    },
    @{
        ID = "LE-04"
        Title = "Accessibility audit (a11y)"
        Body = @"
Conduct comprehensive accessibility audit for WCAG 2.1 AA compliance.

**Acceptance Criteria:**
- [ ] Screen reader compatibility
- [ ] Keyboard navigation support
- [ ] Color contrast validation
- [ ] ARIA labels implementation

**Labels:** `Loose-End`, `a11y`
**Priority:** Medium
"@
        Labels = @("Loose-End", "a11y")
    },
    @{
        ID = "LE-05"
        Title = "Performance optimization"
        Body = @"
Optimize bundle size, loading speed, and overall application performance.

**Acceptance Criteria:**
- [ ] Bundle size analysis and reduction
- [ ] Lazy loading implementation
- [ ] Caching strategy optimization
- [ ] Core Web Vitals improvement

**Labels:** `Loose-End`
**Priority:** Low
"@
        Labels = @("Loose-End")
    },
    @{
        ID = "LE-06"
        Title = "Error boundary implementation"
        Body = @"
Implement comprehensive error boundaries for graceful error handling.

**Acceptance Criteria:**
- [ ] React error boundaries
- [ ] Global error handling
- [ ] User-friendly error messages
- [ ] Error reporting integration

**Labels:** `Loose-End`
**Priority:** High
"@
        Labels = @("Loose-End")
    },
    @{
        ID = "LE-07"
        Title = "Documentation updates"
        Body = @"
Update and maintain comprehensive documentation for APIs and usage.

**Acceptance Criteria:**
- [ ] API documentation refresh
- [ ] Usage guides and examples
- [ ] Developer onboarding docs
- [ ] Architecture documentation

**Labels:** `Loose-End`
**Priority:** Low
"@
        Labels = @("Loose-End")
    },
    @{
        ID = "LE-08"
        Title = "Security headers validation"
        Body = @"
Validate and implement proper security headers and policies.

**Acceptance Criteria:**
- [ ] CSP (Content Security Policy) implementation
- [ ] Security headers audit
- [ ] HTTPS enforcement
- [ ] Security testing

**Labels:** `Loose-End`, `trust`
**Priority:** High
"@
        Labels = @("Loose-End", "trust")
    }
)

Write-Host "Creating Loose-End issues for repository: $Repo" -ForegroundColor Green

foreach ($issue in $issues) {
    $title = "[$($issue.ID)] $($issue.Title)"
    
    Write-Host "`nCreating issue: $title" -ForegroundColor Yellow
    
    if ($DryRun) {
        Write-Host "DRY RUN: Would create issue with title: $title" -ForegroundColor Cyan
        Write-Host "Labels: $($issue.Labels -join ', ')" -ForegroundColor Cyan
        continue
    }
    
    try {
        $createArgs = @{
            title = $title
            body = $issue.Body
            label = $issue.Labels
        }
        
        $result = gh issue create @createArgs --repo $Repo
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Created: $result" -ForegroundColor Green
        } else {
            Write-Host "❌ Failed to create issue: $title" -ForegroundColor Red
        }
    }
    catch {
        Write-Host "❌ Error creating issue $title`: $_" -ForegroundColor Red
    }
    
    Start-Sleep -Seconds 1  # Rate limiting
}

if ($DryRun) {
    Write-Host "`n🔍 DRY RUN COMPLETE" -ForegroundColor Cyan
    Write-Host "Run without -DryRun to actually create issues" -ForegroundColor Cyan
} else {
    Write-Host "`n🎉 Issue creation complete!" -ForegroundColor Green
    Write-Host "Trigger sync workflow to update tracker:" -ForegroundColor Yellow
    Write-Host "gh workflow run 'Loose-Ends Tracker Sync' --repo $Repo" -ForegroundColor White
}