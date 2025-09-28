# scripts/agent/pr-badge-check.ps1 - Pre-merge badge validation for PRs

param(
    [switch]$CheckOnly,
    [switch]$UpdateTemplate,
    [switch]$Json,
    [string]$TemplatePath = ".github/pull_request_template.md"
)

$ErrorActionPreference = "Stop"

function Write-BadgeResult {
    param(
        [string]$Message,
        [bool]$Success = $true
    )
    
    $color = if ($Success) { "Green" } else { "Red" }
    $icon = if ($Success) { "✅" } else { "❌" }
    Write-Host "$icon $Message" -ForegroundColor $color
}

function Get-GuardrailStatus {
    try {
        $output = pnpm agent:guardrails-premium -Json 2>$null
        # Find the JSON part - look for the first { and take everything from there
        $jsonStart = -1
        for ($i = 0; $i -lt $output.Count; $i++) {
            if ($output[$i] -match '^\s*\{') {
                $jsonStart = $i
                break
            }
        }
        
        if ($jsonStart -ge 0) {
            $cleanOutput = ($output | Select-Object -Skip $jsonStart) -join "`n"
        } else {
            $cleanOutput = $output -join "`n"
        }
        $result = $cleanOutput | ConvertFrom-Json
        return @{
            violations = $result.violations
            filesProcessed = $result.filesProcessed
            success = $result.violations -eq 0
            timestamp = (Get-Date).ToString("o")
            status = if ($result.violations -eq 0) { "passing" } else { "failing" }
            color = if ($result.violations -eq 0) { "brightgreen" } else { "red" }
        }
    } catch {
        return @{
            violations = -1
            filesProcessed = 0
            success = $false
            timestamp = (Get-Date).ToString("o")
            error = $_.Exception.Message
            status = "error"
            color = "red"
        }
    }
}

function Get-StatusBadge {
    param([hashtable]$GuardrailStatus)
    
    if ($GuardrailStatus.success) {
        return @{
            color = "green"
            status = "passing"
            message = "All guardrails passed"
            url = "https://img.shields.io/badge/codex--local-guardrails-passing-green.svg?label=Guardrails&message=PASS"
        }
    } else {
        $violations = $GuardrailStatus.violations
        if ($violations -lt 0) {
            return @{
                color = "red"
                status = "error"
                message = "Guardrail check failed"
                url = "https://img.shields.io/badge/codex--local-guardrails-error-red.svg?label=Guardrails&message=ERROR"
            }
        } else {
            return @{
                color = "red"
                status = "failing"
                message = "$violations violations found"
                url = "https://img.shields.io/badge/codex--local-guardrails-failing-red.svg?label=Guardrails&message=$violations+violations"
            }
        }
    }
}

# Import hardening utilities
. "$PSScriptRoot\utils\output-guard.ps1" -Json:$Json -Quiet:$CheckOnly

if (-not $Json -and -not $CheckOnly) {
    Write-Host "🔍 codex-local Pre-merge Badge Check" -ForegroundColor Cyan
    Write-Host "=====================================" -ForegroundColor Cyan
}

# Get guardrail status
if (-not $Json -and -not $CheckOnly) {
    Write-Host "`n📊 Checking guardrail status..." -ForegroundColor Yellow
}
$guardrailStatus = Get-GuardrailStatus
$badge = Get-StatusBadge -GuardrailStatus $guardrailStatus

# JSON output mode
if ($Json) {
    $jsonOutput = @{
        status = $guardrailStatus.status
        color = $guardrailStatus.color
        lastDoctor = $guardrailStatus.timestamp
        violDelta = $guardrailStatus.violations
        filesProcessed = $guardrailStatus.filesProcessed
        success = $guardrailStatus.success
        badgeUrl = $badge.url
    }
    
    $jsonOutput | ConvertTo-Json -Depth 3
    exit $(if ($guardrailStatus.success) { 0 } else { 1 })
}

# Display results (non-JSON mode)
if (-not $CheckOnly) {
    Write-Host "`n📈 Guardrail Status:" -ForegroundColor White
    Write-Host "   Files Processed: $($guardrailStatus.filesProcessed)" -ForegroundColor Gray
    Write-Host "   Violations: $($guardrailStatus.violations)" -ForegroundColor $(if ($guardrailStatus.success) { "Green" } else { "Red" })
    Write-Host "   Status: $($badge.message)" -ForegroundColor $(if ($guardrailStatus.success) { "Green" } else { "Red" })

    Write-Host "`n🎖️ Badge Information:" -ForegroundColor White
    Write-Host "   Status: $($badge.status)" -ForegroundColor $badge.color
    Write-Host "   URL: $($badge.url)" -ForegroundColor Gray
}

if ($UpdateTemplate) {
    Write-Host "`n📝 Updating PR template..." -ForegroundColor Yellow
    
    # Create or update PR template
    $templateContent = @"
# Pull Request

## 🔍 Pre-merge Checklist

- [ ] Code changes reviewed
- [ ] Tests pass
- [ ] Documentation updated

## 🛡️ Guardrail Status

![Guardrails Status]($($badge.url))

**Last Check**: $($guardrailStatus.timestamp)
**Files Processed**: $($guardrailStatus.filesProcessed)
**Violations**: $($guardrailStatus.violations)

$(if (-not $guardrailStatus.success) {
    "⚠️ **Guardrail violations detected!** Please run \`pnpm agent:guardrails-premium -Fix\` to resolve."
})

## 📋 Changes

<!-- Describe your changes here -->

## 🧪 Testing

<!-- Describe how you tested these changes -->

## 📚 Documentation

<!-- List any documentation changes -->
"@

    # Ensure .github directory exists
    if (-not (Test-Path ".github")) {
        New-Item -ItemType Directory ".github" | Out-Null
    }
    
    $templateContent | Set-Content -Path $TemplatePath -Encoding UTF8
    Write-BadgeResult -Message "PR template updated at $TemplatePath" -Success $true
}

if ($CheckOnly) {
    # Just check and report
    if ($guardrailStatus.success) {
        Write-BadgeResult -Message "Pre-merge check PASSED - Ready to merge" -Success $true
        exit 0
    } else {
        Write-BadgeResult -Message "Pre-merge check FAILED - Fix violations before merging" -Success $false
        
        if ($guardrailStatus.violations -gt 0) {
            Write-Host "`n💡 To fix violations:" -ForegroundColor Cyan
            Write-Host "   pnpm agent:guardrails-premium -Fix" -ForegroundColor White
        }
        
        exit 1
    }
}

Write-Host "`n🎯 Pre-merge badge check completed" -ForegroundColor Green
