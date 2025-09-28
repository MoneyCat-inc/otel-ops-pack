# Tetragrammaton Agent Boilerplate - ORCH (Orchestrator) Script
# Purpose: Manage ORCH tickets and bootstrap the Tetragrammaton workflow

param(
    [Parameter(Mandatory=$false)]
    [string]$Action = "status",

    [Parameter(Mandatory=$false)]
    [string]$Feature = "",

    [Parameter(Mandatory=$false)]
    [string]$TicketId = "",

    [Parameter(Mandatory=$false)]
    [switch]$Deploy,

    [Parameter(Mandatory=$false)]
    [switch]$CreateTicket,

    [Parameter(Mandatory=$false)]
    [switch]$ListTickets
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path))
Set-Location $repoRoot

function Step($msg) { Write-Host "==> $msg" -ForegroundColor Cyan }
function Success($msg) { Write-Host "[OK] $msg" -ForegroundColor Green }
function Warn($msg) { Write-Host "[WARN] $msg" -ForegroundColor Yellow }
function Fail($msg) { Write-Host "[ERR] $msg" -ForegroundColor Red }

$configPath = ".agent/config.json"
if (-not (Test-Path $configPath)) {
    Fail "Agent configuration not found at $configPath"
    exit 1
}
$config = Get-Content $configPath | ConvertFrom-Json

if (Test-Path ".agent/LOCK") {
    Warn ".agent/LOCK present - Tetragrammaton paused. Remove the file to resume."
    exit 2
}

function Show-TetragrammatonStatus {
    Step "Tetragrammaton Agent Boilerplate Status"
    Write-Host ""
    Write-Host "Agent: $($config.agentName)"
    Write-Host "Role:  $($config.role)"
    Write-Host "Desc:  $($config.description)"
    Write-Host ""
    Write-Host "Roles:"
    foreach ($role in $config.tetragrammaton.roles.PSObject.Properties) {
        $roleData = $role.Value
        Write-Host "  - $($role.Name): $($roleData.name)"
        Write-Host "    Goal: $($roleData.goal)"
        Write-Host "    Owns: $([string]::Join(', ', $roleData.owns))"
        Write-Host ""
    }
    Write-Host "Guardrails:"
    foreach ($guardrail in $config.guardrails.PSObject.Properties) {
        Write-Host "  - $($guardrail.Name): $($guardrail.Value)"
    }
}

function Ensure-TetragrammatonLayout {
    Step "Ensuring Tetragrammaton directories"
    $dirs = @('.agent/scripts', '.agent/tickets', 'artifacts')
    foreach ($dir in $dirs) {
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
            Success "Created $dir"
        }
    }
}

function Deploy-TetragrammatonSystem {
    Ensure-TetragrammatonLayout
    Success "Tetragrammaton directories ready"
}

function New-OrchTicket {
    if (-not $Feature) {
        Fail "Feature name is required. Use -Feature to provide it."
        exit 1
    }

    Ensure-TetragrammatonLayout

    $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $ticketId = "ORCH-$timestamp"
    $slug = ($Feature.ToLower() -replace '[^a-z0-9]+', '-')
    $slug = $slug.Trim('-')
    if (-not $slug) { $slug = 'feature' }
    $ticketPath = ".agent/tickets/$ticketId-$slug.md"

    $created = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $template = @"
# ${ticketId}: Draft Spec + DoD for $Feature

**Created:** $created
**Feature:** $Feature
**Status:** Draft

## Inputs
Product goal: $Feature

## Tasks
- [ ] Write concise spec in `TASKS.md`
- [ ] Define **Acceptance Criteria** (functional + a11y)
- [ ] Add **Test Notes** (unit + Playwright/E2E)
- [ ] Update `DECISIONS.md` with any new guardrails
- [ ] Define performance budgets and constraints
- [ ] Specify copy tone and accessibility requirements

## Outputs
Markdown artifacts (`TASKS.md`, `DECISIONS.md`)

## Definition of Done
Clear, unambiguous spec exists; IMPL can code without guessing

## Notes
- Follow Tetragrammaton ORCH role guidelines
- Ensure all guardrails are considered
- Create clear hand-off instructions for IMPL
"@

    Set-Content -Path $ticketPath -Value $template -Encoding UTF8
    Success "Created ticket at $ticketPath"
    Write-Host ""
    Write-Host "Next steps:"
    Write-Host "  1. Edit the ticket to add detailed specification"
    Write-Host "  2. Populate acceptance criteria and tests"
    Write-Host "  3. Update TASKS.md and DECISIONS.md as needed"
    Write-Host "  4. Hand off to IMPL role"
}

function List-OrchTickets {
    Ensure-TetragrammatonLayout

    $tickets = Get-ChildItem -Path '.agent/tickets' -Filter 'ORCH-*.md' -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
    if (-not $tickets -or $tickets.Count -eq 0) {
        Warn "No ORCH tickets found. Use -CreateTicket to create one."
        return
    }

    Step "Listing ORCH tickets"
    foreach ($ticket in $tickets) {
        $content = Get-Content $ticket.FullName -Raw
        $status = if ($content -match '\*\*Status:\*\* (.+)') { $matches[1] } else { 'Unknown' }
        $feature = if ($content -match '\*\*Feature:\*\* (.+)') { $matches[1] } else { 'Unknown' }
        Write-Host "- $($ticket.Name)"
        Write-Host "  Feature: $feature"
        Write-Host "  Status:  $status"
        Write-Host "  Updated: $($ticket.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss'))"
        Write-Host ""
    }
}

if ($Deploy) {
    Deploy-TetragrammatonSystem
    return
}
if ($CreateTicket) {
    New-OrchTicket
    return
}

switch ($Action.ToLowerInvariant()) {
    'status' { Show-TetragrammatonStatus }
    'deploy' { Deploy-TetragrammatonSystem }
    'list' { List-OrchTickets }
    'create' { New-OrchTicket }
    'help' {
        Write-Host "Tetragrammaton ORCH Commands:"
        Write-Host "  -Action status            # Show status"
        Write-Host "  -Action deploy            # Ensure directories exist"
        Write-Host "  -Action list              # List ORCH tickets"
        Write-Host "  -Action create -Feature X # Create a ticket"
        Write-Host ""
        Write-Host "Switch shortcuts:"
        Write-Host "  -Deploy"
        Write-Host "  -CreateTicket -Feature X"
        Write-Host "  -ListTickets"
    }
    Default {
        Fail "Unknown action '$Action'"
        Write-Host "Run with -Action help for available commands"
        exit 1
    }
}

