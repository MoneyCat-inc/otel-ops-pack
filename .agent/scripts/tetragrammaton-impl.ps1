# Tetragrammaton Agent Boilerplate - IMPL (Implementer) Script
# Purpose: Implement features according to ORCH specifications

param(
    [Parameter(Mandatory=$false)]
    [string]$Action = "status",
    
    [Parameter(Mandatory=$false)]
    [string]$TicketId = "",
    
    [Parameter(Mandatory=$false)]
    [string]$Feature = "",
    
    [Parameter(Mandatory=$false)]
    [switch]$StartImplementation,
    
    [Parameter(Mandatory=$false)]
    [switch]$ListPending,
    
    [Parameter(Mandatory=$false)]
    [switch]$ValidateGuardrails
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path))
Set-Location $repoRoot

function Step($msg) { Write-Host "==> $msg" -ForegroundColor Cyan }
function Success($msg) { Write-Host "✅ $msg" -ForegroundColor Green }
function Warning($msg) { Write-Host "⚠️ $msg" -ForegroundColor Yellow }
function Error($msg) { Write-Host "❌ $msg" -ForegroundColor Red }

# Load agent configuration
$configPath = ".agent/config.json"
if (-not (Test-Path $configPath)) {
    Error "Agent configuration not found at $configPath"
    exit 1
}

$config = Get-Content $configPath | ConvertFrom-Json

# Check for lock file
if (Test-Path ".agent/LOCK") {
    Warning ".agent/LOCK present — IMPL paused. Remove the file to resume."
    exit 2
}

function Show-IMPL-Status {
    Step "IMPL (Implementer) Status"
    Write-Host ""
    Write-Host "🤖 Role: IMPL (Implementer)" -ForegroundColor Blue
    Write-Host "📋 Goal: $($config.tetragrammaton.roles.IMPL.goal)" -ForegroundColor Blue
    Write-Host "📝 Owns: $($($config.tetragrammaton.roles.IMPL.owns) -join ', ')" -ForegroundColor Blue
    Write-Host "🚫 Never Does: $($($config.tetragrammaton.roles.IMPL.neverDoes) -join ', ')" -ForegroundColor Blue
    Write-Host ""
    
    Write-Host "🛡️ Implementation Guardrails:" -ForegroundColor Yellow
    Write-Host "  ✅ No inline styles/scripts"
    Write-Host "  ✅ Strict CSP compliance"
    Write-Host "  ✅ ARIA accessibility features"
    Write-Host "  ✅ Unit + E2E tests required"
    Write-Host "  ✅ Performance budgets enforced"
    Write-Host "  ✅ WCAG AA compliance"
    Write-Host ""
}

function List-PendingTickets {
    Step "Listing Pending Implementation Tickets"
    
    $ticketsDir = ".agent/tickets"
    if (-not (Test-Path $ticketsDir)) {
        Warning "No tickets directory found. Run ORCH -Deploy first."
        return
    }
    
    $tickets = Get-ChildItem -Path $ticketsDir -Filter "ORCH-*.md" | Sort-Object LastWriteTime -Descending
    
    if ($tickets.Count -eq 0) {
        Warning "No ORCH tickets found. Use ORCH -CreateTicket to create new tickets."
        return
    }
    
    Write-Host ""
    Write-Host "🎫 Pending Implementation Tickets:" -ForegroundColor Yellow
    Write-Host ""
    
    foreach ($ticket in $tickets) {
        $content = Get-Content $ticket.FullName -Raw
        $title = ($content -split "`n")[0] -replace "^# ", ""
        $status = if ($content -match "\*\*Status:\*\* (.+)") { $matches[1] } else { "Unknown" }
        $feature = if ($content -match "\*\*Feature:\*\* (.+)") { $matches[1] } else { "Unknown" }
        
        # Check if IMPL ticket exists
        $implTicketName = $ticket.Name -replace "ORCH-", "IMPL-"
        $implTicketPath = Join-Path $ticketsDir $implTicketName
        $implStatus = if (Test-Path $implTicketPath) { "In Progress" } else { "Not Started" }
        
        Write-Host "  📋 $($ticket.Name)" -ForegroundColor White
        Write-Host "     Title: $title" -ForegroundColor Gray
        Write-Host "     Feature: $feature" -ForegroundColor Gray
        Write-Host "     Status: $status" -ForegroundColor Gray
        Write-Host "     IMPL Status: $implStatus" -ForegroundColor Gray
        Write-Host ""
    }
}

