#Requires -Version 7.0
<#!
.SYNOPSIS
    Generate a MemX hardware health report for the local machine.
.DESCRIPTION
    Collects CPU, memory, GPU, UI (display), and networking information along with
    lightweight health evaluations. The resulting payload is emitted as JSON and can
    optionally be persisted to disk for downstream MemX automation.
.PARAMETER OutFile
    Optional path for the JSON report. When omitted a timestamped file is written to
    artifacts/memx/hardware/.
.PARAMETER NoPersist
    Do not write the report to disk; only emit JSON to the pipeline.
.PARAMETER Quiet
    Suppress console summary output (useful for automation).
.EXAMPLE
    pwsh -File scripts/memx/hardware-report.ps1

    Generates a report and writes it to artifacts/memx/hardware/. Provides a
    color-coded status summary in the console.
#>
param(
    [string]$OutFile,
    [switch]$NoPersist,
    [switch]$Quiet
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function New-MemxStatusSummary {
    param([string[]]$Statuses = @())
    if (-not $Statuses -or $Statuses.Count -eq 0) { return 'unknown' }
    if ($Statuses -contains 'error') { return 'error' }
    if ($Statuses -contains 'warn') { return 'warn' }
    return 'ok'
}

function New-MemxIssue {
    param([string]$Message)
    if ([string]::IsNullOrWhiteSpace($Message)) { return $null }
    return $Message.Trim()
}

function Get-TrimOrNull {
    param([object]$Value)
    if ($null -eq $Value) { return $null }
    $text = $Value.ToString()
    if ([string]::IsNullOrWhiteSpace($text)) { return $null }
    return $text.Trim()
}

function ConvertTo-NullableInt {
    param([object]$Value)
    if ($null -eq $Value) { return $null }
    try {
        return [int]$Value
    } catch {
        return $null
    }
}

function ConvertTo-NullableInt64 {
    param([object]$Value)
    if ($null -eq $Value) { return $null }
    try {
        return [int64]$Value
    } catch {
        return $null
    }
}

$now = Get-Date
$utf8NoBom = [System.Text.UTF8Encoding]::new($false)
$report = [ordered]@{
    version = 'memx-hardware-1'
    generatedAt = $now.ToUniversalTime().ToString('o')
    host = $env:COMPUTERNAME
    summary = [ordered]@{}
    components = [ordered]@{}
}

# --- Memory ---
$memoryModulesRaw = @()
try {
    $memoryModulesRaw = Get-CimInstance -ClassName Win32_PhysicalMemory
} catch {
    $memoryModulesRaw = @()
}

$memoryModules = @()
$memoryIssues = @()
foreach ($module in $memoryModulesRaw) {
    $moduleStatus = 'ok'
    $capacityBytes = ConvertTo-NullableInt64 $module.Capacity
    if ($null -eq $capacityBytes -or $capacityBytes -le 0) {
        $moduleStatus = 'error'
        $memoryIssues += New-MemxIssue "Module $($module.DeviceLocator) reports zero capacity"
    }

    $configuredClock = ConvertTo-NullableInt $module.ConfiguredClockSpeed
    if ($null -eq $configuredClock -or $configuredClock -le 0) {
        if ($moduleStatus -ne 'error') { $moduleStatus = 'warn' }
        $memoryIssues += New-MemxIssue "Module $($module.DeviceLocator) missing configured clock speed"
    }

    $reportedSpeed = ConvertTo-NullableInt $module.Speed
    if ($null -eq $reportedSpeed -or $reportedSpeed -le 0) {
        if ($moduleStatus -ne 'error') { $moduleStatus = 'warn' }
        $memoryIssues += New-MemxIssue "Module $($module.DeviceLocator) missing reported speed"
    }

    $memoryModules += [pscustomobject][ordered]@{
        slot = Get-TrimOrNull $module.DeviceLocator
        bank = Get-TrimOrNull $module.BankLabel
        manufacturer = Get-TrimOrNull $module.Manufacturer
        partNumber = Get-TrimOrNull $module.PartNumber
        serial = Get-TrimOrNull $module.SerialNumber
        capacityBytes = $capacityBytes
        configuredClockMHz = $configuredClock
        reportedSpeedMHz = $reportedSpeed
        dataWidthBits = ConvertTo-NullableInt $module.DataWidth
        totalWidthBits = ConvertTo-NullableInt $module.TotalWidth
        status = $moduleStatus
    }
}

if ($memoryModules.Count -eq 0) {
    $memoryIssues += New-MemxIssue 'No physical memory modules were returned by Win32_PhysicalMemory'
}

$memoryStatus = if ($memoryModules.Count -eq 0) { 'error' } else { New-MemxStatusSummary ($memoryModules | ForEach-Object { $_.status }) }
$memoryTotal = ($memoryModules | Where-Object { $_.capacityBytes -ne $null } | Measure-Object -Property capacityBytes -Sum).Sum
if ($null -eq $memoryTotal) {
    $memoryTotal = 0L
} else {
    $memoryTotal = [int64]$memoryTotal
}

$report.summary.memory = [ordered]@{
    status = $memoryStatus
    moduleCount = $memoryModules.Count
    totalCapacityBytes = $memoryTotal
    issues = @($memoryIssues | Where-Object { $_ })
}
$report.components.memory = [ordered]@{
    modules = $memoryModules
    totalCapacityBytes = $memoryTotal
    moduleCount = $memoryModules.Count
    dataWidths = @($memoryModules | ForEach-Object { $_.dataWidthBits } | Where-Object { $_ } | Sort-Object -Unique)
}

# --- CPU ---
$cpuInfoRaw = @()
try {
    $cpuInfoRaw = Get-CimInstance -ClassName Win32_Processor
} catch {
    $cpuInfoRaw = @()
}

$cpuEntries = @()
$cpuIssues = @()
foreach ($cpu in $cpuInfoRaw) {
    $load = ConvertTo-NullableInt $cpu.LoadPercentage
    $cpuStatus = 'ok'
    if ($null -ne $load -and $load -ge 95) {
        $cpuStatus = 'warn'
        $cpuIssues += New-MemxIssue "High CPU load on $($cpu.DeviceID) (${load}%)"
    }

    $cpuEntries += [pscustomobject][ordered]@{
        name = Get-TrimOrNull $cpu.Name
        deviceId = Get-TrimOrNull $cpu.DeviceID
        cores = ConvertTo-NullableInt $cpu.NumberOfCores
        logicalProcessors = ConvertTo-NullableInt $cpu.NumberOfLogicalProcessors
        maxClockMHz = ConvertTo-NullableInt $cpu.MaxClockSpeed
        currentClockMHz = ConvertTo-NullableInt $cpu.CurrentClockSpeed
        loadPercentage = $load
        status = $cpuStatus
    }
}

if ($cpuEntries.Count -eq 0) {
    $cpuIssues += New-MemxIssue 'No processors were returned by Win32_Processor'
}

$cpuStatus = if ($cpuEntries.Count -eq 0) { 'error' } else { New-MemxStatusSummary ($cpuEntries | ForEach-Object { $_.status }) }
$cpuTotalCores = ($cpuEntries | ForEach-Object { $_.cores } | Where-Object { $_ -ne $null }) | Measure-Object -Sum | Select-Object -ExpandProperty Sum -ErrorAction SilentlyContinue
if ($null -eq $cpuTotalCores) { $cpuTotalCores = 0 } else { $cpuTotalCores = [int]$cpuTotalCores }
$cpuTotalLogical = ($cpuEntries | ForEach-Object { $_.logicalProcessors } | Where-Object { $_ -ne $null }) | Measure-Object -Sum | Select-Object -ExpandProperty Sum -ErrorAction SilentlyContinue
if ($null -eq $cpuTotalLogical) { $cpuTotalLogical = 0 } else { $cpuTotalLogical = [int]$cpuTotalLogical }

$report.summary.cpu = [ordered]@{
    status = $cpuStatus
    packageCount = $cpuEntries.Count
    totalCores = $cpuTotalCores
    totalLogicalProcessors = $cpuTotalLogical
    issues = @($cpuIssues | Where-Object { $_ })
}
$report.components.cpu = [ordered]@{
    packages = $cpuEntries
}

# --- GPU ---
$gpuRaw = @()
try {
    $gpuRaw = Get-CimInstance -ClassName Win32_VideoController
} catch {
    $gpuRaw = @()
}

$gpuEntries = @()
$gpuIssues = @()
foreach ($gpu in $gpuRaw) {
    $gpuStatus = if ($null -ne $gpu.Status -and $gpu.Status -ne 'OK') { 'warn' } else { 'ok' }
    if ($gpuStatus -eq 'warn') {
        $gpuIssues += New-MemxIssue "Video controller $($gpu.Name) reported status $($gpu.Status)"
    }

    $gpuEntries += [pscustomobject][ordered]@{
        name = Get-TrimOrNull $gpu.Name
        driverVersion = Get-TrimOrNull $gpu.DriverVersion
        adapterRamBytes = ConvertTo-NullableInt64 $gpu.AdapterRAM
        currentRefreshRateHz = ConvertTo-NullableInt $gpu.CurrentRefreshRate
        videoMode = Get-TrimOrNull $gpu.VideoModeDescription
        status = $gpuStatus
    }
}

if ($gpuEntries.Count -eq 0) {
    $gpuIssues += New-MemxIssue 'No video controllers were returned by Win32_VideoController'
}

$gpuStatusOverall = if ($gpuEntries.Count -eq 0) { 'warn' } else { New-MemxStatusSummary ($gpuEntries | ForEach-Object { $_.status }) }
$report.summary.gpu = [ordered]@{
    status = $gpuStatusOverall
    controllerCount = $gpuEntries.Count
    issues = @($gpuIssues | Where-Object { $_ })
}
$report.components.gpu = [ordered]@{
    controllers = $gpuEntries
}

# --- UI / Displays ---
$monitorRaw = @()
try {
    $monitorRaw = Get-CimInstance -ClassName Win32_DesktopMonitor
} catch {
    $monitorRaw = @()
}

$monitorEntries = @()
$monitorIssues = @()
foreach ($monitor in $monitorRaw) {
    $availability = $monitor.Availability
    $availabilityStatus = switch ($availability) {
        3 { 'ok' }
        8 { 'warn' }
        10 { 'warn' }
        2 { 'warn' }
        $null { 'unknown' }
        default { 'unknown' }
    }
    if ($availabilityStatus -eq 'warn') {
        $monitorIssues += New-MemxIssue "Monitor $($monitor.Name) availability code $availability"
    }

    $monitorEntries += [pscustomobject][ordered]@{
        name = Get-TrimOrNull $monitor.Name
        pnpDeviceId = Get-TrimOrNull $monitor.PNPDeviceID
        availability = $availability
        screenWidth = ConvertTo-NullableInt $monitor.ScreenWidth
        screenHeight = ConvertTo-NullableInt $monitor.ScreenHeight
        status = $availabilityStatus
    }
}

if ($monitorEntries.Count -eq 0) {
    $monitorIssues += New-MemxIssue 'No desktop monitors were returned by Win32_DesktopMonitor'
}

$uiStatus = if ($monitorEntries.Count -eq 0) { 'warn' } else { New-MemxStatusSummary ($monitorEntries | ForEach-Object { $_.status }) }
$report.summary.ui = [ordered]@{
    status = $uiStatus
    monitorCount = $monitorEntries.Count
    issues = @($monitorIssues | Where-Object { $_ })
}
$report.components.ui = [ordered]@{
    monitors = $monitorEntries
}

# --- Networking ---
$adaptersRaw = @()
try {
    $adaptersRaw = Get-NetAdapter | Sort-Object -Property ifIndex
} catch {
    $adaptersRaw = @()
}

$adapterEntries = @()
$adapterIssues = @()
foreach ($adapter in $adaptersRaw) {
    $state = $adapter.Status
    $adapterStatus = switch ($state) {
        'Up' { 'ok' }
        'Disabled' { 'warn' }
        'Dormant' { 'warn' }
        'Not Present' { 'error' }
        'Down' { 'error' }
        default { 'warn' }
    }
    if ($adapterStatus -in @('warn','error')) {
        $adapterIssues += New-MemxIssue "Adapter $($adapter.Name) status $state"
    }

    $adapterEntries += [pscustomobject][ordered]@{
        name = Get-TrimOrNull $adapter.Name
        interfaceDescription = Get-TrimOrNull $adapter.InterfaceDescription
        status = $state
        linkSpeed = Get-TrimOrNull $adapter.LinkSpeed
        macAddress = Get-TrimOrNull $adapter.MacAddress
        statusLevel = $adapterStatus
    }
}

$loopbackReachable = $null
try {
    $loopbackReachable = Test-Connection -ComputerName 127.0.0.1 -Count 1 -Quiet -ErrorAction Stop
} catch {
    $loopbackReachable = $false
    $adapterIssues += New-MemxIssue 'Loopback ping (127.0.0.1) failed'
}

if ($adapterEntries.Count -eq 0) {
    $adapterIssues += New-MemxIssue 'No network adapters were returned by Get-NetAdapter'
}

$networkStatus = if ($adapterEntries.Count -eq 0) { 'error' } else { New-MemxStatusSummary ($adapterEntries | ForEach-Object { $_.statusLevel }) }
if ($loopbackReachable -eq $false -and $networkStatus -eq 'ok') {
    $networkStatus = 'warn'
}

$report.summary.networking = [ordered]@{
    status = $networkStatus
    adapterCount = $adapterEntries.Count
    adaptersUp = ($adapterEntries | Where-Object { $_.statusLevel -eq 'ok' }).Count
    loopbackReachable = $loopbackReachable
    issues = @($adapterIssues | Where-Object { $_ })
}
$report.components.networking = [ordered]@{
    adapters = $adapterEntries
    loopbackReachable = $loopbackReachable
}

# Determine automatic output path when needed
if (-not $OutFile -and -not $NoPersist) {
    $defaultRoot = Join-Path $PSScriptRoot '../../artifacts/memx/hardware'
    New-Item -ItemType Directory -Force -Path $defaultRoot | Out-Null
    $stamp = $now.ToUniversalTime().ToString('yyyyMMddTHHmmssZ')
    $OutFile = Join-Path $defaultRoot "memx-hardware-$stamp.json"
}

$json = $report | ConvertTo-Json -Depth 6 -Compress

if (-not $Quiet) {
    Write-Host 'MemX Hardware Summary' -ForegroundColor Cyan
    foreach ($key in $report.summary.Keys) {
        $line = $report.summary[$key]
        $status = $line.status
        $fg = switch ($status) {
            'ok' { 'Green' }
            'warn' { 'Yellow' }
            'error' { 'Red' }
            default { 'Gray' }
        }
        Write-Host (" - {0}: {1}" -f $key, $status) -ForegroundColor $fg
        if ($line.issues -and $line.issues.Count -gt 0) {
            foreach ($issue in $line.issues) {
                Write-Host ("   * {0}" -f $issue) -ForegroundColor DarkYellow
            }
        }
    }
}

if (-not $NoPersist) {
    if (-not $OutFile) {
        throw 'Output path resolution failed.'
    }
    [System.IO.File]::WriteAllText($OutFile, $json, $utf8NoBom)
    if (-not $Quiet) {
        Write-Host "MemX hardware report written: $OutFile" -ForegroundColor Green
    }
}

if ($NoPersist -and -not $Quiet) {
    Write-Host 'NoPersist flag set; report was not written to disk.' -ForegroundColor Yellow
}

$json
