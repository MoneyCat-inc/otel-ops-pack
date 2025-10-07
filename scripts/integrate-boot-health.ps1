#Requires -Version 7.0

<#
.SYNOPSIS
    Integrates boot health checks into IONA and BossCat startup processes
.DESCRIPTION
    Updates PowerShell profile, scheduled tasks, and startup scripts
    to automatically run health checks on every boot
#>

param(
    [switch]$Profile,
    [switch]$ScheduledTask,
    [switch]$All
)

$ErrorActionPreference = 'Stop'

Write-Host "`n🔧 Integrating Boot Health Checks" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════`n" -ForegroundColor Cyan

$scriptRoot = $PSScriptRoot
$bootHealthScript = Join-Path $scriptRoot "boot-health-check.ps1"

if (-not (Test-Path $bootHealthScript)) {
    Write-Host "❌ Boot health script not found: $bootHealthScript" -ForegroundColor Red
    exit 1
}

# ============================================================================
# 1. PowerShell Profile Integration
# ============================================================================

if ($Profile -or $All) {
    Write-Host "📝 Integrating into PowerShell Profile..." -ForegroundColor Yellow
    
    $profilePath = $PROFILE.CurrentUserAllHosts
    $profileDir = Split-Path $profilePath -Parent
    
    if (-not (Test-Path $profileDir)) {
        New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
    }
    
    $bootCheckCode = @"

# ============================================================================
# IONA + BossCat Auto Health Check
# ============================================================================
if (`$PWD.Path -like '*otel*') {
    `$bootHealthScript = '$bootHealthScript'
    if (Test-Path `$bootHealthScript) {
        # Run health check silently on first shell in session
        if (-not `$env:OTEL_BOOT_CHECKED) {
            `$env:OTEL_BOOT_CHECKED = '1'
            Write-Host "🐾 Running IONA + BossCat health check..." -ForegroundColor Cyan
            & pwsh -NoProfile -File `$bootHealthScript -Environment dev -SendTelemetry
        }
    }
}
"@

    # Check if already integrated
    if (Test-Path $profilePath) {
        $profileContent = Get-Content $profilePath -Raw
        if ($profileContent -notlike "*IONA + BossCat Auto Health Check*") {
            Add-Content -Path $profilePath -Value "`n$bootCheckCode"
            Write-Host "✅ Added to PowerShell profile: $profilePath" -ForegroundColor Green
        } else {
            Write-Host "✓ Already integrated in profile" -ForegroundColor Green
        }
    } else {
        Set-Content -Path $profilePath -Value $bootCheckCode
        Write-Host "✅ Created PowerShell profile with health check: $profilePath" -ForegroundColor Green
    }
}

# ============================================================================
# 2. Scheduled Task (Run on User Logon)
# ============================================================================

if ($ScheduledTask -or $All) {
    Write-Host "`n📅 Creating Scheduled Task..." -ForegroundColor Yellow
    
    $taskName = "IONABossCatBootHealth"
    $taskPath = "\BossCat"
    
    # Remove existing task if present
    Unregister-ScheduledTask -TaskName $taskName -TaskPath $taskPath -Confirm:$false -ErrorAction SilentlyContinue
    
    $action = New-ScheduledTaskAction `
        -Execute 'pwsh.exe' `
        -Argument "-NoProfile -WindowStyle Hidden -File `"$bootHealthScript`" -Environment dev -SendTelemetry" `
        -WorkingDirectory (Split-Path $bootHealthScript -Parent)
    
    $trigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
    
    $settings = New-ScheduledTaskSettingsSet `
        -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries `
        -StartWhenAvailable `
        -ExecutionTimeLimit (New-TimeSpan -Minutes 5)
    
    $principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive
    
    $task = New-ScheduledTask -Action $action -Trigger $trigger -Settings $settings -Principal $principal
    
    Register-ScheduledTask -TaskName $taskName -TaskPath $taskPath -InputObject $task | Out-Null
    
    Write-Host "✅ Scheduled task created: $taskPath\$taskName" -ForegroundColor Green
    Write-Host "   Runs on: User logon" -ForegroundColor Gray
}

# ============================================================================
# 3. Integration Summary
# ============================================================================

Write-Host "`n✅ Boot Health Check Integration Complete" -ForegroundColor Green
Write-Host "`n📊 Active Integrations:" -ForegroundColor Cyan

if ($Profile -or $All) {
    Write-Host "   ✓ PowerShell Profile: Auto-runs in otel directory" -ForegroundColor Green
}

if ($ScheduledTask -or $All) {
    Write-Host "   ✓ Scheduled Task: Runs on every logon" -ForegroundColor Green
}

Write-Host "`n💡 Test the integration:" -ForegroundColor Yellow
Write-Host "   pwsh -File scripts/boot-health-check.ps1" -ForegroundColor Gray

Write-Host "`n🎯 What happens automatically now:" -ForegroundColor Cyan
Write-Host "   1. On logon: Scheduled task runs health check" -ForegroundColor White
Write-Host "   2. In otel directory: Profile runs health check" -ForegroundColor White
Write-Host "   3. All components: Auto-verified and started" -ForegroundColor White
Write-Host "   4. Boot reports: Saved to artifacts/boot-reports/" -ForegroundColor White

