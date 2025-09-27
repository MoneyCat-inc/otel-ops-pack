# Master Cursor Agent Management Script
# Manages all specialized Cursor agents

param(
    [string]$Action = "Status",
    [string]$AgentId = "",
    [switch]$ListAll = $false
)

$Agents = @(
    @{ Id = "cursor-ecrr-agent-001"; Name = "Cursor ECRR Task Agent"; Status = "Active" },
    @{ Id = "cursor-conflict-analysis-agent"; Name = "Cursor Conflict Analysis Agent"; Status = "Active" },
    @{ Id = "cursor-otlp-wiring-agent"; Name = "Cursor OTLP Wiring Agent"; Status = "Active" },
    @{ Id = "cursor-docker-mount-agent"; Name = "Cursor Docker Mount Fix Agent"; Status = "Active" },
    @{ Id = "cursor-wiring-verification-agent"; Name = "Cursor Wiring Verification Agent"; Status = "Active" },
    @{ Id = "cursor-e2-ratio-analysis-agent"; Name = "Cursor E2 Ratio Analysis Agent"; Status = "Active" },
    @{ Id = "cursor-ecrr-processing-agent"; Name = "Cursor ECRR Processing Agent"; Status = "Active" },
    @{ Id = "cursor-index-management-agent"; Name = "Cursor Index Management Agent"; Status = "Active" }
)

switch ($Action.ToLower()) {
    "status" {
        Write-Host "🤖 Cursor Agent Status Overview" -ForegroundColor Green
        Write-Host "=" * 50 -ForegroundColor Gray
        foreach ($agent in $Agents) {
            $statusColor = if ($agent.Status -eq "Active") { "Green" } else { "Red" }
            Write-Host "$($agent.Id): $($agent.Name)" -ForegroundColor $statusColor
            Write-Host "  Status: $($agent.Status)" -ForegroundColor Gray
        }
    }
    "list" {
        Write-Host "📋 Available Cursor Agents" -ForegroundColor Cyan
        Write-Host "=" * 50 -ForegroundColor Gray
        for ($i = 0; $i -lt $Agents.Count; $i++) {
            $agentNum = $i + 1
            Write-Host "$agentNum. $($Agents[$i].Id)" -ForegroundColor White
            Write-Host "   Name: $($Agents[$i].Name)" -ForegroundColor Gray
        }
    }
    "start" {
        if ($AgentId) {
            $agent = $Agents | Where-Object { $_.Id -eq $AgentId }
            if ($agent) {
                Write-Host "🚀 Starting $($agent.Name)..." -ForegroundColor Green
                pwsh -File "scripts/$AgentId-startup.ps1"
            } else {
                Write-Host "❌ Agent not found: $AgentId" -ForegroundColor Red
            }
        } else {
            Write-Host "❌ Please specify AgentId with -AgentId parameter" -ForegroundColor Red
        }
    }
    "help" {
        Write-Host "🔧 Cursor Agent Management Commands" -ForegroundColor Cyan
        Write-Host "=" * 50 -ForegroundColor Gray
        Write-Host "Status: Show all agent status" -ForegroundColor White
        Write-Host "List: List all available agents" -ForegroundColor White
        Write-Host "Start: Start specific agent (requires -AgentId)" -ForegroundColor White
        Write-Host "Help: Show this help message" -ForegroundColor White
        Write-Host ""
        Write-Host "Examples:" -ForegroundColor Yellow
        Write-Host "  pwsh -File scripts/master-agent-management.ps1 -Action Status" -ForegroundColor Gray
        Write-Host "  pwsh -File scripts/master-agent-management.ps1 -Action List" -ForegroundColor Gray
        Write-Host "  pwsh -File scripts/master-agent-management.ps1 -Action Start -AgentId cursor-ecrr-agent-001" -ForegroundColor Gray
    }
    default {
        Write-Host "❌ Unknown action: $Action" -ForegroundColor Red
        Write-Host "Use -Action Help for available commands" -ForegroundColor Yellow
    }
}
