# Network Adapter Audit and Cleanup Script
# Identifies unused VPN/virtual adapters and provides cleanup options

param(
    [switch]$DisableUnused = $false,
    [switch]$Force = $false
)

function Get-NetworkAdapterInfo {
    $adapters = Get-NetAdapter | Where-Object { $_.Status -ne "Not Present" }
    
    $adapterInfo = @()
    foreach ($adapter in $adapters) {
        $config = Get-NetIPConfiguration -InterfaceIndex $adapter.InterfaceIndex -ErrorAction SilentlyContinue
        $adapterInfo += [PSCustomObject]@{
            Name = $adapter.Name
            InterfaceDescription = $adapter.InterfaceDescription
            Status = $adapter.Status
            InterfaceIndex = $adapter.InterfaceIndex
            LinkSpeed = $adapter.LinkSpeed
            HasIPAddress = $config.IPv4Address -ne $null
            IPAddress = $config.IPv4Address.IPAddress
            Gateway = $config.IPv4DefaultGateway.NextHop
            IsVirtual = $adapter.InterfaceDescription -match "(Virtual|TAP|VPN|Hyper-V|WAN Miniport|Kernel Debug)"
            IsPhysical = $adapter.InterfaceDescription -match "(Intel|Realtek|Broadcom|Qualcomm|Ethernet)"
        }
    }
    
    return $adapterInfo
}

function Show-AdapterSummary {
    param($adapters)
    
    Write-Host "`n=== Network Adapter Audit Report ===" -ForegroundColor Cyan
    Write-Host "Total Adapters: $($adapters.Count)" -ForegroundColor White
    
    $physical = $adapters | Where-Object { $_.IsPhysical }
    $virtual = $adapters | Where-Object { $_.IsVirtual }
    $active = $adapters | Where-Object { $_.HasIPAddress -and $_.Status -eq "Up" }
    $inactive = $adapters | Where-Object { -not $_.HasIPAddress -or $_.Status -ne "Up" }
    
    Write-Host "Physical Adapters: $($physical.Count)" -ForegroundColor Green
    Write-Host "Virtual/VPN Adapters: $($virtual.Count)" -ForegroundColor Yellow
    Write-Host "Active (with IP): $($active.Count)" -ForegroundColor Green
    Write-Host "Inactive: $($inactive.Count)" -ForegroundColor Red
    
    Write-Host "`n=== Active Adapters ===" -ForegroundColor Green
    $active | ForEach-Object {
        Write-Host "  $($_.Name) - $($_.IPAddress) -> $($_.Gateway)" -ForegroundColor White
    }
    
    Write-Host "`n=== Inactive Virtual/VPN Adapters ===" -ForegroundColor Yellow
    $inactive | Where-Object { $_.IsVirtual } | ForEach-Object {
        Write-Host "  $($_.Name) - $($_.InterfaceDescription)" -ForegroundColor Gray
    }
}

function Disable-UnusedAdapters {
    param($adapters, $force)
    
    $unusedVirtual = $adapters | Where-Object { 
        $_.IsVirtual -and 
        (-not $_.HasIPAddress -or $_.Status -ne "Up") -and
        $_.Status -eq "Up"  # Only disable if currently enabled
    }
    
    if ($unusedVirtual.Count -eq 0) {
        Write-Host "No unused virtual adapters found to disable." -ForegroundColor Green
        return
    }
    
    Write-Host "`n=== Adapters to Disable ===" -ForegroundColor Red
    $unusedVirtual | ForEach-Object {
        Write-Host "  $($_.Name) - $($_.InterfaceDescription)" -ForegroundColor Yellow
    }
    
    if (-not $force) {
        $confirm = Read-Host "`nDo you want to disable these adapters? (y/N)"
        if ($confirm -ne "y" -and $confirm -ne "Y") {
            Write-Host "Operation cancelled." -ForegroundColor Yellow
            return
        }
    }
    
    $disabled = 0
    foreach ($adapter in $unusedVirtual) {
        try {
            Disable-NetAdapter -Name $adapter.Name -Confirm:$false -ErrorAction Stop
            Write-Host "Disabled: $($adapter.Name)" -ForegroundColor Red
            $disabled++
        }
        catch {
            Write-Warning "Failed to disable $($adapter.Name): $($_.Exception.Message)"
        }
    }
    
    Write-Host "`nDisabled $disabled adapters." -ForegroundColor Yellow
}

# Main execution
Write-Host "Network Adapter Audit Tool" -ForegroundColor Cyan
Write-Host "=========================" -ForegroundColor Cyan

$adapters = Get-NetworkAdapterInfo
Show-AdapterSummary -adapters $adapters

if ($DisableUnused) {
    Disable-UnusedAdapters -adapters $adapters -force $Force
} else {
    Write-Host "`nTo disable unused adapters, run with -DisableUnused switch" -ForegroundColor Yellow
    Write-Host "Example: .\network-adapter-audit.ps1 -DisableUnused" -ForegroundColor Gray
}

Write-Host "`n=== Recommendations ===" -ForegroundColor Cyan
Write-Host "1. Keep active adapters (with IP addresses)" -ForegroundColor Green
Write-Host "2. Consider disabling unused VPN/virtual adapters" -ForegroundColor Yellow
Write-Host "3. Monitor for adapter changes in SysInfo logs" -ForegroundColor Blue