function Start-Implementation {
    if (-not $TicketId) {
        Error "Ticket ID is required. Use -TicketId parameter."
        exit 1
    }
    
    Step "Starting Implementation for Ticket: $TicketId"
    
    $ticketsDir = ".agent/tickets"
    $orchTicketPath = Join-Path $ticketsDir "$TicketId.md"
    
    if (-not (Test-Path $orchTicketPath)) {
        Error "ORCH ticket not found: $orchTicketPath"
        exit 1
    }
    
    $orchContent = Get-Content $orchTicketPath -Raw
    $feature = if ($orchContent -match "\*\*Feature:\*\* (.+)") { $matches[1] } else { "Unknown Feature" }
    
    # Create IMPL ticket
    $implTicketId = $TicketId -replace "ORCH-", "IMPL-"
    $implTicketPath = Join-Path $ticketsDir "$implTicketId-$($feature.ToLower().Replace(' ', '-')).md"
    
    if (Test-Path $implTicketPath) {
        Warning "IMPL ticket already exists: $implTicketPath"
        Write-Host "Use -TicketId to specify a different ticket or edit the existing one."
        return
    }
    
    $implContent = @"
# ${implTicketId}: Implement $feature per spec $TicketId

**Created:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
**Parent Ticket:** $TicketId
**Feature:** $feature
**Status:** In Progress

## Inputs
Spec from `TASKS.md`, guardrails from `DECISIONS.md`

## Implementation Tasks
- [ ] Write React/Tailwind component(s)
- [ ] Ensure **no inline styles/scripts**; follow CSP/ARIA rules
- [ ] Add unit + Playwright tests per spec
- [ ] Implement accessibility features (ARIA, keyboard nav, screen reader)
- [ ] Add performance monitoring and budgets
- [ ] Open PR with linked ticket ID

## Technical Requirements
- Use utility classes from `app/ui.css` only
- Implement proper ARIA labels and roles
- Add keyboard navigation support
- Include error boundaries for failures
- Add loading states and error handling
- Follow WCAG AA compliance standards

## Outputs
PR + green tests

## Definition of Done
PR meets acceptance criteria; CORD can run gates without changes

## Implementation Notes
- Follow Tetragrammaton IMPL role guidelines
- Ensure all guardrails are enforced
- Create comprehensive test coverage
- Document any deviations from spec

## Progress Log
- $(Get-Date -Format "yyyy-MM-dd HH:mm:ss"): Implementation started
"@
    
    Set-Content -Path $implTicketPath -Value $implContent -Encoding UTF8
    Success "Created IMPL ticket: $implTicketPath"
    
    Write-Host ""
    Write-Host "🎫 IMPL Ticket Created:" -ForegroundColor Yellow
    Write-Host "  ID: $implTicketId"
    Write-Host "  Feature: $feature"
    Write-Host "  Parent: $TicketId"
    Write-Host "  Path: $implTicketPath"
    Write-Host ""
    Write-Host "📋 Next Steps:" -ForegroundColor Yellow
    Write-Host "  1. Review the ORCH specification in $TicketId"
    Write-Host "  2. Implement the feature according to the spec"
    Write-Host "  3. Follow all guardrails (no inline styles, CSP, ARIA)"
    Write-Host "  4. Add comprehensive tests"
    Write-Host "  5. Open PR with @cloud ready-for-gate label"
    Write-Host "  6. Hand off to CORD role for review and merge"
}

function Validate-Guardrails {
    Step "Validating Implementation Guardrails"
    
    Write-Host ""
    Write-Host "🔍 Checking Guardrail Compliance:" -ForegroundColor Yellow
    Write-Host ""
    
    # Check for inline styles
    $inlineStyleFiles = Get-ChildItem -Path "src", "app", "components" -Recurse -Include "*.tsx", "*.jsx", "*.ts", "*.js" | 
        Select-String -Pattern 'style\s*=\s*\{' | 
        Select-Object -ExpandProperty Filename -Unique
    
    if ($inlineStyleFiles.Count -gt 0) {
        Error "Inline styles detected in: $($inlineStyleFiles -join ', ')"
        Write-Host "  Use utility classes from app/ui.css instead"
    } else {
        Success "No inline styles detected"
    }
    
    # Check for inline scripts
    $inlineScriptFiles = Get-ChildItem -Path "src", "app", "components" -Recurse -Include "*.tsx", "*.jsx", "*.ts", "*.js" | 
        Select-String -Pattern 'dangerouslySetInnerHTML' | 
        Select-Object -ExpandProperty Filename -Unique
    
    if ($inlineScriptFiles.Count -gt 0) {
        Warning "dangerouslySetInnerHTML detected in: $($inlineScriptFiles -join ', ')"
        Write-Host "  Review for CSP compliance"
    } else {
        Success "No dangerouslySetInnerHTML detected"
    }
    
    # Check for ARIA compliance
    $ariaFiles = Get-ChildItem -Path "src", "app", "components" -Recurse -Include "*.tsx", "*.jsx" | 
        Select-String -Pattern 'aria-' | 
        Select-Object -ExpandProperty Filename -Unique
    
    if ($ariaFiles.Count -gt 0) {
        Success "ARIA attributes found in: $($ariaFiles -join ', ')"
    } else {
        Warning "No ARIA attributes detected - ensure accessibility compliance"
    }
    
    # Check for CSP compliance
    $cspFiles = Get-ChildItem -Path "next.config.js", "app/layout.tsx" -ErrorAction SilentlyContinue
    if ($cspFiles.Count -gt 0) {
        Success "CSP configuration files found"
    } else {
        Warning "CSP configuration not found - ensure Content Security Policy is configured"
    }
    
    Write-Host ""
    Write-Host "🛡️ Guardrail Validation Complete" -ForegroundColor Yellow
}

# Main execution
if ($StartImplementation) {
    Start-Implementation
    return
}
if ($ListPending) {
    List-PendingTickets
    return
}

switch ($Action.ToLower()) {
    "status" { Show-IMPL-Status }
    "start" { Start-Implementation }
    "help" { 
        Write-Host "Tetragrammaton IMPL Commands:"
        Write-Host "  status - Show IMPL status and capabilities"
        Write-Host "  start - Start implementation for a ticket"
        Write-Host "  help - Show this help message"
        Write-Host ""
        Write-Host "Parameters:"
        Write-Host "  -StartImplementation -TicketId `"ORCH-XXXX`" - Start implementation"
        Write-Host "  -ListPending - List pending implementation tickets"
        Write-Host "  -ValidateGuardrails - Validate guardrail compliance"
    }
    default {
        Error "Unknown action: $Action"
        Write-Host "Use 'help' for available commands"
    }
}



