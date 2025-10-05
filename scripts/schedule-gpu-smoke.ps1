param(
    [string]$TaskName = 'OTel GPU Smoke Nightly',
    [string]$RepoPath = 'C:\otel',
    [string]$ScriptPath = 'C:\otel\scripts\verify-gpu-codex.ps1',
    [string]$StartTime = '02:00'
)
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

if (-not (Test-Path -LiteralPath $RepoPath)) { throw "RepoPath not found: $RepoPath" }
if (-not (Test-Path -LiteralPath $ScriptPath)) { throw "ScriptPath not found: $ScriptPath" }

$action = New-ScheduledTaskAction -Execute 'pwsh.exe' -Argument "-NoLogo -NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`"" -WorkingDirectory $RepoPath
$trigger = New-ScheduledTaskTrigger -Daily -At ([DateTime]::ParseExact($StartTime,'HH:mm',$null))
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -AllowStartIfOnBatteries

try {
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
} catch {}

Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Settings $settings -Description 'Runs GPU Triton smoke test nightly and saves artifacts to artifacts/gpu_diag' | Out-Null
Write-Host "Scheduled task '$TaskName' registered to run at $StartTime daily." -ForegroundColor Green

