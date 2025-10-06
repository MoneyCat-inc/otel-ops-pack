# Security Update Script
# Run this script to update dependencies and fix security vulnerabilities

param(
    [switch]$DryRun,
    [switch]$CriticalOnly,
    [switch]$Verbose
)

Write-Host "🛡️ Security Vulnerability Remediation Script" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

if ($DryRun) {
    Write-Host "🧪 DRY RUN MODE - No changes will be made" -ForegroundColor Yellow
}

Write-Host ""

# Check current vulnerability status
Write-Host "📊 Current Security Status:" -ForegroundColor Blue
try {
    $auditResult = pnpm audit --json 2>$null | ConvertFrom-Json
    $vulnerabilities = $auditResult.vulnerabilities
    $totalVulns = $auditResult.metadata.vulnerabilities.total
    
    Write-Host "Total Vulnerabilities: $totalVulns" -ForegroundColor White
    
    if ($vulnerabilities) {
        $critical = ($vulnerabilities | Where-Object { $_.severity -eq "critical" }).Count
        $high = ($vulnerabilities | Where-Object { $_.severity -eq "high" }).Count
        $moderate = ($vulnerabilities | Where-Object { $_.severity -eq "moderate" }).Count
        $low = ($vulnerabilities | Where-Object { $_.severity -eq "low" }).Count
        
        Write-Host "Critical: $critical" -ForegroundColor Red
        Write-Host "High: $high" -ForegroundColor Yellow
        Write-Host "Moderate: $moderate" -ForegroundColor Cyan
        Write-Host "Low: $low" -ForegroundColor Green
    }
} catch {
    Write-Host "⚠️ Could not retrieve audit information" -ForegroundColor Yellow
}

Write-Host ""

# Create security update branch
Write-Host "🌿 Creating security update branch..." -ForegroundColor Blue
if (-not $DryRun) {
    try {
        git checkout -b security/update-dependencies 2>$null
        Write-Host "✅ Created branch: security/update-dependencies" -ForegroundColor Green
    } catch {
        Write-Host "⚠️ Branch may already exist or git not available" -ForegroundColor Yellow
    }
} else {
    Write-Host "🧪 Would create branch: security/update-dependencies" -ForegroundColor Yellow
}

Write-Host ""

# Update critical dependencies
Write-Host "🔧 Updating Critical Dependencies..." -ForegroundColor Blue

$updateCommands = @(
    @{ Name = "Next.js"; Command = "pnpm update next@latest" },
    @{ Name = "esbuild"; Command = "pnpm update esbuild@latest" }
)

if ($CriticalOnly) {
    Write-Host "🎯 Critical-only mode: Updating only critical packages" -ForegroundColor Yellow
} else {
    $updateCommands += @{ Name = "All Dependencies"; Command = "pnpm update" }
}

foreach ($update in $updateCommands) {
    Write-Host "Updating $($update.Name)..." -ForegroundColor White
    
    if ($DryRun) {
        Write-Host "🧪 Would run: $($update.Command)" -ForegroundColor Yellow
    } else {
        try {
            Invoke-Expression $update.Command
            Write-Host "✅ $($update.Name) updated successfully" -ForegroundColor Green
        } catch {
            Write-Host "❌ Failed to update $($update.Name): $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

Write-Host ""

# Run security audit fix
Write-Host "🔍 Running Security Audit Fix..." -ForegroundColor Blue
if ($DryRun) {
    Write-Host "🧪 Would run: pnpm audit --fix" -ForegroundColor Yellow
} else {
    try {
        pnpm audit --fix
        Write-Host "✅ Security audit fix completed" -ForegroundColor Green
    } catch {
        Write-Host "⚠️ Some vulnerabilities may require manual intervention" -ForegroundColor Yellow
    }
}

Write-Host ""

# Check final status
Write-Host "📊 Final Security Status:" -ForegroundColor Blue
if (-not $DryRun) {
    try {
        $finalAudit = pnpm audit --json 2>$null | ConvertFrom-Json
        $finalVulns = $finalAudit.metadata.vulnerabilities.total
        Write-Host "Remaining Vulnerabilities: $finalVulns" -ForegroundColor White
        
        if ($finalVulns -eq 0) {
            Write-Host "🎉 All vulnerabilities fixed!" -ForegroundColor Green
        } elseif ($finalVulns -lt $totalVulns) {
            $fixed = $totalVulns - $finalVulns
            Write-Host "✅ Fixed $fixed vulnerabilities" -ForegroundColor Green
        }
    } catch {
        Write-Host "⚠️ Could not retrieve final audit status" -ForegroundColor Yellow
    }
}

Write-Host ""

# Next steps
Write-Host "📋 Next Steps:" -ForegroundColor Cyan
Write-Host "1. Test the application: pnpm dev" -ForegroundColor White
Write-Host "2. Run CI/CD tests: pnpm test" -ForegroundColor White
Write-Host "3. Verify SigNoz integration: pwsh scripts/quick-monitor.ps1" -ForegroundColor White
Write-Host "4. Commit changes: git add . && git commit -m 'security: Fix vulnerabilities'" -ForegroundColor White
Write-Host "5. Push branch: git push origin security/update-dependencies" -ForegroundColor White

Write-Host ""
Write-Host "🛡️ Security remediation script completed!" -ForegroundColor Green
